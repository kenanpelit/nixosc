#!/usr/bin/env bash

#######################################
#
# Version: 3.0.3
# Date: 2025-12-13
# Author: Kenan Pelit (Modified)
# Repository: github.com/kenanpelit/dotfiles
# Description: Unified Gammastep + HyprSunset Manager
#
# License: MIT
#
# Changelog v3.0.2:
#   - FIXED: Added temperature adjustment based on current time at first startup
#   - When daemon starts, it sets night temperature if it's night, day temp if day
#
# Changelog v3.0.1:
#   - FIXED: Redundant adjustment every hour problem
#   - Temperature adjustment is done ONLY at transition hours (06:00 and 18:00)
#   - Existing settings are preserved at other times
#
#######################################

#########################################################################
# Unified Night Light Manager
#
# This script manages Gammastep and HyprSunset together. wl-gammarelay support removed.
# All three tools work simultaneously to achieve the desired color tone.
#
# Features:
#   - Simultaneous start/stop of Gammastep and HyprSunset
#   - Time-based automatic color temperature adjustment
#   - Waybar integration
#   - System notifications
#   - Daemon and fork modes
#   - Each tool can run independently
#
# Requirements:
#   - gammastep (optional)
#   - hyprsunset (optional)
#   - #   - libnotify (for notify-send)
#   - waybar (optional)
#
#########################################################################

# File paths
declare -r STATE_FILE="$HOME/.cache/hypr-blue.state"
declare -r PID_FILE="$HOME/.cache/hypr-blue.pid"
declare -r GAMMASTEP_PID_FILE="$HOME/.cache/hypr-blue-gammastep.pid"
declare -r LOG_FILE="/tmp/hypr-blue.log"
declare -r LAST_TEMP_FILE="$HOME/.cache/hypr-blue.last"

# Tool activity checks
ENABLE_GAMMASTEP=true
ENABLE_HYPRSUNSET=true
ENABLE_WLGAMMARELAY=false

# Gammastep settings
MODE="wayland"
LOCATION="41.0108:29.0219"
GAMMA="1,0.2,0.1"
BRIGHTNESS_DAY=1.0
BRIGHTNESS_NIGHT=0.8

# Temperature profiles - 3 different levels for each tool
# 4000K - Light yellow/orange
# 3500K - Medium yellow/orange
# 3000K - Dark orange/reddish

# HyprSunset temperature settings
TEMP_DAY=4000   # Day temperature
TEMP_NIGHT=3500 # Night temperature

# Gammastep temperature settings
GAMMASTEP_TEMP_DAY=4000
GAMMASTEP_TEMP_NIGHT=3500

# Other settings
CHECK_INTERVAL=3600
CLEANUP_ON_EXIT=false

export PATH="/etc/profiles/per-user/$USER/bin:/run/current-system/sw/bin:/run/wrappers/bin:${PATH:-}"

# Logging function
log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >>"$LOG_FILE"
}

