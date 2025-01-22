#!/usr/bin/env bash

#######################################
# HYPRLAND MONITOR & WORKSPACE CONTROL
#######################################
#
# Version: 1.1.0
# Date: 2025-01-22
# Author: Kenan Pelit
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
#
# Requirements:
#   - hyprctl: Hyprland control tool
#   - pypr: Hyprland Python tool
#   - jq: JSON processing tool
#   - ydotool: Wayland automation tool
#
# Installation:
#   The above tools must be installed on your system
#   to run this script.
#
# Note:
#   Script uses $HOME/.cache/hypr/toggle directory
#   Directory will be created automatically if it doesn't exist
#   Also, hyperland gestures must be turned off

#######################################
# Workspace Management Functions
#######################################

get_current_workspace() {
	hyprctl monitors -j | jq -r '.[] | select(.focused==true) | .activeWorkspace.name'
}

get_current_monitor() {
	hyprctl monitors -j | jq -r '.[] | select(.focused==true).name'
}

get_workspaces_for_monitor() {
	local monitor=$1
	hyprctl workspaces -j | jq -r ".[] | select(.monitor==\"$monitor\") | select(.name!=\"special\") | .name" | sort -n
}

switch_to_workspace() {
	local next_ws=$1
	hyprctl dispatch workspace "$next_ws"
}

switch_workspace_direction() {
	local direction=$1

	# Main variables
	local current_monitor=$(get_current_monitor)
	local current_ws=$(get_current_workspace)
	readarray -t workspace_list < <(get_workspaces_for_monitor "$current_monitor")

	# Find current workspace index
	local current_index=-1
	for i in "${!workspace_list[@]}"; do
		if [ "${workspace_list[$i]}" == "$current_ws" ]; then
			current_index=$i
			break
		fi
	done

	# Exit if current workspace not found
	if [ $current_index -eq -1 ]; then
		exit 1
	fi

	# Perform workspace transition
	case $direction in
	"Left")
		# If at leftmost, go to rightmost, else go left
		if [ $current_index -eq 0 ]; then
			switch_to_workspace "${workspace_list[-1]}"
		else
			switch_to_workspace "${workspace_list[$((current_index - 1))]}"
		fi
		;;
	"Right")
		# If at rightmost, go to leftmost, else go right
		if [ $current_index -eq $((${#workspace_list[@]} - 1)) ]; then
			switch_to_workspace "${workspace_list[0]}"
		else
			switch_to_workspace "${workspace_list[$((current_index + 1))]}"
		fi
		;;
	esac
}

#######################################
# Help Message Function
#######################################

show_help() {
	echo "╔══════════════════════════════════╗"
	echo "║   Monitor and Focus Control      ║"
	echo "╚══════════════════════════════════╝"
	echo
	echo "Usage: $0 [-h] [-ms] [-msf] [-mt] [-wt] [-wr] [-wl] [-vn] [-vp] [-vl] [-vr] [-tn] [-tp]"
	echo
	echo "Options:"
	echo "  -h          Show this help message"
	echo "  -ms         Shift monitors without focus"
	echo "  -msf        Shift monitors with focus"
	echo "  -mt         Monitors toggle focus"
	echo "  -wt         Workspace toggle previous"
	echo "  -wr         Workspace right"
	echo "  -wl         Workspace left"
	echo "  -vn         Cycle next window"
	echo "  -vp         Cycle previous window"
	echo "  -vl         Move focus left"
	echo "  -vr         Move focus right"
	echo "  -tn         Next browser tab"
	echo "  -tp         Previous browser tab"
	echo
	echo "Examples:"
	echo "  $0          # Show this help message"
	echo "  $0 -ms      # Only shift monitors"
	echo "  $0 -msf     # Shift monitors and follow with focus"
	echo "  $0 -mt      # Monitors toggle focus"
	echo "  $0 -wt      # Workspace toggle previous"
	echo "  $0 -wr      # Workspace right"
	echo "  $0 -wl      # Workspace left"
	echo "  $0 -vn      # Cycle next window"
	echo "  $0 -vp      # Cycle previous window"
	echo "  $0 -vl      # Move focus left"
	echo "  $0 -vr      # Move focus right"
	echo "  $0 -tn      # Next browser tab"
	echo "  $0 -tp      # Previous browser tab"
	exit 0
}

#######################################
# Main Script
#######################################

# Default values
direction="+1"
shift_only=false
shift_with_focus=false
monitor_toggle=false
workspace_toggle=false
workspace_right=false
workspace_left=false
cycle_next=false
cycle_prev=false
move_focus_left=false
move_focus_right=false
tab_next=false
tab_prev=false

# Show help if no arguments provided
if [ $# -eq 0 ]; then
	show_help
fi

# Parse command line arguments
for arg in "$@"; do
	case $arg in
	-h)
		show_help
		;;
	-ms)
		shift_only=true
		;;
	-msf)
		shift_with_focus=true
		;;
	-mt)
		monitor_toggle=true
		;;
	-wt)
		workspace_toggle=true
		;;
	-wr)
		workspace_right=true
		;;
	-wl)
		workspace_left=true
		;;
	-vn)
		cycle_next=true
		;;
	-vp)
		cycle_prev=true
		;;
	-vl)
		move_focus_left=true
		;;
	-vr)
		move_focus_right=true
		;;
	-tn)
		tab_next=true
		;;
	-tp)
		tab_prev=true
		;;
	*)
		echo "Invalid option: $arg"
		show_help
		;;
	esac
