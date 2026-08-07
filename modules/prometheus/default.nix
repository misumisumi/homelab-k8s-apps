{ charts, lib, ... }:
let
  inherit (lib) nixdyGenerators;
in
{
  imports = [
    ./kube-prometheus-stack.nix
    ./prometheus.nix
    ./alertmanager.nix
    ./grafana.nix
    ./crds.nix
    ./external-secrets.nix
  ];

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
}
