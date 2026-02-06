#!/usr/bin/env bash
set -euo pipefail

SCRIPT_NAME="$(basename "$0")"
LOG_FILE="${XDG_CACHE_HOME:-$HOME/.cache}/osc-mullvad-toggle.log"
LOCK_FILE="${XDG_RUNTIME_DIR:-/tmp}/osc-mullvad-toggle.lock"

mkdir -p "$(dirname "$LOG_FILE")"

log() {
  printf "%s %s\n" "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >>"$LOG_FILE"
}

die() {
  log "error: $*"
  printf "%s: %s\n" "$SCRIPT_NAME" "$*" >&2
  exit 1
}

usage() {
  cat <<EOF
Usage:
  $SCRIPT_NAME [--no-blocky] [--dry-run] [--no-notify]

Options:
  --no-blocky     Do not toggle Blocky together with Mullvad
  --dry-run       Pass through to osc-mullvad (no state-changing action)
  --no-notify     Suppress desktop notifications
EOF
}

trim_log() {
  if [[ -f "$LOG_FILE" ]] && [[ "$(wc -l <"$LOG_FILE")" -gt 200 ]]; then
    tail -n 200 "$LOG_FILE" >"${LOG_FILE}.tmp" && mv "${LOG_FILE}.tmp" "$LOG_FILE"
  fi
}

resolve_osc_mullvad() {
  if [[ -n "${OSC_MULLVAD_BIN:-}" ]] && [[ -x "${OSC_MULLVAD_BIN}" ]]; then
    return 0
  fi

  OSC_MULLVAD_BIN="$(command -v osc-mullvad 2>/dev/null || true)"
  if [[ -z "${OSC_MULLVAD_BIN}" ]]; then
    OSC_MULLVAD_BIN="$HOME/.local/bin/osc-mullvad"
  fi
  [[ -x "${OSC_MULLVAD_BIN}" ]] || die "osc-mullvad not found: ${OSC_MULLVAD_BIN}"
}

notify_user() {
  [[ "${notify_enabled}" == "1" ]] || return 0
  command -v notify-send >/dev/null 2>&1 || return 0

  local vpn_connected="0"
  local blocky_active="0"
  local title=""
  local body=""
  local icon=""

  if command -v mullvad >/dev/null 2>&1; then
    if mullvad status 2>/dev/null | grep -q "Connected"; then
      vpn_connected="1"
    fi
  fi

  if systemctl is-active --quiet blocky.service 2>/dev/null; then
    blocky_active="1"
  fi

  if [[ "$vpn_connected" == "1" ]]; then
    title="Mullvad"
    body="VPN connected"
    icon="network-vpn"
  elif [[ "$blocky_active" == "1" ]]; then
    title="Blocky"
    body="DNS filtering active"
    icon="security-high"
  else
    title="Network"
    body="Mullvad disconnected, Blocky off"
    icon="network-vpn-disconnected"
  fi

  notify-send -t 3500 -i "$icon" "$title" "$body" || true
}

run_toggle() {
  local cmd=("${OSC_MULLVAD_BIN}" toggle)
  [[ "${with_blocky}" == "1" ]] && cmd+=(--with-blocky)
  [[ "${dry_run}" == "1" ]] && cmd+=(--dry-run)

  log "run: ${cmd[*]}"
  "${cmd[@]}"
}

run_via_pkexec() {
  command -v pkexec >/dev/null 2>&1 || die "pkexec not found"

  local pkexec_cmd=(
    pkexec env
    "DISPLAY=${DISPLAY-}"
    "WAYLAND_DISPLAY=${WAYLAND_DISPLAY-}"
    "XDG_RUNTIME_DIR=${XDG_RUNTIME_DIR-}"
    "DBUS_SESSION_BUS_ADDRESS=${DBUS_SESSION_BUS_ADDRESS-}"
    "PATH=/run/current-system/sw/bin:${PATH-}"
    "OSC_MULLVAD_BIN=${OSC_MULLVAD_BIN}"
    "OSC_MULLVAD_DIR=${OSC_MULLVAD_DIR:-$HOME/.mullvad}"
    "$0" --as-root
  )
  [[ "${with_blocky}" == "0" ]] && pkexec_cmd+=(--no-blocky)
  [[ "${dry_run}" == "1" ]] && pkexec_cmd+=(--dry-run)
  [[ "${notify_enabled}" == "0" ]] && pkexec_cmd+=(--no-notify)

  log "pkexec: exec root helper"
  "${pkexec_cmd[@]}"
}

with_blocky="1"
dry_run="0"
notify_enabled="1"
run_as_root="0"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --no-blocky) with_blocky="0" ;;
    --dry-run) dry_run="1" ;;
    --no-notify) notify_enabled="0" ;;
    --as-root) run_as_root="1" ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      usage >&2
      die "unknown option: $1"
      ;;
  esac
  shift
done

trim_log
log "triggered: uid=$(id -u) tty=$(tty 2>/dev/null || echo none)"
log "env: DISPLAY=${DISPLAY-} WAYLAND_DISPLAY=${WAYLAND_DISPLAY-} XDG_RUNTIME_DIR=${XDG_RUNTIME_DIR-}"

resolve_osc_mullvad

# Prevent accidental double-trigger from keybindings.
# Skip locking in the root helper path to avoid self-deadlock when pkexec
# re-enters this script with --as-root while the parent process still holds
# the lock.
if [[ "${run_as_root}" != "1" ]] && command -v flock >/dev/null 2>&1; then
  exec 9>"$LOCK_FILE"
  flock -n 9 || die "another toggle is already running"
fi

if [[ "${run_as_root}" == "1" ]] && [[ "$(id -u)" -ne 0 ]]; then
  die "--as-root can only be used by root"
fi

if [[ "$(id -u)" -eq 0 ]]; then
  run_toggle
  # Parent process sends user-facing notification after pkexec returns.
  [[ "${run_as_root}" != "1" ]] && notify_user
  exit 0
fi

run_via_pkexec
rc=$?
log "pkexec exit=${rc}"
if [[ "$rc" -eq 0 ]]; then
  notify_user
fi
exit "$rc"
