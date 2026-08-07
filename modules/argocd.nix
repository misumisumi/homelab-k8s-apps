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
        # SSO via bundled Dex (GitHub connector configured in configs.cm."dex.config")
        dex.enabled = true;
        notifications.enabled = false;
        # TLS terminated by Gateway, so insecure at ArgoCD level
        configs.params."server.insecure" = true;
        # Disable built-in ingress
        server.ingress.enabled = false;
        global.nodeSelector = {
          "role.worker" = "app";
        };
        # 巨大CRD (ApplicationSet等) がclient-side applyのアノテーション上限(256KB)を超えるため、
        # 全アプリでServerSideApplyを使用する。
        # ArgoCD 3.3.2以降では ClientSideApplyMigration=false は不要(一時的な回避策)なので設定しない。
        configs.cm."application.syncOptions" = "ServerSideApply=true";
      };
    };
  };
}
