{
  applications.kube-prometheus-stack.helm.releases.kube-prometheus-stack.values.prometheus.prometheusSpec = {
    nodeSelector = {
      "role.worker" = "app";
    };
    retention = "10d";
    # Select all ServiceMonitors, PodMonitors and PrometheusRules in every
    # namespace (the default is to only match `release: kube-prometheus-stack`).
    serviceMonitorSelectorNilUsesHelmValues = false;
    podMonitorSelectorNilUsesHelmValues = false;
    ruleSelectorNilUsesHelmValues = false;
    storageSpec.volumeClaimTemplate.spec = {
      storageClassName = "ceph-block";
      accessModes = [ "ReadWriteOnce" ];
      resources.requests.storage = "20Gi";
    };
  };
}
