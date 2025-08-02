# modules/core/dns/default.nix
# ==============================================================================
# DNS Configuration
# ==============================================================================
# This configuration manages DNS settings including:
# - DNS nameserver configuration with Mullvad VPN support
# - Conditional DNS switching based on VPN status
# - Fallback DNS servers for reliability
#
# Author: Kenan Pelit
# ==============================================================================
{ config, lib, host, ... }:
{
 networking = {
   hostName = "${host}";
   enableIPv6 = false;
   
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
 };
}

