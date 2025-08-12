#!/usr/bin/env bash

# Hyprland Workspace App Mover Script
# Usage: ./move_app_from_workspace.sh <workspace_number>

if [ $# -eq 0 ]; then
	echo "Usage: $0 <workspace_number>"
	echo "Example: $0 9"
	exit 1
fi

SOURCE_WORKSPACE=$1

# Get current workspace
CURRENT_WORKSPACE=$(hyprctl activeworkspace -j | jq -r '.id')

# Check if source workspace exists and has apps
APP_ADDRESS=$(hyprctl clients -j | jq -r --arg ws "$SOURCE_WORKSPACE" '.[] | select(.workspace.id == ($ws | tonumber)) | .address' | head -1)

if [ -z "$APP_ADDRESS" ] || [ "$APP_ADDRESS" == "null" ]; then
	notify-send "Hyprland" "No application found in workspace $SOURCE_WORKSPACE" -t 2000
	exit 1
fi

# Check if we're trying to move from current workspace to current workspace
if [ "$SOURCE_WORKSPACE" -eq "$CURRENT_WORKSPACE" ]; then
	notify-send "Hyprland" "Already in workspace $SOURCE_WORKSPACE" -t 2000
	exit 0
fi

# Move the first app from source workspace to current workspace
hyprctl dispatch movetoworkspace $CURRENT_WORKSPACE,address:$APP_ADDRESS

# Optional: Get app info for notification
APP_INFO=$(hyprctl clients -j | jq -r --arg addr "$APP_ADDRESS" '.[] | select(.address == $addr) | .class + " (" + .title + ")"' 2>/dev/null || echo "Application")

# Send notification
notify-send "Hyprland" "Moved $APP_INFO from workspace $SOURCE_WORKSPACE to $CURRENT_WORKSPACE" -t 3000
