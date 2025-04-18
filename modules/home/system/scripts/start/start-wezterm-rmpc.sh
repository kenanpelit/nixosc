#!/usr/bin/env bash
# Profile: wezterm-rmpc
set -euo pipefail

echo "[2025-04-18 15:53:00] Starting wezterm-rmpc..."
echo "Initializing wezterm-rmpc..."

# Switch to initial workspace
if [[ "0" != "0" ]] && command -v hyprctl >/dev/null 2>&1; then
    echo "Workspace 0'e geçiliyor..."
    hyprctl dispatch workspace "0"
    sleep 1
    echo "Geçiş için 1 saniye bekleniyor..."
fi

echo "Uygulama başlatılıyor..."
echo "COMMAND: wezterm "start" "--class" "rmpc" "-e" "rmpc""
echo "VPN MODE: secure"

# Start the application with the appropriate VPN mode
case "secure" in
    bypass)
        if command -v mullvad >/dev/null 2>&1 && mullvad status 2>/dev/null | grep -q "Connected"; then
            if command -v mullvad-exclude >/dev/null 2>&1; then
                echo "VPN bypass ile başlatılıyor (mullvad-exclude)"
                mullvad-exclude wezterm "start" "--class" "rmpc" "-e" "rmpc" &
            else
                echo "UYARI: mullvad-exclude bulunamadı, normal başlatılıyor"
                wezterm "start" "--class" "rmpc" "-e" "rmpc" &
            fi
        else
            echo "VPN bağlı değil, normal başlatılıyor"
            wezterm "start" "--class" "rmpc" "-e" "rmpc" &
        fi
        ;;
    secure|*)
        if command -v mullvad >/dev/null 2>&1 && mullvad status 2>/dev/null | grep -q "Connected"; then
            echo "VPN koruması ile başlatılıyor"
        else
            echo "UYARI: VPN bağlı değil! Korumasız başlatılıyor"
        fi
        wezterm "start" "--class" "rmpc" "-e" "rmpc" &
        ;;
esac

# Save PID and wait a moment
APP_PID=$!
mkdir -p "/tmp/sem"
echo "$APP_PID" > "/tmp/sem/wezterm-rmpc.pid"
echo "Uygulama başlatıldı (PID: $APP_PID)"

# Make fullscreen if needed
if [[ "false" == "true" ]]; then
    echo "Uygulama yüklenmesi için 1 saniye bekleniyor..."
    sleep 1
    
    if command -v hyprctl >/dev/null 2>&1; then
        echo "Tam ekran yapılıyor..."
        hyprctl dispatch fullscreen 1
    fi
fi

# Switch to final workspace if needed
if [[ "0" != "0" && "0" != "0" ]]; then
    echo "Son workspace'e geçiliyor..."
    if command -v hyprctl >/dev/null 2>&1; then
        hyprctl dispatch workspace "0"
    fi
fi

exit 0
