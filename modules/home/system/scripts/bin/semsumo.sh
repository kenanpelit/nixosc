#!/usr/bin/env bash

#######################################
# Semsumo - Advanced Session Manager
# Version: 4.3.0
# Author: Kenan Pelit
# Description: Robust session manager with VPN integration
#######################################

# Strict mode
set -euo pipefail
IFS=$'\n\t'

# Configuration
readonly VERSION="4.3.0"
readonly CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/sem"
readonly CONFIG_FILE="$CONFIG_DIR/config.json"
readonly PID_DIR="/tmp/sem"
readonly LOG_FILE="/tmp/sem/semsumo.log"
readonly SCRIPTS_DIR="$HOME/.nixosc/modules/home/system/scripts/start"
readonly DEFAULT_WAIT_TIME=1
readonly DEFAULT_FULLSCREEN_WAIT=2
readonly DEFAULT_SWITCH_WAIT=1

# Color definitions
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly MAGENTA='\033[0;35m'
readonly NC='\033[0m'

# Global variables
DEBUG=0
CREATE_MODE=0
PARALLEL=0
CURRENT_WORKSPACE=""

## Embedded group definitions
#declare -A APP_GROUPS=(
#	["browsers"]="Brave-Kenp,Brave-CompecTA,Brave-Ai,Brave-Whats,Chrome-Kenp,Chrome-CompecTA,Chrome-AI,Chrome-Whats"
#	["terminals"]="kkenp,mkenp,wkenp,wezterm,kitty-single,wezterm-rmpc"
#	["communications"]="discord,webcord,Brave-Discord,Brave-Whatsapp,Zen-Discord,Zen-Whats"
#	["media"]="spotify,mpv,Brave-Yotube,Brave-Tiktok,Brave-Spotify,Zen-Spotify"
#	["zen"]="Zen-Kenp,Zen-CompecTA,Zen-NoVpn,Zen-Proxy"
#	["all"]="browsers terminals communications media zen"
#)

# Embedded group definitions
declare -A APP_GROUPS=(
	["browsers"]="Brave-Kenp,Brave-CompecTA,Brave-Ai,Brave-Whats"
	["terminals"]="kkenp"
	["communications"]="webcord"
	["media"]="spotify,Brave-Yotube"
	["all"]="browsers communications media terminals"
)

