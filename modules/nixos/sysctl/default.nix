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
    # NOTE: This sysctl does not exist on this kernel; backlog must be set via
    # the kernel cmdline (`audit_backlog_limit=...`) instead.
  };
}
