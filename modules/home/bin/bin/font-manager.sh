#!/usr/bin/env bash

##################### HELP TEXT START #####################
# Hack Nerd Font Manager
#
# Özet:
# Bu script Arch Linux sistemlerde Hack Nerd Font kurulumu yapar,
# font rendering ayarlarını optimize eder ve GNOME masaüstünde
# font yapılandırmasını yönetir.
#
# Özellikler:
# - Sistem seviyesinde font kurulumu ve yapılandırması
# - Font rendering optimizasyonları
# - GNOME masaüstü font ayarlarını yönetme
# - Mevcut font ayarlarını görüntüleme
#
# Kullanım:
#   ./font-manager.sh [seçenek]
#
# Seçenekler:
#   -h, --help           : Bu yardım mesajını gösterir
#   -i, --install        : Hack Nerd Font'u sistem seviyesinde kurar
#   -s, --set-gnome      : GNOME masaüstü font ayarlarını yapılandırır
#   -v, --view           : Mevcut font ayarlarını gösterir
#   --interface-size N   : Arayüz font boyutunu ayarlar (varsayılan: 11)
#   --document-size N    : Doküman font boyutunu ayarlar (varsayılan: 11)
#   --monospace-size N   : Sabit genişlikli font boyutunu ayarlar (varsayılan: 13)
#   --title-size N       : Başlık font boyutunu ayarlar (varsayılan: 11)
#
# Örnekler:
#   ./font-manager.sh -i                      # Sistem kurulumu yapar
#   ./font-manager.sh -s                      # GNOME ayarlarını yapar
#   ./font-manager.sh -v                      # Ayarları gösterir
#   ./font-manager.sh -s --interface-size 12  # Özel boyutla ayarlar
##################### HELP TEXT END #####################

# Renk tanımlamaları
BLUE='\033[0;34m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

# Varsayılan font boyutları
INTERFACE_SIZE="11"
DOCUMENT_SIZE="11"
MONOSPACE_SIZE="12"
TITLE_SIZE="11"

# Yardım mesajını göster
show_help() {
  sed -n '/^##################### HELP TEXT START #####################$/,/^##################### HELP TEXT END #####################$/p' "$0" |
    grep '^#' |
    sed 's/^# \?//'
  exit 0
}

# Root yetkisi kontrolü
check_root() {
  if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Bu işlem root yetkileri gerektiriyor.${NC}"
    echo "Lütfen 'sudo' ile çalıştırın."
    exit 1
  fi
}

# Sistem seviyesinde kurulum
install_system_fonts() {
  check_root

  echo -e "${GREEN}Arch Linux font rendering kurulumu başlıyor...${NC}"

  # Gerekli paketlerin yüklenmesi
  echo "Gerekli paketler yükleniyor..."
  pacman -S --needed --noconfirm freetype2 cairo fontconfig

  # Font konfigürasyon dizini oluşturma
  echo "Font konfigürasyon dizini oluşturuluyor..."
  mkdir -p /etc/fonts

  # Font konfigürasyon dosyasını oluşturma
  echo "Font konfigürasyon dosyası oluşturuluyor..."
  cat >/etc/fonts/local.conf <<'EOL'
<?xml version="1.0"?>
<!DOCTYPE fontconfig SYSTEM "fonts.dtd">
<fontconfig>
  <match target="font">
    <edit name="antialias" mode="assign">
      <bool>true</bool>
    </edit>
    <edit name="hinting" mode="assign">
      <bool>true</bool>
    </edit>
    <edit name="hintstyle" mode="assign">
      <const>hintslight</const>
    </edit>
    <edit name="rgba" mode="assign">
      <const>rgb</const>
    </edit>
    <edit name="lcdfilter" mode="assign">
      <const>lcddefault</const>
    </edit>
  </match>
</fontconfig>
EOL

  # Freetype özelliklerini ayarlama
  echo "Freetype özellikleri ayarlanıyor..."
  echo 'export FREETYPE_PROPERTIES="truetype:interpreter-version=40"' >/etc/profile.d/freetype2.sh

  # Nerd Font kurulumu
  if command -v paru >/dev/null 2>&1; then
    echo "Hack Nerd Font yükleniyor (paru ile)..."
    sudo -u $SUDO_USER paru -S --noconfirm ttf-hack-nerd
  elif command -v yay >/dev/null 2>&1; then
    echo "Hack Nerd Font yükleniyor (yay ile)..."
    sudo -u $SUDO_USER yay -S --noconfirm ttf-hack-nerd
  else
    echo -e "${RED}UYARI: paru veya yay bulunamadı. Hack Nerd Font manuel olarak yüklenmelidir.${NC}"
  fi

  # Font önbelleğini güncelleme
  echo "Font önbelleği güncelleniyor..."
  fc-cache -f

  echo -e "${GREEN}Kurulum tamamlandı!${NC}"
  echo "Değişikliklerin etkili olması için oturumu yeniden başlatmanız önerilir."
}

