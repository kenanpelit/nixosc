#!/usr/bin/env bash

# Bellek Temizleme Scripti
# Özellikler:
# - RAM ve önbellek temizliği
# - Detaylı bellek kullanım raporu
# - Swap yönetimi
# - Renkli çıktılar ve gelişmiş hata yönetimi

# Renk tanımlamaları
GREEN=$'\033[0;32m'
RED=$'\033[0;31m'
BLUE=$'\033[0;34m'
NC=$'\033[0m'

# Hata yakalama
trap 'echo -e "\n${RED}Script sonlandırıldı!${NC}"; exit 1' SIGINT SIGTERM

# Yardım fonksiyonu
usage() {
  echo -e "${BLUE}Bellek Temizleme Scripti${NC}"
  echo -e "Kullanım: sudo $0"
  echo -e "\nBu script şunları yapar:"
  echo "- Önbellekli belleği temizler"
  echo "- RAM'i boşaltır"
  echo "- Swap belleği yeniden başlatır"
  exit 1
}

# Süper kullanıcı kontrolü
check_root() {
  if [ "$(id -u)" != "0" ]; then
    echo -e "${RED}Hata: Bu script root yetkileri gerektirir.${NC}"
    echo -e "Lütfen 'sudo $0' şeklinde çalıştırın."
    exit 1
  fi
}

# Bellek bilgilerini alma fonksiyonu
get_memory_info() {
  local meminfo="/proc/meminfo"
  if [ ! -f "$meminfo" ]; then
    echo -e "${RED}Hata: $meminfo dosyası bulunamadı!${NC}"
    exit 1
  fi

  local mem_free=$(grep MemFree "$meminfo" | awk '{print $2}')
  local mem_cached=$(grep "^Cached" "$meminfo" | awk '{print $2}')
  local mem_total=$(grep MemTotal "$meminfo" | awk '{print $2}')

  echo "scale=2; $mem_free/1024.0" | bc
  echo "scale=2; $mem_cached/1024.0" | bc
  echo "scale=2; $mem_total/1024.0" | bc
}

# Ana program
main() {
  # Root kontrolü
  check_root

  # Başlangıç bellek durumu
  read -r free_before cached_before total < <(get_memory_info)

  echo -e "\n${BLUE}Bellek Temizleme İşlemi Başlatılıyor...${NC}"
  echo -e "Toplam RAM: ${GREEN}${total}${NC} MiB"
  echo -e "Boş RAM: ${GREEN}${free_before}${NC} MiB"
  echo -e "Önbellekteki RAM: ${GREEN}${cached_before}${NC} MiB"

  # Dosya sistemi senkronizasyonu
  echo -e "\n${BLUE}Dosya sistemi senkronize ediliyor...${NC}"
  if ! sync; then
    echo -e "${RED}Hata: Dosya sistemi senkronizasyonu başarısız!${NC}"
    exit 1
  fi

  # Önbellek temizleme
  echo -e "\n${BLUE}Önbellek temizleniyor...${NC}"
  echo 3 >/proc/sys/vm/drop_caches
  if [ $? -ne 0 ]; then
    echo -e "${RED}Hata: Önbellek temizleme başarısız!${NC}"
    exit 1
  fi

  # Temizlik sonrası bellek durumu
  read -r free_after _ _ < <(get_memory_info)
  local freed_memory=$(echo "scale=2; $free_after - $free_before" | bc)

  # Swap yönetimi
  echo -e "\n${BLUE}Swap belleği yeniden başlatılıyor...${NC}"
  swapoff -a && swapon -a
  if [ $? -eq 0 ]; then
    echo -e "${GREEN}Swap belleği başarıyla yeniden başlatıldı.${NC}"
  else
    echo -e "${RED}Uyarı: Swap belleği yeniden başlatılamadı!${NC}"
  fi

  # Sonuç raporu
  echo -e "\n${BLUE}İşlem Özeti:${NC}"
  echo -e "Boşaltılan bellek: ${GREEN}${freed_memory}${NC} MiB"
  echo -e "Yeni boş RAM: ${GREEN}${free_after}${NC} MiB"
}

# Yardım parametresi kontrolü
if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
  usage
fi

# Ana programı çalıştır
main

exit 0
