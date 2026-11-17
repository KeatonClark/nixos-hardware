{
  buildLinux,
  fetchFromGitHub,
  lib,
  ...
}:
buildLinux rec {
  pname = "linux-phytec";
  version = "6.18.35";
  src = fetchFromGitHub {
    owner = "phytec";
    repo = pname;
    rev = "v${version}";
    sha256 = "sha256-NB5IXBAuJFkL8gEmv3FhrBrq9QfuJQjnmxNkSEd3cBE=";
  };
  defconfig = "phytec_ti_defconfig";

  enableCommonConfig = false;
  autoModules = false;

  structuredExtraConfig = with lib.kernel; {
    OVERLAY_FS = yes;
    BLK_DEV_LOOP = yes;
    TMPFS = yes;
    VFAT_FS = yes;
    MMC_SDHCI_AM654 = yes;
  };
}
