# modules/nixos/apparmor/default.nix
# ==============================================================================
# NixOS AppArmor policy toggle and profile plumbing.
# Enable/disable LSM support and manage profile loading in one place.
# Keep confinement policy centralized instead of host-specific tweaks.
# ==============================================================================

{ ... }:
{
  security.apparmor.enable = true;

  environment.shellAliases = {
    aa-status   = "sudo aa-status";
    aa-enforce  = "sudo aa-enforce";
    aa-complain = "sudo aa-complain";
  };
}
