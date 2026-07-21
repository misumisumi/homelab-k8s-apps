{ ... }:
let
  vaultUrl = "https://172.16.11.1:8200";
  vaultK8sMountPath = "kubernetes";
  vaultK8sRole = "external-secrets";
in
{
  applications.external-secrets.resources = {
    clusterSecretStores.vault-backend = {
      apiVersion = "external-secrets.io/v1";
      kind = "ClusterSecretStore";
      metadata.name = "vault-backend";
      spec.provider.vault = {
        server = vaultUrl;
        path = "secret";
        version = "v2";
        auth.kubernetes = {
          mountPath = vaultK8sMountPath;
          role = vaultK8sRole;
          serviceAccountRef.name = "external-secrets";
        };
      };
    };

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
            secretKey = "api-token";
            remoteRef = {
              key = "cloudflare";
              property = "api-token";
            };
          }
        ];
      };
    };
  };
}
