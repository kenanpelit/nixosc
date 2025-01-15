#!/usr/bin/env bash
#######################################
#
# Version: 1.0.0
# Date: 2024-12-12
# Author: Kenan Pelit
# Repository: github.com/kenanpelit/dotfiles
# Description: RsyncTool - Gelişmiş RSYNC Transfer Yöneticisi
#
# Bu script rsync ile dosya transferlerini kolaylaştırmak ve yönetmek için
# tasarlanmış kapsamlı bir araçtır. Temel özellikleri:
# - Tekli ve çoklu transfer desteği
# - Paralel transfer özelliği
# - Profil tabanlı yapılandırma sistemi
# - Exclude pattern yönetimi
# - Transfer öncesi disk ve ağ kontrolü
# - İlerleme çubuğu ve bildirim entegrasyonu
# - Detaylı loglama ve hata yönetimi
# - Ağ bant genişliği kontrolü
# - Sıkıştırma ve doğrulama seçenekleri
#
# Config: ~/.config/rsync-tool/
# Logs: ~/.log/state/rsync-tool/logs/
# Temp: /tmp/rsync-tool-$$/
#
# License: MIT
#
#######################################

# Versiyon ve Dizin Yapılandırması
VERSION="1.0.0"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/rsync-tool"
PROFILES_DIR="$CONFIG_DIR/profiles"
LOG_BASE_DIR="${XDG_STATE_HOME:-$HOME/.log/state}/rsync-tool"
DEFAULT_LOG_DIR="$LOG_BASE_DIR/logs"
TEMP_DIR="/tmp/rsync-tool-$$"
PARALLEL_MAX=4

# Renkler ve Formatlar
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'
BOLD='\033[1m'

# Progress Bar Ayarları
PROGRESS_CHAR="▓"
PENDING_CHAR="░"
PROGRESS_WIDTH=50

# Varsayılan profil ayarları
declare -A profile=(
  ["bandwidth"]="0"
  ["ssh_port"]="22"
  ["backup_count"]="5"
  ["compression"]="auto"
  ["notify"]="false"
  ["exclude_file"]=""
  ["min_space"]="1000"
  ["parallel"]="false"
  ["max_jobs"]="4"
  ["verify"]="true"
)

# Ortam Kurulumu
setup_environment() {
  mkdir -p "$CONFIG_DIR" "$PROFILES_DIR" "$DEFAULT_LOG_DIR" "$TEMP_DIR"
  chmod 755 "$CONFIG_DIR" "$PROFILES_DIR" "$DEFAULT_LOG_DIR" "$TEMP_DIR"
  trap cleanup EXIT
}

cleanup() {
  rm -rf "$TEMP_DIR"
}

# Progress Bar
create_progress_bar() {
  local percentage=$1
  local width=$2
  local completed=$((width * percentage / 100))
  local remaining=$((width - completed))

  printf -v progress "%*s" "$completed" ""
  printf -v pending "%*s" "$remaining" ""
  echo -ne "\r["
  echo -ne "${GREEN}${progress// /$PROGRESS_CHAR}${NC}"
  echo -ne "${pending// /$PENDING_CHAR}"
  echo -ne "] ${percentage}%% "
}

# Disk Alanı Kontrolü Fonksiyonu
check_disk_space() {
  local target="$1"
  local source_size="$2"
  local available
  local required_size

  # Eğer hedef zaten varsa, sadece değişimleri hesapla
  if [[ "$target" == *":"* ]]; then
    local host="${target%:*}"
    local path="${target#*:}"

    # Uzak sunucudaki mevcut boyutu kontrol et
    local target_size
    target_size=$(ssh "$host" "du -sm '$path' 2>/dev/null | cut -f1" || echo "0")
    available=$(ssh "$host" "df -m '$path' | awk 'NR==2 {print \$4}'")
  else
    # Yerel hedef kontrolü
    if [ -e "$target" ]; then
      local target_size
      target_size=$(du -sm "$target" 2>/dev/null | cut -f1 || echo "0")
      # Delta için gereken tahmini alan (kaynak ile hedef arasındaki fark + %10 buffer)
      required_size=$(((source_size - target_size) * 11 / 10))
      required_size=$((required_size > 0 ? required_size : 1))
    else
      # Hedef yoksa kaynak boyutunun %110'u kadar alan gerek
      required_size=$((source_size * 11 / 10))
    fi

    available=$(df -m "$target" | awk 'NR==2 {print $4}')
  fi

  # Minimum 1GB veya dosya boyutunun %10'u kadar boş alan olmalı
  local min_required=1024 # 1GB
  required_size=$((required_size > min_required ? required_size : min_required))

  if [ "${available:-0}" -lt "$required_size" ]; then
    echo -e "${YELLOW}UYARI: Hedef konumda önerilen alan miktarından az alan var${NC}"
    echo -e "Mevcut alan : ${BLUE}${available}MB${NC}"
    echo -e "Önerilen    : ${BLUE}${required_size}MB${NC}"
    echo -e "Not: Rsync delta-transfer kullandığından daha az alan gerekebilir."
    return 1
  fi
  return 0
}

