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

# VLC'yi kontrol et ve durumu değiştir
playerctl --player=vlc play-pause

# Şu anki medya bilgisini al (Başlık ve sanatçı gibi)
title=$(playerctl --player=vlc metadata title)
artist=$(playerctl --player=vlc metadata artist)
state=$(playerctl --player=vlc status)

# Bildirim mesajını oluştur
if [ "$state" == "Playing" ]; then
  notification="🎶 Oynatılıyor: $title - $artist"
else
  notification="⏸️ Duraklatıldı: $title - $artist"
fi

# Bildirimi göster
notify-send "$notification" --icon=media-playback-* --urgency=normal
