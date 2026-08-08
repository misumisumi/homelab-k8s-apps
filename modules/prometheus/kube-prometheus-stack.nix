{ charts, ... }:
{
  applications.kube-prometheus-stack = {
    namespace = "monitoring";
    createNamespace = true;

    helm.releases.kube-prometheus-stack = {
      chart = charts.prometheus-community.kube-prometheus-stack;

      values = {
        # Place every component on app nodes, except node-exporter which runs
        # as a DaemonSet on all nodes to collect VM/node metrics.
        prometheusOperator.nodeSelector = {
          "role.worker" = "app";
        };
        # Subchart values are passed under the dependency name.
        "kube-state-metrics".nodeSelector = {
          "role.worker" = "app";
        };
      };
    };
  };
}