# Initialize environment
initialize() {
	mkdir -p "$CONFIG_DIR" "$PID_DIR" "/tmp/sem"
	touch "$LOG_FILE"

	if [[ ! -f "$CONFIG_FILE" ]]; then
		cat >"$CONFIG_FILE" <<'EOF'
{
  "sessions": {
    "kkenp": {
      "command": "kitty",
      "args": ["--class", "TmuxKenp", "-T", "Tmux", "-e", "tm"],
      "vpn": "bypass",
      "workspace": "2",
      "wait_time": 1
    },
    "mkenp": {
      "command": "kitty",
      "args": ["--class", "TmuxKenp", "-T", "Tmux", "-e", "tm"],
      "vpn": "secure",
      "workspace": "2",
      "wait_time": 1
    },
    "wkenp": {
      "command": "wezterm",
      "args": ["start", "--class", "TmuxKenp", "-e", "tm"],
      "vpn": "bypass",
      "workspace": "2",
      "wait_time": 1
    },
    "wezterm": {
      "command": "wezterm",
      "args": ["start", "--class", "wezterm"],
      "vpn": "secure",
      "workspace": "2",
      "wait_time": 1
    },
    "kitty-single": {
      "command": "kitty",
      "args": ["--class", "kitty", "-T", "kitty", "--single-instance"],
      "vpn": "secure",
      "workspace": "2",
      "wait_time": 1
    },
    "wezterm-rmpc": {
      "command": "wezterm",
      "args": ["start", "--class", "rmpc", "-e", "rmpc"],
      "vpn": "secure",
      "wait_time": 1
    },
    "discord": {
      "command": "discord",
      "args": ["-m", "--class=discord", "--title=discord"],
      "vpn": "bypass",
      "workspace": "5",
      "fullscreen": true,
      "final_workspace": "2",
      "wait_time": 1
    },
    "webcord": {
      "command": "webcord",
      "args": ["-m", "--class=WebCord", "--title=Webcord"],
      "vpn": "secure",
      "workspace": "5",
      "fullscreen": true,
      "wait_time": 1
    },
    "Chrome-Kenp": {
      "command": "profile_chrome",
      "args": ["Kenp", "--class", "Kenp"],
      "vpn": "secure",
      "workspace": "1",
      "wait_time": 1
    },
    "Chrome-CompecTA": {
      "command": "profile_chrome",
      "args": ["CompecTA", "--class", "CompecTA"],
      "vpn": "secure",
      "workspace": "4",
      "wait_time": 1
    },
    "Chrome-AI": {
      "command": "profile_chrome",
      "args": ["AI", "--class", "AI"],
      "vpn": "secure",
      "workspace": "3",
      "wait_time": 1
    },
    "Chrome-Whats": {
      "command": "profile_chrome",
      "args": ["Whats", "--class", "Whats"],
      "vpn": "secure",
      "workspace": "9",
      "wait_time": 1
    },
    "Brave-Kenp": {
      "command": "profile_brave",
      "args": ["Kenp"],
      "vpn": "secure",
      "workspace": "1",
      "wait_time": 1
    },
    "Brave-CompecTA": {
      "command": "profile_brave",
      "args": ["CompecTA"],
      "vpn": "secure",
      "workspace": "4",
      "wait_time": 1
    },
    "Brave-Ai": {
      "command": "profile_brave",
      "args": ["Ai"],
      "vpn": "secure",
      "workspace": "3",
      "wait_time": 1
    },
    "Brave-Whats": {
      "command": "profile_brave",
      "args": ["Whats"],
      "vpn": "secure",
      "workspace": "9",
      "wait_time": 1
    },
    "Brave-Exclude": {
      "command": "profile_brave",
      "args": ["Exclude"],
      "vpn": "bypass",
      "workspace": "6",
      "wait_time": 1
    },
    "Brave-Yotube": {
      "command": "profile_brave",
      "args": ["--youtube"],
      "vpn": "secure",
      "workspace": "7",
      "fullscreen": true,
      "wait_time": 1
    },
    "Brave-Tiktok": {
      "command": "profile_brave",
      "args": ["--tiktok"],
      "vpn": "secure",
      "workspace": "6",
      "fullscreen": true,
      "wait_time": 1
    },
    "Brave-Spotify": {
      "command": "profile_brave",
      "args": ["--spotify"],
      "vpn": "secure",
      "workspace": "8",
      "fullscreen": true,
      "wait_time": 1
    },
    "Brave-Discord": {
      "command": "profile_brave",
      "args": ["--discord"],
      "vpn": "secure",
      "workspace": "5",
      "final_workspace": "2",
      "wait_time": 1,
      "fullscreen": true
    },
    "Brave-Whatsapp": {
      "command": "profile_brave",
      "args": ["--whatsapp"],
      "vpn": "secure",
      "workspace": "9",
      "fullscreen": true,
      "wait_time": 1
    },
    "Zen-Kenp": {
      "command": "zen",
      "args": ["-P", "Kenp", "--class", "Kenp", "--name", "Kenp", "--restore-session"],
      "vpn": "secure",
      "workspace": "1",
      "wait_time": 1
    },
    "Zen-CompecTA": {
      "command": "zen",
      "args": ["-P", "CompecTA", "--class", "CompecTA", "--name", "CompecTA", "--restore-session"],
      "vpn": "secure",
      "workspace": "4",
      "wait_time": 1
    },
    "Zen-Discord": {
      "command": "zen",
      "args": ["-P", "Discord", "--class", "Discord", "--name", "Discord", "--restore-session"],
      "vpn": "secure",
      "workspace": "5",
      "fullscreen": true,
      "wait_time": 1
    },
    "Zen-NoVpn": {
      "command": "zen",
      "args": ["-P", "NoVpn", "--class", "AI", "--name", "AI", "--restore-session"],
      "vpn": "bypass",
      "workspace": "3",
      "wait_time": 1
    },
    "Zen-Proxy": {
      "command": "zen",
      "args": ["-P", "Proxy", "--class", "Proxy", "--name", "Proxy", "--restore-session"],
      "vpn": "bypass",
      "workspace": "7",
      "wait_time": 1
    },
    "Zen-Spotify": {
      "command": "zen",
      "args": ["-P", "Spotify", "--class", "Spotify", "--name", "Spotify", "--restore-session"],
      "vpn": "bypass",
      "workspace": "7",
      "fullscreen": true,
      "wait_time": 1
    },
    "Zen-Whats": {
      "command": "zen",
      "args": ["-P", "Whats", "--class", "Whats", "--name", "Whats", "--restore-session"],
      "vpn": "secure",
      "workspace": "9",
      "fullscreen": true,
      "wait_time": 1
    },
    "spotify": {
      "command": "spotify",
      "args": ["--class", "Spotify", "-T", "Spotify"],
      "vpn": "bypass",
      "workspace": "8",
      "fullscreen": true,
      "wait_time": 1
    },
    "mpv": {
      "command": "mpv",
      "args": [],
      "vpn": "bypass",
      "workspace": "6",
      "fullscreen": true,
      "wait_time": 1
    }
  }
}
EOF
		chmod 600 "$CONFIG_FILE"
	fi
}

