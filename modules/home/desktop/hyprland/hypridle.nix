# modules/home/desktop/hyprland/hypridle.nix
# ==============================================================================
# Hypridle Configuration (Screen & Power Management) - Enhanced
# ==============================================================================
{ config, lib, pkgs, ... }:
{
  # =============================================================================
  # Configuration File
  # =============================================================================
  home.file.".config/hypr/hypridle.conf".text = ''
    # ---------------------------------------------------------------------------
    # General Settings
    # ---------------------------------------------------------------------------
    general {
        lock_cmd = pidof hyprlock || hyprlock
        before_sleep_cmd = loginctl lock-session
        after_sleep_cmd = hyprctl dispatch dpms on
        ignore_dbus_inhibit = false            # DBus inhibit'leri dinle (media player vs.)
        ignore_systemd_inhibit = false         # Systemd inhibit'leri dinle
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
    # System Suspend (60 minutes)
    # ---------------------------------------------------------------------------
    listener {
        timeout = 3600
        on-timeout = systemctl suspend -i
    }
    
    # ---------------------------------------------------------------------------
    # Keyboard backlight off (5 minutes) - Klavye ışığı tasarrufu
    # ---------------------------------------------------------------------------
    listener {
        timeout = 300
        on-timeout = brightnessctl -sd platform::kbd_backlight set 0
        on-resume = brightnessctl -rd platform::kbd_backlight
    }
  '';
  
  # =============================================================================
  # Enhanced Systemd Service
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
      RestartSec = "1";
      TimeoutStopSec = "10";
      KillMode = "mixed";
      
      # Security hardening
      PrivateNetwork = true;
      ProtectHome = "read-only";
      ProtectSystem = "strict";
      NoNewPrivileges = true;
    };
    Install = {
      WantedBy = ["hyprland-session.target"];
    };
  };
  
  # =============================================================================
  # Optional: Power Profiles Support
  # =============================================================================
  systemd.user.services.hypridle-power-profile = {
    Unit = {
      Description = "Hypridle power profile management";
      After = ["hypridle.service"];
      BindsTo = ["hypridle.service"];
    };
    Service = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.writeShellScript "set-power-profile" ''
        # AC/Battery power durumuna göre timing ayarla
        if cat /sys/class/power_supply/AC*/online 2>/dev/null | grep -q 1; then
          echo "AC power detected - extended timeouts"
        else
          echo "Battery power detected - aggressive power saving"
        fi
      ''}";
    };
    Install = {
      WantedBy = ["hypridle.service"];
    };
  };
}

