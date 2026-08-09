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
    # Config (with the Discord webhook receiver) is rendered by
    # external-secrets so the webhook URL never appears in git.
    configSecret = "alertmanager-config";
  };
}
