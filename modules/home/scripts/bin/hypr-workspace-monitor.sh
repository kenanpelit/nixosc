#!/usr/bin/env bash
# hypr-workspace-monitor.sh - Hyprland workspace/monitor eşleştirici
# Çalışma alanlarını belirli monitörlere sabitleyip odak/taşıma işlemlerini yönetir.

#######################################
# HYPRFLOW - UNIFIED HYPRLAND CONTROL
#######################################
#
# Version: 2.0.0
# Date: 2025-11-04
# Original Authors: Kenan Pelit & Contributors
# Enhanced Unified Version
# Description: Complete Hyprland control suite combining workspace, monitor, and window management
#
# License: MIT
#
#######################################

# This unified script provides comprehensive control for the Hyprland window manager:
# - Monitor switching and focus control
# - Workspace navigation and management
# - Window focus and cycling
# - Browser tab navigation
# - Window movement between workspaces
# - Interactive app selection and movement
# - Quick workspace jumping
#
# Requirements:
#   - hyprctl: Hyprland control tool
#   - jq: JSON processing tool
#   - Optional: pypr, rofi/wofi/fuzzel, wtype/ydotool, notify-send
#
# Note:
#   - Script uses $HOME/.cache/hypr/toggle directory
#   - Directory will be created automatically if it doesn't exist
#   - Hyprland gestures must be turned off for some operations

# Enable strict mode
set -euo pipefail

# Ensure runtime metadata for non-login invocations (e.g., from services)
: "${XDG_RUNTIME_DIR:="/run/user/$(id -u)"}"
if [ -z "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]; then
	# Grab the first available Hyprland instance if none exported
	if first_sig=$(ls "$XDG_RUNTIME_DIR"/hypr 2>/dev/null | head -n1); then
		export HYPRLAND_INSTANCE_SIGNATURE="$first_sig"
	fi
fi

# Ensure common Nix profiles are in PATH so dependencies resolve when invoked from minimal services
PATH="/run/current-system/sw/bin:/etc/profiles/per-user/${USER}/bin:${PATH}"

#######################################
# CONFIGURATION & CONSTANTS
#######################################

readonly VERSION="2.0.0"
readonly CACHE_DIR="$HOME/.cache/hypr/toggle"
readonly STATE_FILE="$CACHE_DIR/focus_state"
readonly CURRENT_WS_FILE="$CACHE_DIR/current_workspace"
readonly PREVIOUS_WS_FILE="$CACHE_DIR/previous_workspace"
readonly DEBUG_FILE="$CACHE_DIR/debug.log"
readonly NOTIFICATION_TIMEOUT=3000
readonly SCRIPT_NAME="HyprFlow"
readonly MAX_WORKSPACE=20

# Terminal colors
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly MAGENTA='\033[0;35m'
readonly NC='\033[0m'

# Default values
debug=false
silent=false

#######################################
# INITIALIZATION
#######################################

init_environment() {
	# Create cache directory
	mkdir -p "$CACHE_DIR"

	# Create state file with default value if it doesn't exist
	if [ ! -f "$STATE_FILE" ]; then
		echo "up" >"$STATE_FILE"
	fi

	# Initialize workspace tracking files
	init_workspace_files
}

init_workspace_files() {
	local current_ws
	current_ws=$(get_current_workspace 2>/dev/null || echo "1")

	if [ ! -f "$CURRENT_WS_FILE" ]; then
		safe_write_file "$CURRENT_WS_FILE" "$current_ws"
	fi

	if [ ! -f "$PREVIOUS_WS_FILE" ]; then
		safe_write_file "$PREVIOUS_WS_FILE" "1"
	fi
}

#######################################
# LOGGING FUNCTIONS
#######################################

log() {
	local msg="$1"
	local level="${2:-INFO}"
	local color=""

	case "$level" in
	ERROR) color=$RED ;;
	SUCCESS) color=$GREEN ;;
	WARNING) color=$YELLOW ;;
	INFO) color=$BLUE ;;
	DEBUG) color=$CYAN ;;
	esac

	local timestamp
	timestamp=$(date '+%H:%M:%S')

	echo -e "${color}[${timestamp}] [$level] $msg${NC}" >&2
	echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $msg" >>"$DEBUG_FILE"
}

