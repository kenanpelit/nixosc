#!/usr/bin/env bash

# Hypr Blue Manager
# Version: 3.1.0 (Gammastep + HyprSunset)
# Simple night-light helper for starting/stopping Gammastep and HyprSunset.

STATE_FILE="$HOME/.cache/hypr-blue.state"
PID_FILE="$HOME/.cache/hypr-blue.pid"
GAMMASTEP_PID_FILE="$HOME/.cache/hypr-blue-gammastep.pid"
LOG_FILE="/tmp/hypr-blue.log"
LAST_TEMP_FILE="$HOME/.cache/hypr-blue.last"

ENABLE_GAMMASTEP=true
ENABLE_HYPRSUNSET=true

MODE="wayland"
LOCATION="41.0108:29.0219"
GAMMA="1,0.2,0.1"
BRIGHTNESS_DAY=1.0
BRIGHTNESS_NIGHT=0.8

TEMP_DAY=4000
TEMP_NIGHT=3500
GAMMASTEP_TEMP_DAY=4000
GAMMASTEP_TEMP_NIGHT=3500

CHECK_INTERVAL=3600

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >>"$LOG_FILE"; }

usage() {
  cat <<EOF
Hypr Blue Manager - Gammastep + HyprSunset

Usage:
  $(basename "$0") start|daemon|stop|toggle|status [options]

Options:
  --enable-gammastep BOOL     (default: $ENABLE_GAMMASTEP)
  --enable-hyprsunset BOOL    (default: $ENABLE_HYPRSUNSET)
  --temp-day VALUE            HyprSunset day temp (default: $TEMP_DAY)
  --temp-night VALUE          HyprSunset night temp (default: $TEMP_NIGHT)
  --gs-temp-day VALUE         Gammastep day temp (default: $GAMMASTEP_TEMP_DAY)
  --gs-temp-night VALUE       Gammastep night temp (default: $GAMMASTEP_TEMP_NIGHT)
  --bright-day VALUE          Gammastep day brightness (default: $BRIGHTNESS_DAY)
  --bright-night VALUE        Gammastep night brightness (default: $BRIGHTNESS_NIGHT)
  --location VALUE            Gammastep location lat:lon (default: $LOCATION)
  --gamma VALUE               Gammastep gamma r,g,b (default: $GAMMA)
  --interval VALUE            Check interval seconds (default: $CHECK_INTERVAL)
EOF
}

check_dependencies() {
  local ok=0
  if [[ "$ENABLE_GAMMASTEP" == "true" ]]; then
    if command -v gammastep >/dev/null 2>&1; then ((ok++)); else
      log "Gammastep not found"
      ENABLE_GAMMASTEP=false
    fi
  fi
  if [[ "$ENABLE_HYPRSUNSET" == "true" ]]; then
    if command -v hyprsunset >/dev/null 2>&1; then ((ok++)); else
      log "HyprSunset not found"
      ENABLE_HYPRSUNSET=false
    fi
  fi
  [[ $ok -eq 0 ]] && {
    echo "No tools available"
    exit 1
  }
  log "Active tools: Gammastep=$ENABLE_GAMMASTEP, HyprSunset=$ENABLE_HYPRSUNSET"
}

start_gammastep() {
  [[ "$ENABLE_GAMMASTEP" != "true" ]] && return 0
  log "Starting Gammastep"
  pkill -9 gammastep 2>/dev/null
  gammastep -m "$MODE" -l manual \
    -t "$GAMMASTEP_TEMP_DAY:$GAMMASTEP_TEMP_NIGHT" \
    -b "$BRIGHTNESS_DAY:$BRIGHTNESS_NIGHT" \
    -l "$LOCATION" -g "$GAMMA" >/dev/null 2>&1 &
  echo $! >"$GAMMASTEP_PID_FILE"
}

stop_gammastep() {
  [[ "$ENABLE_GAMMASTEP" != "true" ]] && return 0
  if [[ -f "$GAMMASTEP_PID_FILE" ]]; then
    pid=$(cat "$GAMMASTEP_PID_FILE")
    kill -TERM "$pid" 2>/dev/null || true
    sleep 0.5
    kill -KILL "$pid" 2>/dev/null || true
    rm -f "$GAMMASTEP_PID_FILE"
  fi
  pkill -9 gammastep 2>/dev/null
}

get_hour() { printf "%d" "$(date +%H)"; }

