{ lib, ... }:
let
  inherit (lib) importYAML;
in
{
  applications.argocd = {
    helm.releases.argocd.values = {
      # External URL for ArgoCD
      configs.cm.url = "https://argocd.dev.misumi-sumi.com";
      # SSO via bundled Dex: GitHub connector configuration.
      # issuer/storage/staticClients are managed by ArgoCD itself.
      configs.cm."dex.config" = ''
        connectors:
          - type: github
            id: github
            name: GitHub
            config:
              clientID: $dex.github.clientID
              clientSecret: $dex.github.clientSecret
              orgs:
                - name: misumi-homelab
                  teams:
                    - argocd-admin
      '';
      # No explicit oidc.config: ArgoCD derives the Dex client secret from
      # server.secretkey (matching the bundled Dex static client) and requests
      # the default scopes including "groups" for RBAC.
      # GitHub SSO RBAC: misumi-homelab:argocd-admin team members are admins,
      # all other org members get read-only.
      configs.rbac."policy.csv" = "g, misumi-homelab:argocd-admin, role:admin";
      configs.rbac."policy.default" = "role:readonly";
    };
    resources = {
      httpRoutes.argocd = importYAML ./httproute.yaml;
      referenceGrants.allow-argocd-server = importYAML ./referencegrant.yaml;
      # GitHub OAuth App credentials used by the bundled Dex connector,
      # injected into the Helm-managed argocd-secret.
      externalSecrets.argocd-dex-client = {
        apiVersion = "external-secrets.io/v1";
        kind = "ExternalSecret";
        metadata = {
          name = "argocd-dex-client";
          namespace = "argocd";
        };
        spec = {
          refreshInterval = "1h";
          secretStoreRef = {
            name = "vault-backend";
            kind = "ClusterSecretStore";
          };
          target = {
            name = "argocd-secret";
            creationPolicy = "Merge";
          };
          data = [
            {
              secretKey = "dex.github.clientID";
              remoteRef = {
                key = "argocd";
                property = "github_client_id";
              };
            }
            {
              secretKey = "dex.github.clientSecret";
              remoteRef = {
                key = "argocd";
                property = "github_client_secret";
              };
            }
          ];
        };
      };
    };
  };
}
