# modules/core/sysctl/default.nix
# Kernel/sysctl tuning (non-network basics).

{ ... }:

{
  boot.kernel.sysctl = {
    "vm.swappiness"              = 60;
    "kernel.nmi_watchdog"        = 0;
    "kernel.audit_backlog_limit" = 8192;
  };
}