hyprsunset_temp() {
  local h=$(get_hour)
  if [[ $h -ge 6 && $h -lt 18 ]]; then echo "$TEMP_DAY"; else echo "$TEMP_NIGHT"; fi
}

start_or_update_hyprsunset() {
  [[ "$ENABLE_HYPRSUNSET" != "true" ]] && return 0
  local temp="$1"
  pkill -9 hyprsunset 2>/dev/null
  hyprsunset -t "$temp" >/dev/null 2>&1 &
  echo "$temp" >"$LAST_TEMP_FILE"
}

adjust_temperature() {
  local h=$(get_hour)
  [[ $h -ne 6 && $h -ne 18 ]] && return 0
  if [[ "$ENABLE_HYPRSUNSET" == "true" ]]; then
    start_or_update_hyprsunset "$(hyprsunset_temp)"
  fi
}

start_service() {
  >"$LOG_FILE"
  log "Starting Hypr Blue Manager"
  start_gammastep
  if [[ "$ENABLE_HYPRSUNSET" == "true" ]]; then
    start_or_update_hyprsunset "$(hyprsunset_temp)"
  fi
  touch "$STATE_FILE"
  echo $$ >"$PID_FILE"
  send_notification "Hypr Blue Manager" "Started"
}

stop_service() {
  [[ -f "$STATE_FILE" ]] || {
    echo "Already stopped"
    return 1
  }
  stop_gammastep
  if [[ "$ENABLE_HYPRSUNSET" == "true" ]]; then hyprsunset -i >/dev/null 2>&1; fi
  rm -f "$STATE_FILE" "$PID_FILE"
  send_notification "Hypr Blue Manager" "Stopped"
}

toggle_service() { [[ -f "$STATE_FILE" ]] && stop_service || start_service; }

show_status() {
  echo "=== Hypr Blue Manager Status ==="
  if [[ -f "$STATE_FILE" ]]; then
    echo "Main Service: ACTIVE"
    [[ -f "$PID_FILE" ]] && echo "PID: $(cat "$PID_FILE")"
  else
    echo "Main Service: STOPPED"
  fi
  echo "Gammastep: $([[ \"$ENABLE_GAMMASTEP\" == true ]] && echo ACTIVE || echo OFF)"
  echo "HyprSunset: $([[ \"$ENABLE_HYPRSUNSET\" == true ]] && echo ACTIVE || echo OFF)"
}

daemon_mode() {
  start_service
  while [[ -f "$STATE_FILE" ]]; do
    sleep "$CHECK_INTERVAL"
    adjust_temperature
  done
}

send_notification() {
  if command -v notify-send >/dev/null 2>&1; then
    notify-send -t 1500 "$1" "$2" 2>/dev/null
  fi
  log "Notification: $1 - $2"
}

main() {
  mkdir -p "$(dirname "$LOG_FILE")" "$HOME/.cache"
  touch "$LOG_FILE"

  [[ $# -eq 0 ]] && {
    usage
    exit 1
  }

  while [[ $# -gt 0 ]]; do
    case $1 in
    --enable-gammastep)
      ENABLE_GAMMASTEP="$2"
      shift 2
      ;;
    --enable-hyprsunset)
      ENABLE_HYPRSUNSET="$2"
      shift 2
      ;;
    --temp-day)
      TEMP_DAY="$2"
      shift 2
      ;;
    --temp-night)
      TEMP_NIGHT="$2"
      shift 2
      ;;
    --gs-temp-day)
      GAMMASTEP_TEMP_DAY="$2"
      shift 2
      ;;
    --gs-temp-night)
      GAMMASTEP_TEMP_NIGHT="$2"
      shift 2
      ;;
    --bright-day)
      BRIGHTNESS_DAY="$2"
      shift 2
      ;;
    --bright-night)
      BRIGHTNESS_NIGHT="$2"
      shift 2
      ;;
    --location)
      LOCATION="$2"
      shift 2
      ;;
    --gamma)
      GAMMA="$2"
      shift 2
      ;;
    --interval)
      CHECK_INTERVAL="$2"
      shift 2
      ;;
    start)
      check_dependencies
      start_service
      exit $?
      ;;
    daemon)
      check_dependencies
      daemon_mode
      exit $?
      ;;
    stop)
      stop_service
      exit $?
      ;;
    toggle)
      check_dependencies
      toggle_service
      exit $?
      ;;
    status)
      show_status
      exit $?
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    *)
      echo "Invalid parameter: $1"
      usage
      exit 1
      ;;
    esac
  done
}

main "$@"
