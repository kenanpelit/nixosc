#!/usr/bin/env bash
# Profile: Zen-Proxy
set -euo pipefail
IFS=$'\n\t'

# Configuration
PROFILE="Zen-Proxy"
COMMAND="zen"
WORKSPACE="7"
WAIT_TIME="1"
FULLSCREEN="false"
FINAL_WORKSPACE="0"
VPN_MODE="bypass"
LOG_FILE="/tmp/start-$PROFILE.log"

# Logging setup
exec > >(tee -a "$LOG_FILE") 2>&1
echo "[2025-04-18 15:16:11] Starting $PROFILE..."

# Functions
vpn_status() {
    if command -v mullvad >/dev/null 2>&1; then
        if mullvad status 2>/dev/null | grep -q "Connected"; then
            echo "connected"
        else
            echo "disconnected"
        fi
    else
        echo "not_installed"
    fi
}

switch_workspace() {
    local target_workspace="$1"
    local wait_duration="$2"
    
    if [[ "$target_workspace" != "0" && "$target_workspace" != "" ]] && command -v hyprctl >/dev/null 2>&1; then
        echo "Workspace $target_workspace'e geçiliyor..."
        hyprctl dispatch workspace "$target_workspace"
        echo "Geçiş için $wait_duration saniye bekleniyor..."
        sleep "$wait_duration"
    fi
}

# Main execution
echo "Initializing $PROFILE..."

# Switch to initial workspace
switch_workspace "$WORKSPACE" "$WAIT_TIME"

# Start application with appropriate VPN mode
echo "Uygulama başlatılıyor..."
echo "COMMAND: $COMMAND "-P" "Proxy" "--class" "Proxy" "--name" "Proxy" "--restore-session""
echo "VPN MODE: $VPN_MODE"

# Create function to run the command with proper arguments
run_command() {
    zen "-P" "Proxy" "--class" "Proxy" "--name" "Proxy" "--restore-session" "$@"
}

case "$VPN_MODE" in
    bypass)
        VPN_STATUS=$(vpn_status)
        if [[ "$VPN_STATUS" == "connected" ]]; then
            if command -v mullvad-exclude >/dev/null 2>&1; then
                echo "VPN bypass ile başlatılıyor (mullvad-exclude)"
                # Use direct command with quoted arguments
                mullvad-exclude zen "-P" "Proxy" "--class" "Proxy" "--name" "Proxy" "--restore-session" &
            else
                echo "UYARI: mullvad-exclude bulunamadı, normal başlatılıyor"
                # Use direct command with quoted arguments
                zen "-P" "Proxy" "--class" "Proxy" "--name" "Proxy" "--restore-session" &
            fi
        else
            echo "VPN bağlı değil, normal başlatılıyor"
            # Use direct command with quoted arguments
            zen "-P" "Proxy" "--class" "Proxy" "--name" "Proxy" "--restore-session" &
        fi
        ;;
    secure|*)
        VPN_STATUS=$(vpn_status)
        if [[ "$VPN_STATUS" != "connected" ]]; then
            echo "UYARI: VPN bağlı değil! Korumasız başlatılıyor"
        else
            echo "VPN koruması ile başlatılıyor"
        fi
        # Use direct command with quoted arguments
        zen "-P" "Proxy" "--class" "Proxy" "--name" "Proxy" "--restore-session" &
        ;;
esac

# Save PID and wait a moment
APP_PID=$!
mkdir -p "/tmp/sem"
echo "$APP_PID" > "/tmp/sem/$PROFILE.pid"
echo "Uygulama başlatıldı (PID: $APP_PID)"

# Make fullscreen if needed
if [[ "$FULLSCREEN" == "true" ]]; then
    echo "Uygulama yüklenmesi için $WAIT_TIME saniye bekleniyor..."
    sleep "$WAIT_TIME"
    
    if command -v hyprctl >/dev/null 2>&1; then
        echo "Tam ekran yapılıyor..."
        hyprctl dispatch fullscreen 1
        sleep 1
    fi
fi

# Switch to final workspace if needed
if [[ "$FINAL_WORKSPACE" != "0" && "$FINAL_WORKSPACE" != "$WORKSPACE" ]]; then
    echo "Son workspace'e geçiliyor..."
    switch_workspace "$FINAL_WORKSPACE" 1
fi

exit 0
