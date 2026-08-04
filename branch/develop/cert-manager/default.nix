{ lib, ... }:
let
  inherit (lib) importYAML;
in
{
  applications.cert-manager.resources = {
    certificates.wildcard-misumi-sumi-com = importYAML ./wildcard-certificate.yaml;
  };
}
