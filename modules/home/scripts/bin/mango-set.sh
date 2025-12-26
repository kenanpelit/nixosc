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
# ==============================================================================

set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  mango-set <command>

Commands:
  tty   Start Mango session (DM/TTY)
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

