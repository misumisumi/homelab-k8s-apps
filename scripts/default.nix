{
  lib,
  cilium-cli,
  flake-root,
  kubectl,
  kubernetes-helm,
  writeShellScriptBin,
}:
let
  inherit (lib) mapAttrs' nameValuePair getExe;
  variants = {
    production = "prod";
    develop = "dev";
    test = "test";
  };
in
(mapAttrs' (
  k: v:
  nameValuePair "k-${v}" (
    writeShellScriptBin "k-${v}" ''
      ${kubectl}/bin/kubectl --kubeconfig "$(${getExe flake-root})/../nixos-k8s-config/instances/secrets/${k}/kubeconfig" $@
    ''
  )
) variants)
// (mapAttrs' (
  k: v:
  nameValuePair "helm-${v}" (
    writeShellScriptBin "helm-${v}" ''
      ${kubernetes-helm}/bin/helm --kubeconfig "$(${getExe flake-root})/../nixos-k8s-config/instances/secrets/${k}/kubeconfig" $@
    ''
  )
) variants)
// (mapAttrs' (
  k: v:
  nameValuePair "cilium-${v}" (
    writeShellScriptBin "cilium-${v}" ''
      ${cilium-cli}/bin/cilium --kubeconfig "$(${getExe flake-root})/../nixos-k8s-config/instances/secrets/${k}/kubeconfig" $@
    ''
  )
) variants)
