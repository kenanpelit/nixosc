# modules/home/hyprland/hypridle.nix
# ==============================================================================
# Hypridle Configuration (Screen & Power Management)
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
  '';

  # =============================================================================
  # Systemd Service
  # =============================================================================
  systemd.user.services.hypridle = {
    Unit = {
      Description = "Hypridle daemon";
      After = ["hyprland-session.target"];
      PartOf = ["hyprland-session.target"];
    };
    Service = {
      Type = "simple";
      ExecStart = "${pkgs.hypridle}/bin/hypridle";
      Restart = "always";
      RestartSec = "3";
    };
    Install = {
      WantedBy = ["hyprland-session.target"];
    };
  };
}
