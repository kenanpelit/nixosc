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

# Bluetooth cihaz adresini tanımlıyoruz
device_address="E8:EE:CC:4D:29:00"
device_name="SL4" # Cihazın adı

# Cihazın bağlantı durumunu alıyoruz
connection_status=$(bluetoothctl info "$device_address" | grep "Connected:" | awk '{print $2}')

# Duruma göre bağlantı durumunu belirliyoruz
if [ "$connection_status" == "yes" ]; then
  status="connected"
else
  status="disconnected"
fi

# İlk bağlantı durumunu gösteriyoruz
echo "Device $device_name ($device_address) is currently $status"

# Bağlantıyı kesme ve ses ayarlama işlemleri
if [ "$connection_status" == "yes" ]; then
  echo "Disconnecting from $device_name ($device_address)..."
  bluetoothctl disconnect "$device_address" >/dev/null
  notify-send -t 5000 "$device_name Disconnected" "$device_name ($device_address) bağlantısı kesildi."
  status="disconnected"

  # Bağlantı kesildikten sonra varsayılan ses düzeylerini ayarlama
  default_sink=$(pactl get-default-sink)
  default_source=$(pactl get-default-source)

  if [ -n "$default_sink" ]; then
    pactl set-sink-volume "$default_sink" 15%
    echo "Varsayılan ses çıkışı $default_sink olarak %15 seviyesine ayarlandı."
  fi

  if [ -n "$default_source" ]; then
    pactl set-source-volume "$default_source" 0%
    echo "Varsayılan ses girişi $default_source olarak %0 seviyesine ayarlandı."
  fi
else
  # Cihaz bağlı değilse bağlantıyı sağlıyor ve ses ayarlarını yapıyoruz
  echo "Connecting to $device_name ($device_address)..."
  bluetoothctl connect "$device_address" >/dev/null
  notify-send -t 5000 "$device_name Connected" "$device_name ($device_address) bağlantısı kuruldu."
  status="connected"

  # Bluetooth cihazının tanımlanması için kısa bir bekleme süresi
  sleep 3

  # PulseAudio/PipeWire varsayılan profili Bluetooth için ayarlıyoruz
  bluetooth_sink=$(pactl list short sinks | grep -i "bluez" | awk '{print $1}')
  if [ -n "$bluetooth_sink" ]; then
    # Ses çıkışını Bluetooth cihazına yönlendir
    pactl set-default-sink "$bluetooth_sink"
    pactl set-sink-volume "$bluetooth_sink" 40%
    echo "Ses çıkışı Bluetooth cihazına ayarlandı: $bluetooth_sink"
  else
    echo "Bluetooth cihazı ses çıkışı olarak bulunamadı."
  fi

  bluetooth_source=$(pactl list short sources | grep -i "bluez" | awk '{print $1}')
  if [ -n "$bluetooth_source" ]; then
    # Ses girişini Bluetooth cihazına yönlendir
    pactl set-default-source "$bluetooth_source"
    pactl set-source-volume "$bluetooth_source" 5%
    echo "Ses girişi Bluetooth cihazına ayarlandı: $bluetooth_source"
  else
    echo "Bluetooth cihazı ses girişi olarak bulunamadı."
  fi
fi

# Son durumu gösteriyoruz
echo "Device $device_name ($device_address) is now $status"
