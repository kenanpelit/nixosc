# modules/core/services/network/default.nix
# ==============================================================================
# Network Services Configuration
# ==============================================================================
# This configuration manages network service ports including:
# - Transmission service ports
# - Port range configurations
#
# Author: Kenan Pelit
# ==============================================================================

{ ... }:
{
  networking.firewall = {
    # Transmission Service Ports
    allowedTCPPorts = [ 9091 ];         # Web interface
    allowedTCPPortRanges = [{ 
      from = 51413; 
      to = 51413; 
    }];
    allowedUDPPortRanges = [{ 
      from = 51413; 
      to = 51413; 
    }];
  };
}