# Usage information
usage() {
  cat <<EOF
Hypr Blue Manager - Unified Gammastep + HyprSunset Manager

USAGE:
    $(basename "$0") [COMMAND] [PARAMETERS]

COMMANDS:
    start         Start night light (fork mode)
    daemon        Start in daemon mode (for systemd)
    stop          Stop night light
    toggle        Toggle night light on/off
    status        Show status
    -h, --help    Show this help message

TOOL CONTROL:
    --enable-gammastep BOOL     Enable Gammastep (true/false, default: $ENABLE_GAMMASTEP)
    --enable-hyprsunset BOOL    Enable HyprSunset (true/false, default: $ENABLE_HYPRSUNSET)
    
HYPRSUNSET PARAMETERS:
    --temp-day VALUE            Day temperature (Kelvin, default: $TEMP_DAY)
    --temp-night VALUE          Night temperature (Kelvin, default: $TEMP_NIGHT)

GAMMASTEP PARAMETERS:
    --gs-temp-day VALUE         Gammastep day temperature (Kelvin, default: $GAMMASTEP_TEMP_DAY)
    --gs-temp-night VALUE       Gammastep night temperature (Kelvin, default: $GAMMASTEP_TEMP_NIGHT)
    --bright-day VALUE          Day brightness (0.1-1.0, default: $BRIGHTNESS_DAY)
    --bright-night VALUE        Night brightness (0.1-1.0, default: $BRIGHTNESS_NIGHT)
    --location VALUE            Location (format: lat:lon, default: $LOCATION)
    --gamma VALUE               Gamma value (format: r,g,b, default: $GAMMA)

WL-GAMMARELAY PARAMETERS:
                
OTHER PARAMETERS:
    --interval VALUE            Check interval (seconds, default: $CHECK_INTERVAL)

EXAMPLES:
    # Start with default settings (all tools active)
    $(basename "$0") start

    # Run with Gammastep only
    $(basename "$0") start --enable-hyprsunset false --enable-wlgamma false

    # Run with wl-gammarelay only
    $(basename "$0") start --enable-gammastep false --enable-hyprsunset false

    # Start with custom temperatures (all tools)
    $(basename "$0") start --temp-day 4000 --temp-night 3000 \
                           --gs-temp-day 4000 --gs-temp-night 3000 \
                           --wl-temp-day 4000 --wl-temp-night 3000

    # Light yellow tone (4000K) - all tools
    $(basename "$0") start --temp-day 4000 --temp-night 4000 \
                           --gs-temp-day 4000 --gs-temp-night 4000 \
                           --wl-temp-day 4000 --wl-temp-night 4000

    # Medium tone (3500K) - all tools
    $(basename "$0") start --temp-day 3500 --temp-night 3500 \
                           --gs-temp-day 3500 --gs-temp-night 3500 \
                           --wl-temp-day 3500 --wl-temp-night 3500

    # Dark orange (3000K) - all tools
    $(basename "$0") start --temp-day 3000 --temp-night 3000 \
                           --gs-temp-day 3000 --gs-temp-night 3000 \
                           --wl-temp-day 3000 --wl-temp-night 3000

    # For Systemd service
    $(basename "$0") daemon

    # Check status
    $(basename "$0") status

TEMPERATURE GUIDE:
    4000K - Light yellow/orange (least effect)
    3500K - Medium yellow/orange (balanced)
    3000K - Dark orange/reddish (maximum effect)

NOTE:
    - Each tool can be enabled/disabled independently
    - At least one tool must be active
    - All tools can run simultaneously (maximum effect)
    - Lower temperature values give warmer/redder colors
    - Each tool adds its own layer, together providing stronger effect
    - Temperature adjustment is done ONLY at 06:00 and 18:00
    - Existing settings are preserved at other times
EOF
}

# Check dependencies
check_dependencies() {
  local missing_deps=()
  local available_tools=0

  if [[ "$ENABLE_GAMMASTEP" == "true" ]]; then
    if command -v gammastep >/dev/null 2>&1; then
      ((available_tools++))
    else
      log "WARNING: Gammastep active but not found"
      ENABLE_GAMMASTEP=false
    fi
  fi

  if [[ "$ENABLE_HYPRSUNSET" == "true" ]]; then
    if command -v hyprsunset >/dev/null 2>&1; then
      ((available_tools++))
    else
      log "WARNING: HyprSunset active but not found"
      ENABLE_HYPRSUNSET=false
    fi
  fi


  if [[ $available_tools -eq 0 ]]; then
    echo "Error: No tools available or active"
    log "ERROR: No tools available"
    exit 1
  fi

  log "Active tools: Gammastep=$ENABLE_GAMMASTEP, HyprSunset=$ENABLE_HYPRSUNSET, wl-gammarelay=$ENABLE_WLGAMMARELAY"
}

