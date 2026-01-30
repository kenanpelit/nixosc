#!/usr/bin/env bash
#######################################
#
# Version: 2.0.1
# Date: 2026-01-22
# Original Author: Kenan Pelit
# Script: Bluetooth Toggle + Dual-Boot Rekey Fix (BlueZ + PipeWire/PulseAudio)
#
# License: MIT
#
#######################################

set -euo pipefail

# ==============================================================================
# User settings
# ==============================================================================

DEFAULT_DEVICE_ADDRESS="F4:9D:8A:3D:CB:30"
DEFAULT_DEVICE_NAME="SL4P"

ALTERNATIVE_DEVICE_ADDRESS="E8:EE:CC:4D:29:00"
ALTERNATIVE_DEVICE_NAME="SL4"

# Alias (local display name) after rekey/repair
DEFAULT_DEVICE_ALIAS="SLP4"

# Audio levels (percent)
BT_VOLUME_LEVEL=40
BT_MIC_LEVEL=5
DEFAULT_VOLUME_LEVEL=15
DEFAULT_MIC_LEVEL=0

# Timing / retry
BLUETOOTH_TIMEOUT=12       # seconds for bluetoothctl single commands
AUDIO_WAIT_TIME=4          # seconds before audio routing attempts
MAX_RETRY_COUNT=10         # audio routing retries
SCAN_WAIT_SECONDS=45       # wait for device visibility during scan (dual-boot needs longer)
CONNECT_WAIT_SECONDS=12    # wait to see Connected: yes after connect
WPCTL_NODE_WAIT_SECONDS=20 # wait for bluez nodes in wpctl Settings

# ==============================================================================
# Colors & logging
# ==============================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() {
  local msg="$1" level="${2:-INFO}" color=""
  case "$level" in
  ERROR) color=$RED ;;
  SUCCESS) color=$GREEN ;;
  WARNING) color=$YELLOW ;;
  INFO) color=$BLUE ;;
  esac
  echo -e "${color}[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $msg${NC}"
}

send_notification() {
  command -v notify-send >/dev/null 2>&1 && notify-send -t 5000 "$1" "$2"
}

# ==============================================================================
# Globals (runtime)
# ==============================================================================

MODE="toggle" # toggle | connect | disconnect
MODE_BATTERY_ONLY=false
MODE_REKEY=false
AUTO_REKEY=false

AUDIO_BACKEND=""
BACKEND_FORCED=""

DEVICE_ADDRESS=""
DEVICE_NAME=""
DEVICE_ALIAS=""
ADAPTER_ADDRESS=""

# ==============================================================================
# Command helpers
# ==============================================================================

check_command() {
  command -v "$1" >/dev/null 2>&1 || {
    log "Missing command: $1" "ERROR"
    exit 1
  }
}

_sudo() {
  if [ "$(id -u)" -eq 0 ]; then
    "$@"
  else
    sudo "$@"
  fi
}

