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
    rev = "v${version}-phy3";
    sha256 = "sha256-NB5IXBAuJFkL8gEmv3FhrBrq9QfuJQjnmxNkSEd3cBE=";
  };
  defconfig = "phytec_ti_defconfig";

  enableCommonConfig = false;
  autoModules = false;

  structuredExtraConfig = with lib.kernel; {
    SQUASHFS = yes;
    SQUASHFS_ZLIB = yes;
    SQUASHFS_XZ = yes;
    SQUASHFS_ZSTD = yes;
    SQUASHFS_CHOICE_DECOMP_BY_MOUNT = yes;

    OVERLAY_FS = yes;
    BLK_DEV_LOOP = yes;
    TMPFS = yes;
    VFAT_FS = yes;
  };
}
