#!/usr/bin/env bash

#######################################
#
# HyprFlow Service Manager
# Version: 1.0.0
# Date: 2024-12-14
# Original Author: Kenan Pelit
# Modified by: Claude
# Repository: github.com/kenanpelit/dotfiles
# Description: Hyprland servis yönetim aracı
#
# Bu script, Hyprland masaüstü ortamında çalışan çeşitli servisleri
# yönetmek için kullanılır. Desteklenen servisler:
#   - fusuma: Touchpad gesture control
#   - hyprshade: Shader ve efekt yönetimi
#   - hyprsunset: Gece modu kontrolü
#   - pypr: Python tabanlı pencere yönetimi
#   - waybar: Durum çubuğu
#
# Kullanım:
#   ./hyprflow.sh <komut> [servis_adı] [seçenekler]
#
# Komutlar:
#   start <servis>    : Belirtilen servisi başlatır
#   check <servis>    : Belirtilen servisi sürekli kontrol eder
#   restart <servis>  : Belirtilen servisi yeniden başlatır
#   status <servis>   : Servis durumunu gösterir
#   list             : Tüm desteklenen servisleri listeler
#   help             : Bu yardım mesajını gösterir
#
# Seçenekler:
#   --interval=<saniye> : Kontrol aralığı (varsayılan: 180 saniye)
#   --wait=<saniye>     : Başlangıç beklemesi (varsayılan: 1 saniye)
#
# Örnekler:
#   ./hyprflow.sh start waybar
#   ./hyprflow.sh check pypr --interval=300
#   ./hyprflow.sh restart hyprsunset --wait=2
#   ./hyprflow.sh status fusuma
#   ./hyprflow.sh list
#
# License: MIT
#
#######################################

# Varsayılan değerler
DEFAULT_INTERVAL=180
DEFAULT_WAIT=1

# Desteklenen servisler
SUPPORTED_SERVICES=("fusuma" "hyprshade" "hyprsunset" "pypr" "waybar")

# Renk kodları
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Yardım mesajını göster
show_help() {
  cat <<'EOF'
HyprFlow Service Manager

Kullanım:
    ./hyprflow.sh <komut> [servis_adı] [seçenekler]

Komutlar:
    start <servis>    : Belirtilen servisi başlatır
    check <servis>    : Belirtilen servisi sürekli kontrol eder
    restart <servis>  : Belirtilen servisi yeniden başlatır
    status <servis>   : Servis durumunu gösterir
    list             : Tüm desteklenen servisleri listeler
    help             : Bu yardım mesajını gösterir

Desteklenen Servisler:
    fusuma           : Touchpad gesture control
    hyprshade        : Shader ve efekt yönetimi
    hyprsunset       : Gece modu kontrolü
    pypr             : Python tabanlı pencere yönetimi
    waybar           : Durum çubuğu

Seçenekler:
    --interval=<saniye> : Kontrol aralığı (varsayılan: 180 saniye)
    --wait=<saniye>     : Başlangıç beklemesi (varsayılan: 1 saniye)

Örnekler:
    ./hyprflow.sh start waybar
    ./hyprflow.sh check pypr --interval=300
    ./hyprflow.sh restart hyprsunset --wait=2
    ./hyprflow.sh status fusuma
    ./hyprflow.sh list
EOF
}

# Hata mesajı göster
error() {
  echo -e "${RED}HATA: $1${NC}" >&2
  notify-send -u critical "HyprFlow" "$1"
  exit 1
}

# Bilgi mesajı göster
info() {
  echo -e "${GREEN}$1${NC}"
}

# Uyarı mesajı göster
warn() {
  echo -e "${YELLOW}UYARI: $1${NC}"
}

# Servisin var olup olmadığını kontrol et
service_exists() {
  local n="$1"
  if systemctl --user list-unit-files --type=service | grep -q "^$n.service"; then
    return 0
  else
    return 1
  fi
}

# Servisin aktif olup olmadığını kontrol et
service_active() {
  local n="$1"
  if systemctl --user is-active --quiet "$n.service"; then
    return 0
  else
    return 1
  fi
}

# Hyprland'in başlamasını bekle
wait_for_hyprland() {
  local wait_time="$1"
  while ! pgrep -x "Hyprland" >/dev/null; do
    sleep 1
  done
  sleep "$wait_time"
}

# Servisi başlat
start_service() {
  local service="$1"
  local wait_time="$2"

  wait_for_hyprland "$wait_time"

  if service_exists "$service"; then
    info "$service servisi başlatılıyor..."
    systemctl --user restart "$service.service"
  else
    error "$service servisi bulunamadı!"
  fi
}

# Servisi sürekli kontrol et
check_service() {
  local service="$1"
  local interval="$2"

  info "$service servisi $interval saniye aralıklarla kontrol edilecek..."

  while true; do
    if service_exists "$service"; then
      if ! service_active "$service"; then
        warn "$service servisi çalışmıyor, başlatılıyor..."
        systemctl --user start "$service"
      else
        info "$service servisi çalışıyor."
      fi
    else
      error "$service servisi bulunamadı!"
    fi
    sleep "$interval"
  done
}

# Servis durumunu göster
show_status() {
  local service="$1"

  if service_exists "$service"; then
    local status=$(systemctl --user is-enabled "$service.service" 2>/dev/null)
    local active=$(systemctl --user is-active "$service.service" 2>/dev/null)

    echo "Servis: $service"
    echo "Durum: $active"
    echo "Başlangıçta: $status"
    echo
    echo "Detaylı Bilgi:"
    systemctl --user status "$service.service"
  else
    error "$service servisi bulunamadı!"
  fi
}

# Desteklenen servisleri listele
list_services() {
  info "Desteklenen servisler:"
  for service in "${SUPPORTED_SERVICES[@]}"; do
    if service_exists "$service"; then
      if service_active "$service"; then
        echo -e "  ${GREEN}✓${NC} $service"
      else
        echo -e "  ${YELLOW}✗${NC} $service"
      fi
    else
      echo -e "  ${RED}✗${NC} $service (kurulu değil)"
    fi
  done
}

# Ana fonksiyon
main() {
  # Parametre kontrolü
  if [ $# -lt 1 ]; then
    show_help
    exit 1
  fi

  # Komut ve servis adını al
  local command="$1"
  shift

  # Varsayılan değerleri ayarla
  local interval=$DEFAULT_INTERVAL
  local wait=$DEFAULT_WAIT
  local service=""

  # Parametreleri işle
  while [ $# -gt 0 ]; do
    case "$1" in
    --interval=*)
      interval="${1#*=}"
      shift
      ;;
    --wait=*)
      wait="${1#*=}"
      shift
      ;;
    *)
      if [ -z "$service" ]; then
        service="$1"
      fi
      shift
      ;;
    esac
  done

  # Komutu işle
  case "$command" in
  start)
    [ -z "$service" ] && error "Servis adı belirtilmedi!"
    start_service "$service" "$wait"
    ;;
  check)
    [ -z "$service" ] && error "Servis adı belirtilmedi!"
    check_service "$service" "$interval"
    ;;
  restart)
    [ -z "$service" ] && error "Servis adı belirtilmedi!"
    systemctl --user restart "$service.service"
    ;;
  status)
    [ -z "$service" ] && error "Servis adı belirtilmedi!"
    show_status "$service"
    ;;
  list)
    list_services
    ;;
  help | --help | -h)
    show_help
    ;;
  *)
    error "Geçersiz komut: $command"
    ;;
  esac
}

# Scripti çalıştır
main "$@"
