{
  charts,
  lib,
  ...
}:
let
  inherit (lib) nixdyGenerators;
in
{
  imports = [ ./csi.nix ];

  nixidy.applicationImports = [
    (nixdyGenerators.fromChartCRDModule {
      name = "rook-ceph";
      chart = charts.rook-release.rook-ceph;
      extraOpts = [
        "--set"
        "crds.enabled=true"
      ];
    })
  ];

  applications.rook-ceph = {
    namespace = "rook-ceph";
    createNamespace = true;

    helm.releases.rook-ceph = {
      chart = charts.rook-release.rook-ceph;
      values = {
        crds.enabled = true;
        nodeSelector = {
          "role.worker" = "ceph";
        };
        csi = {
          provisionerNodeAffinity = "role.worker=ceph";
          pluginNodeAffinity = "role.worker=ceph";
        };
      };
    };

    resources = {
      cephBlockPools.replicated-pool = {
        metadata.name = "replicated-pool";
        spec = {
          failureDomain = "host";
          replicated = {
            size = 3;
            requireSafeReplicaSize = true;
          };
          enableRBDStats = true;
        };
      };

      cephFilesystems.cephfs = {
        metadata.name = "cephfs";
        spec = {
          metadataPool = {
            failureDomain = "host";
            replicated.size = 3;
          };
          dataPools = [
            {
              failureDomain = "host";
              replicated.size = 3;
            }
          ];
          metadataServer = {
            activeCount = 1;
            activeStandby = true;
          };
        };
      };

      storageClasses.ceph-block = {
        metadata.name = "ceph-block";
        provisioner = "rook-ceph.rbd.csi.ceph.com";
        reclaimPolicy = "Delete";
        allowVolumeExpansion = true;
        parameters = {
          clusterID = "rook-ceph";
          pool = "replicated-pool";
          imageFeatures = "layering";
          "csi.storage.k8s.io/provisioner-secret-name" = "rook-csi-rbd-provisioner";
          "csi.storage.k8s.io/provisioner-secret-namespace" = "rook-ceph";
          "csi.storage.k8s.io/controller-expand-secret-name" = "rook-csi-rbd-provisioner";
          "csi.storage.k8s.io/controller-expand-secret-namespace" = "rook-ceph";
          "csi.storage.k8s.io/node-stage-secret-name" = "rook-csi-rbd-node";
          "csi.storage.k8s.io/node-stage-secret-namespace" = "rook-ceph";
        };
      };

      storageClasses.ceph-fs = {
        metadata.name = "ceph-fs";
        provisioner = "rook-ceph.cephfs.csi.ceph.com";
        reclaimPolicy = "Delete";
        allowVolumeExpansion = true;
        parameters = {
          clusterID = "rook-ceph";
          fsName = "cephfs";
          "csi.storage.k8s.io/provisioner-secret-name" = "rook-csi-cephfs-provisioner";
          "csi.storage.k8s.io/provisioner-secret-namespace" = "rook-ceph";
          "csi.storage.k8s.io/controller-expand-secret-name" = "rook-csi-cephfs-provisioner";
          "csi.storage.k8s.io/controller-expand-secret-namespace" = "rook-ceph";
          "csi.storage.k8s.io/node-stage-secret-name" = "rook-csi-cephfs-node";
          "csi.storage.k8s.io/node-stage-secret-namespace" = "rook-ceph";
        };
      };
    };
  };
}
