{
  buildUBoot,
  fetchFromGitHub,
  buildPackages,
  ti-linux-firmware,
}:
(buildUBoot rec {
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
    BINMAN_INDIRS=ti-linux-firmware;
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