# GNOME masaüstü ayarları
set_gnome_fonts() {
  echo -e "${GREEN}Hack Nerd Font ayarları uygulanıyor...${NC}"

  # Genel arayüz fontları
  gsettings set org.gnome.desktop.interface font-name "Hack Nerd Font $INTERFACE_SIZE"
  gsettings set org.gnome.desktop.interface document-font-name "Hack Nerd Font $DOCUMENT_SIZE"
  gsettings set org.gnome.desktop.interface monospace-font-name "Hack Nerd Font Mono $MONOSPACE_SIZE"

  # Pencere başlığı fontu
  gsettings set org.gnome.desktop.wm.preferences titlebar-font "Hack Nerd Font Bold $TITLE_SIZE"

  # Font rendering ayarları
  gsettings set org.gnome.desktop.interface font-antialiasing "rgba"
  gsettings set org.gnome.desktop.interface font-hinting "slight"
  gsettings set org.gnome.desktop.interface text-scaling-factor 1.0

  echo -e "${GREEN}Font ayarları başarıyla uygulandı!${NC}"
}

# Mevcut ayarları görüntüle
view_settings() {
  echo -e "${BLUE}=== Sistem Font Ayarları ===${NC}\n"

  echo -e "${GREEN}Genel Arayüz Fontları:${NC}"
  echo "• Sistem Fontu: $(gsettings get org.gnome.desktop.interface font-name)"
  echo "• Doküman Fontu: $(gsettings get org.gnome.desktop.interface document-font-name)"
  echo "• Sabit Genişlikli Font: $(gsettings get org.gnome.desktop.interface monospace-font-name)"

  echo -e "\n${GREEN}Pencere Yöneticisi Fontları:${NC}"
  echo "• Pencere Başlığı Fontu: $(gsettings get org.gnome.desktop.wm.preferences titlebar-font)"

  echo -e "\n${GREEN}Ölçekleme Ayarları:${NC}"
  echo "• Metin Ölçeği: $(gsettings get org.gnome.desktop.interface text-scaling-factor)"
  echo "• DPI Ayarı: $(gsettings get org.gnome.desktop.interface font-dpi 2>/dev/null || echo 'Ayarlanmamış')"

  echo -e "\n${GREEN}Yazı Tipi Hinting:${NC}"
  echo "• Hinting: $(gsettings get org.gnome.desktop.interface font-hinting)"
  echo "• Antialiasing: $(gsettings get org.gnome.desktop.interface font-antialiasing)"
}

# Ana program
main() {
  # Parametre yoksa yardım göster
  if [ $# -eq 0 ]; then
    show_help
    exit 0
  fi

  # Parametreleri işle
  while [ $# -gt 0 ]; do
    case "$1" in
    -h | --help)
      show_help
      ;;
    -i | --install)
      install_system_fonts
      ;;
    -s | --set-gnome)
      set_gnome_fonts
      ;;
    -v | --view)
      view_settings
      ;;
    --interface-size)
      INTERFACE_SIZE="$2"
      shift
      ;;
    --document-size)
      DOCUMENT_SIZE="$2"
      shift
      ;;
    --monospace-size)
      MONOSPACE_SIZE="$2"
      shift
      ;;
    --title-size)
      TITLE_SIZE="$2"
      shift
      ;;
    *)
      echo -e "${RED}Geçersiz parametre: $1${NC}"
      show_help
      exit 1
      ;;
    esac
    shift
  done
}

# Programı çalıştır
main "$@"
