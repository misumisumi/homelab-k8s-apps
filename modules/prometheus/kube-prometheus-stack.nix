{ charts, ... }:
{
  applications.kube-prometheus-stack = {
    namespace = "monitoring";
    createNamespace = true;

    helm.releases.kube-prometheus-stack = {
      chart = charts.prometheus-community.kube-prometheus-stack;

      values.global.nodeSelector = {
        "role.worker" = "app";
      };
    };
  };
}
