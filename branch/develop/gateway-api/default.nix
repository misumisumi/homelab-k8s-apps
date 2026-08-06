{ lib, ... }:
let
  inherit (lib) importYAML;
in
{
  applications.gateway-api.resources = {
    gateways.public-gateway = importYAML ./public-gateway.yaml;
  };
}
