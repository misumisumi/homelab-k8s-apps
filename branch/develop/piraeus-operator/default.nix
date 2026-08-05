let
  hddDisk = "/dev/disk/by-id/scsi-0QEMU_QEMU_HARDDISK_piraeus_disk";

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
  applications.piraeus.resources.linstorSatelliteConfigurations = {
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
}
