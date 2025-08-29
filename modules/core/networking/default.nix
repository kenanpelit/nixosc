# modules/core/networking/default.nix
# ==============================================================================
# Network Configuration
# ==============================================================================
# - Hostname ve temel ağ ayarları
# - NetworkManager + nmcli
# - systemd-resolved ile DNS (VPN ile uyumlu)
# - Mullvad VPN (daemon + CLI) ve WireGuard
# - Boot’ta ağ hazır olana kadar bekleme (NetworkManager-wait-online)
#
# Not: Güvenlik/Firewall kuralları security/default.nix altında
# Author: Kenan Pelit
# ==============================================================================
{ config, lib, pkgs, host, ... }:
let
  hasMullvad = config.services.mullvad-vpn.enable or false;
in
{
  ##############################################################################
  # Base networking
  ##############################################################################
  networking = {
    hostName = "${host}";

    # IPv6 bazı ağlarda ilk el sıkışmaları bozabiliyor; stabil sonrası açılabilir.
    enableIPv6 = false;

    # Wi-Fi yönetimini NM’ye bırakıyoruz
    wireless.enable = false;

    networkmanager = {
      enable = true;
      wifi = {
        backend = "wpa_supplicant";
        scanRandMacAddress = true;
        # Stabilite için powersave kapalı (isteğe göre açılabilir)
        powersave = false;
      };
      # DNS’i systemd-resolved’a devret
      dns = "systemd-resolved";
    };

    # Mullvad’ın WG tünelleri için kernel modülü
    wireguard.enable = true;

    # VPN açık/kapalıya göre isim sunucuları
    nameservers = lib.mkMerge [
      (lib.mkIf (!hasMullvad) [
        "1.1.1.1"
        "1.0.0.1"
        "9.9.9.9"
      ])
      (lib.mkIf hasMullvad [
        "194.242.2.2" # Mullvad
        "194.242.2.3" # Mullvad
      ])
    ];

    firewall.enable = true;
  };

  ##############################################################################
  # Services
  ##############################################################################
  services = {
    # Modern DNS resolution
    resolved = {
      enable = true;
      dnssec = "allow-downgrade"; # uyumluluk
      # Mullvad ile çakışabilecek aşırı özelleştirmeleri kapattık
      extraConfig = "";
    };

    # Mullvad daemon + GUI (daemon bununla gelir)
    mullvad-vpn = {
      enable = true;
      package = pkgs.mullvad-vpn;
    };
  };

  ##############################################################################
  # Ağ gerçekten hazır olana kadar bekle (IP alana dek)
  ##############################################################################
  systemd.services."NetworkManager-wait-online".enable = true;

  ##############################################################################
  # Mullvad otomatizasyonu (race fix)
  #
  # - Daemon ve network-online hazır olana kadar bekler
  # - Autoconnect + DNS blocker ayarlarını yapar
  # - Bağlantıyı birkaç kez dener, sonra protokol/relay’i gevşetip tekrar dener
  ##############################################################################
  systemd.services."mullvad-autoconnect" = {
    description = "Configure and connect Mullvad once daemon socket is ready";
    wantedBy = [ "multi-user.target" ];
    after = [ "network-online.target" "mullvad-daemon.service" ];
    requires = [ "mullvad-daemon.service" "network-online.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = lib.getExe (pkgs.writeShellScriptBin "mullvad-autoconnect" ''
        set -euo pipefail

        CLI="${pkgs.mullvad}/bin/mullvad"

        # Daemon soketi hazır olana kadar bekle
        tries=0
        until "$CLI" status >/dev/null 2>&1; do
          tries=$((tries+1))
          if [ "$tries" -ge 30 ]; then
            printf 'mullvad-daemon socket not ready after %ss\n' "$tries" >&2
            exit 1
          fi
          sleep 1
        done

        # Güvenli varsayılanlar
        "$CLI" auto-connect set on || true
        "$CLI" dns set default --block-ads --block-trackers || true
        "$CLI" relay set location any || true

        # Bağlantı denemeleri (3 kez)
        for i in 1 2 3; do
          if "$CLI" connect; then
            exit 0
          fi
          sleep 2
        done

        # Olmadıysa, protokol/konumu gevşetip tekrar dene
        "$CLI" relay set tunnel-protocol any || true
        "$CLI" relay set location any || true
        "$CLI" connect || true

        exit 0
      '');
      RemainAfterExit = true;
    };
  };

  environment.shellAliases = {
    # WiFi yönetimi
    wifi-list = "nmcli device wifi list";
    wifi-connect = "nmcli device wifi connect";
    wifi-disconnect = "nmcli connection down";
    wifi-saved = "nmcli connection show";

    # Ağ bilgisi
    net-status = "nmcli general status";
    net-connections = "nmcli connection show --active";

    # VPN kısayolları
    vpn-status = "mullvad status";
    vpn-connect = "mullvad connect";
    vpn-disconnect = "mullvad disconnect";
    vpn-relay = "mullvad relay list";

    # DNS testleri
    dns-test = "resolvectl status";
    dns-leak = "curl -s https://mullvad.net/en/check | sed -n '1,120p'";
  };
}


