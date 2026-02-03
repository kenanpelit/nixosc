# modules/nixos/containers/default.nix
# ==============================================================================
# NixOS containers/Podman configuration: runtimes, registries, storage.
# Centralize container host defaults to keep OCI setup consistent.
# Adjust daemon toggles here instead of per-machine hacks.
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
