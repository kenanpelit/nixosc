#!/usr/bin/env bash

#===============================================================================
#
#   Script: Semsumo Unified - Enhanced Application Launcher & Generator
#   Version: 8.0.0
#   Date: 2025-10-05
#   Description: Unified system for launching applications with automatic
#                window manager detection (Hyprland/GNOME/Generic)
#
#   Features:
#   - Automatic window manager detection (Hyprland, GNOME, generic Wayland/X11)
#   - Application startup verification with timeout (Hyprland)
#   - Startup script generation for all profiles
#   - Multi-browser support (Brave, Zen, Chrome)
#   - VPN bypass/secure mode support
#   - Terminal session management
#   - Config-free operation (no external config files needed)
#
#===============================================================================

#-------------------------------------------------------------------------------
# Configuration and Constants
#-------------------------------------------------------------------------------

readonly SCRIPT_NAME=$(basename "$0")
readonly VERSION="8.0.0"
readonly SCRIPTS_DIR="$HOME/.nixosc/modules/home/scripts/start"
readonly LOG_DIR="$HOME/.logs/semsumo"
readonly LOG_FILE="$LOG_DIR/semsumo.log"
readonly DEFAULT_FINAL_WORKSPACE="2"
readonly DEFAULT_WAIT_TIME=2
readonly DEFAULT_APP_TIMEOUT=7
readonly DEFAULT_CHECK_INTERVAL=1

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
APP_TIMEOUT=$DEFAULT_APP_TIMEOUT
CHECK_INTERVAL=$DEFAULT_CHECK_INTERVAL

# Window Manager Detection
WM_TYPE=""

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
# Window Manager Detection
#-------------------------------------------------------------------------------

detect_window_manager() {
	if command -v hyprctl &>/dev/null && hyprctl version &>/dev/null; then
		WM_TYPE="hyprland"
		log "INFO" "DETECT" "Detected Hyprland window manager"
	elif [[ "$XDG_CURRENT_DESKTOP" == *"GNOME"* ]] || command -v gnome-shell &>/dev/null; then
		WM_TYPE="gnome"
		log "INFO" "DETECT" "Detected GNOME desktop environment"
	elif [[ -n "$WAYLAND_DISPLAY" ]]; then
		WM_TYPE="wayland"
		log "INFO" "DETECT" "Detected generic Wayland session"
	else
		WM_TYPE="x11"
		log "INFO" "DETECT" "Detected X11 session"
	fi
}

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

	if [[ "$WM_TYPE" == "gnome" ]] && command -v xrandr >/dev/null 2>&1; then
		local external_monitor=$(xrandr --query | grep " connected" | grep -v "eDP" | head -1 | awk '{print $1}')
		if [[ -n "$external_monitor" ]]; then
			log "INFO" "DISPLAY" "Setting external monitor $external_monitor as primary..."
			xrandr --output "$external_monitor" --primary
			sleep 1
		fi
	fi
}

switch_workspace() {
	local workspace="$1"

	if [[ -z "$workspace" || "$workspace" == "0" || "$DRY_RUN" == "true" ]]; then
		return 0
	fi

	case "$WM_TYPE" in
	hyprland)
		if command -v hyprctl &>/dev/null; then
			local current=$(hyprctl activeworkspace -j | grep -o '"id": [0-9]*' | grep -o '[0-9]*' || echo "")
			if [[ "$current" != "$workspace" ]]; then
				log "INFO" "WORKSPACE" "Switching to workspace $workspace (Hyprland)"
				hyprctl dispatch workspace "$workspace"
				sleep 1
			fi
		fi
		;;
	gnome)
		if command -v wmctrl >/dev/null 2>&1; then
			local target_workspace=$((workspace - 1))
			log "INFO" "WORKSPACE" "Switching to workspace $workspace (GNOME)"
			wmctrl -s "$target_workspace"
			sleep 1
		else
			log "WARN" "WORKSPACE" "wmctrl not found - install for workspace switching"
		fi
		;;
	*)
		if command -v wmctrl >/dev/null 2>&1; then
			local target_workspace=$((workspace - 1))
			log "INFO" "WORKSPACE" "Switching to workspace $workspace (wmctrl)"
			wmctrl -s "$target_workspace"
			sleep 1
		fi
		;;
	esac
}