# Logging functions
log() {
	local level="$1"
	local message="$2"
	local timestamp=$(date +"%Y-%m-%d %T")

	case "$level" in
	"INFO") echo -e "${GREEN}[INFO]${NC} $message" ;;
	"WARN") echo -e "${YELLOW}[WARN]${NC} $message" ;;
	"ERROR") echo -e "${RED}[ERROR]${NC} $message" ;;
	"DEBUG") [[ $DEBUG -eq 1 ]] && echo -e "${CYAN}[DEBUG]${NC} $message" ;;
	*) echo -e "[$level] $message" ;;
	esac

	echo "[$timestamp][$level] $message" >>"$LOG_FILE"
}

# Shortcut log functions for backward compatibility
log_info() { log "INFO" "$1"; }
log_warn() { log "WARN" "$1"; }
log_error() { log "ERROR" "$1"; }
log_debug() { log "DEBUG" "$1"; }
log_success() { log "INFO" "$1"; }

# Check if command exists
command_exists() {
	command -v "$1" >/dev/null 2>&1
}

# Check VPN status
check_vpn() {
	if ! command_exists "mullvad"; then
		log "WARN" "Mullvad VPN not installed"
		return 1
	fi

	if mullvad status 2>/dev/null | grep -q "Connected"; then
		log "DEBUG" "VPN is connected"
		return 0
	fi

	log "DEBUG" "VPN is not connected"
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
		log "ERROR" "Invalid VPN mode: $cli_mode. Use 'secure' or 'bypass'"
		return 1
		;;
	esac
}

# Switch workspace reliably
switch_workspace() {
	local workspace="$1"
	local wait_time="${2:-$DEFAULT_SWITCH_WAIT}"

	# Skip if workspace is not specified or already there
	[[ -z "$workspace" || "$workspace" == "0" || "$workspace" == "null" ]] && return 0
	[[ "$CURRENT_WORKSPACE" == "$workspace" ]] && return 0

	if ! command_exists "hyprctl"; then
		log "WARN" "hyprctl not found, workspace switching disabled"
		return 1
	fi

	log "INFO" "Switching to workspace $workspace"
	if ! hyprctl dispatch workspace "$workspace" >/dev/null 2>&1; then
		log "ERROR" "Failed to switch to workspace $workspace"
		return 1
	fi

	CURRENT_WORKSPACE="$workspace"
	sleep "$wait_time"
	return 0
}

# Handle final workspace if specified
handle_final_workspace() {
	local session_name="$1"
	local final_workspace=$(jq -r ".sessions.\"${session_name}\".final_workspace // \"0\"" "$CONFIG_FILE")

	if [[ "$final_workspace" != "0" && "$final_workspace" != "null" ]]; then
		log "INFO" "Switching to final workspace $final_workspace"
		switch_workspace "$final_workspace"
	fi
}

# Make application fullscreen
make_fullscreen() {
	local wait_time="${1:-$DEFAULT_FULLSCREEN_WAIT}"

	if ! command_exists "hyprctl"; then
		log "WARN" "hyprctl not found, fullscreen disabled"
		return 1
	fi

	log "INFO" "Making application fullscreen"
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

# Execute application with proper error handling
execute_application() {
	local cmd="$1"
	shift
	local -a args=("$@")

	log "DEBUG" "Executing: $cmd ${args[*]}"

	if ! command_exists "$cmd"; then
		log "ERROR" "Command not found: $cmd"
		return 1
	fi

	# Special handling for specific applications
	case "$cmd" in
	webcord | spotify | discord | mpv)
		"$cmd" "${args[@]}" >/dev/null 2>&1 &
		;;
	*)
		nohup "$cmd" "${args[@]}" >/dev/null 2>&1 &
		;;
	esac

	local pid=$!

	# Verify the process is running
	if ! kill -0 "$pid" 2>/dev/null; then
		log "ERROR" "Failed to start process: $cmd"
		return 1
	fi

	echo "$pid"
	return 0
}

