# modules/core/network/dns/default.nix
# ==============================================================================
# DNS Configuration
# ==============================================================================
# This configuration manages DNS settings including:
# - DNS resolution service
# - Fallback DNS servers
#
# Author: Kenan Pelit
# ==============================================================================

{ ... }:
{
  services.resolved = {
    enable = true;
    fallbackDns = [ "1.1.1.1" "1.0.0.1" ];
  };
}