# Ağ Kalitesi Kontrolü
check_network_quality() {
  local target="$1"
  local min_speed=1000          # KB/s
  local packet_loss_threshold=5 # %

  if [[ $target == *":"* ]]; then
    local host=${target%:*}
    echo -e "${BLUE}Ağ kalitesi kontrol ediliyor: $host${NC}"

    # Ping testi
    if ! ping -c 1 -W 2 "$host" >/dev/null 2>&1; then
      echo -e "${RED}UYARI: Host ulaşılamaz: $host${NC}"
      return 1
    fi

    local packet_loss=$(ping -c 5 -q "$host" | grep "packet loss" | awk '{print $6}' | tr -d '%')
    if [ "${packet_loss:-100}" -gt "$packet_loss_threshold" ]; then
      echo -e "${RED}UYARI: Yüksek paket kaybı: $packet_loss%${NC}"
      return 1
    fi
  fi
  return 0
}

# Paralel Transfer
parallel_transfer() {
  local source="$1"
  shift
  local destinations=("$@")
  local job_count=0
  local max_jobs=${profile[max_jobs]}
  local pids=()

  echo -e "${BLUE}Paralel transfer başlatılıyor...${NC}"
  echo "Maksimum eşzamanlı transfer: $max_jobs"

  for dest in "${destinations[@]}"; do
    echo -e "${CYAN}Transfer başlatılıyor: $dest${NC}"
    rsync_transfer "$source" "$dest" &
    pids+=($!)
    ((job_count++))

    if [ "$job_count" -ge "$max_jobs" ]; then
      wait -n
      ((job_count--))
    fi
  done

  echo -e "${YELLOW}Transferler tamamlanıyor...${NC}"
  for pid in "${pids[@]}"; do
    wait "$pid"
  done
  echo -e "${GREEN}Tüm transferler tamamlandı.${NC}"
}

