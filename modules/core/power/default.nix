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
# modules/core/power/default.nix
{ config, lib, pkgs, ... }:
{
  services = {
    upower = {
      enable = true;
      criticalPowerAction = "Hibernate";
    };
    
    logind = {
      lidSwitch = "suspend";
      lidSwitchDocked = "suspend";  
      lidSwitchExternalPower = "suspend";
      extraConfig = ''
        HandlePowerKey=ignore
        HandleSuspendKey=suspend
        HandleHibernateKey=hibernate
        HandleLidSwitch=suspend
        HandleLidSwitchDocked=suspend
        HandleLidSwitchExternalPower=suspend
        IdleAction=ignore
      '';
    };
    
    tlp.enable = false;
    power-profiles-daemon.enable = false;
    thermald.enable = true;
    
    journald.extraConfig = ''
      SystemMaxUse=5G
      SystemMaxFileSize=500M
      MaxRetentionSec=1month
    '';
  };
}

