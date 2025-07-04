#!/usr/bin/env bash

#===============================================================================
#
#   Script: Semsumo - Enhanced Application Launcher & Generator (GNOME Edition)
#   Version: 7.0.0-gnome-workspace-fixed
#   Date: 2025-07-04
#   Description: Unified system for launching applications and generating
#                startup scripts with multi-browser support for GNOME/Wayland
#
#   Features:
#   - Direct application launching with workspace management
#   - Startup script generation for all profiles
#   - Multi-browser support (Brave, Zen, Chrome)
#   - VPN bypass/secure mode support
#   - Terminal session management
#   - Parallel startup capabilities
#   - Config-free operation (no external config files needed)
#   - GNOME/Wayland native workspace switching
#   - Enhanced display management for multi-monitor setups
#   - FIXED: Proper workspace switching BEFORE app launch
#
#===============================================================================

#-------------------------------------------------------------------------------
# Configuration and Constants
#-------------------------------------------------------------------------------

readonly SCRIPT_NAME=$(basename "$0")
readonly VERSION="7.0.0-gnome-workspace-fixed"
readonly SCRIPTS_DIR="$HOME/.nixosc/modules/home/system/scripts/gnome"
readonly LOG_DIR="$HOME/.logs/semsumo"
readonly LOG_FILE="$LOG_DIR/semsumo.log"
readonly DEFAULT_FINAL_WORKSPACE="2"
readonly DEFAULT_WAIT_TIME=3

# Colors
if [[ -t 1 ]]; then
	readonly RED='\033[0;31m'
	readonly GREEN='\033[0;32m'
	readonly YELLOW='\033[1;33m'
	readonly BLUE='\033[0;34m'
	readonly PURPLE='\033[0;35m'
	readonly CYAN='\033[0;36m'
	readonly BOLD='\033[1m'
	readonly NC='\033[0m'
else
	readonly RED='' GREEN='' YELLOW='' BLUE='' PURPLE='' CYAN='' BOLD='' NC=''
fi

# Operation modes
MODE_GENERATE=false
MODE_LAUNCH=false
MODE_LIST=false
MODE_CLEAN=false
RUN_TERMINALS=false
RUN_BROWSER=false
RUN_APPS=false
SINGLE_PROFILE=""
DEBUG_MODE=false
DRY_RUN=false
WAIT_TIME=$DEFAULT_WAIT_TIME
FINAL_WORKSPACE=$DEFAULT_FINAL_WORKSPACE
BROWSER_TYPE="brave"
LAUNCH_ALL=false
LAUNCH_TYPE=""
BROWSER_ONLY=false
LAUNCH_DAILY=false

# Daily/Essential profiles list
declare -A DAILY_PROFILES=(
	["kkenp"]="TERMINALS"
	["brave-kenp"]="BRAVE_BROWSERS"
	["brave-ai"]="BRAVE_BROWSERS"
	["brave-compecta"]="BRAVE_BROWSERS"
	["brave-youtube"]="BRAVE_BROWSERS"
	["discord"]="APPS"
	["spotify"]="APPS"
	["ferdium"]="APPS"
)

#-------------------------------------------------------------------------------
# Application Definitions
#-------------------------------------------------------------------------------

# Terminal Applications
declare -A TERMINALS=(
	["kkenp"]="kitty|--class TmuxKenp -T Tmux -e tm|2|secure|1|false"
	["mkenp"]="kitty|--class TmuxKenp -T Tmux -e tm|2|secure|1|false"
	["wkenp"]="wezterm|start --class TmuxKenp -e tm|2|bypass|1|false"
	["wezterm"]="wezterm|start --class wezterm|2|secure|1|false"
	["kitty-single"]="kitty|--class kitty -T kitty --single-instance|2|secure|1|false"
	["wezterm-rmpc"]="wezterm|start --class rmpc -e rmpc|0|secure|1|false"
)

# Browser Applications - Brave
declare -A BRAVE_BROWSERS=(
	["brave-kenp"]="profile_brave|Kenp --restore-last-session|1|secure|2|false"
	["brave-ai"]="profile_brave|Ai --restore-last-session|3|secure|2|false"
	["brave-compecta"]="profile_brave|CompecTA --restore-last-session|4|secure|2|false"
	["brave-whats"]="profile_brave|Whats --restore-last-session|9|secure|1|false"
	["brave-exclude"]="profile_brave|Exclude --restore-last-session|6|bypass|1|false"
	["brave-youtube"]="profile_brave|--youtube --class youtube --title youtube|7|secure|1|true"
	["brave-tiktok"]="profile_brave|--tiktok --class tiktok --title tiktok|6|secure|1|true"
	["brave-spotify"]="profile_brave|--spotify --class spotify --title spotify|8|secure|1|true"
	["brave-discord"]="profile_brave|--discord --class discord --title discord|5|secure|1|true"
	["brave-whatsapp"]="profile_brave|--whatsapp --class whatsapp --title whatsapp|9|secure|1|true"
)

# Browser Applications - Zen
declare -A ZEN_BROWSERS=(
	["zen-kenp"]="zen|-P Kenp --class Kenp --name Kenp --restore-session|1|secure|1|false"
	["zen-novpn"]="zen|-P NoVpn --class AI --name AI --restore-session|3|bypass|1|false"
	["zen-compecta"]="zen|-P CompecTA --class CompecTA --name CompecTA --restore-session|4|secure|1|false"
	["zen-discord"]="zen|-P Discord --class Discord --name Discord --restore-session|5|secure|1|true"
	["zen-proxy"]="zen|-P Proxy --class Proxy --name Proxy --restore-session|7|bypass|1|false"
	["zen-spotify"]="zen|-P Spotify --class Spotify --name Spotify --restore-session|7|bypass|1|true"
	["zen-whats"]="zen|-P Whats --class Whats --name Whats --restore-session|9|secure|1|true"
)

# Browser Applications - Chrome
declare -A CHROME_BROWSERS=(
	["chrome-kenp"]="profile_chrome|Kenp --class Kenp|1|secure|1|false"
	["chrome-compecta"]="profile_chrome|CompecTA --class CompecTA|4|secure|1|false"
	["chrome-ai"]="profile_chrome|AI --class AI|3|secure|1|false"
	["chrome-whats"]="profile_chrome|Whats --class Whats|9|secure|1|false"
)

