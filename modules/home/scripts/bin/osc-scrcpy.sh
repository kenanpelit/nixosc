#!/usr/bin/env bash
set -euo pipefail

# Simple scrcpy helper without zenity.

CONFIG_DIR="$HOME/.config/scrcpy"
IP_FILE="$CONFIG_DIR/ip.txt"
LOG_FILE="$CONFIG_DIR/prog.log"
mkdir -p "$CONFIG_DIR"

info() { printf "INFO: %s\n" "$*"; }
warn() { printf "WARN: %s\n" "$*" >&2; }
die() { printf "ERROR: %s\n" "$*" >&2; exit 1; }

need() { command -v "$1" >/dev/null 2>&1 || die "missing dependency: $1"; }

pause() {
  read -r -p "Press Enter to continue..." </dev/tty
}

reset_adb() {
  info "Restarting ADB server..."
  adb kill-server >/dev/null 2>&1 || true
  adb start-server >/dev/null 2>&1 || true
  adb devices >/dev/null 2>&1 || true
}

usb_connect() {
  info "Connect your phone via USB (USB debugging enabled)."
  pause
  adb wait-for-device
  if ! adb devices | grep -q "device$"; then
    die "No device detected over USB."
  fi
  info "USB connection OK."
}

detect_phone_ip() {
  local ipadd=""
  for iface in wlan0 wlp2s0 wlp3s0 wlp4s0 eth0; do
    ipadd=$(adb shell ip -f inet addr show "$iface" 2>/dev/null | grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}' | head -n 1 || true)
    [[ -n "$ipadd" ]] && break
  done
  if [[ -z "$ipadd" ]]; then
    ipadd=$(adb shell ip route 2>/dev/null | grep -o 'src [0-9.]*' | awk '{print $2}' | head -n 1 || true)
  fi
  printf "%s" "$ipadd"
}

setup_wifi() {
  info "Setting up WiFi connection (phone + PC same network)."
  pause
  adb tcpip 5555 >/dev/null 2>&1 || true
  sleep 2

  local ipadd
  ipadd="$(detect_phone_ip)"
  [[ -n "$ipadd" ]] || die "Could not detect phone IP."

  local ipfull="${ipadd}:5555"
  echo "$ipfull" >"$IP_FILE"

  if adb connect "$ipfull" 2>/dev/null | grep -q "connected"; then
    info "WiFi connected: $ipfull (you can unplug USB)."
    return 0
  fi
  warn "WiFi connect failed."
  return 1
}

launch_scrcpy() {
  local options=""
  local screen_size width height

  screen_size="$(adb shell wm size 2>/dev/null | awk -F: '{print $2}' | tr -d ' ' || true)"
  width="${screen_size%x*}"
  height="${screen_size#*x}"

  if [[ -n "${width:-}" && "$width" -gt 1080 ]]; then
    options="--max-size 1080 --max-fps 60 --video-bit-rate 16M"
  else
    options="--max-fps 60 --video-bit-rate 8M"
  fi

  options="$options --window-title \"Android Screen Mirror\""
  info "Starting scrcpy..."
  eval "scrcpy $options > \"$LOG_FILE\" 2>&1 &"
}

try_saved_connection() {
  [[ -f "$IP_FILE" ]] || return 1
  local stored
  stored="$(head -n 1 "$IP_FILE" | tr -d '[:space:]')"
  [[ -n "$stored" ]] || return 1
  info "Trying saved IP: $stored"
  adb connect "$stored" 2>/dev/null | grep -q "connected"
}

main() {
  need scrcpy
  need adb

  reset_adb

  if adb devices | grep -qE "[0-9]{1,3}(\\.[0-9]{1,3}){3}"; then
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
  if setup_wifi; then
    launch_scrcpy
    exit 0
  fi

  die "Failed to connect via WiFi."
}

main "$@"