# Start session with all features
start_session() {
	local session_name="$1"
	local vpn_param="${2:-}"

	# Check if session exists
	if ! jq -e ".sessions.\"${session_name}\"" "$CONFIG_FILE" >/dev/null; then
		log "ERROR" "Session not found: $session_name"
		return 1
	fi

	local command=$(jq -r ".sessions.\"${session_name}\".command" "$CONFIG_FILE")
	local vpn_mode=$(get_vpn_mode "$session_name" "$vpn_param")
	local vpn_active=false
	if check_vpn; then
		vpn_active=true
	fi

	# Handle workspace first
	handle_workspace "$session_name"

	# Start the application
	log "INFO" "Starting session: $session_name (VPN: $vpn_mode)"

	local pid
	# Get args as individual items to handle spaces and special characters correctly
	local args=()
	while IFS= read -r arg; do
		[[ -n "$arg" ]] && args+=("$arg")
	done < <(jq -r ".sessions.\"${session_name}\".args[]?" "$CONFIG_FILE")

	log "DEBUG" "Command: $command, Args: ${args[*]}"

	case "$vpn_mode" in
	secure)
		if ! $vpn_active; then
			log "WARN" "VPN not connected. Starting $session_name without protection"
		fi
		pid=$(execute_application "$command" "${args[@]}")
		;;
	bypass)
		# Special cases that shouldn't use mullvad-exclude
		local no_exclude_apps=("spotify" "kkenp" "webcord" "discord")

		if [[ " ${no_exclude_apps[*]} " =~ " $command " ]] || ! $vpn_active || ! command_exists "mullvad-exclude"; then
			if [[ " ${no_exclude_apps[*]} " =~ " $command " ]]; then
				log "INFO" "$command detected - using normal start instead of bypass"
			elif ! $vpn_active; then
				log "INFO" "VPN not active, starting $session_name normally"
			else
				log "WARN" "mullvad-exclude not found, starting $session_name normally"
			fi
			pid=$(execute_application "$command" "${args[@]}")
		else
			log "INFO" "Starting $session_name bypassing VPN"
			# Try mullvad-exclude with timeout and prevent duplicate starts
			if ! pid=$(timeout 10s mullvad-exclude "$command" "${args[@]}"); then
				log "WARN" "mullvad-exclude timed out for $session_name"
				return 1 # Don't fallback to prevent duplicates
			fi
		fi
		;;
	esac

	# Save PID if successful
	if [[ -n "$pid" && "$pid" -gt 0 ]]; then
		mkdir -p "$PID_DIR"
		echo "$pid" >"$PID_DIR/${session_name}.pid"
		log "INFO" "Session started successfully: $session_name (PID: $pid)"
	else
		log "ERROR" "Failed to start session: $session_name"
		return 1
	fi

	# Wait if specified
	local wait_time=$(jq -r ".sessions.\"${session_name}\".wait_time // \"$DEFAULT_WAIT_TIME\"" "$CONFIG_FILE")
	sleep "$wait_time"

	# Handle final workspace if specified
	handle_final_workspace "$session_name"

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

	if [[ -f "$pid_file" ]]; then
		local pid=$(cat "$pid_file")

		if kill "$pid" 2>/dev/null; then
			rm -f "$pid_file"
			log "INFO" "Session stopped: $session_name"
			return 0
		fi
	fi

	log "WARN" "No running session found: $session_name"
	return 1
}

# Restart session
restart_session() {
	local session_name="$1"
	local vpn_param="${2:-}"

	log "INFO" "Restarting session: $session_name"

	if stop_session "$session_name"; then
		sleep 2
	else
		log "WARN" "Session not running, starting fresh: $session_name"
	fi

	start_session "$session_name" "$vpn_param"
	return $?
}

