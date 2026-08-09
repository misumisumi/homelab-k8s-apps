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
        # The control plane components (kube-controller-manager, kube-scheduler,
        # kube-proxy) run as systemd units and do not expose their metrics to
        # Prometheus, which produces false KubeControllerManagerDown /
        # KubeSchedulerDown / KubeProxyDown alerts. Disable their ServiceMonitors.
        kubeControllerManager.enabled = false;
        kubeScheduler.enabled = false;
        kubeProxy.enabled = false;
      };
    };
  };
}
