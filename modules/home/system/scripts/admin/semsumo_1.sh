#!/usr/bin/env bash

#######################################
#
# Version: 2.1.1
# Date: 2025-04-08
# Author: Kenan Pelit
# Repository: github.com/kenanpelit/dotfiles
# Description: Session Manager (semsumo) - Terminal and Application Session Manager
#
# This script is designed to manage application sessions in Unix/Linux systems.
# Main features:
# - Simplified VPN (Mullvad) integration (secure/bypass)
# - JSON-based configuration system
# - Session start/stop/restart
# - CPU and memory usage monitoring
# - Metrics collection in JSON format
# - Secure file permissions and error handling
# - Session script generator (--create parameter)
#
# Config: ~/.config/sem/config.json
# Logs: ~/.config/sem/logs/sem.log
# PID: /tmp/sem/
#
# License: MIT
#
#######################################

# shellcheck disable=SC2034
# shellcheck disable=SC2154

# Strict mode configuration
set -Eeuo pipefail
IFS=$'\n\t'

# Version
readonly VERSION="2.1.1"

# Core configuration
readonly SCRIPT_PATH="${XDG_CONFIG_HOME:-$HOME/.config}/sem"
readonly CONFIG_FILE="$SCRIPT_PATH/config.json"
readonly LOG_FILE="$SCRIPT_PATH/logs/sem.log"
readonly CONFIG_SCHEMA="$SCRIPT_PATH/schema.json"
readonly BACKUP_DIR="$SCRIPT_PATH/backups"
readonly PID_DIR="/tmp/sem"
readonly METRICS_FILE="/tmp/sem_metrics.json"

# Default values
readonly DEFAULT_COMMAND_TIMEOUT=30
readonly DEFAULT_MAX_RETRIES=3
readonly DEFAULT_RETRY_DELAY=1
readonly DEFAULT_MONITOR_INTERVAL=5

# Script generator configuration
readonly SCRIPTS_DIR="$HOME/.nixosc/modules/home/system/scripts/start"
readonly SEMSUMO="semsumo"
readonly TMP_DIR="/tmp/sem"

# Color definitions
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly MAGENTA='\033[0;35m'
readonly NC='\033[0m'

# Global variables
declare -a TEMP_FILES=()
declare -A ACTIVE_MONITORS=()

# Initialize environment
initialize() {
	mkdir -p "$SCRIPT_PATH"/{logs,backups} "$PID_DIR"
	touch "$LOG_FILE" "$METRICS_FILE"
	chmod 700 "$SCRIPT_PATH"
	chmod 600 "$CONFIG_FILE" "$LOG_FILE" 2>/dev/null || true

	if [[ ! -s "$METRICS_FILE" ]]; then
		echo '{"sessions":{}}' >"$METRICS_FILE"
	fi
}

# Cleanup handler
cleanup() {
	local exit_code=$?
	for pid in "${ACTIVE_MONITORS[@]}"; do
		kill "$pid" 2>/dev/null || true
	done
	rm -f "${TEMP_FILES[@]}" 2>/dev/null || true
	exit "$exit_code"
}

# Error handler
error_handler() {
	local exit_code=$1
	local line_no=$2
	local bash_lineno=$3
	local last_command=$4
	local func_trace=$5

	log_error "Error on line $line_no: Command '$last_command' exited with status $exit_code"
	log_error "Function trace: $func_trace"
}

# Set up traps
trap cleanup EXIT
trap 'error_handler $? $LINENO $BASH_LINENO "$BASH_COMMAND" $(printf "::%s" ${FUNCNAME[@]:-})' ERR

# Logging functions
log_info() {
	echo -e "${GREEN}[INFO]${NC} $1" >&2
	echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] $1" >>"$LOG_FILE"
}

log_warn() {
	echo -e "${YELLOW}[WARN]${NC} $1" >&2
	echo "[$(date '+%Y-%m-%d %H:%M:%S')] [WARN] $1" >>"$LOG_FILE"
}

