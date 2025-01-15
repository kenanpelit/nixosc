#!/usr/bin/env bash

# Renk tanımlamaları
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # Renk sıfırlama
BOLD='\033[1m'

# Varsayılan yenileme süresi (saniye)
REFRESH_RATE=10

# Yardım mesajı
show_help() {
  echo "Kullanım: $0 [SEÇENEKLER]"
  echo "Seçenekler:"
  echo "  -r, --refresh SÜRE    Yenileme süresi (saniye), varsayılan: 10"
  echo "  -h, --help            Bu yardım mesajını göster"
  echo
  echo "Örnek:"
  echo "  $0 -r 5              # 5 saniyede bir yenile"
  exit 0
}

# Parametre kontrolü
while [[ $# -gt 0 ]]; do
  case $1 in
  -r | --refresh)
    if [[ $2 =~ ^[0-9]+$ ]]; then
      REFRESH_RATE=$2
      shift 2
    else
      echo "Hata: Geçersiz yenileme süresi: $2"
      echo "Yenileme süresi pozitif bir tam sayı olmalıdır."
      exit 1
    fi
    ;;
  -h | --help)
    show_help
    ;;
  *)
    echo "Hata: Geçersiz parametre: $1"
    echo "Yardım için: $0 --help"
    exit 1
    ;;
  esac
done

# Hangi komutun mevcut olduğunu kontrol et
if command -v incus >/dev/null 2>&1; then
  CMD="incus"
  TITLE="INCUS KONTEYNER MONİTÖRÜ"
elif command -v lxc >/dev/null 2>&1; then
  CMD="lxc"
  TITLE="LXD KONTEYNER MONİTÖRÜ"
else
  echo "Hata: Ne incus ne de lxc komutu bulunamadı!"
  exit 1
fi

# Terminal genişliğini al
TERM_WIDTH=$(tput cols)

print_header() {
  printf "\n${BOLD}%s${NC}\n" "$1"
  printf "%${TERM_WIDTH}s\n" | tr " " "-"
}

print_container_info() {
  local total=$($CMD list -f csv | wc -l)
  local running=$($CMD list | grep RUNNING | wc -l)
  local stopped=$($CMD list | grep STOPPED | wc -l)

  printf "${BOLD}TOPLAM: ${NC}%-3s ${GREEN}ÇALIŞAN: ${NC}%-3s ${RED}DURDURULAN: ${NC}%-3s ${BOLD}YENİLEME: ${NC}%-3s saniye\n" \
    "$total" "$running" "$stopped" "$REFRESH_RATE"
}

format_status() {
  local status="$1"
  case $status in
  "RUNNING")
    echo -e "${GREEN}$status${NC}"
    ;;
  "STOPPED")
    echo -e "${RED}$status${NC}"
    ;;
  *)
    echo -e "${YELLOW}$status${NC}"
    ;;
  esac
}

format_ip() {
  local ip="$1"
  # IP adreslerini düzenle ve kırp
  if [ "$ip" == "N/A" ]; then
    echo "N/A"
  else
    # IP adreslerini ayır ve formatla
    echo "$ip" | tr -d '"' | cut -c1-35 | sed 's/$/.../'
  fi
}

monitor_containers() {
  while true; do
    clear
    print_header "$TITLE"
    print_container_info
    printf "\n"

    printf "${BOLD}%-10s %-10s %-20s %-20s %-15s %-10s %-8s %-10s${NC}\n" \
      "KONTEYNER" "DURUM" "IPv4-1" "IPv4-2" "BELLEK" "DİSK" "PID" "TÜR"
    printf "%${TERM_WIDTH}s\n" | tr " " "-"

    $CMD list -c n,s,4,m,D,p,t -f csv | while IFS=',' read -r name status ipv4 memory disk pid type; do
      status=$(format_status "$status")

      # Test ederek IP'leri parse et
      echo "$ipv4" | while IFS= read -r line; do
        if [[ $line =~ ([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)[[:space:]]*\((eth0|tun0|ppp0)\) ]]; then
          ip1="${BASH_REMATCH[1]}"
        fi
        if [[ $line =~ ([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)[[:space:]]*\((ppp0|tun0)\) ]]; then
          ip2="${BASH_REMATCH[1]}"
        fi
      done

      # Tek IP varsa onu göster
      if [[ ! $ipv4 =~ \((ppp0|tun0)\) ]]; then
        ip1=$(echo "$ipv4" | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+' || echo "N/A")
        ip2="N/A"
      fi

      printf "%-10s %-20s %-20s %-20s %-15s %-10s %-8s %-10s\n" \
        "$name" \
        "$status" \
        "${ip1:-N/A}" \
        "${ip2:-N/A}" \
        "${memory:-N/A}" \
        "${disk:-N/A}" \
        "${pid:-N/A}" \
        "$type"
    done

    printf "\n${BOLD}Çıkış için Ctrl+C'ye basın${NC}\n"
    sleep $REFRESH_RATE
  done
}

# Trap CTRL+C
trap 'echo -e "\nKapatılıyor..."; exit 0' INT

# Script başlangıcı
monitor_containers
