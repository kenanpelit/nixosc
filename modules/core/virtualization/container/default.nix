# modules/core/virtualization/container/default.nix
# ==============================================================================
# Container Registry Configuration
# ==============================================================================
# This configuration manages container registry settings including:
# - Registry search paths
# - Security policies
#
# Author: Kenan Pelit
# ==============================================================================

{ ... }:
{
  virtualisation.containers = {
    enable = true;
    registries = {
      search = [ "docker.io" "quay.io" ];
      insecure = [];
      block = [];
    };
  };
}
