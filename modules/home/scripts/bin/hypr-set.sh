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

resolve_helpers_dir() {
  local candidates=(
    "${HYPR_SET_HELPERS_DIR:-}"
    "/etc/profiles/per-user/${USER}/share/osc/hypr"
    "${HOME}/.nix-profile/share/osc/hypr"
    "${HOME}/.local/state/nix/profiles/profile/share/osc/hypr"
  )

  local d
  for d in "${candidates[@]}"; do
    [[ -n "$d" && -d "$d" ]] && { printf '%s\n' "$d"; return 0; }
  done
  return 1
}

helpers_dir="$(resolve_helpers_dir 2>/dev/null || true)"
exec_helper() {
  local file="$1"; shift
  exec "${helpers_dir}/${file}" "$@"
}

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

if [[ -z "${cmd:-}" || "$cmd" == "-h" || "$cmd" == "--help" || "$cmd" == "help" ]]; then
  usage
  exit 0
fi

if [[ -z "${helpers_dir:-}" ]]; then
  echo "hypr-set: helper scripts not found (expected e.g. /etc/profiles/per-user/${USER}/share/osc/hypr)" >&2
  echo "hypr-set: rebuild Home Manager so osc-hypr helpers get installed" >&2
  exit 1
fi

case "$cmd" in
  tty) exec_helper hyprland_tty.sh "$@" ;;
  init) exec_helper hypr-init.sh "$@" ;;
  workspace-monitor) exec_helper hypr-workspace-monitor.sh "$@" ;;
  switch) exec_helper hypr-switch.sh "$@" ;;
  layout-toggle|layout_toggle) exec_helper hypr-layout_toggle.sh "$@" ;;
  vlc-toggle|vlc_toggle) exec_helper hypr-vlc_toggle.sh "$@" ;;
  wifi-power-save|wifi_power_save) exec_helper hypr-wifi-power-save.sh "$@" ;;
  airplane-mode|airplane_mode) exec_helper hypr-airplane_mode.sh "$@" ;;
  colorpicker|colorpicker) exec_helper hypr-colorpicker.sh "$@" ;;
  start-batteryd|start_batteryd) exec_helper hypr-start-batteryd.sh "$@" ;;

  ""|-h|--help|help) usage ;;
  *) echo "Unknown command: $cmd" >&2; usage >&2; exit 2 ;;
esac