# Run bluetoothctl with a hard timeout and capture output (do not trust exit code)
_btctl_capture() {
  if [ $# -gt 0 ]; then
    timeout "$BLUETOOTH_TIMEOUT" bluetoothctl "$@" 2>&1 || true
  else
    timeout "$BLUETOOTH_TIMEOUT" bluetoothctl 2>&1 || true
  fi
}

# Feed a command batch into bluetoothctl and capture output
_btctl_batch() {
  local input="$1"
  printf '%s\n' "$input" | timeout "$BLUETOOTH_TIMEOUT" bluetoothctl 2>&1 || true
}

# ==============================================================================
# BlueZ / Bluetooth state helpers
# ==============================================================================

check_bluetooth_service() {
  if ! systemctl is-active --quiet bluetooth; then
    log "Bluetooth service is not active. Starting..." "WARNING"
    _sudo systemctl start bluetooth || true
    sleep 2
  fi
}

check_bluetooth_power() {
  if ! bluetoothctl show 2>/dev/null | grep -q "Powered: yes"; then
    log "Bluetooth is powered off. Powering on..." "WARNING"
    bluetoothctl power on >/dev/null 2>&1 || true
    sleep 2
  fi
  bluetoothctl show 2>/dev/null | grep -q "Powered: yes" || {
    log "Bluetooth could not be powered on." "ERROR"
    return 1
  }
  return 0
}

_detect_adapter_address() {
  # bluetoothctl list: "Controller AA:BB:CC:DD:EE:FF <name> [default]"
  bluetoothctl list 2>/dev/null | awk '/Controller/ {print $2; exit}'
}

_is_paired() {
  local mac="$1"
  bluetoothctl paired-devices 2>/dev/null | grep -qi "$mac"
}

_is_connected() {
  local mac="$1"
  bluetoothctl info "$mac" 2>/dev/null | awk -F': ' '/Connected:/ {print $2}' | grep -qi "yes"
}

_wait_connected_yes() {
  local mac="$1"
  local t=0
  while [ $t -lt "$CONNECT_WAIT_SECONDS" ]; do
    _is_connected "$mac" && return 0
    sleep 1
    t=$((t + 1))
  done
  return 1
}

_wait_until_device_visible() {
  local mac="$1"
  local t=0
  while [ $t -lt "$SCAN_WAIT_SECONDS" ]; do
    bluetoothctl devices 2>/dev/null | grep -qi "$mac" && return 0
    sleep 1
    t=$((t + 1))
  done
  return 1
}

# Battery percentage from bluetoothctl info (may not be supported)
get_battery_percentage() {
  local addr="$1"
  local raw pct
  raw="$(bluetoothctl info "$addr" 2>/dev/null | awk -F': ' '/Battery Percentage/ {gsub(/[[:space:]]*/,"",$2); print $2; exit}')"
  [ -z "$raw" ] && return 0
  if echo "$raw" | grep -q '([0-9]\+)'; then
    pct="$(echo "$raw" | sed -n 's/.*(\([0-9]\+\)).*/\1/p')"
  else
    pct="$(echo "$raw" | tr -cd '0-9')"
  fi
  [ -n "${pct:-}" ] && echo "${pct}%"
}

# ==============================================================================
# Audio backend detection (wpctl/pactl)
# ==============================================================================

detect_backend() {
  if [ -n "$BACKEND_FORCED" ]; then
    case "$BACKEND_FORCED" in
    wpctl | pactl) AUDIO_BACKEND="$BACKEND_FORCED" ;;
    *)
      log "Invalid backend: $BACKEND_FORCED (use wpctl|pactl)" "ERROR"
      exit 1
      ;;
    esac
  else
    if command -v wpctl >/dev/null 2>&1; then
      AUDIO_BACKEND="wpctl"
    elif command -v pactl >/dev/null 2>&1; then
      AUDIO_BACKEND="pactl"
    else
      log "No audio backend found. Install PipeWire (wpctl) or PulseAudio (pactl)." "ERROR"
      exit 1
    fi
  fi
  log "Audio backend: ${AUDIO_BACKEND}" "INFO"
}

# ==============================================================================
# wpctl helpers (robust parsing)
# ==============================================================================

_strip_box_chars() { sed 's/[│├─└]//g'; }
_mac_upper() { echo "$1" | tr '[:lower:]' '[:upper:]'; }
_mac_underscore() { _mac_upper "$1" | tr ':' '_'; }

_extract_id_from_line() {
  local line="$1"
  line="${line#"${line%%[![:space:]]*}"}"
  line="${line#\* }"
  line="${line#\*}"
  echo "$line" | awk -F. '{gsub(/^[[:space:]]*/,"",$1); print $1}'
}

_wpctl_block() {
  local start="$1" end="$2"
  wpctl status | sed -n "/^ *$start:/,/^ *$end:/p" | _strip_box_chars
}

_find_id_in_block_by_name() {
  local block="$1" needle_regex="$2" line
  while IFS= read -r line; do
    echo "$line" | grep -qiE "$needle_regex" || continue
    if [[ "$line" =~ ^[[:space:]]*\*?[[:space:]]*[0-9]+\.[[:space:]] ]]; then
      _extract_id_from_line "$line"
      return 0
    fi
  done <<<"$block"
  return 1
}

