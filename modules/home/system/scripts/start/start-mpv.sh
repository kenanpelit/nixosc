#!/usr/bin/env bash
# Profile: mpv

set -euo pipefail
IFS=$'\n\t'

# Configuration
PROFILE="mpv"
COMMAND="mpv"
ARGS=""
VPN_MODE="bypass"
WORKSPACE="6"
WAIT_TIME="1"
FULLSCREEN="true"
FINAL_WORKSPACE="0"
LOG_FILE="/tmp/start-$PROFILE.log"

# Logging
exec > >(tee -a "$LOG_FILE") 2>&1
echo -e "\n[2025-04-18 14:42:49] Starting $PROFILE..."

# Functions
vpn_status() {
    if command -v mullvad >/dev/null 2>&1; then
        mullvad status 2>/dev/null | grep -q "Connected" && echo "connected" || echo "disconnected"
    else
        echo "not_installed"
    fi
}

switch_workspace() {
    if [[ "$1" != "0" ]] && command -v hyprctl >/dev/null 2>&1; then
        echo "Switching to workspace $1"
        hyprctl dispatch workspace "$1"
        sleep "$2"
    fi
}

start_application() {
    case "$VPN_MODE" in
        bypass)
            if [[ $(vpn_status) == "connected" ]] && command -v mullvad-exclude >/dev/null 2>&1; then
                echo "Starting with VPN bypass"
                mullvad-exclude "$COMMAND" $ARGS &
            else
                echo "Starting normally (VPN bypass not available)"
                "$COMMAND" $ARGS &
            fi
            ;;
        secure)
            if [[ $(vpn_status) != "connected" ]]; then
                echo "WARNING: VPN not connected! Starting without protection"
            fi
            "$COMMAND" $ARGS &
            ;;
    esac
}

# Main execution
echo "Initializing $PROFILE..."
switch_workspace "$WORKSPACE" "$WAIT_TIME"

echo "Starting application..."
start_application
APP_PID=$!

# Save PID
echo "$APP_PID" > "/tmp/sem/$PROFILE.pid"
echo "Application started with PID: $APP_PID"

# Fullscreen if needed
if [[ "$FULLSCREEN" == "true" ]] && command -v hyprctl >/dev/null 2>&1; then
    sleep "$WAIT_TIME"
    echo "Enabling fullscreen"
    hyprctl dispatch fullscreen 1
fi

# Return to final workspace if specified
if [[ "$FINAL_WORKSPACE" != "0" ]] && command -v hyprctl >/dev/null 2>&1; then
    sleep 1
    switch_workspace "$FINAL_WORKSPACE" "$WAIT_TIME"
fi

exit 0
