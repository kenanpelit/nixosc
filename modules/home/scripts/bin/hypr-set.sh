#!/usr/bin/env bash
# ==============================================================================
# hypr-set - Hyprland helper multiplexer
# ==============================================================================
# Provides a single entrypoint for Hyprland helper tasks that are currently
# implemented as multiple small scripts under `modules/home/scripts/bin/`.
#
# Usage:
#   hypr-set <subcommand> [args...]
#
# Subcommands mostly forward to existing scripts to keep behavior identical.
# ==============================================================================

set -euo pipefail

: "${XDG_RUNTIME_DIR:="/run/user/$(id -u)"}"
PATH="/run/wrappers/bin:/run/current-system/sw/bin:/etc/profiles/per-user/${USER}/bin:${PATH}"

usage() {
  cat <<'EOF'
Usage:
  hypr-set <command> [args...]

Commands:
  tty                Start Hyprland (was: hyprland_tty)
  init               Session bootstrap (was: hypr-init)
  workspace-monitor  Workspace/monitor helper (was: hypr-workspace-monitor)
  switch             Smart monitor/workspace switcher (was: hypr-switch)
  layout-toggle      Toggle layout preset (was: hypr-layout_toggle)
  vlc-toggle         Toggle VLC helper (was: hypr-vlc_toggle)
  wifi-power-save    WiFi power save helper (was: hypr-wifi-power-save)
  airplane-mode      Airplane mode helper (was: hypr-airplane_mode)
  colorpicker        Color picker helper (was: hypr-colorpicker)
  start-batteryd     Battery daemon helper (was: hypr-start-batteryd)
EOF
}

cmd="${1:-}"
shift || true

case "$cmd" in
  tty) exec hyprland_tty "$@" ;;
  init) exec hypr-init "$@" ;;
  workspace-monitor) exec hypr-workspace-monitor "$@" ;;
  switch) exec hypr-switch "$@" ;;
  layout-toggle|layout_toggle) exec hypr-layout_toggle "$@" ;;
  vlc-toggle|vlc_toggle) exec hypr-vlc_toggle "$@" ;;
  wifi-power-save|wifi_power_save) exec hypr-wifi-power-save "$@" ;;
  airplane-mode|airplane_mode) exec hypr-airplane_mode "$@" ;;
  colorpicker|colorpicker) exec hypr-colorpicker "$@" ;;
  start-batteryd|start_batteryd) exec hypr-start-batteryd "$@" ;;

  ""|-h|--help|help) usage ;;
  *) echo "Unknown command: $cmd" >&2; usage >&2; exit 2 ;;
esac

