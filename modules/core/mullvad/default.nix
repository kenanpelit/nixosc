# modules/core/mullvad/default.nix
# ==============================================================================
# Mullvad VPN Configuration
# ==============================================================================
{ config, pkgs, lib, ... }:
{
  # =============================================================================
  # Mullvad Service Configuration
  # =============================================================================
  services.mullvad-vpn = {
    enable = true;
    package = pkgs.mullvad-vpn;
  };

  # =============================================================================
  # System Packages
  # =============================================================================
  environment.systemPackages = with pkgs; [
    mullvad-vpn
  ];

  # =============================================================================
  # Firewall Configuration
  # =============================================================================
  networking.firewall = {
    # Port Configuration
    allowedTCPPorts = [ 53 1401 ];
    allowedUDPPorts = [ 53 1401 51820 ];
    
    # Security Settings
    checkReversePath = "strict";
    trustedInterfaces = [ "mullvad-" ];
    
    # Custom Firewall Rules
    extraCommands = ''
      # Default Policies
      ip46tables -P INPUT ACCEPT
      ip46tables -P OUTPUT ACCEPT
      ip46tables -P FORWARD DROP

      # Mullvad Interface Rules
      if systemctl is-active mullvad-daemon; then
        ip46tables -A OUTPUT -o mullvad-* -j ACCEPT
        ip46tables -A INPUT -i mullvad-* -j ACCEPT
        ip46tables -A OUTPUT -p udp --dport 53 -j ACCEPT
        ip46tables -A INPUT -p udp --sport 53 -j ACCEPT
      fi

      # Loopback and Established Connections
      ip46tables -A OUTPUT -o lo -j ACCEPT
      ip46tables -A INPUT -i lo -j ACCEPT
      ip46tables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
      ip46tables -A OUTPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
    '';
  };

  # =============================================================================
  # DNS Configuration
  # =============================================================================
  networking.nameservers = lib.mkIf config.services.mullvad-vpn.enable [
    "193.138.218.74"  # Mullvad DNS
    "1.1.1.1"         # Cloudflare DNS (fallback)
  ];
}
