#!/usr/bin/env bash
# Profile: Zen-Whats
set -euo pipefail

echo "[2025-04-18 15:52:59] Starting Zen-Whats..."
echo "Initializing Zen-Whats..."

# Switch to initial workspace
if [[ "9" != "0" ]] && command -v hyprctl >/dev/null 2>&1; then
    echo "Workspace 9'e geçiliyor..."
    hyprctl dispatch workspace "9"
    sleep 1
    echo "Geçiş için 1 saniye bekleniyor..."
fi

echo "Uygulama başlatılıyor..."
echo "COMMAND: zen "-P" "Whats" "--class" "Whats" "--name" "Whats" "--restore-session""
echo "VPN MODE: secure"

# Start the application with the appropriate VPN mode
case "secure" in
    bypass)
        if command -v mullvad >/dev/null 2>&1 && mullvad status 2>/dev/null | grep -q "Connected"; then
            if command -v mullvad-exclude >/dev/null 2>&1; then
                echo "VPN bypass ile başlatılıyor (mullvad-exclude)"
                mullvad-exclude zen "-P" "Whats" "--class" "Whats" "--name" "Whats" "--restore-session" &
            else
                echo "UYARI: mullvad-exclude bulunamadı, normal başlatılıyor"
                zen "-P" "Whats" "--class" "Whats" "--name" "Whats" "--restore-session" &
            fi
        else
            echo "VPN bağlı değil, normal başlatılıyor"
            zen "-P" "Whats" "--class" "Whats" "--name" "Whats" "--restore-session" &
        fi
        ;;
    secure|*)
        if command -v mullvad >/dev/null 2>&1 && mullvad status 2>/dev/null | grep -q "Connected"; then
            echo "VPN koruması ile başlatılıyor"
        else
            echo "UYARI: VPN bağlı değil! Korumasız başlatılıyor"
        fi
        zen "-P" "Whats" "--class" "Whats" "--name" "Whats" "--restore-session" &
        ;;
esac

# Save PID and wait a moment
APP_PID=$!
mkdir -p "/tmp/sem"
echo "$APP_PID" > "/tmp/sem/Zen-Whats.pid"
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
if [[ "9" != "0" && "9" != "9" ]]; then
    echo "Son workspace'e geçiliyor..."
    if command -v hyprctl >/dev/null 2>&1; then
        hyprctl dispatch workspace "9"
    fi
fi

exit 0
