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
        border {
          active-color "${palette.sky}";
          inactive-color "${palette.surface0}";
        }
      }
    }
    workspace "9" { open-on-output "eDP-1"; }

    // Utility workspaces
    workspace "inbox" { open-on-output "DP-3"; }
    workspace "oscndrop" { open-on-output "DP-3"; }

    // Monitor Configuration
    output "DP-3" {
      mode "2560x1440@59.951";
      position x=0 y=0;
      scale 1.0;

      // Layout overrides for the main monitor (more useful width presets).
      layout {
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
        preset-column-widths {
          proportion 0.5;
          proportion 0.66667;
          proportion 1.0;
        }
      }
    }
  '';
}
