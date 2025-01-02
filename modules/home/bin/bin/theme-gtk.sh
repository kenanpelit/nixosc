#!/usr/bin/env bash

#=============================================================================
# theme-gtk.sh - GTK Theme Manager
#=============================================================================
#
# Version: 1.0.0
# Author: Kenan Pelit
# Repository: github.com/kenanpelit/dotfiles
#
# Description:
#   GTK ve GNOME masaüstü ortamı için kapsamlı tema yönetim aracı.
#   Tema, ikon, imleç ve font ayarlarını tek bir noktadan yönetir.
#
#=============================================================================

# Dizin yapılandırması
CONFIG_DIR="$HOME/.config"
GTK3_DIR="$CONFIG_DIR/gtk-3.0"
GTK4_DIR="$CONFIG_DIR/gtk-4.0"

# GSettings şeması
SCHEMA="gsettings set org.gnome.desktop.interface"

# Renk tanımlamaları
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Varsayılan ayarlar
declare -A DEFAULT_SETTINGS=(
  ["THEME"]="Arc-Dark"
  ["ICONS"]="a-candy-beauty-icon-theme"
  ["FONT"]="Hack Nerd Font 11"
  ["CURSOR"]="Catppuccin-Mocha-Dark-Cursors"
  ["SCALE"]="1.0"
  ["SCHEME"]="prefer-dark"
)

# Yardım mesajını göster
show_help() {
  cat <<EOF
Kullanım: $(basename "$0") [SEÇENEK] [DEĞER]

Seçenekler:
    -t, --theme    GTK teması (varsayılan: ${DEFAULT_SETTINGS["THEME"]})
    -i, --icons    İkon teması (varsayılan: ${DEFAULT_SETTINGS["ICONS"]})
    -f, --font     Sistem fontu (varsayılan: ${DEFAULT_SETTINGS["FONT"]})
    -c, --cursor   İmleç teması (varsayılan: ${DEFAULT_SETTINGS["CURSOR"]})
    -s, --scale    Metin ölçeği (varsayılan: ${DEFAULT_SETTINGS["SCALE"]})
    --scheme       Renk şeması (varsayılan: ${DEFAULT_SETTINGS["SCHEME"]})
    -l, --list     Mevcut temaları listele
    --current      Mevcut ayarları göster
    --default      Varsayılan ayarları uygula
    -h, --help     Bu yardım mesajını göster

Örnekler:
    $(basename "$0") -t Adwaita-dark    # GTK temasını değiştir
    $(basename "$0") -i Papirus         # İkon temasını değiştir
    $(basename "$0") --default          # Varsayılan ayarları uygula
    $(basename "$0") --current          # Mevcut ayarları göster
EOF
}

# Mevcut ayarları göster
show_current_settings() {
  echo -e "${BLUE}=== Mevcut GTK Ayarları ===${NC}\n"
  echo -e "${GREEN}Tema Ayarları:${NC}"
  echo "• GTK Teması: $(gsettings get org.gnome.desktop.interface gtk-theme)"
  echo "• İkon Teması: $(gsettings get org.gnome.desktop.interface icon-theme)"
  echo "• İmleç Teması: $(gsettings get org.gnome.desktop.interface cursor-theme)"

  echo -e "\n${GREEN}Font Ayarları:${NC}"
  echo "• Sistem Fontu: $(gsettings get org.gnome.desktop.interface font-name)"
  echo "• Metin Ölçeği: $(gsettings get org.gnome.desktop.interface text-scaling-factor)"

  echo -e "\n${GREEN}Renk Şeması:${NC}"
  echo "• $(gsettings get org.gnome.desktop.interface color-scheme)"
}

