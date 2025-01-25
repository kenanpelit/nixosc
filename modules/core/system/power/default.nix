# modules/core/system/power/default.nix
# ==============================================================================
# Power Management Configuration
# ==============================================================================
# This configuration manages power-related settings including:
# - UPower configuration
# - TLP power management
# - Thermal control
# - System logging
#
# Author: Kenan Pelit
# ==============================================================================

{ ... }:
{
  services = {
    # UPower Configuration
    upower = {
      enable = true;
      criticalPowerAction = "Hibernate";
    };

    # Power Management (logind)
    logind = {
      lidSwitch = "suspend";              # Laptop kapağı kapatıldığında
      lidSwitchDocked = "suspend";        # Dock'a bağlıyken kapak kapatıldığında
      lidSwitchExternalPower = "suspend"; # Harici güç varken kapak kapatıldığında
      extraConfig = ''
        HandlePowerKey=ignore             # Güç düğmesine basıldığında
        HandleSuspendKey=suspend          # Uyku tuşuna basıldığında
        HandleHibernateKey=hibernate      # Hazırda beklet tuşuna basıldığında
        IdleAction=suspend                # Boşta kalma eylemi
        IdleActionSec=60min               # Boşta kalma süresi
      '';
    };

    # TLP Power Management
    tlp = {
      enable = true;
      settings = {
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

    # Thermal Management
    thermald.enable = true;

    # System Logging
    journald = {
      extraConfig = ''
        SystemMaxUse=5G
        SystemMaxFileSize=500M
        MaxRetentionSec=1month
      '';
    };
  };
}
