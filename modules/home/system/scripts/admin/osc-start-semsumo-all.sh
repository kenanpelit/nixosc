#!/usr/bin/env bash
#===============================================================================
#
#   Script: OSC Hybrid Workspace Launcher
#   Version: 3.0.0
#   Date: 2025-03-25
#   Author: Kenan Pelit (original), Claude (enhancements)
#   Repository: https://github.com/kenanpelit/nixosc
#   Description: Advanced workspace session launcher with VPN-awareness and hybrid
#                launch strategies for optimal startup performance
#
#   Features:
#   - Smart VPN detection and validation (OpenVPN & Mullvad)
#   - Hybrid launch strategy (parallel & sequential)
#   - Workspace management with Hyprland integration
#   - Advanced logging with rotation
#   - Application grouping and dependencies
#   - CPU frequency management
#   - Configurable launch delays and behaviors
#   - Support for command line arguments and profiles
#   - Better error recovery handling
#
#   License: MIT
#
#===============================================================================

# Strict error handling
set -euo pipefail
IFS=$'\n\t'

# Error trap
trap 'echo -e "${RED}Error occurred. Line: $LINENO, Command: $BASH_COMMAND${NC}"; exit 1' ERR

#===============================================================================
# Configuration Variables
#===============================================================================

# Path configuration
readonly SCRIPTS_DIR="/etc/profiles/per-user/kenan/bin"
readonly LOG_DIR="$HOME/.logs"
readonly LOG_FILE="$LOG_DIR/session-launcher.log"
readonly LOG_MAX_SIZE=1048576 # 1MB
readonly CONFIG_DIR="$HOME/.config/hybrid-launcher"
readonly CONFIG_FILE="$CONFIG_DIR/config.json"
readonly TMP_DIR="/tmp/session-launcher"

# Color definitions for terminal output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[0;33m'
readonly BLUE='\033[0;34m'
readonly MAGENTA='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m' # No Color

# Icons for logs and notifications
readonly ICON_SUCCESS="✅"
readonly ICON_WARNING="⚠️"
readonly ICON_ERROR="❌"
readonly ICON_INFO="ℹ️"
readonly ICON_CLOCK="⏱️"
readonly ICON_CPU="🖥️"
readonly ICON_ROCKET="🚀"
readonly ICON_NETWORK="🌐"

# Default runtime settings
VERBOSE=0
PROFILE="default"
SKIP_VPN_CHECK=0
DRY_RUN=0
CPU_MODE=""
START_MODE="hybrid" # can be: hybrid, sequential, parallel

#===============================================================================
# Application Configuration
#===============================================================================

# Application Groups - grouped by workspace and launch strategy
declare -A APP_GROUPS
APP_GROUPS["core"]="start-kkenp"                                           # Terminal & Dev
APP_GROUPS["browsers"]="start-zen-kenp start-zen-novpn start-zen-compecta" # Main browsers
APP_GROUPS["communication"]="start-webcord start-zen-whats"                # Communication
APP_GROUPS["media"]="start-spotify"                                        # Media

# Application Configuration - workspace:fullscreen:togglegroup:vpn:sleep
declare -A APP_CONFIGS
# Terminal & Dev (Core)
APP_CONFIGS["start-kkenp"]="2:no:no:always:2" # Tmux session
# Browsers
APP_CONFIGS["start-zen-kenp"]="1:no:no:always:2"     # Main browser
APP_CONFIGS["start-zen-novpn"]="3:no:no:always:2"    # No VPN browser
APP_CONFIGS["start-zen-compecta"]="4:no:no:always:2" # Work browser
# Communication
APP_CONFIGS["start-webcord"]="5:no:yes:always:2"   # Webcord
APP_CONFIGS["start-zen-whats"]="9:no:yes:always:2" # WhatsApp
# Media
APP_CONFIGS["start-spotify"]="8:no:no:always:2" # Spotify

#===============================================================================
# Helper Functions
#===============================================================================

