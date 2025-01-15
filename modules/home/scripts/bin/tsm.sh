#!/usr/bin/env bash
#######################################
#
# Version: 2.2.1
# Date: 2024-12-19
# Author: Kenan Pelit
# Repository: github.com/kenanpelit/dotfiles
# Description: TransmissionCLI - Transmission Terminal Yönetim Aracı
#
# Bu script transmission-remote için gelişmiş bir CLI arayüzü sağlar.
# Temel özellikleri:
# - Pass entegrasyonu ile güvenli kimlik bilgileri yönetimi
# - Gelişmiş torrent arama (kategori destekli)
# - Torrent ekleme ve yönetim (magnet/dosya)
# - Detaylı istatistikler ve sağlık kontrolleri
# - Disk alanı takibi
# - Otomatik tamamlanan torrent yönetimi
# - Hız limitleri ve kategori yönetimi
#
# Komutlar için ./tsm.sh yazarak yardım alabilirsiniz.
#
# Gereksinimler:
# - pass (şifre yöneticisi)
# - transmission-remote
# - transmission-daemon
# - pirate-get (arama özelliği için)
#
# License: MIT
#
#######################################

# Renk kodları
Color_Off='\e[0m'
Red='\e[0;31m'
Green='\e[0;32m'
Yellow='\e[0;33m'
Blue='\e[0;34m'

