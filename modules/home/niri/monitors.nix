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

    // Laptop-safe fallback profile.
    // Runtime profile written by `niri-set init` (dms/monitor-auto.kdl) can
    // override these assignments when an external monitor is connected.
    workspace "1" { open-on-output "eDP-1"; }
    workspace "2" { open-on-output "eDP-1"; }
    workspace "3" { open-on-output "eDP-1"; }
    workspace "4" { open-on-output "eDP-1"; }
    workspace "5" { open-on-output "eDP-1"; }
    workspace "6" { open-on-output "eDP-1"; }
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

    output "eDP-1" {
      mode "1920x1200@60.003";
      position x=0 y=0;
      scale 1.0;
      variable-refresh-rate on-demand=true;
    }
  '';
}
