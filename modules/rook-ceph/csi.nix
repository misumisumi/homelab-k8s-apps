{ charts, ... }:
{
  # Deploys the Ceph CSI driver CRs (rbd, cephfs) for the ceph-csi-operator.
  # The CephConnection, ClientProfile and ImageSet ConfigMap are created by
  # rook-ceph; this chart only registers the drivers so the operator deploys
  # the actual CSI controller/node pods.
  applications.ceph-csi-drivers = {
    namespace = "rook-ceph";

    helm.releases.ceph-csi-drivers = {
      chart = charts.ceph-csi-operator.ceph-csi-drivers;

      values = {
        # Reuse the CephConnection/ClientProfile managed by rook-ceph.
        cephConnections = [ ];
        clientProfiles = [ ];

        operatorConfig = {
          namespace = "rook-ceph";
          create = true;
          driverSpecDefaults = {
            imageSet.name = "rook-csi-operator-image-set-configmap";
            clusterName = "rook-ceph";
          };
        };

        drivers = {
          rbd = {
            name = "rook-ceph.rbd.csi.ceph.com";
            enabled = true;
            imageSet.name = "rook-csi-operator-image-set-configmap";
            clusterName = "rook-ceph";
          };
          cephfs = {
            name = "rook-ceph.cephfs.csi.ceph.com";
            enabled = true;
            imageSet.name = "rook-csi-operator-image-set-configmap";
            clusterName = "rook-ceph";
          };
          nfs = {
            name = "nfs.csi.ceph.com";
            enabled = false;
          };
          nvmeof = {
            name = "nvmeof.csi.ceph.com";
            enabled = false;
          };
        };
      };
    };
  };
}
