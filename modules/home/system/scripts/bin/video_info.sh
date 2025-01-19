#!/usr/bin/env bash

# Renkler için
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Minimum çözünürlük değerleri
MIN_WIDTH=1920
MIN_HEIGHT=1080

# Kullanım kontrolü
if [ $# -eq 0 ]; then
  echo -e "${RED}Kullanım: $0 <video_dosyası veya dizin> [mod]${NC}"
  echo -e "Modlar:"
  echo -e "  -a: Otomatik mod (${MIN_WIDTH}x${MIN_HEIGHT} altındaki dosyaları otomatik siler)"
  echo -e "  -i: İnteraktif mod (her dosya için kullanıcıya sorar)"
  exit 1
fi

# Video analiz fonksiyonu
analyze_video() {
  local file="$1"
  local mode="$2"

  if [[ "$file" == *.mp4 ]]; then
    echo -e "${YELLOW}----------------------------------------"
    echo "Dosya: $file"
    echo -e "----------------------------------------${NC}"

    # Video bilgilerini al
    local video_info=$(ffprobe -v error -select_streams v:0 \
      -show_entries stream=width,height,r_frame_rate,bit_rate,duration \
      -of csv=p=0 "$file")

    # CSV formatındaki çıktıyı parçala
    IFS=',' read -r width height frame_rate bit_rate duration <<<"$video_info"

    # FPS değerini hesapla
    local fps
    if [[ $frame_rate == *"/"* ]]; then
      local num=$(echo $frame_rate | cut -d'/' -f1)
      local den=$(echo $frame_rate | cut -d'/' -f2)
      fps=$(echo "scale=2; $num / $den" | bc)
    else
      fps=$frame_rate
    fi

    # Bit hızını KB/s'ye çevir
    local bitrate_kb
    if [ ! -z "$bit_rate" ]; then
      bitrate_kb=$(echo "scale=0; $bit_rate / 1000" | bc)
    else
      bitrate_kb="Bilinmiyor"
    fi

    # Bilgileri göster
    echo -e "${BLUE}Çözünürlük: ${width}x${height}${NC}"
    echo -e "${GREEN}Bit Hızı: ${bitrate_kb} kb/s"
    echo -e "FPS: ${fps}"
    echo -e "Süre: ${duration}${NC}"

    if [ "$mode" = "auto" ]; then
      # Otomatik mod - düşük çözünürlüklü dosyaları sil
      if [ "$width" -lt "$MIN_WIDTH" ] || [ "$height" -lt "$MIN_HEIGHT" ]; then
        echo -e "${RED}Düşük çözünürlük tespit edildi. Dosya siliniyor: $file${NC}"
        rm "$file"
      else
        echo -e "${GREEN}Yüksek çözünürlük. Dosya korunuyor: $file${NC}"
      fi
    else
      # İnteraktif mod - kullanıcıya sor
      echo -e "\nBu dosya için ne yapmak istersiniz?"
      echo "1) Sakla"
      echo "2) Sil"
      echo "3) Atla"
      echo "4) Çıkış"
      read -p "Seçiminiz (1/2/3/4): " choice

      case $choice in
      1) echo -e "${GREEN}Dosya saklandı: $file${NC}" ;;
      2)
        rm "$file"
        echo -e "${RED}Dosya silindi: $file${NC}"
        ;;
      3) echo -e "${YELLOW}Dosya atlandı: $file${NC}" ;;
      4)
        echo -e "${YELLOW}Program sonlandırılıyor...${NC}"
        exit 0
        ;;
      *) echo -e "${RED}Geçersiz seçim. Dosya atlanıyor.${NC}" ;;
      esac
    fi
    echo ""
  fi
}

# Mod seçimi
MODE="interactive"
if [ "$#" -gt 1 ]; then
  case "$2" in
  -a) MODE="auto" ;;
  -i) MODE="interactive" ;;
  *) echo -e "${RED}Geçersiz mod seçimi. Varsayılan (interaktif) mod kullanılıyor.${NC}" ;;
  esac
fi

# Ana işlem
if [ -f "$1" ]; then
  # Tek dosya işlemi
  analyze_video "$1" "$MODE"
elif [ -d "$1" ]; then
  if [ "$MODE" = "auto" ]; then
    echo -e "${RED}NOT: ${MIN_WIDTH}x${MIN_HEIGHT} altındaki tüm dosyalar silinecek!${NC}"
    echo -e "${GREEN}Devam etmek istiyor musunuz? (e/h)${NC}"
    read -p "Seçiminiz: " choice
    if [ "$choice" != "e" ] && [ "$choice" != "E" ]; then
      echo -e "${YELLOW}İşlem iptal edildi.${NC}"
      exit 0
    fi
  fi

  # Dizindeki tüm mp4'leri işle
  find "$1" -type f -name "*.mp4" | while read -r file; do
    analyze_video "$file" "$MODE"
  done
  echo -e "${GREEN}İşlem tamamlandı!${NC}"
else
  echo -e "${RED}Hata: '$1' geçerli bir dosya veya dizin değil.${NC}"
  exit 1
fi
