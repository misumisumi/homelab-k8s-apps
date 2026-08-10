{
  imports = [
    ./argocd.nix
    ./cert-manager
    ./cilium
    ./coredns.nix
    ./external-dns.nix
    ./external-secrets.nix
    ./gateway-api.nix
    ./owncloud.nix
    ./piraeus-operator.nix
    ./prometheus
    ./rook-ceph
    ./traefik.nix
  ];
}
