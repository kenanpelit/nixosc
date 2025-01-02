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

# Paru uygulamasının mevcut olup olmadığını kontrol et
if ! command -v paru &>/dev/null; then
  notify-send -t 5000 "Hata" "Paru uygulaması bulunamadı."
  echo "Paru uygulaması bulunamadı."
  exit 1
fi

# Güncelleme işlemini Kitty terminalinde başlat
/usr/bin/kitty --class update -T update --hold -e /usr/bin/paru -Syu --noconfirm

# Güncelleme tamamlandığında bildirim gönder
notify-send -i '/usr/share/icons/hicolor/256x256/apps/kitty.png' 'Kitty Terminal' 'Güncelleme tamamlandı! Nice!!!'
