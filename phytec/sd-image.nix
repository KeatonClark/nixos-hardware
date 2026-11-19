{ config, lib, pkgs, modulesPath, ... }:
let
  phytecDownload = "https://download.phytec.de/Software/Linux/BSP-Yocto-AM64x/BSP-Yocto-Ampliphy-AM64x-PD26.1.0/images/ampliphy/phyboard-electra-am64xx-2";
  tiboot3 = pkgs.fetchurl {
    url = "${phytecDownload}/tiboot3.bin";
    hash = "sha256-HWR/X7mZIQBSX7f88vQkM1UTKb/segNOY9YOKbR4f8o=";
  };
  tispl = pkgs.fetchurl {
    url = "${phytecDownload}/tispl.bin";
    hash = "sha256-7rr71KbtLgPbyYlrzlR8aEWtcpJIkUz87XPQJiBXmIs=";
  };
  uboot = pkgs.u-boot-phycore-am64x-a53;
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
      cp ${tiboot3}             firmware/tiboot3.bin
      cp ${tispl}               firmware/tispl.bin
      cp ${uboot}/u-boot.img    firmware/u-boot.img

      cp ${config.system.build.initialRamdisk}/${config.system.boot.loader.initrdFile} firmware/initrd
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
