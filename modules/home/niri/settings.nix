# modules/home/niri/settings.nix
# ==============================================================================
# Niri Core Settings - Modular Configuration
#
# Contains Layout, Animations, Gestures, Colors, and Hardware defaults.
# Imported by default.nix
# ==============================================================================
{ lib, config, pkgs, palette, gtkTheme, cursorTheme, iconTheme, ... }:

let
  cfg = config.my.desktop.niri;
in
{
  layout = ''
    layout {
      gaps 12;
      center-focused-column "on-overflow";
      always-center-single-column;
      background-color "#00000000";

      focus-ring {
        on;
        width 3;
        active-gradient from="${palette.cyan}" to="${palette.mauve}" angle=45 relative-to="workspace-view";
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
        proportion 1.0;
      }

      // Match your preferred default (≈70% width)
      default-column-width { proportion 0.7; }
    }
  '';

  animations = ''
    animations {
      // Premium Motion Profile: Fluid curves with responsive slide dynamics.
      // Updated for softer spring feel (stiffness reduced).

      workspace-switch {
        spring damping-ratio=0.92 stiffness=1000 epsilon=0.0001;
      }

      window-open {
        duration-ms 300;
        curve "ease-out-expo";

        custom-shader r"
          vec4 open_color(vec3 coords_geo, vec3 size_geo) {
            float p = niri_clamped_progress;

            // macOS style: smooth scale + pronounced slide-up
            float scale = mix(0.95, 1.0, p);
            float y_off = mix(0.1, 0.0, p); 
            
            vec3 coords = vec3(
                (coords_geo.x - 0.5) / scale + 0.5,
                (coords_geo.y - 0.5 - y_off) / scale + 0.5,
                1.0
            );

            vec3 coords_tex = niri_geo_to_tex * coords;
            vec4 color = texture2D(niri_tex, coords_tex.st);

            // Clean linear fade
            color *= p;
            
            return color;
          }
        ";
      }
      window-close {
        duration-ms 200;
        curve "ease-out-quad";

        custom-shader r"
          vec4 close_color(vec3 coords_geo, vec3 size_geo) {
            float p = niri_clamped_progress;

            // Slide-down + scale-down on exit
            float scale = mix(1.0, 0.98, p);
            float y_off = mix(0.0, 0.05, p);
            
            vec3 coords = vec3(
                (coords_geo.x - 0.5) / scale + 0.5,
                (coords_geo.y - 0.5 - y_off) / scale + 0.5,
                1.0
            );

            vec3 coords_tex = niri_geo_to_tex * coords;
            vec4 color = texture2D(niri_tex, coords_tex.st);
            
            return color * (1.0 - p);
          }
        ";
      }

      // Snappy but smooth movement (Hyprland style responsiveness)
      // Stiffness reduced slightly for better fluidity
      horizontal-view-movement {
        spring damping-ratio=0.98 stiffness=900 epsilon=0.0001;
      }
      window-movement {
        spring damping-ratio=0.98 stiffness=900 epsilon=0.0001;
      }
      window-resize {
        spring damping-ratio=0.98 stiffness=900 epsilon=0.0001;

        custom-shader r"
          vec4 resize_color(vec3 coords_curr_geo, vec3 size_curr_geo) {
            vec3 coords_next_geo = niri_curr_geo_to_next_geo * coords_curr_geo;

            vec3 coords_stretch_prev = niri_geo_to_tex_prev * coords_curr_geo;
            vec3 coords_stretch_next = niri_geo_to_tex_next * coords_curr_geo;
            vec3 coords_crop_next = niri_geo_to_tex_next * coords_next_geo;

            bool can_crop_by_x = niri_curr_geo_to_next_geo[0][0] <= 1.0;
            bool can_crop_by_y = niri_curr_geo_to_next_geo[1][1] <= 1.0;
            bool crop = can_crop_by_x && can_crop_by_y;

            vec4 color;
            if (crop) {
              if (coords_curr_geo.x < 0.0 || 1.0 < coords_curr_geo.x ||
                  coords_curr_geo.y < 0.0 || 1.0 < coords_curr_geo.y) {
                color = vec4(0.0);
              } else {
                color = texture2D(niri_tex_next, coords_crop_next.st);
              }
            } else {
              vec4 prev = texture2D(niri_tex_prev, coords_stretch_prev.st);
              vec4 next = texture2D(niri_tex_next, coords_stretch_next.st);
              color = mix(prev, next, niri_clamped_progress);
            }

            return color;
          }
        ";
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
        spring damping-ratio=0.92 stiffness=1000 epsilon=0.0001;
      }
      recent-windows-close {
        spring damping-ratio=0.9 stiffness=800 epsilon=0.001;
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

    ${lib.optionalString cfg.preferNoCsd "prefer-no-csd;"}

    hotkey-overlay {
      skip-at-startup;
      hide-not-bound;
    }

    overview {
      zoom 0.25;
      backdrop-color "${palette.surface0}";
      workspace-shadow {
        softness 40;
        spread 12;
        offset x=0 y=12;
        color "#00000050";
      }
    }

    // Put wallpaper surfaces into the overview backdrop when available.
    layer-rule {
      match namespace="^wallpaper$";
      place-within-backdrop true;
    }

    ${lib.optionalString cfg.systemd.enable ''
    // Start session-scoped user services (niri-bootstrap, DMS, …).
    // Also exports WAYLAND_DISPLAY and friends into systemd --user so units that
    // need a Wayland client env do not start with an empty session.
    spawn-at-startup "${config.home.profileDirectory}/bin/niri-set" "session-start";
    ''}

    // Long-running daemons (Clipse, etc.) are started via systemd --user (niri-session.target).

    // Input Configuration
    input {
      workspace-auto-back-and-forth;
      focus-follows-mouse;
      warp-mouse-to-focus mode="center-xy";

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
        accel-profile "adaptive"
        accel-speed 1.0
        scroll-method "two-finger"
        scroll-factor 1.0
      }

      mouse {
        accel-profile "adaptive"
        accel-speed 0.0
        scroll-factor 1.0
      }

      trackpoint {
        accel-profile "adaptive"
        accel-speed 0.0
        middle-emulation
        scroll-method "on-button-down"
        scroll-button 273
        scroll-button-lock
      }
    }

    ${lib.optionalString cfg.deactivateUnfocusedWindows ''
    // Work around Electron/Chromium apps that treat "activated" as focus.
    debug {
      deactivate-unfocused-windows;
    }
    ''}

    // Switch Events
    switch-events {
      lid-close { spawn "${config.home.profileDirectory}/bin/niri-set" "lock" "--logind"; }
    }
  '';
}
