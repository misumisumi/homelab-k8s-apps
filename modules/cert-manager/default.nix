{
  charts,
  lib,
  ...
}:
let
  inherit (lib) importYAML nixdyGenerators;
in
{
  nixidy.applicationImports = [
    (nixdyGenerators.fromChartCRDModule {
      name = "cert-manager";
      chart = charts.jetstack.cert-manager;
      extraOpts = [
        "--set"
        "crds.enabled=true"
      ];
    })
  ];
  applications.cert-manager = {
    namespace = "cert-manager";
    createNamespace = true;

    helm.releases.cert-manager = {
      chart = charts.jetstack.cert-manager;
      values = {
        crds.enabled = true;
        nodeSelector = {
          "role.worker" = "app";
        };
      };
    };

    resources = {
      clusterIssuers.letsencrypt-dns = importYAML ./clusterissuer.yaml;

      # secrets for cloudflare API token, fetched from vault via external-secrets
      externalSecrets.cloudflare-api-token = {
        apiVersion = "external-secrets.io/v1";
        kind = "ExternalSecret";
        metadata = {
          name = "cloudflare-api-token";
          namespace = "cert-manager";
        };
        spec = {
          refreshInterval = "1h";
          secretStoreRef = {
            name = "vault-backend";
            kind = "ClusterSecretStore";
          };
          target = {
            name = "cloudflare-api-token";
            creationPolicy = "Owner";
          };
          data = [
            {
              secretKey = "api_token";
              remoteRef = {
                key = "cloudflare";
                property = "api_token";
              };
            }
          ];
        };
      };

      serviceMonitors = {
        cert-manager = {
          apiVersion = "monitoring.coreos.com/v1";
          kind = "ServiceMonitor";
          metadata = {
            name = "cert-manager";
            namespace = "cert-manager";
          };
          spec = {
            selector.matchLabels."app.kubernetes.io/name" = "cert-manager";
            endpoints = [
              {
                port = "http-metrics";
                interval = "30s";
              }
            ];
          };
        };
        cainjector = {
          apiVersion = "monitoring.coreos.com/v1";
          kind = "ServiceMonitor";
          metadata = {
            name = "cert-manager-cainjector";
            namespace = "cert-manager";
          };
          spec = {
            selector.matchLabels."app.kubernetes.io/name" = "cainjector";
            endpoints = [
              {
                port = "http-metrics";
                interval = "30s";
              }
            ];
          };
        };
        webhook = {
          apiVersion = "monitoring.coreos.com/v1";
          kind = "ServiceMonitor";
          metadata = {
            name = "cert-manager-webhook";
            namespace = "cert-manager";
          };
          spec = {
            selector.matchLabels."app.kubernetes.io/name" = "webhook";
            endpoints = [
              {
                port = "metrics";
                interval = "30s";
              }
            ];
          };
        };
      };
    };
  };
}