# List all sessions
list_sessions() {
	log "INFO" "Available sessions:"

	jq -r '.sessions | keys[]' "$CONFIG_FILE" | while read -r session; do
		local command=$(jq -r ".sessions.\"$session\".command" "$CONFIG_FILE")
		local vpn=$(jq -r ".sessions.\"$session\".vpn // \"secure\"" "$CONFIG_FILE")
		local workspace=$(jq -r ".sessions.\"$session\".workspace // \"0\"" "$CONFIG_FILE")
		local wait_time=$(jq -r ".sessions.\"$session\".wait_time // \"$DEFAULT_WAIT_TIME\"" "$CONFIG_FILE")
		local status=$(check_status "$session")

		printf "${GREEN}%s${NC}: " "$session"

		if [[ "$status" == "running" ]]; then
			printf "[${GREEN}RUNNING${NC}] "
		else
			printf "[${RED}STOPPED${NC}] "
		fi

		printf "Command: ${BLUE}%s${NC}, " "$command"
		printf "VPN: ${CYAN}%s${NC}, " "$vpn"
		printf "Workspace: ${YELLOW}%s${NC}, " "$workspace"
		printf "Wait: ${MAGENTA}%ss${NC}\n" "$wait_time"
	done
}

# List all groups
list_groups() {
	log "INFO" "Available groups:"

	for group in "${!APP_GROUPS[@]}"; do
		printf "${GREEN}%s${NC}: " "$group"

		if [[ "$group" == "all" ]]; then
			printf "${YELLOW}%s${NC} (meta group)\n" "${APP_GROUPS[$group]}"
		else
			printf "${CYAN}%s${NC}\n" "${APP_GROUPS[$group]}"
		fi
	done
}

# Start a group of sessions
start_group() {
	local group_name="$1"
	local parallel="${2:-false}"

	# Check if group exists
	if [[ ! -v APP_GROUPS["$group_name"] ]]; then
		log "ERROR" "Group not found: $group_name"
		return 1
	fi

	local group_content="${APP_GROUPS[$group_name]}"
	local start_time=$(date +%s)

	# Handle meta group "all"
	if [[ "$group_name" == "all" ]]; then
		log "INFO" "Starting meta group: $group_name"

		local subgroups=(browsers terminals communications media)
		for subgroup in "${subgroups[@]}"; do
			if [[ -v APP_GROUPS["$subgroup"] ]]; then
				log "INFO" "Starting subgroup: $subgroup"
				start_group "$subgroup" "$parallel"
				sleep 2
			fi
		done
	else
		log "INFO" "Starting group: $group_name ($group_content)"

		# Process comma-separated session list
		IFS=',' read -ra sessions <<<"$group_content"

		if [[ "$parallel" == "true" ]]; then
			log "DEBUG" "Using parallel mode"
			local pids=()

			for session in "${sessions[@]}"; do
				start_session "$session" &
				pids+=($!)
			done

			# Wait for all parallel sessions to complete
			for pid in "${pids[@]}"; do
				wait "$pid" 2>/dev/null || true
			done
		else
			for session in "${sessions[@]}"; do
				start_session "$session"
				sleep 2
			done
		fi
	fi

	local duration=$(($(date +%s) - start_time))
	log "INFO" "Group startup complete: $group_name (Time: ${duration}s)"

	return 0
}

# Create startup script for a profile
create_startup_script() {
	local profile="$1"
	local script_path="$SCRIPTS_DIR/start-${profile,,}.sh"

	# Check if profile exists
	if ! jq -e ".sessions.\"$profile\"" "$CONFIG_FILE" >/dev/null; then
		log "ERROR" "Profile not found: $profile"
		return 1
	fi

	# Get basic configuration
	local command=$(jq -r ".sessions.\"$profile\".command" "$CONFIG_FILE")
	local vpn_mode=$(jq -r ".sessions.\"$profile\".vpn // \"secure\"" "$CONFIG_FILE")
	local workspace=$(jq -r ".sessions.\"$profile\".workspace // \"0\"" "$CONFIG_FILE")
	local wait_time=$(jq -r ".sessions.\"$profile\".wait_time // \"$DEFAULT_WAIT_TIME\"" "$CONFIG_FILE")
	local fullscreen=$(jq -r ".sessions.\"$profile\".fullscreen // false" "$CONFIG_FILE")
	local final_workspace=$(jq -r ".sessions.\"$profile\".final_workspace // \"$workspace\"" "$CONFIG_FILE")

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
set -euo pipefail

echo "Initializing $profile..."

# Switch to initial workspace
if [[ "$workspace" != "0" ]] && command -v hyprctl >/dev/null 2>&1; then
    echo "Workspace ${workspace}'e geçiliyor..."
    hyprctl dispatch workspace "${workspace}"
    sleep $wait_time
    echo "Geçiş için $wait_time saniye bekleniyor..."
fi

echo "Uygulama başlatılıyor..."
echo "COMMAND: $command$cmd_args"
echo "VPN MODE: $vpn_mode"

# Start the application with the appropriate VPN mode
case "$vpn_mode" in
    bypass)
        if command -v mullvad >/dev/null 2>&1 && mullvad status 2>/dev/null | grep -q "Connected"; then
            if command -v mullvad-exclude >/dev/null 2>&1; then
                echo "VPN bypass ile başlatılıyor (mullvad-exclude)"
                mullvad-exclude $command$cmd_args &
            else
                echo "UYARI: mullvad-exclude bulunamadı, normal başlatılıyor"
                $command$cmd_args &
            fi
        else
            echo "VPN bağlı değil, normal başlatılıyor"
            $command$cmd_args &
        fi
        ;;
    secure|*)
        if command -v mullvad >/dev/null 2>&1 && mullvad status 2>/dev/null | grep -q "Connected"; then
            echo "VPN koruması ile başlatılıyor"
        else
            echo "UYARI: VPN bağlı değil! Korumasız başlatılıyor"
        fi
        $command$cmd_args &
        ;;
