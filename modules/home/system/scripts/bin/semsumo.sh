#!/usr/bin/env bash

#######################################
# Semsumo - Advanced Session Manager
# Version: 5.0.0
# Author: Kenan Pelit
# Description: Robust session manager with VPN integration and profile management
#######################################

# Strict mode
set -euo pipefail
IFS=$'\n\t'

# Configuration
readonly VERSION="5.0.0"
readonly CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/sem"
readonly CONFIG_FILE="$CONFIG_DIR/config.json"
readonly PID_DIR="/tmp/sem"
readonly LOG_FILE="/tmp/sem/semsumo.log"
readonly SCRIPTS_DIR="$HOME/.nixosc/modules/home/system/scripts/start"
readonly PID_FILE="/tmp/sem/semsumo.pid" # PID_FILE değişkeni eklendi
readonly DEFAULT_WAIT_TIME=2
readonly DEFAULT_FULLSCREEN_WAIT=1
readonly DEFAULT_SWITCH_WAIT=0.5

# Color definitions
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly MAGENTA='\033[0;35m'
readonly BOLD='\033[1m'
readonly NC='\033[0m'

# Global variables
DEBUG=0
CREATE_MODE=0
PARALLEL=0
SINGLE_PROFILE=""
RUN_TERMINALS=false
RUN_BROWSERS=false
RUN_APPS=false
DRY_RUN=false
CURRENT_WORKSPACE=""
RETRY_COUNT=3
FINAL_WORKSPACE=""
disable_final_workspace=0
total_steps=0
current_step=0
declare -A APP_PIDS

## Enhanced group definitions
#declare -A APP_GROUPS=(
#	["browsers"]="Brave-Kenp,Brave-CompecTA,Brave-Ai,Brave-Whats,Chrome-Kenp,Chrome-CompecTA,Chrome-AI,Chrome-Whats,Zen-Kenp,Zen-CompecTA,Zen-NoVpn,Zen-Proxy"
#	["terminals"]="kkenp,mkenp,wkenp,wezterm,kitty-single,wezterm-rmpc"
#	["communications"]="discord,webcord,Brave-Discord,Brave-Whatsapp,Zen-Discord,Zen-Whats"
#	["media"]="spotify,mpv,Brave-Youtube,Brave-Tiktok,Brave-Spotify,Zen-Spotify"
#	["all"]="browsers terminals communications media"
#)

# Enhanced group definitions
declare -A APP_GROUPS=(
	["browsers"]="Brave-Kenp,Brave-Ai,Brave-CompecTA,Brave-Whats"
	["terminals"]="kkenp"
	["communications"]="webcord"
	["media"]="spotify,Brave-Youtube"
	["all"]="terminals browsers communications media"
)

# Create default configuration file
create_default_config() {
	cat >"$CONFIG_FILE" <<'EOF'
{
  "settings": {
    "final_workspace": "2",
    "wait_time": 1,
    "retry_count": 2,
    "parallel_mode": false
  },
  "sessions": {
    "kkenp": {
      "command": "kitty",
      "args": ["--class", "TmuxKenp", "-T", "Tmux", "-e", "tm"],
      "vpn": "bypass",
      "workspace": "2",
      "wait_time": 1,
      "enabled": true,
      "type": "terminal"
    },
    "mkenp": {
      "command": "kitty",
      "args": ["--class", "TmuxKenp", "-T", "Tmux", "-e", "tm"],
      "vpn": "secure",
      "workspace": "2",
      "wait_time": 1,
      "enabled": true,
      "type": "terminal"
    },
    "wkenp": {
      "command": "wezterm",
      "args": ["start", "--class", "TmuxKenp", "-e", "tm"],
      "vpn": "bypass",
      "workspace": "2",
      "wait_time": 1,
      "enabled": true,
      "type": "terminal"
    },
    "wezterm": {
      "command": "wezterm",
      "args": ["start", "--class", "wezterm"],
      "vpn": "secure",
      "workspace": "2",
      "wait_time": 1,
      "enabled": true,
      "type": "terminal"
    },
    "kitty-single": {
      "command": "kitty",
      "args": ["--class", "kitty", "-T", "kitty", "--single-instance"],
      "vpn": "secure",
      "workspace": "2",
      "wait_time": 1,
      "enabled": true,
      "type": "terminal"
    },
    "wezterm-rmpc": {
      "command": "wezterm",
      "args": ["start", "--class", "rmpc", "-e", "rmpc"],
      "vpn": "secure",
      "wait_time": 1,
      "enabled": true,
      "type": "terminal"
    },
    "discord": {
      "command": "discord",
      "args": ["-m", "--class=discord", "--title=discord"],
      "vpn": "secure",
      "workspace": "5",
      "fullscreen": true,
      "wait_time": 1,
      "enabled": true,
      "type": "app"
    },
    "webcord": {
      "command": "webcord",
      "args": ["-m", "--class=WebCord", "--title=Webcord"],
      "vpn": "secure",
      "workspace": "5",
      "fullscreen": true,
      "wait_time": 1,
      "enabled": true,
      "type": "app"
    },
    "Chrome-Kenp": {
      "command": "profile_chrome",
      "args": ["Kenp", "--class", "Kenp"],
      "vpn": "secure",
      "workspace": "1",
      "wait_time": 1,
      "enabled": true,
      "type": "browser"
    },
    "Chrome-CompecTA": {
      "command": "profile_chrome",
      "args": ["CompecTA", "--class", "CompecTA"],
      "vpn": "secure",
      "workspace": "4",
      "wait_time": 1,
      "enabled": true,
      "type": "browser"
    },
    "Chrome-AI": {
      "command": "profile_chrome",
      "args": ["AI", "--class", "AI"],
      "vpn": "secure",
      "workspace": "3",
      "wait_time": 1,
      "enabled": true,
      "type": "browser"
    },
    "Chrome-Whats": {
      "command": "profile_chrome",
      "args": ["Whats", "--class", "Whats"],
      "vpn": "secure",
      "workspace": "9",
      "wait_time": 1,
      "enabled": true,
      "type": "browser"
    },
    "Brave-Kenp": {
      "command": "profile_brave",
      "args": ["Kenp"],
      "vpn": "secure",
      "workspace": "1",
      "wait_time": 2,
      "enabled": true,
      "type": "browser"
    },
    "Brave-CompecTA": {
      "command": "profile_brave",
      "args": ["CompecTA"],
      "vpn": "secure",
      "workspace": "4",
      "wait_time": 2,
      "enabled": true,
      "type": "browser"
    },
    "Brave-Ai": {
      "command": "profile_brave",
      "args": ["Ai"],
      "vpn": "secure",
      "workspace": "3",
      "wait_time": 2,
      "enabled": true,
      "type": "browser"
    },
    "Brave-Whats": {
      "command": "profile_brave",
      "args": ["Whats"],
      "vpn": "secure",
      "workspace": "9",
      "wait_time": 1,
      "enabled": true,
      "type": "browser"
    },
    "Brave-Exclude": {
      "command": "profile_brave",
      "args": ["Exclude"],
      "vpn": "bypass",
      "workspace": "6",
      "wait_time": 1,
      "enabled": true,
      "type": "browser"
    },
    "Brave-Youtube": {
      "command": "profile_brave",
      "args": ["--youtube"],
      "vpn": "secure",
      "workspace": "7",
      "fullscreen": true,
      "wait_time": 1,
      "enabled": true,
      "type": "browser"
    },
    "Brave-Tiktok": {
      "command": "profile_brave",
      "args": ["--tiktok"],
      "vpn": "secure",
      "workspace": "6",
      "fullscreen": true,
      "wait_time": 1,
      "enabled": true,
      "type": "browser"
    },
    "Brave-Spotify": {
      "command": "profile_brave",
      "args": ["--spotify"],
      "vpn": "secure",
      "workspace": "8",
      "fullscreen": true,
      "wait_time": 1,
      "enabled": true,
      "type": "browser"
    },
    "Brave-Discord": {
      "command": "profile_brave",
      "args": ["--discord"],
      "vpn": "secure",
      "workspace": "5",
      "wait_time": 1,
      "fullscreen": true,
      "enabled": true,
      "type": "browser"
    },
    "Brave-Whatsapp": {
      "command": "profile_brave",
      "args": ["--whatsapp"],
      "vpn": "secure",
      "workspace": "9",
      "fullscreen": true,
      "wait_time": 1,
      "enabled": true,
      "type": "browser"
    },
    "Zen-Kenp": {
      "command": "zen",
      "args": ["-P", "Kenp", "--class", "Kenp", "--name", "Kenp", "--restore-session"],
      "vpn": "secure",
      "workspace": "1",
      "wait_time": 1,
      "enabled": true,
      "type": "browser"
    },
    "Zen-CompecTA": {
      "command": "zen",
      "args": ["-P", "CompecTA", "--class", "CompecTA", "--name", "CompecTA", "--restore-session"],
      "vpn": "secure",
      "workspace": "4",
      "wait_time": 1,
      "enabled": true,
      "type": "browser"
    },
    "Zen-Discord": {
      "command": "zen",
      "args": ["-P", "Discord", "--class", "Discord", "--name", "Discord", "--restore-session"],
      "vpn": "secure",
      "workspace": "5",
      "fullscreen": true,
      "wait_time": 1,
      "enabled": true,
      "type": "browser"
    },
    "Zen-NoVpn": {
      "command": "zen",
      "args": ["-P", "NoVpn", "--class", "AI", "--name", "AI", "--restore-session"],
      "vpn": "bypass",
      "workspace": "3",
      "wait_time": 1,
      "enabled": true,
      "type": "browser"
    },
    "Zen-Proxy": {
      "command": "zen",
      "args": ["-P", "Proxy", "--class", "Proxy", "--name", "Proxy", "--restore-session"],
      "vpn": "bypass",
      "workspace": "7",
      "wait_time": 1,
      "enabled": true,
      "type": "browser"
    },
    "Zen-Spotify": {
      "command": "zen",
      "args": ["-P", "Spotify", "--class", "Spotify", "--name", "Spotify", "--restore-session"],
      "vpn": "bypass",
      "workspace": "7",
      "fullscreen": true,
      "wait_time": 1,
      "enabled": true,
      "type": "browser"
    },
    "Zen-Whats": {
      "command": "zen",
      "args": ["-P", "Whats", "--class", "Whats", "--name", "Whats", "--restore-session"],
      "vpn": "secure",
      "workspace": "9",
      "fullscreen": true,
      "wait_time": 1,
      "enabled": true,
      "type": "browser"
    },
    "spotify": {
      "command": "spotify",
      "args": ["--class", "Spotify", "-T", "Spotify"],
      "vpn": "bypass",
      "workspace": "8",
      "fullscreen": true,
      "wait_time": 1,
      "enabled": true,
      "type": "app"
    },
    "mpv": {
      "command": "mpv",
      "args": ["--player-operation-mode=pseudo-gui", "--input-ipc-server=/tmp/mpvsocket"],
      "vpn": "bypass",
      "workspace": "6",
      "fullscreen": true,
      "wait_time": 1,
      "enabled": true,
      "type": "app"
    },
    "ferdium": {
      "command": "ferdium",
      "args": [],
      "vpn": "secure",
      "workspace": "9",
      "fullscreen": true,
      "wait_time": 1,
      "enabled": true,
      "type": "app"
    }
  }
}
EOF
	chmod 600 "$CONFIG_FILE"
}

