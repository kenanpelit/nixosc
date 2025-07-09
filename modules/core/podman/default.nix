# modules/core/podman/default.nix
# ==============================================================================
# Container Runtime Configuration (Podman + Registries)
# ==============================================================================
# This configuration manages container runtime including:
# - Podman service and Docker compatibility
# - Container registry configuration
# - Network and security settings
# - Automatic maintenance and cleanup
#
# Author: Kenan Pelit
# ==============================================================================
{ pkgs, ... }:
{
  virtualisation = {
    # Container registries configuration
    containers = {
      enable = true;
      registries = {
        search = [ "docker.io" "quay.io" ];
        insecure = [];
        block = [];
      };
    };
    
    # Podman container runtime
    podman = {
      enable = true;
      dockerCompat = true;
      
      defaultNetwork.settings = {
        dns_enabled = true;
      };
      
      autoPrune = {
        enable = true;
        flags = ["--all"];
        dates = "weekly";
      };
      
      extraPackages = with pkgs; [
        runc
        conmon
        skopeo
        slirp4netns
      ];
    };
  };
}

