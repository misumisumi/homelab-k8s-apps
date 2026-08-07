{ lib, ... }:
{
  # Force server-side apply on the large CRDs to avoid the 256KB
  # last-applied-configuration annotation limit.
  applications.kube-prometheus-stack.resources.customResourceDefinitions = {
    "prometheuses.monitoring.coreos.com" = {
      metadata.annotations."argocd.argoproj.io/sync-options" = lib.mkForce "ServerSideApply=true";
    };
    "alertmanagers.monitoring.coreos.com" = {
      metadata.annotations."argocd.argoproj.io/sync-options" = lib.mkForce "ServerSideApply=true";
    };
    "alertmanagerconfigs.monitoring.coreos.com" = {
      metadata.annotations."argocd.argoproj.io/sync-options" = lib.mkForce "ServerSideApply=true";
    };
    "scrapeconfigs.monitoring.coreos.com" = {
      metadata.annotations."argocd.argoproj.io/sync-options" = lib.mkForce "ServerSideApply=true";
    };
    "prometheusagents.monitoring.coreos.com" = {
      metadata.annotations."argocd.argoproj.io/sync-options" = lib.mkForce "ServerSideApply=true";
    };
    "thanosrulers.monitoring.coreos.com" = {
      metadata.annotations."argocd.argoproj.io/sync-options" = lib.mkForce "ServerSideApply=true";
    };
  };
}