# Logging functions
log() {
	local level="$1"
	local module="${2:-SYSTEM}"
	local message="$3"
	local notify="${4:-false}"
	local timestamp=$(date +"%Y-%m-%d %T")
	local color=""

	case "$level" in
	"INFO") color=$BLUE ;;
	"SUCCESS") color=$GREEN ;;
	"WARN") color=$YELLOW ;;
	"ERROR") color=$RED ;;
	"DEBUG")
		color=$CYAN
		[[ $DEBUG -ne 1 ]] && return
		;;
	*) color=$NC ;;
	esac

	# Print to terminal
	echo -e "${color}${BOLD}[$level]${NC} ${MAGENTA}[$module]${NC} $message"

	# Log to file
	echo "[$timestamp][$level][$module] $message" >>"$LOG_FILE"

	# Show notification if requested
	if [[ "$notify" == "true" ]] && command_exists "notify-send"; then
		notify-send -a "Semsumo" "$module: $message"
	fi

	# Exit on error (unless debug mode or dry run)
	if [[ "$level" == "ERROR" && "$DRY_RUN" != "true" && "$DEBUG" -ne 1 ]]; then
		echo -e "${RED}${BOLD}[ERROR] Critical error! Exiting...${NC}"
		cleanup
		exit 1
	fi
}

# Progress indicator
show_progress() {
	local desc="$1"
	((current_step++))

	# Only show progress bar in a real terminal
	if [[ -t 1 ]]; then
		local percent=$((current_step * 100 / total_steps))
		local bar_size=50
		local filled_size=$((bar_size * current_step / total_steps))
		local empty_size=$((bar_size - filled_size))

		# Progress bar
		printf "\r${CYAN}Progress: [${GREEN}"
		printf "%${filled_size}s" | tr ' ' '#'
		printf "${YELLOW}"
		printf "%${empty_size}s" | tr ' ' '-'
		printf "${CYAN}] %3d%% - %s${NC}" "$percent" "$desc"

		# Add newline after the last step
		if [[ $current_step -eq $total_steps ]]; then
			echo ""
		fi
	fi

	# Show progress notification periodically
	if [[ $total_steps -gt 0 && -n "$desc" ]]; then
		local notify_steps=$((total_steps / 4))
		if [[ $notify_steps -gt 0 && ($current_step -eq $total_steps || $((current_step % notify_steps)) -eq 0) ]]; then
			local percent=$((current_step * 100 / total_steps))
			log "INFO" "PROGRESS" "Progress: $percent% - $desc" "true"
		fi
	fi
}

# Cleanup function
cleanup() {
	log "INFO" "CLEANUP" "Starting cleanup process..." "false"

	# Clean up PID file if it exists
	if [[ -n "${PID_FILE:-}" && -f "$PID_FILE" ]]; then
		rm -f "$PID_FILE"
	fi

	# Don't do actual cleanup in dry run mode
	if [[ "$DRY_RUN" == "true" ]]; then
		log "INFO" "CLEANUP" "Dry run mode - no actual cleanup performed" "false"
		return 0
	fi

	log "INFO" "CLEANUP" "Cleanup completed" "false"
}