_find_id_by_mac_in_section() {
  local section="$1" end="$2" mac_upper="$3" mac_und="$4" block line id
  block="$(_wpctl_block "$section" "$end")"
  while IFS= read -r line; do
    [[ "$line" =~ ^[[:space:]]*\*?[[:space:]]*[0-9]+\.[[:space:]] ]] || continue
    id="$(_extract_id_from_line "$line")"
    wpctl inspect "$id" 2>/dev/null | grep -qE "($mac_upper|$mac_und)" && {
      echo "$id"
      return 0
    }
  done <<<"$block"
  return 1
}

_find_default_serial_from_settings() {
  local kind="$1" macU="$2" macUnd="$3"
  local what
  [ "$kind" = "sink" ] && what="Audio/Sink" || what="Audio/Source"
  wpctl status | sed -n "/^ *Settings:/,\$p" | awk -v w="$what" -v m="$macU" -v mu="$macUnd" '
    BEGIN{IGNORECASE=1}
    /Default Configured Devices:/,0 {
      if ($0 ~ w) {
        line=$0
        if (index(line,m)>0 || index(line,mu)>0) {
          gsub(/^.*Audio\/(Sink|Source)[[:space:]]+/,"",line)
          gsub(/[[:space:]]+$/,"",line)
          print line; exit
        }
      }
    }'
}

_resolve_node_name_from_id() {
  local id="$1"
  wpctl inspect "$id" 2>/dev/null | awk -F'"' '/node.name/ {print $2; exit}'
}

_switch_bt_profile_a2dp() {
  local macU="$(_mac_upper "$DEVICE_ADDRESS")" macUnd="$(_mac_underscore "$DEVICE_ADDRESS")"
  local card_id
  card_id="$(wpctl status | _strip_box_chars | awk -v m="$macU" -v mu="$macUnd" '
    BEGIN{IGNORECASE=1}
    /^[[:space:]]*\*?[[:space:]]*[0-9]+\./ && /bluez_card/ {
      if (index($0,m)>0 || index($0,mu)>0) {
        line=$0; sub(/^[[:space:]]*\*?[[:space:]]*/,"",line); sub(/\..*/,"",line); print line; exit
      }
    }')" || true
  [ -n "$card_id" ] && wpctl set-profile "$card_id" a2dp-sink >/dev/null 2>&1 || true
}

_wait_for_wpctl_bt_nodes() {
  local macU="$(_mac_upper "$DEVICE_ADDRESS")" macUnd="$(_mac_underscore "$DEVICE_ADDRESS")"
  local t=0
  while [ $t -lt "$WPCTL_NODE_WAIT_SECONDS" ]; do
    local s_serial i_serial
    s_serial="$(_find_default_serial_from_settings sink "$macU" "$macUnd")" || true
    i_serial="$(_find_default_serial_from_settings source "$macU" "$macUnd")" || true
    if [ -n "${s_serial:-}" ] || [ -n "${i_serial:-}" ]; then
      return 0
    fi
    sleep 1
    t=$((t + 1))
  done
  return 1
}

_set_default_wpctl() {
  local kind="$1" target="$2"
  local serial=""

  if [[ "$target" =~ ^[0-9]+$ ]]; then
    serial="$(_resolve_node_name_from_id "$target")"
  else
    serial="$target"
  fi

  if [ -z "$serial" ]; then
    local macU="$(_mac_upper "$DEVICE_ADDRESS")" macUnd="$(_mac_underscore "$DEVICE_ADDRESS")"
    serial="$(_find_default_serial_from_settings "$kind" "$macU" "$macUnd")"
  fi

  [ -n "$serial" ] && wpctl set-default "$serial" >/dev/null 2>&1 && return 0
  return 1
}