# Applications
declare -A APPS=(
	["discord"]="discord|-m --class=discord --title=discord|5|secure|1|true"
	["webcord"]="webcord|-m --class=WebCord --title=Webcord|5|secure|1|true"
	["spotify"]="spotify|--class Spotify -T Spotify|8|bypass|1|true"
	["mpv"]="mpv|--player-operation-mode=pseudo-gui --input-ipc-server=/tmp/mpvsocket|6|bypass|1|true"
	["ferdium"]="ferdium||9|secure|1|true"
)

#-------------------------------------------------------------------------------
# Helper Functions
#-------------------------------------------------------------------------------

log() {
	local level="$1"
	local module="${2:-MAIN}"
	local message="$3"
	local notify="${4:-false}"
	local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
	local color=""

	case "$level" in
	"INFO") color=$BLUE ;;
	"SUCCESS") color=$GREEN ;;
	"WARN") color=$YELLOW ;;
	"ERROR") color=$RED ;;
	"DEBUG") color=$PURPLE ;;
	esac

	echo -e "${color}${BOLD}[$level]${NC} ${PURPLE}[$module]${NC} $message"

	mkdir -p "$LOG_DIR"
	echo "[$timestamp] [$level] [$module] $message" >>"$LOG_FILE"

	if [[ "$notify" == "true" && -x "$(command -v notify-send)" ]]; then
		notify-send -a "$SCRIPT_NAME" "$module: $message"
	fi
}

setup_external_monitor() {
	if [[ "$DRY_RUN" == "true" ]]; then
		return 0
	fi

	if command -v xrandr >/dev/null 2>&1; then
		# Try to detect external monitor and make it primary
		local external_monitor=$(xrandr --query | grep " connected" | grep -v "eDP" | head -1 | awk '{print $1}')
		if [[ -n "$external_monitor" ]]; then
			log "INFO" "DISPLAY" "Setting external monitor $external_monitor as primary..."
			xrandr --output "$external_monitor" --primary
			sleep 1
		else
			log "INFO" "DISPLAY" "No external monitor detected"
		fi
	fi
}

switch_workspace() {
	local workspace="$1"

	if [[ -z "$workspace" || "$workspace" == "0" || "$DRY_RUN" == "true" ]]; then
		return 0
	fi

	# GNOME workspace switching (0-based indexing)
	local target_workspace=$((workspace - 1))

	if command -v gdbus >/dev/null 2>&1; then
		local current=$(gdbus call --session --dest org.gnome.Shell --object-path /org/gnome/Shell --method org.gnome.Shell.Eval "global.workspace_manager.get_active_workspace().index()" 2>/dev/null | grep -o '[0-9]*' || echo "")

		if [[ "$current" != "$target_workspace" ]]; then
			log "INFO" "WORKSPACE" "Switching to workspace $workspace (GNOME) BEFORE app launch"
			gdbus call --session --dest org.gnome.Shell --object-path /org/gnome/Shell --method org.gnome.Shell.Eval "global.workspace_manager.get_workspace_by_index($target_workspace).activate(global.get_current_time())" >/dev/null 2>&1
			sleep 3 # INCREASED wait time for workspace switch to complete
		else
			log "INFO" "WORKSPACE" "Already on workspace $workspace"
		fi
	elif command -v wmctrl >/dev/null 2>&1; then
		# Fallback for XWayland apps
		local current=$(wmctrl -d | grep '*' | awk '{print $1}' 2>/dev/null || echo "")

		if [[ "$current" != "$target_workspace" ]]; then
			log "INFO" "WORKSPACE" "Switching to workspace $workspace using wmctrl (XWayland fallback)"
			wmctrl -s "$target_workspace"
			sleep 3 # INCREASED wait time
		else
			log "INFO" "WORKSPACE" "Already on workspace $workspace"
		fi
	else
		log "WARN" "WORKSPACE" "Neither gdbus nor wmctrl available, cannot switch workspace"
	fi
}

# REMOVED force_window_to_workspace function - not needed with proper timing

is_app_running() {
	local app_name="$1"
	local search_pattern="${2:-$app_name}"

	pgrep -f "$search_pattern" &>/dev/null
}

make_fullscreen() {
	if [[ "$DRY_RUN" == "true" ]]; then
		return 0
	fi

	if command -v gdbus >/dev/null 2>&1; then
		log "INFO" "FULLSCREEN" "Making window fullscreen (GNOME/Wayland)"
		sleep 1
		gdbus call --session --dest org.gnome.Shell --object-path /org/gnome/Shell --method org.gnome.Shell.Eval "global.display.get_focus_window().make_fullscreen()" >/dev/null 2>&1
		sleep 1
	elif command -v wmctrl >/dev/null 2>&1; then
		log "INFO" "FULLSCREEN" "Making window fullscreen (XWayland fallback)"
		sleep 1
		# Try to find the window and make it fullscreen
		local window_id=$(wmctrl -l | tail -1 | awk '{print $1}')
		if [[ -n "$window_id" ]]; then
			wmctrl -i -r "$window_id" -b add,fullscreen
		fi
		sleep 1
	else
		log "WARN" "FULLSCREEN" "Cannot make fullscreen - press F11 manually"
	fi
}

parse_config() {
	local config="$1"
	local field="$2"
	echo "$config" | cut -d'|' -f"$field"
}

get_browser_profiles() {
	case "$BROWSER_TYPE" in
	"brave") echo "BRAVE_BROWSERS" ;;
	"zen") echo "ZEN_BROWSERS" ;;
	"chrome") echo "CHROME_BROWSERS" ;;
	*)
		log "ERROR" "BROWSER" "Invalid browser type: $BROWSER_TYPE"
		return 1
		;;
	esac
}

#-------------------------------------------------------------------------------
# Script Generation Functions
#-------------------------------------------------------------------------------

