#!/usr/bin/env bash
# Profile: spotify
set -euo pipefail

echo "[2025-04-18 15:52:59] Starting spotify..."
echo "Initializing spotify..."

# Switch to initial workspace
if [[ "8" != "0" ]] && command -v hyprctl >/dev/null 2>&1; then
    echo "Workspace 8'e geçiliyor..."
    hyprctl dispatch workspace "8"
    sleep 1
    echo "Geçiş için 1 saniye bekleniyor..."
fi

echo "Uygulama başlatılıyor..."
echo "COMMAND: spotify "--class" "Spotify" "-T" "Spotify""
echo "VPN MODE: bypass"

# Start the application with the appropriate VPN mode
case "bypass" in
    bypass)
        if command -v mullvad >/dev/null 2>&1 && mullvad status 2>/dev/null | grep -q "Connected"; then
            if command -v mullvad-exclude >/dev/null 2>&1; then
                echo "VPN bypass ile başlatılıyor (mullvad-exclude)"
                mullvad-exclude spotify "--class" "Spotify" "-T" "Spotify" &
            else
                echo "UYARI: mullvad-exclude bulunamadı, normal başlatılıyor"
                spotify "--class" "Spotify" "-T" "Spotify" &
            fi
        else
            echo "VPN bağlı değil, normal başlatılıyor"
            spotify "--class" "Spotify" "-T" "Spotify" &
        fi
        ;;
    secure|*)
        if command -v mullvad >/dev/null 2>&1 && mullvad status 2>/dev/null | grep -q "Connected"; then
            echo "VPN koruması ile başlatılıyor"
        else
            echo "UYARI: VPN bağlı değil! Korumasız başlatılıyor"
        fi
        spotify "--class" "Spotify" "-T" "Spotify" &
        ;;
esac

# Save PID and wait a moment
APP_PID=$!
mkdir -p "/tmp/sem"
echo "$APP_PID" > "/tmp/sem/spotify.pid"
echo "Uygulama başlatıldı (PID: $APP_PID)"

# Make fullscreen if needed
if [[ "true" == "true" ]]; then
    echo "Uygulama yüklenmesi için 1 saniye bekleniyor..."
    sleep 1
    
    if command -v hyprctl >/dev/null 2>&1; then
        echo "Tam ekran yapılıyor..."
        hyprctl dispatch fullscreen 1
    fi
fi

# Switch to final workspace if needed
if [[ "8" != "0" && "8" != "8" ]]; then
    echo "Son workspace'e geçiliyor..."
    if command -v hyprctl >/dev/null 2>&1; then
        hyprctl dispatch workspace "8"
    fi
fi

exit 0
