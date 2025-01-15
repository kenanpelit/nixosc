#!/usr/bin/env bash

#######################################
#
# Version: 1.0.0
# Date: 2024-12-13
# Author: Kenan Pelit
# Repository: github.com/kenanpelit/dotfiles
# Description: HyprShade Manager
#
# License: MIT
#
#######################################

#########################################################################
# HyprShade Manager
#
# Bu script, Hyprland için shader yönetimini sağlar.
# Farklı shader'ları yönetmek ve özelleştirmek için kullanılır.
# Waybar entegrasyonu ile birlikte çalışır.
#
# Özellikler:
#   - Hyprshade'i başlatma/durdurma/durum kontrolü
#   - Özelleştirilebilir shader seçimi ve güç ayarları
#   - Waybar entegrasyonu
#   - Sistem bildirimleri
#   - Otomatik config izleme ve yeniden başlatma
#
# Gereksinimler:
#   - hyprshade
#   - libnotify (notify-send için)
#   - waybar (opsiyonel)
#   - inotify-tools (config izleme için)
#
#########################################################################

# Sabit değişkenler
declare -r LOG_FILE="/tmp/hyprshade.log"
declare -r SHADER_PATH="$HOME/.config/hypr/shaders"
declare -r CONFIG_DIR="$HOME/.config/hypr/config"
declare -r TOGGLE_FILE="/tmp/.hyprshade_active"
declare -i LAST_RESTART=0
declare -i MIN_WAIT=3

# Varsayılan shader ayarları
SHADER_NAME="blue-light-filter"
SHADER_FILE="$SHADER_PATH/kenp-${SHADER_NAME}.glsl"
SHADER_STRENGTH=0.8
AUTO_RESTART=true

# Kullanım bilgisi
usage() {
  cat <<EOF
Hyprshade Manager - Shader Yönetim Aracı

KULLANIM:
    $(basename "$0") [KOMUT] [PARAMETRELER]

KOMUTLAR:
    start         Hyprshade'i başlat
    stop          Hyprshade'i durdur
    toggle        Hyprshade'i aç/kapat
    status        Hyprshade durumunu göster
    -h, --help    Bu yardım mesajını göster

PARAMETRELER:
    --shader NAME       Kullanılacak shader dosyası
                       (varsayılan: $SHADER_NAME)
    --strength VALUE   Shader efekt gücü (0.1-1.0)
                       (varsayılan: $SHADER_STRENGTH)
    --no-restart       Config değişikliklerinde otomatik yeniden başlatmayı devre dışı bırak
                       (varsayılan: etkin)

ÖRNEKLER:
    # Varsayılan ayarlarla başlatma
    $(basename "$0") start

    # Özel shader ve güç ayarıyla başlatma
    $(basename "$0") start --shader vibrance --strength 0.7

    # Otomatik yeniden başlatma olmadan başlatma
    $(basename "$0") start --no-restart

    # Durumu kontrol etme
    $(basename "$0") status

NOT:
    Shader dosyaları $SHADER_PATH dizininde bulunmalıdır.
    Dosya isimleri "kenp-{shader-name}.glsl" formatında olmalıdır.

EOF
}

# Temizlik işlemleri
cleanup() {
  echo "[$(date)] Servis kapatılıyor..."
  hyprshade off
  rm -f "$TOGGLE_FILE"
  exit 0
}

trap cleanup SIGTERM SIGINT

# Log yapılandırması
setup_logging() {
  exec 1> >(tee -a "$LOG_FILE") 2>&1
  echo "[$(date)] Hyprshade manager başlatılıyor..."
}

# Hyprshade durumunu kontrol et
check_status() {
  if [ -f "$TOGGLE_FILE" ]; then
    echo '{"class": "activated", "tooltip": "Hyprshade is active"}'
    return 0
  else
    echo '{"class": "", "tooltip": "Hyprshade is deactivated"}'
    return 1
  fi
}

# Detaylı durum bilgisi göster
show_status() {
  if [ -f "$TOGGLE_FILE" ]; then
    echo "Hyprshade: AKTİF"
    echo "Shader: $SHADER_NAME"
    echo "Güç: $SHADER_STRENGTH"
    echo "Son başlatma: $(stat -c %y "$TOGGLE_FILE")"
    echo "Config izleme: $([ "$AUTO_RESTART" = true ] && echo "Etkin" || echo "Devre dışı")"
  else
    echo "Hyprshade: KAPALI"
  fi
}

