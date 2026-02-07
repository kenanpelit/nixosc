# modules/home/fusuma/default.nix
# ==============================================================================
# Home module for Fusuma touchpad gestures.
# Installs fusuma and deploys gesture config as user service.
# Tweak gesture mappings here instead of editing config.yml manually.
# ==============================================================================

{ config, pkgs, lib, ... }:
let
  cfg = config.my.user.fusuma;
  hasScripts = config.my.user.scripts.enable or false;
  enableNiri = config.my.desktop.niri.enable or false;
  enableHyprland = config.my.desktop.hyprland.enable or false;
  niriOnly = enableNiri && !enableHyprland;
  gestureThreshold = if niriOnly then {
    swipe = 0.8;
    pinch = 0.3;
  } else {
    swipe = 0.7;
    pinch = 0.3;
  };
  gestureInterval = if niriOnly then {
    swipe = 0.7;
    pinch = 1.0;
  } else {
    swipe = 0.6;
    pinch = 1.0;
  };
  sessionTargets = [
    # Only start Fusuma inside compositor sessions that are known to support it.
    "hyprland-session.target"
    "niri-session.target"
  ];
  detectCompositorSnippet = ''
    log_error() {
      local message="$1"
      echo "$message" >&2
      if command -v logger >/dev/null 2>&1; then
        logger -t fusuma-helper -- "$message"
      fi
    }

    detect_compositor() {
      if [[ -n "''${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
        echo "hyprland"
        return 0
      fi
      if [[ -n "''${NIRI_SOCKET:-}" ]]; then
        echo "niri"
        return 0
      fi

      case "''${XDG_CURRENT_DESKTOP:-}''${XDG_SESSION_DESKTOP:-}" in
        *Hyprland*|*hyprland*)
          echo "hyprland"
          return 0
          ;;
        *niri*|*Niri*)
          echo "niri"
          return 0
          ;;
      esac

      return 1
    }
  '';
  swipeSettings = if niriOnly then {
    # In Niri-only setups keep Fusuma focused on monitor navigation to avoid
    # clashing with Niri's built-in 3/4-finger workspace gestures.
    "4" = {
      right.command = "${workspaceMonitor}/bin/fusuma-workspace-monitor --fusuma -mn";
      left.command = "${workspaceMonitor}/bin/fusuma-workspace-monitor --fusuma -mp";
    };
  } else {
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
  pinchSettings = if niriOnly then {
    # Niri fullscreen action is toggle-style; keep only pinch-in to avoid
    # in/out ambiguity.
    "3" = {
      "in" = { command = "${fullscreen}/bin/fusuma-fullscreen in"; };
    };
  } else {
    "3" = {
      "in" = { command = "${fullscreen}/bin/fusuma-fullscreen in"; };
      out = { command = "${fullscreen}/bin/fusuma-fullscreen out"; };
    };
  };
  workspaceMonitor = pkgs.writeShellScriptBin "fusuma-workspace-monitor" ''
    #!/usr/bin/env bash
    set -euo pipefail

    ${detectCompositorSnippet}

    resolve_router() {
      if [[ -n "''${WM_WORKSPACE_BIN:-}" && -x "''${WM_WORKSPACE_BIN}" ]]; then
        printf '%s\n' "''${WM_WORKSPACE_BIN}"
        return 0
      fi

      if command -v wm-workspace >/dev/null 2>&1; then
        command -v wm-workspace
        return 0
      fi

      printf '%s\n' "${config.home.profileDirectory}/bin/wm-workspace"
    }

    router="$(resolve_router)"
    if [[ ! -x "$router" ]]; then
      log_error "fusuma-workspace-monitor: wm-workspace not found/executable: $router"
      exit 127
    fi

    fusuma_mode=0
    if [[ "''${1:-}" == "--fusuma" ]]; then
      fusuma_mode=1
      shift
    fi

    compositor="$(detect_compositor || true)"
    case "$compositor" in
      hyprland)
        if [[ "$fusuma_mode" == "1" ]]; then
          case "''${1:-}" in
            -msf) shift; set -- -wu "''${@}" ;;
            -ms) shift; set -- -wd "''${@}" ;;
          esac
        fi
        exec "$router" "$@"
        ;;
      niri)
        if [[ "$fusuma_mode" == "1" ]]; then
          case "''${1:-}" in
            -wl|-wr|-wu|-wd|-wt|-mt|-ms|-msf|-tn|-tp)
              exit 0
              ;;
          esac
        fi
        exec "$router" "$@"
        ;;
    esac

    log_error "fusuma-workspace-monitor: compositor not detected (need HYPRLAND_INSTANCE_SIGNATURE or NIRI_SOCKET)"
    exit 127
  '';

  hyprscrollingFocus = pkgs.writeShellScriptBin "fusuma-hyprscrolling-focus" ''
    #!/usr/bin/env bash
    set -euo pipefail

    ${detectCompositorSnippet}

    direction="''${1:-}"
    case "$direction" in
      left|l) dir="l" ;;
      right|r) dir="r" ;;
      *)
        echo "usage: fusuma-hyprscrolling-focus {left|right}" >&2
        exit 2
        ;;
    esac

    compositor="$(detect_compositor || true)"

    # Niri has built-in horizontal swipe navigation; avoid double-triggering.
    if [[ "$compositor" == "niri" ]]; then
      exit 0
    fi

    if [[ "$compositor" != "hyprland" ]]; then
      log_error "fusuma-hyprscrolling-focus: compositor not detected"
      exit 127
    fi

    if ! command -v hyprctl >/dev/null 2>&1; then
      log_error "fusuma-hyprscrolling-focus: hyprctl not found in PATH"
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

    ${detectCompositorSnippet}

    mode="''${1:-toggle}"
    shift || true

    compositor="$(detect_compositor || true)"

    if [[ "$compositor" == "hyprland" ]]; then
      if ! command -v hyprctl >/dev/null 2>&1; then
        log_error "fusuma-fullscreen: hyprctl not found in PATH"
        exit 127
      fi
      case "$mode" in
        in|on|1) exec hyprctl dispatch fullscreen 1 ;;
        out|off|0) exec hyprctl dispatch fullscreen 0 ;;
        toggle) exec hyprctl dispatch fullscreen 1 ;;
        *) exec hyprctl dispatch fullscreen 1 ;;
      esac
    fi

    if [[ "$compositor" == "niri" ]]; then
      case "$mode" in
        out|off|0)
          # Niri fullscreen action is a toggle; avoid accidental unpaired toggles.
          exit 0
          ;;
      esac
      if command -v niri >/dev/null 2>&1; then
        exec niri msg action fullscreen-window
      fi
      log_error "fusuma-fullscreen: niri not found in PATH"
      exit 127
    fi

    log_error "fusuma-fullscreen: compositor not detected (need HYPRLAND_INSTANCE_SIGNATURE or NIRI_SOCKET)"
    exit 127
  '';

  overview = pkgs.writeShellScriptBin "fusuma-overview" ''
    #!/usr/bin/env bash
    set -euo pipefail

    ${detectCompositorSnippet}
    compositor="$(detect_compositor || true)"

    if [[ "$compositor" == "hyprland" ]]; then
      if command -v dms >/dev/null 2>&1; then
        exec dms ipc call hypr toggleOverview
      fi
      log_error "fusuma-overview: dms not found in PATH"
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
    assertions = [
      {
        assertion = hasScripts;
        message = "my.user.fusuma.enable requires my.user.scripts.enable (wm-workspace must be available).";
      }
    ];

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
        Restart = "on-failure";
        RestartSec = "2s";
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
          swipe = gestureThreshold.swipe;
          pinch = gestureThreshold.pinch;
        };
        # ---------------------------------------------------------------------------
        # Timing Settings
        # ---------------------------------------------------------------------------
        interval = {
          swipe = gestureInterval.swipe;
          pinch = gestureInterval.pinch;
        };
        # ---------------------------------------------------------------------------
        # Gesture Mappings
        # ---------------------------------------------------------------------------
        swipe = swipeSettings;
        pinch = pinchSettings;
      };
    };
  };
}
