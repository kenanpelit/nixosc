# modules/core/wireless/default.nix
# ==============================================================================
# Kablosuz Ağ Yapılandırması - NetworkManager
# ==============================================================================
{ config, lib, pkgs, ... }:
{
  # NetworkManager yapılandırması
  networking = {
    enableIPv6 = false;
    wireless.enable = false;  # wpa_supplicant devre dışı (NetworkManager kullanıyor)
    
    networkmanager = {
      enable = true;
      wifi = {
        backend = "wpa_supplicant";
        scanRandMacAddress = true;  # Privacy için MAC randomization
        powersave = false;          # Performance için power save kapalı
      };
      
      # DNS management - delegate to systemd-resolved
      dns = "systemd-resolved";
    };
  };
  
  # Note: DNS configuration handled in modules/core/dns
  # systemd-resolved basic setup for NetworkManager integration
  services.resolved.enable = true;
}

