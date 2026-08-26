{
  applications.kube-prometheus-stack.helm.releases.kube-prometheus-stack.values.grafana = {
    nodeSelector = {
      "role.worker" = "app";
    };
    # Give the first-start DB migration time before the readiness probe
    # restarts the container.
    readinessProbe = {
      httpGet = {
        path = "/api/health";
        port = 3000;
      };
      initialDelaySeconds = 60;
      periodSeconds = 10;
      timeoutSeconds = 1;
      failureThreshold = 10;
      successThreshold = 1;
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
      # Pin the external URL so OAuth redirect_uri is https and matches the
      # callback registered in the GitHub OAuth App (the gateway terminates TLS).
      "server" = {
        domain = "grafana.dev.misumi-sumi.com";
        root_url = "https://grafana.dev.misumi-sumi.com";
      };
      "auth.github" = {
        enabled = true;
        allow_sign_up = true;
        allowed_organizations = "misumi-homelab";
        allowed_teams = "misumi-homelab:homelab-admin";
        client_id = "\$__env{GF_AUTH_GITHUB_CLIENT_ID}";
        client_secret = "\$__env{GF_AUTH_GITHUB_CLIENT_SECRET}";
        role_attribute_path = "contains(groups[*], 'misumi-homelab:homelab-admin') && 'Admin' || 'Viewer'";
      };
    };
  };
}
