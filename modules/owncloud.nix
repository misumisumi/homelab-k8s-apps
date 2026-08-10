{
  charts,
  ...
}:
{
  applications.owncloud = {
    namespace = "owncloud";
    createNamespace = true;

    helm.releases.ocis = {
      chart = charts.owncloud.ocis;
      # Let the chart render its ServiceMonitor (CRDs are not detectable
      # during helm template).
      extraOpts = [ "--api-versions" "monitoring.coreos.com/v1" ];

      values = {
        ingress.enabled = false;
        replicas = 1;
        monitoring.enabled = true;
        # Initial admin account comes from Vault via external-secrets (see branch config).
        secretRefs.adminUserSecretRef = "admin-user";
      };
    };
  };
}
