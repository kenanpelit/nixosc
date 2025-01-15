# modules/core/power/default.nix
# ==============================================================================
# Power Management Configuration
# ==============================================================================
{ config, lib, pkgs, ... }:
{
  # =============================================================================
  # UPower Service Configuration
  # =============================================================================
  services.upower = {
    enable = true;
    criticalPowerAction = "Hibernate";  # Action on critical battery level
  };

  # =============================================================================
  # Logind Power Management
  # =============================================================================
  services.logind = {
    # Lid Switch Actions
    lidSwitch = "suspend";               # When lid is closed
    lidSwitchDocked = "ignore";          # When docked with external display
    lidSwitchExternalPower = "suspend";  # When on external power

    # Power Management Settings
    extraConfig = ''
      HandlePowerKey=suspend         # Power button action
      HandleSuspendKey=suspend       # Suspend key action
      HandleHibernateKey=hibernate   # Hibernate key action
      IdleAction=suspend             # Action when idle
      IdleActionSec=30min            # Idle timeout
    '';
  };

  # =============================================================================
  # TLP Power Management (Laptop Optimized)
  # =============================================================================
  services.tlp = {
    enable = true;
    settings = {
      # CPU Power Management
      CPU_SCALING_GOVERNOR_ON_AC = "performance";
      CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
      CPU_ENERGY_PERF_POLICY_ON_AC = "performance";
      CPU_ENERGY_PERF_POLICY_ON_BAT = "power";

      # CPU Performance Limits
      CPU_MIN_PERF_ON_AC = 0;
      CPU_MAX_PERF_ON_AC = 100;
      CPU_MIN_PERF_ON_BAT = 0;
      CPU_MAX_PERF_ON_BAT = 80;
    };
  };

  # =============================================================================
  # Thermal Management
  # =============================================================================
  services.thermald.enable = true;  # Intel CPU thermal management
}
