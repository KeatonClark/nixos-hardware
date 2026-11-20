{ stdenv, buildPackages, fetchFromGitHub }:
stdenv.mkDerivation rec {
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
}
