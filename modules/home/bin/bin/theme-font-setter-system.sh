#!/usr/bin/env bash
#######################################
#
# Version: 1.0.0
# Date: 2024-12-12
# Author: Kenan Pelit
# Repository: github.com/kenanpelit/dotfiles
# Description: GnomeThemeSetter - GNOME Tema ve Font Yönetim Aracı
#
# Bu script GNOME masaüstü ortamı için tema ve font ayarlarını yönetir.
# Temel özellikleri:
#
# - Tema Yönetimi:
#   - GTK temaları
#   - İkon temaları
#   - İmleç temaları
#   - Renk şemaları
#
# - Font Yönetimi:
#   - Arayüz fontları
#   - Doküman fontları
#   - Sabit genişlikli fontlar
#   - Başlık fontları
#   - Font ölçekleme
#   - Antialiasing ve hinting
#
# - GSettings Entegrasyonu:
#   - Otomatik ayar kontrolü
#   - Tema varlık kontrolü
#   - Anlık uygulama
#   - Hata yönetimi
#
# - Araç Özellikleri:
#   - Komut satırı arayüzü
#   - Mevcut tema listesi
#   - Mevcut font ayarları
#   - Renkli terminal çıktıları
#
# License: MIT
#
#######################################
## Varsayılan ayarlarla çalıştır
#./system-theme-font-setter.sh

## Sadece tema değiştir
#./system-theme-font-setter.sh -t Adwaita-dark -i Papirus

## Sadece fontları değiştir
#./system-theme-font-setter.sh --interface-font "Hack Nerd Font 12" --mono-font "Hack Nerd Font Mono 14"

## Mevcut font ayarlarını göster
#./system-theme-font-setter.sh -f

## Mevcut temaları listele
#./system-theme-font-setter.sh -l

## Yardım mesajını göster
#./system-theme-font-setter.sh -h

# Renk tanımlamaları
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # Renk sıfırlama

# Varsayılan ayarları tanımla
declare -A DEFAULT_SETTINGS=(
  ["THEME"]="Arc-Dark"
  ["ICONS"]="a-candy-beauty-icon-theme"
  ["FONT_INTERFACE"]="Hack Nerd Font 11"
  ["FONT_DOCUMENT"]="Hack Nerd Font 11"
  ["FONT_MONO"]="Hack Nerd Font Mono 13"
  ["FONT_TITLE"]="Hack Nerd Font Bold 11"
  ["CURSOR"]="Catppuccin-Mocha-Dark-Cursors"
  ["SCALE"]="1.0"
  ["SCHEME"]="prefer-dark"
)

# GSettings şeması yolları
INTERFACE_SCHEMA="gsettings set org.gnome.desktop.interface"
WM_SCHEMA="gsettings set org.gnome.desktop.wm.preferences"

# Yardım mesajını göster
show_help() {
  cat <<EOF
Kullanım: $(basename "$0") [SEÇENEKLER]

GNOME masaüstü temalarını, fontları ve görünüm ayarlarını yapılandırır.

Seçenekler:
    -t, --theme           GTK teması (varsayılan: ${DEFAULT_SETTINGS["THEME"]})
    -i, --icons          İkon teması (varsayılan: ${DEFAULT_SETTINGS["ICONS"]})
    -c, --cursor         İmleç teması (varsayılan: ${DEFAULT_SETTINGS["CURSOR"]})
    --scheme             Renk şeması (varsayılan: ${DEFAULT_SETTINGS["SCHEME"]})
    
    Font Ayarları:
    --interface-font     Arayüz fontu (varsayılan: ${DEFAULT_SETTINGS["FONT_INTERFACE"]})
    --document-font     Doküman fontu (varsayılan: ${DEFAULT_SETTINGS["FONT_DOCUMENT"]})
    --mono-font         Sabit genişlikli font (varsayılan: ${DEFAULT_SETTINGS["FONT_MONO"]})
    --title-font        Başlık fontu (varsayılan: ${DEFAULT_SETTINGS["FONT_TITLE"]})
    -s, --scale         Metin ölçeği (varsayılan: ${DEFAULT_SETTINGS["SCALE"]})
    
    Diğer:
    -h, --help          Bu yardım mesajını göster
    -l, --list          Mevcut temaları listele
    -f, --show-fonts    Mevcut font ayarlarını göster

Örnek:
    $(basename "$0") -t Adwaita-dark -i Papirus --interface-font "Hack Nerd Font 12"
EOF
}

# Mevcut font ayarlarını göster
show_current_settings() {
  echo -e "${BLUE}=== Mevcut Font Ayarları ===${NC}\n"

  echo -e "${GREEN}Genel Arayüz Fontları:${NC}"
  echo "• Sistem Fontu: $(gsettings get org.gnome.desktop.interface font-name)"
  echo "• Doküman Fontu: $(gsettings get org.gnome.desktop.interface document-font-name)"
  echo "• Sabit Genişlikli Font: $(gsettings get org.gnome.desktop.interface monospace-font-name)"
  echo "• Pencere Başlığı Fontu: $(gsettings get org.gnome.desktop.wm.preferences titlebar-font)"

  echo -e "\n${GREEN}Rendering Ayarları:${NC}"
  echo "• Antialiasing: $(gsettings get org.gnome.desktop.interface font-antialiasing)"
  echo "• Hinting: $(gsettings get org.gnome.desktop.interface font-hinting)"
  echo "• Metin Ölçeği: $(gsettings get org.gnome.desktop.interface text-scaling-factor)"
}

