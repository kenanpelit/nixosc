# modules/core/containers/default.nix
# Podman container config (physical host).

{ lib, isPhysicalHost ? false, ... }:

{
  virtualisation.podman = lib.mkIf isPhysicalHost {
    enable = true;
    dockerCompat = true;
    defaultNetwork.settings.dns_enabled = true;
  };
}
