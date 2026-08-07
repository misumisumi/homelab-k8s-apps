{ charts, lib, ... }:
let
  inherit (lib) nixdyGenerators;
in
{
  nixidy.applicationImports = [
    (nixdyGenerators.fromChartCRDModule {
      name = "kube-prometheus-stack";
      chart = charts.prometheus-community.kube-prometheus-stack;
      extraOpts = [
        "--set"
        "crds.enabled=true"
      ];
    })
  ];

  applications.kube-prometheus-stack = {
    namespace = "monitoring";
    createNamespace = true;

    helm.releases.kube-prometheus-stack = {
      chart = charts.prometheus-community.kube-prometheus-stack;
      values = {
        global.nodeSelector = {
          "role.worker" = "app";
        };
        prometheus = {
          prometheusSpec = {
            nodeSelector = {
              "role.worker" = "app";
            };
            retention = "10d";
            storageSpec.volumeClaimTemplate = {
              spec = {
                storageClassName = "ceph-block";
                accessModes = [ "ReadWriteOnce" ];
                resources.requests.storage = "20Gi";
              };
            };
          };
        };
        alertmanager = {
          alertmanagerSpec = {
            nodeSelector = {
              "role.worker" = "app";
            };
            storage = {
              volumeClaimTemplate = {
                spec = {
                  storageClassName = "ceph-block";
                  accessModes = [ "ReadWriteOnce" ];
                  resources.requests.storage = "10Gi";
                };
              };
            };
          };
        };
        grafana = {
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
      };
    };

    resources = {
      # Force server-side apply on the large CRDs to avoid the 256KB
      # last-applied-configuration annotation limit.
      customResourceDefinitions = {
        "prometheuses.monitoring.coreos.com" = {
          metadata.annotations."argocd.argoproj.io/sync-options" = lib.mkForce "ServerSideApply=true";
        };
        "alertmanagers.monitoring.coreos.com" = {
          metadata.annotations."argocd.argoproj.io/sync-options" = lib.mkForce "ServerSideApply=true";
        };
        "alertmanagerconfigs.monitoring.coreos.com" = {
          metadata.annotations."argocd.argoproj.io/sync-options" = lib.mkForce "ServerSideApply=true";
        };
        "scrapeconfigs.monitoring.coreos.com" = {
          metadata.annotations."argocd.argoproj.io/sync-options" = lib.mkForce "ServerSideApply=true";
        };
        "prometheusagents.monitoring.coreos.com" = {
          metadata.annotations."argocd.argoproj.io/sync-options" = lib.mkForce "ServerSideApply=true";
        };
        "thanosrulers.monitoring.coreos.com" = {
          metadata.annotations."argocd.argoproj.io/sync-options" = lib.mkForce "ServerSideApply=true";
        };
      };

      # Grafana admin credentials, fetched from vault via external-secrets.
      externalSecrets.grafana-admin = {
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
      externalSecrets.grafana-oauth = {
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
  };
}
