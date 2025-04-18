#!/usr/bin/env bash
# Profile: kitty-single
set -euo pipefail

echo "Initializing kitty-single..."

# Switch to initial workspace
if [[ "2" != "0" ]] && command -v hyprctl >/dev/null 2>&1; then
    echo "Workspace 2'e geçiliyor..."
    hyprctl dispatch workspace "2"
    sleep 1
    echo "Geçiş için 1 saniye bekleniyor..."
fi

echo "Uygulama başlatılıyor..."
echo "COMMAND: kitty "--class" "kitty" "-T" "kitty" "--single-instance""
echo "VPN MODE: secure"

# Start the application with the appropriate VPN mode
case "secure" in
    bypass)
        if command -v mullvad >/dev/null 2>&1 && mullvad status 2>/dev/null | grep -q "Connected"; then
            if command -v mullvad-exclude >/dev/null 2>&1; then
                echo "VPN bypass ile başlatılıyor (mullvad-exclude)"
                mullvad-exclude kitty "--class" "kitty" "-T" "kitty" "--single-instance" &
            else
                echo "UYARI: mullvad-exclude bulunamadı, normal başlatılıyor"
                kitty "--class" "kitty" "-T" "kitty" "--single-instance" &
            fi
        else
            echo "VPN bağlı değil, normal başlatılıyor"
            kitty "--class" "kitty" "-T" "kitty" "--single-instance" &
        fi
        ;;
    secure|*)
        if command -v mullvad >/dev/null 2>&1 && mullvad status 2>/dev/null | grep -q "Connected"; then
            echo "VPN koruması ile başlatılıyor"
        else
            echo "UYARI: VPN bağlı değil! Korumasız başlatılıyor"
        fi
        kitty "--class" "kitty" "-T" "kitty" "--single-instance" &
        ;;
esac

# Save PID and wait a moment
APP_PID=$!
mkdir -p "/tmp/sem"
echo "$APP_PID" > "/tmp/sem/kitty-single.pid"
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
if [[ "2" != "0" && "2" != "2" ]]; then
    echo "Son workspace'e geçiliyor..."
    if command -v hyprctl >/dev/null 2>&1; then
        hyprctl dispatch workspace "2"
    fi
fi

exit 0