is_app_running() {
	local profile="$1"
	local search_pattern="${2:-}"

	# For browser profiles, check if windows exist on Hyprland
	if [[ "$WM_TYPE" == "hyprland" ]] && command -v hyprctl &>/dev/null && command -v jq &>/dev/null; then
		case "$profile" in
		# Terminal profiles
		kkenp | mkenp)
			if hyprctl clients -j 2>/dev/null | jq -e '.[] | select(.class == "TmuxKenp")' >/dev/null 2>&1; then
				return 0
			fi
			return 1
			;;
		wkenp)
			if hyprctl clients -j 2>/dev/null | jq -e '.[] | select(.class == "TmuxKenp" or .class == "wezterm")' >/dev/null 2>&1; then
				return 0
			fi
			return 1
			;;
		kitty-single)
			if hyprctl clients -j 2>/dev/null | jq -e '.[] | select(.class == "kitty")' >/dev/null 2>&1; then
				return 0
			fi
			return 1
			;;
		wezterm)
			if hyprctl clients -j 2>/dev/null | jq -e '.[] | select(.class == "wezterm" or .class == "org.wezfurlong.wezterm")' >/dev/null 2>&1; then
				return 0
			fi
			return 1
			;;
		wezterm-rmpc)
			if hyprctl clients -j 2>/dev/null | jq -e '.[] | select(.class == "rmpc")' >/dev/null 2>&1; then
				return 0
			fi
			return 1
			;;
		# Brave browser profiles
		brave-kenp)
			if hyprctl clients -j 2>/dev/null | jq -e '.[] | select(.class == "Kenp" or .initialTitle == "Kenp Browser")' >/dev/null 2>&1; then
				return 0
			fi
			return 1
			;;
		brave-ai)
			if hyprctl clients -j 2>/dev/null | jq -e '.[] | select(.class == "Ai" or .initialTitle == "Ai Browser")' >/dev/null 2>&1; then
				return 0
			fi
			return 1
			;;
		brave-compecta)
			if hyprctl clients -j 2>/dev/null | jq -e '.[] | select(.class == "CompecTA" or .initialTitle == "CompecTA Browser")' >/dev/null 2>&1; then
				return 0
			fi
			return 1
			;;
		brave-whats)
			if hyprctl clients -j 2>/dev/null | jq -e '.[] | select(.class == "Whats" or .initialTitle == "Whats Browser")' >/dev/null 2>&1; then
				return 0
			fi
			return 1
			;;
		brave-exclude)
			if hyprctl clients -j 2>/dev/null | jq -e '.[] | select(.class == "Exclude" or .initialTitle == "Exclude Browser")' >/dev/null 2>&1; then
				return 0
			fi
			return 1
			;;
		brave-youtube)
			if hyprctl clients -j 2>/dev/null | jq -e '.[] | select(.class | test("brave-youtube"; "i"))' >/dev/null 2>&1; then
				return 0
			fi
			return 1
			;;
		brave-tiktok)
			if hyprctl clients -j 2>/dev/null | jq -e '.[] | select(.class | test("brave-tiktok"; "i"))' >/dev/null 2>&1; then
				return 0
			fi
			return 1
			;;
		brave-spotify)
			if hyprctl clients -j 2>/dev/null | jq -e '.[] | select(.class | test("brave-spotify"; "i"))' >/dev/null 2>&1; then
				return 0
			fi
			return 1
			;;
		brave-discord)
			if hyprctl clients -j 2>/dev/null | jq -e '.[] | select(.class | test("brave-discord"; "i"))' >/dev/null 2>&1; then
				return 0
			fi
			return 1
			;;
		brave-whatsapp)
			if hyprctl clients -j 2>/dev/null | jq -e '.[] | select(.class | test("brave-whatsapp"; "i"))' >/dev/null 2>&1; then
				return 0
			fi
			return 1
			;;
		# Zen browser profiles
		zen-*)
			local profile_class="${profile#zen-}"
			if hyprctl clients -j 2>/dev/null | jq -e ".[] | select(.class | test(\"$profile_class\"; \"i\"))" >/dev/null 2>&1; then
				return 0
			fi
			return 1
			;;
		# Chrome browser profiles
		chrome-*)
			local profile_class="${profile#chrome-}"
			if hyprctl clients -j 2>/dev/null | jq -e ".[] | select(.class | test(\"chrome|google-chrome\"; \"i\")) | select(.title | test(\"$profile_class\"; \"i\"))" >/dev/null 2>&1; then
				return 0
			fi
			return 1
			;;
		esac
	fi

	# Fallback to process check
	if [[ -n "$search_pattern" ]]; then
		pgrep -f "$search_pattern" &>/dev/null
	else
		pgrep -f "$profile" &>/dev/null
	fi
}

