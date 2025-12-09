# modules/nixos/sysctl/default.nix
# ==============================================================================
# NixOS sysctl tunables: kernel networking/performance knobs.
# Keep sysctl values centralized for consistency across hosts.
# Edit here instead of sprinkling sysctl settings in host configs.
# ==============================================================================

{ ... }:

{
  boot.kernel.sysctl = {
    "vm.swappiness"              = 60;
    "kernel.nmi_watchdog"        = 0;
    "kernel.audit_backlog_limit" = 262144;
  };
}
