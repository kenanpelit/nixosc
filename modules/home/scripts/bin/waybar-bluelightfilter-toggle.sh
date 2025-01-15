#!/usr/bin/env bash

# Gammastep uygulamasının çalışıp çalışmadığını kontrol et
if pgrep gammastep; then
  # Eğer çalışıyorsa, gammastep'i durdur
  pkill --signal SIGKILL gammastep

  # Durdurulduğuna dair bildirim gönder
  notify-send -u low "Gammastep Durduruldu" "Gammastep uygulaması kapatıldı."

  # Waybar'ı güncelle
  pkill -RTMIN+8 waybar
else
  # Gammastep ayarları
  MODE="wayland"             # Çalışma modu
  LOCATION="41.0108:29.0219" # Enlem:Boylam (manuel olarak ayarlanmış)
  TEMP_DAY=4500              # Gündüz renk sıcaklığı
  TEMP_NIGHT=4000            # Gece renk sıcaklığı
  BRIGHTNESS_DAY=0.7         # Gündüz parlaklık
  BRIGHTNESS_NIGHT=0.7       # Gece parlaklık
  GAMMA="1,0.2,0.1"          # RGB gamma ayarları

  # Gammastep'i başlat
  /usr/bin/gammastep -m "$MODE" -l manual -t "$TEMP_DAY:$TEMP_NIGHT" -b "$BRIGHTNESS_DAY:$BRIGHTNESS_NIGHT" -l "$LOCATION" -g "$GAMMA" >>/dev/null 2>&1 &

  # Bağımsız işlem haline getir
  disown

  # Başarı bildirimi
  notify-send -u low "Gammastep Başlatıldı" "Gündüz: $TEMP_DAY K, Gece: $TEMP_NIGHT K"
fi

# Monitör güncellemesi için Waybar'a sinyal gönder
pkill -RTMIN+8 waybar
