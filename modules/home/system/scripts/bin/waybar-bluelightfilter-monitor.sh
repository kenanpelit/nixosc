#!/usr/bin/env bash

# Gammastep uygulamasının çalışıp çalışmadığını kontrol et
if pgrep gammastep &>/dev/null; then
  # Eğer gammastep çalışıyorsa, aktivasyon durumu için çıktı
  echo '{"class": "activated", "tooltip": "Gammastep is active"}'
else
  # Eğer gammastep çalışmıyorsa, devre dışı durumu için çıktı
  echo '{"class": "", "tooltip": "Gammastep is deactivated"}'
fi
