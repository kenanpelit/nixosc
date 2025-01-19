#!/usr/bin/env bash

# Dizin tanımlamaları
WOFI_DIR="$HOME/.config/wofi"

# Wofi komutu
wofi_command() {
  wofi --dmenu \
    --style "$WOFI_DIR/styles/bluetooth.css" \
    --conf "$WOFI_DIR/configs/bluetooth" \
    --cache-file=/dev/null \
    --prompt "$1:" \
    --width 400 \
    --height 500 \
    --location center \
    --insensitive
}

case $1 in
"toggle")
  if bluetoothctl show | grep -q "Powered: no"; then
    bluetoothctl power on
    notify-send -i bluetooth "Bluetooth" "Bluetooth açıldı" -h string:x-canonical-private-synchronous:bluetooth
  else
    bluetoothctl power off
    notify-send -i bluetooth "Bluetooth" "Bluetooth kapatıldı" -h string:x-canonical-private-synchronous:bluetooth
  fi
  ;;
"menu")
  # Özel sağ tık menüsü
  choice=$(echo -e "🔍 Cihazları Tara\n🔄 Yeniden Başlat\n📱 Bilinen Cihazlar\n⚙️ Ayarlar\n❌ Tüm Bağlantıları Kes" | wofi_command "Bluetooth Menü")
  case $choice in
  "🔍 Cihazları Tara")
    bluetoothctl scan on &
    sleep 10
    killall bluetoothctl
    notify-send "Bluetooth" "Tarama tamamlandı"
    ;;
  "🔄 Yeniden Başlat")
    systemctl restart bluetooth
    notify-send "Bluetooth" "Bluetooth servisi yeniden başlatıldı"
    ;;
  "📱 Bilinen Cihazlar")
    device=$(bluetoothctl devices | cut -d ' ' -f3- | wofi_command "Cihaz Seç")
    if [ ! -z "$device" ]; then
      mac=$(bluetoothctl devices | grep "$device" | cut -d ' ' -f2)
      bluetoothctl connect $mac
    fi
    ;;
  "⚙️ Ayarlar")
    blueberry
    ;;
  "❌ Tüm Bağlantıları Kes")
    bluetoothctl disconnect
    notify-send "Bluetooth" "Tüm bağlantılar kesildi"
    ;;
  esac
  ;;
"connect")
  device=$(bluetoothctl devices | cut -d ' ' -f3- | wofi_command "Bağlan")
  if [ ! -z "$device" ]; then
    mac=$(bluetoothctl devices | grep "$device" | cut -d ' ' -f2)
    bluetoothctl connect $mac
  fi
  ;;
"disconnect")
  device=$(bluetoothctl info | grep "Name" | cut -d ' ' -f2-)
  if [ ! -z "$device" ]; then
    bluetoothctl disconnect
    notify-send "Bluetooth" "$device bağlantısı kesildi"
  fi
  ;;
esac
