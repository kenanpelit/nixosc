# modules/core/network/base/default.nix
# ==============================================================================
# Base Network Configuration
# ==============================================================================
# This configuration manages basic network settings including:
# - Hostname configuration
# - IPv6 settings
# - DNS nameserver configuration
#
# Author: Kenan Pelit
# ==============================================================================

{ config, lib, host, ... }:
{
  networking = {
    hostName = "${host}";
    enableIPv6 = false;
    
    # DNS Configuration - Conditional based on Mullvad status
    nameservers = lib.mkMerge [
      (lib.mkIf (!config.services.mullvad-vpn.enable) [
       "1.1.1.1"  # Cloudflare Primary
       "1.0.0.1"  # Cloudflare Secondary
       "9.9.9.9"  # Quad9
      ])
      (lib.mkIf config.services.mullvad-vpn.enable [
       "193.138.218.74"  # Mullvad DNS
       "1.1.1.1"         # Cloudflare DNS (fallback)
      ])
    ];
  };
}
