#!/usr/bin/env bash

#######################################
# tsms.sh - Content Search Script
#
# Version: 1.0.0
# Date: 2024-12-19
# Author: Kenan Pelit
# Repository: github.com/kenanpelit/dotfiles
#
# - pirate-get https://github.com/vikstrous/pirate-get
#######################################

# Transmission config'den bilgileri oku
get_transmission_settings() {
  CONFIG_FILE="$HOME/.config/transmission-daemon/settings.json"
  if [ -f "$CONFIG_FILE" ]; then
    PORT=$(grep -o '"rpc-port": [0-9]*' "$CONFIG_FILE" | awk '{print $2}')
    HOST="localhost" # localhost kullan çünkü bağlantı yerel

    # Pass'dan auth bilgilerini al
    USER=$(pass tsm-user 2>/dev/null || echo "admin")
    PASS=$(pass tsm-pass 2>/dev/null)
  else
    PORT=9091
    HOST="localhost"
    USER=$(pass tsm-user 2>/dev/null || echo "admin")
    PASS=$(pass tsm-pass 2>/dev/null)
  fi
}

# Config'den ayarları al
get_transmission_settings

RECENT=false

# Transmission kontrolü
check_transmission() {
  if ! transmission-remote "$HOST:$PORT" --auth "$USER:$PASS" -l >/dev/null 2>&1; then
    echo "Transmission bağlantısı kontrol ediliyor..."
    systemctl --user start transmission
    sleep 2
  fi
}

# Kullanım bilgisi
usage() {
  echo "Kullanım: $0 [-R] arama_terimi"
  echo "Seçenekler:"
  echo "  -R          Son 48 saat içindeki içerikleri ara"
  echo "  -H, --help  Bu yardım mesajını göster"
  exit 1
}

# Transmission'ı kontrol et
check_transmission

# Parametreleri işle
while getopts "RH-:" opt; do
  case $opt in
  R) RECENT=true ;;
  H) usage ;;
  -) case "${OPTARG}" in
    help) usage ;;
    *)
      echo "Geçersiz seçenek: --${OPTARG}" >&2
      exit 1
      ;;
    esac ;;
  ?)
    echo "Geçersiz seçenek: -$OPTARG" >&2
    exit 1
    ;;
  esac
done

# Zorunlu argümanları kontrol et
shift $((OPTIND - 1))
if [ $# -eq 0 ]; then
  echo "Hata: Arama terimi gerekli"
  usage
fi

# Recent flag ekle
RECENT_FLAG=""
if [ "$RECENT" = true ]; then
  RECENT_FLAG="-R"
fi

# Auth bilgilerini ekleyerek komutu oluştur
AUTH="-A $USER:$PASS"
CMD="pirate-get -t -E $HOST:$PORT $AUTH $RECENT_FLAG \"$*\""
echo "Çalıştırılan komut: $CMD"
eval $CMD