# Send notification
send_notification() {
  if command -v notify-send >/dev/null 2>&1; then
    notify-send -t 2000 "$1" "$2" 2>/dev/null
  fi
  log "Notification: $1 - $2"
}

# Update Waybar
update_waybar() {
  if command -v waybar &>/dev/null; then
    pkill -RTMIN+8 waybar
  fi
}

# Get current hour
get_current_hour() {
  local hour
  hour="$(date +%H 2>/dev/null || echo 00)"
  echo $((10#$hour))
}

# Determine temperature for HyprSunset
get_hyprsunset_temp() {
  local hour=$(get_current_hour)

  # Day: 6:00-18:00
  # Night: 18:00-6:00
  if [[ "$hour" -ge 6 && "$hour" -lt 18 ]]; then
    echo "$TEMP_DAY"
  else
    echo "$TEMP_NIGHT"
  fi
}

# Determine temperature for wl-gammarelay
get_wlgamma_temp() {
  local hour=$(get_current_hour)

  if [[ "$hour" -ge 6 && "$hour" -lt 18 ]]; then
    echo "$WLGAMMA_TEMP_DAY"
  else
    echo "$WLGAMMA_TEMP_NIGHT"
  fi
}

# Start Gammastep
start_gammastep() {
  if [[ "$ENABLE_GAMMASTEP" != "true" ]]; then
    log "Gammastep disabled, skipping"
    return 0
  fi

  log "Starting Gammastep..."

  # Clean up old gammastep processes
  pkill -9 gammastep 2>/dev/null
  sleep 1

  $(command -v gammastep) -m "$MODE" \
    -l manual \
    -t "$GAMMASTEP_TEMP_DAY:$GAMMASTEP_TEMP_NIGHT" \
    -b "$BRIGHTNESS_DAY:$BRIGHTNESS_NIGHT" \
    -l "$LOCATION" \
    -g "$GAMMA" \
    >>/dev/null 2>&1 &

  local gammastep_pid=$!
  echo "$gammastep_pid" >"$GAMMASTEP_PID_FILE"
  disown

  log "Gammastep started (PID: $gammastep_pid, Day: ${GAMMASTEP_TEMP_DAY}K, Night: ${GAMMASTEP_TEMP_NIGHT}K)"
}

# Stop Gammastep
stop_gammastep() {
  if [[ "$ENABLE_GAMMASTEP" != "true" ]]; then
    return 0
  fi

  log "Stopping Gammastep..."

  if [[ -f "$GAMMASTEP_PID_FILE" ]]; then
    local pid=$(cat "$GAMMASTEP_PID_FILE")
    if [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null; then
      kill -TERM "$pid" 2>/dev/null
      sleep 1
      kill -0 "$pid" 2>/dev/null && kill -KILL "$pid" 2>/dev/null
    fi
    rm -f "$GAMMASTEP_PID_FILE"
  fi

  # Clean up all gammastep processes
  pkill -9 gammastep 2>/dev/null
  log "Gammastep stopped"
}

# Start HyprSunset daemon or update temperature
start_or_update_hyprsunset() {
  if [[ "$ENABLE_HYPRSUNSET" != "true" ]]; then
    return 0
  fi

  local temp=$1

  # Validate temperature value
  if [[ ! "$temp" =~ ^[0-9]+$ ]] || [[ "$temp" -lt 1000 ]] || [[ "$temp" -gt 10000 ]]; then
    log "ERROR: Invalid temperature value: ${temp}K (must be between 1000-10000)"
    return 1
  fi

  log "Setting HyprSunset temperature: ${temp}K"

  # Stop old hyprsunset processes
  pkill -9 hyprsunset 2>/dev/null
  sleep 0.5

  # Start in daemon mode (runs continuously in background)
  hyprsunset -t "$temp" >/dev/null 2>&1 &
  local hs_pid=$!
  disown

  # Wait for start
  sleep 1

  if kill -0 "$hs_pid" 2>/dev/null; then
    echo "$temp" >"$LAST_TEMP_FILE"
    log "HyprSunset started and temperature set: ${temp}K (PID: $hs_pid)"
    return 0
  else
    log "ERROR: Failed to start HyprSunset"
    return 1
  fi
}

# Start or check wl-gammarelay daemon

# Stop wl-gammarelay daemon (only if we started it)

# Set wl-gammarelay temperature
set_wlgamma_temperature() {

  local temp=$1
  log "Setting wl-gammarelay temperature: ${temp}K"

  # Check if wl-gammarelay service is running
  if ! busctl --user status rs.wl-gammarelay >/dev/null 2>&1; then
    log "WARNING: wl-gammarelay service not found"
    return 1
  fi

  # Set temperature
  if busctl --user set-property rs.wl-gammarelay / rs.wl.gammarelay Temperature q "$temp" >/dev/null 2>&1; then
    log "wl-gammarelay temperature set: ${temp}K"

    # Set brightness and gamma too
    busctl --user set-property rs.wl-gammarelay / rs.wl.gammarelay Brightness d "$WLGAMMA_BRIGHTNESS" >/dev/null 2>&1
    busctl --user set-property rs.wl-gammarelay / rs.wl.gammarelay Gamma d "$WLGAMMA_GAMMA" >/dev/null 2>&1

    return 0
  else
    log "ERROR: Failed to set wl-gammarelay temperature"
    return 1
  fi
}

# Adjust all temperatures
adjust_temperature() {
  local hour=$(get_current_hour)
  local period="night"
  [[ "$hour" -ge 6 && "$hour" -lt 18 ]] && period="day"

  # Only adjust at transition hours (06:00 and 18:00)
  # Maintain current state at other times
  if [[ "$hour" -ne 6 && "$hour" -ne 18 ]]; then
    log "Hour $hour - not a transition hour, maintaining settings (period: $period)"
    return 0
  fi

  log "Temperature adjustment starting (hour: $hour, period: $period) - TRANSITION HOUR"

  # HyprSunset
  if [[ "$ENABLE_HYPRSUNSET" == "true" ]]; then
    local hs_temp=$(get_hyprsunset_temp)
    start_or_update_hyprsunset "$hs_temp"
  fi

}

# Daemon cleanup
cleanup_daemon() {
  log "Daemon cleanup starting (PID: $$"

  stop_gammastep
  stop_wlgammarelay
  rm -f "$STATE_FILE" "$PID_FILE"

  if [[ "$ENABLE_HYPRSUNSET" == "true" ]] && command -v hyprsunset >/dev/null 2>&1; then
    hyprsunset -i >/dev/null 2>&1
    log "HyprSunset temperature reset"
  fi

  log "Daemon cleanup complete"
}

# Set trap
trap cleanup EXIT INT TERM

# Daemon loop (for fork mode)
daemon_loop() {
  # Clear log file (avoid mixing old logs)
  >"$LOG_FILE"

  log "Fork daemon loop started (PID: $$"
  log "Parameters: Gammastep=$ENABLE_GAMMASTEP, HyprSunset=$ENABLE_HYPRSUNSET, wl-gammarelay=$ENABLE_WLGAMMARELAY"

  # Initial adjustments
  start_gammastep
  start_wlgammarelay

  # If wl-gammarelay is disabled but running externally, adjust it too

  # Adjust temperature based on current time at first startup
  local hour=$(get_current_hour)
  local period="night"
  [[ "$hour" -ge 6 && "$hour" -lt 18 ]] && period="day"

  log "First startup: Current hour $hour, period: $period - setting temperature"

  # HyprSunset
  if [[ "$ENABLE_HYPRSUNSET" == "true" ]]; then
    local hs_temp=$(get_hyprsunset_temp)
    start_or_update_hyprsunset "$hs_temp"
  fi



  log "Starting Hypr Blue Manager (fork mode)"
  log "Active tools: Gammastep=$ENABLE_GAMMASTEP, HyprSunset=$ENABLE_HYPRSUNSET, wl-gammarelay=$ENABLE_WLGAMMARELAY"

  touch "$STATE_FILE"

  daemon_loop &
  local daemon_pid=$!

  echo "$daemon_pid" >"$PID_FILE"
  log "Fork daemon started (PID: $daemon_pid)"

  sleep 1
  if kill -0 "$daemon_pid" 2>/dev/null; then
    local tools=""
    [[ "$ENABLE_GAMMASTEP" == "true" ]] && tools+="Gammastep "
    [[ "$ENABLE_HYPRSUNSET" == "true" ]] && tools+="HyprSunset "
    [[ "$ENABLE_WLGAMMARELAY" == "true" ]] && tools+="wl-gammarelay"

    send_notification "Hypr Blue Manager" "Started successfully ($tools)"
    echo "Hypr Blue Manager started (PID: $daemon_pid)"
    echo "Active tools: $tools"
    update_waybar
    return 0
  else
    log "ERROR: Failed to start fork daemon"
    rm -f "$STATE_FILE" "$PID_FILE"
    echo "ERROR: Failed to start service"
    return 1
  fi
}

# Stop service
stop_service() {
  if [[ ! -f "$STATE_FILE" ]]; then
    log "Service already stopped"
    echo "Hypr Blue Manager already stopped"
    return 1
  fi

  log "Stopping Hypr Blue Manager"
  CLEANUP_ON_EXIT=true

  rm -f "$STATE_FILE"

  if [[ -f "$PID_FILE" ]]; then
    local pid=$(cat "$PID_FILE")
    if [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null; then
      log "Terminating daemon (PID: $pid)"
      kill -TERM "$pid" 2>/dev/null

      for i in {1..5}; do
        if ! kill -0 "$pid" 2>/dev/null; then
          break
        fi
        sleep 1
      done

      if kill -0 "$pid" 2>/dev/null; then
        log "Force killing daemon"
        kill -KILL "$pid" 2>/dev/null
      fi
    fi
    rm -f "$PID_FILE"
  fi

  # Stop Gammastep
  stop_gammastep

  # Reset wl-gammarelay
  stop_wlgammarelay

  # Reset HyprSunset
  if [[ "$ENABLE_HYPRSUNSET" == "true" ]] && hyprsunset -i >/dev/null 2>&1; then
    log "HyprSunset temperature reset"
  fi

  send_notification "Hypr Blue Manager" "Stopped"
  echo "Hypr Blue Manager stopped"
  update_waybar

  CLEANUP_ON_EXIT=false
  return 0
}

# Toggle function
toggle_service() {
  if [[ -f "$STATE_FILE" ]]; then
    stop_service
  else
    start_service
  fi
}

# Show status
show_status() {
  echo "=== Hypr Blue Manager Status ==="
  echo ""

  if [[ -f "$STATE_FILE" ]]; then
    local pid=""
    local status="ACTIVE"
    local mode="Unknown"

    if [[ -f "$PID_FILE" ]]; then
      pid=$(cat "$PID_FILE")
      if kill -0 "$pid" 2>/dev/null; then
        if ps -p "$pid" -o cmd= | grep -q "daemon"; then
          mode="Systemd Daemon"
        else
          mode="Fork Daemon"
        fi
      else
        status="ERROR (Invalid PID)"
      fi
    else
      status="ERROR (No PID file)"
    fi

    echo "Main Service: $status"
    [[ -n "$pid" ]] && echo "PID: $pid"
    echo "Mode: $mode"
    echo "Last started: $(stat -c %y "$STATE_FILE" 2>/dev/null || echo 'Unknown')"
  else
    echo "Main Service: STOPPED"
  fi

  echo ""
  echo "--- Tool Status ---"
  echo "Gammastep: $([ "$ENABLE_GAMMASTEP" == "true" ] && echo "ACTIVE" || echo "OFF")"
  echo "HyprSunset: $([ "$ENABLE_HYPRSUNSET" == "true" ] && echo "ACTIVE" || echo "OFF")"
  echo "wl-gammarelay: OFF (removed)"

  if [[ "$ENABLE_GAMMASTEP" == "true" ]]; then
    echo ""
    echo "--- Gammastep Details ---"
    if [[ -f "$GAMMASTEP_PID_FILE" ]]; then
      local gs_pid=$(cat "$GAMMASTEP_PID_FILE")
      if kill -0 "$gs_pid" 2>/dev/null; then
        echo "Status: RUNNING (PID: $gs_pid)"
      else
        echo "Status: ERROR (Invalid PID)"
      fi
    else
      if pgrep gammastep &>/dev/null; then
        echo "Status: RUNNING (No PID file)"
      else
        echo "Status: STOPPED"
      fi
    fi
    echo "Day temperature: ${GAMMASTEP_TEMP_DAY}K"
    echo "Night temperature: ${GAMMASTEP_TEMP_NIGHT}K"
    echo "Day brightness: $BRIGHTNESS_DAY"
    echo "Night brightness: $BRIGHTNESS_NIGHT"
  fi

  if [[ "$ENABLE_HYPRSUNSET" == "true" ]]; then
    echo ""
    echo "--- HyprSunset Details ---"
    echo "Day temperature: ${TEMP_DAY}K (06:00-18:00)"
    echo "Night temperature: ${TEMP_NIGHT}K (18:00-06:00)"
    echo "Check interval: ${CHECK_INTERVAL} seconds"
    echo "Transition hours: 06:00 (day) and 18:00 (night)"
    if [[ -f "$LAST_TEMP_FILE" ]]; then
      echo "Last temperature: $(cat "$LAST_TEMP_FILE")K"
    fi
  fi


  echo ""
  echo "--- Location and Gamma ---"
  echo "Location: $LOCATION"
  echo "Gamma: $GAMMA"

  if [[ -f "$LOG_FILE" ]]; then
    echo ""
    echo "--- Last Log Entries ---"
    echo "Log file: $LOG_FILE"
    if [[ -f "$PID_FILE" ]]; then
      local current_pid=$(cat "$PID_FILE")
      echo "Daemon PID: $current_pid"
    fi
    tail -n 10 "$LOG_FILE" 2>/dev/null || echo "Cannot read log"
  fi
}

# Main process
main() {
  mkdir -p "$(dirname "$LOG_FILE")"
  mkdir -p "$HOME/.cache"
  touch "$LOG_FILE"
  log "=== Hypr Blue Manager started (v3.0.2) ==="

  if [[ $# -eq 0 ]]; then
    usage
    exit 1
  fi

  # Parse parameters
  while [[ $# -gt 0 ]]; do
    case $1 in
    # Tool control
    --enable-gammastep)
      ENABLE_GAMMASTEP="$2"
      shift 2
      ;;
    --enable-hyprsunset)
      ENABLE_HYPRSUNSET="$2"
      shift 2
      ;;
    --enable-wlgamma)
      ENABLE_WLGAMMARELAY="$2"
      shift 2
      ;;
    # HyprSunset parameters
    --temp-day)
      TEMP_DAY="$2"
      shift 2
      ;;
    --temp-night)
      TEMP_NIGHT="$2"
      shift 2
      ;;
    --interval)
      CHECK_INTERVAL="$2"
      shift 2
      ;;
    # Gammastep parameters
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
    # wl-gammarelay parameters
    --wl-temp-day)
      WLGAMMA_TEMP_DAY="$2"
      shift 2
      ;;
    --wl-temp-night)
      WLGAMMA_TEMP_NIGHT="$2"
      shift 2
      ;;
    --wl-brightness)
      WLGAMMA_BRIGHTNESS="$2"
      shift 2
      ;;
    --wl-gamma)
      WLGAMMA_GAMMA="$2"
      shift 2
      ;;
    # Commands
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

# Start program
main "$@"