log_info() {
	log "$1" "INFO"
}

log_error() {
	log "$1" "ERROR"
}

log_success() {
	log "$1" "SUCCESS"
}

log_warning() {
	log "$1" "WARNING"
}

log_debug() {
	if $debug; then
		log "$1" "DEBUG"
	fi
}

notify() {
	local title="$1"
	local message="$2"
	local urgency="${3:-normal}"

	if [ "$silent" = false ] && command -v notify-send >/dev/null 2>&1; then
		notify-send -u "$urgency" -t "$NOTIFICATION_TIMEOUT" "$title" "$message"
	fi
}

#######################################
# VALIDATION FUNCTIONS
#######################################

validate_workspace() {
	local ws=$1
	if ! [[ "$ws" =~ ^[0-9]+$ ]]; then
		log_error "Invalid workspace number: $ws (must be a positive integer)"
		return 1
	fi
	if [ "$ws" -lt 1 ] || [ "$ws" -gt "$MAX_WORKSPACE" ]; then
		log_error "Workspace number out of range: $ws (valid range: 1-${MAX_WORKSPACE})"
		return 1
	fi
	return 0
}

validate_dependencies() {
	local required_deps=("hyprctl" "jq")
	local optional_deps=("pypr" "rofi" "wofi" "fuzzel" "wtype" "ydotool" "notify-send")
	local missing_required=()
	local missing_optional=()

	# Check required dependencies
	for dep in "${required_deps[@]}"; do
		if ! command -v "$dep" &>/dev/null; then
			missing_required+=("$dep")
		fi
	done

	if [ ${#missing_required[@]} -gt 0 ]; then
		log_error "Missing required dependencies: ${missing_required[*]}"
		log_error "Please install the missing dependencies and try again"
		exit 1
	fi

	# Check optional dependencies
	for dep in "${optional_deps[@]}"; do
		if ! command -v "$dep" &>/dev/null; then
			missing_optional+=("$dep")
		fi
	done

	if [ ${#missing_optional[@]} -gt 0 ]; then
		log_debug "Optional dependencies not found: ${missing_optional[*]}"
		log_debug "Some features may be limited"
	fi
}

#######################################
# SAFE FILE OPERATIONS
#######################################

safe_read_file() {
	local file=$1
	local default=${2:-"1"}

	if [ -f "$file" ] && [ -r "$file" ]; then
		local content
		content=$(cat "$file" 2>/dev/null | head -1 | tr -d '\n\r')
		if [[ "$content" =~ ^[0-9]+$ ]] && [ "$content" -ge 1 ] && [ "$content" -le "$MAX_WORKSPACE" ]; then
			echo "$content"
		else
			log_debug "Invalid content in $file: '$content', using default: $default"
			echo "$default"
		fi
	else
		log_debug "File $file not readable, using default: $default"
		echo "$default"
	fi
}

safe_write_file() {
	local file=$1
	local content=$2

	if validate_workspace "$content"; then
		echo "$content" >"$file" 2>/dev/null || log_error "Failed to write to $file"
	else
		log_error "Attempted to write invalid workspace number: $content"
	fi
}

#######################################
# WORKSPACE QUERY FUNCTIONS
#######################################

get_current_workspace() {
	hyprctl monitors -j | jq -r '.[] | select(.focused==true) | .activeWorkspace.name'
}

get_previous_workspace() {
	safe_read_file "$PREVIOUS_WS_FILE" "1"
}

get_current_monitor() {
	hyprctl monitors -j | jq -r '.[] | select(.focused==true).name'
}

get_all_monitors() {
	hyprctl monitors -j | jq -r '.[].name'
}

get_workspaces_for_monitor() {
	local monitor=$1
	hyprctl workspaces -j | jq -r ".[] | select(.monitor==\"$monitor\") | select(.name!=\"special\") | .name" | sort -n
}

get_all_workspaces() {
	hyprctl workspaces -j | jq -r '.[] | select(.name!="special") | .name' | sort -n
}

get_apps_in_workspace() {
	local workspace="$1"
	hyprctl clients -j | jq -r --arg ws "$workspace" \
		'.[] | select(.workspace.id == ($ws | tonumber)) | 
		"\(.address)|\(.class)|\(.title)|\(.pid)"'
}

get_app_count() {
	local workspace="$1"
	hyprctl clients -j | jq --arg ws "$workspace" \
		'[.[] | select(.workspace.id == ($ws | tonumber))] | length'
}

get_focused_window() {
	hyprctl activewindow -j | jq -r '.address'
}

format_app_info() {
	local address="$1"
	hyprctl clients -j | jq -r --arg addr "$address" \
		'.[] | select(.address == $addr) | 
		"\(.class) - \(.title[0:50])"' 2>/dev/null || echo "Application"
}

#######################################
# WORKSPACE MANAGEMENT
#######################################

update_workspace_history() {
	local new_ws
	new_ws=$(get_current_workspace)

	if ! validate_workspace "$new_ws"; then
		log_error "Current workspace validation failed: $new_ws"
		return 1
	fi

	log_debug "Updating workspace history. New workspace: $new_ws"

	local old_ws
	old_ws=$(safe_read_file "$CURRENT_WS_FILE" "1")
	log_debug "Current workspace from file: $old_ws"

	if [ "$new_ws" != "$old_ws" ]; then
		safe_write_file "$PREVIOUS_WS_FILE" "$old_ws"
		log_debug "Updated previous workspace to: $old_ws"
	fi

	safe_write_file "$CURRENT_WS_FILE" "$new_ws"
	log_debug "Updated current workspace to: $new_ws"
}

switch_to_workspace() {
	local next_ws=$1

	if ! validate_workspace "$next_ws"; then
		log_error "Cannot switch to invalid workspace: $next_ws"
		return 1
	fi

	local current_ws
	current_ws=$(get_current_workspace)
	log_debug "Switching from workspace $current_ws to $next_ws"

	safe_write_file "$PREVIOUS_WS_FILE" "$current_ws"
	hyprctl dispatch workspace name:$next_ws
	safe_write_file "$CURRENT_WS_FILE" "$next_ws"

	log_debug "Switch complete. Previous workspace set to $current_ws"
}

switch_workspace_direction() {
	local direction=$1
	local current_ws
	current_ws=$(get_current_workspace)

	log_debug "Switching workspace direction: $direction from current $current_ws"
	safe_write_file "$PREVIOUS_WS_FILE" "$current_ws"

	case $direction in
	"left" | "Left" | "-1")
		hyprctl dispatch workspace m-1
		;;
	"right" | "Right" | "+1")
		hyprctl dispatch workspace m+1
		;;
	esac

	local new_ws
	new_ws=$(get_current_workspace)
	safe_write_file "$CURRENT_WS_FILE" "$new_ws"

	log_debug "Switch direction complete. New workspace: $new_ws"
}

clear_workspace_history() {
	log_info "Clearing workspace history files"
	rm -f "$CURRENT_WS_FILE" "$PREVIOUS_WS_FILE"

	local current_ws
	current_ws=$(get_current_workspace 2>/dev/null || echo "1")
	safe_write_file "$CURRENT_WS_FILE" "$current_ws"
	safe_write_file "$PREVIOUS_WS_FILE" "1"

	log_info "Workspace history files reset"
}

#######################################
# WINDOW MANAGEMENT
#######################################

move_window() {
	local target_workspace="$1"
	local app_address="$2"
	local focus="${3:-false}"

	if ! hyprctl dispatch movetoworkspace "$target_workspace,address:$app_address" >/dev/null 2>&1; then
		log_error "Failed to move window: $app_address"
		return 1
	fi

	if [ "$focus" = "true" ]; then
		hyprctl dispatch focuswindow "address:$app_address" >/dev/null 2>&1
	fi

	return 0
}

move_window_to_workspace() {
	local target_ws=$1

	if ! validate_workspace "$target_ws"; then
		log_error "Cannot move window to invalid workspace: $target_ws"
		return 1
	fi

	local focused_window
	focused_window=$(get_focused_window)

	if [ "$focused_window" != "null" ] && [ -n "$focused_window" ]; then
		log_debug "Moving window $focused_window to workspace $target_ws"
		hyprctl dispatch movetoworkspace "$target_ws"
		hyprctl dispatch workspace "$target_ws"
		safe_write_file "$CURRENT_WS_FILE" "$target_ws"
	else
		log_error "No focused window to move"
		return 1
	fi
}

#######################################
# APP MOVER FUNCTIONS
#######################################

interactive_select() {
	local workspace="$1"
	local selector=""

	if command -v rofi >/dev/null 2>&1; then
		selector="rofi"
	elif command -v wofi >/dev/null 2>&1; then
		selector="wofi"
	elif command -v fuzzel >/dev/null 2>&1; then
		selector="fuzzel"
	else
		log_error "No selector found (rofi/wofi/fuzzel)"
		notify "$SCRIPT_NAME" "Install rofi, wofi, or fuzzel for interactive mode" "critical"
		return 1
	fi

	local apps
	apps=$(get_apps_in_workspace "$workspace")

	if [ -z "$apps" ]; then
		return 1
	fi

	local display_list=""
	while IFS='|' read -r addr class title pid; do
		display_list+="${class} - ${title}\n"
	done <<<"$apps"

	local selected
	case "$selector" in
	rofi)
		selected=$(echo -e "$display_list" | rofi -dmenu -i -p "Select app from workspace $workspace:")
		;;
	wofi)
		selected=$(echo -e "$display_list" | wofi --dmenu -i -p "Select app from workspace $workspace:")
		;;
	fuzzel)
		selected=$(echo -e "$display_list" | fuzzel --dmenu -p "Select app from workspace $workspace: ")
		;;
	esac

	if [ -z "$selected" ]; then
		return 1
	fi

	while IFS='|' read -r addr class title pid; do
		local display="${class} - ${title}"
		if [ "$display" = "$selected" ]; then
			echo "$addr"
			return 0
		fi
	done <<<"$apps"

	return 1
}

