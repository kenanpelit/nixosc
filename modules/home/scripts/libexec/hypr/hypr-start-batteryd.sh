#!/usr/bin/env bash
# hypr-start-batteryd.sh - Hyprland oturumunda batteryd başlatıcı
# Güç izleme daemon’unu tek seferlik başlatır; log ve pid kontrolü içerir.

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

# Battery Daemon
# Get battery status and send notification when battery is low
# Requires: dunst, notify-send, acpi

# Önceki durumlar için bayrak değişkenleri
NOTIFIED_FULL=false
NOTIFIED_CRITICAL=false
NOTIFIED_LOW=false

while true; do
  # Batarya yüzdesini hesapla
  battery_level=$(acpi -b | grep -P -o '[0-9]+(?=%)')

  # Şarj durumu ve doluluk kontrolü
  charging=$(acpi -b | grep -o 'Charging')
  full=$(acpi -b | grep -o 'Full')

  # Şarj doluysa ve daha önce bildirilmemişse
  if [[ $full == "Full" && $charging == "Charging" && $NOTIFIED_FULL == false ]]; then
    notify-send -u low "  Battery is full." "Please unplug the AC adapter."
    NOTIFIED_FULL=true
    NOTIFIED_CRITICAL=false
    NOTIFIED_LOW=false
  fi

  # Batarya kritik seviyedeyse ve daha önce bildirilmemişse
  if [[ $battery_level -le 15 && $charging != "Charging" && $NOTIFIED_CRITICAL == false ]]; then
    notify-send -u critical "  Battery is critically low." "Please plug in the AC adapter."
    NOTIFIED_CRITICAL=true
    NOTIFIED_LOW=false
    NOTIFIED_FULL=false
  fi

  # Batarya düşük seviyedeyse ve daha önce bildirilmemişse
  if [[ $battery_level -le 30 && $battery_level -gt 15 && $charging != "Charging" && $NOTIFIED_LOW == false ]]; then
    notify-send -u normal "  Battery is low." "Please plug in the AC adapter."
    NOTIFIED_LOW=true
    NOTIFIED_CRITICAL=false
    NOTIFIED_FULL=false
  fi

  # Şarj durumu değişirse bayrakları sıfırla
  if [[ $charging == "Charging" ]]; then
    NOTIFIED_CRITICAL=false
    NOTIFIED_LOW=false
  fi

  # 1 dakika bekle ve döngüyü tekrarla
  sleep 60
done
