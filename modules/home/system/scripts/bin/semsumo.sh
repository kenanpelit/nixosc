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
readonly DEFAULT_WAIT_TIME=3
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
	["media"]="spotify"
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
      "workspace": "6",
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
	local config=$(jq -r ".sessions.\"${session_name}\"" "$CONFIG_FILE")

	local workspace=$(jq -r '.workspace // "0"' <<<"$config")
	local fullscreen=$(jq -r '.fullscreen // "false"' <<<"$config")
	local wait_time=$(jq -r '.wait_time // "'"$DEFAULT_WAIT_TIME"'"' <<<"$config")

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

	local config=$(jq -r ".sessions.\"${session_name}\"" "$CONFIG_FILE")
	local command=$(jq -r '.command' <<<"$config")
	local args=$(jq -r '.args // [] | join(" ")' <<<"$config")
	local vpn_mode=$(get_vpn_mode "$session_name" "$vpn_param")
	local vpn_active=$(check_vpn && echo true || echo false)

	# Handle workspace first
	handle_workspace "$session_name"

	# Start the application
	log "INFO" "Starting session: $session_name (VPN: $vpn_mode)"

	local pid
	case "$vpn_mode" in
	secure)
		if ! $vpn_active; then
			log "WARN" "VPN not connected. Starting $session_name without protection"
		fi
		pid=$(execute_application "$command" $args)
		;;
	bypass)
		if $vpn_active && command_exists "mullvad-exclude"; then
			log "INFO" "Starting $session_name bypassing VPN"
			pid=$(mullvad-exclude "$command" $args)
		else
			pid=$(execute_application "$command" $args)
		fi
		;;
	esac

	# Save PID if successful
	if [[ -n "$pid" && "$pid" -gt 0 ]]; then
		echo "$pid" >"$PID_DIR/${session_name}.pid"
		log "INFO" "Session started successfully: $session_name (PID: $pid)"
	else
		log "ERROR" "Failed to start session: $session_name"
		return 1
	fi

	# Wait if specified
	local wait_time=$(jq -r '.wait_time // "'"$DEFAULT_WAIT_TIME"'"' <<<"$config")
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
		local config=$(jq -r ".sessions.\"$session\"" "$CONFIG_FILE")
		local command=$(jq -r '.command' <<<"$config")
		local vpn=$(jq -r '.vpn // "secure"' <<<"$config")
		local workspace=$(jq -r '.workspace // "0"' <<<"$config")
		local wait_time=$(jq -r '.wait_time // "'"$DEFAULT_WAIT_TIME"'"' <<<"$config")
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

	if [[ ! -v APP_GROUPS["$group_name"] ]]; then
		log "ERROR" "Group not found: $group_name"
		return 1
	fi

	local start_time=$(date +%s)
	log "INFO" "Starting group: $group_name"

	# Handle meta groups
	if [[ "$group_name" == "all" ]]; then
		local subgroups=("browsers" "terminals" "communications" "media")

		for subgroup in "${subgroups[@]}"; do
			start_group "$subgroup" "$parallel"
			sleep 3
		done

		return 0
	fi

	# Split group members
	IFS=',' read -ra sessions <<<"${APP_GROUPS[$group_name]}"

	if [[ "$parallel" == "true" && ${#sessions[@]} -gt 1 ]]; then
		log "INFO" "Starting sessions in parallel"

		for session in "${sessions[@]}"; do
			(
				start_session "$session"
			) &
		done

		wait
	else
		for session in "${sessions[@]}"; do
			start_session "$session"
			sleep 2
		done
	fi

	local end_time=$(date +%s)
	local duration=$((end_time - start_time))

	log "INFO" "Group started successfully: $group_name (Duration: ${duration}s)"

	# Return to main workspace if not terminals
	if [[ "$group_name" != "terminals" ]]; then
		switch_workspace "2" "2"
	fi

	return 0
}

# Create startup script for a profile - especially for terminal apps like kitty
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
	local fullscreen=$(jq -r ".sessions.\"$profile\".fullscreen // \"false\"" "$CONFIG_FILE")
	local final_workspace=$(jq -r ".sessions.\"$profile\".final_workspace // \"$workspace\"" "$CONFIG_FILE")

	# Handle terminal apps specially
	local cmd_line=""
	if [[ "$command" == "kitty" || "$command" == "wezterm" ]]; then
		# For terminal apps, construct the command line more carefully
		cmd_line="$command"

		# Extract args one by one and add to cmd_line
		local arg_count=$(jq '.args | length' <<<"$(jq -r ".sessions.\"$profile\"" "$CONFIG_FILE")")
		for ((i = 0; i < arg_count; i++)); do
			local arg=$(jq -r ".args[$i]" <<<"$(jq -r ".sessions.\"$profile\"" "$CONFIG_FILE")")

			# Check if this is the shell command (-e argument for kitty)
			if [[ "$arg" == "-e" && $i -lt $((arg_count - 1)) ]]; then
				# Add -e and the shell command with special handling
				local shell_cmd=$(jq -r ".args[$((i + 1))]" <<<"$(jq -r ".sessions.\"$profile\"" "$CONFIG_FILE")")
				cmd_line+=" -e $shell_cmd"
				# Skip the next arg since we've already processed it
				((i++))
			else
				# Regular arg
				cmd_line+=" $arg"
			fi
		done
	else
		# For non-terminal apps, use the standard approach with arg array
		local args_array=()
		mapfile -t args_array < <(jq -r '.args[]' <<<"$(jq -r ".sessions.\"$profile\"" "$CONFIG_FILE")" 2>/dev/null)

		# Build command line
		cmd_line="$command"
		for arg in "${args_array[@]}"; do
			cmd_line+=" \"$arg\""
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
echo "COMMAND: $cmd_line"
echo "VPN MODE: $vpn_mode"

# Start the application with the appropriate VPN mode
case "$vpn_mode" in
    bypass)
        VPN_STATUS=\$(command -v mullvad >/dev/null 2>&1 && mullvad status 2>/dev/null | grep -q "Connected" && echo "connected" || echo "disconnected")
        if [[ "\$VPN_STATUS" == "connected" ]]; then
            if command -v mullvad-exclude >/dev/null 2>&1; then
                echo "VPN bypass ile başlatılıyor (mullvad-exclude)"
                mullvad-exclude $cmd_line &
            else
                echo "UYARI: mullvad-exclude bulunamadı, normal başlatılıyor"
                $cmd_line &
            fi
        else
            echo "VPN bağlı değil, normal başlatılıyor"
            $cmd_line &
        fi
        ;;
    secure|*)
        VPN_STATUS=\$(command -v mullvad >/dev/null 2>&1 && mullvad status 2>/dev/null | grep -q "Connected" && echo "connected" || echo "disconnected")
        if [[ "\$VPN_STATUS" != "connected" ]]; then
            echo "UYARI: VPN bağlı değil! Korumasız başlatılıyor"
        else
            echo "VPN koruması ile başlatılıyor"
        fi
        $cmd_line &
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
	log "INFO" "Başlatma scripti oluşturuldu: $script_path"
	return 0
}

