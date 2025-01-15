#!/usr/bin/env bash
# monitor-brightness.sh

# Mevcut parlaklığı al
get_brightness() {
  ddcutil --bus 6 getvcp 10 | grep -oP 'current value =\s*\K\d+' || echo "0"
}

# Parametre kontrolü
case "$1" in
# Mevcut parlaklığı göster
"g" | "get")
  current=$(get_brightness)
  notify-send -t 1000 "Monitör Parlaklığı" "Mevcut: %$current"
  echo "Mevcut parlaklık: %$current"
  exit 0
  ;;
# Parlaklığı ayarla
[0-9]* | [1-9][0-9] | 100)
  brightness="$1"
  if [ "$brightness" -lt 0 ] || [ "$brightness" -gt 100 ]; then
    echo "Lütfen 0-100 arası bir değer girin"
    exit 1
  fi
  ddcutil --bus 6 setvcp 10 "$brightness"
  notify-send -t 1000 "Monitör Parlaklığı" "Yeni: %$brightness"
  ;;
*)
  echo "Kullanım: $0 [0-100 | g | get]"
  echo "Örnekler:"
  echo "  $0 70    # Parlaklığı %70'e ayarla"
  echo "  $0 g     # Mevcut parlaklığı göster"
  exit 1
  ;;
esac
