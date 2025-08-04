# modules/core/power/default.nix
# ==============================================================================
# Power Management Configuration
# ==============================================================================
# This configuration manages power-related settings including:
# - UPower and system power policies
# - Lid switch and suspend behavior
# - Thermal control and logging
# - WiFi power save optimization
# - Power management notifications
#
# Author: Kenan Pelit
# ==============================================================================
{ config, lib, pkgs, ... }:
{
  # System Power Services
  services = {
    # Power Management
    upower = {
      enable = true;
      criticalPowerAction = "Hibernate";
    };
    
    # Login and Suspend Management
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
    
    # Power Management Services (disabled for custom control)
    tlp.enable = false;
    power-profiles-daemon.enable = false;
    
    # Thermal Management
    thermald.enable = true;
    
    # System Logging Configuration
    journald.extraConfig = ''
      SystemMaxUse=5G
      SystemMaxFileSize=500M
      MaxRetentionSec=1month
    '';
  };

  # WiFi Power Save Optimization
  systemd = {
    # System-wide WiFi power save disable
    services.disable-wifi-power-save = {
      description = "Disable WiFi power save";
      after = [ "NetworkManager.service" ];
      requires = [ "NetworkManager.service" ];
      wantedBy = [ "multi-user.target" ];
      path = [ pkgs.networkmanager pkgs.gawk ];
      
      script = ''
        for interface in $(nmcli -t -f DEVICE device status | grep "^wlan")
        do
          nmcli connection modify type wifi wifi.powersave 2 || \
          nmcli radio wifi off && nmcli radio wifi on
        done
      '';
      
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = "yes";
        User = "root";
      };
    };

    # User notification service
    user.services.wifi-power-save-notify = {
      description = "Notify WiFi power save status";
      after = [ "graphical-session.target" "disable-wifi-power-save.service" ];
      bindsTo = [ "graphical-session.target" ];
      wantedBy = [ "graphical-session.target" ];
      
      environment = {
        WAYLAND_DISPLAY = "wayland-1";
        XDG_RUNTIME_DIR = "/run/user/1000";
        DBUS_SESSION_BUS_ADDRESS = "unix:path=/run/user/1000/bus";
      };
      
      path = [ pkgs.networkmanager pkgs.gawk pkgs.libnotify ];
      
      script = ''
        interface=$(nmcli -t -f DEVICE device status | grep "^wlan" | head -n1)
        if [ -n "$interface" ]; then
          notify-send -t 10000 "Wi-Fi Güç Tasarrufu" "$interface için güç tasarrufu kapatıldı."
        fi
      '';
      
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = "yes";
      };
    };
  };
}

