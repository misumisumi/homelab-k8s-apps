{
  charts,
  ...
}:
{
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
        # Disable built-in ingress
        server.ingress.enabled = false;
        global.nodeSelector = {
          "role.worker" = "app";
        };
      };
    };
  };
}
