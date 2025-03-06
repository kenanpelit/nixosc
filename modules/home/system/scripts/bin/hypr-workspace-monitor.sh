#!/usr/bin/env bash

#######################################
# HYPRLAND MONITOR & WORKSPACE CONTROL
#######################################
#
# Version: 1.2.0
# Date: 2025-03-06
# Original Author: Kenan Pelit
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
readonly HISTORY_FILE="$CACHE_DIR/workspace_history"
readonly MAX_HISTORY=10

# Create cache directory if it doesn't exist
mkdir -p "$CACHE_DIR"

# Create state file with default value if it doesn't exist
if [ ! -f "$STATE_FILE" ]; then
	echo "up" >"$STATE_FILE"
fi

# Create workspace history file if it doesn't exist
if [ ! -f "$HISTORY_FILE" ]; then
	touch "$HISTORY_FILE"
fi

#######################################
# Logging Functions
#######################################

log_info() {
	echo "[INFO] $1" >&2
}

log_error() {
	echo "[ERROR] $1" >&2
}

#######################################
# Workspace Management Functions
#######################################

get_current_workspace() {
	hyprctl monitors -j | jq -r '.[] | select(.focused==true) | .activeWorkspace.name'
}

get_previous_workspace() {
	if [ -s "$HISTORY_FILE" ]; then
		head -n 1 "$HISTORY_FILE"
	else
		echo "1" # Default to workspace 1 if no history
	fi
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

# Track workspace history
update_workspace_history() {
	local current_ws=$(get_current_workspace)
	local temp_file=$(mktemp)

	# Insert current workspace at top if it's not already there
	echo "$current_ws" >"$temp_file"

	# Add previous workspaces, except current
	grep -v "^$current_ws$" "$HISTORY_FILE" | head -n $(($MAX_HISTORY - 1)) >>"$temp_file"

	# Replace history file with updated version
	mv "$temp_file" "$HISTORY_FILE"
}

switch_to_workspace() {
	local next_ws=$1

	# Save current workspace to history before switching
	update_workspace_history

	# Switch to target workspace
	hyprctl dispatch workspace name:$next_ws
}

switch_workspace_direction() {
	local direction=$1

	# Use simple dispatch commands for left/right navigation
	# This is more robust than trying to calculate the next workspace
	case $direction in
	"Left")
		if $debug; then log_info "Directly dispatching workspace to previous"; fi
		hyprctl dispatch workspace m-1
		;;
	"Right")
		if $debug; then log_info "Directly dispatching workspace to next"; fi
		hyprctl dispatch workspace m+1
		;;
	esac

	# Update history after switching
	update_workspace_history
}

#######################################
# Window Management Functions
#######################################

get_focused_window() {
	hyprctl activewindow -j | jq -r '.address'
}

move_window_to_workspace() {
	local target_ws=$1
	local focused_window=$(get_focused_window)

	if [ "$focused_window" != "null" ]; then
		hyprctl dispatch movetoworkspace "$target_ws"
		hyprctl dispatch workspace "$target_ws"
	else
		log_error "No focused window to move"
	fi
}

#######################################
# Monitor Management Functions
#######################################

toggle_monitor_focus() {
	# Read current state
	local current_state=$(cat "$STATE_FILE")

	# Change focus and save new state based on current state
	if [ "$current_state" = "up" ]; then
		hyprctl dispatch movefocus d
		echo "down" >"$STATE_FILE"
	else
		hyprctl dispatch movefocus u
		echo "up" >"$STATE_FILE"
	fi
}

#######################################
# Browser Tab Management Functions
#######################################

navigate_browser_tab() {
	local direction=$1

	if [ "$direction" = "next" ]; then
		# Try both methods for compatibility
		wtype -M ctrl -k tab 2>/dev/null || ydotool key ctrl+tab 2>/dev/null
	else
		# Try both methods for compatibility
		wtype -M ctrl -M shift -k tab 2>/dev/null || ydotool key ctrl+shift+tab 2>/dev/null
	fi
}

#######################################
# Help Message Function
#######################################

