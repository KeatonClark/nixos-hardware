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
  uboot = pkgs.callPackage ./u-boot-phytec.nix { };
  kernel = pkgs.callPackage ./linux-phytec.nix { };
  dtbName = "k3-am642-phyboard-electra-rdk.dtb";

in {
  imports = [
    "${modulesPath}/installer/sd-card/sd-image.nix"
  ];

  hardware.enableAllHardware = lib.mkForce false;
  boot.initrd.includeDefaultModules = false;

  boot.loader.generic-extlinux-compatible.enable = true;

  boot.initrd.availableKernelModules = lib.mkForce [ ];
  boot.initrd.kernelModules = lib.mkForce [ ];

  boot.kernelPackages = pkgs.linuxPackagesFor kernel;

  boot.loader.grub.enable = false;

  sdImage = {
    imageName = "nixos-am64x.img";
    compressImage = false;

    firmwareSize = 256; # MiB
    firmwarePartitionName = "BOOT";

    storePaths = [ ];
    expandOnBoot = true;

    populateFirmwareCommands = ''
      cp ${tiboot3} firmware/tiboot3.bin
      cp ${tispl}   firmware/tispl.bin
      cp ${uboot}/u-boot.img   firmware/u-boot.img

      cp ${config.system.build.initialRamdisk}/${config.system.boot.loader.initrdFile} firmware/initrd
      ${config.boot.loader.generic-extlinux-compatible.populateCmd} \
        -c ${config.system.build.toplevel} \
        -d ./firmware
    '';

    populateRootCommands = "";

    # The AM64x ROM wants the FAT boot partition flagged active.
    postBuildCommands = ''
      sfdisk --activate $img 1
    '';
  };
}
