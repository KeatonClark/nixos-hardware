{
  buildUBoot,
  fetchFromGitHub,
  fetchurl,
}:
let
  phytecDownload = "https://download.phytec.de/Software/Linux/BSP-Yocto-AM64x/BSP-Yocto-Ampliphy-AM64x-PD26.1.0/images/ampliphy/phyboard-electra-am64xx-2";
  BL31 = fetchurl {
    url = "${phytecDownload}/trusted-firmware-a/bl31.bin";
    hash = "sha256-IqqZSg8hZtyu++hMwO2ZHHLP0PQ9J1CTYper1CHf7Yc=";
  };
in
buildUBoot rec {
  pname = "u-boot-phytec";
  version = "2026.01";
  src = fetchFromGitHub {
    owner = "phytec";
    repo = pname;
    rev = "v${version}-phy3";
    sha256 = "sha256-fE6Ef2FVP3ZBukmaK8UoPYNIVVQEuW24nKDRIj/u7lE=";
  };
  filesToInstall = [
    "u-boot.img"
    "tispl.bin"
  ];
  extraConfig = ''
    CONFIG_CMD_SYSBOOT=y
    CONFIG_BOOTSTD=y
    CONFIG_BOOTMETH_EXTLINUX=y
  '';
  defconfig = "phycore_am64x_a53_defconfig";
  env = { inherit BL31; };
}
