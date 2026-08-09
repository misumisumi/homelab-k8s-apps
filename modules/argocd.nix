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
      # Let the chart render its ServiceMonitors (CRDs are not detectable
      # during helm template).
      extraOpts = [ "--api-versions" "monitoring.coreos.com/v1" ];

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
        # healthz?full=true checks all repos (git ops); on small nodes the
        # default 1s liveness timeout triggers restart loops.
        repoServer = {
          livenessProbe.timeoutSeconds = 30;
          readinessProbe.timeoutSeconds = 10;
        };
        # 巨大CRD (ApplicationSet等) がclient-side applyのアノテーション上限(256KB)を超えるため、
        # 全アプリでServerSideApplyを使用する。
        # ArgoCD 3.3.2以降では ClientSideApplyMigration=false は不要(一時的な回避策)なので設定しない。
        configs.cm."application.syncOptions" = "ServerSideApply=true";
        # Expose Prometheus metrics and ServiceMonitors for each component.
        server.metrics = {
          enabled = true;
          serviceMonitor.enabled = true;
        };
        controller.metrics = {
          enabled = true;
          serviceMonitor.enabled = true;
        };
        repoServer.metrics = {
          enabled = true;
          serviceMonitor.enabled = true;
        };
        dex.metrics = {
          enabled = true;
          serviceMonitor.enabled = true;
        };
      };
    };
  };
}
