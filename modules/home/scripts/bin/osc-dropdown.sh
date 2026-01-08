#!/usr/bin/env bash
# ==============================================================================
# osc-dropdown.sh - Toggle a specialized dropdown terminal in Niri
# ==============================================================================

set -euo pipefail

APP_ID="dropdown-terminal"
TERMINAL_CMD="kitty --class $APP_ID"

# 1. Terminal Hiç Yoksa -> Başlat
if ! niri msg -j windows | jq -e --arg app "$APP_ID" '.[] | select(.app_id == $app)' >/dev/null; then
    exec $TERMINAL_CMD &
    exit 0
fi

# 2. Terminal Var -> Durumunu Kontrol Et
DROPDOWN_ID=$(niri msg -j windows | jq -r --arg app "$APP_ID" '.[] | select(.app_id == $app) | .id')
FOCUSED_ID=$(niri msg -j windows | jq -r '.[] | select(.is_focused == true) | .id')

if [[ "$DROPDOWN_ID" == "$FOCUSED_ID" ]]; then
    # --- GİZLE ---
    if command -v nirius >/dev/null 2>&1; then
        nirius scratchpad-toggle
    else
        niri msg action move-window-to-workspace 255
    fi
else
    # --- GÖSTER ---
    # Nirius varsa, en temiz ve hatasız yöntem budur: "Buraya getir ve odaklan"
    if command -v nirius >/dev/null 2>&1; then
        # Nirius taşıma yaparken zaten odaklar. 
        # Eğer zaten buradaysa hata verebilir, onu yutalım ve manuel odaklanalım.
        if ! nirius move-to-current-workspace --app-id "$APP_ID" --focus 2>/dev/null; then
             niri msg action focus-window --id "$DROPDOWN_ID"
        fi
    else
        # Nirius yoksa manuel yöntem (Riskli, ama denemek lazım)
        TARGET_WS_ID=$(niri msg -j workspaces | jq -r '.[] | select(.is_focused == true) | .id')
        niri msg action focus-window --id "$DROPDOWN_ID"
        # Eğer focus bizi başka yere attıysa, geri taşı
        niri msg action move-window-to-workspace "$TARGET_WS_ID"
        # Ve tekrar o workspace'e git (gerekirse)
        niri msg action focus-workspace "$TARGET_WS_ID"
    fi
fi