log_error() {
	echo -e "${RED}[ERROR]${NC} $1" >&2
	echo "[$(date '+%Y-%m-%d %H:%M:%S')] [ERROR] $1" >>"$LOG_FILE"
}

log_success() {
	echo -e "${GREEN}✓${NC} $1"
	echo "[$(date '+%Y-%m-%d %H:%M:%S')] [SUCCESS] $1" >>"$LOG_FILE"
}

log_verbose() {
	if [[ ${VERBOSE:-0} -eq 1 ]]; then
		echo -e "${CYAN}[VERBOSE]${NC} $1" >&2
		echo "[$(date '+%Y-%m-%d %H:%M:%S')] [VERBOSE] $1" >>"$LOG_FILE"
	fi
}

# Config validation
validate_config() {
	if ! command -v ajv &>/dev/null; then
		log_error "ajv command not found. Install with: npm install -g ajv-cli"
		return 1
	fi

	if ! ajv validate -s "$CONFIG_SCHEMA" -d "$CONFIG_FILE"; then
		log_error "Config file failed schema validation"
		return 1
	fi
}

# VPN functions
check_vpn() {
	local status_output
	if ! command -v mullvad &>/dev/null; then
		log_warn "Mullvad VPN client not found - assuming no VPN connection"
		echo "false"
		return 0
	fi

	status_output=$(mullvad status 2>/dev/null || echo "Not connected")

	if echo "$status_output" | grep -q "Connected"; then
		local vpn_details
		vpn_details=$(echo "$status_output" | grep "Relay:" | awk -F': ' '{print $2}')
		log_info "VPN active: $vpn_details"
		echo "true"
		return 0
	fi

	log_info "No VPN connection"
	echo "false"
	return 0
}

get_vpn_mode() {
	local session_name=$1
	local cli_mode=${2:-}

	case "$cli_mode" in
	bypass | secure)
		echo "$cli_mode"
		;;
	"")
		if [[ -f "$CONFIG_FILE" ]]; then
			jq -r ".sessions.\"$session_name\".vpn // \"secure\"" "$CONFIG_FILE"
		else
			echo "secure"
		fi
		;;
	*)
		log_error "Invalid VPN mode: $cli_mode. Use 'secure' or 'bypass'"
		return 1
		;;
	esac
}

# Session management
execute_application() {
	local cmd=$1
	shift
	local -a args=("$@")

	nohup "$cmd" "${args[@]}" >/dev/null 2>&1 &
	echo $!
}

start_session() {
	local session_name=$1
	local vpn_param=${2:-}
	local start_time
	start_time=$(date +%s)

	if [[ ! -f "$CONFIG_FILE" ]]; then
		log_error "Config file not found: $CONFIG_FILE"
		return 1
	fi

	local command
	command=$(jq -r ".sessions.\"${session_name}\".command" "$CONFIG_FILE")
	if [[ "$command" == "null" ]]; then
		log_error "Session not found: $session_name"
		return 1
	fi

	readarray -t args < <(jq -r ".sessions.\"${session_name}\".args[]" "$CONFIG_FILE")

	local vpn_mode
	vpn_mode=$(get_vpn_mode "$session_name" "$vpn_param")
	local vpn_status
	vpn_status=$(check_vpn)
	local pid

	case "$vpn_mode" in
	secure)
		if [[ "$vpn_status" != "true" ]]; then
			log_warn "No VPN connection found. Starting application normally: $session_name"
			if command -v notify-send &>/dev/null; then
				notify-send "Session Manager" "No VPN connection found. Starting $session_name session without VPN."
			fi
			pid=$(execute_application "$command" "${args[@]}")
		else
			pid=$(execute_application "$command" "${args[@]}")
		fi
		;;
	bypass)
		if [[ "$vpn_status" == "true" ]]; then
			if command -v mullvad-exclude &>/dev/null; then
				pid=$(mullvad-exclude "$command" "${args[@]}")
			else
				log_warn "mullvad-exclude not found - running normally"
				pid=$(execute_application "$command" "${args[@]}")
			fi
		else
			pid=$(execute_application "$command" "${args[@]}")
		fi
		;;
	esac

	local pid_file="$PID_DIR/${session_name}.pid"
	echo "$pid" >"$pid_file"

	monitor_resources "$session_name" "$pid" &
	ACTIVE_MONITORS["$session_name"]=$!

	update_metrics "$session_name" "$start_time" "$(date +%s)" "started"
	log_info "Session started: $session_name (PID: $pid)"
}