check_window_on_workspace() {
	local workspace="$1"
	local class_pattern="$2"
	local timeout="${3:-$APP_TIMEOUT}"
	local interval="${4:-$CHECK_INTERVAL}"

	if [[ "$DRY_RUN" == "true" ]]; then
		return 0
	fi

	# Only Hyprland has window verification
	if [[ "$WM_TYPE" != "hyprland" ]]; then
		sleep "$WAIT_TIME"
		return 0
	fi

	if ! command -v hyprctl &>/dev/null || ! command -v jq &>/dev/null; then
		log "WARN" "VERIFY" "hyprctl or jq not available, skipping window verification"
		sleep "$WAIT_TIME"
		return 0
	fi

	local elapsed=0
	log "INFO" "VERIFY" "Waiting for window (class: $class_pattern) on workspace $workspace (timeout: ${timeout}s)"

	while [[ $elapsed -lt $timeout ]]; do
		if hyprctl clients -j 2>/dev/null | jq -e ".[] | select(.workspace.id == $workspace and (.class | test(\"$class_pattern\"; \"i\")))" >/dev/null 2>&1; then
			log "SUCCESS" "VERIFY" "Window found on workspace $workspace after ${elapsed}s"
			return 0
		fi

		sleep "$interval"
		((elapsed += interval))

		if ((elapsed % 3 == 0)); then
			log "DEBUG" "VERIFY" "Still waiting... (${elapsed}/${timeout}s)"
		fi
	done

	log "WARN" "VERIFY" "Timeout waiting for window on workspace $workspace after ${timeout}s"
	return 1
}

get_class_pattern() {
	local profile="$1"
	local args="$2"

	if [[ "$args" =~ --class[=\ ]([^\ ]+) ]]; then
		echo "${BASH_REMATCH[1]}"
		return 0
	fi

	if [[ "$args" =~ (-T|--title)[=\ ]([^\ ]+) ]]; then
		echo "${BASH_REMATCH[2]}"
		return 0
	fi

	case "$profile" in
	brave-*) echo "brave" ;;
	zen-*) echo "zen" ;;
	chrome-*) echo "chrome|Google-chrome" ;;
	discord) echo "discord|Discord" ;;
	spotify) echo "spotify|Spotify" ;;
	ferdium) echo "ferdium|Ferdium" ;;
	kitty* | kkenp | mkenp) echo "kitty" ;;
	wezterm* | wkenp) echo "wezterm|org.wezfurlong.wezterm" ;;
	*) echo "$profile" ;;
	esac
}

make_fullscreen() {
	if [[ "$DRY_RUN" == "true" ]]; then
		return 0
	fi

	case "$WM_TYPE" in
	hyprland)
		if command -v hyprctl &>/dev/null; then
			log "INFO" "FULLSCREEN" "Making window fullscreen (Hyprland)"
			sleep 1
			hyprctl dispatch fullscreen 1
			sleep 1
		fi
		;;
	gnome)
		if command -v gdbus >/dev/null 2>&1; then
			log "INFO" "FULLSCREEN" "Making window fullscreen (GNOME)"
			sleep 1
			gdbus call --session --dest org.gnome.Shell --object-path /org/gnome/Shell --method org.gnome.Shell.Eval "global.display.get_focus_window().make_fullscreen()" >/dev/null 2>&1
			sleep 1
		elif command -v wmctrl >/dev/null 2>&1; then
			log "INFO" "FULLSCREEN" "Making window fullscreen (wmctrl)"
			sleep 1
			local window_id=$(wmctrl -l | tail -1 | awk '{print $1}')
			if [[ -n "$window_id" ]]; then
				wmctrl -i -r "$window_id" -b add,fullscreen
			fi
			sleep 1
		fi
		;;
	*)
		log "WARN" "FULLSCREEN" "Fullscreen not supported for $WM_TYPE - press F11 manually"
		;;
	esac
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
	local script_path="$SCRIPTS_DIR/start-${profile}.sh"

	local cmd=$(parse_config "$config" 1)
	local args=$(parse_config "$config" 2)
	local workspace=$(parse_config "$config" 3)
	local vpn=$(parse_config "$config" 4)
	local wait=$(parse_config "$config" 5)
	local fullscreen=$(parse_config "$config" 6)

	[[ -z "$workspace" ]] && workspace="0"
	[[ -z "$vpn" ]] && vpn="secure"
	[[ -z "$wait" ]] && wait="1"
	[[ -z "$fullscreen" ]] && fullscreen="false"

	local class_pattern=$(get_class_pattern "$profile" "$args")

	mkdir -p "$SCRIPTS_DIR"

	cat >"$script_path" <<'SCRIPT_HEREDOC_START'
