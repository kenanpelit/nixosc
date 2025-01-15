#!/usr/bin/env bash

###############################################################################
# Script Name  : retry-rsync.sh
# Description : Otomatik yeniden deneme özellikli rsync yedekleme betiği.
#               Hata durumunda belirtilen sayıda yeniden deneme yapar.
#               Her deneme arasında belirlenen süre kadar bekler.
#               Kesintiye uğrayan transferleri kaldığı yerden devam ettirir.
#
# Usage       : ./retry-rsync.sh [-h] kaynak hedef
# Arguments   : kaynak    - Yedeklenecek kaynak dizin/dosya
#               hedef     - Hedef dizin/dosya
#
# Options     : -h        - Bu yardım mesajını gösterir
#
# Features    : - Maksimum 50 yeniden deneme
#               - Denemeler arası 5 saniye bekleme
#               - Yarım kalan transferleri devam ettirme (--partial)
#               - İlerleme göstergesi (-P)
#               - Sıkıştırma (-z)
#               - Ayrıntılı mod (-v)
#               - İstatistik gösterimi (--stats)
#
# Rsync Flags : -a : Arşiv modu (izinleri ve zaman damgalarını korur)
#               -v : Ayrıntılı çıktı
#               -z : Sıkıştırma
#               -h : İnsan okunabilir format
#               -P : İlerleme göstergesi
#               -r : Alt dizinleri tekrarlı kopyala
#
# Exit Codes  : 0 - Başarılı
#               1 - Hata (max deneme sayısına ulaşıldı/kesinti)
#
# Author      : Kenan Pelit
# Date        : 2024
###############################################################################

# Help function
show_help() {
  echo "Kullanım: $0 [-h] kaynak hedef"
  echo "Hata durumunda otomatik yeniden deneme yapan rsync betiği"
  echo ""
  echo "Seçenekler:"
  echo "  -h    Bu yardım mesajını göster"
  echo ""
  echo "Parametreler:"
  echo "  kaynak       Yedeklenecek kaynak dizin/dosya"
  echo "  hedef        Hedef dizin/dosya"
  echo ""
  echo "Özellikler:"
  echo "  - Maksimum $MAX_RETRIES yeniden deneme"
  echo "  - Denemeler arası $RETRY_DELAY saniye bekleme"
  echo "  - Yarım kalan transferleri devam ettirme"
  echo "  - İlerleme göstergesi ve sıkıştırma"
}

# Parse arguments
while getopts "h" opt; do
  case $opt in
  h)
    show_help
    exit 0
    ;;
  \?)
    echo "Geçersiz seçenek: -$OPTARG" >&2
    exit 1
    ;;
  esac
done

# Validate required arguments
shift $((OPTIND - 1))
if [ $# -ne 2 ]; then
  echo "Hata: Kaynak ve hedef parametreleri gerekli"
  show_help
  exit 1
fi

# Configuration
MAX_RETRIES=50
RETRY_DELAY=5 # Seconds between retries

# Trap interrupts
trap "echo 'Betik kesintiye uğradı, çıkılıyor...'; exit 1;" SIGINT SIGTERM

# Main rsync loop
i=0
false # Set initial return value to failure
while [ $? -ne 0 ] && [ $i -lt $MAX_RETRIES ]; do
  i=$((i + 1))
  echo "Deneme $i / $MAX_RETRIES"
  rsync -avzhPr \
    --stats \
    --partial \
    --append \
    --append-verify \
    "$1" "$2"
  if [ $? -ne 0 ] && [ $i -lt $MAX_RETRIES ]; then
    echo "$RETRY_DELAY saniye içinde yeniden denenecek..."
    sleep $RETRY_DELAY
  fi
done

# Check final status
if [ $i -eq $MAX_RETRIES ]; then
  echo "$MAX_RETRIES deneme sonrası başarısız oldu"
  exit 1
else
  echo "Senkronizasyon $i deneme sonrası başarıyla tamamlandı"
  exit 0
fi
