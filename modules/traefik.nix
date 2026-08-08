{
  charts,
  ...
}:
{
  applications.traefik = {
    namespace = "traefik";
    createNamespace = true;

    helm.releases.traefik = {
      # Use the traefik helm chart from nixhelm.
      chart = charts.traefik.traefik;

      # Example values to pass to the Helm Chart.
      values = {
        ingressClass.enabled = false;
        ingressRoute.dashboard.enabled = false;
        api = {
          dashboard = true;
          insecure = true;
        };
        metrics.prometheus = {
          entryPoint = "metrics";
          service.enabled = true;
          serviceMonitor.enabled = true;
          disableAPICheck = true;
        };
        experimental.kubernetesGateway.enabled = true;
        gateway = {
          enabled = false;
        };
        gatewayClass.enabled = true;
        nodeSelector = {
          "role.worker" = "app";
        };
        providers = {
          kubernetesIngress.enabled = false;
          kubernetesGateway.enabled = true;
        };
        ports = {
          traefik.expose.default = true;
          web.port = 80;
          websecure.port = 443;
        };
      };
    };
  };
}
