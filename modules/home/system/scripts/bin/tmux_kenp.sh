#!/usr/bin/env bash
#######################################
#
# Version: 1.0.0
# Date: 2024-12-12
# Author: Kenan Pelit
# Repository: github.com/kenanpelit/dotfiles
# Description: KENPSession - Ana Geliştirme Ortamı için Tmux Oturum Yöneticisi
#
# Bu script ana geliştirme ortamı (KENP) için özel bir tmux oturum yöneticisidir.
# Temel özellikleri:
# - Mevcut KENP oturumunu kontrol etme
# - Bağlı oturuma yeni shell açma
# - Bağlı olmayan oturuma otomatik bağlanma
# - Oturum yoksa yeni oturum oluşturma
#
# İşleyiş:
# - Bağlı oturum varsa: Yeni shell başlatır
# - Bağsız oturum varsa: Oturuma bağlanır
# - Oturum yoksa: Yeni oturum oluşturur
#
# License: MIT
#
#######################################
# Oturum adı
SESSION_NAME="KENP"

# Terminal ve kullanıcı shell bilgisi
export TERM=xterm-256color
USER_SHELL="$(getent passwd "$(id -u)")"
USER_SHELL="${USER_SHELL##*:}"

# Tmux oturumunun durumunu kontrol etme
session=$(tmux ls 2>/dev/null | grep "^${SESSION_NAME}:")

# Oturum durumuna göre işlem yapma
if [[ $session == *"${SESSION_NAME}: attached"* ]]; then
  # Oturum zaten bağlıysa yeni bir shell başlat
  echo "Oturum '${SESSION_NAME}' zaten bağlı, yeni bir shell başlatılıyor..."
  "$USER_SHELL"
elif [[ $session == *"${SESSION_NAME}:"* ]]; then
  # Oturum mevcut fakat bağlı değilse, oturuma bağlan
  echo "Oturum '${SESSION_NAME}' mevcut, oturuma bağlanılıyor..."
  tmux attach-session -t "$SESSION_NAME"
else
  # Oturum yoksa yeni oturum başlat
  echo "Oturum '${SESSION_NAME}' mevcut değil, yeni bir tmux oturumu başlatılıyor..."
  tmux new-session -A -s "$SESSION_NAME"
fi
