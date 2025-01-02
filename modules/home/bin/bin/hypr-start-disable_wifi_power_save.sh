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

# Bağlı Wi-Fi arayüzünü bul
interface=$(iw dev | awk '$1=="Interface"{print $2}')

# Eğer arayüz bulunamazsa hata mesajı göster
if [ -z "$interface" ]; then
  notify-send -t 10000 "Hata" "Wi-Fi arayüzü bulunamadı."
  exit 1
fi

# Güç tasarrufunu kapat
sudo iw "$interface" set power_save off >>/dev/null 2>&1 &
disown

# Bildirim gönder
notify-send -t 10000 "Wi-Fi Güç Tasarrufu" "$interface için güç tasarrufu kapatıldı."
