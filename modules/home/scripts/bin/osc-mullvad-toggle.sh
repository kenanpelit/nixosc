#!/usr/bin/env bash
set -euo pipefail

SCRIPT_NAME="$(basename "$0")"
SELF_PATH="$(command -v "$0" 2>/dev/null || true)"
if [[ -z "${SELF_PATH}" ]]; then
  SELF_PATH="$0"
fi
LOG_FILE="${XDG_CACHE_HOME:-$HOME/.cache}/osc-mullvad-toggle.log"
LOCK_FILE="${XDG_RUNTIME_DIR:-/tmp}/osc-mullvad-toggle.$(id -u).lock"

mkdir -p "$(dirname "$LOG_FILE")"
if ! touch "$LOG_FILE" 2>/dev/null; then
  LOG_FILE="${XDG_RUNTIME_DIR:-/tmp}/osc-mullvad-toggle.$(id -u).log"
  mkdir -p "$(dirname "$LOG_FILE")"
  touch "$LOG_FILE" 2>/dev/null || true
fi

log() {
  { printf "%s %s\n" "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >>"$LOG_FILE"; } 2>/dev/null || true
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
  --dry-run       Preview actions only (no state-changing action)
  --no-notify     Suppress desktop notifications
EOF
}

trim_log() {
  if [[ -f "$LOG_FILE" ]] && [[ -w "$LOG_FILE" ]] && [[ "$(wc -l <"$LOG_FILE" 2>/dev/null || echo 0)" -gt 200 ]]; then
    local tmp_log
    tmp_log="$(mktemp "${XDG_RUNTIME_DIR:-/tmp}/osc-mullvad-toggle.log.XXXXXX" 2>/dev/null || true)"
    if [[ -n "${tmp_log:-}" ]]; then
      tail -n 200 "$LOG_FILE" >"$tmp_log" 2>/dev/null || true
      cat "$tmp_log" >"$LOG_FILE" 2>/dev/null || true
      rm -f "$tmp_log" 2>/dev/null || true
    fi
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
    icon="dialog-error"
  else
    title="Network"
    body="Mullvad disconnected, Blocky off"
    icon="network-vpn-disconnected"
  fi

  notify-send -t 3500 -i "$icon" "$title" "$body" || true
}

run_toggle() {
  if [[ "${dry_run}" == "1" ]]; then
    preview_toggle
    return 0
  fi

  local cmd=("${OSC_MULLVAD_BIN}" toggle)
  [[ "${with_blocky}" == "1" ]] && cmd+=(--with-blocky)

  log "run: ${cmd[*]}"
  "${cmd[@]}"
}

preview_toggle() {
  local vpn_connected="0"
  local blocky_active="0"

  if command -v mullvad >/dev/null 2>&1 && mullvad status 2>/dev/null | grep -q "Connected"; then
    vpn_connected="1"
  fi
  if systemctl is-active --quiet blocky.service 2>/dev/null; then
    blocky_active="1"
  fi

  echo "[dry-run] current: mullvad=$([[ "$vpn_connected" == "1" ]] && echo connected || echo disconnected), blocky=$([[ "$blocky_active" == "1" ]] && echo on || echo off)"
  if [[ "${with_blocky}" == "1" ]]; then
    if [[ "$vpn_connected" == "1" ]]; then
      echo "[dry-run] next: disconnect Mullvad, start Blocky"
    else
      echo "[dry-run] next: stop Blocky, connect Mullvad"
    fi
  else
    if [[ "$vpn_connected" == "1" ]]; then
      echo "[dry-run] next: disconnect Mullvad"
    else
      echo "[dry-run] next: connect Mullvad"
    fi
  fi
  log "dry-run preview emitted"
}

run_via_pkexec() {
  command -v pkexec >/dev/null 2>&1 || die "pkexec not found"

  local pkexec_cmd=(
    pkexec "$SELF_PATH" --as-root
    --osc-mullvad-bin "$OSC_MULLVAD_BIN"
    --osc-mullvad-dir "${OSC_MULLVAD_DIR:-$HOME/.mullvad}"
  )
  [[ "${with_blocky}" == "0" ]] && pkexec_cmd+=(--no-blocky)
  [[ "${notify_enabled}" == "0" ]] && pkexec_cmd+=(--no-notify)

  log "pkexec: exec root helper"
  "${pkexec_cmd[@]}"
}

with_blocky="1"
dry_run="0"
notify_enabled="1"
run_as_root="0"
osc_mullvad_bin_arg=""
osc_mullvad_dir_arg=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --no-blocky) with_blocky="0" ;;
    --dry-run) dry_run="1" ;;
    --no-notify) notify_enabled="0" ;;
    --as-root) run_as_root="1" ;;
    --osc-mullvad-bin)
      shift
      [[ $# -gt 0 ]] || die "missing value for --osc-mullvad-bin"
      osc_mullvad_bin_arg="$1"
      ;;
    --osc-mullvad-dir)
      shift
      [[ $# -gt 0 ]] || die "missing value for --osc-mullvad-dir"
      osc_mullvad_dir_arg="$1"
      ;;
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

if [[ -n "${osc_mullvad_bin_arg}" ]]; then
  OSC_MULLVAD_BIN="${osc_mullvad_bin_arg}"
fi
if [[ -n "${osc_mullvad_dir_arg}" ]]; then
  export OSC_MULLVAD_DIR="${osc_mullvad_dir_arg}"
fi

resolve_osc_mullvad

# Prevent accidental double-trigger from keybindings.
# Skip locking in the root helper path to avoid self-deadlock when pkexec
# re-enters this script with --as-root while the parent process still holds
# the lock.
if [[ "${run_as_root}" != "1" ]] && command -v flock >/dev/null 2>&1; then
  if ! { exec 9>"$LOCK_FILE"; } 2>/dev/null; then
    log "warn: lock file unavailable, continuing without lock: $LOCK_FILE"
  else
    flock -n 9 || die "another toggle is already running"
  fi
fi

if [[ "${run_as_root}" == "1" ]] && [[ "$(id -u)" -ne 0 ]]; then
  die "--as-root can only be used by root"
fi

if [[ "${dry_run}" == "1" ]]; then
  run_toggle
  exit 0
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
