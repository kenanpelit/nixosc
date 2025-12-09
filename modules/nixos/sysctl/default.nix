# modules/nixos/sysctl/default.nix
# ------------------------------------------------------------------------------
# NixOS module for sysctl (system-wide stack).
# Provides host defaults and service toggles declared in this file.
# Keeps machine-wide settings centralized under modules/nixos.
# Extend or override options here instead of ad-hoc host tweaks.
# ------------------------------------------------------------------------------

{ ... }:

{
  boot.kernel.sysctl = {
    "vm.swappiness"              = 60;
    "kernel.nmi_watchdog"        = 0;
    "kernel.audit_backlog_limit" = 262144;
  };
}
