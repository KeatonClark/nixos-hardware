final: prev: {
  linux-phytec-ti = final.callPackage ./linux-phytec-ti.nix { };

  ti-linux-firmware = final.fetchFromGitHub {
    owner = "TexasInstruments";
    repo = "ti-linux-firmware";
    rev = "12.01.00.06";
    sha256 = "sha256-bWWAR8JUVYMSaZ1tzDKd8AlMcIxN4Cb5qct3M1VR2dc=";
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
      "SPD=opteed"
      "bl31"
    ];
    filesToInstall = [
      "build/k3/lite/release/bl31.bin"
    ];
  };

  # am64x packages
  u-boot-phycore-am64x-a53 = final.callPackage ./phycore-am64x/u-boot-phycore-am64x-a53.nix { };
  optee-os-k3-am64x = final.callPackage ./phycore-am64x/optee-os-k3-am64x.nix { };
  pkgsCross.arm-embedded = prev.pkgsCross.arm-embedded // {
    u-boot-phycore-am64x-r5 = prev.pkgsCross.arm-embedded.callPackage ./phycore-am64x/u-boot-phycore-am64x-r5.nix { };
  };
}
