{
  applications.kube-prometheus-stack.helm.releases.kube-prometheus-stack.values.alertmanager.alertmanagerSpec = {
    nodeSelector = {
      "role.worker" = "app";
    };
    storage.volumeClaimTemplate.spec = {
      storageClassName = "ceph-block";
      accessModes = [ "ReadWriteOnce" ];
      resources.requests.storage = "10Gi";
    };
  };
}
