#!/usr/bin/env bash

# Dizin tanımlamaları
WOFI_DIR="$HOME/.config/wofi"

# Sabitler
divider="---------"
goback="Back"

## wofi_command fonksiyonunu güncelle
#wofi_command() {
#    wofi --dmenu \
#        --style "$WOFI_DIR/styles/bluetooth.css" \
#        --conf "$WOFI_DIR/configs/bluetooth" \
#        --cache-file=/dev/null \
#        --prompt "$1:" \
#        --insensitive
#}

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

# Güç durumu kontrolü
power_on() {
  if bluetoothctl show | grep -q "Powered: yes"; then
    return 0
  else
    return 1
  fi
}

# Güç durumu değiştirme
toggle_power() {
  if power_on; then
    bluetoothctl power off
    notify-send "Bluetooth" "Bluetooth turned off"
    show_menu
  else
    if rfkill list bluetooth | grep -q 'blocked: yes'; then
      rfkill unblock bluetooth && sleep 3
    fi
    bluetoothctl power on
    notify-send "Bluetooth" "Bluetooth turned on"
    show_menu
  fi
}

# Tarama durumu kontrolü
scan_on() {
  if bluetoothctl show | grep -q "Discovering: yes"; then
    echo "🔍 Scan: on"
    return 0
  else
    echo "🔍 Scan: off"
    return 1
  fi
}

# Tarama durumu değiştirme
toggle_scan() {
  if scan_on; then
    kill $(pgrep -f "bluetoothctl scan on")
    bluetoothctl scan off
    notify-send "Bluetooth" "Scanning stopped"
    show_menu
  else
    bluetoothctl scan on &
    notify-send "Bluetooth" "Scanning for devices..."
    sleep 5
    show_menu
  fi
}

# Cihaz bağlantı kontrolü
device_connected() {
  device_info=$(bluetoothctl info "$1")
  if echo "$device_info" | grep -q "Connected: yes"; then
    return 0
  else
    return 1
  fi
}

# Cihaz bağlantısını değiştirme
toggle_connection() {
  if device_connected "$1"; then
    bluetoothctl disconnect "$1"
    notify-send "Bluetooth" "Disconnected from $2"
  else
    bluetoothctl connect "$1"
    notify-send "Bluetooth" "Connected to $2"
  fi
  sleep 1
  device_menu "$3"
}

# Cihaz eşleşme kontrolü
device_paired() {
  device_info=$(bluetoothctl info "$1")
  if echo "$device_info" | grep -q "Paired: yes"; then
    echo "🔗 Paired: yes"
    return 0
  else
    echo "🔗 Paired: no"
    return 1
  fi
}

# Cihaz eşleşme durumunu değiştirme
toggle_paired() {
  if device_paired "$1"; then
    bluetoothctl remove "$1"
    notify-send "Bluetooth" "Unpaired from $2"
  else
    bluetoothctl pair "$1"
    notify-send "Bluetooth" "Paired with $2"
  fi
  sleep 1
  device_menu "$3"
}

# Cihaz güven kontrolü
device_trusted() {
  device_info=$(bluetoothctl info "$1")
  if echo "$device_info" | grep -q "Trusted: yes"; then
    echo "✓ Trusted: yes"
    return 0
  else
    echo "✗ Trusted: no"
    return 1
  fi
}

# Cihaz güven durumunu değiştirme
toggle_trust() {
  if device_trusted "$1"; then
    bluetoothctl untrust "$1"
    notify-send "Bluetooth" "Untrusted device $2"
  else
    bluetoothctl trust "$1"
    notify-send "Bluetooth" "Trusted device $2"
  fi
  sleep 1
  device_menu "$3"
}

# Ana menü fonksiyonunu güncelle
show_menu() {
  if power_on; then
    power="⚡ Power: on"
    devices=$(bluetoothctl devices | grep Device | cut -d ' ' -f 3-)
    scan=$(scan_on)

    options="$devices\n$divider\n$power\n$scan\nExit"
  else
    power="⚡ Power: off"
    options="$power\nExit"
  fi

  chosen="$(echo -e "$options" | wofi_command "Bluetooth")"
  # Çıkış kontrolü
  [[ -z "$chosen" ]] && exit 0

  case "$chosen" in
  "$power")
    toggle_power
    ;;
  "$scan")
    toggle_scan
    ;;
  *)
    device=$(bluetoothctl devices | grep "$chosen")
    if [[ $device ]]; then
      device_menu "$device"
    fi
    ;;
  esac
}

# Cihaz menüsü fonksiyonunu da güncelle
device_menu() {
  device=$1

  # Cihaz adı ve MAC adresi
  device_name=$(echo "$device" | cut -d ' ' -f 3-)
  mac=$(echo "$device" | cut -d ' ' -f 2)

  # Seçenekleri oluştur
  if device_connected "$mac"; then
    connected="📱 Connected: yes"
  else
    connected="📱 Connected: no"
  fi
  paired=$(device_paired "$mac")
  trusted=$(device_trusted "$mac")
  options="$connected\n$paired\n$trusted\n$divider\n$goback\nExit"

  # Wofi menüsünü aç
  chosen="$(echo -e "$options" | wofi_command "$device_name")"
  # Çıkış kontrolü
  [[ -z "$chosen" ]] && exit 0

  # Seçilen seçeneği işle
  case "$chosen" in
  "$connected")
    toggle_connection "$mac" "$device_name" "$device"
    ;;
  "$paired")
    toggle_paired "$mac" "$device_name" "$device"
    ;;
  "$trusted")
    toggle_trust "$mac" "$device_name" "$device"
    ;;
  "$goback")
    show_menu
    ;;
  "Exit")
    exit 0
    ;;
  esac
}

# Bluetooth config dosyası oluştur
mkdir -p "$WOFI_DIR/configs"
cat >"$WOFI_DIR/configs/bluetooth" <<EOF
width=400
height=500
location=center
show=dmenu
prompt=Bluetooth:
filter_rate=100
allow_markup=true
no_actions=true
line_wrap=word
insensitive=true
matching=contains
sort_order=default
gtk_dark=true
EOF

# Durum argümanı kontrolü
case "$1" in
--status)
  print_status
  ;;
*)
  show_menu
  ;;
esac
