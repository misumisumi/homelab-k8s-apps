{
  charts,
  lib,
  generators,
  ...
}:
let
  inherit (lib) importYAML extraPkgs;

  crdFiles = [
    "manifests/crds/application-crd.yaml"
    # "manifests/crds/applicationset-crd.yaml"
    # "manifests/crds/appproject-crd.yaml"
    # "manifests/crds/kustomization.yaml"
  ];
in
{
  # nixidy.applicationImports = [
  #   (generators.fromCRDModule {
  #     name = "argocd";
  #     inherit (extraPkgs.argocd) src;
  #     inherit crdFiles;
  #   })
  # ];
  applications.argocd = {
    namespace = "argocd";
    createNamespace = true;

    helm.releases.argocd = {
      chart = charts.argoproj.argo-cd;

      values = {
        # No SSO for homelab
        dex.enabled = false;
        notifications.enabled = false;

        # TLS terminated by Gateway, so insecure at ArgoCD level
        configs.params."server.insecure" = true;

        # External URL for ArgoCD
        configs.cm.url = "https://argocd.k8s.misumi-sumi.com";

        # Disable built-in ingress
        server.ingress.enabled = false;
      };
    };

    resources = {
      gateways.argocd-gateway = importYAML ./gateway.yaml;
      httpRoutes.argocd = importYAML ./httproute.yaml;
      referenceGrants.allow-argocd-server = importYAML ./referencegrant.yaml;
    };
  };
}
