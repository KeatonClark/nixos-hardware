{
  buildUBoot,
  fetchFromGitHub,
  stdenv,
  buildPackages,
  arm-trusted-firmware-k3,
  optee-os-k3-am64x
}:
let
  BL31 = "${arm-trusted-firmware-k3}/bl31.bin";
  TEE = "${optee-os-k3-am64x}/tee-raw.bin";
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
  env = {
    inherit BL31 TEE;
  };
}
