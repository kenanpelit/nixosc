# modules/core/vpn/default.nix
# ==============================================================================
# VPN Configuration
# ==============================================================================
# This configuration manages VPN settings including:
# - Mullvad VPN setup
# - WireGuard support
# - Network namespace isolation
# - VPN utilities
#
# Author: Kenan Pelit
# ==============================================================================
{ pkgs, ... }:
{
  # Mullvad VPN Service
  services.mullvad-vpn = {
    enable = true;
    package = pkgs.mullvad-vpn;
  };
  
  # WireGuard kernel module
  networking.wireguard.enable = true;
  
  # VPN and networking tools
  environment.systemPackages = with pkgs; [
    mullvad-vpn          # Mullvad GUI/CLI
    wireguard-tools      # WireGuard utilities
    openresolv           # DNS management
  ];
  
  # Network security for VPN
  networking = {
    # Enable IP forwarding for WireGuard
    firewall = {
      # Allow Mullvad app
      allowedTCPPorts = [ ];
      allowedUDPPorts = [ ];
      # Trust WireGuard interface
      trustedInterfaces = [ "wg+" ];
    };
  };
  
  # Note: DNS configuration is handled in modules/core/dns
}