# Profil Yönetimi
load_profile() {
  local profile_name="$1"
  local profile_file="$PROFILES_DIR/$profile_name.conf"

  if [[ -f "$profile_file" ]]; then
    while IFS='=' read -r key value; do
      [[ $key =~ ^[[:space:]]*# ]] && continue
      [[ -z $key ]] && continue
      key=$(echo "$key" | tr -d '[:space:]')
      value=$(echo "$value" | tr -d '[:space:]' | tr -d '"')
      profile[$key]="$value"
    done <"$profile_file"
    echo -e "${GREEN}Profil yüklendi: $profile_name${NC}"
    return 0
  else
    echo -e "${RED}Profil bulunamadı: $profile_name${NC}"
    return 1
  fi
}

save_profile() {
  local profile_name="$1"
  local profile_file="$PROFILES_DIR/$profile_name.conf"

  mkdir -p "$PROFILES_DIR"
  {
    echo "# RSYNC Profil - $profile_name - $(date '+%Y-%m-%d %H:%M:%S')"
    for key in "${!profile[@]}"; do
      echo "$key=${profile[$key]}"
    done
  } >"$profile_file"

  echo -e "${GREEN}Profil kaydedildi: $profile_name${NC}"
}

show_settings() {
  echo -e "\n${BOLD}Mevcut Ayarlar${NC}"
  echo "-------------------------"
  printf "%-20s: ${BLUE}%s${NC}\n" "Bandwidth Limit" "${profile[bandwidth]:-Sınırsız}"
  printf "%-20s: ${BLUE}%s${NC}\n" "SSH Port" "${profile[ssh_port]}"
  printf "%-20s: ${BLUE}%s${NC}\n" "Backup Sayısı" "${profile[backup_count]}"
  printf "%-20s: ${BLUE}%s${NC}\n" "Sıkıştırma" "${profile[compression]}"
  printf "%-20s: ${BLUE}%s${NC}\n" "Bildirimler" "${profile[notify]}"
  printf "%-20s: ${BLUE}%s${NC}\n" "Exclude Dosyası" "${profile[exclude_file]:-Yok}"
  printf "%-20s: ${BLUE}%s${NC}\n" "Minimum Alan" "${profile[min_space]} MB"
  printf "%-20s: ${BLUE}%s${NC}\n" "Paralel Transfer" "${profile[parallel]}"
  printf "%-20s: ${BLUE}%s${NC}\n" "Maksimum İş Sayısı" "${profile[max_jobs]}"
  printf "%-20s: ${BLUE}%s${NC}\n" "Doğrulama" "${profile[verify]}"
  echo "-------------------------"

  read -rp "Ana menüye dönmek için Enter'a basın..."
}

rsync_transfer() {
  local source="$1"
  local destination="$2"
  local log_file="$DEFAULT_LOG_DIR/rsync_$(date +%Y%m%d_%H%M%S)_$$.log"

  # Kaynak kontrolü
  if [ ! -e "$source" ]; then
    echo -e "${RED}HATA: Kaynak bulunamadı: $source${NC}"
    notify-send -u critical "RSYNC Hata" "Kaynak bulunamadı: $source"
    return 1
  fi

  # Hedef kontrolü
  if [[ "$destination" == *":"* ]]; then
    local host="${destination%:*}"
    if ! ping -c 1 -W 2 "$host" >/dev/null 2>&1; then
      echo -e "${RED}HATA: Hedef sunucuya erişilemiyor: $host${NC}"
      return 1
    fi
  fi

  # Ön kontroller
  echo -e "${BLUE}Ön kontroller yapılıyor...${NC}"
  local size_mb
  size_mb=$(du -sm "$source" 2>/dev/null | cut -f1)

  # Disk alanı kontrolü
  if ! check_disk_space "$destination" "$size_mb"; then
    echo -e "${YELLOW}Devam etmek riskli olabilir.${NC}"
    read -rp "Yine de devam etmek istiyor musunuz? (e/H) " answer
    [[ "${answer,,}" != "e" ]] && return 1
  fi

  # Ağ kontrolü (sadece uzak hedefler için)
  if [[ "$destination" == *":"* ]]; then
    if ! check_network_quality "$destination"; then
      echo -e "${YELLOW}Ağ bağlantısı optimal değil.${NC}"
      read -rp "Devam etmek istiyor musunuz? (e/H) " answer
      [[ "${answer,,}" != "e" ]] && return 1
    fi
  fi

  # RSYNC parametreleri
  local rsync_opts=(
    --archive
    --verbose
    --human-readable
    --partial
    --progress
    --info=progress2
  )

  # Exclude dosyası kontrolü
  if [[ -n "${profile[exclude_file]}" && -f "${profile[exclude_file]}" ]]; then
    rsync_opts+=(--exclude-from="${profile[exclude_file]}")
    # Dry-run ile exclude edilecek dosyaları göster
    echo -e "\n${BLUE}Dışlanacak dosyaların ön kontrolü:${NC}"
    rsync --dry-run --itemize-changes "${rsync_opts[@]}" "$source/" "$destination/" | grep '^*deleting' || true
  fi

  # Transfer özeti göster
  echo -e "\n${BLUE}Transfer Detayları:${NC}"
  echo -e "Kaynak     : ${CYAN}$source${NC}"
  echo -e "Hedef      : ${CYAN}$destination${NC}"
  [[ -n "${profile[exclude_file]}" ]] && echo -e "Exclude    : ${CYAN}${profile[exclude_file]}${NC}"

  # Onay al
  read -rp "Transfer başlatılsın mı? (e/H): " confirm
  [[ ${confirm,,} != "e" ]] && return 1

  # Opsiyonel parametreler
  [[ "${profile[bandwidth]}" != "0" ]] && rsync_opts+=("--bwlimit=${profile[bandwidth]}")
  [[ -f "${profile[exclude_file]}" ]] && rsync_opts+=("--exclude-from=${profile[exclude_file]}")
  [[ "${profile[verify]}" == "true" ]] && rsync_opts+=("--checksum")

  # Sıkıştırma ayarları
  if [[ "${profile[compression]}" == "true" ]]; then
    rsync_opts+=(
      --compress
      --compress-level=9
      "--skip-compress=jpg/png/gif/zip/gz/tgz/7z/mp3/mp4/mkv"
    )
  fi

  # SSH parametreleri (uzak hedef için)
  if [[ "$destination" == *":"* ]]; then
    rsync_opts+=(-e "ssh -T -c aes128-gcm@openssh.com -o Compression=no -x")
  fi

  # Log dosyası
  rsync_opts+=("--log-file=$log_file")

  # Transfer başlangıç bilgisi
  echo -e "\n${BLUE}Transfer Detayları:${NC}"
  echo -e "Kaynak     : ${CYAN}$source${NC}"
  echo -e "Hedef      : ${CYAN}$destination${NC}"
  echo -e "Boyut      : ${CYAN}${size_mb}MB${NC}"
  echo -e "Log        : ${CYAN}$log_file${NC}"
  echo -e "Başlangıç  : ${CYAN}$(date '+%Y-%m-%d %H:%M:%S')${NC}\n"

  # Transfer ve progress bar
  rsync "${rsync_opts[@]}" "$source" "$destination" 2>&1 |
    while IFS= read -r line; do
      if [[ "$line" =~ ^[0-9]+% ]]; then
        local percentage
        percentage=$(echo "$line" | grep -oE '^[0-9]+')
        create_progress_bar "$percentage" "$PROGRESS_WIDTH"
      fi
    done

  local status=$?
  local end_time
  end_time=$(date '+%Y-%m-%d %H:%M:%S')

  # Transfer sonuç raporu
  if [ $status -eq 0 ]; then
    echo -e "\n${GREEN}Transfer başarıyla tamamlandı!${NC}"
    echo -e "Bitiş: $end_time"
    if [[ "${profile[notify]}" == "true" ]]; then
      notify-send "RSYNC Transfer" "Transfer başarıyla tamamlandı!\nKaynak: $source\nHedef: $destination"
    fi
  else
    echo -e "\n${RED}Transfer başarısız oldu! (Hata kodu: $status)${NC}"
    echo -e "Bitiş: $end_time"
    if [[ "${profile[notify]}" == "true" ]]; then
      notify-send -u critical "RSYNC Transfer" "Transfer başarısız oldu!\nHata kodu: $status"
    fi
  fi

  # Transfer özeti
  echo -e "\n${BLUE}Transfer Özeti:${NC}"
  echo -e "Durum      : $([ $status -eq 0 ] && echo "${GREEN}Başarılı${NC}" || echo "${RED}Başarısız${NC}")"
  echo -e "Başlangıç  : $timestamp"
  echo -e "Bitiş      : $(date +%Y%m%d_%H%M%S)"
  echo -e "Log        : $log_file"

  return $status
}
# Exclude pattern yönetimi
manage_exclude_patterns() {
  local exclude_file="${profile[exclude_file]}"

  # Varsayılan exclude dosyası yolu
  if [ -z "$exclude_file" ]; then
    exclude_file="$CONFIG_DIR/exclude_patterns.txt"
    profile[exclude_file]="$exclude_file"
  fi

  while true; do
    clear
    echo -e "${BOLD}Exclude Pattern Yönetimi${NC}"
    echo -e "${BLUE}-------------------------${NC}"
    echo -e "Mevcut Exclude Dosyası: ${CYAN}${exclude_file}${NC}"
    echo

    if [ -f "$exclude_file" ]; then
      echo -e "${BOLD}Mevcut Desenler:${NC}"
      nl -ba "$exclude_file"
      echo
    else
      echo -e "${YELLOW}Exclude dosyası henüz oluşturulmamış.${NC}"
      echo
    fi

    echo "1) Yeni pattern ekle"
    echo "2) Pattern sil"
    echo "3) Örnek patternları yükle"
    echo "4) Başka exclude dosyası seç"
    echo "5) Tüm patternları göster"
    echo "6) Exclude dosyasını düzenle"
    echo "b) Ana menüye dön"
    echo -e "${BLUE}-------------------------${NC}"

    read -rp "Seçiminiz: " choice
    case "$choice" in
    1)
      add_exclude_pattern "$exclude_file"
      ;;
    2)
      remove_exclude_pattern "$exclude_file"
      ;;
    3)
      load_example_patterns "$exclude_file"
      ;;
    4)
      select_exclude_file
      ;;
    5)
      show_all_patterns "$exclude_file"
      ;;
    6)
      edit_exclude_file "$exclude_file"
      ;;
    b | B)
      break
      ;;
    *)
      echo -e "${RED}Geçersiz seçim!${NC}"
      sleep 1
      ;;
    esac
  done
}

