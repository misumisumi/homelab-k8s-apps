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
      serviceAccounts.vault-token-reviewer = {
        apiVersion = "v1";
        kind = "ServiceAccount";
        metadata = {
          name = "vault-token-reviewer";
          namespace = "kube-system";
        };
      };
      clusterRoleBindings.vault-token-reviewer = {
        apiVersion = "rbac.authorization.k8s.io/v1";
        kind = "ClusterRoleBinding";
        metadata.name = "vault-token-reviewer";
        roleRef = {
          apiGroup = "rbac.authorization.k8s.io";
          kind = "ClusterRole";
          name = "system:auth-delegator";
        };
        subjects = [
          {
            kind = "ServiceAccount";
            name = "vault-token-reviewer";
            namespace = "kube-system";
          }
        ];
      };
    };
  };
}