# Waybar'ı güncelle (eğer varsa)
update_waybar() {
  if command -v waybar >/dev/null 2>&1; then
    pkill -RTMIN+8 waybar
  fi
}

# Config değişikliklerini izleme
monitor_config_changes() {
  if [ "$AUTO_RESTART" = true ]; then
    echo "[$(date)] Config değişiklikleri izleniyor..."
    inotifywait -m -e modify,create,delete "$CONFIG_DIR" -r 2>/dev/null |
      while read -r directory events filename; do
        if [[ "$filename" =~ \.conf$ ]]; then
          echo "[$(date)] Config değişikliği tespit edildi: $filename"
          sleep 1
          manage_hyprshade false
        fi
      done
  fi
}

# Hyprshade'i yönet
manage_hyprshade() {
  local force=${1:-false}

  # Shader dosyasının varlığını kontrol et
  if [ ! -f "$SHADER_FILE" ]; then
    echo "[$(date)] HATA: Shader dosyası bulunamadı: $SHADER_FILE"
    notify-send -t 2000 -u critical "Hyprshade Hatası" "Shader dosyası bulunamadı!"
    return 1
  fi

  # hyprshade'in yüklü olup olmadığını kontrol et
  if ! command -v hyprshade &>/dev/null; then
    echo "[$(date)] HATA: hyprshade yüklü değil!"
    notify-send -t 2000 -u critical "Hyprshade Hatası" "hyprshade yüklü değil!"
    return 1
  fi

  CURRENT_TIME=$(date +%s)
  TIME_DIFF=$((CURRENT_TIME - LAST_RESTART))

  if [ "$force" = false ] && [ $TIME_DIFF -lt $MIN_WAIT ]; then
    echo "[$(date)] Son yeniden başlatmadan bu yana çok az zaman geçti ($TIME_DIFF saniye), işlem atlanıyor..."
    return 0
  fi

  # Eğer çalışıyorsa önce kapat
  hyprshade off
  sleep 0.5

  # (Yeniden) başlat
  HYPRSHADE_STRENGTH=$SHADER_STRENGTH hyprshade on "$SHADER_FILE"
  STATUS=$?

  if [ $STATUS -eq 0 ]; then
    touch "$TOGGLE_FILE"
    echo "[$(date)] Hyprshade başarıyla $([ "$force" = true ] && echo "başlatıldı" || echo "yeniden başlatıldı")"
    [ "$force" = true ] && notify-send -t 1000 -u low "Hyprshade Açıldı" "Shader: $SHADER_NAME"
    LAST_RESTART=$(date +%s)
    update_waybar
    return 0
  else
    echo "[$(date)] HATA: Hyprshade başlatılamadı (kod: $STATUS)"
    return 1
  fi
}

# Hyprland'in başlamasını bekle
wait_for_hyprland() {
  while ! pgrep -x "Hyprland" >/dev/null; do
    echo "[$(date)] Hyprland bekleniyor..."
    sleep 1
  done
  echo "[$(date)] Hyprland bulundu, devam ediliyor..."
}

# Ana işlem
main() {
  setup_logging
  wait_for_hyprland

  # Parametreleri işle
  while [[ $# -gt 0 ]]; do
    case $1 in
    --shader)
      SHADER_NAME="$2"
      SHADER_FILE="$SHADER_PATH/kenp-${SHADER_NAME}.glsl"
      shift 2
      ;;
    --strength)
      SHADER_STRENGTH="$2"
      shift 2
      ;;
    --no-restart)
      AUTO_RESTART=false
      shift
      ;;
    start)
      manage_hyprshade true
      if [ "$AUTO_RESTART" = true ]; then
        monitor_config_changes
      fi
      exit $?
      ;;
    stop)
      hyprshade off
      rm -f "$TOGGLE_FILE"
      notify-send -t 1000 -u low "Hyprshade Kapatıldı" "Shader devre dışı"
      update_waybar
      exit $?
      ;;
    toggle)
      if check_status &>/dev/null; then
        hyprshade off
        rm -f "$TOGGLE_FILE"
        notify-send -t 1000 -u low "Hyprshade Kapatıldı" "Shader devre dışı"
      else
        manage_hyprshade true
      fi
      update_waybar
      exit $?
      ;;
    status)
      show_status
      exit $?
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    *)
      echo "Geçersiz parametre: $1"
      usage
      exit 1
      ;;
    esac
  done

  # Eğer hiç parametre verilmemişse kullanım bilgisini göster
  usage
  exit 1
}

# Programı başlat
main "$@"