stop_session() {
	local session_name=$1
	local pid_file="$PID_DIR/${session_name}.pid"

	if [[ -f "$pid_file" ]]; then
		local pid
		pid=$(<"$pid_file")
		if kill "$pid" 2>/dev/null; then
			rm -f "$pid_file"
			if [[ -n "${ACTIVE_MONITORS[$session_name]:-}" ]]; then
				kill "${ACTIVE_MONITORS[$session_name]}" 2>/dev/null || true
				unset "ACTIVE_MONITORS[$session_name]"
			fi
			log_info "Session stopped: $session_name"
			update_metrics "$session_name" "$(date +%s)" "$(date +%s)" "stopped"
			return 0
		fi
	fi
	log_error "No running session found: $session_name"
	return 1
}

# Session management functions
add_session() {
	if [[ ! -f "$CONFIG_FILE" ]]; then
		# First time config creation
		echo '{"sessions":{}}' >"$CONFIG_FILE"
	fi

	if ! echo "$1" | jq . >/dev/null 2>&1; then
		log_error "Invalid JSON data"
		return 1
	fi

	local temp_file
	temp_file=$(mktemp)
	TEMP_FILES+=("$temp_file")

	if jq --argjson new "$1" '.sessions += $new' "$CONFIG_FILE" >"$temp_file" &&
		mv "$temp_file" "$CONFIG_FILE"; then
		log_info "Session added successfully"
	else
		log_error "Error adding session"
		return 1
	fi
}

remove_session() {
	if [[ ! -f "$CONFIG_FILE" ]]; then
		log_error "Config file not found"
		return 1
	fi

	local temp_file
	temp_file=$(mktemp)
	TEMP_FILES+=("$temp_file")

	if jq --arg name "$1" 'del(.sessions[$name])' "$CONFIG_FILE" >"$temp_file" &&
		mv "$temp_file" "$CONFIG_FILE"; then
		log_info "Session successfully removed: $1"
	else
		log_error "Error removing session"
		return 1
	fi
}

list_sessions() {
	if [[ ! -f "$CONFIG_FILE" ]]; then
		log_error "Config file not found"
		return 1
	fi

	printf "${BLUE}%s${NC}\n" "Available Sessions:"

	jq -r '.sessions | to_entries[] | {
        key: .key,
        command: .value.command,
        vpn: (.value.vpn // "secure"),
        args: (.value.args|join(" "))
    } | "\(.key):\n  Command: \(.command)\n  VPN Mode: \(.vpn)\n  Arguments: \(.args)"' "$CONFIG_FILE" |
		while IFS= read -r line; do
			if [[ $line =~ :$ ]]; then
				session=${line%:}
				status=$(check_status "$session")
				echo -e "${GREEN}${line}${NC}"
			elif [[ $line =~ ^[[:space:]]*VPN[[:space:]]Mode:[[:space:]]*(.*) ]]; then
				mode=${BASH_REMATCH[1]}
				case "$mode" in
				secure) printf "  VPN Mode: ${RED}%s${NC}\n" "$mode" ;;
				bypass) printf "  VPN Mode: ${GREEN}%s${NC}\n" "$mode" ;;
				*) printf "  VPN Mode: ${YELLOW}%s${NC}\n" "$mode" ;;
				esac
			else
				echo "$line"
			fi
		done
}

