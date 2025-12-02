# modules/core/sysctl/default.nix
# ==============================================================================
# Kernel Sysctl Tuning
# ==============================================================================
# General kernel parameter tuning (excluding network/TCP).
# - Virtual memory swappiness
# - NMI watchdog disablement
# - Audit backlog limit
#
# ==============================================================================

{ ... }:

{
  boot.kernel.sysctl = {
    "vm.swappiness"              = 60;
    "kernel.nmi_watchdog"        = 0;
    "kernel.audit_backlog_limit" = 8192;
  };
}
