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

    router="${config.home.profileDirectory}/bin/wm-workspace"

    fusuma_mode=0
    if [[ "''${1:-}" == "--fusuma" ]]; then
      fusuma_mode=1
      shift
    fi

    if [[ -n "''${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
      # In Hyprland we want 4-finger left/right to change workspace (not monitor).
      # Keep the Fusuma config shared with Niri by translating monitor-next/prev to workspace-left/right.
      if [[ "$fusuma_mode" == "1" ]]; then
        case "''${1:-}" in
          -mn) shift; set -- -wr "''${@}" ;;
          -mp) shift; set -- -wl "''${@}" ;;
        esac
      fi
      exec "$router" "$@"
    fi

    if [[ -n "''${NIRI_SOCKET:-}" ]]; then
      # Avoid conflicting with Niri's built-in 3/4-finger gestures when invoked from Fusuma.
      if [[ "$fusuma_mode" == "1" ]]; then
        case "''${1:-}" in
          -wl|-wr|-wt|-mt|-ms|-msf|-tn|-tp)
            exit 0
            ;;
        esac
      fi
      exec "$router" "$@"
    fi

    case "''${XDG_CURRENT_DESKTOP:-}''${XDG_SESSION_DESKTOP:-}" in
      *mango*|*Mango*)
        # Mango has its own gesturebind support; Fusuma may still run for other gestures.
        # Only pass left/right workspace actions through; ignore the rest to avoid noise.
        if [[ "$fusuma_mode" == "1" ]]; then
          case "''${1:-}" in
            -wl|-wr|-mn|-mp) exec "$router" "$@" ;;
            *) exit 0 ;;
          esac
        fi
        exec "$router" "$@"
        ;;
    esac

    case "''${XDG_CURRENT_DESKTOP:-}''${XDG_SESSION_DESKTOP:-}" in
      *Hyprland*|*hyprland*)
        if [[ "$fusuma_mode" == "1" ]]; then
          case "''${1:-}" in
            -mn) shift; set -- -wr "''${@}" ;;
            -mp) shift; set -- -wl "''${@}" ;;
          esac
        fi
        exec "$router" "$@"
        ;;
      *niri*|*Niri*)
        if [[ "$fusuma_mode" == "1" ]]; then
          case "''${1:-}" in
            -wl|-wr|-wt|-mt|-ms|-msf|-tn|-tp)
              exit 0
              ;;
          esac
        fi
        exec "$router" "$@"
        ;;
    esac

    echo "fusuma-workspace-monitor: compositor not detected (need HYPRLAND_INSTANCE_SIGNATURE or NIRI_SOCKET or XDG_CURRENT_DESKTOP=mango)" >&2
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
              command = "${workspaceMonitor}/bin/fusuma-workspace-monitor --fusuma -tn";
              threshold = 0.6;
            };
            left = {
              command = "${workspaceMonitor}/bin/fusuma-workspace-monitor --fusuma -tp";
              threshold = 0.6;
            };
            up = {
              command = "${workspaceMonitor}/bin/fusuma-workspace-monitor --fusuma -wt";
              threshold = 0.6;
            };
            down = {
              command = "${workspaceMonitor}/bin/fusuma-workspace-monitor --fusuma -mt";
              threshold = 0.6;
            };
          };
          "4" = {
            up.command = "${workspaceMonitor}/bin/fusuma-workspace-monitor --fusuma -msf";
            down.command = "${workspaceMonitor}/bin/fusuma-workspace-monitor --fusuma -ms";
            right.command = "${workspaceMonitor}/bin/fusuma-workspace-monitor --fusuma -mn";
            left.command = "${workspaceMonitor}/bin/fusuma-workspace-monitor --fusuma -mp";
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