# Yeni pattern ekleme
add_exclude_pattern() {
  local exclude_file="$1"
  echo -e "\n${BOLD}Yeni Pattern Ekleme${NC}"
  echo -e "${YELLOW}Örnekler:${NC}"
  echo "*.tmp       -> Tüm .tmp dosyalarını dışla"
  echo "*.log       -> Tüm log dosyalarını dışla"
  echo "/temp/*     -> Kök dizindeki temp klasörünü dışla"
  echo ".git/       -> Git dizinlerini dışla"
  echo "node_modules/  -> Node modüllerini dışla"
  echo

  read -rp "Pattern: " pattern
  if [ -n "$pattern" ]; then
    mkdir -p "$(dirname "$exclude_file")"
    echo "$pattern" >>"$exclude_file"
    echo -e "${GREEN}Pattern eklendi.${NC}"
    sleep 1
  fi
}

# Pattern silme
remove_exclude_pattern() {
  local exclude_file="$1"
  if [ -f "$exclude_file" ]; then
    echo -e "\n${BOLD}Pattern Silme${NC}"
    nl -ba "$exclude_file"
    echo
    read -rp "Silinecek satır numarası (İptal için Enter): " line_num
    if [[ "$line_num" =~ ^[0-9]+$ ]]; then
      sed -i "${line_num}d" "$exclude_file"
      echo -e "${GREEN}Pattern silindi.${NC}"
    fi
  else
    echo -e "${RED}Exclude dosyası bulunamadı!${NC}"
  fi
  sleep 1
}

