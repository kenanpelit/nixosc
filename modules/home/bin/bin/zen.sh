#!/bin/bash
#######################################
#
# Version: 1.0.0
# Date: 2024-12-12
# Author: Kenan Pelit
# Repository: github.com/kenanpelit/dotfiles
# Description: ZenBrowserAdvanced - Gelişmiş Zen Browser Yönetim Aracı
#
# Bu script Zen Browser'ı gelişmiş özelliklerle yönetmek için tasarlanmıştır.
# Temel özellikleri:
#
# - Detaylı profil yönetimi
#   - Profil durumu kontrolü
#   - Oturum geri yükleme yapılandırması
#   - Özel/gizli mod desteği
#
# - Sekme yönetimi
#   - Açık sekmeleri listeleme
#   - Sekme açma/kapatma
#   - LZ4 formatında oturum verisi okuma
#
# - Loglama ve izleme
#   - Detaylı loglama sistemi
#   - Renkli terminal çıktıları
#   - Hata yakalama ve raporlama
#
# Dizin Yapısı:
# ~/.zen/: Ana dizin
#   - launcher.log: İşlem kayıtları
#   - [profil_adı]/: Profil dizinleri
#     - prefs.js: Profil tercihleri
#     - sessionstore-backups/: Oturum yedekleri
#
# Kullanım:
# ./zen-launcher [profil] [--private|--list]
#
# License: MIT
#
#######################################
# Sabit değişkenler
ZEN_DIR="$HOME/.zen"
LOG_FILE="$ZEN_DIR/launcher.log"

# Renk kodları
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Loglama fonksiyonu
log_action() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >>"$LOG_FILE"
}

# Profil kontrolü
check_profile() {
  local profile="$1"
  if [ -d "$ZEN_DIR/$profile" ]; then
    return 0
  else
    echo -e "${RED}Hata: '$profile' profili bulunamadı!${NC}"
    return 1
  fi
}

# Oturum geri yükleme ayarlarını yapılandır
configure_session_restore() {
  local profile_dir="$ZEN_DIR/$1"
  local prefs_file="$profile_dir/prefs.js"

  [ ! -f "$prefs_file" ] && touch "$prefs_file"

  local settings=(
    'user_pref("browser.startup.page", 3);'
    'user_pref("browser.sessionstore.resume_session_once", false);'
    'user_pref("browser.sessionstore.resume_from_crash", true);'
    'user_pref("browser.startup.couldRestoreSession.count", 1);'
  )

  for setting in "${settings[@]}"; do
    if ! grep -q "$setting" "$prefs_file"; then
      echo "$setting" >>"$prefs_file"
    fi
  done
}

# Profil başlatma
launch_profile() {
  local profile="$1"
  local private_mode="$2"
  echo -e "${GREEN}Profil başlatılıyor: ${NC}$profile"
  configure_session_restore "$profile"
  log_action "Profil başlatıldı: $profile"
  if [ "$private_mode" = "--private" ]; then
    zen-browser -P "$profile" --private-window &
  else
    zen-browser -P "$profile" --restore-session &
  fi
}

# Sekmeleri listele ve kullanıcıdan işlem seçmesini iste
list_tabs() {
  local profile="$1"
  local recovery_file="$ZEN_DIR/$profile/sessionstore-backups/recovery.jsonlz4"

  if [ ! -f "$recovery_file" ]; then
    echo -e "${RED}Açık sekme bulunamadı.${NC}"
    return 1
  fi

  # Açık sekmeleri listele
  local tabs
  tabs=$(lz4jsoncat "$recovery_file" | jq -r '.windows[].tabs[].entries[-1].url')

  if [ -z "$tabs" ]; then
    echo -e "${RED}Açık sekme bulunamadı.${NC}"
    return 1
  fi

  echo -e "${BLUE}Açık Sekmeler:${NC}"
  echo "$tabs" | nl

  # Kullanıcıdan seçim yapmasını iste
  echo -e "\n${YELLOW}Bir sekme numarası seçin veya kapatmak için 'k' yazın (örn. 3 veya k 3):${NC}"
  read -r action tab_number

  # Girdi kontrolü
  if [[ "$action" =~ ^k$ ]] && [[ "$tab_number" =~ ^[0-9]+$ ]]; then
    local tab_url
    tab_url=$(echo "$tabs" | sed -n "${tab_number}p")
    echo -e "${GREEN}Sekme kapatılıyor:${NC} $tab_url"
    # Buraya kapatma işlemi eklenebilir
    log_action "Sekme kapatıldı: $tab_url"
  elif [[ "$action" =~ ^[0-9]+$ ]]; then
    local tab_url
    tab_url=$(echo "$tabs" | sed -n "${action}p")
    echo -e "${GREEN}Sekme açılıyor:${NC} $tab_url"
    zen-browser "$tab_url" &
    log_action "Sekme açıldı: $tab_url"
  else
    echo -e "${RED}Geçersiz giriş!${NC}"
    return 1
  fi
}

# Profilleri listele ve seç
list_profiles() {
  echo -e "${BLUE}Mevcut Zen Browser Profilleri:${NC}\n"

  profiles=($(ls -d "$ZEN_DIR"/*/ | grep -v "Crash" | xargs -n 1 basename))

  for i in "${!profiles[@]}"; do
    echo -e "${GREEN}$((i + 1))${NC}) ${profiles[$i]}"
  done

  echo -e "\n${YELLOW}Profil numarasını girin (1-${#profiles[@]}):${NC}"
  read -r choice

  if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "${#profiles[@]}" ]; then
    selected_profile="${profiles[$((choice - 1))]}"
    launch_profile "$selected_profile"
  else
    echo -e "${RED}Geçersiz seçim!${NC}"
    exit 1
  fi
}

# Yardım mesajı
show_help() {
  echo -e "${BLUE}Kullanım:${NC}"
  echo -e "  $(basename "$0") [profil_ismi] [seçenek]"
  echo -e "\n${BLUE}Seçenekler:${NC}"
  echo -e "  --private       ${GREEN}Gizli modda başlat${NC}"
  echo -e "  --list            ${GREEN}Açık sekmeleri listele${NC}"
  echo -e "\n${BLUE}Örnekler:${NC}"
  echo -e "  $(basename "$0")          ${GREEN}# İnteraktif menü gösterir${NC}"
  echo -e "  $(basename "$0") Kenp     ${GREEN}# Kenp profilini başlatır${NC}"
  echo -e "  $(basename "$0") Kenp --private ${GREEN}# Kenp profilini gizli modda başlatır${NC}"
  echo -e "  $(basename "$0") Kenp --list ${GREEN}# Kenp profili için açık sekmeleri listeler${NC}"
  echo -e "\n${BLUE}Mevcut Profiller:${NC}"
  ls -d "$ZEN_DIR"/*/ | grep -v "Crash" | xargs -n 1 basename | sed 's/^/  /'
}

# Ana program
main() {
  if [ $# -ge 1 ]; then
    if [ "$2" = "--list" ]; then
      if check_profile "$1"; then
        list_tabs "$1"
      fi
    elif [ "$2" = "--private" ]; then
      if check_profile "$1"; then
        launch_profile "$1" "$2"
      fi
    elif [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
      show_help
      exit 0
    else
      if check_profile "$1"; then
        launch_profile "$1"
      else
        exit 1
      fi
    fi
  else
    list_profiles
  fi
}

# Scripti çalıştır
main "$@"
