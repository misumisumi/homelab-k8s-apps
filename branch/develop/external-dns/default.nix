{
  applications.external-dns = {
    helm.releases.external-dns = {
      values = {
        extraArgs = [
          "--pdns-server=http://172.16.1.2:8081"
          "--pdns-api-key=HogeHoge"
        ];
      };
    };
  };
}
