# modules/home/fusuma/default.nix
# ==============================================================================
# Home module for Fusuma touchpad gestures.
# Installs fusuma and deploys gesture config as user service.
# Tweak gesture mappings here instead of editing config.yml manually.
# ==============================================================================

{ config, pkgs, lib, ... }:
let
  cfg = config.my.user.fusuma;
  workspaceMonitor = pkgs.writeShellScriptBin "fusuma-workspace-monitor" ''
    #!/usr/bin/env bash
    set -euo pipefail

    hypr="${config.home.profileDirectory}/bin/hypr-workspace-monitor"
    niri="${config.home.profileDirectory}/bin/niri-workspace-monitor"

    if [[ -n "''${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
      exec "$hypr" "$@"
    fi

    if [[ -n "''${NIRI_SOCKET:-}" ]]; then
      exec "$niri" "$@"
    fi

    case "''${XDG_CURRENT_DESKTOP:-}''${XDG_SESSION_DESKTOP:-}" in
      *Hyprland*|*hyprland*)
        exec "$hypr" "$@"
        ;;
      *niri*|*Niri*)
        exec "$niri" "$@"
        ;;
    esac

    echo "fusuma-workspace-monitor: compositor not detected (need HYPRLAND_INSTANCE_SIGNATURE or NIRI_SOCKET)" >&2
    exit 127
  '';

  fullscreen = pkgs.writeShellScriptBin "fusuma-fullscreen" ''
    #!/usr/bin/env bash
    set -euo pipefail

    mode="''${1:-toggle}"
    shift || true

    if [[ -n "''${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
      case "$mode" in
        in|on|1) exec ${pkgs.hyprland}/bin/hyprctl dispatch fullscreen 1 ;;
        out|off|0) exec ${pkgs.hyprland}/bin/hyprctl dispatch fullscreen 0 ;;
        toggle) exec ${pkgs.hyprland}/bin/hyprctl dispatch fullscreen 1 ;;
        *) exec ${pkgs.hyprland}/bin/hyprctl dispatch fullscreen 1 ;;
      esac
    fi

    if [[ -n "''${NIRI_SOCKET:-}" ]]; then
      if command -v niri >/dev/null 2>&1; then
        exec niri msg action fullscreen-window
      fi
      echo "fusuma-fullscreen: niri not found in PATH" >&2
      exit 127
    fi

    case "''${XDG_CURRENT_DESKTOP:-}''${XDG_SESSION_DESKTOP:-}" in
      *Hyprland*|*hyprland*)
        exec ${pkgs.hyprland}/bin/hyprctl dispatch fullscreen 1
        ;;
      *niri*|*Niri*)
        if command -v niri >/dev/null 2>&1; then
          exec niri msg action fullscreen-window
        fi
        echo "fusuma-fullscreen: niri not found in PATH" >&2
        exit 127
        ;;
    esac

    echo "fusuma-fullscreen: compositor not detected (need HYPRLAND_INSTANCE_SIGNATURE or NIRI_SOCKET)" >&2
    exit 127
  '';
in
{
  options.my.user.fusuma = {
    enable = lib.mkEnableOption "Fusuma gesture recognizer";
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      workspaceMonitor
      fullscreen
    ];

    # =============================================================================
    # Service Configuration
    # =============================================================================
    services.fusuma = {
      enable = true;
      package = pkgs.fusuma;
      # =============================================================================
      # Gesture Settings
      # =============================================================================
      settings = {
        # ---------------------------------------------------------------------------
        # Sensitivity Settings
        # ---------------------------------------------------------------------------
        threshold = {
          swipe = 0.7;
          pinch = 0.3;
        };
        # ---------------------------------------------------------------------------
        # Timing Settings
        # ---------------------------------------------------------------------------
        interval = {
          swipe = 0.6;
          pinch = 1.0;
        };
        # ---------------------------------------------------------------------------
        # Gesture Mappings
        # ---------------------------------------------------------------------------
        swipe = {
          "3" = {
            right = {
              command = "${workspaceMonitor}/bin/fusuma-workspace-monitor -tn";
              threshold = 0.6;
            };
            left = {
              command = "${workspaceMonitor}/bin/fusuma-workspace-monitor -tp";
              threshold = 0.6;
            };
            up = {
              command = "${workspaceMonitor}/bin/fusuma-workspace-monitor -wt";
              threshold = 0.6;
            };
            down = {
              command = "${workspaceMonitor}/bin/fusuma-workspace-monitor -mt";
              threshold = 0.6;
            };
          };
          "4" = {
            up.command = "${workspaceMonitor}/bin/fusuma-workspace-monitor -msf";
            down.command = "${workspaceMonitor}/bin/fusuma-workspace-monitor -ms";
            right.command = "${workspaceMonitor}/bin/fusuma-workspace-monitor -wr";
            left.command = "${workspaceMonitor}/bin/fusuma-workspace-monitor -wl";
          };
        };
        pinch = {
          "3" = {
            "in" = { command = "${fullscreen}/bin/fusuma-fullscreen in"; };
            out = { command = "${fullscreen}/bin/fusuma-fullscreen out"; };
          };
        };
      };
    };
  };
}
