#!/usr/bin/env bash

#######################################
# HYPRLAND MONITOR & WORKSPACE CONTROL
#######################################
#
# Version: 1.4.0
# Date: 2025-06-22
# Original Author: Kenan Pelit
# Enhanced Version: With validation and improved help
# Description: HyprFlow - Enhanced Hyprland Control Tool
#
# License: MIT
#
#######################################

# This script provides monitor and workspace control for the Hyprland
# window manager. It manages operations such as:
# - Monitor switching and focus control
# - Workspace navigation and management
# - Window focus and cycling
# - Browser tab navigation
# - Window movement between workspaces
# - Quick workspace jumping
#
# Requirements:
#   - hyprctl: Hyprland control tool
#   - pypr: Hyprland Python tool
#   - jq: JSON processing tool
#   - ydotool or wtype: Wayland automation tools
#
# Installation:
#   The above tools must be installed on your system
#   to run this script.
#
# Note:
#   Script uses $HOME/.cache/hypr/toggle directory
#   Directory will be created automatically if it doesn't exist
#   Also, hyperland gestures must be turned off

# Enable strict mode
set -euo pipefail

# Constants
readonly CACHE_DIR="$HOME/.cache/hypr/toggle"
readonly STATE_FILE="$CACHE_DIR/focus_state"
readonly CURRENT_WS_FILE="$CACHE_DIR/current_workspace"
readonly PREVIOUS_WS_FILE="$CACHE_DIR/previous_workspace"
readonly DEBUG_FILE="$CACHE_DIR/debug.log"

# Create cache directory if it doesn't exist
mkdir -p "$CACHE_DIR"

# Create state file with default value if it doesn't exist
if [ ! -f "$STATE_FILE" ]; then
	echo "up" >"$STATE_FILE"
fi

#######################################
# Validation Functions
#######################################

validate_workspace() {
	local ws=$1
	if ! [[ "$ws" =~ ^[0-9]+$ ]]; then
		log_error "Invalid workspace number: $ws (must be a positive integer)"
		return 1
	fi
	if [ "$ws" -lt 1 ] || [ "$ws" -gt 10 ]; then
		log_error "Workspace number out of range: $ws (valid range: 1-10)"
		return 1
	fi
	return 0
}

validate_dependencies() {
	local deps=("hyprctl" "jq")
	local missing_deps=()

	for dep in "${deps[@]}"; do
		if ! command -v "$dep" &>/dev/null; then
			missing_deps+=("$dep")
		fi
	done

	# Check optional dependencies
	if ! command -v "pypr" &>/dev/null; then
		log_debug "pypr not found - monitor shifting will not work"
	fi

	if ! command -v "wtype" &>/dev/null && ! command -v "ydotool" &>/dev/null; then
		log_debug "Neither wtype nor ydotool found - browser tab navigation may not work"
	fi

	if [ ${#missing_deps[@]} -gt 0 ]; then
		log_error "Missing required dependencies: ${missing_deps[*]}"
		log_error "Please install the missing dependencies and try again"
		exit 1
	fi
}

#######################################
# Safe File Operations
#######################################

safe_read_file() {
	local file=$1
	local default=${2:-"1"}

	if [ -f "$file" ] && [ -r "$file" ]; then
		local content
		content=$(cat "$file" 2>/dev/null | head -1 | tr -d '\n\r')
		if [[ "$content" =~ ^[0-9]+$ ]] && [ "$content" -ge 1 ] && [ "$content" -le 10 ]; then
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

# Initialize workspace tracking files with safe operations
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
# Logging Functions
#######################################

log_info() {
	echo "[INFO] $1" >&2
	echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] $1" >>"$DEBUG_FILE"
}

log_error() {
	echo "[ERROR] $1" >&2
	echo "[$(date '+%Y-%m-%d %H:%M:%S')] [ERROR] $1" >>"$DEBUG_FILE"
}

log_debug() {
	if $debug; then
		echo "[DEBUG] $1" >&2
		echo "[$(date '+%Y-%m-%d %H:%M:%S')] [DEBUG] $1" >>"$DEBUG_FILE"
	fi
}

#######################################
# Workspace Management Functions
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

# Update workspace history - enhanced with validation
update_workspace_history() {
	local new_ws
	new_ws=$(get_current_workspace)

	if ! validate_workspace "$new_ws"; then
		log_error "Current workspace validation failed: $new_ws"
		return 1
	fi

	log_debug "Updating workspace history. New workspace: $new_ws"

	# Read current workspace safely
	local old_ws
	old_ws=$(safe_read_file "$CURRENT_WS_FILE" "1")
	log_debug "Current workspace from file: $old_ws"

	# If workspace changed, update previous
	if [ "$new_ws" != "$old_ws" ]; then
		safe_write_file "$PREVIOUS_WS_FILE" "$old_ws"
		log_debug "Updated previous workspace to: $old_ws"
	fi

	# Always update current workspace
	safe_write_file "$CURRENT_WS_FILE" "$new_ws"
	log_debug "Updated current workspace to: $new_ws"

	# Verify files were updated
	log_debug "Current workspace file now contains: $(safe_read_file "$CURRENT_WS_FILE")"
	log_debug "Previous workspace file now contains: $(safe_read_file "$PREVIOUS_WS_FILE")"
}

switch_to_workspace() {
	local next_ws=$1

	if ! validate_workspace "$next_ws"; then
		log_error "Cannot switch to invalid workspace: $next_ws"
		return 1
	fi

	# Get current workspace before switching
	local current_ws
	current_ws=$(get_current_workspace)
	log_debug "Switching from workspace $current_ws to $next_ws"

	# Save current as previous before switching
	safe_write_file "$PREVIOUS_WS_FILE" "$current_ws"

	# Switch to target workspace
	hyprctl dispatch workspace name:$next_ws

	# Update current workspace after switching
	safe_write_file "$CURRENT_WS_FILE" "$next_ws"

	log_debug "Switch complete. Previous workspace set to $current_ws"
}

switch_workspace_direction() {
	local direction=$1
	local current_ws
	current_ws=$(get_current_workspace)

	log_debug "Switching workspace direction: $direction from current $current_ws"

	# Save current as previous before switching
	safe_write_file "$PREVIOUS_WS_FILE" "$current_ws"

	# Use simple dispatch commands for left/right navigation
	case $direction in
	"Left")
		log_debug "Dispatching workspace to previous"
		hyprctl dispatch workspace m-1
		;;
	"Right")
		log_debug "Dispatching workspace to next"
		hyprctl dispatch workspace m+1
		;;
	esac

	# Update current workspace after switching
	local new_ws
	new_ws=$(get_current_workspace)
	safe_write_file "$CURRENT_WS_FILE" "$new_ws"

	log_debug "Switch direction complete. New workspace: $new_ws"
}

