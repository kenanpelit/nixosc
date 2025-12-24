# modules/home/niri/settings.nix
# ==============================================================================
# Niri Core Settings - Modular Configuration
#
# Contains Layout, Animations, Gestures, Colors, and Hardware defaults.
# Imported by default.nix
# ==============================================================================
{ lib, config, pkgs, palette, gtkTheme, cursorTheme, iconTheme, ... }:

{
  layout = ''
    layout {
      gaps 5;
      center-focused-column "never";
      background-color "#00000000";

      focus-ring {
        on;
        width 2;
        active-gradient from="${palette.cyan}" to="${palette.mauve}" angle=45;
        inactive-color "${palette.surface1}";
      }

      border {
        on;
        width 1;
        active-color "${palette.sky}";
        inactive-color "${palette.surface0}";
      }

      tab-indicator {
        hide-when-single-tab;
        place-within-column;
        width 4;
        gap 6;
        length total-proportion=0.9;
        position "top";
        gaps-between-tabs 4;
        corner-radius 8;
        active-color "${palette.cyan}";
        inactive-color "${palette.surface1}";
        urgent-color "${palette.red}";
      }

      insert-hint {
        color "${palette.skyA80}";
        gradient from="${palette.skyA80}" to="${palette.mauveA80}" angle=45 relative-to="workspace-view";
      }

      preset-column-widths {
        proportion 0.33333;
        proportion 0.5;
        proportion 0.66667;
      }

      default-column-width { proportion 0.5; }
    }
  '';

  animations = ''
    animations {
      workspace-switch {
        spring damping-ratio=1.0 stiffness=1000 epsilon=0.0001;
      }

      window-open {
        duration-ms 150;
        curve "ease-out-expo";
      }
      window-close {
        duration-ms 150;
        curve "ease-out-quad";
      }

      horizontal-view-movement {
        spring damping-ratio=1.0 stiffness=800 epsilon=0.0001;
      }
      window-movement {
        spring damping-ratio=1.0 stiffness=800 epsilon=0.0001;
      }
      window-resize {
        spring damping-ratio=1.0 stiffness=800 epsilon=0.0001;
      }

      config-notification-open-close {
        spring damping-ratio=0.6 stiffness=1000 epsilon=0.001;
      }
      exit-confirmation-open-close {
        spring damping-ratio=0.6 stiffness=500 epsilon=0.01;
      }
      screenshot-ui-open {
        duration-ms 200;
        curve "ease-out-quad";
      }
      overview-open-close {
        spring damping-ratio=1.0 stiffness=800 epsilon=0.0001;
      }
      recent-windows-close {
        spring damping-ratio=1.0 stiffness=800 epsilon=0.001;
      }
    }
  '';

  gestures = ''
    gestures {
      dnd-edge-view-scroll {
        trigger-width 30;
        delay-ms 100;
        max-speed 1500;
      }
      hot-corners {
        off;
      }
    }
  '';

  recentWindows = ''
    recent-windows {
      debounce-ms 0;
      open-delay-ms 0;
      highlight {
        active-color "${palette.mauveFF}";
        urgent-color "${palette.redFF}";
        padding 24;
        corner-radius 12;
      }
      previews {
        max-height 720;
        max-scale 0.6;
      }
      binds {
        Mod+Tab { next-window; }
        Mod+Shift+Tab { previous-window; }
      }
    }
  '';

  colors = ''
    // ========================================================================
    // Catppuccin Color Palette Reference
    // ========================================================================
    // Accents:  cyan=${palette.cyan} sky=${palette.sky} mauve=${palette.mauve} red=${palette.red}
    // Surfaces: surface0=${palette.surface0} surface1=${palette.surface1}
  '';

  hardwareDefault = ''
    // ========================================================================
    // Hardware Configuration
    // ========================================================================

    // Named Workspaces (1-9)
    workspace "1" { open-on-output "DP-3"; }
    workspace "2" { open-on-output "DP-3"; }
    workspace "3" { open-on-output "DP-3"; }
    workspace "4" { open-on-output "DP-3"; }
    workspace "5" { open-on-output "DP-3"; }
    workspace "6" { open-on-output "DP-3"; }
    workspace "7" { open-on-output "eDP-1"; }
    workspace "8" {
      open-on-output "eDP-1";
      layout {
        gaps 20;
        border {
          on;
          width 1;
          active-color "${palette.sky}";
          inactive-color "${palette.surface0}";
        }
      }
    }
    workspace "9" { open-on-output "eDP-1"; }

    // Monitor Configuration
    output "DP-3" {
      mode "2560x1440@59.951";
      position x=0 y=0;
      scale 1.0;
    }

    output "eDP-1" {
      mode "1920x1200@60.003";
      position x=320 y=1440;
      scale 1.0;
      variable-refresh-rate on-demand=true;
    }
  '';

  main = ''
    // ========================================================================
    // Niri Configuration - DankMaterialShell Edition
    // ========================================================================

    environment {
      XDG_CURRENT_DESKTOP "niri";
      XDG_SESSION_TYPE "wayland";
      XDG_SESSION_DESKTOP "niri";
      DESKTOP_SESSION "niri";

      GTK_THEME "${gtkTheme}";
      GTK_USE_PORTAL "1";
      XCURSOR_THEME "${cursorTheme}";
      XCURSOR_SIZE "24";
      XDG_ICON_THEME "${iconTheme}";
      QT_ICON_THEME "${iconTheme}";

      QT_QPA_PLATFORM "wayland;xcb";
      ELECTRON_OZONE_PLATFORM_HINT "auto";
      QT_QPA_PLATFORMTHEME "gtk3";
      QT_QPA_PLATFORMTHEME_QT6 "gtk3";
      QT_WAYLAND_DISABLE_WINDOWDECORATION "1";
      MOZ_ENABLE_WAYLAND "1";
      NIXOS_OZONE_WL "1";

      // Use a stable SSH agent socket provided by gnome-keyring on Wayland.
      // This helps prevent late-session passphrase prompts and gcr-prompter popups.
      SSH_AUTH_SOCK "$XDG_RUNTIME_DIR/keyring/ssh";
    }

    cursor {
      hide-when-typing;
      hide-after-inactive-ms 1000;
    }

    prefer-no-csd;

    hotkey-overlay {
      skip-at-startup;
      hide-not-bound;
    }

    // Start session-scoped user services (niri-init, nsticky, nirius, niriswitcher, DMS, …).
    // Also exports WAYLAND_DISPLAY and friends into systemd --user so units that
    // need a Wayland client env do not start with an empty session.
    spawn-at-startup "${config.home.profileDirectory}/bin/niri-set" "session-start";

    // Start Clipse clipboard daemon in Niri session.
    spawn-at-startup "clipse" "-listen";

    // Input Configuration
    input {
      workspace-auto-back-and-forth;
      focus-follows-mouse max-scroll-amount="0%";

      keyboard {
        xkb {
          layout "tr"
          variant "f"
          options "ctrl:nocaps"
        }
        repeat-delay 250
        repeat-rate 35
      }

      touchpad {
        tap
        dwt
        drag-lock
        tap-button-map "left-right-middle"
        middle-emulation
        click-method "clickfinger"
        accel-profile "flat"
        accel-speed 1.0
        scroll-method "two-finger"
        scroll-factor 1.0
      }

      mouse {
        accel-profile "flat"
        accel-speed 0.0
        scroll-factor 1.0
      }

      trackpoint {
        accel-profile "flat"
        accel-speed 0.0
        middle-emulation
        scroll-method "on-button-down"
        scroll-button 273
        scroll-button-lock
      }
    }

    // Switch Events
    switch-events {
      lid-close { spawn "${config.home.profileDirectory}/bin/niri-set" "lock" "--logind"; }
    }
  '';
}
