final: prev: {
  u-boot-phycore-am64x-a53 = final.callPackage ../u-boot-phytec.nix { };
  linux-phytec-ti = final.callPackage ../linux-phytec.nix { };
  pkgsCross.arm-embedded = prev.pkgsCross.arm-embedded // {
    u-boot-phycore-am64x-r5 = prev.pkgsCross.arm-embedded.callPackage ../u-boot-phytec-r5.nix { };
  };
  arm-trusted-firmware-k3 = final.buildArmTrustedFirmware rec {
    version = "lts-v2.14.1";
    src = final.fetchFromGitHub {
      owner = "ARM-software";
      repo = "arm-trusted-firmware";
      rev = version;
      sha256 = "sha256-K6Nl9rWv8g2FiveuI+HCuQMeQ1UQy6FXw+KnUgTse9c=";
    };
    platform = "k3";
    extraMakeFlags = [
      "TARGET_BOARD=lite"
      "bl31"
    ];
    filesToInstall = [
      "build/k3/lite/release/bl31.bin"
    ];
  };
}