#!/usr/bin/env bash
# Profile: PROFILE_NAME
# Generated by Semsumo v8.0.0 (Unified Edition)
set -e

readonly APP_TIMEOUT=APP_TIMEOUT_VALUE
readonly CHECK_INTERVAL=CHECK_INTERVAL_VALUE
readonly WORKSPACE=WORKSPACE_VALUE
readonly VPN_MODE="VPN_VALUE"
readonly FULLSCREEN=FULLSCREEN_VALUE
readonly WAIT_TIME=WAIT_VALUE

# Detect window manager
if command -v hyprctl &>/dev/null && hyprctl version &>/dev/null; then
    WM_TYPE="hyprland"
elif [[ "$XDG_CURRENT_DESKTOP" == *"GNOME"* ]] || command -v gnome-shell &>/dev/null; then
    WM_TYPE="gnome"
else
    WM_TYPE="generic"
fi

echo "Initializing PROFILE_NAME on $WM_TYPE..."

# External monitor setup (GNOME only)
if [[ "$WM_TYPE" == "gnome" ]] && command -v xrandr >/dev/null 2>&1; then
    EXTERNAL_MONITOR=$(xrandr --query | grep " connected" | grep -v "eDP" | head -1 | awk '{print $1}')
    if [[ -n "$EXTERNAL_MONITOR" ]]; then
        echo "Setting $EXTERNAL_MONITOR as primary..."
        xrandr --output "$EXTERNAL_MONITOR" --primary
        sleep 1
    fi
fi

# Switch to workspace
if [[ "$WORKSPACE" != "0" ]]; then
    case "$WM_TYPE" in
    hyprland)
        if command -v hyprctl >/dev/null 2>&1; then
            CURRENT=$(hyprctl activeworkspace -j | grep -o '"id": [0-9]*' | grep -o '[0-9]*' || echo "")
            if [[ "$CURRENT" != "$WORKSPACE" ]]; then
                echo "Switching to workspace $WORKSPACE..."
                hyprctl dispatch workspace "$WORKSPACE"
                sleep 1
            fi
        fi
        ;;
    gnome|*)
        if command -v wmctrl >/dev/null 2>&1; then
            TARGET=$((WORKSPACE - 1))
            echo "Switching to workspace $WORKSPACE..."
            wmctrl -s "$TARGET"
            sleep 1
        fi
        ;;
    esac
fi

echo "Starting application..."
echo "COMMAND: COMMAND_VALUE ARGS_VALUE"
echo "VPN MODE: $VPN_MODE"

# Start application with VPN mode
case "$VPN_MODE" in
    bypass)
        if command -v mullvad >/dev/null 2>&1 && mullvad status 2>/dev/null | grep -q "Connected"; then
            if command -v mullvad-exclude >/dev/null 2>&1; then
                echo "Starting with VPN bypass"
                mullvad-exclude COMMAND_VALUE ARGS_VALUE &
            else
                echo "WARNING: mullvad-exclude not found"
                COMMAND_VALUE ARGS_VALUE &
            fi
        else
            echo "VPN not connected"
            COMMAND_VALUE ARGS_VALUE &
        fi
        ;;
    secure|*)
        if command -v mullvad >/dev/null 2>&1 && mullvad status 2>/dev/null | grep -q "Connected"; then
            echo "Starting with VPN protection"
        else
            echo "WARNING: VPN not connected!"
        fi
        COMMAND_VALUE ARGS_VALUE &
        ;;
esac

APP_PID=$!
mkdir -p "/tmp/semsumo"
echo "$APP_PID" > "/tmp/semsumo/PROFILE_NAME.pid"
echo "Application started (PID: $APP_PID)"

# Window verification (Hyprland only)
if [[ "$WORKSPACE" != "0" && "$WM_TYPE" == "hyprland" ]] && command -v hyprctl >/dev/null 2>&1 && command -v jq >/dev/null 2>&1; then
    echo "Verifying window on workspace $WORKSPACE..."
    ELAPSED=0
    CLASS_PATTERN="CLASS_PATTERN_VALUE"
    
    while [[ $ELAPSED -lt $APP_TIMEOUT ]]; do
        if hyprctl clients -j 2>/dev/null | jq -e ".[] | select(.workspace.id == $WORKSPACE and (.class | test(\"$CLASS_PATTERN\"; \"i\")))" >/dev/null 2>&1; then
            echo "Window verified after ${ELAPSED}s"
            break
        fi
        sleep $CHECK_INTERVAL
        ((ELAPSED += CHECK_INTERVAL))
        if ((ELAPSED % 3 == 0)); then
            echo "Waiting... (${ELAPSED}/${APP_TIMEOUT}s)"
        fi
    done
    
    [[ $ELAPSED -ge $APP_TIMEOUT ]] && echo "WARNING: Timeout after ${APP_TIMEOUT}s"
