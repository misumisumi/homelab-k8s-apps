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
        # Underlying NIC is 1500 MTU; VXLAN (tunnel mode) adds 50B overhead.
        # Without this, cilium auto-detects 1500 and large packets get
        # blackholed (slow TCP, broken UDP DNS from pods).
        mtu = 1450;
        hubble = {
          enabled = true;
          relay.enabled = true;
          ui.enabled = true;
          # Enable hubble-relay Prometheus metrics and its ServiceMonitor.
          relay.prometheus = {
            enabled = true;
            serviceMonitor = {
              enabled = true;
              trustCRDsExist = true;
            };
          };
          metrics.enabled = [
            "dns:query;ignoreAAAA"
            "drop"
            "tcp"
            "flow"
            "icmp"
            "port-distribution"
          ];
        };
        # Cilium agent metrics + ServiceMonitor (port 9962)
        prometheus = {
          enabled = true;
          serviceMonitor = {
            enabled = true;
            trustCRDsExist = true;
          };
        };
        # Cilium operator metrics + ServiceMonitor (port 9963)
        operator.prometheus.serviceMonitor = {
          enabled = true;
          trustCRDsExist = true;
        };
        # Cilium envoy metrics + ServiceMonitor (port 9964)
        envoy.prometheus.serviceMonitor = {
          enabled = true;
          trustCRDsExist = true;
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
        l2NeighDiscovery.enabled = true;
      };
    };

    resources = {
      ciliumBGPPeerConfigs.peer = importYAML ./bgp/peer.yaml;
      ciliumClusterwideNetworkPolicies.cluster = importYAML ./network-policies/cluster.yaml;
    };

    yamls = map toJSON (
      generators.crdObjects {
        inherit (extraPkgs.cilium) src;
        inherit crdFiles;
      }
    );
  };
}
