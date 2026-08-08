{
  applications.kube-prometheus-stack.helm.releases.kube-prometheus-stack.values.grafana = {
    nodeSelector = {
      "role.worker" = "app";
    };
    persistence = {
      enabled = true;
      storageClassName = "ceph-block";
      accessModes = [ "ReadWriteOnce" ];
      size = "10Gi";
    };
    admin.existingSecret = "grafana-admin";
    envFromSecret = "grafana-oauth";
    "grafana.ini" = {
      "auth.github" = {
        enabled = true;
        allow_sign_up = false;
        allowed_organizations = "misumi-homelab";
        allowed_teams = "misumi-homelab:argocd-admin";
        client_id = "\$__env{GF_AUTH_GITHUB_CLIENT_ID}";
        client_secret = "\$__env{GF_AUTH_GITHUB_CLIENT_SECRET}";
        role_attribute_path = "contains(groups[*], 'misumi-homelab:argocd-admin') && 'Admin' || 'Viewer'";
      };
    };
  };
}
