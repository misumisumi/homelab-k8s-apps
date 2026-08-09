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

    # AlertManager config with the Discord webhook receiver, rendered from
    # vault so the webhook URL stays out of git.
    alertmanager-config = {
      apiVersion = "external-secrets.io/v1";
      kind = "ExternalSecret";
      metadata = {
        name = "alertmanager-config";
        namespace = "monitoring";
      };
      spec = {
        refreshInterval = "1h";
        secretStoreRef = {
          name = "vault-backend";
          kind = "ClusterSecretStore";
        };
        target = {
          name = "alertmanager-config";
          creationPolicy = "Owner";
          template = {
            engineVersion = "v2";
            data = {
              "alertmanager.yaml" = ''
                route:
                  group_by: ['alertname']
                  group_wait: 30s
                  group_interval: 5m
                  repeat_interval: 4h
                  receiver: discord
                receivers:
                  - name: discord
                    discord_configs:
                      - webhook_url: '{{ .discordWebhookUrl }}'
                        send_resolved: true
              '';
            };
          };
        };
        data = [
          {
            secretKey = "discordWebhookUrl";
            remoteRef = {
              key = "alertmanager";
              property = "discord_webhook_url";
            };
          }
        ];
      };
    };
  };
}