# Mevcut temaları listele
list_themes() {
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

# GTK yapılandırma dosyalarını güncelle
update_gtk_config() {
  # Dizinleri oluştur
  mkdir -p "$GTK3_DIR" "$GTK4_DIR"

  # Ortak GTK ayarları
  local settings="[Settings]
gtk-theme-name=${DEFAULT_SETTINGS[THEME]}
gtk-application-prefer-dark-theme=1
gtk-icon-theme-name=${DEFAULT_SETTINGS[ICONS]}
gtk-font-name=${DEFAULT_SETTINGS[FONT]}
gtk-cursor-theme-name=${DEFAULT_SETTINGS[CURSOR]}
gtk-cursor-theme-size=24
gtk-decoration-layout=icon:minimize,maximize,close
gtk-enable-animations=true
gtk-primary-button-warps-slider=true
gtk-xft-antialias=1
gtk-xft-dpi=147456
gtk-xft-hinting=1
gtk-xft-hintstyle=hintslight
gtk-xft-rgba=rgb
gtk-overlay-scrolling=true"

  # GTK4'e özel modül ekleyerek yaz
  echo -e "$settings\ngtk-modules=colorreload-gtk-module" >"$GTK4_DIR/settings.ini"

  # GTK3'e sadece ortak ayarları yaz
  echo "$settings" >"$GTK3_DIR/settings.ini"
}

# Ayarları uygula
apply_settings() {
  local success=true

  # GTK yapılandırma dosyalarını güncelle
  update_gtk_config

  # GSettings ile sistem ayarlarını güncelle
  if command -v gsettings &>/dev/null; then
    if check_theme_exists "gtk-theme" "${DEFAULT_SETTINGS["THEME"]}"; then
      $SCHEMA gtk-theme "${DEFAULT_SETTINGS["THEME"]}" || success=false
    else
      echo -e "${RED}HATA: GTK teması '${DEFAULT_SETTINGS["THEME"]}' bulunamadı${NC}"
      success=false
    fi

    if check_theme_exists "icon-theme" "${DEFAULT_SETTINGS["ICONS"]}"; then
      $SCHEMA icon-theme "${DEFAULT_SETTINGS["ICONS"]}" || success=false
    else
      echo -e "${RED}HATA: İkon teması '${DEFAULT_SETTINGS["ICONS"]}' bulunamadı${NC}"
      success=false
    fi

    if check_theme_exists "cursor-theme" "${DEFAULT_SETTINGS["CURSOR"]}"; then
      $SCHEMA cursor-theme "${DEFAULT_SETTINGS["CURSOR"]}" || success=false
    else
      echo -e "${RED}HATA: İmleç teması '${DEFAULT_SETTINGS["CURSOR"]}' bulunamadı${NC}"
      success=false
    fi

    $SCHEMA font-name "${DEFAULT_SETTINGS["FONT"]}" || success=false
    $SCHEMA text-scaling-factor "${DEFAULT_SETTINGS["SCALE"]}" || success=false
    $SCHEMA color-scheme "${DEFAULT_SETTINGS["SCHEME"]}" || success=false
  else
    echo -e "${RED}HATA: gsettings bulunamadı. GNOME ayarları güncellenemedi.${NC}"
    success=false
  fi

  if $success; then
    echo -e "${GREEN}GTK ayarları başarıyla güncellendi!${NC}"
    return 0
  else
    echo -e "${RED}Bazı ayarlar uygulanırken hata oluştu.${NC}"
    return 1
  fi
}

# Ana mantık
if [ $# -eq 0 ]; then
  show_help
  exit 0
fi

# Parametreleri işle
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
  -f | --font)
    DEFAULT_SETTINGS["FONT"]="$2"
    shift 2
    ;;
  -c | --cursor)
    DEFAULT_SETTINGS["CURSOR"]="$2"
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
  -l | --list)
    list_themes
    exit 0
    ;;
  --current)
    show_current_settings
    exit 0
    ;;
  --default)
    echo -e "${GREEN}Varsayılan ayarlar uygulanıyor...${NC}"
    apply_settings
    exit 0
    ;;
  -h | --help)
    show_help
    exit 0
    ;;
  *)
    echo -e "${RED}Geçersiz seçenek: $1${NC}"
    show_help
    exit 1
    ;;
  esac
done

# Ayarları uygula
apply_settings
