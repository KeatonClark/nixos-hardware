{ config, lib, pkgs, modulesPath, ... }:
let
  uboot-r5 = pkgs.pkgsCross.arm-embedded.u-boot-phycore-am64x-r5;
  uboot-a53 = pkgs.u-boot-phycore-am64x-a53;
  kernel = pkgs.linux-phytec-ti;
in {
  imports = [
    "${modulesPath}/installer/sd-card/sd-image.nix"
  ];
  nixpkgs = {
    overlays = [
      (import ./phycore-am64x/overlay.nix)
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

  image.baseName = "nixos-phycore-am64x-${config.system.nixos.label}-${pkgs.stdenv.hostPlatform.system}";
  sdImage = {
    compressImage = false;

    firmwareSize = 128;
    firmwarePartitionName = "BOOT";

    storePaths = [ ];
    expandOnBoot = true;

    populateFirmwareCommands = ''
      cp ${uboot-r5}/tiboot3.bin    firmware/tiboot3.bin
      cp ${uboot-a53}/tispl.bin     firmware/tispl.bin
      cp ${uboot-a53}/u-boot.img    firmware/u-boot.img

      ${config.boot.loader.generic-extlinux-compatible.populateCmd} \
        -c ${config.system.build.toplevel} \
        -d ./firmware
    '';

    populateRootCommands = "";

    postBuildCommands = ''
      sfdisk --activate $img 1
    '';
  };
}
