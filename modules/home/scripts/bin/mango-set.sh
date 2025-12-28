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
#   mango-set init
#   mango-set lock
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
  init           Bootstrap Mango session (audio, optional tag layout)
  lock           Lock session via DMS/logind
  workspace-monitor  Workspace/monitor helper (Fusuma)
EOF
}

cmd="${1:-}"
shift || true

ensure_runtime_dir() {
  if [[ -n "${XDG_RUNTIME_DIR:-}" ]]; then
    return 0
  fi

  local uid
  uid="$(id -u 2>/dev/null || true)"
  if [[ -n "$uid" ]]; then
    export XDG_RUNTIME_DIR="/run/user/$uid"
  fi
}

detect_wayland_display() {
  if [[ -n "${WAYLAND_DISPLAY:-}" ]]; then
    return 0
  fi

  [[ -n "${XDG_RUNTIME_DIR:-}" ]] || return 0

  local sock
  for sock in "${XDG_RUNTIME_DIR}"/wayland-*; do
    [[ -S "$sock" ]] || continue
    export WAYLAND_DISPLAY
    WAYLAND_DISPLAY="$(basename "$sock")"
    return 0
  done
}

import_env_to_systemd() {
  command -v systemctl >/dev/null 2>&1 || return 0

  local timeout_bin=""
  if command -v timeout >/dev/null 2>&1; then
    timeout_bin="timeout"
  fi

  local vars=(
    WAYLAND_DISPLAY
    XDG_DATA_DIRS
    XDG_CONFIG_DIRS
    XDG_CURRENT_DESKTOP
    XDG_SESSION_TYPE
    XDG_SESSION_DESKTOP
    DESKTOP_SESSION
    SSH_AUTH_SOCK
    GTK_THEME
    GTK_USE_PORTAL
    XDG_ICON_THEME
    QT_ICON_THEME
    XCURSOR_THEME
    XCURSOR_SIZE
    NIXOS_OZONE_WL
    MOZ_ENABLE_WAYLAND
    QT_QPA_PLATFORM
    QT_QPA_PLATFORMTHEME
    QT_QPA_PLATFORMTHEME_QT6
    QT_WAYLAND_DISABLE_WINDOWDECORATION
    ELECTRON_OZONE_PLATFORM_HINT
  )

  if [[ -n "$timeout_bin" ]]; then
    $timeout_bin 2s systemctl --user import-environment "${vars[@]}" >/dev/null 2>&1 || true
  else
    systemctl --user import-environment "${vars[@]}" >/dev/null 2>&1 || true
  fi

  if command -v dbus-update-activation-environment >/dev/null 2>&1; then
    if [[ -n "$timeout_bin" ]]; then
      $timeout_bin 2s dbus-update-activation-environment --systemd "${vars[@]}" >/dev/null 2>&1 || true
    else
      dbus-update-activation-environment --systemd "${vars[@]}" >/dev/null 2>&1 || true
    fi
  fi
}

start_target() {
  command -v systemctl >/dev/null 2>&1 || return 0
  systemctl --user reset-failed >/dev/null 2>&1 || true
  systemctl --user start mango-session.target >/dev/null 2>&1 || true
}

restart_dms_if_running() {
  command -v systemctl >/dev/null 2>&1 || return 0
  systemctl --user try-restart dms.service >/dev/null 2>&1 || true
}

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

    ensure_runtime_dir
    detect_wayland_display
    import_env_to_systemd
    restart_dms_if_running
    start_target
    exit 0
    ;;

  init)
    # ----------------------------------------------------------------------------
    # Bootstrap for Mango sessions (mirrors the spirit of niri-set init).
    #
    # Workspace focus (enabled by default):
    #   MANGO_INIT_FOCUS_TAG=2
    #   MANGO_INIT_FOCUS_OUTPUT=DP-3
    #
    # Optional tag layout (disabled by default):
    #   MANGO_INIT_SET_OUTPUT_TAGS=1
    #   MANGO_INIT_PRIMARY_OUTPUT=DP-3    MANGO_INIT_PRIMARY_TAG=1
    #   MANGO_INIT_SECONDARY_OUTPUT=eDP-1 MANGO_INIT_SECONDARY_TAG=7
    # ----------------------------------------------------------------------------
    ensure_runtime_dir
    detect_wayland_display

    if [[ "${MANGO_INIT_SKIP_FOCUS_TAG:-0}" != "1" ]] && command -v mmsg >/dev/null 2>&1; then
      focus_tag="${MANGO_INIT_FOCUS_TAG:-2}"
      # Pin to external monitor by default.
      focus_output="${MANGO_INIT_FOCUS_OUTPUT:-DP-3}"

      current_output() {
        mmsg -g -o 2>/dev/null | awk '$2=="selmon" && $3=="1" {print $1; exit}'
      }

      focus_output_by_name() {
        local desired="$1"
        local cur
        cur="$(current_output)"
        [[ -z "$desired" || "$cur" == "$desired" ]] && return 0

        # `focusmon` dispatch is directional; try both ways and verify by reading selmon.
        for dir in down up; do
          for _ in 1 2 3 4 5; do
            mmsg -s -d "focusmon,${dir}" >/dev/null 2>&1 || true
            cur="$(current_output)"
            [[ "$cur" == "$desired" ]] && return 0
          done
        done

        return 1
      }

      # Best effort: focus desired output, then select tag on the focused output.
      focus_output_by_name "$focus_output" || true
      mmsg -s -t "$focus_tag" >/dev/null 2>&1 || true
    fi

    if command -v osc-soundctl >/dev/null 2>&1; then
      osc-soundctl init >/dev/null 2>&1 || true
    fi

    if [[ "${MANGO_INIT_SET_OUTPUT_TAGS:-0}" == "1" ]] && command -v mmsg >/dev/null 2>&1; then
      primary_output="${MANGO_INIT_PRIMARY_OUTPUT:-DP-3}"
      primary_tag="${MANGO_INIT_PRIMARY_TAG:-1}"
      secondary_output="${MANGO_INIT_SECONDARY_OUTPUT:-eDP-1}"
      secondary_tag="${MANGO_INIT_SECONDARY_TAG:-7}"

      mmsg -s -o "${primary_output}" -t "${primary_tag}" >/dev/null 2>&1 || true
      mmsg -s -o "${secondary_output}" -t "${secondary_tag}" >/dev/null 2>&1 || true
    fi

    exit 0
    ;;

  lock)
    if command -v dms >/dev/null 2>&1; then
      dms ipc call lock lock >/dev/null 2>&1 && exit 0
    fi
    if command -v loginctl >/dev/null 2>&1; then
      exec loginctl lock-session
    fi
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
