# modules/core/networking/default.nix
# ==============================================================================
# Network Configuration
# ==============================================================================
# This configuration manages networking settings including:
# - Hostname and basic network setup
# - WiFi and NetworkManager configuration with nmcli support
# - DNS resolution with systemd-resolved
# - Mullvad VPN and WireGuard setup
#
# NOTE: Firewall rules are managed in security/default.nix
#
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

    # Not: Mullvad IPv6 sızıntı koruması sağlıyor ama host tarafında IPv6
    # açıkken bazı ağlarda (özellikle captive/şirket ağları) ilk el sıkışma
    # sorunları görülebiliyor. Çalışan yapıdaki gibi kapatalım.
    enableIPv6 = false;

    wireless.enable = false;

    networkmanager = {
      enable = true;
      wifi = {
        backend = "wpa_supplicant";
        scanRandMacAddress = true;
        # Pil yerine stabilite/çekiş için powersave kapalı tutmak genelde
        # VPN bağlantı stabilitesine yardım ediyor.
        powersave = false;
      };
      # DNS’i systemd-resolved’a devrediyoruz.
      dns = "systemd-resolved";
    };

    # Mullvad (WG/OVPN) için WireGuard çekirdek modülü
    wireguard.enable = true;

    # Basit/güvenli: VPN açık/kapalı durumuna göre isim sunucuları.
    # (resolved bunu kaynak alır)
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
    # Modern DNS yöneti mi
    resolved = {
      enable = true;

      # DNSSEC'i uyumluluk için allow-downgrade tutalım.
      dnssec = "allow-downgrade";

      # Aşırı özelleştirilmiş extraConfig kaldırıldı.
      # DNSOverTLS gibi seçenekler Mullvad ile çakışabiliyordu.
      extraConfig = "";
    };

    # Mullvad daemon + GUI paketi (daemon bununla gelir)
    mullvad-vpn = {
      enable = true;
      package = pkgs.mullvad-vpn;
    };

    # Ağ hazır olana kadar beklet
    NetworkManager-wait-online.enable = true;
  };

  ##############################################################################
  # Mullvad otomatizasyonu (race fix)
  #
  # postStart yerine ayrı, bağımlılıkları doğru tanımlanmış bir oneshot servis.
  # - Daemon ve ağ hazır olana kadar bekler.
  # - Sonra güvenli şekilde autoconnect + DNS reklam/izleyici bloklamayı ayarlar.
  # - İsteğe göre "any" relay seçer ve bağlanır (ilk koklaşmada tekrar dener).
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

        # Olmadı, farklı relay dene
        "$CLI" relay set tunnel-protocol any || true
        "$CLI" relay set location any || true
        "$CLI" connect || true

        exit 0
      '');
      RemainAfterExit = true;
    };
  };

  # Kabuk kısayolları
  environment.shellAliases = {
    wifi-list = "nmcli device wifi list";
    wifi-connect = "nmcli device wifi connect";
    wifi-disconnect = "nmcli connection down";
    wifi-saved = "nmcli connection show";

    net-status = "nmcli general status";
    net-connections = "nmcli connection show --active";

    vpn-status = "mullvad status";
    vpn-connect = "mullvad connect";
    vpn-disconnect = "mullvad disconnect";
    vpn-relay = "mullvad relay list";

    dns-test = "resolvectl status";
    dns-leak = "curl -s https://mullvad.net/en/check | sed -n '1,120p'";
  };
}