# Display help information
show_help() {
	cat <<EOF
Usage: $(basename "$0") [OPTIONS]

OSC Hybrid Workspace Launcher - Smart workspace launcher with Hyprland integration

Options:
  -h, --help            Show this help message
  -v, --verbose         Enable verbose output
  -p, --profile NAME    Load specific profile (default: default)
  -s, --skip-vpn        Skip VPN checks
  -d, --dry-run         Simulate without launching applications
  -l, --list-groups     List available application groups
  -c, --cpu MODE        Set CPU frequency (high/low)
  -g, --group NAME      Launch only specific group
  -m, --mode TYPE       Launch mode (hybrid/sequential/parallel)

Examples:
  $(basename "$0") --profile work     # Start with work profile
  $(basename "$0") --skip-vpn         # Start without VPN checks
  $(basename "$0") --group browsers   # Launch only browsers
  $(basename "$0") --cpu high         # Set CPU to high performance mode
  $(basename "$0") --dry-run          # Simulation mode

EOF
}

# List available application groups
list_groups() {
	echo -e "${BLUE}Available Application Groups:${NC}"
	for group in "${!APP_GROUPS[@]}"; do
		echo -e "${GREEN}$group${NC}: ${APP_GROUPS[$group]}"
	done
}

# Advanced logging function
log() {
	local app=$1
	local message=$2
	local notify=${3:-false}
	local duration=${4:-5000}
	local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
	local log_entry="[$timestamp] [$app] $message"

	# Always write to log file
	echo "$log_entry" >>"$LOG_FILE"

	# Terminal output with colors based on message type
	if [[ $VERBOSE -eq 1 ]]; then
		# Show all messages in verbose mode
		if [[ "$app" == "ERROR" ]]; then
			echo -e "${RED}$log_entry${NC}"
		elif [[ "$app" == "WARNING" ]]; then
			echo -e "${YELLOW}$log_entry${NC}"
		elif [[ "$app" == "GROUP" ]]; then
			echo -e "${MAGENTA}$log_entry${NC}"
		elif [[ "$app" == "TIMING" || "$app" == "Duration" ]]; then
			echo -e "${CYAN}$log_entry${NC}"
		elif [[ "$app" == "VPN" ]]; then
			echo -e "${BLUE}$log_entry${NC}"
		else
			echo -e "${GREEN}$log_entry${NC}"
		fi
	else
		# Only show important messages in normal mode
		if [[ "$app" == "ERROR" ]]; then
			echo -e "${RED}$log_entry${NC}"
		elif [[ "$app" == "WARNING" ]]; then
			echo -e "${YELLOW}$log_entry${NC}"
		elif [[ "$app" == "START" || "$app" == "Duration" ]]; then
			echo -e "${GREEN}$log_entry${NC}"
		fi
	fi

	# Send desktop notification if requested
	if [[ "$notify" == "true" && $DRY_RUN -eq 0 ]]; then
		notify-send -t "$duration" -a "Workspace Launcher" "$app: $message"
	fi
}

# Check if dependency commands are available
check_dependencies() {
	local missing=false

	# Essential commands
	for cmd in hyprctl notify-send bc jq; do
		if ! command -v "$cmd" &>/dev/null; then
			log "ERROR" "Required command not found: $cmd" "true" 7000
			missing=true
		fi
	done

	# Optional commands with fallbacks
	if ! command -v "cpupower" &>/dev/null; then
		log "WARNING" "cpupower not found, CPU frequency management disabled" "false"
	fi

	if $missing; then
		log "ERROR" "Missing dependencies. Please install required packages." "true" 7000
		return 1
	fi

	return 0
}

# Create required directories
setup_directories() {
	# Create log directory if it doesn't exist
	if [[ ! -d "$LOG_DIR" ]]; then
		mkdir -p "$LOG_DIR"
		log "INFO" "Created log directory: $LOG_DIR" "false"
	fi

	# Create config directory if it doesn't exist
	if [[ ! -d "$CONFIG_DIR" ]]; then
		mkdir -p "$CONFIG_DIR"
		log "INFO" "Created config directory: $CONFIG_DIR" "false"
	fi

	# Create temp directory with secure permissions
	if [[ ! -d "$TMP_DIR" ]]; then
		mkdir -p "$TMP_DIR"
		chmod 700 "$TMP_DIR"
		log "INFO" "Created temp directory: $TMP_DIR" "false"
	fi
}