move_apps_from_workspace() {
	local source_workspace="$1"
	local move_all="${2:-false}"
	local interactive="${3:-false}"
	local focus_window="${4:-false}"

	if ! validate_workspace "$source_workspace"; then
		return 1
	fi

	local current_workspace
	current_workspace=$(get_current_workspace)

	if [ "$source_workspace" -eq "$current_workspace" ]; then
		notify "$SCRIPT_NAME" "Already in workspace $source_workspace" "normal"
		return 0
	fi

	local apps
	apps=$(get_apps_in_workspace "$source_workspace")
	local app_count
	app_count=$(get_app_count "$source_workspace")

	if [ -z "$apps" ] || [ "$app_count" -eq 0 ]; then
		notify "$SCRIPT_NAME" "No applications in workspace $source_workspace" "normal"
		log_warning "No applications found in workspace $source_workspace"
		return 1
	fi

	log_debug "Found $app_count app(s) in workspace $source_workspace"

	local moved_count=0
	local moved_names=()

	if [ "$interactive" = "true" ]; then
		local selected_addr
		selected_addr=$(interactive_select "$source_workspace")

		if [ -n "$selected_addr" ]; then
			local app_info
			app_info=$(format_app_info "$selected_addr")

			if move_window "$current_workspace" "$selected_addr" "$focus_window"; then
				moved_count=1
				moved_names+=("$app_info")
				log_success "Moved: $app_info"
			fi
		fi

	elif [ "$move_all" = "true" ]; then
		while IFS='|' read -r addr class title pid; do
			local app_info="${class} - ${title:0:30}"

			if move_window "$current_workspace" "$addr" "$focus_window"; then
				moved_count=$((moved_count + 1))
				moved_names+=("$app_info")
				log_debug "Moved: $app_info"
			fi
		done <<<"$apps"

	else
		local first_addr
		first_addr=$(echo "$apps" | head -1 | cut -d'|' -f1)
		local app_info
		app_info=$(format_app_info "$first_addr")

		if move_window "$current_workspace" "$first_addr" "$focus_window"; then
			moved_count=1
			moved_names+=("$app_info")
			log_success "Moved: $app_info"
		fi
	fi

	if [ $moved_count -gt 0 ]; then
		if [ $moved_count -eq 1 ]; then
			notify "$SCRIPT_NAME" "Moved ${moved_names[0]} from WS$source_workspace → WS$current_workspace" "normal"
		else
			notify "$SCRIPT_NAME" "Moved $moved_count apps from WS$source_workspace → WS$current_workspace" "normal"
		fi
	else
		log_warning "No windows were moved"
		return 1
	fi

	log_success "Successfully moved $moved_count window(s)"
	return 0
}

