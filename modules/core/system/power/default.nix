# modules/core/system/power/default.nix
# ==============================================================================
# Power Management Configuration
# ==============================================================================
# This configuration manages power-related settings including:
# - UPower configuration
# - Power management policies
# - Thermal control
# - System logging
#
# Author: Kenan Pelit
# Modified: 2025-05-12 (COSMIC compatibility)
# ==============================================================================
{ ... }:
{
  services = {
    # UPower Configuration
    # UPower handles power management events and battery state
    upower = {
      enable = true;
      criticalPowerAction = "Hibernate";  # Hibernate when battery critically low
    };
    
    # Power Management (logind)
    # Controls system behavior for power events like lid close
    logind = {
      lidSwitch = "suspend";              # Suspend when laptop lid closed
      lidSwitchDocked = "suspend";        # Suspend when lid closed while docked
      lidSwitchExternalPower = "suspend"; # Suspend when lid closed on AC power
      extraConfig = ''
        HandlePowerKey=ignore             # Ignore power button press (prevent accidental shutdown)
        HandleSuspendKey=suspend          # Suspend when suspend key pressed
        HandleHibernateKey=hibernate      # Hibernate when hibernate key pressed
        IdleAction=suspend                # Action to take when system is idle
        IdleActionSec=60min               # Time before idle action is triggered
      '';
    };
    
    # TLP Power Management - Disabled for COSMIC compatibility
    # TLP provides advanced power management but conflicts with power-profiles-daemon
    tlp = {
      enable = false;  # Disabled to avoid conflict with power-profiles-daemon used by COSMIC
      settings = {
        # CPU Governor Settings (preserved for reference)
        CPU_SCALING_GOVERNOR_ON_AC = "performance";
        CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
        CPU_ENERGY_PERF_POLICY_ON_AC = "performance";
        CPU_ENERGY_PERF_POLICY_ON_BAT = "power";
        CPU_MIN_PERF_ON_AC = 0;
        CPU_MAX_PERF_ON_AC = 100;
        CPU_MIN_PERF_ON_BAT = 0;
        CPU_MAX_PERF_ON_BAT = 80;
      };
    };
    
    # Enable power-profiles-daemon for COSMIC compatibility
    # This provides a modern power management service that integrates well with desktop environments
    power-profiles-daemon.enable = true;
    
    # Thermal Management
    # Prevents overheating by monitoring and controlling temperature
    thermald.enable = true;
    
    # System Logging Configuration
    # Controls how much log data is stored
    journald = {
      extraConfig = ''
        SystemMaxUse=5G                 # Maximum disk space used by logs
        SystemMaxFileSize=500M          # Maximum size of individual log files
        MaxRetentionSec=1month          # How long to keep logs
      '';
    };
  };
}
