#!/usr/bin/env bash
# gnome-flow.sh - GNOME workspace/pencere yöneticisi
# wmctrl odaklı kısayol setiyle çalışma alanları, MPV/ekran kontrolleri
# ve hyprflow benzeri akışı GNOME’da sağlayan yardımcı.

#######################################
# GNOME WORKSPACE & WINDOW CONTROL
#######################################
#
# Version: 2.0.0
# Date: 2025-07-03
# Author: Adapted from HyprFlow for GNOME
# Description: GnomeFlow - GNOME Control Tool with wmctrl
#
# License: MIT
#
#######################################

# This script provides workspace and window control for the GNOME
# desktop environment using wmctrl. It manages operations such as:
# - Workspace navigation and management
# - Window focus and cycling
# - Window movement between workspaces
# - Browser tab navigation
#
# Requirements:
#   - wmctrl: Window manager control
#   - xdotool: Input automation
#   - wtype or ydotool: Wayland input (optional)

# Enable strict mode
set -euo pipefail

# Constants
readonly CACHE_DIR="$HOME/.cache/gnome/toggle"
readonly STATE_FILE="$CACHE_DIR/focus_state"
readonly CURRENT_WS_FILE="$CACHE_DIR/current_workspace"
readonly PREVIOUS_WS_FILE="$CACHE_DIR/previous_workspace"
readonly DEBUG_FILE="$CACHE_DIR/debug.log"

# Create cache directory if it doesn't exist
mkdir -p "$CACHE_DIR"

# Create state file with default value if it doesn't exist
if [ ! -f "$STATE_FILE" ]; then
	echo "1" >"$STATE_FILE"
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
	if [ "$ws" -lt 1 ] || [ "$ws" -gt 9 ]; then
		log_error "Workspace number out of range: $ws (valid range: 1-9)"
		return 1
	fi
	return 0
}

validate_dependencies() {
	local deps=("wmctrl")
	local missing_deps=()

	for dep in "${deps[@]}"; do
		if ! command -v "$dep" &>/dev/null; then
			missing_deps+=("$dep")
		fi
	done

	# Check optional dependencies
	if ! command -v "xdotool" &>/dev/null && ! command -v "wtype" &>/dev/null && ! command -v "ydotool" &>/dev/null; then
		log_debug "No input automation tool found - browser tab navigation may not work"
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
		if [[ "$content" =~ ^[0-9]+$ ]] && [ "$content" -ge 1 ] && [ "$content" -le 9 ]; then
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

# Initialize workspace tracking files
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
	# wmctrl workspace'ler 0-indexed, script 1-indexed kullanıyor
	local current_index
	current_index=$(wmctrl -d | grep '*' | awk '{print $1}' | head -1)

	if [[ "$current_index" =~ ^[0-9]+$ ]]; then
		echo $((current_index + 1))
	else
		echo "1"
	fi
}

get_previous_workspace() {
	safe_read_file "$PREVIOUS_WS_FILE" "1"
}

get_all_workspaces() {
	wmctrl -d | awk '{print $1+1}' | sort -n
}

switch_to_workspace() {
	local target_ws=$1

	if ! validate_workspace "$target_ws"; then
		log_error "Cannot switch to invalid workspace: $target_ws"
		return 1
	fi

	# Get current workspace before switching
	local current_ws
	current_ws=$(get_current_workspace)
	log_debug "Switching from workspace $current_ws to $target_ws"

	# Save current as previous before switching
	safe_write_file "$PREVIOUS_WS_FILE" "$current_ws"

	# Switch to target workspace (wmctrl uses 0-indexed)
	local target_index=$((target_ws - 1))
	wmctrl -s "$target_index"

	# Update current workspace after switching
	safe_write_file "$CURRENT_WS_FILE" "$target_ws"
	log_debug "Switch complete. Previous workspace set to $current_ws"
}

switch_workspace_direction() {
	local direction=$1
	local current_ws
	current_ws=$(get_current_workspace)

	log_debug "Switching workspace direction: $direction from current $current_ws"

	# Save current as previous before switching
	safe_write_file "$PREVIOUS_WS_FILE" "$current_ws"

	case $direction in
	"left")
		if [ "$current_ws" -gt 1 ]; then
			switch_to_workspace $((current_ws - 1))
		else
			log_debug "Already at first workspace"
		fi
		;;
	"right")
		if [ "$current_ws" -lt 9 ]; then
			switch_to_workspace $((current_ws + 1))
		else
			log_debug "Already at last workspace"
		fi
		;;
	esac
}

#######################################
# Window Management Functions
#######################################

get_focused_window() {
	# Get active window ID
	local active_window
	active_window=$(wmctrl -l | grep "$(wmctrl -d | grep '*' | awk '{print $1}')" | head -1 | awk '{print $1}')

	# Alternative: use xdotool if available
	if command -v xdotool &>/dev/null; then
		xdotool getactivewindow 2>/dev/null || echo "$active_window"
	else
		echo "$active_window"
	fi
}

move_window_to_workspace() {
	local target_ws=$1

	if ! validate_workspace "$target_ws"; then
		log_error "Cannot move window to invalid workspace: $target_ws"
		return 1
	fi

	local focused_window
	focused_window=$(get_focused_window)

	if [ -n "$focused_window" ] && [ "$focused_window" != "0x00000000" ]; then
		log_debug "Moving window $focused_window to workspace $target_ws"

		# Move window to workspace (wmctrl uses 0-indexed)
		wmctrl -i -r "$focused_window" -t $((target_ws - 1))

		# Switch to that workspace
		switch_to_workspace "$target_ws"
	else
		log_error "No focused window to move"
		return 1
	fi
}

