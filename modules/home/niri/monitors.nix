# modules/home/niri/monitors.nix
# ==============================================================================
# Niri Monitor & Workspace Configuration
#
# Defines output modes, positioning, and workspace assignments.
# Imported by default.nix
# ==============================================================================
{ lib, palette, ... }:

{
  config = ''
    // ========================================================================
    // Hardware Configuration (Monitors & Workspaces)
    // ========================================================================

    // Named Workspaces
    workspace "kenp" { open-on-output "DP-3"; }
    workspace "term" { open-on-output "DP-3"; }
    workspace "ai" { open-on-output "DP-3"; }
    workspace "cta" { open-on-output "DP-3"; }
    workspace "chat" { open-on-output "DP-3"; }
    workspace "media" { open-on-output "DP-3"; }
    workspace "tools" { open-on-output "eDP-1"; }
    workspace "mus" {
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
    workspace "msg" { open-on-output "eDP-1"; }

    // Monitor Configuration
    output "DP-3" {
      mode "2560x1440@59.951";
      position x=0 y=0;
      scale 1.0;

      // Layout overrides for the main monitor (more useful width presets).
      layout {
        default-column-width { proportion 0.5; }
        preset-column-widths {
          proportion 0.25;
          proportion 0.33333;
          proportion 0.5;
          proportion 0.66667;
          proportion 0.75;
          proportion 1.0;
        }
      }
    }

    output "eDP-1" {
      mode "1920x1200@60.003";
      position x=320 y=1440;
      scale 1.0;
      variable-refresh-rate on-demand=true;

      // Layout overrides for the laptop panel (bigger default, fewer presets).
      layout {
        default-column-width { proportion 1.0; }
        preset-column-widths {
          proportion 0.5;
          proportion 0.66667;
          proportion 1.0;
        }
      }
    }
  '';
}
