# modules/home/fusuma/default.nix
# ==============================================================================
# Home module for Fusuma touchpad gestures.
# Installs fusuma and deploys gesture config as user service.
# Tweak gesture mappings here instead of editing config.yml manually.
# ==============================================================================

{ config, pkgs, lib, ... }:
let
  cfg = config.my.user.fusuma;
  sessionTargets = [
    # Only start Fusuma inside compositor sessions that are known to support it.
    "hyprland-session.target"
    "niri-session.target"
  ];
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
      # In Hyprland we want 4-finger up/down to change workspace (vertical).
      # Keep the Fusuma config shared by translating monitor-shift to workspace up/down.
      if [[ "$fusuma_mode" == "1" ]]; then
        case "''${1:-}" in
          -msf) shift; set -- -wu "''${@}" ;;
          -ms) shift; set -- -wd "''${@}" ;;
        esac
      fi
      exec "$router" "$@"
    fi

    if [[ -n "''${NIRI_SOCKET:-}" ]]; then
      # Avoid conflicting with Niri's built-in 3/4-finger gestures when invoked from Fusuma.
      if [[ "$fusuma_mode" == "1" ]]; then
        case "''${1:-}" in
          -wl|-wr|-wu|-wd|-wt|-mt|-ms|-msf|-tn|-tp)
            exit 0
            ;;
        esac
      fi
      exec "$router" "$@"
    fi

    case "''${XDG_CURRENT_DESKTOP:-}''${XDG_SESSION_DESKTOP:-}" in
      *Hyprland*|*hyprland*)
        if [[ "$fusuma_mode" == "1" ]]; then
          case "''${1:-}" in
            -msf) shift; set -- -wu "''${@}" ;;
            -ms) shift; set -- -wd "''${@}" ;;
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

    echo "fusuma-workspace-monitor: compositor not detected (need HYPRLAND_INSTANCE_SIGNATURE or NIRI_SOCKET)" >&2
    exit 127
  '';

  hyprscrollingFocus = pkgs.writeShellScriptBin "fusuma-hyprscrolling-focus" ''
    #!/usr/bin/env bash
    set -euo pipefail

    direction="''${1:-}"
    case "$direction" in
      left|l) dir="l" ;;
      right|r) dir="r" ;;
      *)
        echo "usage: fusuma-hyprscrolling-focus {left|right}" >&2
        exit 2
        ;;
    esac

    # Niri has built-in horizontal swipe navigation; avoid double-triggering.
    if [[ -n "''${NIRI_SOCKET:-}" ]] || [[ "''${XDG_CURRENT_DESKTOP:-}" == "niri" ]] || [[ "''${XDG_SESSION_DESKTOP:-}" == "niri" ]]; then
      exit 0
    fi

    if ! command -v hyprctl >/dev/null 2>&1; then
      echo "fusuma-hyprscrolling-focus: hyprctl not found in PATH" >&2
      exit 127
    fi

    # Prefer hyprscrolling focus (also scrolls layout), but gracefully fall back
    # to standard directional focus if the current layout doesn't support it.
    if hyprctl dispatch layoutmsg "focus $dir" >/dev/null 2>&1; then
      exit 0
    fi

    exec hyprctl dispatch movefocus "$dir"
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

  overview = pkgs.writeShellScriptBin "fusuma-overview" ''
    #!/usr/bin/env bash
    set -euo pipefail

    if [[ -n "''${HYPRLAND_INSTANCE_SIGNATURE:-}" ]] || [[ "''${XDG_CURRENT_DESKTOP:-}" == *Hyprland* ]] || [[ "''${XDG_SESSION_DESKTOP:-}" == *Hyprland* ]]; then
      if command -v dms >/dev/null 2>&1; then
        exec dms ipc call hypr toggleOverview
      fi
      echo "fusuma-overview: dms not found in PATH" >&2
      exit 127
    fi

    # Niri has built-in gestures for overview; avoid double-triggering.
    exit 0
  '';
in
{
  options.my.user.fusuma = {
    enable = lib.mkEnableOption "Fusuma gesture recognizer";
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      workspaceMonitor
      hyprscrollingFocus
      fullscreen
      overview
    ];

    # Bind Fusuma lifecycle to compositor session targets (instead of
    # graphical-session.target), so it reliably starts on Niri/Hyprland.
    systemd.user.services.fusuma = {
      Unit = {
        After = sessionTargets;
        PartOf = sessionTargets;
      };
      Service = {
        # Ensure common tools are available when started from systemd --user.
        Environment = [
          "XDG_RUNTIME_DIR=/run/user/%U"
          "PATH=/run/current-system/sw/bin:/etc/profiles/per-user/%u/bin"
        ];
        PassEnvironment = [
          "WAYLAND_DISPLAY"
          "NIRI_SOCKET"
          "HYPRLAND_INSTANCE_SIGNATURE"
          "HYPRLAND_SOCKET"
          "SWAYSOCK"
          "XDG_CURRENT_DESKTOP"
          "XDG_SESSION_TYPE"
          "XDG_SESSION_DESKTOP"
        ];
      };
      Install = {
        WantedBy = lib.mkForce sessionTargets;
      };
    };

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
              command = "${hyprscrollingFocus}/bin/fusuma-hyprscrolling-focus right";
              threshold = 0.6;
            };
            left = {
              command = "${hyprscrollingFocus}/bin/fusuma-hyprscrolling-focus left";
              threshold = 0.6;
            };
            up = {
              command = "${workspaceMonitor}/bin/fusuma-workspace-monitor --fusuma -wu";
              threshold = 0.6;
            };
            down = {
              command = "${workspaceMonitor}/bin/fusuma-workspace-monitor --fusuma -wd";
              threshold = 0.6;
            };
          };
          "4" = {
            up.command = "${overview}/bin/fusuma-overview";
            down.command = "${overview}/bin/fusuma-overview";
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
