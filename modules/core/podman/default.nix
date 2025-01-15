# modules/core/podman/default.nix
# ==============================================================================
# Podman Container Engine Configuration
# ==============================================================================
{ config, lib, pkgs, ... }:
{
  virtualisation = {
    # =============================================================================
    # Podman Configuration
    # =============================================================================
    podman = {
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

    # =============================================================================
    # Container Registry Configuration
    # =============================================================================
    containers = {
      enable = true;
      registries = {
        search = [ "docker.io" "quay.io" ];
        insecure = [];
        block = [];
      };
    };
  };
}
