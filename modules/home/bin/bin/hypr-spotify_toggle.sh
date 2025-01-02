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

# Spotify çalışıyor mu kontrol et
if pgrep -x "spotify" >/dev/null; then
  # Spotify çalıyor mu kontrol et
  STATUS=$(dbus-send --print-reply --dest=org.mpris.MediaPlayer2.spotify /org/mpris/MediaPlayer2 \
    org.freedesktop.DBus.Properties.Get string:"org.mpris.MediaPlayer2.Player" string:"PlaybackStatus" |
    grep -o "Playing\|Paused")
  if [ "$STATUS" == "Playing" ]; then
    # Oynuyorsa durdur
    dbus-send --print-reply --dest=org.mpris.MediaPlayer2.spotify /org/mpris/MediaPlayer2 \
      org.mpris.MediaPlayer2.Player.Pause
    echo "Spotify durduruldu."
    notify-send -t 2000 "Spotify" "⏸ Durduruldu"
  else
    # Duruyorsa oynat
    dbus-send --print-reply --dest=org.mpris.MediaPlayer2.spotify /org/mpris/MediaPlayer2 \
      org.mpris.MediaPlayer2.Player.Play
    echo "Spotify oynatılıyor."
    notify-send -t 2000 "Spotify" "▶  Oynatılıyor"
  fi
else
  # Spotify çalışmıyorsa başlat
  echo "Spotify çalışmıyor, başlatılıyor..."
  notify-send -t 2000 "Spotify" "❗ Spotify çalışmıyor, başlatılıyor..."
  $HOME/.config/hypr/scripts/start-spotify.sh
  sleep 5 # Spotify'ın açılması için kısa bir bekleme süresi
  notify-send -t 2000 "Spotify" "▶ Spotify başlatıldı"
fi