audio_find_bt_sink() {
  case "$AUDIO_BACKEND" in
  pactl)
    pactl list short sinks | awk '/bluez/i {print $2; exit}'
    ;;
  wpctl)
    local macU="$(_mac_upper "$DEVICE_ADDRESS")" macUnd="$(_mac_underscore "$DEVICE_ADDRESS")" block
    block="$(_wpctl_block "Sinks" "Sources")"
    _find_id_in_block_by_name "$block" "bluez|Bluetooth|A2DP|Headset|Headphones|Earbuds|${DEFAULT_DEVICE_NAME}|${ALTERNATIVE_DEVICE_NAME}|S4|SLP4" && return 0
    _find_id_by_mac_in_section "Sinks" "Sources" "$macU" "$macUnd" && return 0
    _find_default_serial_from_settings sink "$macU" "$macUnd" && return 0
    return 1
    ;;
  esac
}

audio_find_bt_source() {
  case "$AUDIO_BACKEND" in
  pactl)
    pactl list short sources | awk '/bluez.*input/i {print $2; exit}'
    ;;
  wpctl)
    local macU="$(_mac_upper "$DEVICE_ADDRESS")" macUnd="$(_mac_underscore "$DEVICE_ADDRESS")" block
    block="$(_wpctl_block "Sources" "Clients")"
    _find_id_in_block_by_name "$block" "bluez|Bluetooth|HSP|HFP|Headset|Mic|${DEFAULT_DEVICE_NAME}|${ALTERNATIVE_DEVICE_NAME}|S4|SLP4" && return 0
    _find_id_by_mac_in_section "Sources" "Clients" "$macU" "$macUnd" && return 0
    _find_default_serial_from_settings source "$macU" "$macUnd" && return 0
    return 1
    ;;
  esac
}

audio_set_default_sink() {
  local target="$1"
  case "$AUDIO_BACKEND" in
  pactl) pactl set-default-sink "$target" ;;
  wpctl) _set_default_wpctl sink "$target" ;;
  esac
}

audio_set_default_source() {
  local target="$1"
  case "$AUDIO_BACKEND" in
  pactl) pactl set-default-source "$target" ;;
  wpctl) _set_default_wpctl source "$target" ;;
  esac
}

audio_set_sink_volume_pct() {
  local pct="$1"
  case "$AUDIO_BACKEND" in
  pactl) pactl set-sink-volume @DEFAULT_SINK@ "${pct}%" ;;
  wpctl) wpctl set-volume @DEFAULT_AUDIO_SINK@ "${pct}%" ;;
  esac
}

audio_set_source_volume_pct() {
  local pct="$1"
  case "$AUDIO_BACKEND" in
  pactl) pactl set-source-volume @DEFAULT_SOURCE@ "${pct}%" ;;
  wpctl) wpctl set-volume @DEFAULT_AUDIO_SOURCE@ "${pct}%" ;;
  esac
}

# ==============================================================================
# Audio configuration
# ==============================================================================

configure_audio_default() {
  if audio_set_sink_volume_pct "$DEFAULT_VOLUME_LEVEL" 2>/dev/null && audio_set_source_volume_pct "$DEFAULT_MIC_LEVEL" 2>/dev/null; then
    log "Default audio levels set: sink %${DEFAULT_VOLUME_LEVEL}, mic %${DEFAULT_MIC_LEVEL}" "SUCCESS"
  else
    log "Failed to set default audio levels (non-fatal)." "WARNING"
  fi
}

