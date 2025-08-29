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
{
  networking = {
    # Basic Network Configuration
    hostName = "${host}";
    enableIPv6 = true;  # Mullvad handles IPv6 leak protection
    
    # WiFi and Network Management
    wireless.enable = false;  # wpa_supplicant managed by NetworkManager
    
    networkmanager = {
      enable = true;
      wifi = {
        backend = "wpa_supplicant";  # For nmcli compatibility
        scanRandMacAddress = true;    # MAC randomization for privacy
        powersave = true;             # Better battery life
      };
      
      # Let systemd-resolved handle DNS
      dns = "systemd-resolved";
    };
    
    # WireGuard for VPN
    wireguard.enable = true;
    
    # Firewall is configured in security/default.nix to avoid conflicts
    # Only set minimal required settings here
    firewall.enable = true;
  };
  
  # Services Configuration
  services = {
    # systemd-resolved for modern DNS management
    resolved = {
      enable = true;
      dnssec = "allow-downgrade";  # More compatible than "true"
      domains = [ "~." ];
      
      # Fallback DNS servers (when VPN is off)
      fallbackDns = lib.mkIf (!config.services.mullvad-vpn.enable) [
        "1.1.1.1#cloudflare-dns.com"
        "1.0.0.1#cloudflare-dns.com"
        "9.9.9.9#dns.quad9.net"
      ];
      
      # DNS configuration
      extraConfig = ''
        DNS=${lib.optionalString config.services.mullvad-vpn.enable "194.242.2.2 194.242.2.3"}
        DNSOverTLS=opportunistic
        Cache=yes
        CacheFromLocalhost=yes
        DNSStubListener=yes
        ReadEtcHosts=yes
      '';
    };
    
    # Mullvad VPN Service
    mullvad-vpn = {
      enable = true;
      package = pkgs.mullvad-vpn;
    };
  };
  
  # Mullvad auto-connect and kill-switch
  systemd.services.mullvad-daemon.postStart = lib.mkIf config.services.mullvad-vpn.enable ''
    ${pkgs.mullvad}/bin/mullvad auto-connect set on
    ${pkgs.mullvad}/bin/mullvad dns set default --block-ads --block-trackers
    ${pkgs.mullvad}/bin/mullvad relay set location any
  '';
 
  # Network manager aliases for convenience
  environment.shellAliases = {
    # WiFi management
    wifi-list = "nmcli device wifi list";
    wifi-connect = "nmcli device wifi connect";
    wifi-disconnect = "nmcli connection down";
    wifi-saved = "nmcli connection show";
    
    # Connection info
    net-status = "nmcli general status";
    net-connections = "nmcli connection show --active";
    
    # VPN shortcuts
    vpn-status = "mullvad status";
    vpn-connect = "mullvad connect";
    vpn-disconnect = "mullvad disconnect";
    vpn-relay = "mullvad relay list";
    
    # DNS testing
    dns-test = "resolvectl status";
    dns-leak = "curl https://mullvad.net/en/check";
  };
}