#######################################
# MONITOR MANAGEMENT
#######################################

toggle_monitor_focus() {
	local current_state
	current_state=$(cat "$STATE_FILE" 2>/dev/null || echo "up")

	log_debug "Toggling monitor focus, current state: $current_state"

	if [ "$current_state" = "up" ]; then
		hyprctl dispatch movefocus d
		echo "down" >"$STATE_FILE"
		log_debug "Focus changed to: down"
	else
		hyprctl dispatch movefocus u
		echo "up" >"$STATE_FILE"
		log_debug "Focus changed to: up"
	fi
}

#######################################
# BROWSER TAB MANAGEMENT
#######################################

navigate_browser_tab() {
	local direction=$1
	local current_window
	current_window=$(hyprctl activewindow -j | jq -r '.class')

	log_debug "Navigating browser tab $direction in window class: $current_window"

	if [[ "$current_window" == *"brave"* || "$current_window" == *"Brave"* ]]; then
		if [ "$direction" = "next" ]; then
			hyprctl dispatch exec "wtype -P ctrl -p tab -r tab -R ctrl"
		else
			hyprctl dispatch exec "wtype -P ctrl -P shift -p tab -r tab -R shift -R ctrl"
		fi
	else
		if [ "$direction" = "next" ]; then
			wtype -M ctrl -k tab 2>/dev/null || ydotool key ctrl+tab 2>/dev/null
		else
			wtype -M ctrl -M shift -k tab 2>/dev/null || ydotool key ctrl+shift+tab 2>/dev/null
		fi
	fi
}

