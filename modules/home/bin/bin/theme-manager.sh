#!/usr/bin/env bash

#=============================================================================
# theme-manager.sh - Unified Theme Manager for Terminal Applications
#=============================================================================
#
# Version: 1.0.0
# Author: Kenan
# Repository: github.com/kenany/dotfiles
#
# Description:
#   Merkezi tema yönetim aracı. Alacritty, Kitty, Tmux ve Waybar için tema
#   geçişlerini tek bir noktadan yönetir. Her uygulama için ayrı tema
#   seçilebilir veya tüm uygulamalara aynı anda tema uygulanabilir.
#
# Features:
#   - Alacritty terminal teması yönetimi
#   - Kitty terminal teması yönetimi
#   - Tmux teması yönetimi
#   - Waybar teması yönetimi
#   - Tokyo Night, Dracula, Mocha, Kenp ve diğer temalar
#   - Tek komutla tüm uygulamalara tema uygulama
#   - Tema değişiminde otomatik bildirim
#   - Tema geçiş ve backup desteği
#
# Dependencies:
#   - theme-alacritty.sh
#   - theme-kitty.sh
#   - theme-tmux.sh
#   - theme-waybar.sh
#   - notify-send (bildirimler için)
#
# Usage Examples:
#   ./theme-manager.sh -l                 # Tüm temaları listele
#   ./theme-manager.sh -a tokyo          # Tüm uygulamalara Tokyo temasını uygula
#   ./theme-manager.sh kitty dracula     # Sadece Kitty'ye Dracula temasını uygula
#   ./theme-manager.sh tmux -t           # Tmux'ta sonraki temaya geç
#
#=============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Renk tanımlamaları
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Desteklenen uygulamalar ve ilgili scriptleri
declare -A APP_SCRIPTS=(
  ["alacritty"]="theme-alacritty.sh"
  ["kitty"]="theme-kitty.sh"
  ["tmux"]="theme-tmux.sh"
  ["waybar"]="theme-waybar.sh"
)

# Yardım mesajını göster
show_help() {
  cat <<EOF
Usage: $(basename "$0") [SEÇENEK] [UYGULAMA] [TEMA]

SEÇENEKLER:
    -l, --list      Temaları listele
    -t, --toggle    Sonraki temaya geç
    -c, --current   Mevcut temayı göster
    -h, --help      Bu yardım mesajını göster
    -a, --all       Tüm uygulamalara uygula

UYGULAMALAR:
    alacritty       Alacritty terminal
    kitty           Kitty terminal
    tmux            Tmux
    waybar          Waybar
    all             Tüm uygulamalar

TEMALAR:
    tokyo           Tokyo Night teması
    dracula         Dracula teması
    mocha           Catppuccin Mocha teması
    kenp            Kenp teması
    nord            Nord teması (mevcut ise)
    kanagawa        Kanagawa teması (mevcut ise)

ÖRNEKLER:
    $(basename "$0") alacritty tokyo    # Alacritty'ye Tokyo temasını uygula
    $(basename "$0") -t kitty           # Kitty'de sonraki temaya geç
    $(basename "$0") -l                 # Tüm temaları listele
    $(basename "$0") -a dracula         # Tüm uygulamalara Dracula temasını uygula
    $(basename "$0") -c tmux            # Tmux'un mevcut temasını göster
EOF
}

# Tüm uygulamaların mevcut temalarını göster
show_all_current() {
  for app in "${!APP_SCRIPTS[@]}"; do
    echo -e "${BLUE}=== $app mevcut tema ===${NC}"
    apply_theme "$app" "-c"
  done
}

# Tema uygulamak için yardımcı fonksiyon
apply_theme() {
  local app=$1
  shift
  local args=("$@")
  local script="${APP_SCRIPTS[$app]}"

  if [[ -f "$SCRIPT_DIR/$script" ]]; then
    if [[ "${args[0]}" == "-c" ]]; then
      # Mevcut tema gösterimi için özel durum
      "$SCRIPT_DIR/$script" "-c"
    elif [[ "${args[0]}" == "-l" ]]; then
      # Tema listesi gösterimi için özel durum
      "$SCRIPT_DIR/$script" "-l"
    else
      # Tema uygulama ve diğer komutlar için
      "$SCRIPT_DIR/$script" "${args[@]}"
      # Waybar için özel bildirim
      if [[ "$app" == "waybar" && -n "${args[0]}" && "${args[0]}" != "-t" ]]; then
        notify-send "Waybar Theme" "Switched to ${args[0]} theme"
      fi
    fi
  else
    echo -e "${RED}Hata: '$app' için tema scripti bulunamadı${NC}"
    return 1
  fi
}

# Tüm uygulamaların temalarını listele
list_all_themes() {
  for app in "${!APP_SCRIPTS[@]}"; do
    echo -e "\n${BLUE}=== $app temaları ===${NC}"
    apply_theme "$app" "-l"
  done
}

# Tüm uygulamalara tema uygula
apply_all() {
  local theme=$1
  local success=true

  for app in "${!APP_SCRIPTS[@]}"; do
    echo -e "${BLUE}$app için tema uygulanıyor...${NC}"
    if ! apply_theme "$app" "$theme"; then
      success=false
    fi
  done

  $success
}

# Ana mantık
main() {
  # Parametre yoksa yardım göster
  if [[ $# -eq 0 ]]; then
    show_help
    exit 0
  fi

  local command=""
  local app=""
  local theme=""

  # İlk parametreyi kontrol et
  case "$1" in
  # Genel seçenekler
  -h | --help)
    show_help
    exit 0
    ;;
  -l | --list)
    list_all_themes
    exit 0
    ;;
  -t | --toggle)
    apply_all "-t"
    exit 0
    ;;
  -c | --current)
    show_all_current
    exit 0
    ;;
  -a | --all)
    shift
    if [[ $# -eq 0 ]]; then
      echo -e "${RED}Hata: Tema belirtilmedi${NC}"
      exit 1
    fi
    apply_all "$1"
    exit 0
    ;;
  *)
    # Uygulama adı ve sonraki parametreler
    app="$1"
    shift
    if [[ -n "$1" ]]; then
      command="$1"
      shift
      if [[ -n "$1" ]]; then
        theme="$1"
      fi
    fi
    ;;
  esac

  # Eğer uygulama belirtildiyse
  if [[ -n "$app" ]]; then
    if [[ "$app" == "all" ]]; then
      if [[ -n "$theme" ]]; then
        apply_all "$theme"
      else
        apply_all "$command"
      fi
    elif [[ -n "${APP_SCRIPTS[$app]}" ]]; then
      if [[ -n "$theme" ]]; then
        apply_theme "$app" "$command" "$theme"
      else
        apply_theme "$app" "$command"
      fi
    else
      echo -e "${RED}Hata: Geçersiz uygulama '$app'${NC}"
      echo "Desteklenen uygulamalar: ${!APP_SCRIPTS[*]} all"
      exit 1
    fi
  fi
}

# Scripti çalıştır
main "$@"