esac

# Save PID and wait a moment
APP_PID=\$!
mkdir -p "/tmp/sem"
echo "\$APP_PID" > "/tmp/sem/$profile.pid"
echo "Uygulama başlatıldı (PID: \$APP_PID)"

# Make fullscreen if needed
if [[ "$fullscreen" == "true" ]]; then
    echo "Uygulama yüklenmesi için $wait_time saniye bekleniyor..."
    sleep $wait_time
    
    if command -v hyprctl >/dev/null 2>&1; then
        echo "Tam ekran yapılıyor..."
        hyprctl dispatch fullscreen 1
    fi
fi

# Switch to final workspace if needed
if [[ "$final_workspace" != "0" && "$final_workspace" != "$workspace" ]]; then
    echo "Son workspace'e geçiliyor..."
    if command -v hyprctl >/dev/null 2>&1; then
        hyprctl dispatch workspace "$final_workspace"
    fi
fi

exit 0
EOF

	# Make script executable
	chmod +x "$script_path"
	log "INFO" "Created startup script: $script_path"
	return 0
}

# Generate startup scripts for all profiles
generate_startup_scripts() {
	log "INFO" "Generating startup scripts for all profiles..."

	if ! command_exists jq; then
		log "ERROR" "jq is required for script generation"
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

	log "INFO" "Successfully generated $count/$total startup scripts"

	# Show an example
	if [[ $count -gt 0 ]]; then
		local example=$(jq -r '.sessions | keys[0]' "$CONFIG_FILE")
		echo "Example usage: $SCRIPTS_DIR/start-${example,,}.sh"
	fi

	return 0
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
  help                          Show this help message

Options:
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

Config: $CONFIG_FILE
Logs: $LOG_FILE
Startup Scripts: $SCRIPTS_DIR
EOF
}

# Main function
main() {
	initialize

	# Parse options
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
		*) break ;;
		esac
	done

	# Process commands
	case "${1:-}" in
	start)
		if [[ -z "${2:-}" ]]; then
			log "ERROR" "Session name required"
			show_help
			exit 1
		fi
		start_session "$2" "${3:-}"
		;;
	stop)
		if [[ -z "${2:-}" ]]; then
			log "ERROR" "Session name required"
			show_help
			exit 1
		fi
		stop_session "$2"
		;;
	restart)
		if [[ -z "${2:-}" ]]; then
			log "ERROR" "Session name required"
			show_help
			exit 1
		fi
		restart_session "$2" "${3:-}"
		;;
	status)
		if [[ -z "${2:-}" ]]; then
			log "ERROR" "Session name required"
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
			log "ERROR" "Group name required"
			list_groups
			exit 1
		fi
		# Use parallel mode if specified
		if [[ $PARALLEL -eq 1 ]]; then
			start_group "$2" "true"
		else
			start_group "$2" "false"
		fi
		;;
	groups)
		list_groups
		;;
	create)
		generate_startup_scripts
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
			log "ERROR" "Unknown command: ${1:-}"
			show_help
		fi
		exit 1
		;;
	esac
}

# Execute main function with all arguments
main "$@"
