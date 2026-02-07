#!/usr/bin/env bash
set -euo pipefail

# Simple scrcpy helper without zenity.
# Wayland/Hyprland/niri friendly defaults (UHID input).

CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/scrcpy"
IP_FILE="$CONFIG_DIR/ip.txt"
LOG_FILE="$CONFIG_DIR/prog.log"
mkdir -p "$CONFIG_DIR"

info() { printf "INFO: %s\n" "$*"; }
warn() { printf "WARN: %s\n" "$*" >&2; }
die() {
  printf "ERROR: %s\n" "$*" >&2
  exit 1
}

need() { command -v "$1" >/dev/null 2>&1 || die "missing dependency: $1"; }

pause() { read -r -p "Press Enter to continue..." </dev/tty; }

reset_adb() {
  info "Restarting ADB server..."
  adb kill-server >/dev/null 2>&1 || true
  adb start-server >/dev/null 2>&1 || true
}

# Ensure we have exactly one usable device over USB or WiFi.
ensure_single_ready_device() {
  local out
  out="$(adb devices 2>/dev/null | tail -n +2 | sed '/^\s*$/d' || true)"

  # No devices at all
  [[ -n "$out" ]] || return 1

  # Multiple devices (common when emulator exists)
  if [[ "$(printf "%s\n" "$out" | wc -l | tr -d ' ')" -gt 1 ]]; then
    warn "Multiple ADB devices detected:"
    printf "%s\n" "$out" >&2
    warn "Set ADB_SERIAL to target one device (e.g., export ADB_SERIAL=XXXX) or disconnect others."
    return 2
  fi

  # Single line: "<serial>\t<state>"
  local state
  state="$(printf "%s\n" "$out" | awk '{print $2}')"

  case "$state" in
  device) return 0 ;;
  unauthorized)
    warn "Device is 'unauthorized'. Unlock phone and accept 'Allow USB debugging'."
    return 3
    ;;
  offline)
    warn "Device is 'offline'. Try toggling USB debugging or re-plug USB."
    return 4
    ;;
  *)
    warn "Unexpected device state: $state"
    return 5
    ;;
  esac
}

# Wrapper to target a specific device if user set ADB_SERIAL.
adb_cmd() {
  if [[ -n "${ADB_SERIAL:-}" ]]; then
    adb -s "$ADB_SERIAL" "$@"
  else
    adb "$@"
  fi
}

usb_connect() {
  info "Connect your phone via USB (USB debugging enabled)."
  pause

  adb_cmd wait-for-device

  if ! ensure_single_ready_device; then
    die "No usable device detected over USB (or multiple/unauthorized/offline)."
  fi

  info "USB connection OK."
}

# Detect phone IP from Android itself (not PC interfaces).
detect_phone_ip() {
  local ipadd=""

  # Most Android devices use wlan0; some may use wlan1.
  for iface in wlan0 wlan1 wifi0; do
    ipadd="$(adb_cmd shell ip -f inet addr show "$iface" 2>/dev/null |
      awk '/inet /{print $2}' | cut -d/ -f1 | head -n1 || true)"
    [[ -n "$ipadd" ]] && break
  done

  # Fallback: parse default route src
  if [[ -z "$ipadd" ]]; then
    ipadd="$(adb_cmd shell ip route 2>/dev/null |
      awk '/src /{for(i=1;i<=NF;i++) if($i=="src") {print $(i+1); exit}}' || true)"
  fi

  printf "%s" "$ipadd"
}

setup_wifi_tcpip_5555() {
  info "Setting up WiFi ADB (TCPIP 5555). Phone + PC must be on same network."
  pause

  # Switch adbd to TCP mode on the device
  adb_cmd tcpip 5555 >/dev/null 2>&1 || true
  sleep 1

  local ipadd
  ipadd="$(detect_phone_ip)"
  [[ -n "$ipadd" ]] || die "Could not detect phone IP."

  local ipfull="${ipadd}:5555"
  echo "$ipfull" >"$IP_FILE"

  # adb connect may return "connected" OR "already connected"
  local resp
  resp="$(adb_cmd connect "$ipfull" 2>/dev/null || true)"
  if printf "%s" "$resp" | grep -Eq "connected to|already connected to"; then
    info "WiFi connected: $ipfull (you can unplug USB)."
    return 0
  fi

  warn "WiFi connect failed: $resp"
  return 1
}

launch_scrcpy() {
  local -a scrcpy_cmd=()
  local screen_size width height max_size

  screen_size="$(adb_cmd shell wm size 2>/dev/null | awk -F: '{print $2}' | tr -d ' ' || true)"
  width="${screen_size%x*}"
  height="${screen_size#*x}"

  # Allow override via env (e.g., SCRCPY_MAX_SIZE=1200)
  if [[ -n "${SCRCPY_MAX_SIZE:-}" ]]; then
    max_size="$SCRCPY_MAX_SIZE"
  else
    if [[ -n "${width:-}" && -n "${height:-}" ]]; then
      if [[ "$width" -ge "$height" ]]; then
        max_size="$height"
      else
        max_size="$width"
      fi
    fi
    if [[ -n "${max_size:-}" && "$max_size" -gt 1200 ]]; then
      max_size=1200
    fi
  fi

  # Reasonable defaults for WiFi
  if [[ -n "${width:-}" && "$width" -gt 1080 ]]; then
    scrcpy_cmd+=(--max-fps 60 --video-bit-rate 16M)
  else
    scrcpy_cmd+=(--max-fps 60 --video-bit-rate 8M)
  fi
  [[ -n "${max_size:-}" ]] && scrcpy_cmd+=(--max-size "$max_size")

  # Wayland-safe input: UHID
  scrcpy_cmd+=(
    --window-title "Android Screen Mirror"
    --mouse=uhid
    --keyboard=uhid
    --disable-screensaver
  )

  info "Starting scrcpy..."
  SCRCPY_OPTS= SCRCPY_ARGS= scrcpy "${scrcpy_cmd[@]}" >"$LOG_FILE" 2>&1 &
  local scrcpy_pid=$!
  sleep 0.8
  if ! kill -0 "$scrcpy_pid" 2>/dev/null; then
    warn "scrcpy exited immediately. Last log lines:"
    tail -n 40 "$LOG_FILE" >&2 || true
    return 1
  fi
}

try_saved_connection() {
  [[ -f "$IP_FILE" ]] || return 1
  local stored
  stored="$(head -n 1 "$IP_FILE" | tr -d '[:space:]')"
  [[ -n "$stored" ]] || return 1
  info "Trying saved IP: $stored"

  local resp
  resp="$(adb_cmd connect "$stored" 2>/dev/null || true)"
  printf "%s" "$resp" | grep -Eq "connected to|already connected to"
}

already_wifi_connected() {
  # Detect "serial:port device" entries in adb devices
  adb devices 2>/dev/null | awk 'NR>1 && $1 ~ /:[0-9]+$/ && $2=="device"{found=1} END{exit !found}'
}

main() {
  need scrcpy
  need adb

  reset_adb

  if already_wifi_connected; then
    info "Already connected over WiFi."
    launch_scrcpy
    exit 0
  fi

  if try_saved_connection; then
    info "Connected to saved device."
    launch_scrcpy
    exit 0
  fi

  usb_connect
  setup_wifi_tcpip_5555 || die "Failed to connect via WiFi."
  launch_scrcpy
}

main "$@"
