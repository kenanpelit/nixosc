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
#   mango-set workspace-monitor <flags>
# ==============================================================================

set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  mango-set <command>

Commands:
  tty   Start Mango session (DM/TTY)
  workspace-monitor  Workspace/monitor helper (Fusuma)
EOF
}

cmd="${1:-}"
shift || true

case "${cmd}" in
  tty)
    export XDG_SESSION_TYPE=wayland
    export XDG_CURRENT_DESKTOP=mango
    export XDG_SESSION_DESKTOP=mango
    export NIXOS_OZONE_WL=1

    if command -v dbus-update-activation-environment >/dev/null 2>&1; then
      dbus-update-activation-environment --systemd \
        DISPLAY WAYLAND_DISPLAY \
        XDG_CURRENT_DESKTOP XDG_SESSION_DESKTOP XDG_SESSION_TYPE \
        NIXOS_OZONE_WL XCURSOR_THEME XCURSOR_SIZE \
        >/dev/null 2>&1 || true
    fi

    if command -v systemctl >/dev/null 2>&1; then
      systemctl --user reset-failed >/dev/null 2>&1 || true
      systemctl --user start mango-session.target >/dev/null 2>&1 || true
    fi

    exec mango
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
    direction="${1:-}"
    shift || true

    case "${direction}" in
      -wl|-mp) direction="left" ;;
      -wr|-mn) direction="right" ;;
      *)
        echo "mango-set workspace-monitor: unsupported args: ${direction:-} $*" >&2
        exit 2
        ;;
    esac

    if ! command -v mmsg >/dev/null 2>&1; then
      echo "mango-set workspace-monitor: mmsg not found in PATH" >&2
      exit 127
    fi

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
      seltags=1
    fi

    current=1
    for i in 1 2 3 4 5 6 7 8 9; do
      if (( (seltags & (1 << (i - 1))) != 0 )); then
        current="${i}"
        break
      fi
    done

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
