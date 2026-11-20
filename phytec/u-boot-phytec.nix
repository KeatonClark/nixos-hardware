{
  buildUBoot,
  fetchFromGitHub,
  stdenv,
  buildPackages,
  arm-trusted-firmware-k3,
}:
let
  optee-os = stdenv.mkDerivation rec {
    pname = "optee_os";
    version = "4.11.0";
    src = fetchFromGitHub {
      owner = "OP-TEE";
      repo = pname;
      rev = version;
      sha256 = "sha256-d/E1FaP7NmSRQyWx9Gly3QjCW31H+xkiB5Ih8u5n00o=";
    };
    nativeBuildInputs = [
      (buildPackages.python3.withPackages (ps: with ps; [
        cryptography
        pyelftools
      ]))
      buildPackages.makeWrapper
    ];

    enableParallelBuilding = true;

    makeFlags = [
      "PLATFORM=k3-am64x"
      "CFG_ARM64_core=y"
      "CROSS_COMPILE_core=${stdenv.cc.targetPrefix}"
      "CROSS_COMPILE_ta_arm64=${stdenv.cc.targetPrefix}"
      "ta-targets=ta_arm64"
    ];

    postPatch = ''
      patchShebangs scripts/
      patchShebangs ta/pkcs11/scripts/
    '';

    installPhase = ''
      mkdir -p $out
      install -m0644 ./out/arm-plat-k3/core/tee-raw.bin $out/
    '';
  };
  BL31 = "${arm-trusted-firmware-k3}/bl31.bin";
  TEE = "${optee-os}/tee-raw.bin";
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