# Hata kontrolü ve bağımlılık kontrolü
check_dependencies() {
  local missing_deps=()

  # Gerekli komutların kontrolü
  for cmd in pass transmission-remote pirate-get; do
    if ! command -v "$cmd" &>/dev/null; then
      missing_deps+=("$cmd")
    fi
  done

  if [ ${#missing_deps[@]} -ne 0 ]; then
    echo -e "${Red}Hata: Aşağıdaki bağımlılıklar eksik:${Color_Off}"
    printf '%s\n' "${missing_deps[@]}"
    exit 1
  fi
}

# Transmission ayarlarını al
get_transmission_settings() {
  CONFIG_FILE="$HOME/.config/transmission-daemon/settings.json"
  if [ -f "$CONFIG_FILE" ]; then
    PORT=$(grep -o '"rpc-port": [0-9]*' "$CONFIG_FILE" | awk '{print $2}')
    HOST="localhost" # localhost kullan çünkü bağlantı yerel
    USER=$(pass tsm-user 2>/dev/null || echo "admin")
    PASS=$(pass tsm-pass 2>/dev/null)
  else
    PORT=9091
    HOST="localhost"
    USER=$(pass tsm-user 2>/dev/null || echo "admin")
    PASS=$(pass tsm-pass 2>/dev/null)
  fi
}

# Pass kontrolü ve yapılandırma
setup_pass() {
  if ! pass show tsm-user &>/dev/null; then
    read -p "Transmission kullanıcı adı (varsayılan: admin): " username
    username=${username:-admin}
    echo "$username" | pass insert -e tsm-user
  fi

  if ! pass show tsm-pass &>/dev/null; then
    read -sp "Transmission şifresi: " password
    echo
    echo "$password" | pass insert -e tsm-pass
  fi
}

# Program başlangıç kontrolleri
init() {
  check_dependencies
  setup_pass
  get_transmission_settings
}

# Transmission kontrolü
check_transmission() {
  if ! transmission-remote "$HOST:$PORT" --auth "$USER:$PASS" -l >/dev/null 2>&1; then
    echo -e "${Yellow}Transmission bağlantısı kontrol ediliyor...${Color_Off}"
    systemctl --user start transmission
    sleep 2
  fi
}

# Yardım mesajı
show_help() {
  echo -e "${Blue}Transmission Terminal Yöneticisi${Color_Off}"
  echo "Kullanım: tsm.sh [komut] [parametre]"
  echo
  echo "Arama Komutları:"
  echo -e "${Green}search${Color_Off}, ${Green}s${Color_Off} [terim]     Torrent ara"
  echo -e "${Green}search -c${Color_Off} [kategori] [terim]  Belirli kategoride ara"
  echo -e "${Green}search -R${Color_Off} [terim]    Son 48 saatteki torrentlerde ara"
  echo -e "${Green}search -l${Color_Off}            Mevcut kategorileri listele"
  echo
  echo "Temel Komutlar:"
  echo -e "${Green}add${Color_Off} [link/dosya]    Torrent veya magnet link ekle"
  echo -e "${Green}list${Color_Off}, ${Green}l${Color_Off}              Torrent listesini göster"
  echo -e "${Green}start${Color_Off} [id]          Torrenti başlat"
  echo -e "${Green}stop${Color_Off} [id]           Torrenti durdur"
  echo -e "${Green}remove${Color_Off} [id]         Torrenti sil"
  echo -e "${Green}purge${Color_Off} [id]          Torrenti ve dosyaları sil"
  echo -e "${Green}info${Color_Off} [id]           Torrent detaylarını göster"
  echo
  echo "Gelişmiş Komutlar:"
  echo -e "${Green}tsm-remove-done${Color_Off}     Tamamlanmış torrentleri sil"
  echo -e "${Green}auto-remove${Color_Off}         Otomatik tamamlanan torrent silme (daemon)"
  echo -e "${Green}disk-check${Color_Off}          Disk kullanım durumunu kontrol et"
  echo -e "${Green}stats${Color_Off}               Detaylı istatistikleri göster"
  echo -e "${Green}move${Color_Off} [id] [hedef]   Torrenti başka klasöre taşı"
  echo -e "${Green}limit${Color_Off} [up/down] [hız] Hız limiti ayarla (KB/s)"
  echo -e "${Green}tracker${Color_Off} [id]        Tracker bilgilerini göster"
  echo -e "${Green}health${Color_Off}              Torrent sağlık kontrolü"
  echo -e "${Green}speed${Color_Off}               İndirme/yükleme hızını göster"
  echo -e "${Green}files${Color_Off} [id]          Torrent dosyalarını listele"
  echo -e "${Green}config${Color_Off}              Yapılandırmayı güncelle"
  echo
  echo "Not: [id] yerine 'all' yazarak tüm torrentlere işlem yapabilirsiniz"
}

# Torrent listesini göster
show_list() {
  echo -e "${Blue}Torrent Listesi:${Color_Off}"
  transmission-remote "$HOST:$PORT" --auth "$USER:$PASS" -l
}

# Yapılandırmayı yeniden ayarla
reconfigure() {
  read -p "Yeni kullanıcı adı (varsayılan: admin): " new_username
  new_username=${new_username:-admin}
  echo "$new_username" | pass insert -f -e tsm-user

  read -sp "Yeni şifre: " new_password
  echo
  echo "$new_password" | pass insert -f -e tsm-pass

  echo -e "${Green}Yapılandırma güncellendi.${Color_Off}"
}

# Search fonksiyonu
do_search() {
  check_transmission
  local RECENT=false
  local CATEGORY=""
  local search_term=""

  # Eğer ilk parametre -l ise kategorileri listele
  if [ "$1" = "-l" ] || [ "$1" = "--list-categories" ]; then
    echo -e "${Blue}Mevcut Kategoriler:${Color_Off}"
    pirate-get --list-categories
    return 0
  fi

  # Parametreleri kontrol et
  while getopts "Rc:" opt; do
    case $opt in
    R) RECENT=true ;;
    c) CATEGORY="-c $OPTARG" ;;
    \?) return 1 ;;
    esac
  done
  shift $((OPTIND - 1))

  search_term="$*"
  if [ -z "$search_term" ]; then
    echo -e "${Red}Hata: Arama terimi gerekli${Color_Off}"
    return 1
  fi

  local RECENT_FLAG=""
  if [ "$RECENT" = true ]; then
    RECENT_FLAG="-R"
  fi

  echo -e "${Yellow}Arama yapılıyor: $search_term${Color_Off}"
  if [ -n "$CATEGORY" ]; then
    echo -e "${Blue}Kategori: ${CATEGORY#-c }${Color_Off}"
  fi

  pirate-get -t -E "$HOST:$PORT" -A "$USER:$PASS" $RECENT_FLAG $CATEGORY "$search_term"
}

# Program başlangıç işlemleri
init

# Ana case yapısı
case "$1" in
"search" | "s")
  shift
  do_search "$@"
  ;;

