{ charts, lib, ... }:
let
  inherit (lib) nixdyGenerators;
in
{
  nixidy.applicationImports = [
    (nixdyGenerators.fromChartCRDModule {
      name = "external-secrets";
      chart = charts.external-secrets.external-secrets;
      extraOpts = [
        "--set"
        "installCRDs=true"
      ];
    })
  ];

  applications.external-secrets = {
    namespace = "external-secrets";
    createNamespace = true;

    helm.releases.external-secrets = {
      chart = charts.external-secrets.external-secrets;
      values.installCRDs = true;
    };

    resources = {
    };
  };
}
