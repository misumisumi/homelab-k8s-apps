{ lib, ... }:
let
  inherit (lib) importYAML;
in
{
  applications.gateway = {
    namespace = "kube-system";

    resources = {
      gateways.public-gateway = importYAML ./public-gateway.yaml;
    };
  };
}
