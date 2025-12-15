#!/usr/bin/env bash
# mpc-control.sh - mpd/mpc kontrol kısayolu
# Çalma, duraklatma, ileri/geri ve ses ayarlarını hızlı komutlarla yönetir.

# İkon tanımlamaları (Nerd Font ikonları)
PLAY_ICON="󰐊"
PAUSE_ICON="󰏤"
STOP_ICON="󰓛"
NEXT_ICON="󰒭"
PREV_ICON="󰒮"
VOLUME_UP_ICON="󰝝"
VOLUME_DOWN_ICON="󰝞"
VOLUME_MUTE_ICON="󰝟"
MUSIC_ICON="󱍙"
ERROR_ICON="󰀩"

# Bildirim süreleri (milisaniye)
NOTIFY_TIMEOUT_NORMAL=3000 # Normal bildirimler
NOTIFY_TIMEOUT_SHORT=1500  # Ses değişimi
NOTIFY_TIMEOUT_LONG=5000   # Hata bildirimleri

# Renk tanımlamaları
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

# Song Info Format
format() {
  local info=$(mpc status -f "[[%artist% - ]%title%]|[%file%]" | head -n1)
  # Dosya adıysa .mp3 uzantısını kaldır
  echo "${info%.mp3}"
}

# Progress bar oluştur
create_progress_bar() {
  local current_time=$(mpc status | awk 'NR==2 {print $3}' | cut -d'/' -f1)
  local total_time=$(mpc status | awk 'NR==2 {print $3}' | cut -d'/' -f2)
  local percentage=$(mpc status | awk 'NR==2 {print $4}' | tr -d '()%')
  echo "$current_time / $total_time ($percentage%)"
}

# Gelişmiş notification gönder
send_notification() {
  local title="$1"
  local message="$2"
  local icon="$3"
  local timeout="$4"
  local urgency="$5"

  notify-send -t "${timeout:-$NOTIFY_TIMEOUT_NORMAL}" \
    -h string:x-canonical-private-synchronous:mpd \
    -u "${urgency:-normal}" \
    "$title" \
    "$message" \
    -i "$icon"
}

# Durum bilgisi
status() {
  local state=$(mpc status | sed -n 2p | awk '{print $1}' | tr -d '[]')
  local current_song="$(format)"
  local progress="$(create_progress_bar)"

  case $state in
  "playing")
    echo -e "${GREEN}$PLAY_ICON${NC} $current_song"
    send_notification \
      "$PLAY_ICON Şimdi Çalıyor" \
      "$current_song\n$progress" \
      "media-playback-start" \
      "$NOTIFY_TIMEOUT_NORMAL"
    ;;
  "paused")
    echo -e "${BLUE}$PAUSE_ICON${NC} $current_song"
    send_notification \
      "$PAUSE_ICON Duraklatıldı" \
      "$current_song\n$progress" \
      "media-playback-pause" \
      "$NOTIFY_TIMEOUT_NORMAL"
    ;;
  *)
    echo -e "${RED}$STOP_ICON${NC} Stopped"
    send_notification \
      "$STOP_ICON Durduruldu" \
      "MPD durduruldu" \
      "media-playback-stop" \
      "$NOTIFY_TIMEOUT_SHORT"
    ;;
  esac
}

# Ses kontrolü
volume() {
  local vol=$(mpc volume | cut -d':' -f2 | tr -d ' %')
  local vol_icon

  if [ "$vol" -ge 70 ]; then
    vol_icon="󰕾"
  elif [ "$vol" -ge 30 ]; then
    vol_icon="󰖀"
  else
    vol_icon="󰕿"
  fi

  echo "$vol%"
  return "$vol"
}

# Kullanım mesajı
usage() {
  echo "Kullanım: $(basename "$0") [KOMUT]"
  echo
  echo "Komutlar:"
  echo "  toggle    - Oynat/Duraklat"
  echo "  play      - Oynat"
  echo "  pause     - Duraklat"
  echo "  stop      - Durdur"
  echo "  next      - Sonraki parça"
  echo "  prev      - Önceki parça"
  echo "  status    - Durum bilgisi"
  echo "  vol up    - Sesi artır"
  echo "  vol down  - Sesi azalt"
  echo "  help      - Bu mesajı göster"
  exit 1
}

# Ana kontrol fonksiyonu
case "$1" in
"toggle")
  mpc toggle >/dev/null
  status
  ;;
"play")
  mpc play >/dev/null
  status
  ;;
"pause")
  mpc pause >/dev/null
  status
  ;;
"stop")
  mpc stop >/dev/null
  status
  ;;
"next")
  mpc next >/dev/null
  song_info="$(format)"
  progress="$(create_progress_bar)"
  echo -e "$NEXT_ICON $song_info"
  send_notification \
    "$NEXT_ICON Sonraki Parça" \
    "$song_info\n$progress" \
    "media-skip-forward" \
    "$NOTIFY_TIMEOUT_NORMAL"
  ;;
"prev")
  mpc prev >/dev/null
  song_info="$(format)"
  progress="$(create_progress_bar)"
  echo -e "$PREV_ICON $song_info"
  send_notification \
    "$PREV_ICON Önceki Parça" \
    "$song_info\n$progress" \
    "media-skip-backward" \
    "$NOTIFY_TIMEOUT_NORMAL"
  ;;
"status")
  status
  ;;
"vol")
  case "$2" in
  "up")
    mpc volume +5 >/dev/null
    vol=$(volume)
    send_notification \
      "$VOLUME_UP_ICON Ses Artırıldı" \
      "Ses Seviyesi: $vol" \
      "audio-volume-high" \
      "$NOTIFY_TIMEOUT_SHORT"
    echo "$vol"
    ;;
  "down")
    mpc volume -5 >/dev/null
    vol=$(volume)
    send_notification \
      "$VOLUME_DOWN_ICON Ses Azaltıldı" \
      "Ses Seviyesi: $vol" \
      "audio-volume-low" \
      "$NOTIFY_TIMEOUT_SHORT"
    echo "$vol"
    ;;
  *)
    volume
    ;;
  esac
  ;;
*)
  usage
  ;;
esac
