# modules/home/hyprland/hypridle.nix
# ==============================================================================
# Hypridle user config: idle/screen/power management under Hyprland session.
# Uses HM services.hypridle, session targets, and safe wrappers for devices.
# ==============================================================================
# - Locks via hyprlock and coordinates sleep/wake DPMS properly
# - Sensible defaults with clear, English comments
# ==============================================================================

{ config, lib, pkgs, ... }:
let
  cfg = config.my.desktop.hyprland;
  stasisEnabled = lib.attrByPath [ "my" "user" "stasis" "enable" ] false config;
in
lib.mkMerge [
  (lib.mkIf (cfg.enable && stasisEnabled) {
    warnings = [
      "my.user.stasis is enabled: disabling Hypridle to avoid double idle management."
    ];
  })

  (lib.mkIf (cfg.enable && !stasisEnabled) {
    services.hypridle = {
      enable = true;

      # Hypridle native settings mapped by Home-Manager;
      # HM will generate the config and a user service under the hood.
      settings = {
        # -----------------------------------------------------------------------
        # General: lock & sleep orchestration
        # -----------------------------------------------------------------------
        general = {
          # Start hyprlock only if not already running (idempotent)
          lock_cmd = "pidof hyprlock >/dev/null || hyprlock";

          # Always lock before suspend to avoid a visible desktop on resume
          before_sleep_cmd = "loginctl lock-session";

          # Bring displays back after resume; a short delay helps GPUs settle
          after_sleep_cmd  = "hyprctl dispatch dpms on && sleep 1";

          # Respect apps that set inhibit (e.g., video players or calls)
          ignore_dbus_inhibit    = false;
          ignore_systemd_inhibit = false;
        };

        listener = [
          # ---------------------------------------------------------------------
          # 1) Keyboard backlight OFF after 5 minutes (power saving)
          #    Wrapped in sh -c and tolerant to missing kbd backlight devices.
          # ---------------------------------------------------------------------
          {
            timeout    = 300; # seconds
            on-timeout = "sh -c 'brightnessctl -sd platform::kbd_backlight set 0 || true'";
            on-resume  = "sh -c 'brightnessctl -rd platform::kbd_backlight || true'";
          }

          # ---------------------------------------------------------------------
          # 2) Screen dim after 15 minutes
          #    Uses brightnessctl --save/--restore via -s/-r.
          # ---------------------------------------------------------------------
          {
            timeout    = 900;
            on-timeout = "sh -c 'brightnessctl -s set 10 || true'";
            on-resume  = "sh -c 'brightnessctl -r || true'";
          }

          # ---------------------------------------------------------------------
          # 3) Lock the session after 30 minutes (let PAM/screensaver do its job)
          # ---------------------------------------------------------------------
          {
            timeout    = 1800;
            on-timeout = "loginctl lock-session";
          }

          # ---------------------------------------------------------------------
          # 4) Turn displays OFF after 31 minutes (saves power without suspend)
          # ---------------------------------------------------------------------
          {
            timeout    = 1860;
            on-timeout = "hyprctl dispatch dpms off";
            on-resume  = "hyprctl dispatch dpms on";
          }

          # ---------------------------------------------------------------------
          # 5) Suspend the system after 60 minutes (battery-friendly)
          # ---------------------------------------------------------------------
          {
            timeout    = 3600;
            on-timeout = "systemctl suspend -i";
            on-resume  = "hyprctl dispatch dpms on && sleep 1";
          }
        ];
      };
    };
  })
]