show_help() {
	cat <<EOF
╔══════════════════════════════════╗
║   HyprFlow - Hyprland Control    ║
╚══════════════════════════════════╝

Usage: $0 [-h] [OPTION]

Monitor Operations:
  -ms         Shift monitors without focus
  -msf        Shift monitors with focus
  -mt         Toggle monitor focus (up/down)
  -ml         Switch to left monitor
  -mr         Switch to right monitor

Workspace Operations:
  -wt         Switch to previous workspace
  -wr         Switch to workspace on the right
  -wl         Switch to workspace on the left
  -wn NUM     Jump to workspace NUM
  -mw NUM     Move focused window to workspace NUM

Window Operations:
  -vn         Cycle to next window
  -vp         Cycle to previous window
  -vl         Move focus left
  -vr         Move focus right
  -vu         Move focus up
  -vd         Move focus down

Browser Operations:
  -tn         Next browser tab
  -tp         Previous browser tab

Other:
  -h          Show this help message
  -d          Debug mode (detailed output)

Examples:
  $0 -wn 5    # Jump to workspace 5
  $0 -mw 3    # Move current window to workspace 3
  $0 -ms      # Shift monitors
  $0 -wt      # Go to previous workspace

Version: 1.2.0
EOF
	exit 0
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

# Parse command line arguments
while [[ $# -gt 0 ]]; do
	case $1 in
	-h)
		show_help
		;;
	-d)
		debug=true
		shift
		;;
	-ms)
		if $debug; then log_info "Shifting monitors without focus"; fi
		pypr shift_monitors "$direction"
		shift
		;;
	-msf)
		if $debug; then log_info "Shifting monitors with focus"; fi
		pypr shift_monitors "$direction"
		hyprctl dispatch focusmonitor "$direction"
		shift
		;;
	-mt)
		if $debug; then log_info "Toggling monitor focus"; fi
		toggle_monitor_focus
		shift
		;;
	-ml)
		if $debug; then log_info "Focusing left monitor"; fi
		hyprctl dispatch focusmonitor l
		shift
		;;
	-mr)
		if $debug; then log_info "Focusing right monitor"; fi
		hyprctl dispatch focusmonitor r
		shift
		;;
	-wt)
		if $debug; then log_info "Switching to previous workspace"; fi
		prev_ws=$(get_previous_workspace)
		switch_to_workspace "$prev_ws"
		shift
		;;
	-wr)
		if $debug; then log_info "Switching to workspace on right"; fi
		# Direct command for workspace right
		hyprctl dispatch workspace +1
		update_workspace_history
		shift
		;;
	-wl)
		if $debug; then log_info "Switching to workspace on left"; fi
		# Direct command for workspace left
		hyprctl dispatch workspace -1
		update_workspace_history
		shift
		;;
	-wn)
		if [[ -z "${2:-}" ]]; then
			log_error "Workspace number is required for -wn"
			exit 1
		fi
		if $debug; then log_info "Jumping to workspace $2"; fi
		# Direct command to avoid issues with workspace names
		hyprctl dispatch workspace "$2"
		update_workspace_history
		shift 2
		;;
	-mw)
		if [[ -z "${2:-}" ]]; then
			log_error "Workspace number is required for -mw"
			exit 1
		fi
		if $debug; then log_info "Moving window to workspace $2"; fi
		move_window_to_workspace "$2"
		shift 2
		;;
	-vn)
		if $debug; then log_info "Cycling to next window"; fi
		hyprctl dispatch cyclenext
		shift
		;;
	-vp)
		if $debug; then log_info "Cycling to previous window"; fi
		hyprctl dispatch cyclenext prev
		shift
		;;
	-vl)
		if $debug; then log_info "Moving focus left"; fi
		hyprctl dispatch movefocus l
		shift
		;;
	-vr)
		if $debug; then log_info "Moving focus right"; fi
		hyprctl dispatch movefocus r
		shift
		;;
	-vu)
		if $debug; then log_info "Moving focus up"; fi
		hyprctl dispatch movefocus u
		shift
		;;
	-vd)
		if $debug; then log_info "Moving focus down"; fi
		hyprctl dispatch movefocus d
		shift
		;;
	-tn)
		if $debug; then log_info "Navigating to next browser tab"; fi
		navigate_browser_tab "next"
		shift
		;;
	-tp)
		if $debug; then log_info "Navigating to previous browser tab"; fi
		navigate_browser_tab "prev"
		shift
		;;
	*)
		log_error "Invalid option: $1"
		show_help
		;;
	esac
done
