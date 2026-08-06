{ lib, ... }:
let
  inherit (lib) importYAML;
in
{
  applications.argocd = {
    helm.releases.argocd.values = {
      # External URL for ArgoCD
      configs.cm.url = "https://argocd.dev.misumi-sumi.com";
    };
    resources = {
      httpRoutes.argocd = importYAML ./httproute.yaml;
      referenceGrants.allow-argocd-server = importYAML ./referencegrant.yaml;
    };
  };
}
