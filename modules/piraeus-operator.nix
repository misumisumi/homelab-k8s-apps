{
  config,
  charts,
  lib,
  ...
}:
let
  inherit (lib) nixdyGenerators extraPkgs;
  piraeusNamespace = "piraeus-datastore";

  # Grafana dashboard shipped by piraeus-operator, read from the pinned source
  # (config/extras/monitoring) to avoid vendoring a 50KB JSON blob.
  dashboardJson = builtins.readFile "${extraPkgs.piraeus-operator.src}/config/extras/monitoring/piraeus-dashboard.json";
in
{
  nixidy.applicationImports = [
    (nixdyGenerators.fromChartCRDModule {
      name = "piraeus-operator";
      chart = charts.piraeus-operator.piraeus;
      extraOpts = [
        "--set"
        "installCRDs=true"
      ];
    })
  ];

  applications.piraeus = {
    namespace = piraeusNamespace;
    createNamespace = true;

    helm.releases.piraeus-operator = {
      chart = charts.piraeus-operator.piraeus;
      values.installCRDs = true;
    };

    resources = {
      linstorClusters.linstorcluster = {
        metadata.name = "linstorcluster";
        spec = {
          linstorPassphraseSecret = "linstor-passphrase";
          nodeSelector = {
            "role.worker" = "piraeus";
          };
        };
      };

      # DRBD カーネルモジュールは NixOS 側 (drbd9-dkms) で既にビルド・ロード済みのため、
      # drbd-module-loader は DRBD のビルド/ロードをスキップする (deps_only)。
      # compile モードだと /usr/src (カーネルソース) を要求し、NixOS では失敗する。
      linstorSatelliteConfigurations.skip-drbd-module-loader = {
        metadata.name = "skip-drbd-module-loader";
        spec.podTemplate = {
          spec.initContainers = [
            {
              name = "drbd-module-loader";
              env = [
                {
                  name = "LB_HOW";
                  value = "deps_only";
                }
              ];
            }
          ];
        };
      };
      # master passphrase secret for linstor cluster, fetched from vault via external-secrets
      externalSecrets.piraeus-master-passphrase = {
        apiVersion = "external-secrets.io/v1";
        kind = "ExternalSecret";
        metadata = {
          name = "piraeus-master-passphrase";
          namespace = piraeusNamespace;
        };
        spec = {
          refreshInterval = "1h";
          secretStoreRef = {
            name = "vault-backend";
            kind = "ClusterSecretStore";
          };
          target = {
            name = "linstor-passphrase";
            creationPolicy = "Owner";
          };
          data = [
            {
              secretKey = "MASTER_PASSPHRASE";
              remoteRef = {
                key = "piraeus";
                property = "master_passphrase";
              };
            }
          ];
        };
      };
      serviceMonitors.piraeus-operator = {
        apiVersion = "monitoring.coreos.com/v1";
        kind = "ServiceMonitor";
        metadata = {
          name = "piraeus-operator";
          namespace = piraeusNamespace;
        };
        spec = {
          selector.matchLabels."app.kubernetes.io/name" = "piraeus-datastore";
          endpoints = [
            {
              port = "metrics";
              scheme = "https";
              interval = "30s";
              tlsConfig.insecureSkipVerify = true;
            }
          ];
        };
      };

      # LINSTOR/DRBD metrics scraping, alerting rules and Grafana dashboard
      # (equivalent of piraeus-operator's config/extras/monitoring kustomize).
      serviceMonitors.linstor-controller = {
        apiVersion = "monitoring.coreos.com/v1";
        kind = "ServiceMonitor";
        metadata = {
          name = "linstor-controller";
          namespace = piraeusNamespace;
        };
        spec = {
          selector.matchLabels."app.kubernetes.io/component" = "linstor-controller";
          endpoints = [
            {
              port = "api";
              scheme = "http";
              path = "/metrics";
            }
          ];
        };
      };
      podMonitors.linstor-affinity-controller = {
        apiVersion = "monitoring.coreos.com/v1";
        kind = "PodMonitor";
        metadata = {
          name = "linstor-affinity-controller";
          namespace = piraeusNamespace;
        };
        spec = {
          selector.matchLabels."app.kubernetes.io/component" = "linstor-affinity-controller";
          podMetricsEndpoints = [
            {
              port = "metrics";
              scheme = "http";
              path = "/metrics";
            }
          ];
        };
      };
      podMonitors.linstor-satellite = {
        apiVersion = "monitoring.coreos.com/v1";
        kind = "PodMonitor";
        metadata = {
          name = "linstor-satellite";
          namespace = piraeusNamespace;
        };
        spec = {
          selector.matchLabels."app.kubernetes.io/component" = "linstor-satellite";
          podMetricsEndpoints = [
            {
              port = "prometheus";
              scheme = "http";
              relabelings = [
                {
                  action = "replace";
                  sourceLabels = [ "__meta_kubernetes_pod_node_name" ];
                  targetLabel = "node";
                }
              ];
            }
          ];
        };
      };
      prometheusRules.piraeus-datastore = {
        apiVersion = "monitoring.coreos.com/v1";
        kind = "PrometheusRule";
        metadata = {
          name = "piraeus-datastore";
          namespace = piraeusNamespace;
        };
        spec.groups = [
          {
            name = "linstor.rules";
            rules = [
              {
                alert = "linstorControllerOffline";
                annotations.description = ''
                  LINSTOR Controller is not reachable.
                '';
                expr = "up{job=\"linstor-controller\"} == 0";
                labels.severity = "critical";
              }
              {
                alert = "linstorSatelliteErrorRate";
                annotations.description = ''
                  LINSTOR Satellite "{{ $labels.hostname }}" reports {{ $value }} errors in the last 15 minutes.
                  Use "linstor error-reports list --nodes {{ $labels.hostname }} --since 15minutes" to see them.
                '';
                expr = "increase(linstor_error_reports_count{module=\"SATELLITE\"}[15m]) > 0";
                labels.severity = "warning";
              }
              {
                alert = "linstorControllerErrorRate";
                annotations.description = ''
                  LINSTOR Controller reports {{ $value }} errors in the last 15 minutes.
                  Use "linstor error-reports list --since 15minutes" to see them.
                '';
                expr = "increase(linstor_error_reports_count{module=\"CONTROLLER\"}[15m]) > 0";
                labels.severity = "warning";
              }
              {
                alert = "linstorSatelliteNotOnline";
                annotations.description = ''
                  LINSTOR Satellite "{{ $labels.node }}" is not ONLINE.
                  Check that the Satellite is running and reachable from the LINSTOR Controller.
                '';
                expr = "linstor_node_state{nodetype=\"SATELLITE\"} != 2 and on (node) up{job=~\".*/linstor-satellite\"}";
                labels.severity = "critical";
              }
              {
                alert = "linstorStoragePoolErrors";
                annotations.description = ''
                  Storage pool "{{ $labels.storage_pool }}" on node "{{ $labels.node }}" ({{ $labels.driver }}={{ $labels.backing_pool }}) is reporting errors.
                '';
                expr = "linstor_storage_pool_error_count > 0";
                labels.severity = "critical";
              }
              {
                alert = "linstorStoragePoolAtCapacity";
                annotations.description = ''
                  Storage pool "{{ $labels.storage_pool }}" on node "{{ $labels.node }}" ({{ $labels.driver }}={{ $labels.backing_pool }}) has less than 20% free space available.
                '';
                expr = "( linstor_storage_pool_capacity_free_bytes / linstor_storage_pool_capacity_total_bytes ) < 0.20";
                labels.severity = "warning";
              }
            ];
          }
          {
            name = "drbd.rules";
            rules = [
              {
                alert = "drbdReactorOffline";
                annotations.description = ''
                  DRBD Reactor on "{{ $labels.node }}" is not reachable.
                '';
                expr = "up{job=~\".*/linstor-satellite\"} == 0";
                labels.severity = "critical";
              }
              {
                alert = "drbdConnectionNotConnected";
                annotations.description = ''
                  DRBD Resource "{{ $labels.name }}" on "{{ $labels.node }}" is not connected to "{{ $labels.conn_name }}": {{ $labels.drbd_connection_state }}.
                '';
                expr = "drbd_connection_state{drbd_connection_state!=\"Connected\"} > 0";
                for = "1m";
                labels.severity = "warning";
              }
              {
                alert = "drbdDeviceNotUpToDate";
                annotations.description = ''
                  DRBD device "{{ $labels.name }}" on "{{ $labels.node }}" has unexpected device state "{{ $labels.drbd_device_state }}".
                '';
                expr = "drbd_device_state{drbd_device_state!~\"UpToDate|Diskless|Inconsistent\"} > 0";
                for = "1m";
                labels.severity = "warning";
              }
              {
                alert = "drbdDeviceUnintentionalDiskless";
                annotations.description = ''
                  DRBD device "{{ $labels.name }}" on "{{ $labels.node }}" is unintenionally diskless.
                  This usually indicates IO errors reported on the backing device. Check the kernel log.
                '';
                expr = "drbd_device_unintentionaldiskless > 0";
                labels.severity = "warning";
              }
              {
                alert = "drbdDeviceWithoutQuorum";
                annotations.description = ''
                  DRBD device "{{ $labels.name }}" on "{{ $labels.node }}" has no quorum.
                  This usually indicates connectivity issues.
                '';
                expr = "drbd_device_quorum == 0";
                for = "1m";
                labels.severity = "warning";
              }
              {
                alert = "drbdResourceSuspended";
                annotations.description = ''
                  DRBD resource "{{ $labels.name }}" on "{{ $labels.node }}" has been suspended for 1m.
                '';
                expr = "drbd_resource_suspended > 0";
                for = "1m";
                labels.severity = "warning";
              }
              {
                alert = "drbdResourceResyncWithoutProgress";
                annotations.description = ''
                  DRBD resource "{{ $labels.name }}" on "{{ $labels.node }}" has been in Inconsistent without resync progress for 5 minutes.
                  This may indicate there is no connection to UpToDate data, or a stuck resync.
                '';
                expr = "drbd_device_state{drbd_device_state=\"Inconsistent\"} and delta(drbd_peerdevice_outofsync_bytes[5m]) >= 0";
                labels.severity = "warning";
              }
              {
                alert = "drbdResourceWithNoUpToDateReplicas";
                annotations.description = ''
                  DRBD resource "{{ $labels.name }}" has no UpToDate replicas.
                '';
                expr = "sum by (name) (drbd_device_state{drbd_device_state=\"UpToDate\"}) == 0";
                for = "1m";
                labels.severity = "critical";
              }
            ];
          }
        ];
      };
      configMaps.piraeus-datastore-dashboard = {
        apiVersion = "v1";
        kind = "ConfigMap";
        metadata = {
          name = "piraeus-datastore-dashboard";
          namespace = piraeusNamespace;
          labels."grafana_dashboard" = "1";
        };
        data."piraeus-dashboard.json" = dashboardJson;
      };
    };
  };
}