# Log rotation to keep logs manageable
rotate_logs() {
	# Get file size (compatible with both BSD and GNU stat)
	local log_size
	if stat --version &>/dev/null; then
		# GNU stat
		log_size=$(stat --format="%s" "$LOG_FILE" 2>/dev/null || echo "0")
	else
		# BSD stat (macOS)
		log_size=$(stat -f%z "$LOG_FILE" 2>/dev/null || echo "0")
	fi

	# Rotate if file exists and exceeds max size
	if [[ -f "$LOG_FILE" && $log_size -gt $LOG_MAX_SIZE ]]; then
		local backup_file="$LOG_FILE.$(date '+%Y%m%d-%H%M%S').old"
		mv "$LOG_FILE" "$backup_file"
		touch "$LOG_FILE"
		chmod 600 "$LOG_FILE"
		log "INFO" "Log rotated: $backup_file" "false"

		# Clean up old logs (keep latest 5)
		find "$LOG_DIR" -name "session-launcher.log.*.old" -type f | sort -r | tail -n +6 | xargs -r rm
		log "INFO" "Cleaned up old log files" "false"
	fi
}

# Check VPN connection status
check_vpn_status() {
	# Skip check if requested
	if [[ $SKIP_VPN_CHECK -eq 1 ]]; then
		log "VPN" "VPN check skipped (--skip-vpn)" "false"
		return 0
	fi

	local vpn_mode=$1
	local app_name=$2

	# Skip check for 'never' mode
	if [[ "$vpn_mode" == "never" ]]; then
		log "VPN" "$app_name doesn't require VPN" "false"
		return 0
	fi

	# Check for 'always' mode
	if [[ "$vpn_mode" == "always" ]]; then
		# OpenVPN check
		local openvpn_active=false
		if pgrep -x "openvpn" >/dev/null || ip link show tun0 &>/dev/null; then
			openvpn_active=true
		fi

		# Mullvad WireGuard check
		local mullvad_active=false
		if ip link show wg0-mullvad &>/dev/null; then
			mullvad_active=true
		fi

		# Require at least one active VPN
		if ! $openvpn_active && ! $mullvad_active; then
			log "ERROR" "$ICON_ERROR $app_name requires VPN but none is active!" "true" 10000
			return 1
		fi

		# Log which VPNs are active
		local active_vpns=""
		$openvpn_active && active_vpns+="OpenVPN "
		$mullvad_active && active_vpns+="Mullvad "
		log "VPN" "$ICON_NETWORK $app_name has active VPN: ${active_vpns}" "false"
	fi

	return 0
}

# Get detailed VPN status information
get_vpn_details() {
	log "VPN" "Checking VPN connection status" "false"

	local status=""
	local active_count=0

	# OpenVPN check
	if pgrep -x "openvpn" >/dev/null || ip link show tun0 &>/dev/null; then
		status+="${GREEN}● OpenVPN: Active${NC}\n"
		if ip link show tun0 &>/dev/null; then
			local ip=$(ip addr show tun0 2>/dev/null | grep "inet " | awk '{print $2}')
			status+="  └─ IP: $ip\n"
		else
			status+="  └─ Process running (no interface)\n"
		fi
		((active_count++))
	else
		status+="${RED}○ OpenVPN: Inactive${NC}\n"
	fi

	# Mullvad WireGuard check
	if ip link show wg0-mullvad &>/dev/null; then
		status+="${GREEN}● Mullvad: Active${NC}\n"
		local ip=$(ip addr show wg0-mullvad 2>/dev/null | grep "inet " | awk '{print $2}')
		status+="  └─ IP: $ip\n"
		((active_count++))
	else
		status+="${RED}○ Mullvad: Inactive${NC}\n"
	fi

	# Summary
	if [[ $active_count -gt 0 ]]; then
		status="${GREEN}$ICON_NETWORK VPN Status: $active_count active connection(s)${NC}\n$status"
	else
		status="${RED}$ICON_NETWORK VPN Status: No active connections${NC}\n$status"
	fi

	echo -e "$status"
	log "VPN" "VPN status check completed" "false"
}