# Resource monitoring
monitor_resources() {
	local session_name=$1
	local pid=$2
	local interval=${3:-$DEFAULT_MONITOR_INTERVAL}

	while kill -0 "$pid" 2>/dev/null; do
		local cpu mem
		cpu=$(ps -p "$pid" -o %cpu= 2>/dev/null || echo "0")
		mem=$(ps -p "$pid" -o %mem= 2>/dev/null || echo "0")

		update_metrics "$session_name" "$(date +%s)" "$(date +%s)" "running" "{\"cpu\":$cpu,\"mem\":$mem}"
		sleep "$interval"
	done
}

# Metrics management
update_metrics() {
	local session_name=$1
	local start_time=$2
	local end_time=$3
	local status=$4
	local resources=${5:-"{}"}

	local duration=$((end_time - start_time))
	local temp_file
	temp_file=$(mktemp)
	TEMP_FILES+=("$temp_file")

	jq --arg session "$session_name" \
		--arg timestamp "$(date -Iseconds)" \
		--arg duration "$duration" \
		--arg status "$status" \
		--argjson resources "$resources" \
		'.sessions[$session].runs += [{
            timestamp: $timestamp,
            duration: $duration | tonumber,
            status: $status,
            resources: $resources
        }]' "$METRICS_FILE" >"$temp_file" && mv "$temp_file" "$METRICS_FILE"
}

# Utility functions
check_status() {
	local session_name=$1
	local pid_file="$PID_DIR/${session_name}.pid"

	if [[ -f "$pid_file" ]] && kill -0 "$(<"$pid_file")" 2>/dev/null; then
		echo "running"
	else
		echo "stopped"
	fi
}

backup_config() {
	local timestamp
	timestamp=$(date +%Y%m%d_%H%M%S)
	local backup_file="$BACKUP_DIR/sem_config_$timestamp.json"

	if cp "$CONFIG_FILE" "$backup_file"; then
		log_info "Config backed up: $backup_file"
		return 0
	else
		log_error "Error backing up config"
		return 1
	fi
}

show_version() {
	echo "semsumo version $VERSION"
}

#===============================================================================
# Session Script Generator Functions (--create parameter)
#===============================================================================

check_script_generator_dependencies() {
	local missing_deps=0

	# Check for required commands
	for cmd in jq "$SEMSUMO" mkdir chmod; do
		if ! command -v "$cmd" >/dev/null 2>&1; then
			log_error "Required command not found: $cmd"
			missing_deps=1
		else
			log_verbose "Found required command: $cmd"
		fi
	done

	if [[ $missing_deps -eq 1 ]]; then
		log_error "Please install missing dependencies and try again."
		return 1
	fi

	return 0
}

validate_script_generator_config() {
	if [[ ! -f "$CONFIG_FILE" ]]; then
		log_error "Configuration file not found at: $CONFIG_FILE"
		return 1
	fi

	# Check if config is valid JSON
	if ! jq empty "$CONFIG_FILE" 2>/dev/null; then
		log_error "Configuration file is not valid JSON: $CONFIG_FILE"
		return 1
	fi

	# Check if config contains sessions field
	if ! jq -e '.sessions' "$CONFIG_FILE" >/dev/null 2>&1; then
		log_error "Configuration file must contain a 'sessions' field"
		return 1
	fi

	# Check if there are any profiles defined
	local profile_count
	profile_count=$(jq '.sessions | keys | length' "$CONFIG_FILE")

	if [[ $profile_count -eq 0 ]]; then
		log_warn "No profiles found in configuration file"
		return 1
	else
		log_info "Found $profile_count profile(s) in configuration file"
		return 0
	fi
}

create_script() {
	local profile=$1
	local vpn_mode=$2
	local script_path="$SCRIPTS_DIR/start-${profile,,}.sh"

	log_verbose "Creating script: $script_path for profile $profile with VPN mode: $vpn_mode"

	# Create script content with improved comments and structure
	cat >"$script_path" <<EOF
#!/usr/bin/env bash
#===============================================================================
# Generated script for $profile
# Generated on: $(date '+%Y-%m-%d %H:%M:%S')
# VPN Mode: $vpn_mode
# Do not edit manually - this file is automatically generated
#===============================================================================

# Error handling
set -euo pipefail

# Environment setup
export TMPDIR="$TMP_DIR"

# Start session with Semsumo
$SEMSUMO start "$profile" "$vpn_mode"

# Exit successfully
exit 0
EOF

	# Make script executable and set proper permissions
	chmod 755 "$script_path"
	log_success "Created: start-${profile,,}.sh"
}

