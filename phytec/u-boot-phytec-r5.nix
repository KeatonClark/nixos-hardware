{
  buildUBoot,
  fetchFromGitHub,
  buildPackages,
}:
let
  tiLinuxFirmware = fetchFromGitHub {
    owner = "TexasInstruments";
    repo = "ti-linux-firmware";
    rev = "11.02.21";
    sha256 = "sha256-MmpIm9tCVDNUhRpByewR+kIDR7FEXTjuk55YUgH04zo=";
  };
in (buildUBoot rec {
  pname = "u-boot-phytec";
  version = "2026.01";
  src = fetchFromGitHub {
    owner = "phytec";
    repo = pname;
    rev = "v${version}-phy3";
    sha256 = "sha256-fE6Ef2FVP3ZBukmaK8UoPYNIVVQEuW24nKDRIj/u7lE=";
  };
  filesToInstall = [
    "tiboot3.bin"
  ];
  defconfig = "phycore_am64x_r5_defconfig";
  env = {
    BINMAN_INDIRS=tiLinuxFirmware;
  };
}).overrideAttrs (old: {
  nativeBuildInputs = [
    (buildPackages.python3.withPackages (ps: with ps; [
      pyyaml
      yamllint
      jsonschema
      libfdt
      setuptools
      pyelftools
    ]))
  ] ++ (old.nativeBuildInputs or []);
})