"list" | "l")
  show_list
  ;;

"add")
  if [ -z "$2" ]; then
    echo -e "${Red}Hata: Torrent dosyası veya magnet link gerekli${Color_Off}"
    exit 1
  fi
  echo -e "${Yellow}Torrent ekleniyor...${Color_Off}"
  transmission-remote "$HOST:$PORT" --auth "$USER:$PASS" -a "$2"
  ;;

"start")
  if [ "$2" = "all" ]; then
    echo -e "${Yellow}Tüm torrentler başlatılıyor...${Color_Off}"
    transmission-remote "$HOST:$PORT" --auth "$USER:$PASS" -t all -s
  elif [ -n "$2" ]; then
    echo -e "${Yellow}$2 ID'li torrent başlatılıyor...${Color_Off}"
    transmission-remote "$HOST:$PORT" --auth "$USER:$PASS" -t "$2" -s
  else
    echo -e "${Red}Hata: Torrent ID'si gerekli${Color_Off}"
    exit 1
  fi
  ;;

"stop")
  if [ "$2" = "all" ]; then
    echo -e "${Yellow}Tüm torrentler durduruluyor...${Color_Off}"
    transmission-remote "$HOST:$PORT" --auth "$USER:$PASS" -t all -S
  elif [ -n "$2" ]; then
    echo -e "${Yellow}$2 ID'li torrent durduruluyor...${Color_Off}"
    transmission-remote "$HOST:$PORT" --auth "$USER:$PASS" -t "$2" -S
  else
    echo -e "${Red}Hata: Torrent ID'si gerekli${Color_Off}"
    exit 1
  fi
  ;;

"remove")
  if [ "$2" = "all" ]; then
    echo -e "${Red}Tüm torrentler siliniyor...${Color_Off}"
    transmission-remote "$HOST:$PORT" --auth "$USER:$PASS" -t all -r
  elif [ -n "$2" ]; then
    echo -e "${Red}$2 ID'li torrent siliniyor...${Color_Off}"
    transmission-remote "$HOST:$PORT" --auth "$USER:$PASS" -t "$2" -r
  else
    echo -e "${Red}Hata: Torrent ID'si gerekli${Color_Off}"
    exit 1
  fi
  ;;

"purge")
  if [ "$2" = "all" ]; then
    echo -e "${Red}Tüm torrentler ve dosyaları siliniyor...${Color_Off}"
    transmission-remote "$HOST:$PORT" --auth "$USER:$PASS" -t all -rad
  elif [ -n "$2" ]; then
    echo -e "${Red}$2 ID'li torrent ve dosyaları siliniyor...${Color_Off}"
    transmission-remote "$HOST:$PORT" --auth "$USER:$PASS" -t "$2" -rad
  else
    echo -e "${Red}Hata: Torrent ID'si gerekli${Color_Off}"
    exit 1
  fi
  ;;

"tsm-remove-done")
  echo -e "${Yellow}Tamamlanmış torrentler kontrol ediliyor...${Color_Off}"
  completed_torrents=$(transmission-remote "$HOST:$PORT" --auth "$USER:$PASS" -l | grep "100%" | awk '{print $1}' | sed 's/[*]//g')

  if [ -z "$completed_torrents" ]; then
    echo -e "${Yellow}Tamamlanmış torrent bulunamadı.${Color_Off}"
    exit 0
  fi

  echo -e "${Red}Tamamlanmış torrentler siliniyor...${Color_Off}"
  for id in $completed_torrents; do
    echo -e "${Yellow}$id ID'li tamamlanmış torrent siliniyor...${Color_Off}"
    transmission-remote "$HOST:$PORT" --auth "$USER:$PASS" -t "$id" -r
  done
  echo -e "${Green}Tamamlanmış torrentler silindi.${Color_Off}"
  ;;

"auto-remove")
  echo -e "${Yellow}Otomatik silme modu etkinleştiriliyor...${Color_Off}"
  while true; do
    completed=$(transmission-remote "$HOST:$PORT" --auth "$USER:$PASS" -l | grep "100%" | awk '{print $1}' | sed 's/[*]//g')
    if [ -n "$completed" ]; then
      for id in $completed; do
        transmission-remote "$HOST:$PORT" --auth "$USER:$PASS" -t "$id" -r
        echo -e "${Green}Torrent $id otomatik silindi${Color_Off}"
      done
    fi
    sleep 300 # 5 dakikada bir kontrol
  done
  ;;

