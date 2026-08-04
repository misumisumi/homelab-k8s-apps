{ ... }:
let
  hddDisk = "/dev/disk/by-id/scsi-0QEMU_QEMU_HARDDISK_piraeus_diks";

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
    linstor1-storage = {
      metadata.name = "linstor1-storage";
      spec = {
        nodeSelector."kubernetes.io/hostname" = "linstor1";
        storagePools = [ storagePool ];
      };
    };
    linstor2-storage = {
      metadata.name = "linstor2-storage";
      spec = {
        nodeSelector."kubernetes.io/hostname" = "linstor2";
        storagePools = [ storagePool ];
      };
    };
    linstor3-diskless = {
      metadata.name = "linstor3-diskless";
      spec = {
        nodeSelector."kubernetes.io/hostname" = "linstor3";
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
