#!/usr/bin/env bash
#######################################
#
# Version: 1.0.0
# Date: 2024-12-08
# Author: Kenan Pelit
# Repository: github.com/kenanpelit/dotfiles
# Description: HyprFlow
#
# License: MIT
#
#######################################

# Konfigürasyon dosyaları
MONITOR_CONFIG="$HOME/.config/hypr/config/02_monitor.conf"
CONFIG_STATE="$HOME/.monitor_config_state"

# Dell monitör ayarları
DELL_MONITOR_2K="monitor=desc:Dell Inc. DELL UP2716D KRXTR88N909L,2560x1440@59,0x0,1"
DELL_MONITOR_FHD="monitor=desc:Dell Inc. DELL UP2716D KRXTR88N909L,1920x1080@59,0x0,1"

# AU Optronics monitör ayarları
AU_MONITOR_2K="monitor=desc:AU Optronics 0x2036,2560x1440@60,0x1440,1"
AU_MONITOR_FHD="monitor=desc:AU Optronics 0x2036,1920x1080@60,320x1440,1"

# Workspace ayarları
WORKSPACE_CONFIG="
workspace = 1, monitor:DELL UP2716D KRXTR88N909L,1, default:true
workspace = 2, monitor:DELL UP2716D KRXTR88N909L,2
workspace = 3, monitor:DELL UP2716D KRXTR88N909L,3
workspace = 4, monitor:DELL UP2716D KRXTR88N909L,4
workspace = 5, monitor:DELL UP2716D KRXTR88N909L,5
workspace = 6, monitor:DELL UP2716D KRXTR88N909L,6
workspace = 7, monitor:AU Optronics 0x2036,7, default:true
workspace = 8, monitor:AU Optronics 0x2036,8
workspace = 9, monitor:AU Optronics 0x2036,9"

# Başlık yorumu
HEADER="# █▀▄▀█ █▀█ █▄░█ █ ▀█▀ █▀█ █▀█
# █░▀░█ █▄█ █░▀█ █ ░█░ █▄█ █▀▄
# ===========================
# Monitör Yapılandırmaları
# ==========================="

# Yardım mesajı
show_help() {
  echo "Kullanım: $0 [seçenek]"
  echo "Seçenekler:"
  echo "  1  Her iki monitör 2560x1440 (2K)"
  echo "  2  Her iki monitör 1920x1080 (FHD)"
  echo "  3  Dell: 2560x1440 (2K), AU: 1920x1080 (FHD)"
  echo "  t  Toggle modu (Sırayla geçiş yapar)"
  echo "  h  Bu yardım mesajını gösterir"
  exit 1
}

# Yeni konfigürasyonu oluştur
create_config() {
  local dell_monitor=$1
  local au_monitor=$2
  local config_num=$3

  echo "$HEADER" >"$MONITOR_CONFIG"
  echo "" >>"$MONITOR_CONFIG"
  echo "$dell_monitor" >>"$MONITOR_CONFIG"
  echo "$au_monitor" >>"$MONITOR_CONFIG"
  echo "" >>"$MONITOR_CONFIG"
  echo "# Çalışma Alanı Yapılandırmaları" >>"$MONITOR_CONFIG"
  echo "$WORKSPACE_CONFIG" >>"$MONITOR_CONFIG"

  echo "$config_num" >"$CONFIG_STATE"
}

# Toggle fonksiyonu
toggle_config() {
  current_config=$(cat "$CONFIG_STATE" 2>/dev/null || echo "1")

  if [ "$current_config" == "1" ]; then
    set_config "2"
  elif [ "$current_config" == "2" ]; then
    set_config "3"
  else
    set_config "1"
  fi
}

# Belirli bir konfigürasyonu ayarla
set_config() {
  local config_num=$1
  case $config_num in
  1)
    create_config "$DELL_MONITOR_2K" "$AU_MONITOR_2K" "1"
    echo "Konfigürasyon 1 aktif edildi (Her iki monitör 2560x1440)"
    ;;
  2)
    create_config "$DELL_MONITOR_FHD" "$AU_MONITOR_FHD" "2"
    echo "Konfigürasyon 2 aktif edildi (Her iki monitör 1920x1080)"
    ;;
  3)
    create_config "$DELL_MONITOR_2K" "$AU_MONITOR_FHD" "3"
    echo "Konfigürasyon 3 aktif edildi (Dell: 2560x1440, AU: 1920x1080)"
    ;;
  *)
    echo "Geçersiz konfigürasyon numarası: $config_num"
    show_help
    exit 1
    ;;
  esac

  # Hyprland'ı yeniden yükle
  hyprctl reload
}

# Parametre kontrolü
case $1 in
1 | 2 | 3)
  set_config "$1"
  ;;
t | T | -t | --toggle)
  toggle_config
  ;;
h | -h | --help | "")
  show_help
  ;;
*)
  echo "Geçersiz parametre: $1"
  show_help
  ;;
esac
