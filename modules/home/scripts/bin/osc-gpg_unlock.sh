#!/usr/bin/env bash
# osc-gpg_unlock.sh - GPG anahtar/agent açıcı
# Smartcard/USB anahtarları için pinentry sürecini hızlandırır, cache tazeler.

# Renk tanımlamaları
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Log fonksiyonları
log_info() {
	echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
	echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_error() {
	echo -e "${RED}[ERROR]${NC} $1"
}

log_header() {
	echo -e "\n${BOLD}${YELLOW}$1${NC}"
	echo -e "${YELLOW}$(printf '=%.0s' {1..50})${NC}\n"
}

# Hata yakalama
set -e
trap 'echo -e "\n${RED}[ERROR] Bir hata oluştu! Satır: $LINENO${NC}"; exit 1' ERR

# Banner göster
clear
echo -e "${BOLD}${BLUE}"
cat <<"EOF"
  ____  ____   ____    _    _  _____ _   _ _____ 
 / ___||  _ \ / ___|  / \  | |/ /_ _| \ | |_   _|
| |  _ | |_) | |  _  / _ \ | ' / | ||  \| | | |  
| |_| ||  __/| |_| |/ ___ \| . \ | || |\  | | |  
 \____|_|     \____/_/   \_\_|\_\___|_| \_| |_|  
                                                  
EOF
echo -e "${NC}"

# Çevre değişkenlerini ayarla
log_header "Çevre Değişkenleri Ayarlanıyor"
export WAYLAND_DISPLAY=wayland-1
export XDG_RUNTIME_DIR="/run/user/$(id -u)"
export DBUS_SESSION_BUS_ADDRESS="unix:path=${XDG_RUNTIME_DIR}/bus"
export GPG_TTY=$(tty)
log_success "Çevre değişkenleri ayarlandı"

# GPG agent'ı yeniden başlat
log_header "GPG Agent Yeniden Başlatılıyor"
log_info "GPG agent durduruluyor..."
gpgconf --kill all
sleep 1
log_info "TTY güncelleniyor..."
gpg-connect-agent updatestartuptty /bye
log_success "GPG agent yeniden başlatıldı"

# Anahtarları listele
log_header "GPG Anahtarları"
gpg -K --with-keygrip

# Test imzalama
log_header "Test İmzalama"
log_info "İmzalama işlemi başlatılıyor..."
TEST_RESULT=$(echo "test" | gpg --clearsign 2>&1)

# Sonucu kontrol et
if [ $? -eq 0 ]; then
	log_success "GPG anahtar kilidi başarıyla açıldı!"
	log_info "İmzalama işlemi başarılı"
else
	log_error "İmzalama işlemi başarısız!"
	log_error "$TEST_RESULT"
	exit 1
fi

echo -e "\n${BOLD}${GREEN}İşlem Tamamlandı!${NC}\n"