generate_script() {
	local profile="$1"
	local config="$2"
	local script_path="$SCRIPTS_DIR/gnome-${profile}.sh"

	local cmd=$(parse_config "$config" 1)
	local args=$(parse_config "$config" 2)
	local workspace=$(parse_config "$config" 3)
	local vpn=$(parse_config "$config" 4)
	local wait=$(parse_config "$config" 5)
	local fullscreen=$(parse_config "$config" 6)

	# Set defaults
	[[ -z "$workspace" ]] && workspace="0"
	[[ -z "$vpn" ]] && vpn="secure"
	[[ -z "$wait" ]] && wait="2"
	[[ -z "$fullscreen" ]] && fullscreen="false"

	mkdir -p "$SCRIPTS_DIR"

	{
		echo "#!/usr/bin/env bash"
		echo "# Profile: $profile"
		echo "# Generated by Semsumo v$VERSION (GNOME Edition - Workspace Fixed)"
		echo "set -e"
		echo "echo \"Initializing $profile for GNOME/Wayland...\""
		echo ""
		echo "# Force external monitor as primary (if connected)"
		echo "if command -v xrandr >/dev/null 2>&1; then"
		echo "    EXTERNAL_MONITOR=\$(xrandr --query | grep \" connected\" | grep -v \"eDP\" | head -1 | awk '{print \$1}')"
		echo "    if [[ -n \"\$EXTERNAL_MONITOR\" ]]; then"
		echo "        echo \"Setting external monitor \$EXTERNAL_MONITOR as primary...\""
		echo "        xrandr --output \"\$EXTERNAL_MONITOR\" --primary"
		echo "        sleep 1"
		echo "    fi"
		echo "fi"
		echo ""
		echo "# ✅ FIXED: Switch to workspace FIRST and WAIT (before starting app)"
		echo "if [[ \"$workspace\" != \"0\" ]]; then"
		echo "    echo \"Switching to workspace $workspace BEFORE starting application...\""
		echo "    # GNOME workspace switching (0-based indexing)"
		echo "    TARGET_WORKSPACE=\$(($workspace - 1))"
		echo "    "
		echo "    if command -v gdbus >/dev/null 2>&1; then"
		echo "        CURRENT_WORKSPACE=\$(gdbus call --session --dest org.gnome.Shell --object-path /org/gnome/Shell --method org.gnome.Shell.Eval \"global.workspace_manager.get_active_workspace().index()\" 2>/dev/null | grep -o '[0-9]*' || echo \"\")"
		echo ""
		echo "        if [[ \"\$CURRENT_WORKSPACE\" != \"\$TARGET_WORKSPACE\" ]]; then"
		echo "            echo \"Switching to workspace $workspace using gdbus (Wayland)...\""
		echo "            gdbus call --session --dest org.gnome.Shell --object-path /org/gnome/Shell --method org.gnome.Shell.Eval \"global.workspace_manager.get_workspace_by_index(\$TARGET_WORKSPACE).activate(global.get_current_time())\" >/dev/null 2>&1"
		echo "            sleep 3  # Wait for workspace switch to complete"
		echo "        else"
		echo "            echo \"Already on workspace $workspace, skipping switch.\""
		echo "        fi"
		echo "    elif command -v wmctrl >/dev/null 2>&1; then"
		echo "        # Fallback for XWayland apps"
		echo "        CURRENT_WORKSPACE=\$(wmctrl -d | grep '*' | awk '{print \$1}' 2>/dev/null || echo \"\")"
		echo "        "
		echo "        if [[ \"\$CURRENT_WORKSPACE\" != \"\$TARGET_WORKSPACE\" ]]; then"
		echo "            echo \"Switching to workspace $workspace using wmctrl (XWayland fallback)...\""
		echo "            wmctrl -s \"\$TARGET_WORKSPACE\""
		echo "            sleep 3  # Wait for workspace switch to complete"
		echo "        else"
		echo "            echo \"Already on workspace $workspace, skipping switch.\""
		echo "        fi"
		echo "    else"
		echo "        echo \"WARNING: Neither gdbus nor wmctrl available, cannot switch workspace\""
		echo "        echo \"INFO: Install with: nix-env -iA nixpkgs.wmctrl or add to configuration.nix\""
		echo "    fi"
		echo "fi"
		echo ""
		echo "echo \"Starting application on workspace $workspace...\""
		echo "echo \"COMMAND: $cmd $args\""
		echo "echo \"VPN MODE: $vpn\""
		echo ""
		echo "# Start application with VPN mode"
		echo "case \"$vpn\" in"
		echo "    bypass)"
		echo "        if command -v mullvad >/dev/null 2>&1 && mullvad status 2>/dev/null | grep -q \"Connected\"; then"
		echo "            if command -v mullvad-exclude >/dev/null 2>&1; then"
		echo "                echo \"Starting with VPN bypass (mullvad-exclude)\""
		echo "                mullvad-exclude $cmd $args &"
		echo "            else"
		echo "                echo \"WARNING: mullvad-exclude not found, starting normally\""
		echo "                echo \"INFO: Install with: nix-env -iA nixpkgs.mullvad-vpn\""
		echo "                $cmd $args &"
		echo "            fi"
		echo "        else"
		echo "            echo \"VPN not connected, starting normally\""
		echo "            $cmd $args &"
		echo "        fi"
		echo "        ;;"
		echo "    secure|*)"
		echo "        if command -v mullvad >/dev/null 2>&1 && mullvad status 2>/dev/null | grep -q \"Connected\"; then"
		echo "            echo \"Starting with VPN protection\""
		echo "        else"
		echo "            echo \"WARNING: VPN not connected! Starting without protection\""
		echo "            echo \"INFO: Install Mullvad with: nix-env -iA nixpkgs.mullvad-vpn\""
		echo "        fi"
		echo "        $cmd $args &"
		echo "        ;;"
		echo "esac"
		echo ""
		echo "# Save PID"
		echo "APP_PID=\$!"
		echo "mkdir -p \"/tmp/semsumo\""
		echo "echo \"\$APP_PID\" > \"/tmp/semsumo/$profile.pid\""
		echo "echo \"Application started (PID: \$APP_PID) on workspace $workspace\""
		echo ""
		echo "# Wait for application to load"
		echo "sleep 3"
		echo ""
		echo "# ❌ NO window workspace moving - app should open on correct workspace"
		echo ""
		echo "# Make fullscreen if needed"
		echo "if [[ \"$fullscreen\" == \"true\" ]]; then"
		echo "    echo \"Waiting $wait seconds for application to load...\""
		echo "    sleep $wait"
		echo "    "
		echo "    # For Wayland, use gdbus to interact with GNOME Shell"
		echo "    if command -v gdbus >/dev/null 2>&1; then"
		echo "        echo \"Making fullscreen using gdbus (Wayland)...\""
		echo "        gdbus call --session --dest org.gnome.Shell --object-path /org/gnome/Shell --method org.gnome.Shell.Eval \"global.display.get_focus_window().make_fullscreen()\" >/dev/null 2>&1"
		echo "    elif command -v wmctrl >/dev/null 2>&1; then"
		echo "        echo \"Making fullscreen using wmctrl (XWayland fallback)...\""
		echo "        WINDOW_ID=\$(wmctrl -l | tail -1 | awk '{print \$1}')"
		echo "        if [[ -n \"\$WINDOW_ID\" ]]; then"
		echo "            wmctrl -i -r \"\$WINDOW_ID\" -b add,fullscreen"
		echo "        fi"
		echo "    else"
		echo "        echo \"WARNING: Neither gdbus nor wmctrl available, cannot make fullscreen\""
		echo "        echo \"INFO: Install wmctrl with: nix-env -iA nixpkgs.wmctrl\""
		echo "        echo \"INFO: You can manually press F11 to make the window fullscreen\""
		echo "    fi"
		echo "fi"
		echo ""
		echo "exit 0"
	} >"$script_path"

	chmod +x "$script_path"
	log "SUCCESS" "GENERATE" "Generated: gnome-${profile}.sh"
}

