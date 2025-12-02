#!/usr/bin/env bash

# =================================================================
# Hyprpaper Duvar Kağıdı Yöneticisi v1.1
# Multi-monitor desteği ile
# =================================================================

set -euo pipefail

# =================================================================
# YAPILANDIRMA
# =================================================================

DEFAULT_INTERVAL=300
WALLPAPER_PATH="$HOME/Pictures/wallpapers"
WALLPAPERS_FOLDER="$WALLPAPER_PATH/others"
WALLPAPER_LINK="$WALLPAPER_PATH/wallpaper"
MAX_HISTORY=15
SUPPORTED_EXTENSIONS=("jpg" "jpeg" "png" "webp" "jxl")

# Multi-monitor: Her monitöre farklı duvar kağıdı
MULTI_MONITOR_MODE=true # false yaparak tek duvar kağıdı kullanabilirsin

# =================================================================
# DOSYA YOLLARI
# =================================================================

PID_FILE="/tmp/hyprpaper-manager.pid"
HISTORY_DIR="$HOME/.cache/wallpapers"
HISTORY_FILE="$HISTORY_DIR/history.txt"
TOTAL_FILE="$HISTORY_DIR/total_wallpapers.txt"
MONITOR_HISTORY_DIR="$HISTORY_DIR/monitors"
LOG_FILE="/tmp/hyprpaper-manager.log"

# =================================================================
# RENKLER
# =================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

SCRIPT_NAME="$(basename "$0")"

# =================================================================
# GLOBAL DEĞİŞKENLER
# =================================================================

INTERVAL=$DEFAULT_INTERVAL
VERBOSE=false
DRY_RUN=false
USE_FD=false

# =================================================================
# YARDIMCI FONKSİYONLAR
# =================================================================

log() {
  local level="$1"
  shift
  local message="$*"
  local timestamp
  timestamp=$(date '+%Y-%m-%d %H:%M:%S')

  case "$level" in
  ERROR) echo -e "${RED}[ERROR]${NC} $message" >&2 ;;
  WARN) echo -e "${YELLOW}[WARN]${NC} $message" >&2 ;;
  SUCCESS) echo -e "${GREEN}[SUCCESS]${NC} $message" ;;
  INFO) echo -e "${BLUE}[INFO]${NC} $message" ;;
  DEBUG) $VERBOSE && echo -e "${CYAN}[DEBUG]${NC} $message" ;;
  esac

  echo "[$timestamp] [$level] $message" >>"$LOG_FILE" 2>/dev/null || true
}

detect_find_tool() {
  if command -v fd >/dev/null 2>&1; then
    USE_FD=true
    log DEBUG "fd komutu kullanılacak"
  else
    USE_FD=false
    log DEBUG "find komutu kullanılacak"
  fi
}

ensure_directory() {
  local dir="$1"
  [[ -d "$dir" ]] || mkdir -p "$dir" 2>/dev/null || true
}

# =================================================================
# DUVAR KAĞIDI LİSTELE
# =================================================================

list_wallpapers() {
  if $USE_FD; then
    fd -t f -e jpg -e jpeg -e png -e webp -e jxl . "$WALLPAPERS_FOLDER" 2>/dev/null
  else
    find "$WALLPAPERS_FOLDER" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" -o -iname "*.jxl" \) 2>/dev/null
  fi
}

list_wallpapers_basename() {
  if $USE_FD; then
    fd -t f -e jpg -e jpeg -e png -e webp -e jxl . "$WALLPAPERS_FOLDER" -x basename 2>/dev/null
  else
    find "$WALLPAPERS_FOLDER" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" -o -iname "*.jxl" \) -exec basename {} \; 2>/dev/null
  fi
}

# =================================================================
# MONİTÖR VE HYPRPAPER YÖNETİMİ
# =================================================================

