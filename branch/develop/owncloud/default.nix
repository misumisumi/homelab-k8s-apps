{ lib, ... }:
let
  inherit (lib) importYAML;
in
{
  applications.owncloud = {
    helm.releases.ocis.values = {
      externalDomain = "owncloud.dev.misumi-sumi.com";
      nodeSelector = {
        "role.worker" = "piraeus";
      };

      services.storagesystem.persistence = {
        enabled = true;
        storageClassName = "linstor-hdd-pool";
        size = "1Gi";
        accessModes = [ "ReadWriteOnce" ];
      };
      services.storageusers.persistence = {
        enabled = true;
        storageClassName = "linstor-hdd-pool";
        size = "4Gi";
        accessModes = [ "ReadWriteOnce" ];
      };
      services.idm.persistence = {
        enabled = true;
        storageClassName = "linstor-hdd-pool";
        size = "1Gi";
        accessModes = [ "ReadWriteOncePod" ];
      };
      services.nats.persistence = {
        enabled = true;
        storageClassName = "linstor-hdd-pool";
        size = "1Gi";
        accessModes = [ "ReadWriteOncePod" ];
      };
      services.search.persistence = {
        enabled = true;
        storageClassName = "linstor-hdd-pool";
        size = "1Gi";
        accessModes = [ "ReadWriteOncePod" ];
      };
      services.thumbnails.persistence = {
        enabled = true;
        storageClassName = "linstor-hdd-pool";
        size = "1Gi";
        accessModes = [ "ReadWriteOnce" ];
      };
      services.web.persistence = {
        enabled = true;
        storageClassName = "linstor-hdd-pool";
        size = "1Gi";
        accessModes = [ "ReadWriteOnce" ];
      };
    };

    resources = {
      httpRoutes.owncloud = importYAML ./httproute.yaml;
      referenceGrants.allow-owncloud = importYAML ./referencegrant.yaml;

      externalSecrets.owncloud-admin-user = {
        apiVersion = "external-secrets.io/v1";
        kind = "ExternalSecret";
        metadata = {
          name = "owncloud-admin-user";
          namespace = "owncloud";
        };
        spec = {
          refreshInterval = "1h";
          secretStoreRef = {
            name = "vault-backend";
            kind = "ClusterSecretStore";
          };
          target = {
            name = "admin-user";
            creationPolicy = "Owner";
          };
          data = [
            {
              secretKey = "user-id";
              remoteRef = {
                key = "owncloud";
                property = "admin_user_id";
              };
            }
            {
              secretKey = "password";
              remoteRef = {
                key = "owncloud";
                property = "admin_password";
              };
            }
          ];
        };
      };
    };
  };
}
