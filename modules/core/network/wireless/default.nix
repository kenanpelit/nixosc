# modules/core/network/wireless/default.nix
# ==============================================================================
# Kablosuz Ağ Yapılandırması - NetworkManager
# ==============================================================================
{ config, lib, pkgs, ... }:

{
  # NetworkManager yapılandırması
  networking = {
    # IPv6'yı global olarak devre dışı bırak
    enableIPv6 = false;
    
    # wpa_supplicant servisinin ayrıca etkinleştirilmediğinden emin olun
    wireless.enable = false; # wpa_supplicant zaten NetworkManager tarafından yönetiliyor
    
    networkmanager = {
      enable = true;
      
      # wpa_supplicant backend kullan
      wifi = {
        backend = "wpa_supplicant";
        scanRandMacAddress = true;
        powersave = false;
      };
      
      # NetworkManager ayarları
      settings = {
        main = {
          dns = "systemd-resolved";
        };
        connection = {
          "ipv6.method" = "disabled";
        };
      };
    };
  };

  # Önceden tanımlanmış ağ bağlantıları oluşturmak için dispatcher script
  environment.etc."NetworkManager/dispatcher.d/10-create-connections" = {
    mode = "0755";
    text = ''
      #!/bin/sh
      if [ "$2" = "up" ]; then
        # Ken_5 bağlantısı kontrol et, yoksa oluştur
        if ! nmcli connection show "Ken_5" >/dev/null 2>&1; then
          # Parola dosyasını oku
          PASSWORD=$(cat ${config.sops.secrets.wireless_ken_5_password.path})
          
          # Ken_5 bağlantısını oluştur
          nmcli connection add \
            type wifi \
            con-name "Ken_5" \
            ifname "*" \
            autoconnect yes \
            ssid "Ken_5" \
            wifi.powersave 0 \
            ipv4.method manual \
            ipv4.addresses "192.168.0.100/24" \
            ipv4.gateway "192.168.0.1" \
            ipv4.dns "1.1.1.1" \
            ipv6.method disabled \
            wifi-sec.key-mgmt wpa-psk \
            wifi-sec.psk "$PASSWORD" \
            connection.autoconnect-priority 20
        fi
        
        # Ken_2_4 bağlantısı kontrol et, yoksa oluştur
        if ! nmcli connection show "Ken_2_4" >/dev/null 2>&1; then
          # Parola dosyasını oku
          PASSWORD=$(cat ${config.sops.secrets.wireless_ken_2_4_password.path})
          
          # Ken_2_4 bağlantısını oluştur
          nmcli connection add \
            type wifi \
            con-name "Ken_2_4" \
            ifname "*" \
            autoconnect yes \
            ssid "Ken_2_4" \
            wifi.powersave 0 \
            ipv4.method manual \
            ipv4.addresses "192.168.0.101/24" \
            ipv4.gateway "192.168.0.1" \
            ipv4.dns "1.1.1.1" \
            ipv6.method disabled \
            wifi-sec.key-mgmt wpa-psk \
            wifi-sec.psk "$PASSWORD" \
            connection.autoconnect-priority 10
        fi
      fi
    '';
  };

  # DNS çözümleme servisi
  services.resolved = {
    enable = true;
    dnssec = "false";
    fallbackDns = [ "1.1.1.1" "8.8.8.8" ];
  };
}