#######################################
# HELP SYSTEM
#######################################

show_help() {
	cat <<EOF
╭─────────────────────────────────────────────────────────────────╮
│              🚀 HyprFlow - Unified Hyprland Control             │
│                        Version ${VERSION}                           │
╰─────────────────────────────────────────────────────────────────╯

📋 QUICK REFERENCE (Most Used Commands):
  $0 -wt           ← Go to previous workspace (super useful!)
  $0 -wn 5         ← Jump to workspace 5
  $0 -mw 3         ← Move current window to workspace 3
  $0 -wr/-wl       ← Navigate workspaces left/right
  $0 -am 9         ← Move app FROM workspace 9 to current workspace
  $0 -am -i 9      ← Interactively select app to move from workspace 9

🖥️  MONITOR OPERATIONS:
  -ms              Shift monitors without focus
  -msf             Shift monitors with focus  
  -mt              Toggle monitor focus (up/down)
  -ml              Switch to left monitor
  -mr              Switch to right monitor
  -mn              Switch to next monitor
  -mp              Switch to previous monitor

🏠 WORKSPACE OPERATIONS:
  -wt              Switch to previous workspace ⭐
  -wr              Switch to workspace on the right
  -wl              Switch to workspace on the left  
  -wn NUM          Jump to workspace NUM (1-10)
  -mw NUM          Move focused window to workspace NUM

📦 APP MOVER OPERATIONS:
  -am NUM          Move first app FROM workspace NUM to current
  -am -a NUM       Move ALL apps FROM workspace NUM to current
  -am -i NUM       Interactive: select which app to move FROM workspace NUM
  -am -f NUM       Move app and focus it
  -am -a -f NUM    Move all apps and focus the first one

🪟 WINDOW FOCUS OPERATIONS:
  -vn              Cycle to next window
  -vp              Cycle to previous window
  -vl/-vr          Move focus left/right
  -vu/-vd          Move focus up/down

🌐 BROWSER TAB OPERATIONS:
  -tn              Next browser tab
  -tp              Previous browser tab
  
🛠️  MAINTENANCE & OPTIONS:
  -h, --help       Show this help message
  -d, --debug      Debug mode (detailed output)
  -s, --silent     Silent mode (no notifications)
  -c, --clear      Clear workspace history files
  -v, --version    Show version information

📝 EXAMPLES:
  # Workspace Navigation
  $0 -wn 5                    # Jump to workspace 5
  $0 -wt                      # Go to previous workspace
  $0 -wr                      # Move to next workspace
  
  # Window Management
  $0 -mw 3                    # Move current window to workspace 3
  $0 -vn                      # Focus next window
  
  # App Moving (NEW!)
  $0 -am 9                    # Move first app from workspace 9 here
  $0 -am -a 9                 # Move ALL apps from workspace 9 here
  $0 -am -i 9                 # Choose which app to move from workspace 9
  $0 -am -f 9                 # Move app from workspace 9 and focus it
  
  # Monitor Operations
  $0 -ms                      # Shift monitors
  $0 -mt                      # Toggle monitor focus
  
  # Debug & Maintenance
  $0 -d -wn 2                 # Jump to workspace 2 with debug output
  $0 -c                       # Reset workspace history

💡 TIPS:
  • Use -wt frequently to toggle between two workspaces
  • Combine -d with any command for troubleshooting
  • Use -am -i for interactive app selection with rofi/wofi
  • Use -am -a to quickly gather all apps from a workspace
  • Workspace numbers must be between 1-10
  • Browser tab navigation works with: Firefox, Chrome, Chromium, Brave

🔧 REQUIREMENTS:
  Required:  hyprctl, jq
  Optional:  pypr, rofi/wofi/fuzzel, wtype/ydotool, notify-send

📚 KEYBINDING EXAMPLES (add to hyprland.conf):
  # Quick workspace switching
  bind = SUPER CTRL, 1, exec, $0 -wn 1
  bind = SUPER CTRL, 2, exec, $0 -wn 2
  
  # Move current window to workspace
  bind = SUPER SHIFT, 1, exec, $0 -mw 1
  bind = SUPER SHIFT, 2, exec, $0 -mw 2
  
  # Pull apps from other workspaces
  bind = SUPER ALT, 1, exec, $0 -am 1
  bind = SUPER ALT, 2, exec, $0 -am -i 2
  
  # Navigation
  bind = SUPER, TAB, exec, $0 -wt
  bind = SUPER, left, exec, $0 -wl
  bind = SUPER, right, exec, $0 -wr

Version: ${VERSION} | License: MIT
Report issues: Check logs in ~/.cache/hypr/toggle/debug.log
EOF
}