# Örnek patternları yükle
load_example_patterns() {
  local exclude_file="$1"
  echo -e "\n${BOLD}Örnek Patternlar Yükleniyor${NC}"

  local examples=(
    "# Geçici dosyalar"
    "*.tmp"
    "*.temp"
    "*.bak"
    "*.swp"
    "._*"
    ".DS_Store"
    "Thumbs.db"
    ""
    "# Sistem dizinleri"
    ".git/"
    ".svn/"
    ".hg/"
    ".idea/"
    ".vscode/"
    ""
    "# Programlama"
    "node_modules/"
    "__pycache__/"
    "*.pyc"
    "*.pyo"
    "*.pyd"
    "venv/"
    ".env/"
    ""
    "# Log ve cache"
    "*.log"
    "logs/"
    "cache/"
    ".cache/"
    ""
    "# Diğer"
    "lost+found/"
    ".Trash*/"
  )

  mkdir -p "$(dirname "$exclude_file")"
  printf "%s\n" "${examples[@]}" >"$exclude_file"
  echo -e "${GREEN}Örnek patternlar yüklendi.${NC}"
  sleep 1
}

# Başka exclude dosyası seç
select_exclude_file() {
  echo -e "\n${BOLD}Exclude Dosyası Seçimi${NC}"
  read -rp "Yeni exclude dosyası yolu: " new_file
  if [ -n "$new_file" ]; then
    profile[exclude_file]="$new_file"
    echo -e "${GREEN}Exclude dosyası güncellendi.${NC}"
  fi
  sleep 1
}

# Tüm patternları göster
show_all_patterns() {
  local exclude_file="$1"
  if [ -f "$exclude_file" ]; then
    echo -e "\n${BOLD}Tüm Exclude Patternları${NC}"
    echo -e "${BLUE}-------------------------${NC}"
    nl -ba "$exclude_file"
    echo -e "${BLUE}-------------------------${NC}"
  else
    echo -e "${RED}Exclude dosyası bulunamadı!${NC}"
  fi
  read -rp "Devam etmek için Enter'a basın..."
}

# Exclude dosyasını düzenle
edit_exclude_file() {
  local exclude_file="$1"
  local editor="${EDITOR:-nano}"

  if ! command -v "$editor" >/dev/null; then
    editor="nano"
  fi

  mkdir -p "$(dirname "$exclude_file")"
  touch "$exclude_file"
  $editor "$exclude_file"
}