# Shortcut log functions for backward compatibility
log_info() { log "INFO" "SYSTEM" "$1"; }
log_warn() { log "WARN" "SYSTEM" "$1"; }
log_error() { log "ERROR" "SYSTEM" "$1"; }
log_debug() { log "DEBUG" "SYSTEM" "$1"; }
log_success() { log "SUCCESS" "SYSTEM" "$1"; }

# Check if command exists
command_exists() {
	command -v "$1" >/dev/null 2>&1
}

# Retry command with specified number of attempts
retry_command() {
	local cmd="$1"
	local max_attempts="${RETRY_COUNT:-3}"
	local description="$2"
	local attempt=1

	while [[ $attempt -le $max_attempts ]]; do
		log "INFO" "RETRY" "Executing command (attempt $attempt/$max_attempts): $description" "false"

		if eval "$cmd"; then
			log "SUCCESS" "RETRY" "Command executed successfully: $description" "false"
			return 0
		else
			log "WARN" "RETRY" "Command failed, retrying..." "false"
			((attempt++))
			sleep 2
		fi
	done

	log "ERROR" "RETRY" "Maximum retry count reached, command failed: $description" "true"
	return 1
}

# Check VPN status
check_vpn() {
	if ! command_exists "mullvad"; then
		log "WARN" "VPN" "Mullvad VPN not installed"
		return 1
	fi

	if mullvad status 2>/dev/null | grep -q "Connected"; then
		log "DEBUG" "VPN" "VPN is connected"
		return 0
	fi

	log "DEBUG" "VPN" "VPN is not connected"
	return 1
}

# Get VPN mode for session
get_vpn_mode() {
	local session_name="$1"
	local cli_mode="${2:-}"

	case "$cli_mode" in
	bypass | secure)
		echo "$cli_mode"
		;;
	"")
		jq -r ".sessions.\"$session_name\".vpn // \"secure\"" "$CONFIG_FILE"
		;;
	*)
		log "ERROR" "VPN" "Invalid VPN mode: $cli_mode. Use 'secure' or 'bypass'"
		return 1
		;;
	esac
}

# Switch workspace reliably
switch_workspace() {
	local workspace="$1"
	local wait_time="${2:-$DEFAULT_SWITCH_WAIT}"

	# Skip if workspace is not specified
	[[ -z "$workspace" || "$workspace" == "0" || "$workspace" == "null" ]] && return 0

	# Skip in dry run mode
	if [[ "$DRY_RUN" == "true" ]]; then
		log "DEBUG" "WORKSPACE" "Dry run: Would switch to workspace $workspace" "false"
		CURRENT_WORKSPACE="$workspace"
		return 0
	fi

	if ! command_exists "hyprctl"; then
		log "WARN" "WORKSPACE" "hyprctl not found, workspace switching disabled"
		return 1
	fi

	# Get current workspace
	local current=$(hyprctl activeworkspace -j | grep -o '"id": [0-9]*' | grep -o '[0-9]*' || echo "")

	# Check if we're already on the requested workspace
	if [[ "$current" == "$workspace" ]]; then
		log "DEBUG" "WORKSPACE" "Already on workspace $workspace, skipping switch" "false"
		CURRENT_WORKSPACE="$workspace"
		return 0
	fi

	# Otherwise, switch to the requested workspace
	log "INFO" "WORKSPACE" "Switching to workspace $workspace"
	if ! hyprctl dispatch workspace "$workspace" >/dev/null 2>&1; then
		log "ERROR" "WORKSPACE" "Failed to switch to workspace $workspace"
		return 1
	fi

	CURRENT_WORKSPACE="$workspace"
	sleep "$wait_time"
	return 0
}

# Make application fullscreen
make_fullscreen() {
	local wait_time="${1:-$DEFAULT_FULLSCREEN_WAIT}"

	# Skip in dry run mode
	if [[ "$DRY_RUN" == "true" ]]; then
		log "DEBUG" "FULLSCREEN" "Dry run: Would make application fullscreen" "false"
		return 0
	fi

	if ! command_exists "hyprctl"; then
		log "WARN" "FULLSCREEN" "hyprctl not found, fullscreen disabled"
		return 1
	fi

	log "INFO" "FULLSCREEN" "Making application fullscreen"
	sleep "$wait_time"
	hyprctl dispatch fullscreen 1 >/dev/null 2>&1
	sleep 1
	return 0
}

# Handle workspace and fullscreen setup
handle_workspace() {
	local session_name="$1"

	# Extract configuration
	local workspace=$(jq -r ".sessions.\"${session_name}\".workspace // \"0\"" "$CONFIG_FILE")
	local fullscreen=$(jq -r ".sessions.\"${session_name}\".fullscreen // false" "$CONFIG_FILE")
	local wait_time=$(jq -r ".sessions.\"${session_name}\".wait_time // \"$DEFAULT_WAIT_TIME\"" "$CONFIG_FILE")

	if [[ "$workspace" != "0" && "$workspace" != "null" ]]; then
		switch_workspace "$workspace" "$wait_time"

		if [[ "$fullscreen" == "true" ]]; then
			make_fullscreen "$wait_time"
		fi
	fi

	return 0
}

# Check if application is already running
is_app_running() {
	local app_name="$1"

	# Hyprland'den pencere bilgisini kontrol et
	if hyprctl clients -j | jq -e ".[] | select(.initialClass == \"${app_name,,}\")" >/dev/null; then
		return 0
	fi

	# Fallback: PID kontrol
	[ -f "$PID_DIR/${app_name}.pid" ] && return 0

	return 1
}