configure_audio_bluetooth() {
  if ! _is_connected "$DEVICE_ADDRESS"; then
    log "Skipping audio routing: device is not connected." "WARNING"
    return 1
  fi

  log "Waiting for Bluetooth audio nodes..." "INFO"
  sleep "$AUDIO_WAIT_TIME"

  if [ "$AUDIO_BACKEND" = "wpctl" ]; then
    _switch_bt_profile_a2dp
    _wait_for_wpctl_bt_nodes || log "wpctl BT nodes are late; continuing anyway." "WARNING"
  fi

  # Sink routing
  local i=0
  while [ $i -lt "$MAX_RETRY_COUNT" ]; do
    local bt_sink=""
    bt_sink="$(audio_find_bt_sink)" || true
    if [ -n "$bt_sink" ] && audio_set_default_sink "$bt_sink"; then
      audio_set_sink_volume_pct "$BT_VOLUME_LEVEL" 2>/dev/null || true
      log "Default sink set to BT: $bt_sink (%${BT_VOLUME_LEVEL})" "SUCCESS"
      break
    fi
    i=$((i + 1))
    log "BT sink not found yet... ($i/$MAX_RETRY_COUNT)" "WARNING"
    sleep 1
  done

  # Source routing
  i=0
  while [ $i -lt "$MAX_RETRY_COUNT" ]; do
    local bt_src=""
    bt_src="$(audio_find_bt_source)" || true
    if [ -n "$bt_src" ] && audio_set_default_source "$bt_src"; then
      audio_set_source_volume_pct "$BT_MIC_LEVEL" 2>/dev/null || true
      log "Default mic set to BT: $bt_src (%${BT_MIC_LEVEL})" "SUCCESS"
      return 0
    fi
    i=$((i + 1))
    log "BT source not found yet... ($i/$MAX_RETRY_COUNT)" "WARNING"
    sleep 1
  done

  log "BT microphone could not be set (speaker may still work)." "WARNING"
  return 0
}

# ==============================================================================
# Strict re-pair / dual-boot fix (PATCHED: settle + keep scan)
# ==============================================================================

_bt_prepare_agent() {
  _btctl_batch $'power on\nagent on\ndefault-agent' >/dev/null 2>&1 || true
}

_set_alias_best_effort() {
  local mac="$1"
  local alias="${2:-}"
  [ -z "$alias" ] && return 0

  # Best effort: try "select <mac>" then "set-alias <name>", plus fallback
  _btctl_batch "select $mac" >/dev/null 2>&1 || true
  _btctl_batch "set-alias $alias" >/dev/null 2>&1 || true
  _btctl_batch "set-alias $alias" >/dev/null 2>&1 || true
  return 0
}

_pair_trust_connect_strict() {
  local mac="$1"
  local out=""

  _bt_prepare_agent

  # Start scanning and wait until device appears
  bluetoothctl scan on >/dev/null 2>&1 || true
  if ! _wait_until_device_visible "$mac"; then
    bluetoothctl scan off >/dev/null 2>&1 || true
    log "Device not visible during scan. Put the headset into pairing mode, then retry --rekey." "ERROR"
    return 1
  fi

  # Pair (keep scanning ON to mimic blueman "search" behavior)
  out="$(_btctl_capture pair "$mac")"

  # Hard error patterns
  if echo "$out" | grep -qiE "AuthenticationFailed|org\.bluez\.Error|Failed|not available|No such device"; then
    log "Pair command failed. bluetoothctl output:" "ERROR"
    printf '%s\n' "$out" >&2
    bluetoothctl scan off >/dev/null 2>&1 || true
    return 1
  fi

  # If pair output does not explicitly say success, still continue and verify via paired-devices
  if ! echo "$out" | grep -qiE "Pairing successful|\[CHG\].*Paired: yes|\[CHG\].*Bonded: yes"; then
    log "Pair did not explicitly report success (may still succeed late). Output follows:" "WARNING"
    printf '%s\n' "$out" >&2
  fi

  # Trust (best effort)
  bluetoothctl trust "$mac" >/dev/null 2>&1 || true

  # Wait for paired-devices to settle (bluetoothctl lists can lag behind events)
  local t=0
  while [ $t -lt 10 ]; do
    if bluetoothctl paired-devices 2>/dev/null | grep -qi "$mac"; then
      break
    fi
    sleep 1
    t=$((t + 1))
  done

  if ! bluetoothctl paired-devices 2>/dev/null | grep -qi "$mac"; then
    # Accept if we saw explicit success in the captured output
    if echo "$out" | grep -qiE "Pairing successful|\[CHG\].*Paired: yes|\[CHG\].*Bonded: yes"; then
      log "paired-devices lag detected; proceeding because pairing success was reported." "WARNING"
    else
      log "Device is still not listed in paired-devices after pairing attempt." "ERROR"
      printf '%s\n' "$out" >&2
      bluetoothctl scan off >/dev/null 2>&1 || true
      return 1
    fi
  fi

  # Connect (keep scan on until it resolves)
  out="$(_btctl_capture connect "$mac")"
  if echo "$out" | grep -qiE "org\.bluez\.Error|Failed|not available|No such device"; then
    log "Connect command returned an error. bluetoothctl output:" "ERROR"
    printf '%s\n' "$out" >&2
    bluetoothctl scan off >/dev/null 2>&1 || true
    return 1
  fi

  if ! _wait_connected_yes "$mac"; then
    # Extra settle time while scanning, like blueman
    local t2=0
    while [ $t2 -lt 8 ]; do
      _is_connected "$mac" && break
      sleep 1
      t2=$((t2 + 1))
    done
    if ! _is_connected "$mac"; then
      log "Connect did not reach 'Connected: yes'." "ERROR"
      printf '%s\n' "$out" >&2
      bluetoothctl scan off >/dev/null 2>&1 || true
      return 1
    fi
  fi

  bluetoothctl scan off >/dev/null 2>&1 || true
  return 0
}

