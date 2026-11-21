{ config, options, lib, pkgs, ... }:

let
  uboot-r5 = pkgs.pkgsCross.arm-embedded.u-boot-phycore-am64x-r5;
  uboot-a53 = pkgs.u-boot-phycore-am64x-a53;
  kernel = pkgs.linux-phytec-ti;
  firmware = pkgs.ti-linux-firmware;
  cfg = config.hardware.am64x;

    mkFirmwareFile = firmwareName: source: {
    inherit firmwareName source;
  };

  firmwareFileSubmodule = lib.types.submodule {
    options = {
      source = lib.mkOption {
        type = lib.types.nullOr lib.types.path;
        default = null;
        description = "Path to firmware file.";
      };

      firmwareName = lib.mkOption {
        type = lib.types.str;
        description = "Deployment path relative to lib/firmware. Check firmware-name in your device tree.";
      };
    };
  };

  mkFirmwareOption = default:
    lib.mkOption {
      type = lib.types.nullOr firmwareFileSubmodule;
      inherit default;
      description = "Firmware file to deploy.";
    };

  mkRPCFirmwareOption = name:
    mkFirmwareOption (
      mkFirmwareFile name "${firmware}/ti-ipc/am64xx/${name}"
    );

  mkPRUFirmwareOption = name:
    mkFirmwareOption (
      mkFirmwareFile name null
    );

  mkPRUEthernetFirmwareOption = names:
    lib.mkOption {
      type = lib.types.listOf firmwareFileSubmodule;
      default = map (name:
        mkFirmwareFile "ti-pruss/${name}" "${firmware}/ti-pruss/${name}"
      ) names;
      description = "Ethernet firmware files to deploy.";
    };
in
{
  options.hardware.am64x.firmware = {
    m4f0-0 = mkRPCFirmwareOption "am64-mcu-m4f0_0-fw";

    r5f0-0 = mkRPCFirmwareOption "am64-main-r5f0_0-fw";
    r5f0-1 = mkRPCFirmwareOption "am64-main-r5f0_1-fw";
    r5f1-0 = mkRPCFirmwareOption "am64-main-r5f1_0-fw";
    r5f1-1 = mkRPCFirmwareOption "am64-main-r5f1_1-fw";

    pru0-0 = mkPRUFirmwareOption "am64x-pru0_0-fw";
    pru0-1 = mkPRUFirmwareOption "am64x-pru0_1-fw";
    rtu0-0 = mkPRUFirmwareOption "am64x-rtu0_0-fw";
    rtu0-1 = mkPRUFirmwareOption "am64x-rtu0_1-fw";
    txpru0-0 = mkPRUFirmwareOption "am64x-txpru0_0-fw";
    txpru0-1 = mkPRUFirmwareOption "am64x-txpru0_1-fw";

    pru1-0 = mkPRUFirmwareOption "am64x-pru1_0-fw";
    pru1-1 = mkPRUFirmwareOption "am64x-pru1_1-fw";
    rtu1-0 = mkPRUFirmwareOption "am64x-rtu1_0-fw";
    rtu1-1 = mkPRUFirmwareOption "am64x-rtu1_1-fw";
    txpru1-0 = mkPRUFirmwareOption "am64x-txpru1_0-fw";
    txpru1-1 = mkPRUFirmwareOption "am64x-txpru1_1-fw";

    icssg-ethernet = mkPRUEthernetFirmwareOption [
      "am65x-sr2-pru0-prueth-fw.elf"
      "am65x-sr2-rtu0-prueth-fw.elf"
      "am65x-sr2-txpru0-prueth-fw.elf"
      "am65x-sr2-pru1-prueth-fw.elf"
      "am65x-sr2-rtu1-prueth-fw.elf"
      "am65x-sr2-txpru1-prueth-fw.elf"
    ];
  };

  config = lib.mkMerge [
    {
      nixpkgs = {
        hostPlatform = "aarch64-linux";
        overlays = [
          (import ../overlay.nix)
        ];
      };

      hardware = {
        enableAllHardware = lib.mkForce false;

        deviceTree = let
          dtbName = "k3-am642-phyboard-electra-rdk.dtb";
        in {
          name = lib.mkDefault "ti/${dtbName}";
          filter = lib.mkDefault dtbName;
        };

        firmware = lib.concatLists (
          lib.mapAttrsToList (name: value:
            let
              files = if name == "icssg-ethernet" then
                value
              else
                lib.optional (value != null) value;
            in
            lib.optional (files != [ ]) (
              pkgs.runCommand "firmware-${name}" { } ''
                mkdir -p $out/lib/firmware

                ${lib.concatMapStringsSep "\n" (file:
                  lib.optionalString (file.source != null) ''
                    mkdir -p "$out/lib/firmware/${builtins.dirOf file.firmwareName}"
                    cp ${file.source} "$out/lib/firmware/${file.firmwareName}"
                  ''
                ) files}
              ''
            )
          ) cfg.firmware
        );

        firmwareCompression = "none";
      };

      boot = {
        loader = {
          generic-extlinux-compatible.enable = true;
          grub.enable = lib.mkForce false;
        };

        kernelPackages = pkgs.linuxPackagesFor kernel;

        kernelParams = [
          "console=ttyS2,115200n8"
          "earlycon=ns16550a,mmio32,0x02800000"
        ];

        initrd = {
          includeDefaultModules = false;
          availableKernelModules = lib.mkForce [ ];
          kernelModules = lib.mkForce [ ];
        };
      };

      image.baseName =
        "nixos-phycore-am64x-${config.system.nixos.label}-${pkgs.stdenv.hostPlatform.system}";
    }

    (lib.mkIf (options ? sdImage) {

      fileSystems."/boot" = {
        device = "/dev/disk/by-label/BOOT";
        fsType = "vfat";
      };

      sdImage = {
        compressImage = false;

        firmwareSize = 256;
        firmwarePartitionName = "BOOT";

        storePaths = [ ];
        expandOnBoot = true;

        populateFirmwareCommands = ''
          cp ${uboot-r5}/tiboot3.bin firmware/tiboot3.bin
          cp ${uboot-a53}/tispl.bin firmware/tispl.bin
          cp ${uboot-a53}/u-boot.img firmware/u-boot.img

          ${config.boot.loader.generic-extlinux-compatible.populateCmd} \
            -c ${config.system.build.toplevel} \
            -d ./firmware
        '';

        populateRootCommands = "";

        postBuildCommands = ''
          sfdisk --activate $img 1
        '';
      };
    })
  ];
}
