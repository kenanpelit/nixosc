#!/usr/bin/env bash
#######################################
#
# Version: 1.0.0
# Date: 2024-12-08
# Author: Kenan Pelit
# Repository: github.com/kenanpelit/dotfiles
# Description: HyprFlow Spotify Controller
#
# License: MIT
#
#######################################

# Spotify kontrolü için playerctl kullan
PLAYER="spotify"

# Spotify'ın çalışıp çalışmadığını kontrol et
if ! pgrep "$PLAYER" >/dev/null; then
  notify-send -t 2000 "Spotify" "❗ Spotify çalışmıyor, başlatılıyor..."
  start-spotify-default &
  exit 0
fi

# Spotify'ın hazır olmasını bekle (maksimum 5 saniye)
for i in {1..10}; do
  if playerctl -p spotify status &>/dev/null; then
    break
  fi
  sleep 0.5
done

# Mevcut durumu kontrol et
STATUS=$(playerctl -p spotify status 2>/dev/null)

case $STATUS in
"Playing")
  playerctl -p spotify pause
  notify-send -t 2000 "Spotify" "⏸ Durduruldu" -h string:x-canonical-private-synchronous:spotify-status
  ;;
"Paused")
  playerctl -p spotify play
  notify-send -t 2000 "Spotify" "▶ Oynatılıyor" -h string:x-canonical-private-synchronous:spotify-status
  ;;
*)
  # Spotify açık ama yanıt vermiyorsa
  notify-send -t 2000 "Spotify" "⚠️ Spotify yanıt vermiyor, yeniden başlatın" -h string:x-canonical-private-synchronous:spotify-status
  ;;
esac
