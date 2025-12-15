#!/usr/bin/env bash
# hypr-airplane_mode.sh - Hyprland kablosuz/kablolu güç yönetimi toggle’ı
# rfkill/Wi‑Fi/Bluetooth durumunu değiştirip oturum bildirimleriyle haber verir.

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

# Wi-Fi durumu kontrol ediliyor
wifi_status=$(nmcli -t -f WIFI g)

if [[ "$wifi_status" == "enabled" ]]; then
  rfkill block all &
  notify-send -t 1000 "Airplane Mode: Active" "All wireless devices are disabled."
elif [[ "$wifi_status" == "disabled" ]]; then
  rfkill unblock all &
  notify-send -t 1000 "Airplane Mode: Inactive" "All wireless devices are enabled."
else
  notify-send -u critical -t 3000 "Error" "Failed to retrieve Wi-Fi status."
  exit 1
fi
