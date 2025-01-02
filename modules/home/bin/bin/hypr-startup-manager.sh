#!/usr/bin/env bash

#######################################
#
# Version: 2.0.0
# Date: 2024-12-08
# Author: Kenan Pelit
# Repository: github.com/kenanpelit/dotfiles
# Description: HyprFlow
#
# License: MIT
#
#######################################
#
# Hyprland Startup Manager
#
# Description: Manages startup applications for Hyprland
# Author: Kenan
# License: MIT
#
# # Yeni uygulama eklemek için
#./startup-manager.sh add "Firefox" 2 browser "firefox-profile" "🦊" yes no 5

## Uygulama kaldırmak için
#./startup-manager.sh remove "Firefox"

## Listelemek için
#./startup-manager.sh list

## Düzenlemek için (vim ile)
#./startup-manager.sh edit

## Tüm uygulamaları başlatmak için
#./startup-manager.sh start

set -euo pipefail
IFS=$'\n\t'

# Configuration and Directory Setup
readonly BASE_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
readonly CONFIG_DIR="$BASE_DIR/hypr/startup"
readonly SCRIPTS_DIR="$BASE_DIR/hypr/scripts"
readonly LOG_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/hypr/logs"
readonly CONFIG_FILE="$CONFIG_DIR/apps.conf"
readonly FUNCTIONS_FILE="$SCRIPTS_DIR/startup-functions.sh"

# Default Configuration Values
declare -A CONFIG=(
  [WORKSPACE_SWITCH_DELAY]=2
  [DEFAULT_LAUNCH_DELAY]=5
  [CPU_HIGH_FREQ]=4000
  [CPU_LOW_FREQ]=2000
  [NOTIFICATION_TIMEOUT]=5000
)

# Ensure required directories exist
mkdir -p "$CONFIG_DIR" "$LOG_DIR"

# Setup logging
readonly LOG_FILE="$LOG_DIR/startup-$(date +%Y%m%d-%H%M%S).log"
exec 1> >(tee -a "$LOG_FILE")
exec 2> >(tee -a "$LOG_FILE" >&2)

# Helper Functions
log() {
  local level="$1"
  shift
  echo "[$(date +'%Y-%m-%d %H:%M:%S')] [$level] $*" >&2
}

die() {
  log "ERROR" "$*"
  exit 1
}

confirm() {
  local prompt="$1"
  local response
  read -r -p "$prompt (y/N) " response
  [[ "$response" =~ ^[Yy]$ ]]
}

# Configuration File Management
create_default_config() {
  cat >"$CONFIG_FILE" <<EOF
# Hyprland Startup Configuration
# Auto-generated on $(date)

# System Settings
WORKSPACE_SWITCH_DELAY=${CONFIG[WORKSPACE_SWITCH_DELAY]}
DEFAULT_LAUNCH_DELAY=${CONFIG[DEFAULT_LAUNCH_DELAY]}
CPU_HIGH_FREQ=${CONFIG[CPU_HIGH_FREQ]}
CPU_LOW_FREQ=${CONFIG[CPU_LOW_FREQ]}
NOTIFICATION_TIMEOUT=${CONFIG[NOTIFICATION_TIMEOUT]}

# Application Definitions
# Format: name|workspace|type|profile_or_script|icon|fullscreen|togglegroup|delay
APPS=(
)
EOF
  chmod 600 "$CONFIG_FILE"
  log "INFO" "Created default configuration at $CONFIG_FILE"
}

# Config management functions
list_apps() {
  if [[ ! -f "$CONFIG_FILE" ]]; then
    log "ERROR" "No configuration file found at $CONFIG_FILE"
    return 1
  fi

  echo
  echo "Current Applications Configuration:"
  echo "--------------------------------"
  printf "%-20s %-5s %-10s %-20s %-6s %-6s %-6s %-6s\n" \
    "NAME" "WS" "TYPE" "PROFILE/SCRIPT" "ICON" "FULL" "GROUP" "DELAY"
  echo "--------------------------------"

  # Load config file
  source "$CONFIG_FILE"

  # Check if APPS array exists and has items
  if [[ -z "${APPS[*]:-}" ]]; then
    echo "No applications configured."
    return 0
  fi

  # Loop through applications
  for app in "${APPS[@]}"; do
    # Remove quotes and extra spaces
    app="${app#\"}"
    app="${app%\"}"

    # Split the app string into fields
    IFS='|' read -r name ws type profile icon full group delay <<<"$app"

    # Print formatted output
    printf "%-20s %-5s %-10s %-20s %-6s %-6s %-6s %-6s\n" \
      "$name" "$ws" "$type" "$profile" "$icon" "$full" "$group" "$delay"
  done
  echo
}

