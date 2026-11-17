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
  uboot = pkgs.fetchurl {
    url = "${phytecDownload}/u-boot.img";
    hash = "sha256-VQX3bapMwN6D33ha8G7Y25HAetmb75gJ1K8Ynok3s20=";
  };
  kernel = pkgs.callPackage ./linux-phytec.nix { };
  dtbName = "k3-am642-phyboard-electra-rdk.dtb";

  bootCmd = pkgs.writeText "boot.cmd" ''
    setenv bootargs "init=${config.system.build.toplevel}/init ${toString config.boot.kernelParams}"

    load mmc 1:1 0x82000000 Image
    load mmc 1:1 0x88000000 ${dtbName}
    load mmc 1:1 0x88080000 initrd
    setenv initrd_size ''${filesize}

    booti 0x82000000 0x88080000:''${initrd_size} 0x88000000
  '';

  bootScr = pkgs.runCommand "boot.scr"
    { nativeBuildInputs = [ pkgs.buildPackages.ubootTools ]; }
    ''
      mkimage -A arm64 -O linux -T script -C none -n "NixOS AM64x" \
        -d ${bootCmd} $out
    '';
in {
  imports = [
    "${modulesPath}/installer/sd-card/sd-image.nix"
    "${modulesPath}/installer/netboot/netboot-minimal.nix"
  ];

  # Stop the profile from adding its giant default hardware list
  hardware.enableAllHardware = lib.mkForce false;
  boot.initrd.includeDefaultModules = false;

  # Replace whatever the profiles accumulated with only what you need
  boot.initrd.availableKernelModules = lib.mkForce [
  #  "squashfs"
  #  "overlay"
  #  "loop"
  #  "vfat"
  #  "nls_cp437"
  #  "nls_iso8859-1"
    # The SD controller and anything else needed *before* rootfs is mounted,
    # but only if they're modules in your kernel. Skip built-ins:
    # "sdhci_am654"
  ];

  boot.initrd.kernelModules = lib.mkForce [ ];

  boot.kernelPackages = pkgs.linuxPackagesFor kernel;

  boot.loader.grub.enable = false;
  sdImage = {
    imageName = "nixos-am64x.img";
    compressImage = false;

    firmwareSize = 1024; # MiB
    firmwarePartitionName = "BOOT";

    storePaths = [ ];
    populateRootCommands = "";
    expandOnBoot = false;

    populateFirmwareCommands = ''
      cp ${tiboot3} firmware/tiboot3.bin
      cp ${tispl}   firmware/tispl.bin
      cp ${uboot}   firmware/u-boot.img

      cp ${kernel}/Image firmware/Image
      cp ${kernel}/dtbs/ti/${dtbName} firmware/${dtbName}
      cp ${config.system.build.netbootRamdisk}/initrd firmware/initrd

      cp ${bootScr} firmware/boot.scr
    '';

    # The AM64x ROM wants the FAT boot partition flagged active.
    postBuildCommands = ''
      sfdisk --activate $img 1
    '';
  };
}