generate_all_scripts() {
	log "INFO" "GENERATE" "Generating GNOME scripts for ALL profiles (all browsers + terminals + apps)..."

	local count=0

	# Generate terminal scripts
	for profile in "${!TERMINALS[@]}"; do
		generate_script "$profile" "${TERMINALS[$profile]}"
		((count++))
	done

	# Generate ALL browser scripts (Brave, Zen, Chrome)
	log "INFO" "GENERATE" "Generating Brave browser scripts..."
	for profile in "${!BRAVE_BROWSERS[@]}"; do
		generate_script "$profile" "${BRAVE_BROWSERS[$profile]}"
		((count++))
	done

	log "INFO" "GENERATE" "Generating Zen browser scripts..."
	for profile in "${!ZEN_BROWSERS[@]}"; do
		generate_script "$profile" "${ZEN_BROWSERS[$profile]}"
		((count++))
	done

	log "INFO" "GENERATE" "Generating Chrome browser scripts..."
	for profile in "${!CHROME_BROWSERS[@]}"; do
		generate_script "$profile" "${CHROME_BROWSERS[$profile]}"
		((count++))
	done

	# Generate app scripts
	log "INFO" "GENERATE" "Generating application scripts..."
	for profile in "${!APPS[@]}"; do
		generate_script "$profile" "${APPS[$profile]}"
		((count++))
	done

	log "SUCCESS" "GENERATE" "Generated $count GNOME startup scripts (ALL browsers + terminals + apps) in $SCRIPTS_DIR"
}

generate_daily_scripts() {
	log "INFO" "GENERATE" "Generating GNOME scripts for daily/essential profiles only..."

	local count=0

	# Generate daily profiles only
	for profile in "${!DAILY_PROFILES[@]}"; do
		local profile_type="${DAILY_PROFILES[$profile]}"
		local config=""

		case "$profile_type" in
		"TERMINALS")
			config="${TERMINALS[$profile]}"
			;;
		"BRAVE_BROWSERS")
			config="${BRAVE_BROWSERS[$profile]}"
			;;
		"APPS")
			config="${APPS[$profile]}"
			;;
		esac

		if [[ -n "$config" ]]; then
			generate_script "$profile" "$config"
			((count++))
		else
			log "WARN" "GENERATE" "Profile not found: $profile"
		fi
	done

	log "SUCCESS" "GENERATE" "Generated $count daily/essential GNOME scripts in $SCRIPTS_DIR"
}

generate_browser_only_scripts() {
	log "INFO" "GENERATE" "Generating GNOME scripts for $BROWSER_TYPE browser only..."

	local count=0

	# Generate terminal scripts
	for profile in "${!TERMINALS[@]}"; do
		generate_script "$profile" "${TERMINALS[$profile]}"
		((count++))
	done

	# Generate browser scripts for current type only
	case "$BROWSER_TYPE" in
	"brave")
		for profile in "${!BRAVE_BROWSERS[@]}"; do
			generate_script "$profile" "${BRAVE_BROWSERS[$profile]}"
			((count++))
		done
		;;
	"zen")
		for profile in "${!ZEN_BROWSERS[@]}"; do
			generate_script "$profile" "${ZEN_BROWSERS[$profile]}"
			((count++))
		done
		;;
	"chrome")
		for profile in "${!CHROME_BROWSERS[@]}"; do
			generate_script "$profile" "${CHROME_BROWSERS[$profile]}"
			((count++))
		done
		;;
	esac

	# Generate app scripts
	for profile in "${!APPS[@]}"; do
		generate_script "$profile" "${APPS[$profile]}"
		((count++))
	done

	log "SUCCESS" "GENERATE" "Generated $count GNOME startup scripts for $BROWSER_TYPE browser in $SCRIPTS_DIR"
}

generate_by_type() {
	local type="$1"
	local count=0

	case "$type" in
	terminals)
		log "INFO" "GENERATE" "Generating GNOME terminal scripts..."
		for profile in "${!TERMINALS[@]}"; do
			generate_script "$profile" "${TERMINALS[$profile]}"
			((count++))
		done
		;;
	browsers)
		log "INFO" "GENERATE" "Generating GNOME $BROWSER_TYPE browser scripts..."
		local browsers_var=$(get_browser_profiles)
		local -n browsers_ref=$browsers_var
		for profile in "${!browsers_ref[@]}"; do
			generate_script "$profile" "${browsers_ref[$profile]}"
			((count++))
		done
		;;
	apps)
		log "INFO" "GENERATE" "Generating GNOME application scripts..."
		for profile in "${!APPS[@]}"; do
			generate_script "$profile" "${APPS[$profile]}"
			((count++))
		done
		;;
	*)
		log "ERROR" "GENERATE" "Unknown type: $type"
		log "INFO" "GENERATE" "Available types: terminals, browsers, apps"
		return 1
		;;
	esac

	log "SUCCESS" "GENERATE" "Generated $count GNOME $type scripts"
}

generate_single_script() {
	local profile="$1"

	if [[ -v TERMINALS["$profile"] ]]; then
		generate_script "$profile" "${TERMINALS[$profile]}"
	elif [[ -v BRAVE_BROWSERS["$profile"] && "$BROWSER_TYPE" == "brave" ]]; then
		generate_script "$profile" "${BRAVE_BROWSERS[$profile]}"
	elif [[ -v ZEN_BROWSERS["$profile"] && "$BROWSER_TYPE" == "zen" ]]; then
		generate_script "$profile" "${ZEN_BROWSERS[$profile]}"
	elif [[ -v CHROME_BROWSERS["$profile"] && "$BROWSER_TYPE" == "chrome" ]]; then
		generate_script "$profile" "${CHROME_BROWSERS[$profile]}"
	elif [[ -v APPS["$profile"] ]]; then
		generate_script "$profile" "${APPS[$profile]}"
	else
		log "ERROR" "GENERATE" "Profile not found: $profile"
		log "INFO" "GENERATE" "Use 'list' command to see available profiles"
		return 1
	fi
}

