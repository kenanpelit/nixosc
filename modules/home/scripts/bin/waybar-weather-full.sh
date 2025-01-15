#!/usr/bin/env bash

# Terminal karakter kodlamasını UTF-8 olarak ayarla
export LANG=tr_TR.UTF-8
export LC_ALL=tr_TR.UTF-8

# Geçici dosya oluştur
TMP_FILE="/tmp/weather_full.txt"

# Daha basit ve temiz bir format kullan
curl -s "wttr.in/Istanbul?lang=tr&format=%l:+%c+%t,+%h+nem,+%w+rüzgar\n3+günlük+tahmin:\n%f" >"$TMP_FILE"

# Wofi ile görüntüle
cat "$TMP_FILE" |
  wofi --dmenu \
    --style "$HOME/.config/wofi/styles/weather.css" \
    --cache-file=/dev/null \
    --prompt "Hava Durumu:" \
    --width 520 \
    --height 200 \
    --location center \
    --no-actions \
    --insensitive

# Geçici dosyayı temizle
rm -f "$TMP_FILE"
