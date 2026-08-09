let
  hddDisk = "/dev/disk/by-id/scsi-0QEMU_QEMU_HARDDISK_incus_piraeus_disk";

  piraeusHosts = [
    "piraeus-worker1"
    "piraeus-worker2"
    "piraeus-worker3"
  ];

  storagePool = {
    name = "hdd-pool";
    lvmThinPool = {
      volumeGroup = "piraeus-vg";
      thinPool = "thin";
    };
    source.hostDevices = [ hddDisk ];
  };
in
{
  applications.piraeus = {
    helm.releases.piraeus-operator.values = {
      affinity = {
        nodeAffinity = {
          requiredDuringSchedulingIgnoredDuringExecution = {
            nodeSelectorTerms = [
              {
                matchExpressions = [
                  {
                    key = "kubernetes.io/hostname";
                    operator = "In";
                    values = piraeusHosts;
                  }
                ];
              }
            ];
          };
        };
      };
    };

    resources = {
      linstorSatelliteConfigurations = {
        piraeus-worker1-storage = {
          metadata.name = "piraeus-worker1-storage";
          spec = {
            nodeSelector."kubernetes.io/hostname" = "piraeus-worker1";
            storagePools = [ storagePool ];
          };
        };
        piraeus-worker2-storage = {
          metadata.name = "piraeus-worker2-storage";
          spec = {
            nodeSelector."kubernetes.io/hostname" = "piraeus-worker2";
            storagePools = [ storagePool ];
          };
        };
        piraeus-worker3-diskless = {
          metadata.name = "piraeus-worker3-diskless";
          spec = {
            nodeSelector."kubernetes.io/hostname" = "piraeus-worker3";
            properties = [
              {
                name = "AutoplaceTarget";
                value = "no";
              }
            ];
          };
        };
      };

      storageClasses.linstor-hdd-pool = {
        metadata.name = "linstor-hdd-pool";
        provisioner = "linstor.csi.linbit.com";
        reclaimPolicy = "Delete";
        allowVolumeExpansion = true;
        volumeBindingMode = "WaitForFirstConsumer";
        parameters = {
          "linstor.csi.linbit.com/storagePool" = storagePool.name;
          "linstor.csi.linbit.com/placementCount" = "2";
        };
      };
    };
  };
}
