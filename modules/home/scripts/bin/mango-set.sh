#!/usr/bin/env bash
# ==============================================================================
# mango-set - Mango (MangoWC) session helper multiplexer
# ==============================================================================
# Minimal, self-contained entrypoint to integrate Mango sessions with:
# - systemd --user (graphical-session / mango-session targets)
# - DMS (dms.service is WantedBy mango-session.target)
#
# Usage:
#   mango-set tty
#   mango-set start
#   mango-set session-start
#   mango-set workspace-monitor <flags>
# ==============================================================================

set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  mango-set <command>

Commands:
  start          Start Mango session (DM/TTY)
  tty            Alias for start
  session-start  Export env to systemd --user; start mango-session.target
  workspace-monitor  Workspace/monitor helper (Fusuma)
EOF
}

cmd="${1:-}"
shift || true

case "${cmd}" in
  start)
    export XDG_SESSION_TYPE=wayland
    export XDG_CURRENT_DESKTOP=mango
    export XDG_SESSION_DESKTOP=mango
    export NIXOS_OZONE_WL=1

    exec mango
    ;;

  tty)
    exec "$0" start
    ;;

  session-start)
    # ----------------------------------------------------------------------------
    # Export environment to systemd --user and start mango-session.target.
    #
    # Must run *inside* the Mango session so WAYLAND_DISPLAY exists.
    # Mirrors niri-set/hypr-set patterns.
    # ----------------------------------------------------------------------------
    export SYSTEMD_OFFLINE=0

    # Ensure NixOS sudo wrapper wins when called from user services.
    case ":${PATH:-}:" in
      *":/run/wrappers/bin:"*) ;;
      *) export PATH="/run/wrappers/bin:${PATH:-}" ;;
    esac

    if ! command -v systemctl >/dev/null 2>&1; then
      exit 0
    fi

    timeout_bin=""
    if command -v timeout >/dev/null 2>&1; then
      timeout_bin="timeout"
    fi

    vars="WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE XDG_SESSION_DESKTOP GTK_THEME XCURSOR_THEME SYSTEMD_OFFLINE NIXOS_OZONE_WL"

    if [[ -n "$timeout_bin" ]]; then
      $timeout_bin 2s systemctl --user import-environment $vars >/dev/null 2>&1 || true
    else
      systemctl --user import-environment $vars >/dev/null 2>&1 || true
    fi

    if command -v dbus-update-activation-environment >/dev/null 2>&1; then
      if [[ -n "$timeout_bin" ]]; then
        $timeout_bin 2s dbus-update-activation-environment --systemd --all >/dev/null 2>&1 || true
      else
        dbus-update-activation-environment --systemd --all >/dev/null 2>&1 || true
      fi
    fi

    systemctl --user reset-failed >/dev/null 2>&1 || true
    systemctl --user start mango-session.target >/dev/null 2>&1 || true
    systemctl --user try-restart dms.service >/dev/null 2>&1 || true
    exit 0
    ;;

  workspace-monitor)
    # ----------------------------------------------------------------------------
    # Minimal workspace switcher for Mango via `mmsg` (dwl-ipc).
    #
    # Flags (aligned with hypr-set/niri-set conventions used by fusuma-workspace-monitor):
    #   -wl   workspace left
    #   -wr   workspace right
    #   -mp   (fusuma) previous => workspace left
    #   -mn   (fusuma) next     => workspace right
    # ----------------------------------------------------------------------------
    # systemd --user services may run with a minimal PATH.
    export PATH="/run/current-system/sw/bin:/etc/profiles/per-user/${USER}/bin:${PATH:-}"

    direction="${1:-}"
    shift || true

    cache_root="${XDG_CACHE_HOME:-$HOME/.cache}"
    cache_dir_candidate="$cache_root/mango-flow"
    if ! mkdir -p "$cache_dir_candidate" 2>/dev/null || [[ ! -w "$cache_dir_candidate" ]]; then
      cache_root="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
      cache_dir_candidate="$cache_root/mango-flow"
      mkdir -p "$cache_dir_candidate" 2>/dev/null || true
    fi
    readonly CACHE_DIR="$cache_dir_candidate"
    readonly PREVIOUS_TAG_FILE="$CACHE_DIR/previous_tag"
    readonly MONITOR_STATE_FILE="$CACHE_DIR/monitor_state"

    ensure_state_files() {
      mkdir -p "$CACHE_DIR" 2>/dev/null || true
      if [[ ! -f "$PREVIOUS_TAG_FILE" ]]; then echo "1" >"$PREVIOUS_TAG_FILE" 2>/dev/null || true; fi
      if [[ ! -f "$MONITOR_STATE_FILE" ]]; then echo "down" >"$MONITOR_STATE_FILE" 2>/dev/null || true; fi
    }

    current_tag() {
      # Find current selected tag on the active output.
      active_output="$(
        mmsg -g -o 2>/dev/null \
          | awk '$2=="selmon" && $3=="1" {print $1; exit}'
      )"

      seltags="$(
        if [[ -n "${active_output:-}" ]]; then
          mmsg -g -t -o "${active_output}" 2>/dev/null \
            | awk '$2=="tags" {print $4; exit}'
        fi
      )"

      if [[ -z "${seltags:-}" ]]; then
        echo "1"
        return 0
      fi

      for i in 1 2 3 4 5 6 7 8 9; do
        if (( (seltags & (1 << (i - 1))) != 0 )); then
          echo "${i}"
          return 0
        fi
      done

      echo "1"
    }

    save_current_as_previous() {
      local current
      current="$(current_tag)"
      echo "$current" >"$PREVIOUS_TAG_FILE" 2>/dev/null || true
    }

    toggle_previous_tag() {
      local prev cur
      prev="$(cat "$PREVIOUS_TAG_FILE" 2>/dev/null || echo "1")"
      cur="$(current_tag)"
      if [[ -n "$prev" && "$prev" != "$cur" ]]; then
        save_current_as_previous
        exec mmsg -s -t "$prev"
      fi
      exit 0
    }

    focus_monitor_toggle() {
      local state
      state="$(cat "$MONITOR_STATE_FILE" 2>/dev/null || echo "down")"
      if [[ "$state" == "down" ]]; then
        echo "up" >"$MONITOR_STATE_FILE" 2>/dev/null || true
        exec mmsg -s -d focusmon,down
      else
        echo "down" >"$MONITOR_STATE_FILE" 2>/dev/null || true
        exec mmsg -s -d focusmon,up
      fi
    }

    ensure_state_files

    case "${direction}" in
      # Workspace left/right (tags)
      -wl|-mp) direction="left" ;;
      -wr|-mn) direction="right" ;;

      # Toggle previous workspace
      -wt) toggle_previous_tag ;;

      # Browser tab navigation (WM-agnostic; uses wtype).
      -tn)
        if command -v wtype >/dev/null 2>&1; then
          wtype -M ctrl -k tab 2>/dev/null || true
        fi
        exit 0
        ;;
      -tp)
        if command -v wtype >/dev/null 2>&1; then
          wtype -M ctrl -M shift -k tab 2>/dev/null || true
        fi
        exit 0
        ;;

      # Monitor focus / shifting: map to focusmon up/down for Mango.
      -mt) focus_monitor_toggle ;;
      -msf) exec mmsg -s -d focusmon,up ;;
      -ms) exec mmsg -s -d focusmon,down ;;

      *)
        # Don't hard-fail a gesture pipeline; just no-op.
        exit 0
        ;;
    esac

    if ! command -v mmsg >/dev/null 2>&1; then
      echo "mango-set workspace-monitor: mmsg not found in PATH" >&2
      exit 127
    fi

    save_current_as_previous

    current="$(current_tag)"

    if [[ "${direction}" == "right" ]]; then
      next=$(( (current % 9) + 1 ))
    else
      next=$(( ((current + 7) % 9) + 1 ))
    fi

    exec mmsg -s -t "${next}"
    ;;

  ""|-h|--help|help)
    usage
    exit 0
    ;;

  *)
    echo "mango-set: unknown command: ${cmd}" >&2
    usage >&2
    exit 2
    ;;
esac
