#!/usr/bin/env bash
# Profile: discord
set -euo pipefail

echo "Initializing discord..."

# Switch to initial workspace
if [[ "5" != "0" ]] && command -v hyprctl >/dev/null 2>&1; then
    echo "Workspace 5'e geçiliyor..."
    hyprctl dispatch workspace "5"
    sleep 1
    echo "Geçiş için 1 saniye bekleniyor..."
fi

echo "Uygulama başlatılıyor..."
echo "COMMAND: discord "-m" "--class=discord" "--title=discord""
echo "VPN MODE: bypass"

# Start the application with the appropriate VPN mode
case "bypass" in
    bypass)
        if command -v mullvad >/dev/null 2>&1 && mullvad status 2>/dev/null | grep -q "Connected"; then
            if command -v mullvad-exclude >/dev/null 2>&1; then
                echo "VPN bypass ile başlatılıyor (mullvad-exclude)"
                mullvad-exclude discord "-m" "--class=discord" "--title=discord" &
            else
                echo "UYARI: mullvad-exclude bulunamadı, normal başlatılıyor"
                discord "-m" "--class=discord" "--title=discord" &
            fi
        else
            echo "VPN bağlı değil, normal başlatılıyor"
            discord "-m" "--class=discord" "--title=discord" &
        fi
        ;;
    secure|*)
        if command -v mullvad >/dev/null 2>&1 && mullvad status 2>/dev/null | grep -q "Connected"; then
            echo "VPN koruması ile başlatılıyor"
        else
            echo "UYARI: VPN bağlı değil! Korumasız başlatılıyor"
        fi
        discord "-m" "--class=discord" "--title=discord" &
        ;;
esac

# Save PID and wait a moment
APP_PID=$!
mkdir -p "/tmp/sem"
echo "$APP_PID" > "/tmp/sem/discord.pid"
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
if [[ "2" != "0" && "2" != "5" ]]; then
    echo "Son workspace'e geçiliyor..."
    if command -v hyprctl >/dev/null 2>&1; then
        hyprctl dispatch workspace "2"
    fi
fi

exit 0