clean_scripts() {
	log "INFO" "GENERATE" "Removing all generated GNOME scripts..."

	if [[ -d "$SCRIPTS_DIR" ]]; then
		rm -f "$SCRIPTS_DIR"/gnome-*.sh
		log "SUCCESS" "GENERATE" "All GNOME scripts removed from $SCRIPTS_DIR"
	else
		log "INFO" "GENERATE" "Scripts directory doesn't exist"
	fi
}

#-------------------------------------------------------------------------------
# Direct Launch Functions - FIXED WORKSPACE LOGIC
#-------------------------------------------------------------------------------

launch_application() {
	local profile="$1"
	local config="$2"
	local type="${3:-app}"

	local cmd=$(parse_config "$config" 1)
	local args=$(parse_config "$config" 2)
	local workspace=$(parse_config "$config" 3)
	local vpn=$(parse_config "$config" 4)
	local wait=$(parse_config "$config" 5)
	local fullscreen=$(parse_config "$config" 6)

	# Set defaults
	[[ -z "$workspace" ]] && workspace="0"
	[[ -z "$vpn" ]] && vpn="secure"
	[[ -z "$wait" ]] && wait="2"
	[[ -z "$fullscreen" ]] && fullscreen="false"

	# Check if already running
	if is_app_running "$profile"; then
		log "WARN" "LAUNCH" "$profile is already running"
		return 0
	fi

	# Setup external monitor first
	setup_external_monitor

	# ✅ CRITICAL FIX: Switch workspace BEFORE launching app and WAIT
	if [[ "$workspace" != "0" ]]; then
		log "INFO" "LAUNCH" "Switching to workspace $workspace BEFORE starting $profile"
		switch_workspace "$workspace"
		# Extra wait to ensure workspace switch is complete
		sleep 1
	fi

	log "INFO" "LAUNCH" "Starting $profile ($type) on workspace: $workspace"

	if [[ "$DRY_RUN" == "true" ]]; then
		log "DEBUG" "LAUNCH" "Dry run: would start $profile"
		return 0
	fi

	# Start application with VPN mode
	case "$vpn" in
	bypass)
		if command -v mullvad >/dev/null 2>&1 && mullvad status 2>/dev/null | grep -q "Connected"; then
			if command -v mullvad-exclude >/dev/null 2>&1; then
				log "INFO" "LAUNCH" "Starting with VPN bypass"
				mullvad-exclude $cmd $args &
			else
				log "WARN" "LAUNCH" "mullvad-exclude not found, starting normally"
				$cmd $args &
			fi
		else
			log "INFO" "LAUNCH" "VPN not connected, starting normally"
			$cmd $args &
		fi
		;;
	secure | *)
		if command -v mullvad >/dev/null 2>&1 && mullvad status 2>/dev/null | grep -q "Connected"; then
			log "INFO" "LAUNCH" "Starting with VPN protection"
		else
			log "WARN" "LAUNCH" "VPN not connected! Starting without protection"
		fi
		$cmd $args &
		;;
	esac

	# Save PID
	local app_pid=$!
	mkdir -p "/tmp/semsumo"
	echo "$app_pid" >"/tmp/semsumo/$profile.pid"

	# Wait for app to start
	sleep 3

	# ❌ REMOVED: No window workspace moving - app should open on correct workspace

	if [[ "$fullscreen" == "true" ]]; then
		sleep "$wait"
		make_fullscreen
	fi

	log "SUCCESS" "LAUNCH" "$profile started (PID: $app_pid) on workspace $workspace"
}

launch_profile() {
	local profile="$1"

	if [[ -v TERMINALS["$profile"] ]]; then
		launch_application "$profile" "${TERMINALS[$profile]}" "terminal"
	elif [[ -v BRAVE_BROWSERS["$profile"] && "$BROWSER_TYPE" == "brave" ]]; then
		launch_application "$profile" "${BRAVE_BROWSERS[$profile]}" "brave"
	elif [[ -v ZEN_BROWSERS["$profile"] && "$BROWSER_TYPE" == "zen" ]]; then
		launch_application "$profile" "${ZEN_BROWSERS[$profile]}" "zen"
	elif [[ -v CHROME_BROWSERS["$profile"] && "$BROWSER_TYPE" == "chrome" ]]; then
		launch_application "$profile" "${CHROME_BROWSERS[$profile]}" "chrome"
	elif [[ -v APPS["$profile"] ]]; then
		launch_application "$profile" "${APPS[$profile]}" "app"
	else
		log "ERROR" "LAUNCH" "Profile not found: $profile"
		return 1
	fi
}

launch_terminals() {
	log "INFO" "LAUNCH" "Starting terminal sessions..."

	for profile in "${!TERMINALS[@]}"; do
		launch_application "$profile" "${TERMINALS[$profile]}" "terminal"
		sleep 2 # Stagger launches with proper delay
	done
}

launch_browsers() {
	log "INFO" "LAUNCH" "Starting $BROWSER_TYPE browser profiles..."

	local browsers_var=$(get_browser_profiles)
	local -n browsers_ref=$browsers_var

	for profile in "${!browsers_ref[@]}"; do
		launch_application "$profile" "${browsers_ref[$profile]}" "$BROWSER_TYPE"
		sleep 3 # Longer delay for browsers
	done
}

launch_apps() {
	log "INFO" "LAUNCH" "Starting applications..."

	for profile in "${!APPS[@]}"; do
		launch_application "$profile" "${APPS[$profile]}" "app"
		sleep 2
	done
}

launch_daily_profiles() {
	log "INFO" "LAUNCH" "Starting daily/essential profiles with proper workspace timing..."

	# Launch daily profiles in specific order with delays
	local daily_order=("kkenp" "brave-kenp" "brave-ai" "brave-compecta" "discord" "spotify" "ferdium" "brave-youtube")

	for profile in "${daily_order[@]}"; do
		if [[ -v DAILY_PROFILES["$profile"] ]]; then
			local profile_type="${DAILY_PROFILES[$profile]}"
			local config=""

			case "$profile_type" in
			"TERMINALS")
				config="${TERMINALS[$profile]}"
				launch_application "$profile" "$config" "terminal"
				sleep 3 # Extra delay for terminals
				;;
			"BRAVE_BROWSERS")
				config="${BRAVE_BROWSERS[$profile]}"
				launch_application "$profile" "$config" "brave"
				sleep 4 # Extra delay for browsers
				;;
			"APPS")
				config="${APPS[$profile]}"
				launch_application "$profile" "$config" "app"
				sleep 2
				;;
			esac
		fi
	done

	log "SUCCESS" "LAUNCH" "Daily/essential profiles launched with workspace fixes"
}

