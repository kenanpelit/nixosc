# modules/core/virtualization/podman/default.nix
# ==============================================================================
# Podman Configuration
# ==============================================================================
# This configuration manages Podman settings including:
# - Docker compatibility layer
# - Network settings
# - Automatic maintenance
# - Required packages
#
# Author: Kenan Pelit
# ==============================================================================

{ pkgs, ... }:
{
  virtualisation.podman = {
    enable = true;
    dockerCompat = true;        # Docker command compatibility
    
    # Network Configuration
    defaultNetwork.settings = {
      dns_enabled = true;
    };
    
    # Automatic Cleanup
    autoPrune = {
      enable = true;
      flags = ["--all"];        # Clean all unused images
      dates = "weekly";         # Weekly cleanup schedule
    };
    
    # Required Packages
    extraPackages = [
      pkgs.runc            # Container runtime
      pkgs.conmon          # Container monitoring
      pkgs.skopeo          # Container image tool
      pkgs.slirp4netns     # Rootless networking
    ];
  };
}