# Set CPU frequency for performance or power saving
set_cpu_frequency() {
	local mode=$1

	# Skip in dry run mode
	if [[ $DRY_RUN -eq 1 ]]; then
		log "CPU" "$ICON_CPU Simulating CPU frequency change to: $mode" "true" 5000
		return 0
	fi

	# Check if cpupower is available
	if ! command -v "cpupower" &>/dev/null; then
		log "ERROR" "cpupower not found, cannot set CPU frequency" "true" 5000
		return 1
	fi

	log "CPU" "Changing CPU frequency mode: $mode" "false"

	case $mode in
	"high")
		# Enable turbo boost
		if [[ -f /sys/devices/system/cpu/intel_pstate/no_turbo ]]; then
			echo 0 | sudo tee /sys/devices/system/cpu/intel_pstate/no_turbo &>/dev/null || {
				log "ERROR" "Failed to enable CPU turbo mode" "true" 5000
				return 1
			}
		fi

		# Set performance governor
		sudo cpupower frequency-set -g performance &>/dev/null || {
			log "ERROR" "Failed to set CPU governor" "true" 5000
			return 1
		}

		# Set frequency range
		sudo cpupower frequency-set -d 1900MHz -u 2800MHz &>/dev/null || {
			log "ERROR" "Failed to set CPU frequency range" "true" 5000
			return 1
		}

		log "CPU" "$ICON_CPU Performance mode: 1900-2800MHz (Turbo ON)" "true" 5000
		;;
	"low")
		# Disable turbo boost
		if [[ -f /sys/devices/system/cpu/intel_pstate/no_turbo ]]; then
			echo 1 | sudo tee /sys/devices/system/cpu/intel_pstate/no_turbo &>/dev/null || {
				log "ERROR" "Failed to disable CPU turbo mode" "true" 5000
				return 1
			}
		fi

		# Set powersave governor
		sudo cpupower frequency-set -g powersave &>/dev/null || {
			log "ERROR" "Failed to set CPU governor" "true" 5000
			return 1
		}

		# Set frequency range
		sudo cpupower frequency-set -d 1200MHz -u 1900MHz &>/dev/null || {
			log "ERROR" "Failed to set CPU frequency range" "true" 5000
			return 1
		}

		log "CPU" "$ICON_CPU Power save mode: 1200-1900MHz (Turbo OFF)" "true" 5000
		;;
	*)
		log "ERROR" "Invalid CPU mode: $mode (use high/low)" "true" 5000
		return 1
		;;
	esac

	return 0
}

# Switch to a specific workspace
switch_workspace() {
	local workspace=$1

	# Skip in dry run mode
	if [[ $DRY_RUN -eq 1 ]]; then
		log "WORKSPACE" "Simulating switch to workspace $workspace" "false"
		return 0
	fi

	log "WORKSPACE" "Switching to workspace $workspace" "false"

	if ! hyprctl dispatch workspace "$workspace" &>/dev/null; then
		log "ERROR" "Failed to switch to workspace $workspace" "false"
		return 1
	fi

	return 0
}

