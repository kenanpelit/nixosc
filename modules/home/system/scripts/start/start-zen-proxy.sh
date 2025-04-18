#!/usr/bin/env bash
# Profile: Zen-Proxy
set -euo pipefail

echo "[2025-04-18 15:52:59] Starting Zen-Proxy..."
echo "Initializing Zen-Proxy..."

# Switch to initial workspace
if [[ "7" != "0" ]] && command -v hyprctl >/dev/null 2>&1; then
    echo "Workspace 7'e geçiliyor..."
    hyprctl dispatch workspace "7"
    sleep 1
    echo "Geçiş için 1 saniye bekleniyor..."
fi

echo "Uygulama başlatılıyor..."
echo "COMMAND: zen "-P" "Proxy" "--class" "Proxy" "--name" "Proxy" "--restore-session""
echo "VPN MODE: bypass"

# Start the application with the appropriate VPN mode
case "bypass" in
    bypass)
        if command -v mullvad >/dev/null 2>&1 && mullvad status 2>/dev/null | grep -q "Connected"; then
            if command -v mullvad-exclude >/dev/null 2>&1; then
                echo "VPN bypass ile başlatılıyor (mullvad-exclude)"
                mullvad-exclude zen "-P" "Proxy" "--class" "Proxy" "--name" "Proxy" "--restore-session" &
            else
                echo "UYARI: mullvad-exclude bulunamadı, normal başlatılıyor"
                zen "-P" "Proxy" "--class" "Proxy" "--name" "Proxy" "--restore-session" &
            fi
        else
            echo "VPN bağlı değil, normal başlatılıyor"
            zen "-P" "Proxy" "--class" "Proxy" "--name" "Proxy" "--restore-session" &
        fi
        ;;
    secure|*)
        if command -v mullvad >/dev/null 2>&1 && mullvad status 2>/dev/null | grep -q "Connected"; then
            echo "VPN koruması ile başlatılıyor"
        else
            echo "UYARI: VPN bağlı değil! Korumasız başlatılıyor"
        fi
        zen "-P" "Proxy" "--class" "Proxy" "--name" "Proxy" "--restore-session" &
        ;;
esac

# Save PID and wait a moment
APP_PID=$!
mkdir -p "/tmp/sem"
echo "$APP_PID" > "/tmp/sem/Zen-Proxy.pid"
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
if [[ "7" != "0" && "7" != "7" ]]; then
    echo "Son workspace'e geçiliyor..."
    if command -v hyprctl >/dev/null 2>&1; then
        hyprctl dispatch workspace "7"
    fi
fi

exit 0
