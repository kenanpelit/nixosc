#!/usr/bin/env bash
# Profile: Zen-CompecTA
set -euo pipefail

echo "Initializing Zen-CompecTA..."

# Switch to initial workspace
if [[ "4" != "0" ]] && command -v hyprctl >/dev/null 2>&1; then
    echo "Workspace 4'e geçiliyor..."
    hyprctl dispatch workspace "4"
    sleep 1
    echo "Geçiş için 1 saniye bekleniyor..."
fi

echo "Uygulama başlatılıyor..."
echo "COMMAND: zen "-P" "CompecTA" "--class" "CompecTA" "--name" "CompecTA" "--restore-session""
echo "VPN MODE: secure"

# Start the application with the appropriate VPN mode
case "secure" in
    bypass)
        if command -v mullvad >/dev/null 2>&1 && mullvad status 2>/dev/null | grep -q "Connected"; then
            if command -v mullvad-exclude >/dev/null 2>&1; then
                echo "VPN bypass ile başlatılıyor (mullvad-exclude)"
                mullvad-exclude zen "-P" "CompecTA" "--class" "CompecTA" "--name" "CompecTA" "--restore-session" &
            else
                echo "UYARI: mullvad-exclude bulunamadı, normal başlatılıyor"
                zen "-P" "CompecTA" "--class" "CompecTA" "--name" "CompecTA" "--restore-session" &
            fi
        else
            echo "VPN bağlı değil, normal başlatılıyor"
            zen "-P" "CompecTA" "--class" "CompecTA" "--name" "CompecTA" "--restore-session" &
        fi
        ;;
    secure|*)
        if command -v mullvad >/dev/null 2>&1 && mullvad status 2>/dev/null | grep -q "Connected"; then
            echo "VPN koruması ile başlatılıyor"
        else
            echo "UYARI: VPN bağlı değil! Korumasız başlatılıyor"
        fi
        zen "-P" "CompecTA" "--class" "CompecTA" "--name" "CompecTA" "--restore-session" &
        ;;
esac

# Save PID and wait a moment
APP_PID=$!
mkdir -p "/tmp/sem"
echo "$APP_PID" > "/tmp/sem/Zen-CompecTA.pid"
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
if [[ "4" != "0" && "4" != "4" ]]; then
    echo "Son workspace'e geçiliyor..."
    if command -v hyprctl >/dev/null 2>&1; then
        hyprctl dispatch workspace "4"
    fi
fi

exit 0