get_monitors() {
  if ! command -v hyprctl >/dev/null 2>&1; then
    echo "eDP-1"
    return
  fi

  local monitors=""

  # Önce jq ile dene
  if command -v jq >/dev/null 2>&1; then
    monitors=$(hyprctl monitors -j 2>/dev/null | jq -r '.[].name' 2>/dev/null | tr '\n' ' ')
  fi

  # jq yoksa veya başarısız olduysa grep ile dene
  if [[ -z "$monitors" ]]; then
    monitors=$(hyprctl monitors 2>/dev/null | grep -oP '^Monitor \K[^\s]+' | tr '\n' ' ')
  fi

  # Hala boşsa varsayılan
  if [[ -z "$monitors" ]]; then
    echo "eDP-1"
  else
    echo "$monitors" | xargs # trim whitespace
  fi
}

check_hyprpaper() {
  if ! command -v hyprpaper >/dev/null 2>&1; then
    log ERROR "hyprpaper komutu bulunamadı"
    log INFO "Yüklemek için: sudo pacman -S hyprpaper"
    return 1
  fi

  if ! pgrep -x hyprpaper >/dev/null 2>&1; then
    log INFO "hyprpaper başlatılıyor..."
    hyprpaper &>/dev/null &
    sleep 2

    if ! pgrep -x hyprpaper >/dev/null 2>&1; then
      log ERROR "hyprpaper başlatılamadı"
      return 1
    fi
    log SUCCESS "hyprpaper başlatıldı"
  fi

  return 0
}

check_hyprctl() {
  if ! command -v hyprctl >/dev/null 2>&1; then
    log ERROR "hyprctl komutu bulunamadı"
    return 1
  fi

  if ! hyprctl monitors &>/dev/null; then
    log ERROR "hyprctl çalışmıyor (Hyprland çalışıyor mu?)"
    return 1
  fi

  return 0
}

# =================================================================
# GEÇMİŞ YÖNETİMİ (MONITÖR BAZINDA)
# =================================================================

init_history() {
  ensure_directory "$HISTORY_DIR"
  ensure_directory "$MONITOR_HISTORY_DIR"
  touch "$HISTORY_FILE" "$TOTAL_FILE" 2>/dev/null || true
}

get_monitor_history() {
  local monitor="$1"
  local history_file="$MONITOR_HISTORY_DIR/${monitor}.txt"

  if [[ -f "$history_file" ]]; then
    tail -n 10 "$history_file" 2>/dev/null
  fi
}

add_to_monitor_history() {
  local monitor="$1"
  local wallpaper="$2"
  local history_file="$MONITOR_HISTORY_DIR/${monitor}.txt"

  echo "$wallpaper" >>"$history_file" 2>/dev/null || true

  # Temizle
  local line_count
  line_count=$(wc -l <"$history_file" 2>/dev/null || echo "0")

  if [[ $line_count -gt $MAX_HISTORY ]]; then
    tail -n "$MAX_HISTORY" "$history_file" >"${history_file}.tmp" 2>/dev/null
    mv "${history_file}.tmp" "$history_file" 2>/dev/null || true
  fi
}

cleanup_history() {
  [[ ! -f "$HISTORY_FILE" ]] && return

  local line_count
  line_count=$(wc -l <"$HISTORY_FILE" 2>/dev/null || echo "0")

  if [[ $line_count -gt $MAX_HISTORY ]]; then
    log DEBUG "Geçmiş temizleniyor: $line_count -> $MAX_HISTORY"
    tail -n "$MAX_HISTORY" "$HISTORY_FILE" >"${HISTORY_FILE}.tmp" 2>/dev/null
    mv "${HISTORY_FILE}.tmp" "$HISTORY_FILE" 2>/dev/null || true
  fi
}

# =================================================================
# DUVAR KAĞIDI SEÇME (MONITÖR BAZINDA)
# =================================================================