#######################################
# Window Management Functions
#######################################

get_focused_window() {
	hyprctl activewindow -j | jq -r '.address'
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

		# Update workspace tracking
		safe_write_file "$CURRENT_WS_FILE" "$target_ws"
	else
		log_error "No focused window to move"
		return 1
	fi
}

#######################################
# Monitor Management Functions
#######################################

toggle_monitor_focus() {
	# Read current state
	local current_state
	current_state=$(cat "$STATE_FILE" 2>/dev/null || echo "up")

	log_debug "Toggling monitor focus, current state: $current_state"

	# Change focus and save new state based on current state
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
# Browser Tab Management Functions
#######################################

navigate_browser_tab() {
	local direction=$1
	local current_window
	current_window=$(hyprctl activewindow -j | jq -r '.class')

	log_debug "Navigating browser tab $direction in window class: $current_window"

	# Browser detection - geniş pattern matching
	case "$current_window" in
	*"brave"* | *"Brave"* | *"firefox"* | *"Firefox"* | *"chromium"* | *"Chromium"* | *"google-chrome"* | *"Google-chrome"* | *"zen"* | *"Zen"*)
		log_debug "Browser detected: $current_window"

		# ESKI SCRIPT'TEKİ GİBİ hyprctl dispatch exec kullan!
		if [ "$direction" = "next" ]; then
			hyprctl dispatch exec "wtype -P ctrl -p Tab -r Tab -R ctrl"
		else
			hyprctl dispatch exec "wtype -P ctrl -P shift -p Tab -r Tab -R shift -R ctrl"
		fi
		;;
	*)
		log_error "Browser not supported or no browser focused: $current_window"
		log_error "Supported browsers: brave, firefox, chromium, google-chrome, zen"
		return 1
		;;
	esac
}

#######################################
# Help Message Function (Enhanced)
#######################################

