#!/usr/bin/env bash
#######################################
#
# Version: 1.0.0
# Date: 2024-12-12
# Author: Kenan Pelit
# Repository: github.com/kenanpelit/dotfiles
# Description: ZenBrowserManager - Zen Browser Oturum Kapatma Aracı
#
# Bu script Zen Browser oturumlarını güvenli şekilde sonlandırmak için
# tasarlanmıştır. Temel özellikleri:
#
# - Tüm Zen Browser süreçlerini güvenli kapatma
# - Bildirim sistemi entegrasyonu
# - Sistemi kapatma seçenekleri:
#   - suspend: Sistemi uyku moduna alma
#   - reboot: Sistemi yeniden başlatma
#   - poweroff: Sistemi kapatma
#   - terminate: Kullanıcı oturumunu sonlandırma
#
# Kullanım:
# ./zen-close suspend|reboot|poweroff|terminate
#
# License: MIT
#
#######################################
# Zen-browser oturumlarını kapatma
echo "Kapatılıyor: Zen-browser oturumları..."
pkill -f "zen-browser"

sleep 3

# Uygulamanın sonlandığına dair bildirim
notify-send -t 5000 "Zen-browser" "Tüm Zen-browser oturumları kapatıldı."

# Eğer işlemlerden biri verilmişse onu çalıştır
if [ "$1" == "suspend" ]; then
  systemctl suspend -i
elif [ "$1" == "reboot" ]; then
  systemctl reboot -i
elif [ "$1" == "poweroff" ]; then
  systemctl poweroff -i
elif [ "$1" == "terminate" ]; then
  loginctl terminate-user "$USER"
else
  echo "Geçersiz işlem. Lütfen 'suspend', 'reboot', 'poweroff' veya 'terminate' girin."
fi