process_profiles() {
	local profiles
	local total_profiles
	local current=0

	# Get all profile names from config in one call
	profiles=$(jq -r '.sessions | keys[]' "$CONFIG_FILE")
	total_profiles=$(echo "$profiles" | wc -l)

	echo "----------------------------------------"
	log_info "Starting script generation for $total_profiles profile(s)..."

	# Process each profile and generate scripts based on VPN mode
	while IFS= read -r profile; do
		current=$((current + 1))

		# Skip empty profiles (shouldn't happen with proper JSON)
		if [[ -z "$profile" ]]; then
			continue
		fi

		# Show progress
		log_info "[$current/$total_profiles] Processing profile: $profile"

		# Validate profile name (avoid directory traversal)
		if [[ "$profile" =~ [\/\\] ]]; then
			log_error "Invalid profile name (contains path characters): $profile"
			continue
		fi

		# Get VPN mode from config - convert old vpn_mode if needed
		local vpn_mode

		# First try the new 'vpn' field
		vpn_mode=$(jq -r ".sessions.\"$profile\".vpn // \"\"" "$CONFIG_FILE")

		# If empty, try legacy vpn_mode and convert
		if [[ -z "$vpn_mode" ]]; then
			local legacy_mode
			legacy_mode=$(jq -r ".sessions.\"$profile\".vpn_mode // \"default\"" "$CONFIG_FILE")

			case "$legacy_mode" in
			"never")
				vpn_mode="bypass"
				;;
			"always")
				vpn_mode="secure"
				;;
			*)
				vpn_mode="secure" # Default to secure if not specified or invalid
				;;
			esac

			log_verbose "Converting legacy vpn_mode '$legacy_mode' to '$vpn_mode' for profile $profile"
		fi

		# Generate script with the correct VPN mode
		create_script "$profile" "$vpn_mode"

		echo ""
	done <<<"$profiles"

	echo "----------------------------------------"
	log_success "Script generation complete! Generated $total_profiles scripts."
}

run_script_generator() {
	local alternative_config=${1:-""}
	local alternative_output=${2:-""}

	# Set alternative config if provided
	if [[ -n "$alternative_config" ]]; then
		CONFIG_FILE="$alternative_config"
	fi

	# Set alternative output directory if provided
	if [[ -n "$alternative_output" ]]; then
		SCRIPTS_DIR="$alternative_output"
	fi

	# Check dependencies
	if ! check_script_generator_dependencies; then
		return 1
	fi

	# Validate configuration file
	if ! validate_script_generator_config; then
		return 1
	fi

	# Create necessary directories with proper permissions
	mkdir -p "$SCRIPTS_DIR"
	if [[ ! -d "$TMP_DIR" ]]; then
		mkdir -p "$TMP_DIR"
		chmod 700 "$TMP_DIR"
		log_verbose "Created temporary directory: $TMP_DIR"
	fi

	# Process profiles and generate scripts
	process_profiles

	# Show usage examples
	echo ""
	log_info "Usage examples:"

	# Get first profile for example
	local example_profile
	example_profile=$(jq -r '.sessions | keys[0] // "example"' "$CONFIG_FILE")
	example_profile=${example_profile,,}

	echo "  $SCRIPTS_DIR/start-$example_profile.sh"

	return 0
}

show_create_help() {
	cat <<EOF
Script Generator for Semsumo Profiles

Usage: semsumo --create [OPTIONS]

Generate session management scripts for Semsumo profiles.

Options:
  -h, --help     Show this help message and exit
  -v, --verbose  Enable verbose output
  -c, --config   Specify an alternative config file location
  -o, --output   Specify an alternative output directory

Example:
  semsumo --create --verbose
  semsumo --create --config ~/custom-config.json --output ~/scripts

EOF
}