select_random_wallpaper() {
  local monitor="${1:-}"
  local wallpaper_list=("${@:2}")
  local count=${#wallpaper_list[@]}

  if [[ $count -eq 0 ]]; then
    return 1
  fi

  # Bu monitörün geçmişini al
  local recent=()
  if [[ -n "$monitor" ]]; then
    mapfile -t recent < <(get_monitor_history "$monitor")
  fi

  # Rastgele seç (geçmişte olmayanlardan)
  local selected=""
  local selected_name=""
  local attempts=0

  while [[ $attempts -lt 50 ]]; do
    selected="${wallpaper_list[RANDOM % count]}"
    selected_name=$(basename "$selected")

    # Geçmişte var mı?
    local found=false
    for r in "${recent[@]}"; do
      if [[ "$r" == "$selected_name" ]]; then
        found=true
        break
      fi
    done

    [[ "$found" == "false" ]] && break
    ((attempts++))
  done

  echo "$selected"
}

# =================================================================
# DUVAR KAĞIDI AYARLAMA
# =================================================================

set_wallpaper_single() {
  local monitor="$1"
  local wallpaper="$2"

  log DEBUG "[$monitor] Ayarlanıyor: $(basename "$wallpaper")"

  # Preload
  hyprctl hyprpaper preload "$wallpaper" &>/dev/null || {
    log DEBUG "[$monitor] Preload uyarısı"
  }

  sleep 0.3

  # Wallpaper uygula
  if hyprctl hyprpaper wallpaper "$monitor,$wallpaper" &>/dev/null; then
    log DEBUG "[$monitor] ✓ Başarılı"
    return 0
  else
    log WARN "[$monitor] ✗ Başarısız"
    return 1
  fi
}

set_wallpaper() {
  local wallpaper="${1:-}"

  # Tek duvar kağıdı modu
  if [[ -n "$wallpaper" ]]; then
    if [[ ! -f "$wallpaper" ]]; then
      log ERROR "Dosya bulunamadı: $wallpaper"
      return 1
    fi
  fi

  if ! check_hyprpaper; then
    return 1
  fi

  if ! check_hyprctl; then
    return 1
  fi

  [[ "$DRY_RUN" == "true" ]] && return 0

  # Monitörleri al
  local monitors
  mapfile -t monitors < <(get_monitors | tr ' ' '\n')

  if [[ ${#monitors[@]} -eq 0 ]]; then
    log ERROR "Monitör bulunamadı"
    return 1
  fi

  log DEBUG "Bulunan monitörler: ${monitors[*]}"

  # Multi-monitor modu
  if $MULTI_MONITOR_MODE && [[ -z "$wallpaper" ]]; then
    log INFO "Multi-monitor modu: Her monitöre farklı duvar kağıdı"

    local wallpaper_list
    mapfile -t wallpaper_list < <(list_wallpapers)

    local success=false
    for monitor in "${monitors[@]}"; do
      local selected
      selected=$(select_random_wallpaper "$monitor" "${wallpaper_list[@]}")

      if set_wallpaper_single "$monitor" "$selected"; then
        success=true
        add_to_monitor_history "$monitor" "$(basename "$selected")"
        log SUCCESS "[$monitor] $(basename "$selected")"
      fi
    done

    if ! $success; then
      log ERROR "Hiçbir monitöre duvar kağıdı uygulanamadı"
      return 1
    fi

  else
    # Tek duvar kağıdı modu - tüm monitörlere aynı
    log INFO "Tek duvar kağıdı modu: Tüm monitörlere aynı"

    if [[ -z "$wallpaper" ]]; then
      local wallpaper_list
      mapfile -t wallpaper_list < <(list_wallpapers)
      wallpaper=$(select_random_wallpaper "" "${wallpaper_list[@]}")
    fi

    log DEBUG "Seçilen: $(basename "$wallpaper")"

    # Preload
    hyprctl hyprpaper preload "$wallpaper" &>/dev/null || {
      log WARN "Preload hatası"
    }

    sleep 0.5

    # Tüm monitörlere uygula
    local success=false
    for monitor in "${monitors[@]}"; do
      if hyprctl hyprpaper wallpaper "$monitor,$wallpaper" &>/dev/null; then
        log DEBUG "[$monitor] ✓"
        success=true
      else
        log WARN "[$monitor] ✗"
      fi
    done

    if ! $success; then
      log ERROR "Hiçbir monitöre uygulanamadı"
      return 1
    fi

    log SUCCESS "Değiştirildi: $(basename "$wallpaper")"
  fi

  # Bellek temizliği
  sleep 1
  hyprctl hyprpaper unload all &>/dev/null || true

  return 0
}

# =================================================================
# DUVAR KAĞIDI DEĞİŞTİRME
# =================================================================

change_wallpaper() {
  init_history

  # Duvar kağıtlarını listele
  local wallpaper_list
  mapfile -t wallpaper_list < <(list_wallpapers)

  local count=${#wallpaper_list[@]}

  if [[ $count -eq 0 ]]; then
    log ERROR "Duvar kağıdı bulunamadı: $WALLPAPERS_FOLDER"
    return 1
  fi

  log DEBUG "$count duvar kağıdı bulundu"

  # Toplam sayıyı kaydet
  echo "$count" >"$TOTAL_FILE" 2>/dev/null || true

  # Duvar kağıdını ayarla
  if ! set_wallpaper; then
    log ERROR "Duvar kağıdı ayarlanamadı"
    return 1
  fi

  # Global geçmişi güncelle
  if [[ "$DRY_RUN" != "true" ]]; then
    # Son değiştirilen wallpaper'ı kaydet
    local last_wallpaper=""

    if $MULTI_MONITOR_MODE; then
      # Multi-monitor: ilk monitörün wallpaper'ını al
      local monitors
      mapfile -t monitors < <(get_monitors | tr ' ' '\n')
      if [[ ${#monitors[@]} -gt 0 ]]; then
        last_wallpaper=$(get_monitor_history "${monitors[0]}" | tail -1)
      fi
    fi

    if [[ -n "$last_wallpaper" ]]; then
      echo "$last_wallpaper" >>"$HISTORY_FILE" 2>/dev/null || true
      cleanup_history

      # Symlink güncelle
      local full_path
      full_path=$(find "$WALLPAPERS_FOLDER" -name "$last_wallpaper" -print -quit)
      if [[ -n "$full_path" ]]; then
        ln -sf "$full_path" "$WALLPAPER_LINK" 2>/dev/null || true
      fi
    fi
  fi

  return 0
}

# =================================================================
# DAEMON LOOP
# =================================================================

daemon_loop() {
  local interval="$1"

  echo $$ >"$PID_FILE"

  log INFO "Daemon başlatıldı (PID: $$, aralık: ${interval}s, mod: $(${MULTI_MONITOR_MODE} && echo "multi-monitor" || echo "single"))"

  cleanup_daemon() {
    log INFO "Daemon durduruluyor..."
    rm -f "$PID_FILE"
    exit 0
  }

  trap cleanup_daemon EXIT INT TERM HUP

  while true; do
    if change_wallpaper; then
      log DEBUG "Sonraki değişim: ${interval}s sonra"
      sleep "$interval" &
      wait $!
    else
      log ERROR "Hata, 60s bekle"
      sleep 60 &
      wait $!
    fi
  done
}

# =================================================================
# SERVİS YÖNETİMİ
# =================================================================

check_status() {
  local quiet=${1:-false}

  if [[ ! -f "$PID_FILE" ]]; then
    $quiet || log WARN "Servis çalışmıyor"
    return 1
  fi

  local pid
  pid=$(cat "$PID_FILE" 2>/dev/null) || {
    $quiet || log WARN "PID dosyası okunamadı"
    rm -f "$PID_FILE" 2>/dev/null
    return 1
  }

  if ! kill -0 "$pid" 2>/dev/null; then
    $quiet || log WARN "Servis çalışmıyor (eski PID temizlendi)"
    rm -f "$PID_FILE" 2>/dev/null
    return 1
  fi

  $quiet || log SUCCESS "Servis çalışıyor (PID: $pid)"
  return 0
}

start_service() {
  if check_status true; then
    log WARN "Servis zaten çalışıyor"
    return 1
  fi

  if [[ ! -d "$WALLPAPERS_FOLDER" ]]; then
    log ERROR "Dizin bulunamadı: $WALLPAPERS_FOLDER"
    return 1
  fi

  if ! check_hyprpaper; then
    return 1
  fi

  if ! check_hyprctl; then
    return 1
  fi

  ensure_directory "$WALLPAPER_PATH"

  log INFO "Servis başlatılıyor (aralık: ${INTERVAL}s, mod: $(${MULTI_MONITOR_MODE} && echo "multi-monitor" || echo "single"))"

  local display="${DISPLAY:-}"
  local wayland_display="${WAYLAND_DISPLAY:-}"
  local xdg_runtime_dir="${XDG_RUNTIME_DIR:-}"
  local hyprland_instance="${HYPRLAND_INSTANCE_SIGNATURE:-}"

  (
    export DISPLAY="$display"
    export WAYLAND_DISPLAY="$wayland_display"
    export XDG_RUNTIME_DIR="$xdg_runtime_dir"
    export HYPRLAND_INSTANCE_SIGNATURE="$hyprland_instance"

    "$0" --daemon "$INTERVAL"
  ) </dev/null >>"$LOG_FILE" 2>&1 &

  disown

  sleep 2

  if check_status true; then
    local pid
    pid=$(cat "$PID_FILE" 2>/dev/null || echo "?")
    log SUCCESS "Servis başlatıldı (PID: $pid)"
    return 0
  else
    log ERROR "Servis başlatılamadı - log: $LOG_FILE"
    return 1
  fi
}

stop_service() {
  if [[ ! -f "$PID_FILE" ]]; then
    log WARN "Servis zaten durmuş"
    return 0
  fi

  local pid
  pid=$(cat "$PID_FILE" 2>/dev/null) || {
    log WARN "PID okunamadı"
    rm -f "$PID_FILE" 2>/dev/null
    return 0
  }

  if ! kill -0 "$pid" 2>/dev/null; then
    log WARN "Servis zaten durmuş"
    rm -f "$PID_FILE" 2>/dev/null
    return 0
  fi

  log INFO "Servis durduruluyor (PID: $pid)"

  kill -TERM "$pid" 2>/dev/null || true

  local count=0
  while [[ $count -lt 15 ]] && kill -0 "$pid" 2>/dev/null; do
    sleep 0.5
    ((count++))
  done

  if kill -0 "$pid" 2>/dev/null; then
    log WARN "Zorla sonlandırılıyor..."
    kill -KILL "$pid" 2>/dev/null || true
    sleep 1
    pkill -KILL -P "$pid" 2>/dev/null || true
  fi

  rm -f "$PID_FILE" 2>/dev/null

  sleep 0.5
  if kill -0 "$pid" 2>/dev/null; then
    log ERROR "Servis durdurulamadı - force-stop kullanın"
    return 1
  else
    log SUCCESS "Servis durduruldu"
    return 0
  fi
}

restart_service() {
  log INFO "Servis yeniden başlatılıyor..."
  stop_service
  sleep 2
  start_service
}

force_stop() {
  log WARN "Zorla durdurma başlatılıyor..."

  local pid=""
  [[ -f "$PID_FILE" ]] && pid=$(cat "$PID_FILE" 2>/dev/null || echo "")

  if [[ -n "$pid" ]]; then
    kill -KILL "$pid" 2>/dev/null || true
    pkill -KILL -P "$pid" 2>/dev/null || true
  fi

  pkill -9 -f "$SCRIPT_NAME.*--daemon" 2>/dev/null || true

  rm -f "$PID_FILE" 2>/dev/null

  sleep 1

  if pgrep -f "$SCRIPT_NAME.*--daemon" >/dev/null 2>&1; then
    log ERROR "Bazı process'ler hala çalışıyor:"
    ps aux | grep -E "$SCRIPT_NAME.*--daemon" | grep -v grep
    return 1
  else
    log SUCCESS "Tüm process'ler temizlendi"
    return 0
  fi
}

# =================================================================
# İNTERAKTİF FONKSİYONLAR
# =================================================================

select_wallpaper_rofi() {
  if ! command -v rofi >/dev/null 2>&1; then
    log ERROR "rofi komutu bulunamadı"
    return 1
  fi

  local name
  name=$(list_wallpapers_basename | sort | rofi -dmenu -p "Duvar kağıdı seçin") || {
    log INFO "İptal edildi"
    return 1
  }

  local path="$WALLPAPERS_FOLDER/$name"

  if [[ -f "$path" ]]; then
    if set_wallpaper "$path"; then
      ln -sf "$path" "$WALLPAPER_LINK" 2>/dev/null || true
      init_history
      echo "$name" >>"$HISTORY_FILE" 2>/dev/null || true
      cleanup_history
      log SUCCESS "Duvar kağıdı değiştirildi: $name"
    fi
  else
    log ERROR "Dosya bulunamadı: $path"
    return 1
  fi
}

show_stats() {
  init_history

  local total=0
  [[ -f "$TOTAL_FILE" ]] && total=$(cat "$TOTAL_FILE" 2>/dev/null || echo "0")

  local history=0
  [[ -f "$HISTORY_FILE" ]] && history=$(wc -l <"$HISTORY_FILE" 2>/dev/null || echo "0")

  local current="Bilinmiyor"
  [[ -L "$WALLPAPER_LINK" ]] && current=$(basename "$(readlink "$WALLPAPER_LINK")" 2>/dev/null || echo "Bilinmiyor")

  local tool="find"
  $USE_FD && tool="fd"

  echo -e "${CYAN}╔══════════════════════════════════════════════╗${NC}"
  echo -e "${CYAN}║${NC}  Duvar Kağıdı Yöneticisi - İstatistikler      ${CYAN}║${NC}"
  echo -e "${CYAN}╚══════════════════════════════════════════════╝${NC}"
  echo ""
  echo -e "  Toplam duvar kağıdı : ${GREEN}$total${NC}"
  echo -e "  Geçmiş kayıt        : ${GREEN}$history${NC}"
  echo -e "  Mevcut duvar kağıdı : ${GREEN}$current${NC}"
  echo -e "  Duvar kağıdı dizini : ${BLUE}$WALLPAPERS_FOLDER${NC}"
  echo -e "  Değişim aralığı     : ${YELLOW}${INTERVAL}s${NC}"
  echo -e "  Arama aracı         : ${CYAN}$tool${NC}"
  echo -e "  Multi-monitor modu  : $(${MULTI_MONITOR_MODE} && echo -e "${GREEN}Aktif${NC}" || echo -e "${YELLOW}Pasif${NC}")"
  echo ""

  if check_status true; then
    local pid
    pid=$(cat "$PID_FILE" 2>/dev/null || echo "?")
    echo -e "  Servis durumu       : ${GREEN}● Çalışıyor${NC} (PID: $pid)"
  else
    echo -e "  Servis durumu       : ${RED}○ Durduruldu${NC}"
  fi

  if pgrep -x hyprpaper >/dev/null 2>&1; then
    echo -e "  Hyprpaper           : ${GREEN}● Çalışıyor${NC}"
  else
    echo -e "  Hyprpaper           : ${RED}○ Durduruldu${NC}"
  fi

  # Monitörler
  local monitors
  monitors=$(get_monitors)
  echo -e "  Monitörler          : ${CYAN}$monitors${NC}"

  # Her monitörün son duvar kağıdı
  if $MULTI_MONITOR_MODE; then
    echo ""
    echo -e "${CYAN}  Monitör Bazlı Duvar Kağıtları:${NC}"
    for monitor in $monitors; do
      local last_wall
      last_wall=$(get_monitor_history "$monitor" | tail -1)
      if [[ -n "$last_wall" ]]; then
        echo -e "    ${MAGENTA}$monitor${NC}: $last_wall"
      else
        echo -e "    ${MAGENTA}$monitor${NC}: -"
      fi
    done
  fi

  echo ""
}

# =================================================================
# YARDIM
# =================================================================

show_usage() {
  echo -e "${CYAN}Hyprpaper Duvar Kağıdı Yöneticisi v1.1${NC}"
  echo ""
  echo -e "${YELLOW}KULLANIM:${NC}"
  echo "    $SCRIPT_NAME [KOMUT] [SEÇENEKLER]"
  echo ""
  echo -e "${YELLOW}KOMUTLAR:${NC}"
  echo -e "    ${GREEN}start [süre]${NC}     Servisi başlat (varsayılan: ${DEFAULT_INTERVAL}s)"
  echo -e "    ${GREEN}stop${NC}             Servisi durdur"
  echo -e "    ${GREEN}restart${NC}          Servisi yeniden başlat"
  echo -e "    ${GREEN}force-stop${NC}       Zorla durdur"
  echo -e "    ${GREEN}status${NC}           Servis durumunu göster"
  echo -e "    ${GREEN}stats${NC}            Detaylı istatistikler"
  echo -e "    ${GREEN}select${NC}           Rofi ile duvar kağıdı seç"
  echo -e "    ${GREEN}now${NC}              Manuel duvar kağıdı değiştir"
  echo -e "    ${GREEN}(boş)${NC}            Tek seferlik rastgele değişim"
  echo ""
  echo -e "${YELLOW}SEÇENEKLER:${NC}"
  echo -e "    ${CYAN}-v, --verbose${NC}    Ayrıntılı çıktı"
  echo -e "    ${CYAN}-n, --dry-run${NC}    Deneme modu (gerçekte değiştirmez)"
  echo -e "    ${CYAN}-h, --help${NC}       Bu yardım mesajı"
  echo ""
  echo -e "${YELLOW}ÖZELLİKLER:${NC}"
  echo "    • Multi-monitor: Her monitöre farklı duvar kağıdı"
  echo "    • Akıllı geçmiş: Monitör bazında tekrar önleme"
  echo "    • Otomatik hyprpaper yönetimi"
  echo ""
  echo -e "${YELLOW}ÖRNEKLER:${NC}"
  echo -e "    $SCRIPT_NAME start              ${CYAN}# Servisi başlat${NC}"
  echo -e "    $SCRIPT_NAME start 60           ${CYAN}# 60 saniye aralıkla${NC}"
  echo -e "    $SCRIPT_NAME now                ${CYAN}# Hemen değiştir${NC}"
  echo -e "    $SCRIPT_NAME stats              ${CYAN}# İstatistikleri göster${NC}"
  echo ""
  echo -e "${YELLOW}YAPıLANDIRMA:${NC}"
  echo -e "    • Multi-monitor modunu kapatmak için scriptte:"
  echo -e "      ${CYAN}MULTI_MONITOR_MODE=false${NC}"
  echo -e "    • Log: $LOG_FILE"
}

# =================================================================
# ANA FONKSİYON
# =================================================================

main() {
  if [[ "${1:-}" == "--daemon" ]]; then
    shift
    local interval="${1:-$DEFAULT_INTERVAL}"
    detect_find_tool
    daemon_loop "$interval"
    exit 0
  fi

  detect_find_tool

  while [[ $# -gt 0 ]]; do
    case $1 in
    -v | --verbose)
      VERBOSE=true
      shift
      ;;
    -n | --dry-run)
      DRY_RUN=true
      log INFO "Deneme modu aktif"
      shift
      ;;
    -h | --help)
      show_usage
      exit 0
      ;;

    start)
      shift
      if [[ $# -gt 0 && "$1" =~ ^[0-9]+$ ]]; then
        INTERVAL=$1
        shift
      fi
      start_service
      exit $?
      ;;

    stop)
      stop_service
      exit $?
      ;;
    restart)
      restart_service
      exit $?
      ;;
    force-stop)
      force_stop
      exit $?
      ;;
    status)
      check_status
      exit $?
      ;;
    stats)
      show_stats
      exit 0
      ;;
    select)
      select_wallpaper_rofi
      exit $?
      ;;
    now)
      change_wallpaper
      exit $?
      ;;

    *)
      log ERROR "Bilinmeyen komut: $1"
      echo ""
      show_usage
      exit 1
      ;;
    esac
  done

  change_wallpaper
}

main "$@"
