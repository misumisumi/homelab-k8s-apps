{
  applications.kube-prometheus-stack.resources.externalSecrets = {
    # Grafana admin credentials, fetched from vault via external-secrets.
    grafana-admin = {
      apiVersion = "external-secrets.io/v1";
      kind = "ExternalSecret";
      metadata = {
        name = "grafana-admin";
        namespace = "monitoring";
      };
      spec = {
        refreshInterval = "1h";
        secretStoreRef = {
          name = "vault-backend";
          kind = "ClusterSecretStore";
        };
        target = {
          name = "grafana-admin";
          creationPolicy = "Owner";
        };
        data = [
          {
            secretKey = "admin-user";
            remoteRef = {
              key = "grafana";
              property = "admin_user";
            };
          }
          {
            secretKey = "admin-password";
            remoteRef = {
              key = "grafana";
              property = "admin_password";
            };
          }
        ];
      };
    };

    # GitHub OAuth credentials for Grafana, fetched from vault.
    grafana-oauth = {
      apiVersion = "external-secrets.io/v1";
      kind = "ExternalSecret";
      metadata = {
        name = "grafana-oauth";
        namespace = "monitoring";
      };
      spec = {
        refreshInterval = "1h";
        secretStoreRef = {
          name = "vault-backend";
          kind = "ClusterSecretStore";
        };
        target = {
          name = "grafana-oauth";
          creationPolicy = "Owner";
        };
        data = [
          {
            secretKey = "GF_AUTH_GITHUB_CLIENT_ID";
            remoteRef = {
              key = "grafana";
              property = "github_client_id";
            };
          }
          {
            secretKey = "GF_AUTH_GITHUB_CLIENT_SECRET";
            remoteRef = {
              key = "grafana";
              property = "github_client_secret";
            };
          }
        ];
      };
    };
  };
}