_rekey_and_repair() {
  local adapter="${ADAPTER_ADDRESS:-$(_detect_adapter_address)}"
  if [ -z "$adapter" ]; then
    log "Adapter address could not be detected. Use --adapter=<MAC>." "ERROR"
    return 1
  fi

  log "Rekey starting (adapter: $adapter) — removing /var/lib/bluetooth/$adapter" "WARNING"
  _sudo systemctl stop bluetooth || true
  _sudo rm -rf "/var/lib/bluetooth/$adapter"
  _sudo systemctl start bluetooth
  sleep 2

  check_bluetooth_power || return 1
  _bt_prepare_agent

  log "Re-pairing device: $DEVICE_NAME ($DEVICE_ADDRESS)" "INFO"

  # Remove stale pairing record (ignore failures)
  bluetoothctl remove "$DEVICE_ADDRESS" >/dev/null 2>&1 || true

  if ! _pair_trust_connect_strict "$DEVICE_ADDRESS"; then
    log "Rekey re-pair failed. Most likely the headset is NOT in pairing mode (or not advertising)." "ERROR"
    return 1
  fi

  local alias_name="${DEVICE_ALIAS:-$DEFAULT_DEVICE_ALIAS}"
  _set_alias_best_effort "$DEVICE_ADDRESS" "$alias_name"
  [ -n "$alias_name" ] && log "Alias set (best effort): $alias_name" "SUCCESS"

  local battery=""
  battery="$(get_battery_percentage "$DEVICE_ADDRESS")" || true
  if [ -n "$battery" ]; then
    send_notification "Bluetooth Rekey OK" "$DEVICE_NAME connected. Battery: $battery"
  else
    send_notification "Bluetooth Rekey OK" "$DEVICE_NAME connected."
  fi

  configure_audio_bluetooth || true
  return 0
}

# ==============================================================================
# Normal connect/disconnect/toggle
# ==============================================================================

_connect_device_fast() {
  # Try a direct connect first
  local mac="$1"
  local out=""
  _bt_prepare_agent
  out="$(_btctl_capture connect "$mac")"

  if echo "$out" | grep -qiE "Device .* not available|No such device"; then
    return 2
  fi
  if echo "$out" | grep -qiE "org\.bluez\.Error|Failed"; then
    return 1
  fi

  _wait_connected_yes "$mac" && return 0
  # Give it a tiny settle window (without full rekey)
  sleep 2
  _is_connected "$mac" && return 0
  return 1
}

