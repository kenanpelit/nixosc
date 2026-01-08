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
    if command -v nirius >/dev/null 2>&1; then
        nirius scratchpad-toggle
    else
        niri msg action move-window-to-workspace 255
    fi
else
    # Odakta değil veya başka yerde -> GÖSTER
    
    # Adım A: Mevcut workspace'i kaydet (Gitmek istediğimiz yer burası)
    TARGET_WS_ID=$(niri msg -j workspaces | jq -r '.[] | select(.is_focused == true) | .id')
    
    # Adım B: Pencereye odaklan (Niri bizi o pencerenin olduğu yere götürebilir)
    # Eğer scratchpad'deyse nirius ile çekmek daha mantıklı ama manuel yapıyoruz.
    niri msg action focus-window --id "$DROPDOWN_ID"
    
    # Adım C: Pencereyi hedef workspace'e taşı
    # Focus işlemi sonrası aktif workspace değişmiş olabilir ama pencere artık "odaklanmış" durumda.
    # Odaklı pencereyi TARGET_WS_ID'ye taşıyoruz.
    niri msg action move-window-to-workspace "$TARGET_WS_ID"
    
    # Adım D: Hedef workspace'e geri dön (Eğer Niri otomatik götürmediyse)
    # move-window-to-workspace genellikle odaklanılan pencereyi taşıdığı için
    # ve biz o pencereye odaklı olduğumuz için, pencereyle birlikte geri gelmiş olmalıyız.
    # Ancak garanti olsun diye focus-workspace de yapılabilir ama genelde gerekmez.
fi