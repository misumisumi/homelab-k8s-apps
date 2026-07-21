{
  nixidy = {
    defaults = {
      destination.server = "https://172.16.100.100";
      syncPolicy.autoSync = {
        enable = true;
        prune = true;
        selfHeal = true;
      };
    };
    target = {
      repository = "https://github.com/misumisumi/homelab-k8s-apps.git";
      branch = "test";
      rootPath = "./manifests/test";
    };
    kube = {
      configPath = "/home/sumi/Workspace/nix/server/nixos-k8s-config/nix/k8s/secrets/test/kubeconfig";
    };
  };
}