show_help() {
	cat <<EOF
╭─────────────────────────────────────────────────────────────╮
│                🚀 HyprFlow - Hyprland Control                │
│                     Enhanced Version 1.4.0                  │
╰─────────────────────────────────────────────────────────────╯

📋 QUICK REFERENCE (Most Used Commands):
  $0 -wt         ← Go to previous workspace (super useful!)
  $0 -wn 5       ← Jump to workspace 5
  $0 -mw 3       ← Move current window to workspace 3
  $0 -wr/-wl     ← Navigate workspaces left/right

🖥️  MONITOR OPERATIONS:
  -ms            Shift monitors without focus
  -msf           Shift monitors with focus  
  -mt            Toggle monitor focus (up/down)
  -ml            Switch to left monitor
  -mr            Switch to right monitor

🏠 WORKSPACE OPERATIONS:
  -wt            Switch to previous workspace ⭐
  -wr            Switch to workspace on the right
  -wl            Switch to workspace on the left  
  -wn NUM        Jump to workspace NUM (1-10)
  -mw NUM        Move focused window to workspace NUM

🪟 WINDOW OPERATIONS:
  -vn            Cycle to next window
  -vp            Cycle to previous window
  -vl/-vr        Move focus left/right
  -vu/-vd        Move focus up/down

🌐 BROWSER OPERATIONS:
  -tn            Next browser tab
  -tp            Previous browser tab
  
🛠️  MAINTENANCE & DEBUG:
  -h             Show this help message
  -d             Debug mode (detailed output)
  -c             Clear workspace history files

📝 EXAMPLES:
  $0 -wn 5       # Jump to workspace 5
  $0 -mw 3       # Move current window to workspace 3  
  $0 -ms         # Shift monitors
  $0 -wt         # Go to previous workspace (most useful!)
  $0 -d -wn 2    # Jump to workspace 2 with debug output

💡 TIPS:
  • Use -wt frequently to toggle between two workspaces
  • Combine -d with any command for troubleshooting
  • Workspace numbers must be between 1-10
  • Browser tab navigation works with: Firefox, Chrome, Chromium, Brave

🔧 REQUIREMENTS:
  Required: hyprctl, jq
  Optional: pypr (for monitor operations), wtype/ydotool (for browser tabs)

Version: 1.4.0 | License: MIT
Report issues: Check logs in ~/.cache/hypr/toggle/debug.log
EOF
	exit 0
}

#######################################
# Debug/Maintenance Functions
#######################################

clear_workspace_history() {
	log_info "Clearing workspace history files"
	rm -f "$CURRENT_WS_FILE" "$PREVIOUS_WS_FILE"

	# Create them anew with validation
	local current_ws
	current_ws=$(get_current_workspace 2>/dev/null || echo "1")
	safe_write_file "$CURRENT_WS_FILE" "$current_ws"
	safe_write_file "$PREVIOUS_WS_FILE" "1"

	log_info "Workspace history files reset"
}

#######################################
# Main Script
#######################################

# Default values
direction="+1"
debug=false

# Show help if no arguments provided
if [ $# -eq 0 ]; then
	show_help
fi

# Validate dependencies first
validate_dependencies

# Initialize workspace files
init_workspace_files

# Parse command line arguments
while [[ $# -gt 0 ]]; do
	case $1 in
	-h)
		show_help
		;;
	-d)
		debug=true
		log_info "Debug mode enabled"
		shift
		;;
	-c)
		clear_workspace_history
		shift
		;;
	-ms)
		if command -v pypr &>/dev/null; then
			log_debug "Shifting monitors without focus"
			pypr shift_monitors "$direction"
		else
			log_error "pypr not found - cannot shift monitors"
			exit 1
		fi
		shift
		;;
	-msf)
		if command -v pypr &>/dev/null; then
			log_debug "Shifting monitors with focus"
			pypr shift_monitors "$direction"
			hyprctl dispatch focusmonitor "$direction"
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
	-wt)
		log_debug "Switching to previous workspace"
		prev_ws=$(get_previous_workspace)
		log_debug "Previous workspace is: $prev_ws"
		switch_to_workspace "$prev_ws"
		shift
		;;
	-wr)
		log_debug "Switching to workspace on right"
		# Save current workspace before switching
		current_ws=$(get_current_workspace)
		safe_write_file "$PREVIOUS_WS_FILE" "$current_ws"

		# Direct command for workspace right
		hyprctl dispatch workspace +1

		# Update current workspace after switching
		new_ws=$(get_current_workspace)
		safe_write_file "$CURRENT_WS_FILE" "$new_ws"

		log_debug "Switched from $current_ws to $new_ws"
		shift
		;;
	-wl)
		log_debug "Switching to workspace on left"
		# Save current workspace before switching
		current_ws=$(get_current_workspace)
		safe_write_file "$PREVIOUS_WS_FILE" "$current_ws"

		# Direct command for workspace left
		hyprctl dispatch workspace -1

		# Update current workspace after switching
		new_ws=$(get_current_workspace)
		safe_write_file "$CURRENT_WS_FILE" "$new_ws"

		log_debug "Switched from $current_ws to $new_ws"
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

		# Save current workspace before switching
		current_ws=$(get_current_workspace)
		safe_write_file "$PREVIOUS_WS_FILE" "$current_ws"

		# Direct command to avoid issues with workspace names
		hyprctl dispatch workspace "$2"

		# Update current after switching
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
