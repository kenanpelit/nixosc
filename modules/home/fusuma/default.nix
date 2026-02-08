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
  preferNiriTuning = enableNiri;
  gestureThreshold = if preferNiriTuning then {
    swipe = 0.8;
    pinch = 0.3;
  } else {
    swipe = 0.7;
    pinch = 0.3;
  };
  gestureInterval = if preferNiriTuning then {
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
      # Optional override for debugging.
      case "''${FUSUMA_COMPOSITOR:-}" in
        niri|hyprland)
          echo "''${FUSUMA_COMPOSITOR}"
          return 0
          ;;
      esac

      # Prefer explicit Niri markers first. In long-lived systemd --user
      # sessions, HYPRLAND_INSTANCE_SIGNATURE may remain set from a previous
      # login and cause false Hyprland detection.
      if [[ -n "''${NIRI_SOCKET:-}" && -S "''${NIRI_SOCKET}" ]]; then
        echo "niri"
        return 0
      fi

      case "''${XDG_CURRENT_DESKTOP:-}''${XDG_SESSION_DESKTOP:-}" in
        *niri*|*Niri*)
          echo "niri"
          return 0
          ;;
        *Hyprland*|*hyprland*)
          echo "hyprland"
          return 0
          ;;
      esac

      if [[ -n "''${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
        local runtime_dir hypr_socket
        runtime_dir="''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
        hypr_socket="$runtime_dir/hypr/''${HYPRLAND_INSTANCE_SIGNATURE}/.socket.sock"
        if [[ -S "$hypr_socket" ]]; then
          echo "hyprland"
          return 0
        fi
      fi

      return 1
    }
  '';
  swipeSettings = {
    # Runtime-router based mapping: the same gesture config is generated once,
    # and helper scripts choose compositor-specific behavior at execution time.
    "3" = {
      right = {
        command = "${swipeRouter}/bin/fusuma-swipe 3 right";
        threshold = 0.6;
      };
      left = {
        command = "${swipeRouter}/bin/fusuma-swipe 3 left";
        threshold = 0.6;
      };
      up = {
        command = "${swipeRouter}/bin/fusuma-swipe 3 up";
        threshold = 0.6;
      };
      down = {
        command = "${swipeRouter}/bin/fusuma-swipe 3 down";
        threshold = 0.6;
      };
    };
    "4" = {
      up.command = "${swipeRouter}/bin/fusuma-swipe 4 up";
      down.command = "${swipeRouter}/bin/fusuma-swipe 4 down";
      right.command = "${swipeRouter}/bin/fusuma-swipe 4 right";
      left.command = "${swipeRouter}/bin/fusuma-swipe 4 left";
    };
  };
  pinchSettings = {
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

  swipeRouter = pkgs.writeShellScriptBin "fusuma-swipe" ''
    #!/usr/bin/env bash
    set -euo pipefail

    ${detectCompositorSnippet}

    fingers="''${1:-}"
    direction="''${2:-}"

    case "$fingers:$direction" in
      3:left|3:right|3:up|3:down|4:left|4:right|4:up|4:down) ;;
      *)
        echo "usage: fusuma-swipe <3|4> <left|right|up|down>" >&2
        exit 2
        ;;
    esac

    compositor="$(detect_compositor || true)"
    case "$fingers" in
      4)
        case "$direction" in
          left) exec "${workspaceMonitor}/bin/fusuma-workspace-monitor --fusuma -mp" ;;
          right) exec "${workspaceMonitor}/bin/fusuma-workspace-monitor --fusuma -mn" ;;
          up|down) exec "${overview}/bin/fusuma-overview" ;;
        esac
        ;;
      3)
        if [[ "$compositor" == "niri" ]]; then
          # Niri already has native workspace/overview swipe gestures.
          exit 0
        fi
        if [[ "$compositor" != "hyprland" ]]; then
          log_error "fusuma-swipe: compositor not detected"
          exit 127
        fi

        case "$direction" in
          up) exec "${workspaceMonitor}/bin/fusuma-workspace-monitor --fusuma -wu" ;;
          down) exec "${workspaceMonitor}/bin/fusuma-workspace-monitor --fusuma -wd" ;;
          left|right)
            if ! command -v hyprctl >/dev/null 2>&1; then
              log_error "fusuma-swipe: hyprctl not found in PATH"
              exit 127
            fi
            if [[ "$direction" == "left" ]]; then
              dir="l"
            else
              dir="r"
            fi

            # Prefer hyprscrolling focus (also scrolls layout), fall back to
            # standard directional focus.
            if hyprctl dispatch layoutmsg "focus $dir" >/dev/null 2>&1; then
              exit 0
            fi

            exec hyprctl dispatch movefocus "$dir"
            ;;
        esac
        ;;
    esac
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
      {
        assertion = enableNiri || enableHyprland;
        message = "my.user.fusuma.enable requires at least one compositor: my.desktop.niri.enable or my.desktop.hyprland.enable.";
      }
    ];

    home.packages = [
      workspaceMonitor
      swipeRouter
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