# Menü Fonksiyonları
show_menu() {
  while true; do
    clear
    echo -e "${BOLD}RSYNC Transfer Aracı v${VERSION}${NC}"
    echo -e "${BLUE}-------------------------${NC}"
    echo "1) Tekli Transfer"
    echo "2) Çoklu Transfer"
    echo "3) Paralel Transfer"
    echo "4) Profil Yükle"
    echo "5) Profil Kaydet"
    echo "6) Ayarları Göster"
    echo "7) Sistem Kontrolü"
    echo "8) Exclude Yönetimi" # Yeni eklenen menü
    echo "9) Yardım"
    echo "q) Çıkış"
    echo -e "${BLUE}-------------------------${NC}"

    read -rp "Seçiminiz: " choice
    case "$choice" in
    1) single_transfer_menu ;;
    2) multiple_transfer_menu ;;
    3) parallel_transfer_menu ;;
    4) load_profile_menu ;;
    5) save_profile_menu ;;
    6) show_settings ;;
    7) system_check_menu ;;
    8) manage_exclude_patterns ;;
    9) show_help ;;
    q | Q) exit 0 ;;
    *)
      echo -e "${RED}Geçersiz seçim!${NC}"
      sleep 1
      ;;
    esac
  done
}

single_transfer_menu() {
  echo -e "\n${BOLD}Tekli Transfer${NC}"

  # Exclude durumu göster
  if [[ -n "${profile[exclude_file]}" && -f "${profile[exclude_file]}" ]]; then
    echo -e "${GREEN}Aktif exclude dosyası:${NC} ${profile[exclude_file]}"
    echo -e "${BLUE}Dışlanan öğeler:${NC}"
    grep -v '^#' "${profile[exclude_file]}" | grep -v '^$' | sed 's/^/  - /'
    echo
  else
    echo -e "${YELLOW}Exclude dosyası aktif değil${NC}\n"
  fi

  # Transfer seçenekleri
  echo "1) Normal transfer"
  echo "2) Exclude ile transfer"
  echo "3) Exclude ayarla/düzenle"
  echo "b) Geri"

  read -rp "Seçiminiz: " choice
  case "$choice" in
  1)
    # Normal transfer
    unset 'profile[exclude_file]'
    do_transfer
    ;;
  2)
    # Exclude ile transfer
    if [[ -z "${profile[exclude_file]}" ]]; then
      echo -e "${YELLOW}Önce exclude dosyası seçilmeli!${NC}"
      manage_exclude_patterns
    fi
    if [[ -n "${profile[exclude_file]}" ]]; then
      do_transfer
    fi
    ;;
  3)
    manage_exclude_patterns
    ;;
  b | B)
    return
    ;;
  *)
    echo -e "${RED}Geçersiz seçim!${NC}"
    sleep 1
    ;;
  esac
}

# Transfer işlemi
do_transfer() {
  read -rp "Kaynak: " source
  read -rp "Hedef: " destination

  if [ -z "$source" ] || [ -z "$destination" ]; then
    echo -e "${RED}Kaynak ve hedef belirtilmeli!${NC}"
    read -rp "Devam etmek için Enter'a basın..."
    return 1
  fi

  # Exclude dosyası kontrolü ve gösterimi
  if [[ -n "${profile[exclude_file]}" && -f "${profile[exclude_file]}" ]]; then
    echo -e "\n${BLUE}Dışlanacak öğeler:${NC}"
    grep -v '^#' "${profile[exclude_file]}" | grep -v '^$' | sed 's/^/  - /'
    echo
    read -rp "Transfer bu dışlamalarla yapılacak. Devam? (e/H): " confirm
    [[ ${confirm,,} != "e" ]] && return
  fi

  # Transfer işlemini başlat
  rsync_transfer "$source" "$destination"
  read -rp "Ana menüye dönmek için Enter'a basın..."
}

