#!/usr/bin/env bash
#===============================================================================
#
#   Script: Hybrid Workspace Session Launcher
#   Version: 2.0.0
#   Date: 2024-12-12
#   Author: Kenan Pelit
#   Description: VPN-aware workspace session launcher with hybrid launch strategy
#
#   License: MIT
#
#===============================================================================

# Yapılandırma Değişkenleri
readonly SCRIPTS_DIR="$HOME/.bin/start-scripts"
readonly LOG_DIR="$HOME/.log"
readonly LOG_FILE="$LOG_DIR/session-launcher.log"

# Log dizinini oluştur
[[ ! -d "$LOG_DIR" ]] && mkdir -p "$LOG_DIR"

# Hata yakalama
set -euo pipefail
trap 'echo "Hata oluştu. Satır: $LINENO, Komut: $BASH_COMMAND"' ERR

# Uygulama Grupları - workspace ve başlatma stratejisine göre gruplandırılmış
declare -A APP_GROUPS
APP_GROUPS["core"]="start-akenp"                        # Terminal & Dev
APP_GROUPS["browsers"]="start-zen-kenp start-zen-novpn" # Ana browserlar
APP_GROUPS["communication"]="start-zen-whats"           # İletişim
APP_GROUPS["media"]="start-spotify"                     # Medya

# Uygulama Yapılandırması - workspace:fullscreen:togglegroup:vpn:sleep
declare -A APP_CONFIGS
# Terminal & Dev (Core)
APP_CONFIGS["start-akenp"]="2:no:no:always:2" # Tmux session
# Browsers
APP_CONFIGS["start-zen-kenp"]="1:yes:no:always:2"  # Main browser
APP_CONFIGS["start-zen-novpn"]="3:yes:no:always:2" # No VPN browser
# Communication
APP_CONFIGS["start-zen-whats"]="9:no:yes:always:2" # WhatsApp
# Media
APP_CONFIGS["start-spotify"]="8:no:no:always:2" # Spotify

# Gelişmiş Loglama Fonksiyonu
log() {
  local app=$1
  local message=$2
  local notify=${3:-false}
  local duration=${4:-5000}
  local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
  local log_entry="[$timestamp] [$app] $message"

  echo "$log_entry" >>"$LOG_FILE"
  echo "$log_entry"

  if [[ "$notify" == "true" ]]; then
    notify-send -t "$duration" -a "$app" "$message"
  fi
}

# VPN Durum Kontrolü
check_vpn_status() {
  local vpn_mode=$1
  local app_name=$2

  if [[ "$vpn_mode" == "always" ]]; then
    if ! pgrep -x "openvpn" >/dev/null; then
      log "VPN" "$app_name için VPN bağlantısı gerekli fakat aktif değil!" "true" 10000
      return 1
    fi
    log "VPN" "$app_name için VPN bağlantısı aktif ✓" "false"
  fi
  return 0
}

# CPU Frekans Ayarı
set_cpu_frequency() {
  local mode=$1
  case $mode in
  "high")
    echo 0 | sudo tee /sys/devices/system/cpu/intel_pstate/no_turbo >/dev/null
    sudo cpupower frequency-set -g performance
    sudo cpupower frequency-set -d 1900MHz -u 2800MHz >/dev/null 2>&1
    log "CPU" "Performance mode: 1900-2800MHz (Turbo ON) 🔥" "true" 5000
    ;;
  "low")
    echo 1 | sudo tee /sys/devices/system/cpu/intel_pstate/no_turbo >/dev/null
    sudo cpupower frequency-set -g powersave
    sudo cpupower frequency-set -d 1200MHz -u 1900MHz >/dev/null 2>&1
    log "CPU" "Power save mode: 1200-1900MHz (Turbo OFF) 🌱" "true" 5000
    ;;
  esac
}

# Tekil Uygulama Başlatma
launch_app() {
  local script_name=$1
  local config=${APP_CONFIGS[$script_name]}
  local workspace=$(echo "$config" | cut -d: -f1)
  local fullscreen=$(echo "$config" | cut -d: -f2)
  local togglegroup=$(echo "$config" | cut -d: -f3)
  local vpn_mode=$(echo "$config" | cut -d: -f4)
  local sleep_time=$(echo "$config" | cut -d: -f5)

  # VPN kontrolü
  if ! check_vpn_status "$vpn_mode" "${script_name#start-}"; then
    log "ERROR" "VPN kontrolü başarısız: ${script_name#start-}" "true" 10000
    return 1
  fi

  local script_path="$SCRIPTS_DIR/${script_name}-${vpn_mode}.sh"
  log "${script_name#start-}" "Starting (VPN: $vpn_mode)" "false"

  if [[ -x "$script_path" ]]; then
    "$script_path" &
    local app_pid=$!
    sleep "$sleep_time"

    # Fullscreen ve group ayarları
    if [[ "$fullscreen" == "yes" ]]; then
      sleep 0.5
      hyprctl dispatch fullscreen 0
    fi
    if [[ "$togglegroup" == "yes" ]]; then
      sleep 0.5
      hyprctl dispatch togglegroup
    fi

    wait $app_pid
    log "WORKSPACE" "Switched to workspace $workspace" "false"
  else
    log "ERROR" "Script bulunamadı: $script_path" "true" 10000
    return 1
  fi
}

# Grup Başlatma Fonksiyonu
launch_group() {
  local group_name=$1
  local apps=${APP_GROUPS[$group_name]}
  local parallel=${2:-false}

  log "GROUP" "Starting $group_name group" "false"

  if [[ "$parallel" == "true" ]]; then
    local pids=()
    for app in $apps; do
      launch_app "$app" &
      pids+=($!)
    done
    for pid in "${pids[@]}"; do
      wait "$pid"
    done
  else
    for app in $apps; do
      launch_app "$app"
    done
  fi
}

# Hibrit Başlatma Stratejisi
launch_apps_hybrid() {
  log "LAUNCH" "Starting hybrid launch..." "true" 3000
  local start_time=$(date +%s.%N)

  # Grup 1: Core uygulamalar (sıralı)
  launch_group "core" false

  # Grup 2: Browserlar (paralel)
  launch_group "browsers" true

  # Grup 3: İletişim uygulamaları (paralel)
  launch_group "communication" true

  # Grup 4: Medya uygulamaları (sıralı)
  launch_group "media" false

  local end_time=$(date +%s.%N)
  local duration=$(echo "$end_time - $start_time" | bc)
  log "TIMING" "Hybrid launch completed in ${duration}s" "true" 10000
}

# Ana Fonksiyon
main() {
  local start_time=$(date +%s)
  log "START" "Hybrid launcher starting! 🔥" "true" 5000

  # Log rotasyonu (1MB üzerinde ise yedekle)
  if [[ -f "$LOG_FILE" ]] && [[ $(stat -f%z "$LOG_FILE") -gt 1048576 ]]; then
    mv "$LOG_FILE" "$LOG_FILE.old"
    log "LOG" "Log dosyası rotasyonu yapıldı" "false"
  fi

  # CPU yüksek performans modu
  set_cpu_frequency "high"
  sleep 0.5

  # Hibrit başlatma
  launch_apps_hybrid

  # Süre hesaplama ve final bildirim
  local end_time=$(date +%s)
  local duration=$((end_time - start_time))
  log "Duration" "Total time: ${duration}s ⏱️" "true" 20000

  # İkinci workspace'e geç
  sleep 5
  hyprctl dispatch workspace 2
  log "WORKSPACE" "Final switch to workspace 2" "false"
}

main "$@"
