#!/usr/bin/env bash
set -euo pipefail

LOG_FILE="${XDG_CACHE_HOME:-$HOME/.cache}/osc-mullvad-toggle.log"
mkdir -p "$(dirname "$LOG_FILE")"

die() {
  log "error: $*"
  printf "osc-mullvad-toggle: %s\n" "$*" >&2
  exit 1
}

log() {
  printf "%s %s\n" "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >>"$LOG_FILE"
}

# Best-effort user notification
notify_user() {
  command -v notify-send >/dev/null 2>&1 || return 0

  local vpn_state="Unknown"
  local vpn_icon="network-vpn"
  local blocky_state="unknown"
  local blocky_icon="security-medium"

  if command -v mullvad >/dev/null 2>&1; then
    if mullvad status 2>/dev/null | grep -q "Connected"; then
      vpn_state="Connected"
      vpn_icon="network-vpn"
    else
      vpn_state="Disconnected"
      vpn_icon="network-vpn-disconnected"
    fi
  fi

  if systemctl is-active --quiet blocky.service 2>/dev/null; then
    blocky_state="on"
    blocky_icon="security-high"
  else
    blocky_state="off"
    blocky_icon="security-low"
  fi

  notify-send -t 4000 -i "$vpn_icon" "Mullvad: ${vpn_state}" "Blocky: ${blocky_state}"
  notify-send -t 4000 -i "$blocky_icon" "Blocky: ${blocky_state}" "Mullvad: ${vpn_state}"
}

# Keep log size sane (last 200 lines).
if [ -f "$LOG_FILE" ] && [ "$(wc -l <"$LOG_FILE")" -gt 200 ]; then
  tail -n 200 "$LOG_FILE" >"${LOG_FILE}.tmp" && mv "${LOG_FILE}.tmp" "$LOG_FILE"
fi

log "triggered: uid=$(id -u) tty=$(tty 2>/dev/null || echo none)"
log "env: DISPLAY=${DISPLAY-} WAYLAND_DISPLAY=${WAYLAND_DISPLAY-} XDG_RUNTIME_DIR=${XDG_RUNTIME_DIR-}"

OSC_MULLVAD_BIN="${OSC_MULLVAD_BIN:-}"
if [[ -z "${OSC_MULLVAD_BIN}" ]]; then
  OSC_MULLVAD_BIN="$(command -v osc-mullvad 2>/dev/null || true)"
fi
if [[ -z "${OSC_MULLVAD_BIN}" ]]; then
  OSC_MULLVAD_BIN="$HOME/.local/bin/osc-mullvad"
fi
[[ -x "${OSC_MULLVAD_BIN}" ]] || die "osc-mullvad not found: ${OSC_MULLVAD_BIN}"

ENV_BIN="$(command -v env 2>/dev/null || true)"
[[ -n "${ENV_BIN}" ]] || die "'env' not found in PATH"

BASH_BIN="$(command -v bash 2>/dev/null || true)"
[[ -n "${BASH_BIN}" ]] || die "'bash' not found in PATH"

CMD=("${OSC_MULLVAD_BIN}" toggle --with-blocky)

if [ "$(id -u)" -eq 0 ]; then
  log "running as root"
  "${CMD[@]}"
  exit 0
fi

# Use pkexec with environment so polkit has session context.
# On NixOS, avoid hard-coded /usr/bin/* and /bin/* paths.
if command -v pkexec >/dev/null 2>&1; then
  log "pkexec running"
  ROOT_LOG="/tmp/osc-mullvad-toggle.root.log"
  pkexec "${ENV_BIN}" \
    DISPLAY="${DISPLAY-}" \
    WAYLAND_DISPLAY="${WAYLAND_DISPLAY-}" \
    XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR-}" \
    DBUS_SESSION_BUS_ADDRESS="${DBUS_SESSION_BUS_ADDRESS-}" \
    PATH="/run/current-system/sw/bin:${PATH-}" \
    OSC_MULLVAD_NO_NOTIFY="1" \
    OSC_MULLVAD_DIR="$HOME/.mullvad" \
    "${BASH_BIN}" -lc \
    "\"${OSC_MULLVAD_BIN}\" toggle --with-blocky >>\"${ROOT_LOG}\" 2>&1"
  rc=$?
  log "pkexec exit=${rc}"
  if [ "$rc" -eq 0 ]; then
    notify_user || true
  fi
  exit "${rc}"
fi

log "pkexec not found"
exit 1
