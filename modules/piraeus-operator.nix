{
  config,
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
      linstorClusters.linstorcluster = {
        metadata.name = "linstorcluster";
        spec = {
          linstorPassphraseSecret = "linstor-passphrase";
          nodeSelector = {
            "role.worker" = "piraeus";
          };
        };
      };

      # DRBD カーネルモジュールは NixOS 側 (drbd9-dkms) で既にビルド・ロード済みのため、
      # drbd-module-loader は DRBD のビルド/ロードをスキップする (deps_only)。
      # compile モードだと /usr/src (カーネルソース) を要求し、NixOS では失敗する。
      linstorSatelliteConfigurations.skip-drbd-module-loader = {
        metadata.name = "skip-drbd-module-loader";
        spec.podTemplate = {
          spec.initContainers = [
            {
              name = "drbd-module-loader";
              env = [
                {
                  name = "LB_HOW";
                  value = "deps_only";
                }
              ];
            }
          ];
        };
      };
      # master passphrase secret for linstor cluster, fetched from vault via external-secrets
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
    };
  };
}
