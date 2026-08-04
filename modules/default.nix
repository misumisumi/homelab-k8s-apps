{
  imports = [
    ./argocd.nix
    ./cert-manager
    ./cilium
    ./coredns.nix
    ./external-dns.nix
    ./external-secrets.nix
    ./gateway-api.nix
    ./piraeus-operator.nix
    ./traefik.nix
  ];
}