#-------------------------------------------------------------------------------
# Listing Functions
#-------------------------------------------------------------------------------

list_profiles() {
	echo -e "${BOLD}${CYAN}Available Profiles (Browser: $BROWSER_TYPE, GNOME Workspace Fixed):${NC}\n"

	echo -e "${BOLD}${GREEN}Terminals:${NC}"
	for profile in "${!TERMINALS[@]}"; do
		local config="${TERMINALS[$profile]}"
		local cmd=$(parse_config "$config" 1)
		local workspace=$(parse_config "$config" 3)
		local vpn=$(parse_config "$config" 4)
		printf "  %-20s %s (workspace: %s, vpn: %s)\n" "$profile" "$cmd" "$workspace" "$vpn"
	done

	echo -e "\n${BOLD}${GREEN}Browsers ($BROWSER_TYPE):${NC}"
	local browsers_var=$(get_browser_profiles)
	local -n browsers_ref=$browsers_var
	for profile in "${!browsers_ref[@]}"; do
		local config="${browsers_ref[$profile]}"
		local cmd=$(parse_config "$config" 1)
		local workspace=$(parse_config "$config" 3)
		local vpn=$(parse_config "$config" 4)
		printf "  %-20s %s (workspace: %s, vpn: %s)\n" "$profile" "$cmd" "$workspace" "$vpn"
	done

	echo -e "\n${BOLD}${GREEN}Applications:${NC}"
	for profile in "${!APPS[@]}"; do
		local config="${APPS[$profile]}"
		local cmd=$(parse_config "$config" 1)
		local workspace=$(parse_config "$config" 3)
		local vpn=$(parse_config "$config" 4)
		printf "  %-20s %s (workspace: %s, vpn: %s)\n" "$profile" "$cmd" "$workspace" "$vpn"
	done

	echo -e "\n${BOLD}${YELLOW}GNOME Workspace Fixes Applied:${NC}"
	echo -e "  • Switch to workspace BEFORE launching app (3s wait)"
	echo -e "  • No post-launch window moving (apps open in correct workspace)"
	echo -e "  • External monitor automatically set as primary"
	echo -e "  • Staggered application launches with proper delays"
	echo -e "  • Increased timing for workspace switches"
}

#-------------------------------------------------------------------------------
# Status and Utility Functions
#-------------------------------------------------------------------------------

check_status() {
	echo -e "${BOLD}${CYAN}Application Status (GNOME Workspace Fixed):${NC}\n"

	local running_count=0
	local total_count=0

	# Check terminals
	echo -e "${BOLD}${GREEN}Terminals:${NC}"
	for profile in "${!TERMINALS[@]}"; do
		((total_count++))
		if is_app_running "$profile"; then
			echo -e "  ${GREEN}✓${NC} $profile (running)"
			((running_count++))
		else
			echo -e "  ${RED}✗${NC} $profile (stopped)"
		fi
	done

	# Check browsers
	echo -e "\n${BOLD}${GREEN}Browsers ($BROWSER_TYPE):${NC}"
	local browsers_var=$(get_browser_profiles)
	local -n browsers_ref=$browsers_var
	for profile in "${!browsers_ref[@]}"; do
		((total_count++))
		if is_app_running "$profile"; then
			echo -e "  ${GREEN}✓${NC} $profile (running)"
			((running_count++))
		else
			echo -e "  ${RED}✗${NC} $profile (stopped)"
		fi
	done

	# Check apps
	echo -e "\n${BOLD}${GREEN}Applications:${NC}"
	for profile in "${!APPS[@]}"; do
		((total_count++))
		if is_app_running "$profile"; then
			echo -e "  ${GREEN}✓${NC} $profile (running)"
			((running_count++))
		else
			echo -e "  ${RED}✗${NC} $profile (stopped)"
		fi
	done

	echo -e "\n${BOLD}Summary:${NC} $running_count/$total_count applications running"
}

