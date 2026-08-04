{
  charts,
  generators,
  lib,
  ...
}:
let
  inherit (builtins) toJSON;
  inherit (lib) importYAML extraPkgs;

  crdFiles = [
    "pkg/k8s/apis/cilium.io/client/crds/v2/ciliumbgpadvertisements.yaml"
    "pkg/k8s/apis/cilium.io/client/crds/v2/ciliumbgpclusterconfigs.yaml"
    "pkg/k8s/apis/cilium.io/client/crds/v2/ciliumbgpnodeconfigoverrides.yaml"
    "pkg/k8s/apis/cilium.io/client/crds/v2/ciliumbgpnodeconfigs.yaml"
    "pkg/k8s/apis/cilium.io/client/crds/v2/ciliumbgppeerconfigs.yaml"
    "pkg/k8s/apis/cilium.io/client/crds/v2/ciliumclusterwidenetworkpolicies.yaml"
    "pkg/k8s/apis/cilium.io/client/crds/v2/ciliumegressgatewaypolicies.yaml"
    "pkg/k8s/apis/cilium.io/client/crds/v2/ciliumloadbalancerippools.yaml"
    "pkg/k8s/apis/cilium.io/client/crds/v2/ciliumnetworkpolicies.yaml"
  ];
in
{
  nixidy.applicationImports = [
    (generators.fromCRDModule {
      name = "cilium";
      inherit (extraPkgs.cilium) src;
      inherit crdFiles;
    })
  ];
  applications.cilium = {
    namespace = "kube-system";

    helm.releases.cilium = {
      chart = charts.cilium.cilium;

      includeCRDs = true;
      values = {
        kubeProxyReplacement = true;
        identityAllocationMode = "crd";
        hubble = {
          enabled = true;
          relay.enabled = true;
          ui.enabled = true;
        };
        ciliumEndpointSlice = {
          enabled = true;
          rateLimits = [
            {
              nodes = 0;
              limit = 10;
              burst = 20;
            }
            {

              nodes = 100;
              limit = 50;
              burst = 100;
            }
          ];
        };
        hostFirewall.enabled = true;
        bgpControlPlane.enabled = true;
      };
    };

    resources = {
      ciliumBGPPeerConfigs.peer = importYAML ./bgp/peer.yaml;
      ciliumClusterwideNetworkPolicies.cluster = importYAML ./network-policies/cluster.yaml;
      gateways.public-gateway = importYAML ./hubble/gateway.yaml;
    };

    yamls = map toJSON (
      generators.crdObjects {
        inherit (extraPkgs.cilium) src;
        inherit crdFiles;
      }
    );
  };
}
