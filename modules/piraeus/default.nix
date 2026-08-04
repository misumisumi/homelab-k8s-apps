{
  charts,
  lib,
  ...
}:
let
  inherit (lib) nixdyGenerators;
  piraeusNamespace = "piraeus-datastore";
in
{
  nixidy.applicationImports = [
    (nixdyGenerators.fromChartCRDModule {
      name = "piraeus-operator";
      chart = charts.piraeus-operator.piraeus;
      extraOpts = [
        "--set"
        "installCRDs=true"
      ];
    })
  ];

  applications.piraeus = {
    namespace = piraeusNamespace;
    createNamespace = true;

    helm.releases.piraeus-operator = {
      chart = charts.piraeus-operator.piraeus;
      values.installCRDs = true;
    };

    resources = {
      externalSecrets.piraeus-master-passphrase = {
        apiVersion = "external-secrets.io/v1";
        kind = "ExternalSecret";
        metadata = {
          name = "piraeus-master-passphrase";
          namespace = piraeusNamespace;
        };
        spec = {
          refreshInterval = "1h";
          secretStoreRef = {
            name = "vault-backend";
            kind = "ClusterSecretStore";
          };
          target = {
            name = "linstor-passphrase";
            creationPolicy = "Owner";
          };
          data = [
            {
              secretKey = "MASTER_PASSPHRASE";
              remoteRef = {
                key = "piraeus";
                property = "master_passphrase";
              };
            }
          ];
        };
      };

      linstorClusters.linstorcluster = {
        metadata.name = "linstorcluster";
        spec.linstorPassphraseSecret = "linstor-passphrase";
      };
    };
  };
}