_connect_device_with_scan() {
  # Mimic blueman: keep discovery on while trying to connect
  local mac="$1"
  local out=""

  _bt_prepare_agent
  bluetoothctl scan on >/dev/null 2>&1 || true

  # Wait a bit for visibility
  _wait_until_device_visible "$mac" || true

  out="$(_btctl_capture connect "$mac")"
  if echo "$out" | grep -qiE "org\.bluez\.Error|Failed|No such device"; then
    bluetoothctl scan off >/dev/null 2>&1 || true
    return 1
  fi

  if ! _wait_connected_yes "$mac"; then
    local t=0
    while [ $t -lt 6 ]; do
      _is_connected "$mac" && break
      sleep 1
      t=$((t + 1))
    done
  fi

  bluetoothctl scan off >/dev/null 2>&1 || true
  _is_connected "$mac" && return 0
  return 1
}

_disconnect_device() {
  local mac="$1"
  timeout "$BLUETOOTH_TIMEOUT" bluetoothctl disconnect "$mac" >/dev/null 2>&1 || true
  _is_connected "$mac" && return 1
  return 0
}

manage_connection() {
  local mac="$1" name="$2"

  local connected="no"
  connected="$(bluetoothctl info "$mac" 2>/dev/null | awk -F': ' '/Connected:/ {print $2; exit}' || true)"
  [ -z "${connected:-}" ] && connected="no"

  if [ "$connected" = "yes" ]; then
    log "Device is currently connected: $name ($mac)" "INFO"
    case "$MODE" in
    connect)
      log "Already connected; refreshing audio routing." "INFO"
      configure_audio_bluetooth || true
      return 0
      ;;
    disconnect | toggle)
      log "Disconnecting..." "INFO"
      if _disconnect_device "$mac"; then
        log "Disconnected." "SUCCESS"
        send_notification "Bluetooth Disconnected" "$name disconnected."
        configure_audio_default || true
        return 0
      else
        log "Failed to disconnect (non-fatal)." "WARNING"
        return 1
      fi
      ;;
    *)
      log "Invalid mode: $MODE" "ERROR"
      return 1
      ;;
    esac
  else
    log "Device is NOT connected: $name ($mac)" "INFO"
    case "$MODE" in
    disconnect)
      log "Already disconnected; applying default audio levels." "INFO"
      configure_audio_default || true
      return 0
      ;;
    connect | toggle)
      log "Connecting..." "INFO"

      local rc=0
      _connect_device_fast "$mac" || rc=$?

      if [ "${rc:-0}" -eq 0 ]; then
        log "Connected." "SUCCESS"
        local battery=""
        battery="$(get_battery_percentage "$mac")" || true
        if [ -n "$battery" ]; then
          send_notification "Bluetooth Connected" "$name connected. Battery: $battery"
        else
          send_notification "Bluetooth Connected" "$name connected."
        fi
        configure_audio_bluetooth || true
        return 0
      fi

      # If device "not available", try connect while scanning (blueman-like)
      if [ "${rc:-0}" -eq 2 ]; then
        log "Device not available. Trying discovery-assisted connect..." "WARNING"
        if _connect_device_with_scan "$mac"; then
          log "Connected (after scan)." "SUCCESS"
          configure_audio_bluetooth || true
          return 0
        fi
      fi

      # If connect fails:
      if [ "$AUTO_REKEY" = true ]; then
        log "Connect failed; AUTO_REKEY enabled. Running --rekey path..." "WARNING"
        _rekey_and_repair && return 0
      fi

      log "Connect failed. If this is dual-boot br-connection-key, run: --rekey --adapter=<MAC>" "ERROR"
      return 1
      ;;
    *)
      log "Invalid mode: $MODE" "ERROR"
      return 1
      ;;
    esac
  fi
}

# ==============================================================================
# CLI
# ==============================================================================

