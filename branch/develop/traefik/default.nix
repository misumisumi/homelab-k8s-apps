{ lib, ... }:
let
  inherit (lib) importYAML;
in
{
  applications.traefik.resources = {
    httpRoutes.traefik-dashboard = importYAML ./dashboard-httproute.yaml;
    referenceGrants.allow-traefik-dashboard = importYAML ./dashboard-referencegrant.yaml;
  };
}
