# modules/core/wireless/default.nix
# ==============================================================================
# Kablosuz Ağ Yapılandırması - NetworkManager
# ==============================================================================
{ config, lib, pkgs, ... }:
{
  # NetworkManager yapılandırması - en basit haliyle
  networking = {
    enableIPv6 = false;
    wireless.enable = false;
    
    networkmanager = {
      enable = true;
      wifi = {
        backend = "wpa_supplicant";
        scanRandMacAddress = true;
        powersave = false;
      };
    };
  };
  
  # DNS çözümleme servisi
  services.resolved = {
    enable = true;
    dnssec = "false";
    fallbackDns = [ "1.1.1.1" "8.8.8.8" ];
  };
}