# Generate startup scripts for all profiles
generate_startup_scripts() {
	log "INFO" "Tüm profiller için başlatma scriptleri oluşturuluyor..."

	# Check if jq is available
	if ! command -v jq &>/dev/null; then
		log "ERROR" "Script oluşturmak için jq gerekiyor"
		return 1
	fi

	# Create scripts directory
	mkdir -p "$SCRIPTS_DIR"

	# Get all profiles
	local profiles count=0 total=0
	profiles=$(jq -r '.sessions | keys[]' "$CONFIG_FILE")
	total=$(echo "$profiles" | wc -l)

	# Process each profile
	while IFS= read -r profile; do
		[[ -z "$profile" ]] && continue

		if create_startup_script "$profile"; then
			((count++))
			echo -ne "\rİlerleme: $count/$total"
		fi
	done <<<"$profiles"
	echo ""

	log "INFO" "$total profilden $count tanesi için başlatma scripti oluşturuldu"

	# Show an example
	if [[ $count -gt 0 ]]; then
		local example
		example=$(jq -r '.sessions | keys[0]' "$CONFIG_FILE")
		echo "Örnek kullanım: $SCRIPTS_DIR/start-${example,,}.sh"
	fi

	return 0
}

# Generate startup scripts for all profiles
generate_startup_scripts() {
	log_info "Tüm profiller için başlatma scriptleri oluşturuluyor..."

	# Check if jq is available
	if ! command -v jq &>/dev/null; then
		log_error "Script oluşturmak için jq gerekiyor"
		return 1
	fi

	# Create scripts directory
	mkdir -p "$SCRIPTS_DIR"

	# Get all profiles
	local profiles count=0 total=0
	profiles=$(jq -r '.sessions | keys[]' "$CONFIG_FILE")
	total=$(echo "$profiles" | wc -l)

	# Process each profile
	while IFS= read -r profile; do
		[[ -z "$profile" ]] && continue

		if create_startup_script "$profile"; then
			((count++))
			echo -ne "\rİlerleme: $count/$total"
		fi
	done <<<"$profiles"
	echo ""

	log_success "$total profilden $count tanesi için başlatma scripti oluşturuldu"

	# Show an example
	if [[ $count -gt 0 ]]; then
		local example
		example=$(jq -r '.sessions | keys[0]' "$CONFIG_FILE")
		echo "Örnek kullanım: $SCRIPTS_DIR/start-${example,,}.sh"
	fi

	return 0
}

# Generate startup scripts for all profiles
generate_startup_scripts() {
	log "INFO" "Generating startup scripts for all profiles..."

	if ! command_exists jq; then
		log "ERROR" "jq is required for script generation"
		return 1
	fi

	local profiles=$(jq -r '.sessions | keys[]' "$CONFIG_FILE")
	local total=$(echo "$profiles" | wc -l)
	local count=0

	while IFS= read -r profile; do
		if create_startup_script "$profile"; then
			count=$((count + 1))
		fi
	done <<<"$profiles"

	log "INFO" "Successfully generated $count/$total startup scripts"
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

	case "${1:-}" in
	start)
		[[ -z "${2:-}" ]] && {
			log "ERROR" "Session name required"
			show_help
			exit 1
		}
		start_session "$2" "${3:-}"
		;;
	stop)
		[[ -z "${2:-}" ]] && {
			log "ERROR" "Session name required"
			show_help
			exit 1
		}
		stop_session "$2"
		;;
	restart)
		[[ -z "${2:-}" ]] && {
			log "ERROR" "Session name required"
			show_help
			exit 1
		}
		restart_session "$2" "${3:-}"
		;;
	status)
		[[ -z "${2:-}" ]] && {
			log "ERROR" "Session name required"
			show_help
			exit 1
		}
		check_status "$2"
		;;
	list) list_sessions ;;
	group)
		[[ -z "${2:-}" ]] && {
			log "ERROR" "Group name required"
			list_groups
			exit 1
		}
		start_group "$2" "$([[ $PARALLEL -eq 1 ]] && echo "true" || echo "false")"
		;;
	groups) list_groups ;;
	create) generate_startup_scripts ;;
	help | --help | -h) show_help ;;
	version | --version | -v) echo "Semsumo v$VERSION" ;;
	*)
		show_help
		exit 1
		;;
	esac
}

# Run the script
main "$@"