multiple_transfer_menu() {
  echo -e "\n${BOLD}Çoklu Transfer${NC}"
  read -rp "Kaynak: " source
  if [ -z "$source" ]; then
    echo -e "${RED}Kaynak belirtilmeli!${NC}"
    read -rp "Devam etmek için Enter'a basın..."
    return 1
  fi

  local destinations=()
  echo "Hedefleri girin (boş satır için Enter):"
  while true; do
    read -rp "Hedef: " dest
    [[ -z "$dest" ]] && break
    destinations+=("$dest")
  done

  if [ ${#destinations[@]} -eq 0 ]; then
    echo -e "${RED}En az bir hedef belirtilmeli!${NC}"
    read -rp "Devam etmek için Enter'a basın..."
    return 1
  fi

  for dest in "${destinations[@]}"; do
    echo -e "\n${BLUE}Transfer: $dest${NC}"
    rsync_transfer "$source" "$dest"
  done
  read -rp "Ana menüye dönmek için Enter'a basın..."
}

parallel_transfer_menu() {
  echo -e "\n${BOLD}Paralel Transfer${NC}"
  read -rp "Kaynak: " source
  if [ -z "$source" ]; then
    echo -e "${RED}Kaynak belirtilmeli!${NC}"
    read -rp "Devam etmek için Enter'a basın..."
    return 1
  fi

  local destinations=()
  echo "Hedefleri girin (boş satır için Enter):"
  while true; do
    read -rp "Hedef: " dest
    [[ -z "$dest" ]] && break
    destinations+=("$dest")
  done

  if [ ${#destinations[@]} -eq 0 ]; then
    echo -e "${RED}En az bir hedef belirtilmeli!${NC}"
    read -rp "Devam etmek için Enter'a basın..."
    return 1
  fi

  read -rp "Maksimum eşzamanlı transfer sayısı [${profile[max_jobs]}]: " max_jobs
  [[ -n "$max_jobs" ]] && profile[max_jobs]=$max_jobs

  parallel_transfer "$source" "${destinations[@]}"
  read -rp "Ana menüye dönmek için Enter'a basın..."
}

load_profile_menu() {
  echo -e "\n${BOLD}Profil Yükle${NC}"
  echo "Mevcut profiller:"
  ls -1 "$PROFILES_DIR"/*.conf 2>/dev/null | while read -r profile_path; do
    echo "- $(basename "$profile_path" .conf)"
  done

  read -rp "Profil adı: " profile_name
  [[ -n "$profile_name" ]] && load_profile "$profile_name"
  read -rp "Ana menüye dönmek için Enter'a basın..."
}

save_profile_menu() {
  echo -e "\n${BOLD}Profil Kaydet${NC}"
  read -rp "Profil adı: " profile_name
  [[ -n "$profile_name" ]] && save_profile "$profile_name"
  read -rp "Ana menüye dönmek için Enter'a basın..."
}

system_check_menu() {
  echo -e "\n${BOLD}Sistem Kontrolü${NC}"
  read -rp "Hedef dizin/sunucu: " target

  if [ -n "$target" ]; then
    echo -e "\n${BLUE}Disk alanı kontrolü...${NC}"
    check_disk_space "$target"

    echo -e "\n${BLUE}Ağ bağlantı kalitesi kontrolü...${NC}"
    check_network_quality "$target"
  else
    echo -e "${RED}Hedef belirtilmeli!${NC}"
  fi
  read -rp "Ana menüye dönmek için Enter'a basın..."
}

show_help() {
  clear
  cat <<EOF
${BOLD}Gelişmiş RSYNC Transfer Aracı v${VERSION}${NC}

${BOLD}Özellikler:${NC}
- Tek ve çoklu transfer desteği
- Paralel transfer yapabilme
- Disk alanı ve ağ kalitesi kontrolü
- Profil yönetimi
- Detaylı loglama
- İlerleme çubuğu
- Bildirim desteği

${BOLD}Kullanım:${NC}
1. Tekli Transfer: Tek kaynak ve hedef için transfer
2. Çoklu Transfer: Tek kaynak, birden fazla hedef
3. Paralel Transfer: Eşzamanlı çoklu transfer
4. Profil Yükle: Kayıtlı ayarları yükle
5. Profil Kaydet: Mevcut ayarları kaydet
6. Ayarlar: Mevcut ayarları görüntüle
7. Sistem Kontrolü: Hedef sistem kontrolü
8. Yardım: Bu mesajı göster

${BOLD}İpuçları:${NC}
- Uzak sunucular için: kullanıcı@sunucu:/dizin formatını kullanın
- Exclude dosyası için her satıra bir pattern yazın
- Paralel transferde sistem kaynaklarına dikkat edin
EOF
  read -rp "Ana menüye dönmek için Enter'a basın..."
}

# Ana Program
main() {
  setup_environment
  show_menu
}

# Programı başlat
main "$@"
