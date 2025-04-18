#!/usr/bin/env bash
#===============================================================================
# Brave-Discord için oluşturulan başlatma script'i
# VPN Modu: secure
# Elle düzenlemeyin - semsumo tarafından otomatik oluşturulmuştur
#===============================================================================

# Hata yönetimi
set -euo pipefail

# Ortam ayarları
export TMPDIR="/tmp/sem"

# Sabitler
WORKSPACE=5
FINAL_WORKSPACE=2
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

# Brave-Discord workspace'ine geç
switch_workspace "$WORKSPACE"

# Semsumo ile oturumu başlat
echo "Brave-Discord başlatılıyor..."
semsumo start "Brave-Discord" "secure" &

# Uygulamanın açılması için bekle
echo "Uygulama açılması için $WAIT_TIME saniye bekleniyor..."
sleep $WAIT_TIME

# Tam ekran yap
make_fullscreen

# Tamamlandığında ana workspace'e geri dön
echo "İşlem tamamlandı, workspace $FINAL_WORKSPACE'e dönülüyor..."
switch_workspace "$FINAL_WORKSPACE"

# Başarıyla çıkış yap
exit 0
