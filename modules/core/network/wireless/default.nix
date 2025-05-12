# modules/core/network/wireless/default.nix
# ==============================================================================
# Wireless Configuration
# ==============================================================================
# This configuration manages wireless network settings including:
# - NetworkManager configuration and settings
# - Network profiles
# - Power management
#
# Author: Kenan Pelit
# ==============================================================================
{ config, pkgs, ... }:
{
  # Full NetworkManager configuration replacing IWD
  networking.networkmanager = {
    enable = true;
    
    # Disable IWD backend in favor of wpa_supplicant
    wifi.backend = "wpa_supplicant";
    
    # Disable IPv6 globally
    enableIPv6 = false;
    
    # Network Manager settings
    extraConfig = ''
      [main]
      dns=systemd-resolved
      
      [connection]
      ipv6.method=disabled
      
      [device]
      wifi.scan-rand-mac-address=yes
      
      [connection-wifi]
      wifi.powersave=2
    '';
    
    # Pre-define network connections for Ken_5 and Ken_2_4
    dispatcherScripts = [
      {
        source = pkgs.writeText "10-create-connections" ''
          #!/bin/sh
          if [ "$2" = "up" ]; then
            # Ken_5 connection
            nmcli connection show "Ken_5" >/dev/null 2>&1 || \
            nmcli connection add \
              type wifi \
              con-name "Ken_5" \
              ifname "*" \
              autoconnect yes \
              ssid "Ken_5" \
              ipv4.method manual \
              ipv4.addresses "192.168.0.100/24" \
              ipv4.gateway "192.168.0.1" \
              ipv4.dns "1.1.1.1" \
              ipv6.method disabled \
              wifi.powersave 2
              
            # Ken_2_4 connection
            nmcli connection show "Ken_2_4" >/dev/null 2>&1 || \
            nmcli connection add \
              type wifi \
              con-name "Ken_2_4" \
              ifname "*" \
              autoconnect yes \
              ssid "Ken_2_4" \
              ipv4.method manual \
              ipv4.addresses "192.168.0.101/24" \
              ipv4.gateway "192.168.0.1" \
              ipv4.dns "1.1.1.1" \
              ipv6.method disabled \
              wifi.powersave 2 \
              connection.autoconnect-priority 10
          fi
        '';
        type = "basic";
      }
    ];
  };
  
  # Ensure wpa_supplicant service is enabled and IWD is disabled
  networking.wireless.enable = false; # wpa_supplicant is already managed by NetworkManager
  services.iwd.enable = false;
}

