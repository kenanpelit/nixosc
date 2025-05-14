#!/usr/bin/env bash

#######################################
# HYPRLAND MONITOR & WORKSPACE CONTROL
#######################################
#
# Version: 1.3.0
# Date: 2025-05-14
# Original Author: Kenan Pelit
# Updated By: Claude
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

# Create workspace tracking files if they don't exist
if [ ! -f "$CURRENT_WS_FILE" ]; then
	get_current_workspace >"$CURRENT_WS_FILE" 2>/dev/null || echo "1" >"$CURRENT_WS_FILE"
fi

if [ ! -f "$PREVIOUS_WS_FILE" ]; then
	echo "1" >"$PREVIOUS_WS_FILE"
fi

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
	if [ -s "$PREVIOUS_WS_FILE" ]; then
		cat "$PREVIOUS_WS_FILE"
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

# Update workspace history - simplified version
update_workspace_history() {
	local new_ws
	new_ws=$(get_current_workspace)
	log_debug "Updating workspace history. New workspace: $new_ws"

	# Read current workspace
	local old_ws
	if [ -s "$CURRENT_WS_FILE" ]; then
		old_ws=$(cat "$CURRENT_WS_FILE")
		log_debug "Current workspace from file: $old_ws"

		# If workspace changed, update previous
		if [ "$new_ws" != "$old_ws" ]; then
			echo "$old_ws" >"$PREVIOUS_WS_FILE"
			log_debug "Updated previous workspace to: $old_ws"
		fi
	else
		log_debug "No current workspace file found or it's empty"
	fi

	# Always update current workspace
	echo "$new_ws" >"$CURRENT_WS_FILE"
	log_debug "Updated current workspace to: $new_ws"

	# Verify files were updated
	log_debug "Current workspace file now contains: $(cat "$CURRENT_WS_FILE" 2>/dev/null || echo 'ERROR READING FILE')"
	log_debug "Previous workspace file now contains: $(cat "$PREVIOUS_WS_FILE" 2>/dev/null || echo 'ERROR READING FILE')"
}

switch_to_workspace() {
	local next_ws=$1

	# Get current workspace before switching
	local current_ws
	current_ws=$(get_current_workspace)
	log_debug "Switching from workspace $current_ws to $next_ws"

	# Save current as previous before switching
	echo "$current_ws" >"$PREVIOUS_WS_FILE"

	# Switch to target workspace
	hyprctl dispatch workspace name:$next_ws

	# Update current workspace after switching
	echo "$next_ws" >"$CURRENT_WS_FILE"

	log_debug "Switch complete. Previous workspace set to $current_ws"
}

switch_workspace_direction() {
	local direction=$1
	local current_ws
	current_ws=$(get_current_workspace)

	log_debug "Switching workspace direction: $direction from current $current_ws"

	# Save current as previous before switching
	echo "$current_ws" >"$PREVIOUS_WS_FILE"

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
	echo "$new_ws" >"$CURRENT_WS_FILE"

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
	local focused_window
	focused_window=$(get_focused_window)

	if [ "$focused_window" != "null" ]; then
		log_debug "Moving window $focused_window to workspace $target_ws"
		hyprctl dispatch movetoworkspace "$target_ws"
		hyprctl dispatch workspace "$target_ws"

		# Update workspace tracking
		echo "$target_ws" >"$CURRENT_WS_FILE"
	else
		log_error "No focused window to move"
	fi
}

#######################################
# Monitor Management Functions
#######################################

toggle_monitor_focus() {
	# Read current state
	local current_state
	current_state=$(cat "$STATE_FILE")

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

	if [[ "$current_window" == "brave" || "$current_window" == "Brave" ]]; then
		if [ "$direction" = "next" ]; then
			hyprctl dispatch exec "wtype -P ctrl -p tab -r tab -R ctrl"
		else
			hyprctl dispatch exec "wtype -P ctrl -P shift -p tab -r tab -R shift -R ctrl"
		fi
	else
		# Diğer tarayıcılar için
		if [ "$direction" = "next" ]; then
			wtype -M ctrl -k tab 2>/dev/null || ydotool key ctrl+tab 2>/dev/null
		else
			wtype -M ctrl -M shift -k tab 2>/dev/null || ydotool key ctrl+shift+tab 2>/dev/null
		fi
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
  -c          Clear workspace history files

Examples:
  $0 -wn 5    # Jump to workspace 5
  $0 -mw 3    # Move current window to workspace 3
  $0 -ms      # Shift monitors
  $0 -wt      # Go to previous workspace

Version: 1.3.0
EOF
	exit 0
}

#######################################
# Debug/Maintenance Functions
#######################################

clear_workspace_history() {
	log_info "Clearing workspace history files"
	rm -f "$CURRENT_WS_FILE" "$PREVIOUS_WS_FILE"

	# Create them anew
	get_current_workspace >"$CURRENT_WS_FILE" 2>/dev/null || echo "1" >"$CURRENT_WS_FILE"
	echo "1" >"$PREVIOUS_WS_FILE"

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
		log_debug "Shifting monitors without focus"
		pypr shift_monitors "$direction"
		shift
		;;
	-msf)
		log_debug "Shifting monitors with focus"
		pypr shift_monitors "$direction"
		hyprctl dispatch focusmonitor "$direction"
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
		echo "$current_ws" >"$PREVIOUS_WS_FILE"

		# Direct command for workspace right
		hyprctl dispatch workspace +1

		# Update current workspace after switching
		new_ws=$(get_current_workspace)
		echo "$new_ws" >"$CURRENT_WS_FILE"

		log_debug "Switched from $current_ws to $new_ws"
		shift
		;;
	-wl)
		log_debug "Switching to workspace on left"
		# Save current workspace before switching
		current_ws=$(get_current_workspace)
		echo "$current_ws" >"$PREVIOUS_WS_FILE"

		# Direct command for workspace left
		hyprctl dispatch workspace -1

		# Update current workspace after switching
		new_ws=$(get_current_workspace)
		echo "$new_ws" >"$CURRENT_WS_FILE"

		log_debug "Switched from $current_ws to $new_ws"
		shift
		;;
	-wn)
		if [[ -z "${2:-}" ]]; then
			log_error "Workspace number is required for -wn"
			exit 1
		fi
		log_debug "Jumping to workspace $2"

		# Save current workspace before switching
		current_ws=$(get_current_workspace)
		echo "$current_ws" >"$PREVIOUS_WS_FILE"

		# Direct command to avoid issues with workspace names
		hyprctl dispatch workspace "$2"

		# Update current after switching
		echo "$2" >"$CURRENT_WS_FILE"

		log_debug "Switched from workspace $current_ws to $2"
		shift 2
		;;
	-mw)
		if [[ -z "${2:-}" ]]; then
			log_error "Workspace number is required for -mw"
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
		show_help
		;;
	esac
done
