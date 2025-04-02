#!/usr/bin/env bash
#######################################
#
# Version: 1.0.0
# Date: 2024-12-12
# Author: Kenan Pelit
# Repository: github.com/kenanpelit/dotfiles
# Description: TmuxSessionManager - Özelleştirilmiş Tmux Oturum Başlatıcı
#
# Bu script otomatik tmux oturum yönetimi için tasarlanmıştır.
# Temel özellikleri:
# - Var olan oturumlara otomatik bağlanma
# - Yeni oturumlar için özelleştirilmiş başlatma
# - Her oturum için özel dizin ve komut yapılandırması
# - t3 pencere desteği
#
# Desteklenen Oturumlar:
# - KENP, CTA: Ana geliştirme oturumları
# - Downloads: Dosya yönetimi için ranger
# - Music: Müzik kontrolü için ncmpcpp
# - Project: Proje geliştirme ortamı
# - Ranger: Dosya gezgini
# - SSH: Uzak bağlantı yönetimi
# - TmuxConfig: Tmux yapılandırması
# - Tor: Tor projesi geliştirme
# - Update: Sistem güncelleme
# - Vim: Metin düzenleme
#
# License: MIT
#
#######################################
# Terminal ve kullanıcı shell ayarları
export TERM=xterm-256color
USER_SHELL="$(getent passwd "$(id -u)")"
USER_SHELL="${USER_SHELL##*:}"

# Ana oturum fonksiyonu
create_or_attach_session() {
  local session_name=$1
  local session=$(tmux ls 2>/dev/null | grep "^${session_name}:")

  if [[ $session == *"${session_name}: attached"* ]]; then
    echo "Oturum '${session_name}' zaten bağlı, yeni bir shell başlatılıyor..."
    "$USER_SHELL"
    return
  elif [[ $session == *"${session_name}:"* ]]; then
    echo "Oturum '${session_name}' mevcut, oturuma bağlanılıyor..."
    tmux attach-session -t "$session_name"
    return
  fi

  echo "Oturum '${session_name}' mevcut değil, yeni bir tmux oturumu başlatılıyor..."
  return 1
}

# t3 komutu için yardımcı fonksiyon
create_t3_window() {
  local session_name=$1
  tmux new-window -t "$session_name" -c "#{pane_current_path}"
  tmux send-keys -t "$session_name" "t3" C-m
}

# Ana oturumlar için kontrol
create_or_attach_session "KENP" || {
  # KENP01 oturumu
  tmux new-session -d -s "KENP"
  create_t3_window "KENP"

  # CTA oturumu
  tmux new-session -d -s "CTA"
  create_t3_window "CTA"

  # Diğer oturumlar (alfabetik sıralı)
  tmux new-session -d -s "Downloads" -c ~/Downloads
  tmux send-keys -t "Downloads" "ranger" C-m

  tmux new-session -d -s "Music" -c ~/Music
  tmux send-keys -t "Music" "ncmpcpp" C-m

  tmux new-session -d -s "Project" -c ~/.projects
  create_t3_window "Project"

  tmux new-session -d -s "Ranger" -c ~/
  tmux send-keys -t "Ranger" "ranger" C-m

  tmux new-session -d -s "SSH" -c ~/
  create_t3_window "SSH"

  tmux new-session -d -s "TmuxConfig" -c ~/.tmux
  tmux send-keys -t "TmuxConfig" "nvim ~/.config/tmux/tmux.conf.local" C-m

  tmux new-session -d -s "Tor" -c /repo/tor
  create_t3_window "Tor"

  tmux new-session -d -s "Update" -c ~/
  tmux send-keys -t "Update" "upall" C-m

  # Yeni Vim oturumu
  tmux new-session -d -s "Vim" -c ~/
  tmux send-keys -t "Vim" "nvim" C-m

  # Ana oturuma bağlan
  tmux attach-session -t "KENP"
}
