final: prev: {
  u-boot-phycore-am64x-a53 = final.callPackage ../u-boot-phytec.nix { };
  linux-phytec-ti = final.callPackage ../linux-phytec.nix { };
  pkgsCross.arm-embedded = prev.pkgsCross.arm-embedded // {
    u-boot-phycore-am64x-r5 = prev.pkgsCross.arm-embedded.callPackage ../u-boot-phytec-r5.nix { };
  };
}
