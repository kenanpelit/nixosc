#!/usr/bin/env bash
# ==============================================================================
# osc-here.sh - Move window to current workspace and focus it
# ==============================================================================
# Usage: osc-here.sh <app-id>
# Example: osc-here.sh ferdium
# ==============================================================================

set -euo pipefail

APP_ID="${1:-}"

if [[ -z "$APP_ID" ]]; then
    echo "Error: You must provide an App ID."
    exit 1
fi

send_notify() {
    local msg="$1"
    local urgency="${2:-normal}"
    if command -v notify-send >/dev/null 2>&1; then
        notify-send -t 2000 -u "$urgency" -i "system-run" "Niri" "$msg"
    fi
}

# 1. Attempt to move the window (Nirius)
# Use exact match regex anchor if possible, or assume Nirius handles regex.
# Nirius uses regex by default, so we anchor it to be exact: "^APP_ID$"
if nirius move-to-current-workspace --app-id "^${APP_ID}$" --focus >/dev/null 2>&1; then
    send_notify "<b>$APP_ID</b> moved here."
    exit 0
fi

# 2. Move failed (likely already on this workspace). Attempt to focus by ID.
if command -v niri >/dev/null 2>&1 && command -v jq >/dev/null 2>&1; then
    # Find the window ID matching the App ID EXACTLY (case-insensitive)
    # We check if app_id equals the input, ignoring case.
    window_id=$(niri msg -j windows | jq -r --arg app "$APP_ID" '.[] | select(.app_id | ascii_downcase == ($app | ascii_downcase)) | .id' | head -n1)
    
    if [[ -n "$window_id" ]]; then
        # Focus by ID
        if niri msg action focus-window --id "$window_id" >/dev/null 2>&1; then
            echo "Info: '$APP_ID' already here, focusing."
            send_notify "<b>$APP_ID</b> focused."
            exit 0
        fi
    fi
fi

# 3. Window not found or couldn't be focused.
echo "Error: '$APP_ID' not found."
send_notify "'$APP_ID' window not found." "critical"
exit 1
