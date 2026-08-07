{ lib, ... }:
let
  inherit (lib) importYAML;
in
{
  applications.kube-prometheus-stack.resources = {
    httpRoutes.grafana = importYAML ./httproute.yaml;
    referenceGrants.allow-grafana = importYAML ./referencegrant.yaml;
  };
}
