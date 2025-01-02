#!/usr/bin/env bash

#=============================================================================
# theme-waybar.sh - Waybar Theme Manager
#=============================================================================
#
# Version: 1.0.0
# Author: Kenan
# Repository: github.com/kenany/dotfiles
#
# Description:
#   Waybar için tema yönetim scripti. Önceden tanımlanmış temalar arasında
#   geçiş yapmanızı ve mevcut temaları yönetmenizi sağlar. Theme Manager
#   (theme-manager.sh) ile entegre çalışmak üzere tasarlanmıştır.
#
# Features:
#   - Tema listeleme
#   - Tema değiştirme
#   - Otomatik tema geçişi
#   - Mevcut tema gösterimi
#   - Tema yedekleme
#   - Sistem bildirimleri
#   - Waybar otomatik yenileme
#
# Dependencies:
#   - waybar
#   - systemctl (waybar servisini yeniden başlatmak için)
#   - notify-send (bildirimler için)
#
# Usage Examples:
#   ./theme-waybar.sh -l                # Temaları listele
#   ./theme-waybar.sh mocha            # Mocha temasına geç
#   ./theme-waybar.sh -t               # Sonraki temaya geç
#   ./theme-waybar.sh -c               # Mevcut temayı göster
#
# Notes:
#   - Theme Manager ile kullanıldığında otomatik olarak çalışır
#   - Tema değişikliklerinde waybar otomatik olarak yeniden başlatılır
#   - Tüm temalar ~/.config/waybar/themes/ dizininde bulunmalıdır
#
#=============================================================================
WAYBAR_DIR="$HOME/.config/waybar"
THEMES_DIR="$WAYBAR_DIR/themes"
THEME_MARKER="# Current theme: "

# Renk tanımlamaları
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Mevcut temayı al
get_current_theme() {
  if [ -L "$WAYBAR_DIR/style.css" ]; then
    basename "$(readlink -f "$WAYBAR_DIR/style.css")" .css
  else
    echo "default"
  fi
}

# Temaları listele
list_themes() {
  echo -e "${BLUE}Available themes:${NC}"
  current=$(get_current_theme)

  for theme in "$THEMES_DIR"/*.css; do
    if [[ -f "$theme" ]]; then
      theme_name=$(basename "$theme" .css)
      if [ "$theme_name" = "$current" ]; then
        echo -e "  ${GREEN}* $theme_name ${YELLOW}(current)${NC}"
      else
        echo "    $theme_name"
      fi
    fi
  done
}

# Bildirim göster
notify() {
  local theme=$1
  local message="Switched to $theme theme"

  echo -e "${GREEN}Waybar theme switched to ${theme}${NC}"
  notify-send "Waybar Theme" "$message" --icon=preferences-desktop-theme
}

# Tema uygula
apply_theme() {
  local theme=$1

  # Validate theme
  if [[ ! -f "$THEMES_DIR/$theme.css" ]]; then
    echo -e "${RED}Error: Theme '$theme' not found${NC}"
    echo "Available themes:"
    list_themes
    return 1
  fi

  # Backup current theme if it's not a symlink
  if [ ! -L "$WAYBAR_DIR/style.css" ]; then
    mv "$WAYBAR_DIR/style.css" "$WAYBAR_DIR/style.css.backup"
  fi

  # Create symlink to theme file
  ln -sf "$THEMES_DIR/$theme.css" "$WAYBAR_DIR/style.css"

  # Restart waybar
  systemctl --user restart waybar.service

  notify "$theme"
}

# Tema geçişi yap
toggle_theme() {
  themes=(mocha tokyo dracula rosepin)
  current=$(get_current_theme)
  local next_theme=""
  local found=0

  # Find next theme
  for theme in "${themes[@]}"; do
    if [ $found -eq 1 ]; then
      next_theme=$theme
      break
    fi
    if [ "$theme" = "$current" ]; then
      found=1
    fi
  done

  # If we're at the last theme or theme not found, go back to first
  if [ -z "$next_theme" ]; then
    next_theme="${themes[0]}"
  fi

  apply_theme "$next_theme"
}

# Yardım mesajını göster
show_help() {
  echo "Usage: $(basename "$0") [OPTION] [THEME]"
  echo
  echo "Options:"
  echo "  -l, --list     List available themes"
  echo "  -t, --toggle   Toggle to next theme"
  echo "  -h, --help     Show this help message"
  echo "  -c, --current  Show current theme"
  echo
  echo "Available themes:"
  list_themes
  echo
  echo "Examples:"
  echo "  $(basename "$0") -t          # Toggle to next theme"
  echo "  $(basename "$0") mocha      # Switch to Mocha theme"
  echo "  $(basename "$0") -l          # List all themes"
}

# Ana mantık
if [ $# -eq 0 ]; then
  show_help
  exit 0
fi

case "$1" in
"-t" | "--toggle")
  toggle_theme
  ;;
"-l" | "--list")
  list_themes
  ;;
"-h" | "--help")
  show_help
  ;;
"-c" | "--current")
  echo -e "Current theme: ${GREEN}$(get_current_theme)${NC}"
  ;;
*)
  apply_theme "$1"
  ;;
esac
