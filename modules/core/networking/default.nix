# modules/core/networking/default.nix
# ==============================================================================
# Network Configuration
# ==============================================================================
# This configuration manages networking settings including:
# - Hostname and basic network setup
# - WiFi and NetworkManager configuration
# - DNS nameserver configuration with VPN support
# - Mullvad VPN and WireGuard setup
# - Network security and firewall rules
#
# Author: Kenan Pelit
# ==============================================================================
{ config, lib, pkgs, host, ... }:
{
  networking = {
    # Basic Network Configuration
    hostName = "${host}";
    enableIPv6 = false;
    
    # WiFi and Network Management
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
    
    # DNS nameserver configuration - switches based on Mullvad VPN status
    nameservers = lib.mkMerge [
      # Default DNS servers when VPN is disabled
      (lib.mkIf (!config.services.mullvad-vpn.enable) [
        "1.1.1.1"  # Cloudflare Primary
        "1.0.0.1"  # Cloudflare Secondary
        "9.9.9.9"  # Quad9
      ])
      
      # Mullvad DNS servers when VPN is enabled
      (lib.mkIf config.services.mullvad-vpn.enable [
        "194.242.2.2"  # Mullvad DNS Primary
        "194.242.2.3"  # Mullvad DNS Secondary
        "1.1.1.1"      # Cloudflare DNS (fallback)
      ])
    ];
    
    # VPN Configuration
    wireguard.enable = true;
    
    # Network security for VPN
    firewall = {
      # Allow Mullvad app
      allowedTCPPorts = [ ];
      allowedUDPPorts = [ ];
      # Trust WireGuard interface
      trustedInterfaces = [ "wg+" ];
    };
  };

  # Services Configuration
  services = {
    # DNS Resolution
    resolved.enable = true;
    
    # Mullvad VPN Service
    mullvad-vpn = {
      enable = true;
      package = pkgs.mullvad-vpn;
    };
  };
  
  # VPN and networking tools
  environment.systemPackages = with pkgs; [
    mullvad-vpn          # Mullvad GUI/CLI
    wireguard-tools      # WireGuard utilities
    openresolv           # DNS management
  ];
}

