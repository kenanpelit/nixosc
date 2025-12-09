# modules/nixos/containers/default.nix
# ------------------------------------------------------------------------------
# NixOS module for containers (system-wide stack).
# Provides host defaults and service toggles declared in this file.
# Keeps machine-wide settings centralized under modules/nixos.
# Extend or override options here instead of ad-hoc host tweaks.
# ------------------------------------------------------------------------------

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
