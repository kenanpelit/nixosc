# modules/home/hyprland/hypridle.nix
# ==============================================================================
# Hypridle Configuration (Screen & Power Management) - Fixed Lid Switch
# ==============================================================================
{ config, lib, pkgs, ... }:
{
  # =============================================================================
  # Configuration File
  # =============================================================================
  home.file.".config/hypr/hypridle.conf".text = ''
    # ---------------------------------------------------------------------------
    # General Settings - Fixed for Suspend Issues
    # ---------------------------------------------------------------------------
    general {
        lock_cmd = pidof hyprlock || hyprlock
        # WORKAROUND: Kill existing hyprlock first, then start new one without screenshot
        before_sleep_cmd = pkill hyprlock; sleep 0.5; hyprlock --grace 0 & sleep 2
        after_sleep_cmd = hyprctl dispatch dpms on && sleep 2
        ignore_dbus_inhibit = false
        ignore_systemd_inhibit = false
    }
   
    # ---------------------------------------------------------------------------
    # Keyboard backlight off (5 minutes) - Klavye ışığı tasarrufu
    # ---------------------------------------------------------------------------
    listener {
        timeout = 300
        on-timeout = brightnessctl -sd platform::kbd_backlight set 0
        on-resume = brightnessctl -rd platform::kbd_backlight
    }
    
    # ---------------------------------------------------------------------------
    # Screen Dimming (15 minutes)
    # ---------------------------------------------------------------------------
    listener {
        timeout = 900
        on-timeout = brightnessctl -s set 10
        on-resume = brightnessctl -r
    }
    
    # ---------------------------------------------------------------------------
    # Screen Lock (30 minutes)
    # ---------------------------------------------------------------------------
    listener {
        timeout = 1800
        on-timeout = loginctl lock-session
    }
    
    # ---------------------------------------------------------------------------
    # Screen Off (31 minutes)
    # ---------------------------------------------------------------------------
    listener {
        timeout = 1860
        on-timeout = hyprctl dispatch dpms off
        on-resume = hyprctl dispatch dpms on
    }
    
    # ---------------------------------------------------------------------------
    # System Suspend (60 minutes) - Enhanced
    # ---------------------------------------------------------------------------
    listener {
        timeout = 3600
        on-timeout = systemctl suspend -i
        on-resume = hyprctl dispatch dpms on && sleep 1
    }
  '';
  
  # =============================================================================
  # Fixed Systemd Service (Less Restrictive)
  # =============================================================================
  systemd.user.services.hypridle = {
    Unit = {
      Description = "Hypridle daemon for idle management";
      Documentation = "man:hypridle(1)";
      After = ["hyprland-session.target"];
      PartOf = ["hyprland-session.target"];
      Requisite = ["hyprland-session.target"];
    };
    Service = {
      Type = "simple";
      ExecStart = "${pkgs.hypridle}/bin/hypridle";
      ExecReload = "/bin/kill -SIGUSR2 $MAINPID";
      Restart = "on-failure";
      RestartSec = "3";
      TimeoutStopSec = "10";
      KillMode = "mixed";
      
      # Less restrictive security (for suspend/resume compatibility)
      ProtectSystem = "false";     # Suspend için system access gerekli
      ProtectHome = "false";       # Home access gerekli
      PrivateNetwork = "false";    # Network access gerekli
      NoNewPrivileges = false;     # Privileges gerekli
    };
    Install = {
      WantedBy = ["hyprland-session.target"];
    };
  };
  
  # =============================================================================
  # Suspend/Resume Fix Service
  # =============================================================================
  systemd.user.services.suspend-resume-fix = {
    Unit = {
      Description = "Fix display issues after suspend/resume";
      After = ["suspend.target"];
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${pkgs.writeShellScript "suspend-resume-fix" ''
        #!/bin/bash
        # Wait a bit for system to stabilize
        sleep 2
        
        # Refresh Hyprland
        if pgrep -x Hyprland > /dev/null; then
          hyprctl dispatch dpms on
          hyprctl reload
        fi
        
        # Fix potential lock screen issues
        if pgrep -x hyprlock > /dev/null; then
          pkill -SIGUSR1 hyprlock
        fi
      ''}";
    };
    Install = {
      WantedBy = ["suspend.target"];
    };
  };
}