"disk-check")
  echo -e "${Blue}Disk Durumu:${Color_Off}"
  download_dir=$(grep '"download-dir":' ~/.config/transmission-daemon/settings.json | cut -d'"' -f4)
  used=$(df -h "$download_dir" | awk 'NR==2 {print $5}' | sed 's/%//')
  if [ "$used" -gt 90 ]; then
    echo -e "${Red}Uyarı: Disk kullanımı %$used${Color_Off}"
  else
    echo -e "${Green}Disk kullanımı: %$used${Color_Off}"
  fi
  ;;

"stats")
  echo -e "${Blue}Transmission İstatistikleri:${Color_Off}"
  transmission-remote "$HOST:$PORT" --auth "$USER:$PASS" -st
  echo -e "\n${Blue}En Hızlı Torrentler:${Color_Off}"
  transmission-remote "$HOST:$PORT" --auth "$USER:$PASS" -l | sort -k5 -nr | head -5
  ;;

"move")
  if [ -n "$2" ] && [ -n "$3" ]; then
    echo -e "${Yellow}$2 ID'li torrent $3 klasörüne taşınıyor...${Color_Off}"
    transmission-remote "$HOST:$PORT" --auth "$USER:$PASS" -t "$2" --move "$3"
  else
    echo -e "${Red}Hata: Torrent ID ve hedef klasör gerekli${Color_Off}"
  fi
  ;;

"limit")
  case "$2" in
  "up")
    transmission-remote "$HOST:$PORT" --auth "$USER:$PASS" -as -u "$3"
    echo -e "${Green}Upload limit: $3 KB/s${Color_Off}"
    ;;
  "down")
    transmission-remote "$HOST:$PORT" --auth "$USER:$PASS" -as -d "$3"
    echo -e "${Green}Download limit: $3 KB/s${Color_Off}"
    ;;
  *)
    echo -e "${Red}Kullanım: limit [up/down] [hız KB/s]${Color_Off}"
    ;;
  esac
  ;;

"tracker")
  if [ -n "$2" ]; then
    echo -e "${Blue}Tracker Bilgileri:${Color_Off}"
    transmission-remote "$HOST:$PORT" --auth "$USER:$PASS" -t "$2" -it
  else
    echo -e "${Red}Hata: Torrent ID gerekli${Color_Off}"
  fi
  ;;

"health")
  echo -e "${Blue}Torrent Sağlık Kontrolü:${Color_Off}"
  transmission-remote "$HOST:$PORT" --auth "$USER:$PASS" -l | while read -r line; do
    id=$(echo "$line" | awk '{print $1}' | sed 's/[*]//g')
    peers=$(echo "$line" | awk '{print $5}')
    if [ "$peers" -eq 0 ]; then
      echo -e "${Red}Torrent $id: Peer bulunamadı${Color_Off}"
    fi
  done
  ;;

"info")
  if [ -n "$2" ]; then
    echo -e "${Blue}$2 ID'li torrent detayları:${Color_Off}"
    transmission-remote "$HOST:$PORT" --auth "$USER:$PASS" -t "$2" -i
  else
    echo -e "${Red}Hata: Torrent ID'si gerekli${Color_Off}"
    exit 1
  fi
  ;;

"speed")
  echo -e "${Blue}Anlık hız bilgisi:${Color_Off}"
  transmission-remote "$HOST:$PORT" --auth "$USER:$PASS" -si
  ;;

"files")
  if [ -n "$2" ]; then
    echo -e "${Blue}$2 ID'li torrent dosyaları:${Color_Off}"
    transmission-remote "$HOST:$PORT" --auth "$USER:$PASS" -t "$2" -f
  else
    echo -e "${Red}Hata: Torrent ID'si gerekli${Color_Off}"
    exit 1
  fi
  ;;

"config")
  reconfigure
  ;;

*)
  show_help
  ;;
esac