# Application launcher
launch_application() {
  local name="$1"
  local workspace="$2"
  local type="$3"
  local profile_or_script="$4"
  local icon="${5:-}"
  local fullscreen="${6:-no}"
  local togglegroup="${7:-no}"
  local delay="${8:-$DEFAULT_LAUNCH_DELAY}"

  log "INFO" "Launching $name on workspace $workspace"

  hyprctl dispatch workspace "$workspace"
  sleep "$WORKSPACE_SWITCH_DELAY"

  notify-send -t "$NOTIFICATION_TIMEOUT" -a "$name" "$icon $name - $workspace ..."

  case "$type" in
  browser)
    # Check if browser command exists
    if ! command -v "$BROWSER_CMD" >/dev/null 2>&1; then
      log "ERROR" "Browser command not found: $BROWSER_CMD"
      return 1
    fi

    # Build environment variables string
    local env_vars=""
    for flag in "${BROWSER_FLAGS[@]}"; do
      env_vars+=" $flag"
    done

    # Launch browser with environment variables
    env $env_vars "$BROWSER_CMD" -P "$profile_or_script" &>/dev/null &
    ;;
  script)
    if [[ -x "$SCRIPTS_DIR/$profile_or_script" ]]; then
      "$SCRIPTS_DIR/$profile_or_script" &>/dev/null &
    else
      log "ERROR" "Script not found or not executable: $profile_or_script"
      return 1
    fi
    ;;
  *)
    log "ERROR" "Unknown application type: $type"
    return 1
    ;;
  esac

  disown
  sleep "$delay"

  hyprctl dispatch movetoworkspacesilent "$workspace"

  if [[ "$fullscreen" == "yes" ]]; then
    sleep 0.5
    hyprctl dispatch fullscreen 0
  fi

  if [[ "$togglegroup" == "yes" ]]; then
    sleep 0.5
    hyprctl dispatch togglegroup
  fi
}

# Validate configuration
validate_config() {
  if [[ ! -f "$CONFIG_FILE" ]]; then
    return 1
  fi

  # Basic syntax check
  if ! bash -n "$CONFIG_FILE"; then
    log "ERROR" "Configuration file contains syntax errors"
    return 1
  fi

  # Source the config file to test it
  if ! source "$CONFIG_FILE" 2>/dev/null; then
    log "ERROR" "Failed to source configuration file"
    return 1
  fi

  # Check required variables
  local required_vars=(
    "WORKSPACE_SWITCH_DELAY"
    "DEFAULT_LAUNCH_DELAY"
    "CPU_HIGH_FREQ"
    "CPU_LOW_FREQ"
    "NOTIFICATION_TIMEOUT"
    "BROWSER_CMD"
    "BROWSER_FLAGS"
    "APPS"
  )

  for var in "${required_vars[@]}"; do
    if [[ -z "${!var+x}" ]]; then
      log "ERROR" "Required variable $var is not set in config"
      return 1
    fi
  done

  # Validate browser command
  if ! command -v "$BROWSER_CMD" >/dev/null 2>&1; then
    log "ERROR" "Browser command not found: $BROWSER_CMD"
    return 1
  fi

  return 0
}

