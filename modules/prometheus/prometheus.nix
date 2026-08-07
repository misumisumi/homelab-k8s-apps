{
  applications.kube-prometheus-stack.helm.releases.kube-prometheus-stack.values.prometheus.prometheusSpec = {
    nodeSelector = {
      "role.worker" = "app";
    };
    retention = "10d";
    storageSpec.volumeClaimTemplate.spec = {
      storageClassName = "ceph-block";
      accessModes = [ "ReadWriteOnce" ];
      resources.requests.storage = "20Gi";
    };
  };
}