else
    sleep $WAIT_TIME
fi

# Make fullscreen if needed
if [[ "$FULLSCREEN" == "true" ]]; then
    sleep $WAIT_TIME
    case "$WM_TYPE" in
    hyprland)
        command -v hyprctl >/dev/null 2>&1 && hyprctl dispatch fullscreen 1
        ;;
    gnome)
        if command -v gdbus >/dev/null 2>&1; then
            gdbus call --session --dest org.gnome.Shell --object-path /org/gnome/Shell --method org.gnome.Shell.Eval "global.display.get_focus_window().make_fullscreen()" >/dev/null 2>&1
        elif command -v wmctrl >/dev/null 2>&1; then
            WID=$(wmctrl -l | tail -1 | awk '{print $1}')
            [[ -n "$WID" ]] && wmctrl -i -r "$WID" -b add,fullscreen
        fi
        ;;
    esac
fi

echo "PROFILE_NAME initialization complete"
exit 0
SCRIPT_HEREDOC_START

	# Replace placeholders
	sed -i "s/PROFILE_NAME/$profile/g" "$script_path"
	sed -i "s/APP_TIMEOUT_VALUE/$APP_TIMEOUT/g" "$script_path"
	sed -i "s/CHECK_INTERVAL_VALUE/$CHECK_INTERVAL/g" "$script_path"
	sed -i "s/WORKSPACE_VALUE/$workspace/g" "$script_path"
	sed -i "s/VPN_VALUE/$vpn/g" "$script_path"
	sed -i "s/FULLSCREEN_VALUE/$fullscreen/g" "$script_path"
	sed -i "s/WAIT_VALUE/$wait/g" "$script_path"
	sed -i "s|COMMAND_VALUE|$cmd|g" "$script_path"
	sed -i "s|ARGS_VALUE|$args|g" "$script_path"
	sed -i "s/CLASS_PATTERN_VALUE/$class_pattern/g" "$script_path"

	chmod +x "$script_path"
	log "SUCCESS" "GENERATE" "Generated: start-${profile}.sh"
}

generate_all_scripts() {
	log "INFO" "GENERATE" "Generating scripts for ALL profiles..."
	local count=0

	for profile in "${!TERMINALS[@]}"; do
		generate_script "$profile" "${TERMINALS[$profile]}"
		((count++))
	done

	for profile in "${!BRAVE_BROWSERS[@]}"; do
		generate_script "$profile" "${BRAVE_BROWSERS[$profile]}"
		((count++))
	done

	for profile in "${!ZEN_BROWSERS[@]}"; do
		generate_script "$profile" "${ZEN_BROWSERS[$profile]}"
		((count++))
	done

	for profile in "${!CHROME_BROWSERS[@]}"; do
		generate_script "$profile" "${CHROME_BROWSERS[$profile]}"
		((count++))
	done

	for profile in "${!APPS[@]}"; do
		generate_script "$profile" "${APPS[$profile]}"
		((count++))
	done

	log "SUCCESS" "GENERATE" "Generated $count unified scripts in $SCRIPTS_DIR"
}

generate_daily_scripts() {
	log "INFO" "GENERATE" "Generating daily/essential profiles..."
	local count=0

	for profile in "${!DAILY_PROFILES[@]}"; do
		local profile_type="${DAILY_PROFILES[$profile]}"
		local config=""

		case "$profile_type" in
		"TERMINALS") config="${TERMINALS[$profile]}" ;;
		"BRAVE_BROWSERS") config="${BRAVE_BROWSERS[$profile]}" ;;
		"APPS") config="${APPS[$profile]}" ;;
		esac

		if [[ -n "$config" ]]; then
			generate_script "$profile" "$config"
			((count++))
		fi
	done

	log "SUCCESS" "GENERATE" "Generated $count daily scripts"
}

clean_scripts() {
	log "INFO" "GENERATE" "Removing all generated scripts..."
	if [[ -d "$SCRIPTS_DIR" ]]; then
		rm -f "$SCRIPTS_DIR"/start-*.sh
		log "SUCCESS" "GENERATE" "All scripts removed"
	fi
}

