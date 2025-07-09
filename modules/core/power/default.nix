# modules/core/power/default.nix
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
# Power Management Configuration - FIXED for Lid Suspend
# ==============================================================================
{ ... }:
{
  services = {
    # UPower Configuration
    upower = {
      enable = true;
      criticalPowerAction = "Hibernate";  # Hibernate when battery critically low
    };
    
    # Power Management (logind) - FIXED for lid suspend
    logind = {
      lidSwitch = "suspend";              # Suspend when laptop lid closed
      lidSwitchDocked = "suspend";        # Suspend when lid closed while docked  
      lidSwitchExternalPower = "suspend"; # Suspend when lid closed on AC power
      extraConfig = ''
        HandlePowerKey=ignore             # Ignore power button (prevent accidental shutdown)
        HandleSuspendKey=suspend          # Suspend when suspend key pressed
        HandleHibernateKey=hibernate      # Hibernate when hibernate key pressed
        HandleLidSwitch=suspend           # EXPLICIT: Suspend on lid close
        HandleLidSwitchDocked=suspend     # EXPLICIT: Suspend on lid close when docked
        HandleLidSwitchExternalPower=suspend # EXPLICIT: Suspend on lid close on AC
        IdleAction=ignore                 # FIXED: Don't compete with GNOME idle management
        # IdleActionSec removed - let GNOME handle idle
      '';
    };
    
    # TLP - Keep disabled to avoid conflicts
    tlp.enable = false;
    
    # FIXED: Disable power-profiles-daemon to avoid conflict with GNOME
    power-profiles-daemon.enable = false;  # This may conflict with GNOME power management
    
    # Thermal Management
    thermald.enable = true;
    
    # System Logging Configuration
    journald = {
      extraConfig = ''
        SystemMaxUse=5G
        SystemMaxFileSize=500M
        MaxRetentionSec=1month
      '';
    };
  };
  
  # ADDITION: Ensure systemd-logind has priority over other power managers
  systemd.extraConfig = ''
    [Login]
    HandleLidSwitch=suspend
    HandleLidSwitchDocked=suspend
    HandleLidSwitchExternalPower=suspend
  '';
}