# Load profile configuration
load_profile() {
	local profile_name=$1
	local profile_file="$CONFIG_DIR/$profile_name.profile"

	log "PROFILE" "Loading profile: $profile_name" "false"

	# Check if profile file exists
	if [[ ! -f "$profile_file" ]]; then
		# Use default settings for 'default' profile
		if [[ "$profile_name" == "default" ]]; then
			log "PROFILE" "Using built-in default profile" "false"
			return 0
		fi

		log "ERROR" "$ICON_ERROR Profile not found: $profile_name" "true" 5000
		return 1
	fi

	# Load profile file (simple key=value format)
	while IFS='=' read -r key value; do
		# Skip empty lines and comments
		[[ -z "$key" || "$key" =~ ^# ]] && continue

		# Trim whitespace
		key=$(echo "$key" | xargs)
		value=$(echo "$value" | xargs)

		# Update groups or application configurations
		if [[ "$key" =~ ^GROUP_ ]]; then
			group_name=${key#GROUP_}
			APP_GROUPS["$group_name"]="$value"
			log "PROFILE" "Updated group: $group_name" "false"
		elif [[ "$key" =~ ^APP_ ]]; then
			app_name=${key#APP_}
			APP_CONFIGS["$app_name"]="$value"
			log "PROFILE" "Updated app: $app_name" "false"
		elif [[ "$key" == "CPU_MODE" ]]; then
			CPU_MODE="$value"
			log "PROFILE" "Set CPU mode: $CPU_MODE" "false"
		elif [[ "$key" == "START_MODE" ]]; then
			START_MODE="$value"
			log "PROFILE" "Set start mode: $START_MODE" "false"
		fi
	done <"$profile_file"

	log "PROFILE" "$ICON_INFO Successfully loaded profile: $profile_name" "true" 3000
	return 0
}

#===============================================================================
# Application Launch Functions
#===============================================================================

# Launch a single application
launch_app() {
	local script_name=$1

	# Get application configuration or use default
	local config=${APP_CONFIGS[$script_name]:-"2:no:no:always:2"}

	# Parse configuration
	local workspace=$(echo "$config" | cut -d: -f1)
	local fullscreen=$(echo "$config" | cut -d: -f2)
	local togglegroup=$(echo "$config" | cut -d: -f3)
	local vpn_mode=$(echo "$config" | cut -d: -f4)
	local sleep_time=$(echo "$config" | cut -d: -f5)

	local app_name="${script_name#start-}"

	# Dry run mode
	if [[ $DRY_RUN -eq 1 ]]; then
		log "$app_name" "Would launch (VPN: $vpn_mode, Workspace: $workspace)" "false"
		return 0
	fi

	# VPN check
	if ! check_vpn_status "$vpn_mode" "$app_name"; then
		log "ERROR" "$ICON_ERROR VPN check failed for $app_name" "true" 10000
		return 1
	fi

	# Construct script path
	local script_path="$SCRIPTS_DIR/${script_name}-${vpn_mode}.sh"

	# Try without .sh extension if not found
	if [[ ! -x "$script_path" ]]; then
		script_path="$SCRIPTS_DIR/${script_name}-${vpn_mode}"
	fi

	# Log launch attempt
	log "$app_name" "Starting (VPN: $vpn_mode, Workspace: $workspace)" "false"

	# Check if script exists and is executable
	if [[ -x "$script_path" ]]; then
		# Switch to target workspace
		switch_workspace "$workspace"

		# Launch application
		"$script_path" &
		local app_pid=$!
		log "$app_name" "Launched (PID: $app_pid)" "false"

		# Wait specified time
		sleep "$sleep_time"

		# Configure fullscreen if needed
		if [[ "$fullscreen" == "yes" ]]; then
			sleep 0.5
			if ! hyprctl dispatch fullscreen 0 &>/dev/null; then
				log "WARNING" "Failed to set fullscreen for $app_name" "false"
			else
				log "$app_name" "Set to fullscreen" "false"
			fi
		fi

		# Configure togglegroup if needed
		if [[ "$togglegroup" == "yes" ]]; then
			sleep 0.5
			if ! hyprctl dispatch togglegroup &>/dev/null; then
				log "WARNING" "Failed to set togglegroup for $app_name" "false"
			else
				log "$app_name" "Set to togglegroup" "false"
			fi
		fi

		# Verify process is still running
		if kill -0 $app_pid &>/dev/null; then
			log "$app_name" "$ICON_SUCCESS Successfully launched" "false"
			return 0
		else
			log "ERROR" "$ICON_ERROR $app_name terminated prematurely" "true" 5000
			return 1
		fi
	else
		log "ERROR" "$ICON_ERROR Script not found: $script_path" "true" 10000
		return 1
	fi
}

# Launch a group of applications
launch_group() {
	local group_name=$1
	local parallel=${2:-false}

	# Get applications in this group
	local apps=${APP_GROUPS[$group_name]}

	# Skip empty groups
	if [[ -z "$apps" ]]; then
		log "WARNING" "Group $group_name is empty" "false"
		return 0
	fi

	# Track success/failure
	local success_count=0
	local total_apps=0

	# Count applications in group
	for app in $apps; do
		((total_apps++))
	done

	log "GROUP" "$ICON_INFO Starting $group_name group ($total_apps apps, Parallel: $parallel)" "false"

	# Parallel launch strategy
	if [[ "$parallel" == "true" ]]; then
		local pids=()
		local app_names=()

		# Launch all applications in parallel
		for app in $apps; do
			# Skip in dry run mode (handled inside launch_app)
			launch_app "$app" &
			pids+=($!)
			app_names+=("$app")
		done

		# Wait for all processes to complete
		for i in "${!pids[@]}"; do
			if wait "${pids[$i]}" &>/dev/null; then
				((success_count++))
				log "GROUP" "${app_names[$i]#start-} completed successfully" "false"
			else
				log "ERROR" "${app_names[$i]#start-} failed" "false"
			fi
		done

	# Sequential launch strategy
	else
		# Launch applications one by one
		for app in $apps; do
			if launch_app "$app"; then
				((success_count++))
			fi
		done
	fi

	# Report success rate
	local success_rate=$((success_count * 100 / total_apps))

	if [[ $success_count -eq $total_apps ]]; then
		log "GROUP" "$ICON_SUCCESS $group_name group complete: $success_count/$total_apps apps (100%)" "false"
	else
		log "GROUP" "$ICON_WARNING $group_name group partial: $success_count/$total_apps apps ($success_rate%)" "false"
	fi

	# All applications failed
	[[ $success_count -eq 0 && $total_apps -gt 0 ]] && return 1

	return 0
}

# Launch applications in hybrid strategy (mix of sequential and parallel)
launch_apps_hybrid() {
	log "LAUNCH" "$ICON_ROCKET Starting hybrid launch sequence..." "true" 3000
	local start_time=$(date +%s.%N)
	local success=true

	# Group 1: Core applications (sequential)
	if ! launch_group "core" false; then
		log "WARNING" "$ICON_WARNING Core group launch partially failed" "true" 5000
		success=false
	fi

	# Group 2: Browsers (parallel)
	if ! launch_group "browsers" true; then
		log "WARNING" "$ICON_WARNING Browsers group launch partially failed" "true" 5000
		success=false
	fi

	# Group 3: Communication applications (parallel)
	if ! launch_group "communication" true; then
		log "WARNING" "$ICON_WARNING Communication group launch partially failed" "true" 5000
		success=false
	fi

	# Group 4: Media applications (sequential)
	if ! launch_group "media" false; then
		log "WARNING" "$ICON_WARNING Media group launch partially failed" "true" 5000
		success=false
	fi

	# Calculate total duration
	local end_time=$(date +%s.%N)
	local duration=$(echo "$end_time - $start_time" | bc)

	# Format duration to 2 decimal places
	duration=$(printf "%.2f" $duration)

	if $success; then
		log "TIMING" "$ICON_SUCCESS Hybrid launch completed in ${duration}s" "true" 10000
	else
		log "TIMING" "$ICON_WARNING Hybrid launch completed in ${duration}s with some failures" "true" 10000
	fi

	return $(! $success) # Return 0 for success, 1 for failure
}

# Launch applications sequentially (all groups, one by one)
launch_apps_sequential() {
	log "LAUNCH" "$ICON_ROCKET Starting sequential launch sequence..." "true" 3000
	local start_time=$(date +%s.%N)
	local success=true

	# Launch all groups sequentially
	for group in "${!APP_GROUPS[@]}"; do
		if ! launch_group "$group" false; then
			log "WARNING" "$ICON_WARNING $group group launch partially failed" "true" 5000
			success=false
		fi
	done

	# Calculate total duration
	local end_time=$(date +%s.%N)
	local duration=$(echo "$end_time - $start_time" | bc)

	# Format duration to 2 decimal places
	duration=$(printf "%.2f" $duration)

	if $success; then
		log "TIMING" "$ICON_SUCCESS Sequential launch completed in ${duration}s" "true" 10000
	else
		log "TIMING" "$ICON_WARNING Sequential launch completed in ${duration}s with some failures" "true" 10000
	fi

	return $(! $success) # Return 0 for success, 1 for failure
}

# Launch all applications in parallel
launch_apps_parallel() {
	log "LAUNCH" "$ICON_ROCKET Starting parallel launch sequence..." "true" 3000
	local start_time=$(date +%s.%N)
	local success=true
	local pids=()
	local group_names=()

	# Launch all groups in parallel
	for group in "${!APP_GROUPS[@]}"; do
		launch_group "$group" true &
		pids+=($!)
		group_names+=("$group")
	done

	# Wait for all groups to complete
	for i in "${!pids[@]}"; do
		if wait "${pids[$i]}" &>/dev/null; then
			log "GROUP" "${group_names[$i]} group completed successfully" "false"
		else
			log "WARNING" "$ICON_WARNING ${group_names[$i]} group launch partially failed" "true" 5000
			success=false
		fi
	done

	# Calculate total duration
	local end_time=$(date +%s.%N)
	local duration=$(echo "$end_time - $start_time" | bc)

	# Format duration to 2 decimal places
	duration=$(printf "%.2f" $duration)

	if $success; then
		log "TIMING" "$ICON_SUCCESS Parallel launch completed in ${duration}s" "true" 10000
	else
		log "TIMING" "$ICON_WARNING Parallel launch completed in ${duration}s with some failures" "true" 10000
	fi

	return $(! $success) # Return 0 for success, 1 for failure
}

# Parse command line arguments
parse_args() {
	while [[ $# -gt 0 ]]; do
		case $1 in
		-h | --help)
			show_help
			exit 0
			;;
		-v | --verbose)
			VERBOSE=1
			shift
			;;
		-p | --profile)
			PROFILE="$2"
			shift
			shift
			;;
		-s | --skip-vpn)
			SKIP_VPN_CHECK=1
			shift
			;;
		-d | --dry-run)
			DRY_RUN=1
			shift
			;;
		-l | --list-groups)
			list_groups
			exit 0
			;;
		-c | --cpu)
			if [[ -z "$2" || ! "$2" =~ ^(high|low)$ ]]; then
				log "ERROR" "Invalid CPU mode: $2 (use high/low)" "true" 5000
				exit 1
			fi
			set_cpu_frequency "$2"
			exit $?
			;;
		-g | --group)
			local group="$2"
			if [[ -z "$group" ]]; then
				log "ERROR" "Group name required" "true" 5000
				exit 1
			fi
			if [[ -n "${APP_GROUPS[$group]}" ]]; then
				launch_group "$group" false
				exit $?
			else
				log "ERROR" "Group not found: $group" "true" 5000
				list_groups
				exit 1
			fi
			;;
		-m | --mode)
			if [[ ! "$2" =~ ^(hybrid|sequential|parallel)$ ]]; then
				log "ERROR" "Invalid launch mode: $2" "true" 5000
				exit 1
			fi
			START_MODE="$2"
			shift
			shift
			;;
		*)
			log "ERROR" "Unknown option: $1" "true" 5000
			show_help
			exit 1
			;;
		esac
	done
}