#-------------------------------------------------------------------------------
# Launch Functions
#-------------------------------------------------------------------------------

ensure_windows_on_correct_workspace() {
	if [[ "$DRY_RUN" == "true" ]]; then
		return 0
	fi

	# Only works on Hyprland
	if [[ "$WM_TYPE" != "hyprland" ]]; then
		return 0
	fi

	if ! command -v hyprctl &>/dev/null || ! command -v jq &>/dev/null; then
		log "WARN" "WINDOW" "hyprctl or jq not available, skipping window workspace verification"
		return 0
	fi

	log "INFO" "WINDOW" "Ensuring all windows are on correct workspaces..."

	# Define window to workspace mappings
	declare -A WINDOW_WORKSPACE_MAP=(
		["discord|Discord"]="5"
		["spotify|Spotify"]="8"
		["ferdium|Ferdium"]="9"
	)

	local moved_count=0

	for class_pattern in "${!WINDOW_WORKSPACE_MAP[@]}"; do
		local target_workspace="${WINDOW_WORKSPACE_MAP[$class_pattern]}"

		# Check if window exists and move if needed
		if hyprctl clients -j 2>/dev/null | jq -e ".[] | select(.class | test(\"^($class_pattern)$\"; \"i\"))" >/dev/null 2>&1; then
			log "INFO" "WINDOW" "Moving windows matching '$class_pattern' to workspace $target_workspace"
			hyprctl dispatch movetoworkspacesilent "${target_workspace},class:^(${class_pattern})$" >/dev/null 2>&1
			((moved_count++))
			sleep 0.5
		fi
	done

	if [[ $moved_count -gt 0 ]]; then
		log "SUCCESS" "WINDOW" "Verified/moved $moved_count window type(s) to correct workspaces"
	else
		log "INFO" "WINDOW" "No windows needed repositioning"
	fi
}

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

	[[ -z "$workspace" ]] && workspace="0"
	[[ -z "$vpn" ]] && vpn="secure"
	[[ -z "$wait" ]] && wait="1"
	[[ -z "$fullscreen" ]] && fullscreen="false"

	if is_app_running "$profile"; then
		log "WARN" "LAUNCH" "$profile is already running"
		return 0
	fi

	setup_external_monitor
	switch_workspace "$workspace"
	log "INFO" "LAUNCH" "Starting $profile ($type, $WM_TYPE, workspace: $workspace)"

	if [[ "$DRY_RUN" == "true" ]]; then
		log "DEBUG" "LAUNCH" "Dry run: would start $profile"
		return 0
	fi

	case "$vpn" in
	bypass)
		if command -v mullvad >/dev/null 2>&1 && mullvad status 2>/dev/null | grep -q "Connected"; then
			if command -v mullvad-exclude >/dev/null 2>&1; then
				log "INFO" "LAUNCH" "Starting with VPN bypass"
				mullvad-exclude $cmd $args &
			else
				log "WARN" "LAUNCH" "mullvad-exclude not found"
				$cmd $args &
			fi
		else
			$cmd $args &
		fi
		;;
	secure | *)
		if command -v mullvad >/dev/null 2>&1 && mullvad status 2>/dev/null | grep -q "Connected"; then
			log "INFO" "LAUNCH" "Starting with VPN protection"
		else
			log "WARN" "LAUNCH" "VPN not connected!"
		fi
		$cmd $args &
		;;
	esac

	local app_pid=$!
	mkdir -p "/tmp/semsumo"
	echo "$app_pid" >"/tmp/semsumo/$profile.pid"

	if [[ "$workspace" != "0" ]]; then
		local class_pattern=$(get_class_pattern "$profile" "$args")
		check_window_on_workspace "$workspace" "$class_pattern" "$APP_TIMEOUT" "$CHECK_INTERVAL"
	else
		sleep "$wait"
	fi

	[[ "$fullscreen" == "true" ]] && make_fullscreen

	log "SUCCESS" "LAUNCH" "$profile started (PID: $app_pid)"
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

