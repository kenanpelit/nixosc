# modules/core/containers/default.nix
# ==============================================================================
# Container Runtime Configuration
# ==============================================================================
# Configures Podman as the container engine for physical hosts.
# - Enables Podman
# - Enables Docker compatibility mode
# - Configures DNS for container networking
#
# ==============================================================================

{ lib, config, ... }:

let
  isPhysicalHost = config.my.host.isPhysicalHost;
in
{
  virtualisation.podman = lib.mkIf isPhysicalHost {
    enable = true;
    dockerCompat = true;
    defaultNetwork.settings.dns_enabled = true;
  };
}