#===============================================================================
# Main Function
#===============================================================================

main() {
	local start_time=$(date +%s)

	# Parse command line arguments
	parse_args "$@"

	# Start message
	log "START" "$ICON_ROCKET Hybrid Workspace Launcher starting! (Profile: $PROFILE) $([[ $DRY_RUN -eq 1 ]] && echo "[DRY RUN]")" "true" 5000

	# Setup required directories
	setup_directories

	# Check required dependencies
	check_dependencies || exit 1

	# Rotate logs if needed
	rotate_logs

	# Load profile configuration
	if ! load_profile "$PROFILE"; then
		log "ERROR" "Failed to load profile, using defaults" "true" 5000
	fi

	# Check VPN status
	if [[ $SKIP_VPN_CHECK -eq 0 ]]; then
		get_vpn_details
	fi

	# Set CPU frequency if specified
	if [[ -n "$CPU_MODE" ]]; then
		set_cpu_frequency "$CPU_MODE"
	fi

	# Initial workspace
	switch_workspace 2

	# Launch applications based on selected mode
	local launch_status=0
	case "$START_MODE" in
	"hybrid")
		launch_apps_hybrid
		launch_status=$?
		;;
	"sequential")
		launch_apps_sequential
		launch_status=$?
		;;
	"parallel")
		launch_apps_parallel
		launch_status=$?
		;;
	*)
		log "ERROR" "Invalid launch mode: $START_MODE" "true" 5000
		launch_status=1
		;;
	esac

	# Calculate total duration
	local end_time=$(date +%s)
	local duration=$((end_time - start_time))

	# Final status message
	if [[ $launch_status -eq 0 ]]; then
		log "Duration" "$ICON_CLOCK Total time: ${duration}s - Successfully completed" "true" 20000
	else
		log "Duration" "$ICON_WARNING Total time: ${duration}s - Completed with issues" "true" 20000
	fi

	# Final workspace switch
	sleep 5
	switch_workspace 2
	log "WORKSPACE" "Final switch to workspace 2" "false"

	return $launch_status
}

# Execute main function with all arguments
main "$@"
