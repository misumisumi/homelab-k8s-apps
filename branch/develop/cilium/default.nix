{ lib, ... }:
let
  inherit (lib) importYAML;
in
{
  applications.cilium = {
    helm.releases.cilium.values = {
      k8sServiceHost = "172.16.100.100";
      k8sServicePort = 443;
    };

    resources = {
      ciliumBGPAdvertisements.advertisement = importYAML ./bgp/advertisement.yaml;
      ciliumBGPClusterConfigs.cluster = importYAML ./bgp/cluster.yaml;
      ciliumLoadBalancerIPPools.default-pool = importYAML ./lb/ippool.yaml;
      httpRoutes.hubble-ui = importYAML ./hubble/httproute.yaml;
    };
  };
}
