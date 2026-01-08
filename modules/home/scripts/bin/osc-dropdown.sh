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
    # Zaten odakta -> GİZLE
    # Scratchpad'e göndererek gizlemek en temizi
    if command -v nirius >/dev/null 2>&1; then
        nirius scratchpad-toggle --id "$DROPDOWN_ID"
    else
        # Nirius yoksa, en sona at
        niri msg action move-window-to-workspace 255
    fi
else
    # Odakta değil veya başka yerde -> GÖSTER
    # Önce scratchpad'den çıkar (veya olduğu yerden) ve odaklan
    niri msg action focus-window --id "$DROPDOWN_ID"
    
    # Eğer başka workspace'teyse buraya çek (Opsiyonel, focus genelde yeterli olur)
    # Ama dropdown mantığı gereği mevcut işimizin üstüne gelmeli.
    current_ws=$(niri msg -j workspaces | jq -r '.[] | select(.is_focused == true) | .id')
    niri msg action move-window-to-workspace "$current_ws"
fi