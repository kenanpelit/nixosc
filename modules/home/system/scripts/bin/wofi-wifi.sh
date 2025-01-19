#!/usr/bin/env bash

# Dizin tanımlamaları
WOFI_DIR="$HOME/.config/wofi"
CACHE_DIR="/tmp/wofi-wifi"

# Cache dizinini oluştur
mkdir -p "$CACHE_DIR"

# WiFi menüsünü göster
show_wifi_menu() {
  notify-send "WiFi" "Getting list of available Wi-Fi networks..."
  sleep 1

  # WiFi taraması yap
  nmcli device wifi rescan

  # WiFi durumunu kontrol et
  connected=$(nmcli -fields WIFI g)
  if [[ "$connected" =~ "enabled" ]]; then
    toggle="睊  Disable Wi-Fi"
  elif [[ "$connected" =~ "disabled" ]]; then
    toggle="直  Enable Wi-Fi"
  fi

  # WiFi listesini al ve sinyal gücüne göre sırala
  wifi_list=$(nmcli --fields SIGNAL,SECURITY,SSID device wifi list | sort -nr |
    awk '{ if (NR!=1) { 
                    signal=$1; 
                    sec=$2; 
                    # Remove first two fields and whitespace
                    $1=""; $2=""; sub(/^[ \t]+/, "");
                    # Get the SSID
                    ssid=$0;
                    # Add signal strength indicator
                    if(signal >= 75) indicator="󰤨";
                    else if(signal >= 50) indicator="󰤥";
                    else if(signal >= 25) indicator="󰤢";
                    else indicator="󰤟";
                    # Add lock symbol if secured
                    if(sec != "--") extra="🔒";
                    else extra="";
                    printf "%s %s %s\n", indicator, extra, ssid
                }}')

  # Wofi menüsünü göster
  echo -e "$toggle\n$wifi_list" | uniq -u | wofi \
    --dmenu \
    --style "$WOFI_DIR/styles/style.css" \
    --conf "$WOFI_DIR/configs/wifi" \
    --cache-file=/dev/null \
    --prompt "Select WiFi:" \
    --insensitive
}

# Şifre giriş menüsünü göster
get_password() {
  local ssid="$1"
  local password_file="$CACHE_DIR/password_input"

  # Şifre girişi için geçici dosya oluştur
  echo "" >"$password_file"

  # Şifre girişi için wofi'yi başlat
  echo "" | wofi \
    --dmenu \
    --style "$WOFI_DIR/styles/style.css" \
    --conf "$WOFI_DIR/configs/wifi" \
    --cache-file=/dev/null \
    --prompt "Enter password for $ssid:" \
    --password >"$password_file"

  # Şifreyi oku ve geçici dosyayı sil
  local password=$(cat "$password_file")
  rm -f "$password_file"

  echo "$password"
}

# Ana işlemler
main() {
  # WiFi seçimini al
  chosen_network=$(show_wifi_menu)

  # Çıkış kontrolü
  [[ -z "$chosen_network" ]] && exit 0

  # SSID'yi ayıkla
  if [[ "$chosen_network" =~ "🔒" ]]; then
    chosen_id=$(echo "$chosen_network" | sed 's/^.*🔒 //')
  else
    chosen_id=$(echo "$chosen_network" | sed 's/^.* //')
  fi
  chosen_id=$(echo "$chosen_id" | xargs) # Boşlukları temizle

  case "$chosen_network" in
  *"Enable Wi-Fi"*)
    nmcli radio wifi on
    notify-send "WiFi" "WiFi enabled"
    ;;
  *"Disable Wi-Fi"*)
    nmcli radio wifi off
    notify-send "WiFi" "WiFi disabled"
    ;;
  *)
    # Kayıtlı bağlantıları kontrol et
    if nmcli -g NAME connection show | grep -q "^${chosen_id}$"; then
      notify-send "WiFi" "Connecting to saved network: $chosen_id"
      nmcli connection up "$chosen_id" &&
        notify-send "WiFi" "Connected to $chosen_id"
    else
      if [[ "$chosen_network" =~ "🔒" ]]; then
        # Şifre iste
        wifi_password=$(get_password "$chosen_id")

        if [[ -n "$wifi_password" ]]; then
          notify-send "WiFi" "Connecting to: $chosen_id"
          nmcli device wifi connect "$chosen_id" password "$wifi_password" &&
            notify-send "WiFi" "Connected to $chosen_id" ||
            notify-send "Error" "Failed to connect to $chosen_id"
        else
          notify-send "Cancelled" "No password entered"
        fi
      else
        # Açık ağa bağlan
        notify-send "WiFi" "Connecting to open network: $chosen_id"
        nmcli device wifi connect "$chosen_id" &&
          notify-send "WiFi" "Connected to $chosen_id" ||
          notify-send "Error" "Failed to connect to $chosen_id"
      fi
    fi
    ;;
  esac
}

# Programı başlat
main