#######################################
# Window Focus Functions
#######################################

cycle_windows() {
	local direction=$1

	case $direction in
	"next")
		# Get all windows on current workspace
		local current_ws_index=$(($(get_current_workspace) - 1))
		local windows
		windows=$(wmctrl -l | awk -v ws="$current_ws_index" '$2 == ws {print $1}')

		if [ -n "$windows" ]; then
			local active_window
			active_window=$(get_focused_window)
			local next_window
			next_window=$(echo "$windows" | grep -A 1 "$active_window" | tail -1)

			if [ -z "$next_window" ] || [ "$next_window" = "$active_window" ]; then
				next_window=$(echo "$windows" | head -1)
			fi

			if [ -n "$next_window" ]; then
				wmctrl -i -a "$next_window"
			fi
		fi
		;;
	"prev")
		# Similar logic but in reverse
		local current_ws_index=$(($(get_current_workspace) - 1))
		local windows
		windows=$(wmctrl -l | awk -v ws="$current_ws_index" '$2 == ws {print $1}' | tac)

		if [ -n "$windows" ]; then
			local active_window
			active_window=$(get_focused_window)
			local prev_window
			prev_window=$(echo "$windows" | grep -A 1 "$active_window" | tail -1)

			if [ -z "$prev_window" ] || [ "$prev_window" = "$active_window" ]; then
				prev_window=$(echo "$windows" | head -1)
			fi

			if [ -n "$prev_window" ]; then
				wmctrl -i -a "$prev_window"
			fi
		fi
		;;
	esac
}

#######################################
# Browser Tab Management Functions
#######################################

navigate_browser_tab() {
	local direction=$1

	log_debug "Navigating browser tab $direction"

	case $direction in
	"next")
		if command -v xdotool &>/dev/null; then
			xdotool key "ctrl+Tab"
		elif command -v wtype &>/dev/null; then
			wtype -M ctrl -k Tab
		elif command -v ydotool &>/dev/null; then
			ydotool key ctrl+Tab
		else
			log_error "No input automation tool found"
		fi
		;;
	"prev")
		if command -v xdotool &>/dev/null; then
			xdotool key "ctrl+shift+Tab"
		elif command -v wtype &>/dev/null; then
			wtype -M ctrl -M shift -k Tab
		elif command -v ydotool &>/dev/null; then
			ydotool key ctrl+shift+Tab
		else
			log_error "No input automation tool found"
		fi
		;;
	esac
}

#######################################
# Help Message Function
#######################################

show_help() {
	cat <<EOF
╭─────────────────────────────────────────────────────────────╮
│                🚀 GnomeFlow - GNOME Control                 │
│                     Version 2.0.0                          │
╰─────────────────────────────────────────────────────────────╯

📋 QUICK REFERENCE (Most Used Commands):
  $0 -wt         ← Go to previous workspace (super useful!)
  $0 -wn 5       ← Jump to workspace 5
  $0 -mw 3       ← Move current window to workspace 3
  $0 -wr/-wl     ← Navigate workspaces left/right

🏠 WORKSPACE OPERATIONS:
  -wt            Switch to previous workspace ⭐
  -wr            Switch to workspace on the right
  -wl            Switch to workspace on the left  
  -wn NUM        Jump to workspace NUM (1-9)
  -mw NUM        Move focused window to workspace NUM

🪟 WINDOW OPERATIONS:
  -vn            Cycle to next window
  -vp            Cycle to previous window
  -vl/-vr        Move focus left/right (cycle approximation)
  -vu/-vd        Move focus up/down (cycle approximation)

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
  $0 -wt         # Go to previous workspace (most useful!)
  $0 -d -wn 2    # Jump to workspace 2 with debug output

💡 TIPS:
  • Use -wt frequently to toggle between two workspaces
  • Combine -d with any command for troubleshooting
  • Workspace numbers must be between 1-9 (GNOME standard)
  • Window cycling works with wmctrl window management

🔧 REQUIREMENTS:
  Required: wmctrl
  Optional: xdotool/wtype/ydotool (for input automation)

Version: 2.0.0 | License: MIT
Report issues: Check logs in ~/.cache/gnome/toggle/debug.log
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
			log_info "Usage: $0 -wn <workspace_number> (1-9)"
			exit 1
		fi

		if ! validate_workspace "$2"; then
			exit 1
		fi

		log_debug "Jumping to workspace $2"
		switch_to_workspace "$2"
		shift 2
		;;
	-mw)
		if [[ -z "${2:-}" ]]; then
			log_error "Workspace number is required for -mw"
			log_info "Usage: $0 -mw <workspace_number> (1-9)"
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
		cycle_windows "next"
		shift
		;;
	-vp)
		log_debug "Cycling to previous window"
		cycle_windows "prev"
		shift
		;;
	-vl)
		log_debug "Moving focus left"
		cycle_windows "prev"
		shift
		;;
	-vr)
		log_debug "Moving focus right"
		cycle_windows "next"
		shift
		;;
	-vu)
		log_debug "Moving focus up"
		cycle_windows "prev"
		shift
		;;
	-vd)
		log_debug "Moving focus down"
		cycle_windows "next"
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
