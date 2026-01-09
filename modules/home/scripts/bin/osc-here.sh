#!/usr/bin/env bash
# ==============================================================================
# osc-here.sh - Bring window here OR launch it if it's not running
# ==============================================================================
# Usage: osc-here.sh <app-id>
# Example: osc-here.sh Kenp
# ==============================================================================

set -euo pipefail

APP_ID="${1:-}"

if [[ -z "$APP_ID" ]]; then
    echo "Error: App ID is required."
    exit 1
fi

send_notify() {
    local msg="$1"
    local urgency="${2:-normal}"
    if command -v notify-send >/dev/null 2>&1; then
        notify-send -t 2000 -u "$urgency" -i "system-run" "Niri" "$msg"
    fi
}

# --- 1. Try to pull existing window (Nirius) ---
# Nirius move-to-current-workspace returns success only if it actually moves something.
# We use exact regex anchor to avoid matches like Kenp matching TmuxKenp.
if nirius move-to-current-workspace --app-id "^${APP_ID}$" --focus >/dev/null 2>&1; then
    send_notify "<b>$APP_ID</b> moved to current workspace."
    exit 0
fi

# --- 2. Check if it's already here but not focused ---
if command -v niri >/dev/null 2>&1 && command -v jq >/dev/null 2>&1; then
    window_id=$(niri msg -j windows | jq -r --arg app "$APP_ID" '.[] | select(.app_id == $app) | .id' | head -n1)
    if [[ -n "$window_id" ]]; then
        niri msg action focus-window --id "$window_id"
        send_notify "<b>$APP_ID</b> focused."
        exit 0
    fi
fi

# --- 3. Launching logic (Window not found) ---
send_notify "Launching <b>$APP_ID</b>..."

case "$APP_ID" in
    "Kenp")
        start-brave-kenp &
        ;;
    "TmuxKenp")
        start-kkenp &
        ;;
    "Ai")
        start-brave-ai &
        ;;
    "CompecTA")
        start-brave-compecta &
        ;;
    "WebCord")
        start-webcord &
        ;;
    "org.telegram.desktop")
        # Check if there's a start script, else use binary
        if command -v start-telegram >/dev/null 2>&1; then
            start-telegram &
        else
            telegram-desktop &
        fi
        ;;
    "brave-youtube.com__-Default")
        start-brave-youtube &
        ;;
    "spotify")
        start-spotify &
        ;;
    "ferdium")
        start-ferdium &
        ;;
    "discord")
        start-discord &
        ;;
    "kitty")
        kitty &
        ;;
    *)
        # Generic launch attempt
        if command -v "$APP_ID" >/dev/null 2>&1; then
            "$APP_ID" &
        else
            send_notify "Error: No start command found for <b>$APP_ID</b>" "critical"
            exit 1
        fi
        ;;
esac

exit 0