show_help() {
  cat <<EOF
Usage: $0 [OPTIONS] [MAC] [NAME]

Modes:
  --connect             Connect (or refresh audio if already connected)
  --disconnect          Disconnect (or apply default audio if already disconnected)
  --toggle              Toggle (default)

Dual-boot fix:
  --rekey               Stop bluetooth, wipe /var/lib/bluetooth/<ADAPTER>, start bluetooth,
                        then remove/pair/trust/connect with strict verification and set alias.
  --adapter=<MAC>       Adapter MAC for /var/lib/bluetooth/<MAC> (e.g. A8:59:5F:FF:8E:BB)
  --alias=<NAME>        Alias to set after rekey (default: ${DEFAULT_DEVICE_ALIAS})
  --auto-rekey          If normal connect fails, automatically run rekey flow.

Other:
  --backend=wpctl       Force PipeWire wpctl
  --backend=pactl       Force PulseAudio pactl
  --battery             Only show battery (if supported)
  -v, --verbose         set -x
  -q, --quiet           suppress stderr
  -h, --help            show help

Examples:
  $0
  $0 --connect
  $0 --auto-rekey
  $0 --rekey --adapter=A8:59:5F:FF:8E:BB --alias=SLP4
  $0 F4:9D:8A:3D:CB:30 "SL4P"

Default device: ${DEFAULT_DEVICE_NAME} (${DEFAULT_DEVICE_ADDRESS})
EOF
}

parse_arguments() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
    --connect)
      MODE="connect"
      shift
      ;;
    --disconnect)
      MODE="disconnect"
      shift
      ;;
    --toggle)
      MODE="toggle"
      shift
      ;;
    --battery)
      MODE_BATTERY_ONLY=true
      shift
      ;;
    --rekey)
      MODE_REKEY=true
      shift
      ;;
    --auto-rekey)
      AUTO_REKEY=true
      shift
      ;;
    --adapter=*)
      ADAPTER_ADDRESS="${1#*=}"
      shift
      ;;
    --alias=*)
      DEVICE_ALIAS="${1#*=}"
      shift
      ;;
    --backend=*)
      BACKEND_FORCED="${1#*=}"
      shift
      ;;
    -v | --verbose)
      set -x
      shift
      ;;
    -q | --quiet)
      exec 2>/dev/null
      shift
      ;;
    -h | --help)
      show_help
      exit 0
      ;;
    -*)
      log "Unknown option: $1" "ERROR"
      show_help
      exit 1
      ;;
    *)
      if [ -z "${DEVICE_ADDRESS:-}" ]; then
        DEVICE_ADDRESS="$1"
      elif [ -z "${DEVICE_NAME:-}" ]; then
        DEVICE_NAME="$1"
      else
        log "Too many positional args." "ERROR"
        show_help
        exit 1
      fi
      shift
      ;;
    esac
  done
}

cleanup() {
  log "Exiting..." "INFO"
  exit 0
}
trap cleanup SIGINT SIGTERM

main() {
  parse_arguments "$@"

  DEVICE_ADDRESS="${DEVICE_ADDRESS:-$DEFAULT_DEVICE_ADDRESS}"
  DEVICE_NAME="${DEVICE_NAME:-$DEFAULT_DEVICE_NAME}"

  # Basic deps
  check_command bluetoothctl
  check_command timeout

  check_bluetooth_service
  check_bluetooth_power || exit 1

  detect_backend
  if [ "$AUDIO_BACKEND" = "wpctl" ]; then check_command wpctl; fi
  if [ "$AUDIO_BACKEND" = "pactl" ]; then check_command pactl; fi

  log "Target device: $DEVICE_NAME ($DEVICE_ADDRESS)" "INFO"

  if [ "$MODE_BATTERY_ONLY" = true ]; then
    local battery=""
    battery="$(get_battery_percentage "$DEVICE_ADDRESS")" || true
    if [ -n "$battery" ]; then
      send_notification "BT Battery" "$DEVICE_NAME: $battery"
      log "Battery: $battery" "INFO"
      exit 0
    else
      log "Battery info not available." "WARNING"
      exit 1
    fi
  fi

  if [ "$MODE_REKEY" = true ]; then
    _rekey_and_repair && {
      log "Done." "SUCCESS"
      exit 0
    }
    log "Rekey failed." "ERROR"
    exit 1
  fi

  if manage_connection "$DEVICE_ADDRESS" "$DEVICE_NAME"; then
    log "Done." "SUCCESS"
    exit 0
  else
    log "Failed." "ERROR"
    exit 1
  fi
}

main "$@"