kill_all() {
	log "INFO" "KILL" "Stopping all managed applications..."

	local killed_count=0

	# Kill based on PID files
	if [[ -d "/tmp/semsumo" ]]; then
		for pid_file in /tmp/semsumo/*.pid; do
			if [[ -f "$pid_file" ]]; then
				local pid=$(cat "$pid_file")
				local profile=$(basename "$pid_file" .pid)

				if kill -0 "$pid" 2>/dev/null; then
					log "INFO" "KILL" "Stopping $profile (PID: $pid)"
					kill "$pid" 2>/dev/null && ((killed_count++))
				fi
				rm -f "$pid_file"
			fi
		done
	fi

	log "SUCCESS" "KILL" "Stopped $killed_count applications"
}

export_config() {
	log "INFO" "EXPORT" "Exporting current GNOME configuration (Workspace Fixed Edition)"

	echo -e "${BOLD}${CYAN}Current GNOME Configuration (Workspace Fixed):${NC}\n"
	echo -e "${BOLD}Edition:${NC} GNOME/Wayland v$VERSION"
	echo -e "${BOLD}Browser Type:${NC} $BROWSER_TYPE"
	echo -e "${BOLD}Final Workspace:${NC} $FINAL_WORKSPACE"
	echo -e "${BOLD}Wait Time:${NC} $WAIT_TIME"
	echo -e "${BOLD}Scripts Directory:${NC} $SCRIPTS_DIR"
	echo -e "${BOLD}Log Directory:${NC} $LOG_DIR"

	echo -e "\n${BOLD}Profile Counts:${NC}"
	echo -e "  Terminals: ${#TERMINALS[@]}"

	case "$BROWSER_TYPE" in
	"brave") echo -e "  Browsers: ${#BRAVE_BROWSERS[@]} (Brave)" ;;
	"zen") echo -e "  Browsers: ${#ZEN_BROWSERS[@]} (Zen)" ;;
	"chrome") echo -e "  Browsers: ${#CHROME_BROWSERS[@]} (Chrome)" ;;
	esac

	echo -e "  Applications: ${#APPS[@]}"

	echo -e "\n${BOLD}Workspace Fixes:${NC}"
	echo -e "  • Workspace switching BEFORE app launch (not after)"
	echo -e "  • 3-second wait for workspace switches to complete"
	echo -e "  • No post-launch window moving (relies on proper timing)"
	echo -e "  • Automatic external monitor primary setup"
	echo -e "  • Staggered launches with increased delays"
	echo -e "  • Script prefix: gnome-"

	log "INFO" "EXPORT" "Workspace Fixed GNOME configuration displayed"
}

#-------------------------------------------------------------------------------
# Help and Usage
#-------------------------------------------------------------------------------

show_help() {
	echo -e "${BOLD}${GREEN}Semsumo v$VERSION - Enhanced Application Launcher & Generator (GNOME Workspace Fixed)${NC}"
	echo
	echo -e "${BOLD}Usage:${NC}"
	echo "    $0 [BROWSER] <command> [options]"
	echo
	echo -e "${BOLD}Browser Types:${NC}"
	echo "    brave                 Use Brave Browser profiles (default)"
	echo "    zen                   Use Zen Browser profiles"
	echo "    chrome                Use Chrome Browser profiles"
	echo
	echo -e "${BOLD}Commands:${NC}"
	echo "    generate [profile]    Generate GNOME startup script(s)"
	echo "    launch [profile]      Launch application(s) directly"
	echo "    list                  List all available profiles"
	echo "    clean                 Remove all generated GNOME scripts"
	echo "    status                Show running applications status"
	echo "    kill                  Stop all managed applications"
	echo "    export                Show current GNOME configuration"
	echo "    help                  Show this help"
	echo
	echo -e "${BOLD}Generate Options:${NC}"
	echo "    --all                 Generate scripts for ALL profiles (all browsers)"
	echo "    --daily               Generate scripts for daily/essential profiles only"
	echo "    --type TYPE           Generate scripts for specific type"
	echo "    --browser-only        Generate scripts only for current browser type"
	echo
	echo -e "${BOLD}Launch Options:${NC}"
	echo "    --daily               Launch daily/essential profiles"
	echo "    --terminals           Launch only terminal sessions"
	echo "    --browsers            Launch only browser profiles"
	echo "    --apps                Launch only applications"
	echo "    --workspace NUM       Final workspace (default: $DEFAULT_FINAL_WORKSPACE)"
	echo "    --wait NUM            Wait time between launches (default: $DEFAULT_WAIT_TIME)"
	echo
	echo -e "${BOLD}Global Options:${NC}"
	echo "    --dry-run             Test mode (don't actually run anything)"
	echo "    --debug               Enable debug output"
	echo "    --help                Show this help"
	echo
	echo -e "${BOLD}🔧 WORKSPACE FIXES (New):${NC}"
	echo "    • Switch to workspace BEFORE launching app (not after)"
	echo "    • 3-second wait for workspace switches to complete"
	echo "    • No post-launch window moving (proper timing approach)"
	echo "    • Automatic external monitor detection and primary setup"
	echo "    • Staggered launches with increased delays"
	echo "    • Multi-monitor support with primary display detection"
	echo
	echo -e "${BOLD}Examples:${NC}"
	echo "    $0 generate --daily                 # Generate daily/essential GNOME scripts"
	echo "    $0 brave generate --browser-only    # Generate only Brave GNOME scripts"
	echo "    $0 launch --daily                   # Launch daily/essential profiles (workspace fixed)"
	echo "    $0 brave launch --browsers          # Launch all Brave browser profiles"
	echo "    $0 launch brave-kenp                # Launch specific profile (workspace 1)"
	echo "    $0 list                             # List all available profiles"
	echo "    $0 clean                            # Remove all generated GNOME scripts"
	echo
	echo -e "${BOLD}Locations:${NC}"
	echo "    Scripts: $SCRIPTS_DIR"
	echo "    Logs:    $LOG_FILE"
	echo
	echo -e "${BOLD}Multi-Monitor Setup:${NC}"
	echo "    The script automatically detects external monitors and sets them as primary."
	echo "    Applications will launch on the primary display with correct workspace assignment."
	echo
	echo -e "${BOLD}GNOME Workspace Requirements:${NC}"
	echo "    ${YELLOW}IMPORTANT:${NC} Ensure 'Dynamic workspaces' is disabled in GNOME Settings"
	echo "    ${YELLOW}IMPORTANT:${NC} Set 'Fixed number of workspaces' to at least 10"
	echo "    Install wmctrl for XWayland fallback: nix-env -iA nixpkgs.wmctrl"
	echo
	echo -e "${BOLD}Workspace Logic Fix:${NC}"
	echo "    Previous issue: Apps opened in wrong workspace due to timing"
	echo "    New approach: Switch workspace FIRST, wait, THEN launch app"
	echo "    Result: Apps correctly open in intended workspace"
}

#-------------------------------------------------------------------------------
# Argument Parsing
#-------------------------------------------------------------------------------

detect_browser_from_script_name() {
	case "$SCRIPT_NAME" in
	*brave*) echo "brave" ;;
	*zen*) echo "zen" ;;
	*chrome*) echo "chrome" ;;
	*) echo "brave" ;;
	esac
}

parse_args() {
	# First parameter might be browser type
	if [[ $# -gt 0 && ("$1" == "brave" || "$1" == "zen" || "$1" == "chrome") ]]; then
		BROWSER_TYPE="$1"
		shift
	elif [[ $# -gt 0 && "$1" != "-"* && "$1" != "generate" && "$1" != "launch" && "$1" != "list" && "$1" != "clean" && "$1" != "help" && "$1" != "status" && "$1" != "kill" && "$1" != "export" ]]; then
		log "ERROR" "ARGS" "Invalid browser type: $1"
		echo "Supported browser types: brave, zen, chrome" >&2
		exit 1
	else
		BROWSER_TYPE=$(detect_browser_from_script_name)
	fi

	# Parse command
	case "${1:-help}" in
	generate)
		MODE_GENERATE=true
		shift
		;;
	launch)
		MODE_LAUNCH=true
		shift
		;;
	list)
		MODE_LIST=true
		shift
		;;
	clean)
		MODE_CLEAN=true
		shift
		;;
	status)
		check_status
		exit 0
		;;
	kill)
		kill_all
		exit 0
		;;
	export)
		export_config
		exit 0
		;;
	help | --help | -h)
		show_help
		exit 0
		;;
	version | --version | -v)
		echo "Semsumo v$VERSION (GNOME Edition - Workspace Fixed)"
		exit 0
		;;
	*)
		log "ERROR" "ARGS" "Unknown command: $1"
		show_help
		exit 1
		;;
	esac

	# Parse remaining options
	while [[ $# -gt 0 ]]; do
		case "$1" in
		--all)
			if [[ "$MODE_GENERATE" == "true" ]]; then
				LAUNCH_ALL=true
			elif [[ "$MODE_LAUNCH" == "true" ]]; then
				RUN_TERMINALS=true
				RUN_BROWSER=true
				RUN_APPS=true
			fi
			shift
			;;
		--daily)
			LAUNCH_DAILY=true
			shift
			;;
		--browser-only)
			BROWSER_ONLY=true
			shift
			;;
		--type)
			LAUNCH_TYPE="$2"
			shift 2
			;;
		--terminals)
			RUN_TERMINALS=true
			shift
			;;
		--browsers)
			RUN_BROWSER=true
			shift
			;;
		--apps)
			RUN_APPS=true
			shift
			;;
		--workspace)
			FINAL_WORKSPACE="$2"
			shift 2
			;;
		--wait)
			WAIT_TIME="$2"
			shift 2
			;;
		--dry-run)
			DRY_RUN=true
			shift
			;;
		--debug)
			DEBUG_MODE=true
			shift
			;;
		"")
			break
			;;
		*)
			SINGLE_PROFILE="$1"
			shift
			;;
		esac
	done

	# Set defaults for launch mode if no specific options given
	if [[ "$MODE_LAUNCH" == "true" && "$RUN_TERMINALS" != "true" && "$RUN_BROWSER" != "true" && "$RUN_APPS" != "true" && -z "$SINGLE_PROFILE" && "$LAUNCH_DAILY" != "true" ]]; then
		RUN_TERMINALS=true
		RUN_BROWSER=true
		RUN_APPS=true
	fi
}

#-------------------------------------------------------------------------------
# Main Function
#-------------------------------------------------------------------------------

main() {
	local start_time=$(date +%s)

	parse_args "$@"

	if [[ "$DEBUG_MODE" == "true" ]]; then
		log "DEBUG" "CONFIG" "Browser: $BROWSER_TYPE, Mode: Generate=$MODE_GENERATE Launch=$MODE_LAUNCH"
		log "DEBUG" "CONFIG" "Terminals: $RUN_TERMINALS, Browsers: $RUN_BROWSER, Apps: $RUN_APPS"
		log "DEBUG" "CONFIG" "Single Profile: $SINGLE_PROFILE, Dry Run: $DRY_RUN"
	fi

	mkdir -p "$LOG_DIR"
	log "INFO" "START" "Semsumo v$VERSION (GNOME Workspace Fixed) started ($BROWSER_TYPE)" "true"

	if [[ "$DRY_RUN" == "true" ]]; then
		log "INFO" "CONFIG" "Dry run mode - no applications will be started" "true"
	fi

	# Execute based on mode
	if [[ "$MODE_GENERATE" == "true" ]]; then
		if [[ "$LAUNCH_ALL" == "true" ]]; then
			generate_all_scripts
		elif [[ "$LAUNCH_DAILY" == "true" ]]; then
			generate_daily_scripts
		elif [[ "$BROWSER_ONLY" == "true" ]]; then
			generate_browser_only_scripts
		elif [[ -n "$LAUNCH_TYPE" ]]; then
			generate_by_type "$LAUNCH_TYPE"
		elif [[ -n "$SINGLE_PROFILE" ]]; then
			generate_single_script "$SINGLE_PROFILE"
		else
			log "ERROR" "GENERATE" "Profile name or option required"
			show_help
			exit 1
		fi

	elif [[ "$MODE_LAUNCH" == "true" ]]; then
		if [[ "$LAUNCH_DAILY" == "true" ]]; then
			launch_daily_profiles
		elif [[ -n "$SINGLE_PROFILE" ]]; then
			launch_profile "$SINGLE_PROFILE"
		else
			# Launch in order: terminals, browsers, apps with proper spacing
			if [[ "$RUN_TERMINALS" == "true" ]]; then
				launch_terminals
				sleep 2
			fi
			if [[ "$RUN_BROWSER" == "true" ]]; then
				launch_browsers
				sleep 2
			fi
			if [[ "$RUN_APPS" == "true" ]]; then
				launch_apps
			fi
		fi

		# Switch to final workspace
		if [[ -n "$FINAL_WORKSPACE" ]]; then
			log "INFO" "WORKSPACE" "Switching to final workspace $FINAL_WORKSPACE"
			switch_workspace "$FINAL_WORKSPACE"
		fi

	elif [[ "$MODE_LIST" == "true" ]]; then
		list_profiles

	elif [[ "$MODE_CLEAN" == "true" ]]; then
		clean_scripts

	else
		show_help
		exit 1
	fi

	local end_time=$(date +%s)
	local total_time=$((end_time - start_time))

	log "SUCCESS" "DONE" "All operations completed (GNOME Workspace Fixed - $BROWSER_TYPE) - Time: ${total_time}s" "true"
}

#-------------------------------------------------------------------------------
# Error Handling and Entry Point
#-------------------------------------------------------------------------------

# Trap errors and cleanup
trap 'log "ERROR" "TRAP" "Script interrupted or failed"; exit 1' ERR INT TERM

# Check dependencies
check_dependencies() {
	local missing_deps=()

	# Check for required commands based on browser type
	case "$BROWSER_TYPE" in
	brave)
		command -v profile_brave >/dev/null 2>&1 || missing_deps+=("profile_brave")
		;;
	zen)
		command -v zen >/dev/null 2>&1 || missing_deps+=("zen")
		;;
	chrome)
		command -v profile_chrome >/dev/null 2>&1 || missing_deps+=("profile_chrome")
		;;
	esac

	# Check for GNOME/Wayland tools
	if ! command -v gdbus >/dev/null 2>&1; then
		log "WARN" "DEPS" "gdbus not found - GNOME Shell integration may not work"
	fi

	if ! command -v wmctrl >/dev/null 2>&1; then
		log "INFO" "DEPS" "wmctrl not found - install with: nix-env -iA nixpkgs.wmctrl"
		log "INFO" "DEPS" "wmctrl provides XWayland fallback support"
	fi

	# Check workspace settings
	if command -v gsettings >/dev/null 2>&1; then
		local dynamic_workspaces=$(gsettings get org.gnome.mutter dynamic-workspaces 2>/dev/null || echo "unknown")
		if [[ "$dynamic_workspaces" == "true" ]]; then
			log "WARN" "WORKSPACE" "Dynamic workspaces is enabled - this may cause issues"
			log "INFO" "WORKSPACE" "Disable with: gsettings set org.gnome.mutter dynamic-workspaces false"
		fi
	fi

	# Check for optional but useful commands
	if [[ ${#missing_deps[@]} -gt 0 ]]; then
		log "WARN" "DEPS" "Missing dependencies: ${missing_deps[*]}"
		log "INFO" "DEPS" "Some features may not work properly"
	fi
}

# Check dependencies before main execution
check_dependencies

# Run main function
main "$@"
