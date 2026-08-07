{
  imports = [
    ./argocd
    ./cert-manager
    ./cilium
    ./external-dns
    ./external-secrets
    ./gateway-api
    ./piraeus-operator
    ./rook-ceph
    ./traefik
  ];

  nixidy = {
    defaults = {
      syncPolicy.autoSync.enable = false;
    };
    target = {
      repository = "https://github.com/misumisumi/homelab-k8s-apps.git";
      branch = "develop";
      rootPath = "manifests/develop";
    };
  };
}