show_help() {
	cat <<EOF
Session Manager $VERSION - Terminal and Application Session Manager

Usage: 
  semsumo <command> [parameters]

Commands:
  start   <session> [vpn_mode]  Start session
  stop    <session>             Stop session
  restart <session> [vpn_mode]  Restart session
  status  <session>             Show session status
  list                          List available sessions
  add     <json_data>           Add new session configuration
  remove  <session>             Remove session configuration
  backup                        Backup config
  validate                      Validate config  
  version                       Show version information
  help                          Show this help message
  --create [options]            Generate session management scripts
  
VPN Modes:
  bypass  : Run outside VPN (bypass VPN)
  secure  : Run securely through VPN

Example Usage:
  # Session start examples
  semsumo start secure-browser         # Use configuration VPN mode
  semsumo start local-browser bypass   # Run outside VPN
  semsumo restart zen-browser secure   # Restart inside VPN

  # Session management
  semsumo list                         # List all sessions
  semsumo status local-browser         # Check session status
  semsumo stop secure-browser          # Stop session

  # Script generation
  semsumo --create                     # Generate session scripts
  semsumo --create --verbose           # Generate with detailed output

  # Configuration examples
  semsumo add '{
    "secure-browser": {
      "command": "/usr/bin/firefox",
      "args": ["-P", "Secure", "--class", "Firefox-Secure"],
      "vpn": "secure"
    }
  }'

  semsumo add '{
    "local-terminal": {
      "command": "/usr/bin/alacritty",
      "args": ["--class", "Terminal", "-T", "Local"],
      "vpn": "bypass"
    }
  }'

  semsumo remove old-profile           # Remove profile
  semsumo backup                       # Backup configuration

Note: If VPN mode is defined in the configuration file and not specified 
on the command line, the mode from the configuration is used. If neither 
is specified, "secure" mode is used by default.
EOF
}

# Main program
main() {
	initialize

	# Handle script generator (--create parameter)
	if [[ "${1:-}" == "--create" ]]; then
		shift
		VERBOSE=0
		CONFIG_OVERRIDE=""
		OUTPUT_OVERRIDE=""

		# Parse create-specific arguments
		while [[ $# -gt 0 ]]; do
			case $1 in
			-h | --help)
				show_create_help
				exit 0
				;;
			-v | --verbose)
				VERBOSE=1
				shift
				;;
			-c | --config)
				CONFIG_OVERRIDE="$2"
				shift 2
				;;
			-o | --output)
				OUTPUT_OVERRIDE="$2"
				shift 2
				;;
			*)
				log_error "Unknown option for create: $1"
				show_create_help
				exit 1
				;;
			esac
		done

		# Run script generator with parsed options
		run_script_generator "$CONFIG_OVERRIDE" "$OUTPUT_OVERRIDE"
		exit $?
	fi

	# Handle regular commands
	case "${1:-}" in
	start)
		if [[ -z "${2:-}" ]]; then
			show_help
			exit 1
		fi
		start_session "$2" "${3:-}"
		;;
	stop)
		if [[ -z "${2:-}" ]]; then
			show_help
			exit 1
		fi
		stop_session "$2"
		;;
	restart)
		if [[ -z "${2:-}" ]]; then
			show_help
			exit 1
		fi
		stop_session "$2" && start_session "$2" "${3:-}"
		;;
	status)
		if [[ -z "${2:-}" ]]; then
			show_help
			exit 1
		fi
		check_status "$2"
		;;
	list)
		list_sessions
		;;
	add)
		if [[ -z "${2:-}" ]]; then
			show_help
			exit 1
		fi
		add_session "$2"
		;;
	remove)
		if [[ -z "${2:-}" ]]; then
			show_help
			exit 1
		fi
		remove_session "$2"
		;;
	backup)
		backup_config
		;;
	validate)
		validate_config
		;;
	version)
		show_version
		;;
	help | --help | -h)
		show_help
		;;
	*)
		show_help
		exit 1
		;;
	esac
}

main "$@"
