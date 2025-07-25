#!/usr/bin/env bash
# Profile: brave-youtube
# Generated by Semsumo v7.0.0
set -e

echo "Initializing brave-youtube..."

# Switch to workspace
if [[ "7" != "0" ]] && command -v hyprctl >/dev/null 2>&1; then
    CURRENT_WORKSPACE=$(hyprctl activeworkspace -j | grep -o '"id": [0-9]*' | grep -o '[0-9]*' || echo "")
    
    if [[ "$CURRENT_WORKSPACE" != "7" ]]; then
        echo "Switching to workspace 7..."
        hyprctl dispatch workspace "7"
        sleep 1
    else
        echo "Already on workspace 7, skipping switch."
    fi
fi

echo "Starting application..."
echo "COMMAND: profile_brave --youtube --class youtube --title youtube"
echo "VPN MODE: secure"

# Start application with VPN mode
case "secure" in
    bypass)
        if command -v mullvad >/dev/null 2>&1 && mullvad status 2>/dev/null | grep -q "Connected"; then
            if command -v mullvad-exclude >/dev/null 2>&1; then
                echo "Starting with VPN bypass (mullvad-exclude)"
                mullvad-exclude profile_brave --youtube --class youtube --title youtube &
            else
                echo "WARNING: mullvad-exclude not found, starting normally"
                profile_brave --youtube --class youtube --title youtube &
            fi
        else
            echo "VPN not connected, starting normally"
            profile_brave --youtube --class youtube --title youtube &
        fi
        ;;
    secure|*)
        if command -v mullvad >/dev/null 2>&1 && mullvad status 2>/dev/null | grep -q "Connected"; then
            echo "Starting with VPN protection"
        else
            echo "WARNING: VPN not connected! Starting without protection"
        fi
        profile_brave --youtube --class youtube --title youtube &
        ;;
esac

# Save PID
APP_PID=$!
mkdir -p "/tmp/semsumo"
echo "$APP_PID" > "/tmp/semsumo/brave-youtube.pid"
echo "Application started (PID: $APP_PID)"

# Make fullscreen if needed
if [[ "true" == "true" ]]; then
    echo "Waiting 1 seconds for application to load..."
    sleep 1
    
    if command -v hyprctl >/dev/null 2>&1; then
        echo "Making fullscreen..."
        hyprctl dispatch fullscreen 1
    fi
fi

exit 0
