{ lib, ... }:
let
  inherit (lib) importYAML;
in
{
  applications.external-secrets.resources = {
    clusterSecretStores.vault-backend = importYAML ./vault-backend.yaml;
  };
}
