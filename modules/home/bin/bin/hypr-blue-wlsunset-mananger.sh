#!/usr/bin/env bash

#######################################
#
# Version: 1.0.0
# Date: 2024-12-08
# Author: Kenan Pelit
# Repository: github.com/kenanpelit/dotfiles
# Description: HyprFlow
#
# License: MIT
#
#######################################

# Farklı wlsunset profilleri
TOGGLE_FILE="/tmp/.wlsunset_active"
CURRENT_PROFILE_FILE="/tmp/.wlsunset_profile"

# Varsayılan profil
DEFAULT="-S 00:01 -s 00:00 -d 4000 -g 1"
# Gece profili
NIGHT="-S 00:01 -s 00:00 -d 3500 -g 0.9"
# Akşam profili
EVENING="-S 00:01 -s 00:00 -d 4000 -g 0.95"
# Kod yazma profili
CODING="-S 00:01 -s 00:00 -d 5000 -g 1"

# Help fonksiyonu
show_help() {
  echo "Kullanım: $(basename "$0") [seçenek]"
  echo ""
  echo "Seçenekler:"
  echo "  default  - Varsayılan mod (4000K, %100 parlaklık)"
  echo "  night    - Gece modu (3500K, %90 parlaklık)"
  echo "  evening  - Akşam modu (4000K, %95 parlaklık)"
  echo "  coding   - Kod yazma modu (5000K, %100 parlaklık)"
  echo "  help     - Bu yardım mesajını gösterir"
  exit 0
}

# Eğer parametre yoksa help göster
if [ -z "$1" ]; then
  show_help
fi

# Profil seçimi
case "$1" in
"help" | "-h" | "--help") show_help ;;
"default") PROFILE="$DEFAULT" && PROFILE_NAME="Varsayılan Mod" ;;
"night") PROFILE="$NIGHT" && PROFILE_NAME="Gece Modu" ;;
"evening") PROFILE="$EVENING" && PROFILE_NAME="Akşam Modu" ;;
"coding") PROFILE="$CODING" && PROFILE_NAME="Kod Yazma Modu" ;;
*) show_help ;; # Geçersiz parametre durumunda da help göster
esac

# wlsunset'in aktif olup olmadığını kontrol et
if [ -f "$TOGGLE_FILE" ]; then
  # Eğer aktifse kapat
  pkill wlsunset
  rm -f "$TOGGLE_FILE"
  rm -f "$CURRENT_PROFILE_FILE"
  notify-send -t 1000 -u low "Wlsunset Kapatıldı" "Filtre devre dışı"
else
  # Eğer aktif değilse başlat
  pkill wlsunset 2>/dev/null
  sleep 0.5
  wlsunset $PROFILE &
  echo "$PROFILE_NAME" >"$CURRENT_PROFILE_FILE"
  touch "$TOGGLE_FILE"
  notify-send -t 1000 -u low "Wlsunset Açıldı" "$PROFILE_NAME aktif"
fi
