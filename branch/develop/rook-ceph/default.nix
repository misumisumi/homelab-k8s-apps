let
  hddDisk1 = "/dev/disk/by-id/scsi-0QEMU_QEMU_HARDDISK_incus_ceph_disk_01";
  hddDisk2 = "/dev/disk/by-id/scsi-0QEMU_QEMU_HARDDISK_incus_ceph_disk_02";

  cephHosts = [
    "ceph-worker1"
    "ceph-worker2"
    "ceph-worker3"
  ];

  cephNode = name: {
    inherit name;
    devices = [
      { name = hddDisk1; }
      { name = hddDisk2; }
    ];
  };
in
{
  applications.rook-ceph = {
    syncPolicy.syncOptions.serverSideApply = true;
    syncPolicy.syncOptions.clientSideApplyMigration = false;
    resources.cephClusters.rook-ceph = {
    metadata.name = "rook-ceph";
    spec = {
      cephVersion = {
        image = "quay.io/ceph/ceph:v20.2.2";
        allowUnsupported = false;
      };
      dataDirHostPath = "/var/lib/rook";
      mon = {
        count = 3;
        allowMultiplePerNode = false;
      };
      mgr.count = 2;
      dashboard.enabled = true;
      placement = {
        all = {
          nodeAffinity = {
            requiredDuringSchedulingIgnoredDuringExecution = {
              nodeSelectorTerms = [
                {
                  matchExpressions = [
                    {
                      key = "role.worker";
                      operator = "In";
                      values = [ "ceph" ];
                    }
                  ];
                }
              ];
            };
          };
        };
      };
      storage = {
        useAllNodes = false;
        nodes = map cephNode cephHosts;
      };
      resources = {
        mon = {
          limits = {
            cpu = "1";
            memory = "2Gi";
          };
          requests = {
            cpu = "500m";
            memory = "1Gi";
          };
        };
        mgr = {
          limits = {
            cpu = "1";
            memory = "2Gi";
          };
          requests = {
            cpu = "500m";
            memory = "1Gi";
          };
        };
        osd = {
          limits = {
            cpu = "2";
            memory = "4Gi";
          };
          requests = {
            cpu = "1";
            memory = "1Gi";
          };
        };
      };
    };
  };
  };
}
