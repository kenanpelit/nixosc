#!/usr/bin/env bash
# ==============================================================================
# osc-here.sh - Bring window here OR launch it if it's not running
# ==============================================================================
# Usage: 
#   osc-here.sh <app-id>
#   osc-here.sh all [app1,app2,...]
#
# Notifications:
#   - Success: Disabled by default (enable with OSC_HERE_NOTIFY=1)
#   - Error: Always enabled
# ==============================================================================

set -euo pipefail

# Notification setting: 0 (off), 1 (on)
NOTIFY_ENABLED="${OSC_HERE_NOTIFY:-0}"

# Default list for 'all' command
DEFAULT_APPS=(
    "Kenp"
    "TmuxKenp"
    "Ai"
    "CompecTA"
    "WebCord"
    "org.telegram.desktop"
    "brave-youtube.com__-Default"
    "spotify"
    "ferdium"
)

send_notify() {
    local msg="$1"
    local urgency="${2:-normal}"
    
    # Only show normal notifications if enabled
    if [[ "$urgency" == "normal" && "$NOTIFY_ENABLED" != "1" ]]; then
        return 0
    fi

    if command -v notify-send >/dev/null 2>&1; then
        notify-send -t 2000 -u "$urgency" -i "system-run" "Niri" "$msg"
    fi
}

# Helper function to process a single app
process_app() {
    local APP_ID="$1"
    
    # --- 1. Try to pull existing window (Nirius) ---
    if nirius move-to-current-workspace --app-id "^${APP_ID}$" --focus >/dev/null 2>&1; then
        send_notify "<b>$APP_ID</b> moved to current workspace."
        return 0
    fi

    # --- 2. Check if it's already here but not focused ---
    if command -v niri >/dev/null 2>&1 && command -v jq >/dev/null 2>&1; then
        window_id=$(niri msg -j windows | jq -r --arg app "$APP_ID" '.[] | select(.app_id == $app) | .id' | head -n1)
        if [[ -n "$window_id" ]]; then
            niri msg action focus-window --id "$window_id"
            send_notify "<b>$APP_ID</b> focused."
            return 0
        fi
    fi

    # --- 3. Launching logic (Window not found) ---
    send_notify "Launching <b>$APP_ID</b>..."

    case "$APP_ID" in
        "Kenp") start-brave-kenp & ;;
        "TmuxKenp") start-kkenp & ;;
        "Ai") start-brave-ai & ;;
        "CompecTA") start-brave-compecta & ;;
        "WebCord") start-webcord & ;;
        #"org.telegram.desktop") Telegram & ;;
        "brave-youtube.com__-Default") start-brave-youtube & ;;
        "spotify") start-spotify & ;;
        "ferdium") start-ferdium & ;;
        "discord") start-discord & ;;
        "kitty") kitty & ;;
        *)
            if command -v "$APP_ID" >/dev/null 2>&1; then
                "$APP_ID" &
            else
                send_notify "Error: No start command found for <b>$APP_ID</b>" "critical"
            fi
            ;;
    esac
}

APP_ID="${1:-}"
LIST="${2:-}"

if [[ -z "$APP_ID" ]]; then
    echo "Error: App ID is required."
    exit 1
fi

if [[ "$APP_ID" == "all" ]]; then
    # Process list
    if [[ -n "$LIST" ]]; then
        IFS=',' read -ra APPS <<< "$LIST"
    else
        APPS=("${DEFAULT_APPS[@]}")
    fi
    
    for app in "${APPS[@]}"; do
        process_app "$app"
        # Small delay to let Niri process moves smoothly
        sleep 0.1
    done
    
    send_notify "All specified apps gathered here."
else
    # Process single app
    process_app "$APP_ID"
fi

exit 0