launch_daily_profiles() {
	log "INFO" "LAUNCH" "Starting daily/essential profiles on $WM_TYPE..."
	local daily_order=("kkenp" "brave-kenp" "brave-ai" "brave-compecta" "discord" "spotify" "ferdium" "brave-youtube")

	for profile in "${daily_order[@]}"; do
		if [[ -v DAILY_PROFILES["$profile"] ]]; then
			local profile_type="${DAILY_PROFILES[$profile]}"
			local config=""

			case "$profile_type" in
			"TERMINALS")
				config="${TERMINALS[$profile]}"
				launch_application "$profile" "$config" "terminal"
				;;
			"BRAVE_BROWSERS")
				config="${BRAVE_BROWSERS[$profile]}"
				launch_application "$profile" "$config" "brave"
				;;
			"APPS")
				config="${APPS[$profile]}"
				launch_application "$profile" "$config" "app"
				;;
			esac
		fi
	done

	log "SUCCESS" "LAUNCH" "Daily profiles launched"
}

#-------------------------------------------------------------------------------
# Nix Expression Generator
#-------------------------------------------------------------------------------

generate_nix_expressions() {
	log "INFO" "NIX-GEN" "Generating Nix expressions for script directories..."

	declare -A NIX_DIRECTORIES=(
		["bin"]="$HOME/.nixosc/modules/home/scripts/bin"
		["start"]="$HOME/.nixosc/modules/home/scripts/start"
	)

	local total_generated=0

	for dir_name in "${!NIX_DIRECTORIES[@]}"; do
		local script_dir="${NIX_DIRECTORIES[$dir_name]}"
		local output_file="$HOME/.nixosc/modules/home/scripts/${dir_name}.nix"

		log "INFO" "NIX-GEN" "Processing directory: $dir_name"

		# Header
		cat >"$output_file" <<'EOF'
{ pkgs, ... }:
let
EOF

		local script_count=0

		# Process scripts
		for script in "$script_dir"/*.sh "$script_dir"/t[1-9] "$script_dir"/tm; do
			[[ -f "$script" ]] || continue

			local filename=$(basename "$script")
			[[ $filename == _* ]] && continue

			local varname="${filename%.sh}"
			varname="${varname// /-}"
			varname="${varname//./-}"

			cat >>"$output_file" <<EOF
  ${varname} = pkgs.writeShellScriptBin "${varname}" (
    builtins.readFile ./${dir_name}/${filename}
  );
EOF
			((script_count++))
		done

		# Footer
		cat >>"$output_file" <<'EOF'
in {
  home.packages = with pkgs; [
EOF

		# Package list
		for script in "$script_dir"/*.sh "$script_dir"/t[1-9] "$script_dir"/tm; do
			[[ -f "$script" ]] || continue

			local filename=$(basename "$script")
			[[ $filename == _* ]] && continue

			local varname="${filename%.sh}"
			varname="${varname// /-}"
			varname="${varname//./-}"

			echo "    ${varname}" >>"$output_file"
		done

		cat >>"$output_file" <<'EOF'
  ];
}
EOF

		log "SUCCESS" "NIX-GEN" "Generated: ${dir_name}.nix ($script_count scripts)"
		((total_generated++))
	done

	log "SUCCESS" "NIX-GEN" "All Nix expressions generated ($total_generated files)"
}

#-------------------------------------------------------------------------------
# List and Status Functions
#-------------------------------------------------------------------------------

list_profiles() {
	echo -e "${BOLD}${CYAN}Available Profiles (Browser: $BROWSER_TYPE, WM: $WM_TYPE):${NC}\n"

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
}

check_status() {
	echo -e "${BOLD}${CYAN}Application Status (WM: $WM_TYPE):${NC}\n"

	local running_count=0
	local total_count=0

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

#-------------------------------------------------------------------------------
# Help Function
#-------------------------------------------------------------------------------

show_help() {
	echo -e "${BOLD}${GREEN}Semsumo v$VERSION - Unified Application Launcher${NC}"
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
	echo "    generate [profile]    Generate startup script(s)"
	echo "    launch [profile]      Launch application(s) directly"
	echo "    list                  List all available profiles"
	echo "    clean                 Remove all generated scripts"
	echo "    status                Show running applications status"
	echo "    kill                  Stop all managed applications"
	echo "    nix-gen               Generate Nix expressions for bin/ and start/ directories"
	echo "    help                  Show this help"
	echo
	echo -e "${BOLD}Generate Options:${NC}"
	echo "    --all                 Generate scripts for ALL profiles (all browsers)"
	echo "    --daily               Generate scripts for daily/essential profiles"
	echo
	echo -e "${BOLD}Launch Options:${NC}"
	echo "    --daily               Launch only daily/essential profiles"
	echo "    --workspace NUM       Final workspace (default: $DEFAULT_FINAL_WORKSPACE)"
	echo "    --timeout NUM         App verification timeout (default: $DEFAULT_APP_TIMEOUT)"
	echo
	echo -e "${BOLD}Global Options:${NC}"
	echo "    --dry-run             Test mode (don't actually run anything)"
	echo "    --debug               Enable debug output"
	echo
	echo -e "${BOLD}Features:${NC}"
	echo "    - Auto-detects window manager (Hyprland/GNOME/generic)"
	echo "    - Window verification on Hyprland (requires jq)"
	echo "    - VPN bypass/secure mode support (Mullvad)"
	echo "    - Multi-browser profile support"
	echo "    - Nix expression generator for home-manager integration"
	echo
	echo -e "${BOLD}Examples:${NC}"
	echo "    $0 generate --all                   # Generate ALL scripts"
	echo "    $0 generate --daily                 # Generate daily scripts only"
	echo "    $0 launch --daily                   # Launch daily profiles"
	echo "    $0 brave launch brave-kenp          # Launch specific profile"
	echo "    $0 list                             # List all profiles"
	echo "    $0 status                           # Check running apps"
	echo "    $0 nix-gen                          # Generate Nix expressions"
	echo
	echo -e "${BOLD}Detected:${NC} Window Manager = $WM_TYPE"
	echo -e "${BOLD}Locations:${NC}"
	echo "    Scripts: $SCRIPTS_DIR"
	echo "    Logs:    $LOG_FILE"
}

#-------------------------------------------------------------------------------
# Argument Parsing
#-------------------------------------------------------------------------------

parse_args() {
	if [[ $# -gt 0 && ("$1" == "brave" || "$1" == "zen" || "$1" == "chrome") ]]; then
		BROWSER_TYPE="$1"
		shift
	fi

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
	nix-gen)
		generate_nix_expressions
		exit 0
		;;
	help | --help | -h)
		show_help
		exit 0
		;;
	version | --version | -v)
		echo "Semsumo v$VERSION"
		exit 0
		;;
	*)
		log "ERROR" "ARGS" "Unknown command: $1"
		show_help
		exit 1
		;;
	esac

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
		--workspace)
			FINAL_WORKSPACE="$2"
			shift 2
			;;
		--timeout)
			APP_TIMEOUT="$2"
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
		"") break ;;
		*)
			SINGLE_PROFILE="$1"
			shift
			;;
		esac
	done
}

#-------------------------------------------------------------------------------
# Main Function
#-------------------------------------------------------------------------------

main() {
	local start_time=$(date +%s)

	detect_window_manager
	parse_args "$@"

	mkdir -p "$LOG_DIR"
	log "INFO" "START" "Semsumo v$VERSION started ($WM_TYPE, $BROWSER_TYPE)" "true"

	if [[ "$MODE_GENERATE" == "true" ]]; then
		if [[ "$LAUNCH_ALL" == "true" ]]; then
			generate_all_scripts
		elif [[ "$LAUNCH_DAILY" == "true" ]]; then
			generate_daily_scripts
		elif [[ -n "$SINGLE_PROFILE" ]]; then
			log "ERROR" "GENERATE" "Single profile generation not yet implemented in unified version"
			exit 1
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
			log "ERROR" "LAUNCH" "Please specify --daily or profile name"
			exit 1
		fi

		# Ensure all windows are on correct workspaces (Hyprland only)
		if [[ "$WM_TYPE" == "hyprland" ]]; then
			log "INFO" "WINDOW" "Verifying window positions..."
			sleep 2 # Give windows time to fully appear
			ensure_windows_on_correct_workspace
		fi

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

	log "SUCCESS" "DONE" "Completed ($WM_TYPE, $BROWSER_TYPE) - Time: ${total_time}s" "true"
}

# Check dependencies
check_dependencies() {
	local missing_deps=()

	case "$BROWSER_TYPE" in
	brave) command -v profile_brave >/dev/null 2>&1 || missing_deps+=("profile_brave") ;;
	zen) command -v zen >/dev/null 2>&1 || missing_deps+=("zen") ;;
	chrome) command -v profile_chrome >/dev/null 2>&1 || missing_deps+=("profile_chrome") ;;
	esac

	if [[ "$WM_TYPE" == "hyprland" ]] && ! command -v jq >/dev/null 2>&1; then
		log "WARN" "DEPS" "jq not found - window verification disabled"
	fi

	if [[ ${#missing_deps[@]} -gt 0 ]]; then
		log "WARN" "DEPS" "Missing: ${missing_deps[*]}"
	fi
}

trap 'log "ERROR" "TRAP" "Script interrupted"; exit 1' ERR INT TERM

check_dependencies
main "$@"
