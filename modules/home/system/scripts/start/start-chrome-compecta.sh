#!/usr/bin/env bash
#===============================================================================
# Chrome-CompecTA için oluşturulan başlatma script'i
# VPN Modu: secure
# Elle düzenlemeyin - semsumo tarafından otomatik oluşturulmuştur
#===============================================================================

# Hata yönetimi
set -euo pipefail

# Ortam ayarları
export TMPDIR="/tmp/sem"

# Sabitler
WORKSPACE=4
FINAL_WORKSPACE=4
WAIT_TIME=2

# Workspace'e geçiş fonksiyonu
switch_workspace() {
    local workspace="$1"
    if command -v hyprctl &>/dev/null; then
        echo "Workspace $workspace'e geçiliyor..."
        hyprctl dispatch workspace "$workspace"
        sleep 1
    fi
}

# Tam ekran yapma fonksiyonu
make_fullscreen() {
    if command -v hyprctl &>/dev/null; then
        echo "Aktif pencere tam ekran yapılıyor..."
        sleep 1
        hyprctl dispatch fullscreen 1
        sleep 1
    fi
}

# Chrome-CompecTA workspace'ine geç
switch_workspace "$WORKSPACE"

# Semsumo ile oturumu başlat
echo "Chrome-CompecTA başlatılıyor..."
semsumo start "Chrome-CompecTA" "secure" &

# Uygulamanın açılması için bekle
echo "Uygulama açılması için $WAIT_TIME saniye bekleniyor..."
sleep $WAIT_TIME

# Başarıyla çıkış yap
exit 0