add_app() {
  if [[ $# -lt 4 ]]; then
    die "Usage: $0 add NAME WORKSPACE TYPE PROFILE [ICON] [FULLSCREEN] [TOGGLEGROUP] [DELAY]"
  fi

  local name="$1"
  local workspace="$2"
  local type="$3"
  local profile="$4"
  local icon="${5:-}"
  local fullscreen="${6:-no}"
  local togglegroup="${7:-no}"
  local delay="${8:-${CONFIG[DEFAULT_LAUNCH_DELAY]}}"

  # Validate inputs
  [[ "$workspace" =~ ^[0-9]+$ ]] || die "Workspace must be a number"
  [[ "$type" =~ ^(browser|script)$ ]] || die "Type must be either 'browser' or 'script'"
  [[ "$fullscreen" =~ ^(yes|no)$ ]] || die "Fullscreen must be either 'yes' or 'no'"
  [[ "$togglegroup" =~ ^(yes|no)$ ]] || die "Togglegroup must be either 'yes' or 'no'"
  [[ "$delay" =~ ^[0-9]+$ ]] || die "Delay must be a number"

  # Create config if it doesn't exist
  [[ -f "$CONFIG_FILE" ]] || create_default_config

  # Load current config
  source "$CONFIG_FILE"

  # Check for existing app
  local app_exists=0
  for ((i = 0; i < ${#APPS[@]}; i++)); do
    if [[ "${APPS[i]}" == *"\"$name|"* ]]; then
      app_exists=1
      if confirm "Application '$name' already exists. Update it?"; then
        APPS[i]="\"$name|$workspace|$type|$profile|$icon|$fullscreen|$togglegroup|$delay\""
        log "INFO" "Updated existing application: $name"
      else
        log "INFO" "Operation cancelled"
        return 0
      fi
      break
    fi
  done

  # Add new app if it doesn't exist
  if [[ $app_exists -eq 0 ]]; then
    APPS+=("\"$name|$workspace|$type|$profile|$icon|$fullscreen|$togglegroup|$delay\"")
    log "INFO" "Added new application: $name"
  fi

  # Write updated config
  local temp_file
  temp_file=$(mktemp)

  {
    echo "# Hyprland Startup Configuration"
    echo "# Updated on $(date)"
    echo
    echo "# System Settings"
    echo "WORKSPACE_SWITCH_DELAY=$WORKSPACE_SWITCH_DELAY"
    echo "DEFAULT_LAUNCH_DELAY=$DEFAULT_LAUNCH_DELAY"
    echo "CPU_HIGH_FREQ=$CPU_HIGH_FREQ"
    echo "CPU_LOW_FREQ=$CPU_LOW_FREQ"
    echo "NOTIFICATION_TIMEOUT=$NOTIFICATION_TIMEOUT"
    echo
    echo "# Application Definitions"
    echo "# Format: name|workspace|type|profile_or_script|icon|fullscreen|togglegroup|delay"
    echo "APPS=("
    printf '%s\n' "${APPS[@]}" | sed 's/^/    /'
    echo ")"
  } >"$temp_file"

  mv "$temp_file" "$CONFIG_FILE"
  chmod 600 "$CONFIG_FILE"

  echo "Configuration updated successfully"
  list_apps
}

remove_app() {
  if [[ $# -lt 1 ]]; then
    die "Usage: $0 remove APP_NAME"
  fi

  local name="$1"
  local found=0

  # Load current config
  source "$CONFIG_FILE"

  # Create new array without the specified app
  local new_apps=()
  for app in "${APPS[@]}"; do
    if [[ "$app" == *"\"$name|"* ]]; then
      found=1
      continue
    fi
    new_apps+=("$app")
  done

  if [[ $found -eq 0 ]]; then
    die "Application '$name' not found in configuration"
  fi

  APPS=("${new_apps[@]}")

  # Write updated config
  local temp_file
  temp_file=$(mktemp)

  {
    echo "# Hyprland Startup Configuration"
    echo "# Updated on $(date)"
    echo
    echo "# System Settings"
    echo "WORKSPACE_SWITCH_DELAY=$WORKSPACE_SWITCH_DELAY"
    echo "DEFAULT_LAUNCH_DELAY=$DEFAULT_LAUNCH_DELAY"
    echo "CPU_HIGH_FREQ=$CPU_HIGH_FREQ"
    echo "CPU_LOW_FREQ=$CPU_LOW_FREQ"
    echo "NOTIFICATION_TIMEOUT=$NOTIFICATION_TIMEOUT"
    echo
    echo "# Application Definitions"
    echo "# Format: name|workspace|type|profile_or_script|icon|fullscreen|togglegroup|delay"
    echo "APPS=("
    printf '%s\n' "${APPS[@]}" | sed 's/^/    /'
    echo ")"
  } >"$temp_file"

  mv "$temp_file" "$CONFIG_FILE"
  chmod 600 "$CONFIG_FILE"

  echo "Successfully removed $name from configuration"
  list_apps
}

edit_config() {
  if [[ ! -f "$CONFIG_FILE" ]]; then
    create_default_config
  fi

  ${EDITOR:-vim} "$CONFIG_FILE"

  if ! validate_config; then
    die "Configuration file is invalid after editing"
  fi

  list_apps
}

show_help() {
  cat <<EOF
Hyprland Startup Manager

Usage: $(basename "$0") [OPTIONS] COMMAND

Commands:
    start               Start all configured applications
    list               List all configured applications
    add NAME WS TYPE PROFILE [ICON] [FULL] [GROUP] [DELAY]
                       Add or update an application
    remove NAME        Remove an application
    edit               Edit configuration file directly

Options:
    -h, --help         Show this help message
    -v, --verbose      Enable verbose output
    -d, --dry-run      Show what would be done without doing it

Examples:
    $(basename "$0") add "Firefox" 2 browser "firefox-profile" "🦊" yes no 5
    $(basename "$0") remove "Firefox"
    $(basename "$0") list
    $(basename "$0") edit

Configuration file: $CONFIG_FILE
EOF
}

main() {
  # Parse command line options
  local verbose=0
  local dry_run=0

  while [[ $# -gt 0 ]]; do
    case "$1" in
    -h | --help)
      show_help
      exit 0
      ;;
    -v | --verbose)
      verbose=1
      shift
      ;;
    -d | --dry-run)
      dry_run=1
      shift
      ;;
    start | list | add | remove | edit)
      break
      ;;
    *)
      die "Unknown option: $1"
      ;;
    esac
  done

  [[ $# -eq 0 ]] && {
    show_help
    exit 1
  }

  # Process commands
  case "$1" in
  start)
    if [[ $dry_run -eq 1 ]]; then
      echo "Would start applications..."
      exit 0
    fi
    if [[ ! -f "$FUNCTIONS_FILE" ]]; then
      die "Required file not found: $FUNCTIONS_FILE"
    fi
    # shellcheck source=startup-functions.sh
    source "$FUNCTIONS_FILE"
    start_applications
    ;;
  list)
    list_apps
    ;;
  add)
    shift
    add_app "$@"
    ;;
  remove)
    shift
    remove_app "$@"
    ;;
  edit)
    edit_config
    ;;
  *)
    die "Unknown command: $1"
    ;;
  esac
}

# Script execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