show_version() {
	cat <<EOF
HyprFlow - Unified Hyprland Control
Version: ${VERSION}
Date: 2025-11-04
License: MIT

A comprehensive Hyprland control suite combining:
  - Workspace management
  - Monitor control
  - Window operations
  - App movement between workspaces
  - Browser tab navigation

Original Authors: Kenan Pelit & Contributors
EOF
}

#######################################
# MAIN EXECUTION
#######################################

main() {
	# Initialize environment
	init_environment

	# Show help if no arguments
	if [ $# -eq 0 ]; then
		show_help
		exit 0
	fi

	# Validate dependencies
	validate_dependencies

	# Parse arguments
	while [[ $# -gt 0 ]]; do
		case $1 in
		-h | --help)
			show_help
			exit 0
			;;
		-v | --version)
			show_version
			exit 0
			;;
		-d | --debug)
			debug=true
			log_info "Debug mode enabled"
			shift
			;;
		-s | --silent)
			silent=true
			log_debug "Silent mode enabled"
			shift
			;;
		-c | --clear)
			clear_workspace_history
			exit 0
			;;
		# Monitor operations
		-ms)
			if command -v pypr &>/dev/null; then
				log_debug "Shifting monitors without focus"
				pypr shift_monitors "+1"
			else
				log_error "pypr not found - cannot shift monitors"
				exit 1
			fi
			shift
			;;
		-msf)
			if command -v pypr &>/dev/null; then
				log_debug "Shifting monitors with focus"
				pypr shift_monitors "+1"
				hyprctl dispatch focusmonitor "+1"
			else
				log_error "pypr not found - cannot shift monitors"
				exit 1
			fi
			shift
			;;
		-mt)
			log_debug "Toggling monitor focus"
			toggle_monitor_focus
			shift
			;;
		-ml)
			log_debug "Focusing left monitor"
			hyprctl dispatch focusmonitor l
			shift
			;;
		-mr)
			log_debug "Focusing right monitor"
			hyprctl dispatch focusmonitor r
			shift
			;;
		-mn)
			log_debug "Focusing next monitor"
			hyprctl dispatch focusmonitor "+1"
			shift
			;;
		-mp)
			log_debug "Focusing previous monitor"
			hyprctl dispatch focusmonitor "-1"
			shift
			;;
		# Workspace operations
		-wt)
			log_debug "Switching to previous workspace"
			prev_ws=$(get_previous_workspace)
			log_debug "Previous workspace is: $prev_ws"
			switch_to_workspace "$prev_ws"
			shift
			;;
		-wr)
			log_debug "Switching to workspace on right"
			switch_workspace_direction "right"
			shift
			;;
		-wl)
			log_debug "Switching to workspace on left"
			switch_workspace_direction "left"
			shift
			;;
		-wn)
			if [[ -z "${2:-}" ]]; then
				log_error "Workspace number is required for -wn"
				log_info "Usage: $0 -wn <workspace_number> (1-10)"
				exit 1
			fi

			if ! validate_workspace "$2"; then
				exit 1
			fi

			log_debug "Jumping to workspace $2"
			current_ws=$(get_current_workspace)
			safe_write_file "$PREVIOUS_WS_FILE" "$current_ws"
			hyprctl dispatch workspace "$2"
			safe_write_file "$CURRENT_WS_FILE" "$2"
			log_debug "Switched from workspace $current_ws to $2"
			shift 2
			;;
		-mw)
			if [[ -z "${2:-}" ]]; then
				log_error "Workspace number is required for -mw"
				log_info "Usage: $0 -mw <workspace_number> (1-10)"
				exit 1
			fi

			if ! validate_workspace "$2"; then
				exit 1
			fi

			log_debug "Moving window to workspace $2"
			move_window_to_workspace "$2"
			shift 2
			;;
		# App mover operations
		-am)
			shift
			local move_all=false
			local interactive=false
			local focus_window=false
			local source_ws=""

			# Parse app mover sub-options
			while [[ $# -gt 0 ]]; do
				case $1 in
				-a)
					move_all=true
					shift
					;;
				-i)
					interactive=true
					shift
					;;
				-f)
					focus_window=true
					shift
					;;
				[0-9] | [0-9][0-9])
					source_ws=$1
					shift
					break
					;;
				*)
					log_error "Invalid option for -am: $1"
					exit 1
					;;
				esac
			done

			if [ -z "$source_ws" ]; then
				log_error "Workspace number required for -am"
				log_info "Usage: $0 -am [-a] [-i] [-f] <workspace_number>"
				exit 1
			fi

			log_debug "Moving apps from workspace $source_ws (all=$move_all, interactive=$interactive, focus=$focus_window)"
			move_apps_from_workspace "$source_ws" "$move_all" "$interactive" "$focus_window"
			;;
		# Window focus operations
		-vn)
			log_debug "Cycling to next window"
			hyprctl dispatch cyclenext
			shift
			;;
		-vp)
			log_debug "Cycling to previous window"
			hyprctl dispatch cyclenext prev
			shift
			;;
		-vl)
			log_debug "Moving focus left"
			hyprctl dispatch movefocus l
			shift
			;;
		-vr)
			log_debug "Moving focus right"
			hyprctl dispatch movefocus r
			shift
			;;
		-vu)
			log_debug "Moving focus up"
			hyprctl dispatch movefocus u
			shift
			;;
		-vd)
			log_debug "Moving focus down"
			hyprctl dispatch movefocus d
			shift
			;;
		# Browser tab operations
		-tn)
			log_debug "Navigating to next browser tab"
			navigate_browser_tab "next"
			shift
			;;
		-tp)
			log_debug "Navigating to previous browser tab"
			navigate_browser_tab "prev"
			shift
			;;
		*)
			log_error "Invalid option: $1"
			log_info "Use $0 -h for help"
			exit 1
			;;
		esac
	done
}

# Run main function
main "$@"