# Mevcut temaları listele
list_available_themes() {
  echo -e "${YELLOW}Mevcut GTK Temaları:${NC}"
  find /usr/share/themes ~/.themes -maxdepth 1 -type d -printf "%f\n" 2>/dev/null | sort -u | grep -v '^$'

  echo -e "\n${YELLOW}Mevcut İkon Temaları:${NC}"
  find /usr/share/icons ~/.icons -maxdepth 1 -type d -printf "%f\n" 2>/dev/null | sort -u | grep -v '^$'

  echo -e "\n${YELLOW}Mevcut İmleç Temaları:${NC}"
  find /usr/share/icons ~/.icons -maxdepth 1 -type d -name "*cursor*" -printf "%f\n" 2>/dev/null | sort -u
}

# Tema varlığını kontrol et
check_theme_exists() {
  local theme_type=$1
  local theme_name=$2
  local found=0

  case $theme_type in
  "gtk-theme")
    [[ -d "/usr/share/themes/$theme_name" ]] || [[ -d "$HOME/.themes/$theme_name" ]] && found=1
    ;;
  "icon-theme")
    [[ -d "/usr/share/icons/$theme_name" ]] || [[ -d "$HOME/.icons/$theme_name" ]] && found=1
    ;;
  "cursor-theme")
    [[ -d "/usr/share/icons/$theme_name" ]] || [[ -d "$HOME/.icons/$theme_name" ]] && found=1
    ;;
  esac

  return $((1 - found))
}

# Font ve tema ayarlarını uygula
apply_settings() {
  local success=true

  echo -e "${BLUE}Tema ve font ayarları uygulanıyor...${NC}\n"

  # Tema ayarlarını uygula
  if check_theme_exists "gtk-theme" "${DEFAULT_SETTINGS["THEME"]}"; then
    $INTERFACE_SCHEMA gtk-theme "${DEFAULT_SETTINGS["THEME"]}" || success=false
  else
    echo -e "${RED}HATA: GTK teması '${DEFAULT_SETTINGS["THEME"]}' bulunamadı${NC}"
    success=false
  fi

  if check_theme_exists "icon-theme" "${DEFAULT_SETTINGS["ICONS"]}"; then
    $INTERFACE_SCHEMA icon-theme "${DEFAULT_SETTINGS["ICONS"]}" || success=false
  else
    echo -e "${RED}HATA: İkon teması '${DEFAULT_SETTINGS["ICONS"]}' bulunamadı${NC}"
    success=false
  fi

  if check_theme_exists "cursor-theme" "${DEFAULT_SETTINGS["CURSOR"]}"; then
    $INTERFACE_SCHEMA cursor-theme "${DEFAULT_SETTINGS["CURSOR"]}" || success=false
  else
    echo -e "${RED}HATA: İmleç teması '${DEFAULT_SETTINGS["CURSOR"]}' bulunamadı${NC}"
    success=false
  fi

  # Font ayarlarını uygula
  $INTERFACE_SCHEMA font-name "${DEFAULT_SETTINGS["FONT_INTERFACE"]}" || success=false
  $INTERFACE_SCHEMA document-font-name "${DEFAULT_SETTINGS["FONT_DOCUMENT"]}" || success=false
  $INTERFACE_SCHEMA monospace-font-name "${DEFAULT_SETTINGS["FONT_MONO"]}" || success=false
  $WM_SCHEMA titlebar-font "${DEFAULT_SETTINGS["FONT_TITLE"]}" || success=false

  # Diğer ayarları uygula
  $INTERFACE_SCHEMA text-scaling-factor "${DEFAULT_SETTINGS["SCALE"]}" || success=false
  $INTERFACE_SCHEMA color-scheme "${DEFAULT_SETTINGS["SCHEME"]}" || success=false

  # Font rendering ayarları
  $INTERFACE_SCHEMA font-antialiasing "rgba" || success=false
  $INTERFACE_SCHEMA font-hinting "slight" || success=false

  if $success; then
    echo -e "${GREEN}Tüm temalar ve font ayarları başarıyla uygulandı!${NC}"
    return 0
  else
    echo -e "${RED}Bazı ayarlar uygulanırken hata oluştu.${NC}"
    return 1
  fi
}

# Komut satırı argümanlarını işle
while [[ $# -gt 0 ]]; do
  case $1 in
  -t | --theme)
    DEFAULT_SETTINGS["THEME"]="$2"
    shift 2
    ;;
  -i | --icons)
    DEFAULT_SETTINGS["ICONS"]="$2"
    shift 2
    ;;
  -c | --cursor)
    DEFAULT_SETTINGS["CURSOR"]="$2"
    shift 2
    ;;
  --interface-font)
    DEFAULT_SETTINGS["FONT_INTERFACE"]="$2"
    shift 2
    ;;
  --document-font)
    DEFAULT_SETTINGS["FONT_DOCUMENT"]="$2"
    shift 2
    ;;
  --mono-font)
    DEFAULT_SETTINGS["FONT_MONO"]="$2"
    shift 2
    ;;
  --title-font)
    DEFAULT_SETTINGS["FONT_TITLE"]="$2"
    shift 2
    ;;
  -s | --scale)
    DEFAULT_SETTINGS["SCALE"]="$2"
    shift 2
    ;;
  --scheme)
    DEFAULT_SETTINGS["SCHEME"]="$2"
    shift 2
    ;;
  -h | --help)
    show_help
    exit 0
    ;;
  -l | --list)
    list_available_themes
    exit 0
    ;;
  -f | --show-fonts)
    show_current_settings
    exit 0
    ;;
  *)
    echo -e "${RED}Geçersiz seçenek: $1${NC}"
    show_help
    exit 1
    ;;
  esac
done

# Ana fonksiyonu çalıştır
apply_settings

# Mevcut ayarları göster
echo -e "\n${BLUE}Güncel ayarlar:${NC}"
show_current_settings