# Clean all PID files
clean_pid_files() {
	local force="${1:-false}"

	log "INFO" "CLEANUP" "Cleaning PID files..."

	# Remove all PID files
	rm -rf "$PID_DIR"/*.pid
	mkdir -p "$PID_DIR"

	log "SUCCESS" "CLEANUP" "All PID files have been removed"
}

# Execute application with proper error handling
execute_application() {
	local cmd="$1"
	shift
	local -a args=("$@")

	# Arguments for debug output
	local args_str=$(printf "%s " "${args[@]}")
	log "DEBUG" "EXEC" "Executing: $cmd $args_str"

	# Skip in dry run mode
	if [[ "$DRY_RUN" == "true" ]]; then
		log "DEBUG" "EXEC" "Dry run: Would execute $cmd $args_str" "false"
		return 0
	fi

	if ! command_exists "$cmd"; then
		log "ERROR" "EXEC" "Command not found: $cmd"
		return 1
	fi

	# Start the process in a completely detached way
	log "DEBUG" "EXEC" "Starting detached process: $cmd ${args[*]}"

	# Use nohup and disown to properly detach the process
	nohup "$cmd" "${args[@]}" >/dev/null 2>&1 &
	local pid=$!
	disown $pid

	# Verify the process is running
	if kill -0 "$pid" 2>/dev/null; then
		log "DEBUG" "EXEC" "Process $cmd started successfully with PID: $pid"
		echo "$pid"
		return 0
	else
		log "ERROR" "EXEC" "Failed to start process or get valid PID"
		return 1
	fi
}

# Initialize environment with PID checking
initialize() {
	mkdir -p "$CONFIG_DIR" "$PID_DIR" "/tmp/sem"
	touch "$LOG_FILE"

	if [[ ! -f "$CONFIG_FILE" ]]; then
		create_default_config
	fi

	# Check and clean stale PID files at startup
	echo "Checking PID directory at startup..."
	mkdir -p "$PID_DIR"

	# Check if PID directory exists and has PID files
	if [[ -d "$PID_DIR" ]]; then
		local pid_files=("$PID_DIR"/*.pid)
		if [[ ${#pid_files[@]} -gt 0 && -f "${pid_files[0]}" ]]; then
			for pid_file in "$PID_DIR"/*.pid; do
				[[ -f "$pid_file" ]] || continue

				pid=$(cat "$pid_file")
				app_name=$(basename "$pid_file" .pid)

				if kill -0 "$pid" 2>/dev/null; then
					echo "  $app_name: Running (PID: $pid)"
				else
					echo "  $app_name: Stale PID file (PID: $pid)"
					rm -f "$pid_file"
					echo "    Removed stale PID file"
				fi
			done
		else
			echo "  No PID files found."
		fi
	else
		echo "  PID directory does not exist. Creating..."
		mkdir -p "$PID_DIR"
	fi
}

track_process() {
	local name="$1"
	local pid="$2"

	# Skip in dry run mode
	if [[ "$DRY_RUN" == "true" ]]; then
		log "DEBUG" "TRACK" "Dry run: Would track process $name (PID: $pid)" "false"
		return 0
	fi

	mkdir -p "$PID_DIR"
	echo "$pid" >"$PID_DIR/${name}.pid"
	APP_PIDS["$name"]="$pid"
	log "INFO" "TRACK" "Tracking application $name (PID: $pid)" "false"

	# Verify the PID file was created
	if [[ ! -f "$PID_DIR/${name}.pid" ]]; then
		log "ERROR" "TRACK" "Failed to create PID file for $name"
		return 1
	fi

	return 0
}

# Check session status
check_status() {
	local session_name="$1"
	local pid_file="$PID_DIR/${session_name}.pid"

	if [[ -f "$pid_file" ]] && kill -0 "$(cat "$pid_file")" 2>/dev/null; then
		echo "running"
	else
		echo "stopped"
	fi
}

# Stop session
stop_session() {
	local session_name="$1"
	local pid_file="$PID_DIR/${session_name}.pid"
	local force="${2:-false}"

	log "DEBUG" "STOP" "Attempting to stop session: $session_name"

	if [[ -f "$pid_file" ]]; then
		local pid=$(cat "$pid_file")
		log "DEBUG" "STOP" "Found PID file: $pid"

		if kill "$pid" 2>/dev/null; then
			log "SUCCESS" "STOP" "Session stopped: $session_name (PID: $pid)"
			rm -f "$pid_file"
			return 0
		else
			log "WARN" "STOP" "Could not stop process with PID $pid, may have already exited"
			rm -f "$pid_file"
		fi
	fi

	# Fallback: Try to find and kill process by name
	local app_type=$(jq -r ".sessions.\"${session_name}\".type // \"app\"" "$CONFIG_FILE")
	local command=$(jq -r ".sessions.\"${session_name}\".command" "$CONFIG_FILE")

	log "DEBUG" "STOP" "No PID file or stale PID, trying to find process by name: $command (type: $app_type)"

	local pid
	case "$app_type" in
	"browser")
		pid=$(pgrep -f "$session_name" 2>/dev/null | head -1)
		;;
	"app")
		pid=$(pgrep -x "$(basename "$command")" 2>/dev/null | head -1)
		;;
	*)
		pid=$(pgrep -f "$command" 2>/dev/null | head -1)
		;;
	esac

	if [[ -n "$pid" ]]; then
		log "DEBUG" "STOP" "Found process: $pid"
		if kill "$pid" 2>/dev/null; then
			log "SUCCESS" "STOP" "Session stopped: $session_name (PID: $pid)"
			return 0
		else
			log "WARN" "STOP" "Failed to stop process: $session_name"
		fi
	else
		log "WARN" "STOP" "No running session found: $session_name"
	fi

	return 1
}

# Start session with all features
start_session() {
	local session_name="$1"
	local vpn_param="${2:-}"

	# Check if session exists in config
	if ! jq -e ".sessions.\"${session_name}\"" "$CONFIG_FILE" >/dev/null; then
		log "ERROR" "SESSION" "Session not found in config: $session_name"
		return 1
	fi

	log "DEBUG" "SESSION" "Starting session check for $session_name"

	# Special handling for Spotify
	if [[ "$session_name" == "spotify" ]]; then
		log "INFO" "SESSION" "Applying special handling for Spotify"

		# Get command and args
		local command=$(jq -r ".sessions.\"${session_name}\".command" "$CONFIG_FILE")
		readarray -t args < <(jq -r ".sessions.\"${session_name}\".args[]? // empty" "$CONFIG_FILE")

		# Start Spotify with nohup and disown
		log "INFO" "SESSION" "Starting Spotify in detached mode"
		nohup "$command" "${args[@]}" >/dev/null 2>&1 &
		local pid=$!
		disown $pid

		# Track the process
		if [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null; then
			track_process "$session_name" "$pid"
			log "SUCCESS" "SESSION" "Spotify started successfully (PID: $pid)"

			# Handle workspace and fullscreen for Spotify
			handle_workspace "$session_name"
			return 0
		else
			log "ERROR" "SESSION" "Failed to start Spotify"
			return 1
		fi
	fi

	# Check if session is enabled
	local enabled=$(jq -r ".sessions.\"${session_name}\".enabled // true" "$CONFIG_FILE")
	if [[ "$enabled" != "true" ]]; then
		log "INFO" "SESSION" "Session disabled: $session_name"
		return 0
	fi

	# Check if app is already running
	local app_type=$(jq -r ".sessions.\"${session_name}\".type // \"app\"" "$CONFIG_FILE")
	log "DEBUG" "SESSION" "Session type: $app_type"

	if is_app_running "$session_name" "$app_type"; then
		log "INFO" "SESSION" "Session already running: $session_name"
		return 0
	fi

	local command=$(jq -r ".sessions.\"${session_name}\".command" "$CONFIG_FILE")
	local vpn_mode=$(get_vpn_mode "$session_name" "$vpn_param")
	local vpn_active=false
	if check_vpn; then
		vpn_active=true
	fi

	log "DEBUG" "SESSION" "Command: $command, VPN: $vpn_mode, VPN active: $vpn_active"

	# Handle workspace first
	handle_workspace "$session_name"

	# Start the application
	log "INFO" "SESSION" "Starting session: $session_name (VPN: $vpn_mode)"

	local pid
	# Get args as individual items in an array
	readarray -t args < <(jq -r ".sessions.\"${session_name}\".args[]? // empty" "$CONFIG_FILE")

	# Log arguments as a single line for debugging
	local args_str=$(printf "%s " "${args[@]}")
	log "DEBUG" "SESSION" "Command: $command, Args: $args_str"

	case "$vpn_mode" in
	secure)
		if ! $vpn_active; then
			log "WARN" "VPN" "VPN not connected. Starting $session_name without protection"
		fi
		pid=$(execute_application "$command" "${args[@]}")
		;;
	bypass)
		if ! command_exists "mullvad-exclude"; then
			log "WARN" "VPN" "mullvad-exclude not found, starting normally"
			pid=$(execute_application "$command" "${args[@]}")
		else
			log "INFO" "VPN" "Starting $session_name bypassing VPN (timeout: 10s)"
			pid=$(timeout 10s mullvad-exclude "$command" "${args[@]}" 2>/dev/null)

			if [[ -z "$pid" || "$pid" -le 0 ]]; then
				log "WARN" "VPN" "Bypass failed, trying normal start"
				pid=$(execute_application "$command" "${args[@]}")
			fi
		fi
		;;
	esac

	# Save PID if successful
	if [[ -n "$pid" && "$pid" -gt 0 ]]; then
		track_process "$session_name" "$pid"
		log "SUCCESS" "SESSION" "Session started successfully: $session_name (PID: $pid)"

		# Immediately check status
		if ! is_app_running "$session_name" "$app_type"; then
			log "WARN" "SESSION" "Session may have started but is not detected as running: $session_name"
		fi
	else
		log "ERROR" "SESSION" "Failed to start session: $session_name"
		return 1
	fi

	# Wait if specified
	local wait_time=$(jq -r ".sessions.\"${session_name}\".wait_time // \"$DEFAULT_WAIT_TIME\"" "$CONFIG_FILE")
	log "DEBUG" "SESSION" "Waiting $wait_time seconds for $session_name to initialize"
	sleep "$wait_time"

	# Make fullscreen if needed
	local fullscreen=$(jq -r ".sessions.\"${session_name}\".fullscreen // false" "$CONFIG_FILE")
	if [[ "$fullscreen" == "true" ]]; then
		log "INFO" "FULLSCREEN" "Making $session_name fullscreen"
		make_fullscreen "$wait_time"
	fi

	# Handle final workspace if specified
	handle_final_workspace "$session_name"

	return 0
}

# Restart session
restart_session() {
	local session_name="$1"
	local vpn_param="${2:-}"

	log "INFO" "SESSION" "Restarting session: $session_name"

	if stop_session "$session_name"; then
		sleep 2
	else
		log "WARN" "SESSION" "Session not running, starting fresh: $session_name"
	fi

	start_session "$session_name" "$vpn_param"
	return $?
}

# List all sessions
list_sessions() {
	log "INFO" "LIST" "Available sessions:"

	jq -r '.sessions | keys[]' "$CONFIG_FILE" | while read -r session; do
		local command=$(jq -r ".sessions.\"$session\".command" "$CONFIG_FILE")
		local vpn=$(jq -r ".sessions.\"$session\".vpn // \"secure\"" "$CONFIG_FILE")
		local workspace=$(jq -r ".sessions.\"$session\".workspace // \"0\"" "$CONFIG_FILE")
		local wait_time=$(jq -r ".sessions.\"$session\".wait_time // \"$DEFAULT_WAIT_TIME\"" "$CONFIG_FILE")
		local type=$(jq -r ".sessions.\"$session\".type // \"app\"" "$CONFIG_FILE")
		local enabled=$(jq -r ".sessions.\"$session\".enabled // true" "$CONFIG_FILE")
		local status=$(check_status "$session")

		printf "${GREEN}%s${NC}: " "$session"

		if [[ "$status" == "running" ]]; then
			printf "[${GREEN}RUNNING${NC}] "
		else
			printf "[${RED}STOPPED${NC}] "
		fi

		if [[ "$enabled" != "true" ]]; then
			printf "[${YELLOW}DISABLED${NC}] "
		fi

		printf "Type: ${MAGENTA}%s${NC}, " "$type"
		printf "Command: ${BLUE}%s${NC}, " "$command"
		printf "VPN: ${CYAN}%s${NC}, " "$vpn"
		printf "Workspace: ${YELLOW}%s${NC}, " "$workspace"
		printf "Wait: ${MAGENTA}%ss${NC}\n" "$wait_time"
	done
}

# List all groups
list_groups() {
	log "INFO" "GROUP" "Available groups:"

	for group in "${!APP_GROUPS[@]}"; do
		printf "${GREEN}%s${NC}: " "$group"

		if [[ "$group" == "all" ]]; then
			printf "${YELLOW}%s${NC} (meta group)\n" "${APP_GROUPS[$group]}"
		else
			printf "${CYAN}%s${NC}\n" "${APP_GROUPS[$group]}"
		fi
	done
}

# Handle final workspace if specified
handle_final_workspace() {
	local session_name="$1"

	# Disable_final_workspace değişkeni 1 ise işlemi atla
	if [[ "$disable_final_workspace" -eq 1 ]]; then
		return 0
	fi

	local final_workspace=""

	# If specific final workspace is provided, use it
	if [[ -n "$FINAL_WORKSPACE" ]]; then
		final_workspace="$FINAL_WORKSPACE"
	else
		# Otherwise check the session's final_workspace
		final_workspace=$(jq -r ".sessions.\"${session_name}\".final_workspace // \"0\"" "$CONFIG_FILE")

		# If not set in session, check global settings
		if [[ "$final_workspace" == "0" || "$final_workspace" == "null" ]]; then
			final_workspace=$(jq -r ".settings.final_workspace // \"0\"" "$CONFIG_FILE")
		fi
	fi

	if [[ "$final_workspace" != "0" && "$final_workspace" != "null" ]]; then
		log "INFO" "WORKSPACE" "Switching to final workspace $final_workspace"
		switch_workspace "$final_workspace"
	fi
}

start_all_groups() {
	local old_disable_final_workspace="$disable_final_workspace"
	disable_final_workspace=1
	local start_time=$(date +%s)

	log "INFO" "ALL" "Starting all groups sequentially"

	# Grupları tanımlı sırayla başlat
	local group_order=("terminals" "browsers" "communications" "media")

	for group in "${group_order[@]}"; do
		if [[ -v APP_GROUPS["$group"] ]]; then
			log "INFO" "ALL" "Starting $group group"
			local group_content="${APP_GROUPS["$group"]}"

			# Trim ve boş eleman kontrolü
			local sessions=()
			while IFS=',' read -ra temp_arr; do
				for session in "${temp_arr[@]}"; do
					session=$(echo "$session" | xargs) # Trim whitespace
					[[ -n "$session" ]] && sessions+=("$session")
				done
			done <<<"$group_content"

			for session in "${sessions[@]}"; do
				log "INFO" "SESSION" "Starting session: $session"

				# Session'ın config'te var olduğunu kontrol et
				if ! jq -e ".sessions.\"$session\"" "$CONFIG_FILE" >/dev/null; then
					log "ERROR" "SESSION" "Session not found in config: $session"
					continue
				fi

				start_session "$session"
				sleep 1
			done
		fi
	done

	disable_final_workspace="$old_disable_final_workspace"

	# Final workspace'e geç
	local final_workspace=$(jq -r ".settings.final_workspace // \"0\"" "$CONFIG_FILE")
	if [[ "$final_workspace" != "0" && "$final_workspace" != "null" ]]; then
		log "INFO" "WORKSPACE" "Switching to final workspace $final_workspace"
		switch_workspace "$final_workspace"
	fi

	local duration=$(($(date +%s) - start_time))
	log "SUCCESS" "ALL" "All groups started successfully (Time: ${duration}s)"
}

# Start a group of sessions
start_group() {
	local group_name="$1"
	local parallel="${2:-false}"

	# Check if group exists
	if [[ ! -v APP_GROUPS["$group_name"] ]]; then
		log "ERROR" "GROUP" "Group not found: $group_name"
		return 1
	fi

	# Geçici olarak final workspace geçişlerini devre dışı bırak
	local old_disable_final_workspace="$disable_final_workspace"
	disable_final_workspace=1

	local group_content="${APP_GROUPS[$group_name]}"
	local start_time=$(date +%s)

	# Handle meta group "all" using the helper function
	if [[ "$group_name" == "all" ]]; then
		start_all_groups
	else
		log "INFO" "GROUP" "Starting group: $group_name ($group_content)"

		# Calculate total steps for progress bar
		local sessions_array=()
		local OLD_IFS="$IFS"
		IFS=',' read -ra sessions_array <<<"$group_content"
		IFS="$OLD_IFS"
		total_steps=${#sessions_array[@]}
		current_step=0

		# Process sessions
		if [[ "$parallel" == "true" ]]; then
			log "DEBUG" "GROUP" "Using parallel mode"
			local pids=()

			for session in "${sessions_array[@]}"; do
				start_session "$session" &
				pids+=($!)
			done

			# Wait for all parallel sessions to complete
			for pid in "${pids[@]}"; do
				wait "$pid" 2>/dev/null || true
			done
		else
			# Önce uygulamaları workspace'e göre gruplandır
			declare -A workspace_sessions

			for session in "${sessions_array[@]}"; do
				local workspace=$(jq -r ".sessions.\"${session}\".workspace // \"0\"" "$CONFIG_FILE")

				# Workspace listesine ekle
				if [[ -z "${workspace_sessions[$workspace]+x}" ]]; then
					workspace_sessions[$workspace]="$session"
				else
					workspace_sessions[$workspace]="${workspace_sessions[$workspace]} $session"
				fi
			done

			# Her workspace için uygulamaları başlat
			for workspace in "${!workspace_sessions[@]}"; do
				# Skip invalid workspace
				[[ "$workspace" == "0" || "$workspace" == "null" ]] && continue

				# Switch to workspace once
				switch_workspace "$workspace"
				sleep 1

				# Start all apps in this workspace
				for session in ${workspace_sessions[$workspace]}; do
					start_session "$session"
					sleep 1
				done
			done
		fi

		# Alt gruplar için eski değeri geri yükle
		disable_final_workspace="$old_disable_final_workspace"
	fi

	local duration=$(($(date +%s) - start_time))
	log "SUCCESS" "GROUP" "Group startup complete: $group_name (Time: ${duration}s)"

	return 0
}

# Create startup script for a profile
create_startup_script() {
	local profile="$1"
	local script_path="$SCRIPTS_DIR/start-${profile,,}.sh"

	# Check if profile exists
	if ! jq -e ".sessions.\"$profile\"" "$CONFIG_FILE" >/dev/null; then
		log "ERROR" "CREATE" "Profile not found: $profile"
		return 1
	fi

	# Get basic configuration
	local command=$(jq -r ".sessions.\"$profile\".command" "$CONFIG_FILE")
	local vpn_mode=$(jq -r ".sessions.\"$profile\".vpn // \"secure\"" "$CONFIG_FILE")
	local workspace=$(jq -r ".sessions.\"$profile\".workspace // \"0\"" "$CONFIG_FILE")
	local wait_time=$(jq -r ".sessions.\"$profile\".wait_time // \"$DEFAULT_WAIT_TIME\"" "$CONFIG_FILE")
	local fullscreen=$(jq -r ".sessions.\"$profile\".fullscreen // false" "$CONFIG_FILE")
	local final_workspace=$(jq -r ".sessions.\"$profile\".final_workspace // \"$workspace\"" "$CONFIG_FILE")
	local type=$(jq -r ".sessions.\"$profile\".type // \"app\"" "$CONFIG_FILE")

	# Build command line based on app type
	local cmd_args=""

	# Handle terminal apps specially
	if [[ "$command" == "kitty" || "$command" == "wezterm" ]]; then
		# For terminal apps, extract and format args specially to handle -e properly
		local arg_count=$(jq ".sessions.\"$profile\".args | length" "$CONFIG_FILE")
		local args=()

		for ((i = 0; i < arg_count; i++)); do
			args[i]=$(jq -r ".sessions.\"$profile\".args[$i]" "$CONFIG_FILE")
		done

		# Format args for proper quoting in the script
		for arg in "${args[@]}"; do
			cmd_args+=" \"$arg\""
		done
	else
		# For other apps, format args normally
		local args=()
		readarray -t args < <(jq -r ".sessions.\"$profile\".args[]" "$CONFIG_FILE" 2>/dev/null || echo "")

		for arg in "${args[@]}"; do
			cmd_args+=" \"$arg\""
		done
	fi

	# Create scripts directory if not exists
	mkdir -p "$SCRIPTS_DIR"

	# Generate the script
	cat >"$script_path" <<EOF
#!/usr/bin/env bash
# Profile: $profile
# Type: $type
# Generated by Semsumo v$VERSION
set -euo pipefail

echo "Initializing $profile..."

# Switch to initial workspace
if [[ "$workspace" != "0" ]] && command -v hyprctl >/dev/null 2>&1; then
    # Get current workspace
    CURRENT_WORKSPACE=\$(hyprctl activeworkspace -j | grep -o '"id": [0-9]*' | grep -o '[0-9]*' || echo "")
    
    # Only switch if we're not already on the target workspace
    if [[ "\$CURRENT_WORKSPACE" != "$workspace" ]]; then
        echo "Switching to workspace $workspace..."
        hyprctl dispatch workspace "$workspace"
        sleep $wait_time
        echo "Waiting $wait_time seconds for transition..."
    else
        echo "Already on workspace $workspace, skipping switch."
    fi
fi

echo "Starting application..."
echo "COMMAND: $command$cmd_args"
echo "VPN MODE: $vpn_mode"

# Start the application with the appropriate VPN mode
case "$vpn_mode" in
    bypass)
        if command -v mullvad >/dev/null 2>&1 && mullvad status 2>/dev/null | grep -q "Connected"; then
            if command -v mullvad-exclude >/dev/null 2>&1; then
                echo "Starting with VPN bypass (mullvad-exclude)"
                mullvad-exclude $command$cmd_args &
            else
                echo "WARNING: mullvad-exclude not found, starting normally"
                $command$cmd_args &
            fi
        else
            echo "VPN not connected, starting normally"
            $command$cmd_args &
        fi
        ;;
    secure|*)
        if command -v mullvad >/dev/null 2>&1 && mullvad status 2>/dev/null | grep -q "Connected"; then
            echo "Starting with VPN protection"
        else
            echo "WARNING: VPN not connected! Starting without protection"
        fi
        $command$cmd_args &
        ;;
esac

# Save PID and wait a moment
APP_PID=\$!
mkdir -p "/tmp/sem"
echo "\$APP_PID" > "/tmp/sem/$profile.pid"
echo "Application started (PID: \$APP_PID)"

# Make fullscreen if needed
if [[ "$fullscreen" == "true" ]]; then
    echo "Waiting $wait_time seconds for application to load..."
    sleep $wait_time
    
    if command -v hyprctl >/dev/null 2>&1; then
        echo "Making fullscreen..."
        hyprctl dispatch fullscreen 1
    fi
fi

# Switch to final workspace if needed
if [[ "$final_workspace" != "0" ]]; then
    # Get current workspace again
    CURRENT_WORKSPACE=\$(hyprctl activeworkspace -j | grep -o '"id": [0-9]*' | grep -o '[0-9]*' || echo "")
    
    # Only switch if we're not already on the target final workspace
    if [[ "\$CURRENT_WORKSPACE" != "$final_workspace" ]]; then
        echo "Switching to final workspace $final_workspace..."
        if command -v hyprctl >/dev/null 2>&1; then
            hyprctl dispatch workspace "$final_workspace"
        fi
    else
        echo "Already on final workspace $final_workspace, skipping switch."
    fi
fi

exit 0
EOF

	# Make script executable
	chmod +x "$script_path"
	log "SUCCESS" "CREATE" "Created startup script: $script_path"
	return 0
}

# Generate startup scripts for all profiles
generate_startup_scripts() {
	log "INFO" "CREATE" "Generating startup scripts for all profiles..."

	if ! command_exists jq; then
		log "ERROR" "CREATE" "jq is required for script generation"
		return 1
	fi

	# Create scripts directory
	mkdir -p "$SCRIPTS_DIR"

	# Get all profiles
	local profiles=$(jq -r '.sessions | keys[]' "$CONFIG_FILE")
	local total=$(echo "$profiles" | wc -l)
	local count=0

	# Process each profile
	while IFS= read -r profile; do
		[[ -z "$profile" ]] && continue

		if create_startup_script "$profile"; then
			count=$((count + 1))
			echo -ne "\rProgress: $count/$total"
		fi
	done <<<"$profiles"
	echo ""

	log "SUCCESS" "CREATE" "Successfully generated $count/$total startup scripts"

	# Show an example
	if [[ $count -gt 0 ]]; then
		local example=$(jq -r '.sessions | keys[0]' "$CONFIG_FILE")
		echo "Example usage: $SCRIPTS_DIR/start-${example,,}.sh"
	fi

	return 0
}

# Filter sessions by type
filter_sessions_by_type() {
	local type="$1"
	jq -r ".sessions | to_entries[] | select(.value.type == \"$type\" and (.value.enabled // true) == true) | .key" "$CONFIG_FILE"
}

# Calculate total steps for progress bar
calculate_total_steps() {
	total_steps=0

	if [[ "$RUN_BROWSERS" == "true" ]]; then
		local browser_count=$(filter_sessions_by_type "browser" | wc -l)
		total_steps=$((total_steps + browser_count))
	fi

	if [[ "$RUN_TERMINALS" == "true" ]]; then
		local terminal_count=$(filter_sessions_by_type "terminal" | wc -l)
		total_steps=$((total_steps + terminal_count))
	fi

	if [[ "$RUN_APPS" == "true" ]]; then
		local app_count=$(filter_sessions_by_type "app" | wc -l)
		total_steps=$((total_steps + app_count))
	fi

	# If single profile mode, just one step
	if [[ -n "$SINGLE_PROFILE" ]]; then
		total_steps=1
	fi

	log "DEBUG" "PROGRESS" "Total steps: $total_steps"
}

# Start terminal sessions
start_terminal_sessions() {
	log "INFO" "START" "Starting terminal sessions..." "true"

	local terminals=$(filter_sessions_by_type "terminal")
	while IFS= read -r terminal; do
		[[ -z "$terminal" ]] && continue
		start_session "$terminal"
	done <<<"$terminals"

	log "SUCCESS" "START" "All terminal sessions started" "true"
}

# Start browser profiles
start_browser_profiles() {
	log "INFO" "START" "Starting browser profiles..." "true"

	# If in single profile mode
	if [[ -n "$SINGLE_PROFILE" ]]; then
		start_session "$SINGLE_PROFILE"
		return $?
	fi

	# Get ordered browser list - customize this order for your workflow
	local ordered_browsers=("Brave-Kenp" "Brave-Ai" "Brave-CompecTA" "Brave-Whats")

	# First start browsers in the specified order
	for browser in "${ordered_browsers[@]}"; do
		local exists=$(jq -r ".sessions.\"$browser\" // empty" "$CONFIG_FILE")
		if [[ -n "$exists" ]]; then
			start_session "$browser"
		fi
	done

	# Then start any remaining browsers not in the ordered list
	local browsers=$(filter_sessions_by_type "browser")
	while IFS= read -r browser; do
		[[ -z "$browser" ]] && continue

		# Skip if already started
		local already_started=false
		for ordered in "${ordered_browsers[@]}"; do
			if [[ "$browser" == "$ordered" ]]; then
				already_started=true
				break
			fi
		done

		if [[ "$already_started" == "false" ]]; then
			start_session "$browser"
		fi
	done <<<"$browsers"

	log "SUCCESS" "START" "All browser profiles started" "true"
}

# Start applications
start_applications() {
	log "INFO" "START" "Starting applications..." "true"

	# Group apps by workspace for efficiency
	declare -A workspace_apps

	# If a specific app is specified
	if [[ -n "$SINGLE_PROFILE" ]]; then
		start_session "$SINGLE_PROFILE"
		return $?
	fi

	local apps=$(filter_sessions_by_type "app")
	while IFS= read -r app; do
		[[ -z "$app" ]] && continue

		local workspace=$(jq -r ".sessions.\"$app\".workspace // \"0\"" "$CONFIG_FILE")

		# Initialize array if not already initialized
		if [[ -z "${workspace_apps[$workspace]+x}" ]]; then
			workspace_apps[$workspace]="$app"
		else
			workspace_apps[$workspace]="${workspace_apps[$workspace]} $app"
		fi
	done <<<"$apps"

	# Start apps by workspace
	for workspace in "${!workspace_apps[@]}"; do
		switch_workspace "$workspace"

		for app in ${workspace_apps[$workspace]}; do
			start_session "$app"
		done
	done

	log "SUCCESS" "START" "All applications started" "true"
}

# Show help
show_help() {
	cat <<EOF
Semsumo $VERSION - Advanced Session Manager

Usage: semsumo <command> [parameters]

Commands:
  start   <session> [vpn_mode]  Start a session
  stop    <session>             Stop a session
  restart <session> [vpn_mode]  Restart a session
  status  <session>             Show session status
  list                          List all sessions
  group   <group>               Start a group of sessions
  groups                        List all groups
  create                        Generate startup scripts for all profiles
  boot    [options]             Boot multiple session types
  help                          Show this help message

Boot Options:
  -t, --terminals               Start terminal sessions
  -b, --browsers                Start browser profiles
  -a, --apps                    Start applications
  -p, --profile PROFILE         Start a specific profile
  -w, --workspace NUMBER        Final workspace to return to
  -r, --retry NUMBER            Number of retries (default: 3)
  -d, --debug                   Enable debug mode
  -D, --dry-run                 Don't actually start anything

Global Options:
  -p, --parallel               Start group sessions in parallel
  -d, --debug                  Enable debug mode

VPN Modes:
  bypass  : Run outside VPN
  secure  : Run through VPN (default)

Examples:
  semsumo start Brave-Kenp
  semsumo start webcord bypass
  semsumo group browsers
  semsumo group all -p
  semsumo create
  semsumo boot -t -b            # Start terminals and browsers
  semsumo boot -p Brave-Kenp    # Start just one profile
  semsumo boot -w 3             # Start everything and return to workspace 3

Config: $CONFIG_FILE
Logs: $LOG_FILE
Startup Scripts: $SCRIPTS_DIR
EOF
}

# Parse boot command arguments
parse_boot_args() {
	local single_profile=""

	# Process all arguments
	while [[ $# -gt 0 ]]; do
		case "$1" in
		-t | --terminals)
			RUN_TERMINALS=true
			shift
			;;
		-b | --browsers)
			RUN_BROWSERS=true
			shift
			;;
		-a | --apps)
			RUN_APPS=true
			shift
			;;
		-p | --profile)
			if [[ $# -gt 1 ]]; then
				SINGLE_PROFILE="$2"
				log "DEBUG" "ARGS" "Single profile set to: $SINGLE_PROFILE"
				shift 2
			else
				log "ERROR" "ARGS" "Missing argument for -p/--profile"
				shift
			fi
			;;
		-w | --workspace)
			if [[ $# -gt 1 ]]; then
				FINAL_WORKSPACE="$2"
				shift 2
			else
				log "ERROR" "ARGS" "Missing argument for -w/--workspace"
				shift
			fi
			;;
		-r | --retry)
			if [[ $# -gt 1 ]]; then
				RETRY_COUNT="$2"
				shift 2
			else
				log "ERROR" "ARGS" "Missing argument for -r/--retry"
				shift
			fi
			;;
		-d | --debug)
			DEBUG=1
			shift
			;;
		-D | --dry-run)
			DRY_RUN=true
			shift
			;;
		*)
			log "WARN" "ARGS" "Unknown boot option: $1"
			shift
			;;
		esac
	done

	# If a single profile is specified, don't run session types
	if [[ -n "$SINGLE_PROFILE" ]]; then
		log "DEBUG" "ARGS" "Single profile mode enabled for: $SINGLE_PROFILE"
		RUN_TERMINALS=false
		RUN_BROWSERS=false
		RUN_APPS=false
	# If no specific category selected, run all
	elif [[ "$RUN_TERMINALS" != "true" && "$RUN_BROWSERS" != "true" && "$RUN_APPS" != "true" ]]; then
		RUN_TERMINALS=true
		RUN_BROWSERS=true
		RUN_APPS=true
	fi
}

# Boot function - starts multiple session types
boot_sessions() {
	local start_time=$(date +%s)

	log "INFO" "BOOT" "Semsumo boot process starting..." "true"

	if [[ "$DRY_RUN" == "true" ]]; then
		log "INFO" "BOOT" "Dry run mode active - no applications will be started" "true"
	fi

	# If a single profile is specified, just start that
	if [[ -n "$SINGLE_PROFILE" ]]; then
		log "INFO" "BOOT" "Starting single profile: $SINGLE_PROFILE"
		# Check if profile exists
		if ! jq -e ".sessions.\"${SINGLE_PROFILE}\"" "$CONFIG_FILE" >/dev/null; then
			log "ERROR" "BOOT" "Profile not found: $SINGLE_PROFILE"
			return 1
		fi

		start_session "$SINGLE_PROFILE"
		local result=$?

		# Calculate total time
		local end_time=$(date +%s)
		local total_time=$((end_time - start_time))

		if [[ $result -eq 0 ]]; then
			log "SUCCESS" "BOOT" "Single profile boot completed in ${total_time}s" "true"
		else
			log "ERROR" "BOOT" "Failed to start profile: $SINGLE_PROFILE" "true"
		fi

		return $result
	fi

	# Calculate total steps for progress bar
	calculate_total_steps

	# Start terminal sessions if requested
	if [[ "$RUN_TERMINALS" == "true" ]]; then
		start_terminal_sessions
	fi

	# Start browser profiles if requested
	if [[ "$RUN_BROWSERS" == "true" ]]; then
		start_browser_profiles
	fi

	# Start applications if requested
	if [[ "$RUN_APPS" == "true" ]]; then
		start_applications
	fi

	# Switch to final workspace if specified
	if [[ -n "$FINAL_WORKSPACE" ]]; then
		log "INFO" "WORKSPACE" "All applications started, returning to workspace $FINAL_WORKSPACE" "true"
		switch_workspace "$FINAL_WORKSPACE"
	else
		# Check if we have a global final workspace setting
		local global_final=$(jq -r ".settings.final_workspace // \"0\"" "$CONFIG_FILE")
		if [[ "$global_final" != "0" && "$global_final" != "null" ]]; then
			log "INFO" "WORKSPACE" "All applications started, returning to workspace $global_final" "true"
			switch_workspace "$global_final"
		fi
	fi

	# Calculate total time
	local end_time=$(date +%s)
	local total_time=$((end_time - start_time))

	# Show summary
	log "SUCCESS" "BOOT" "Boot process completed successfully - Total time: ${total_time}s" "true"

	# Show stats on started applications
	local started_count=${#APP_PIDS[@]}
	if [[ $started_count -gt 0 ]]; then
		log "INFO" "SUMMARY" "Total applications started: $started_count" "false"
	fi

	return 0
}

# Main function
main() {
	initialize

	# Parse global options first
	while [[ $# -gt 0 ]]; do
		case "$1" in
		-p | --parallel)
			PARALLEL=1
			shift
			;;
		-d | --debug)
			DEBUG=1
			shift
			;;
		*)
			# Not a global option, break to process commands
			break
			;;
		esac
	done

	# Process commands
	case "${1:-}" in
	start)
		if [[ -z "${2:-}" ]]; then
			log "ERROR" "MAIN" "Session name required"
			show_help
			exit 1
		fi
		shift # Remove the 'start' command
		local session_name="$1"
		shift                                  # Remove the session name
		start_session "$session_name" "${1:-}" # Optional VPN mode
		;;
	stop)
		if [[ -z "${2:-}" ]]; then
			log "ERROR" "MAIN" "Session name required"
			show_help
			exit 1
		fi
		stop_session "$2"
		;;
	restart)
		if [[ -z "${2:-}" ]]; then
			log "ERROR" "MAIN" "Session name required"
			show_help
			exit 1
		fi
		restart_session "$2" "${3:-}"
		;;
	status)
		if [[ -z "${2:-}" ]]; then
			log "ERROR" "MAIN" "Session name required"
			show_help
			exit 1
		fi
		check_status "$2"
		;;
	list)
		list_sessions
		;;
	group)
		if [[ -z "${2:-}" ]]; then
			log "ERROR" "MAIN" "Group name required"
			list_groups
			exit 1
		fi
		case "$2" in
		all)
			start_all_groups
			;;
		*)
			if [[ -v APP_GROUPS["$2"] ]]; then
				start_group "$2" "$([[ $PARALLEL -eq 1 ]] && echo "true" || echo "false")"
			else
				log "ERROR" "GROUP" "Invalid group: $2"
				list_groups
				exit 1
			fi
			;;
		esac
		;;
	groups)
		list_groups
		;;
	create)
		generate_startup_scripts
		;;
	boot)
		shift # Remove the 'boot' command
		parse_boot_args "$@"
		boot_sessions
		;;
	clean)
		clean_pid_files
		;;
	help | --help | -h)
		show_help
		;;
	version | --version | -v)
		echo "Semsumo v$VERSION"
		;;
	*)
		# No command or unknown command
		if [[ -z "${1:-}" ]]; then
			show_help
		else
			log "ERROR" "MAIN" "Unknown command: ${1:-}"
			show_help
		fi
		exit 1
		;;
	esac
}

# Execute main function with all arguments
main "$@"
