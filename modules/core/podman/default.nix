# modules/core/podman.nix
{ config, lib, pkgs, ... }:

{
  virtualisation = {
    podman = {
      enable = true;
      dockerCompat = true;        # docker komutlarıyla uyumluluk
      defaultNetwork.settings = {
        dns_enabled = true;      # DNS desteği
      };
      autoPrune = {             # Otomatik temizlik
        enable = true;
        flags = ["--all"];      # Kullanılmayan tüm imajları temizle
        dates = "weekly";       # Haftalık temizlik
      };

      # Container politikaları
      extraPackages = [ pkgs.runc pkgs.conmon pkgs.skopeo pkgs.slirp4netns ];
    };

    containers = {
      enable = true;
      registries = {
        search = [ "docker.io" "quay.io" ];
        insecure = [];
        block = [];
      };
    };
  };

}
