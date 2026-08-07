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
      branch = "main";
      rootPath = "./manifests/production";
    };
  };
}