done

#######################################
# Command Execution
#######################################

# Monitor operations
if $shift_only; then
	pypr shift_monitors "$direction"
fi

if $shift_with_focus; then
	pypr shift_monitors "$direction"
	hyprctl dispatch focusmonitor "$direction"
fi

if $monitor_toggle; then
	CACHE_DIR="$HOME/.cache/hypr/toggle"
	STATE_FILE="$CACHE_DIR/focus_state"

	# Create cache directory if it doesn't exist
	if [ ! -d "$CACHE_DIR" ]; then
		mkdir -p "$CACHE_DIR"
	fi

	# Create state file with default value if it doesn't exist
	if [ ! -f "$STATE_FILE" ]; then
		echo "up" >"$STATE_FILE"
	fi

	# Read current state
	current_state=$(cat "$STATE_FILE")

	# Change focus and save new state based on current state
	if [ "$current_state" = "up" ]; then
		hyprctl dispatch movefocus d
		echo "down" >"$STATE_FILE"
	else
		hyprctl dispatch movefocus u
		echo "up" >"$STATE_FILE"
	fi
fi

# Workspace operations
if $workspace_toggle; then
	hyprctl dispatch workspace previous
fi

if $workspace_right; then
	switch_workspace_direction "Right"
fi

if $workspace_left; then
	switch_workspace_direction "Left"
fi

# Window focus operations
if $cycle_next; then
	hyprctl dispatch cyclenext
fi

if $cycle_prev; then
	hyprctl dispatch cyclenext prev
fi

if $move_focus_left; then
	hyprctl dispatch movefocus l
fi

if $move_focus_right; then
	hyprctl dispatch movefocus r
fi

# Browser tab operations (using wtype for Wayland)
if $tab_next; then
	# Using Page_Down instead of tab due to application conflicts
	# Alternative commands if needed:
	wtype -M ctrl -k tab
	# ydotool key ctrl+tab
	#wtype -M ctrl -k Page_Down
fi

if $tab_prev; then
	# Using Page_Up instead of tab due to application conflicts
	# Alternative commands if needed:
	wtype -M ctrl -M shift -k tab
	# ydotool key ctrl+shift+tab
	#wtype -M ctrl -k Page_Up
fi
