{
  imports = [
    ./argocd
    ./cert-manager
    ./cilium
    ./external-secrets
    ./piraeus-operator
    ./rook-ceph
  ];

  nixidy = {
    defaults = {
      syncPolicy.autoSync.enable = false;
    };
    target = {
      repository = "https://github.com/misumisumi/nixos-k8s-config.git";
      branch = "refactor/k8s";
      rootPath = "k8s-apps/manifests/develop";
    };
    kube = {
      configPath = "/home/sumi/Workspace/nix/server/nixos-k8s-config/nix/k8s/secrets/develop/kubeconfig";
    };
  };
}
