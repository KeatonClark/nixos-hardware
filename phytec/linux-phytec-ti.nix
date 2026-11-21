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

  enableCommonConfig = true;
  ignoreConfigErrors = true;
  autoModules = false;

  structuredExtraConfig = with lib.kernel; {
    NF_TABLES = yes;
    NF_TABLES_INET = yes;
    NF_TABLES_IPV4 = yes;
    NF_TABLES_IPV6 = yes;
    NETFILTER_NETLINK = yes;
    NF_CONNTRACK = yes;

    NFT_CT = yes;
    NFT_LOG = yes;
    NFT_LIMIT = yes;
    NFT_REJECT = yes;
    NFT_NAT = yes;
    NFT_FIB_IPV4 = yes;
    NFT_FIB_IPV6 = yes;
    NFT_FIB_INET = yes;

    NFT_COMPAT = module;
    NETFILTER_XTABLES = module;
    NETFILTER_XT_MATCH_PKTTYPE = module;
    NETFILTER_XT_MATCH_LIMIT = module;
    NETFILTER_XT_MATCH_CONNTRACK = module;
    IP_NF_IPTABLES = module;
    IP_NF_FILTER = module;
    IP_NF_RAW = module;
    IP_NF_MATCH_RPFILTER = module;
    IP_NF_TARGET_REJECT = module;
    IP6_NF_IPTABLES = module;
    IP6_NF_FILTER = module;
    IP6_NF_RAW = module;
    IP6_NF_MATCH_RPFILTER = module;
    IP6_NF_TARGET_REJECT = module;
  };
}
