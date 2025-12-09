# modules/nixos/apparmor/default.nix
# ------------------------------------------------------------------------------
# NixOS module for apparmor (system-wide stack).
# Provides host defaults and service toggles declared in this file.
# Keeps machine-wide settings centralized under modules/nixos.
# Extend or override options here instead of ad-hoc host tweaks.
# ------------------------------------------------------------------------------

{ ... }:
{
  security.apparmor.enable = true;

  environment.shellAliases = {
    aa-status   = "sudo aa-status";
    aa-enforce  = "sudo aa-enforce";
    aa-complain = "sudo aa-complain";
  };
}
