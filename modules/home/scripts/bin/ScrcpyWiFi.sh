#!/usr/bin/env bash

# Script to connect Linux to Android device over WiFi and mirror display

new_conn() {
  zenity --info \
    --text="Telefonu USB ile bilgisayara bağlayın. Telefonun kilidinin açık olduğundan emin olun.\n\nDevam etmek için Tamam'a tıklayın" \
    --title="Telefon Bağlantısı" \
    --width=300 \
    --height=150

  adb tcpip 5555
  sleep 3

  # Try multiple network interfaces
  for interface in wlan0 wlp2s0 wlp3s0; do
    ipadd=$(adb shell ip -f inet addr show $interface 2>/dev/null | grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}' | head -n 1)
    if [ ! -z "$ipadd" ]; then
      break
    fi
  done

  if [ -z "$ipadd" ]; then
    zenity --error --text="IP adresi bulunamadı. WiFi bağlantınızı kontrol edin." --width=250
    exit 1
  fi

  ipfull="${ipadd}:5555"
  mkdir -p "$HOME/.config/scrcpy"
  echo "$ipfull" >"$HOME/.config/scrcpy/ip.txt"

  adb connect "$ipfull"
  zenity --info \
    --text="USB kablosunu çıkarabilirsiniz.\n\nDevam etmek için Tamam'a tıklayın" \
    --title="WiFi Bağlantısı Kuruluyor" \
    --width=250 \
    --height=150
}

launch_scrcpy() {
  log="$HOME/.config/scrcpy/prog.log"

  # Enhanced scrcpy options for better performance
  scrcpy --max-fps 60 --bit-rate 16M --window-title "Android Ekranı" >"$log" 2>&1 &
  pid=$!

  sleep 3

  if grep -q "INFO" "$log"; then
    exit 0
  else
    zenity --info \
      --text="WiFi bağlantısı başarısız.\n\nTekrar denemek için Tamam'a tıklayın" \
      --title="Bağlantı Hatası" \
      --width=250 \
      --height=150

    kill $pid 2>/dev/null
    new_conn
    sleep 2

    scrcpy --max-fps 60 --bit-rate 16M --window-title "Android Ekranı" >"$log" 2>&1 &
    pid=$!
    sleep 3

    if ! grep -q "INFO" "$log"; then
      zenity --error \
        --text="WiFi bağlantısı tekrar başarısız oldu.\n\nÇıkış yapılıyor." \
        --title="Bağlantı Hatası" \
        --width=250 \
        --height=150
      kill $pid 2>/dev/null
      exit 1
    fi
  fi
}

main() {
  if ! command -v scrcpy >/dev/null; then
    zenity --error --text="scrcpy yüklü değil. Lütfen önce yükleyin." --width=250
    exit 1
  fi

  adb kill-server
  adb start-server

  if adb devices | grep -q "[0-9]\{1,3\}\.[0-9]\{1,3\}"; then
    launch_scrcpy
  else
    if [ -f "$HOME/.config/scrcpy/ip.txt" ]; then
      storedip=$(head -n 1 "$HOME/.config/scrcpy/ip.txt")
      if adb connect "$storedip" 2>/dev/null | grep -q "connected"; then
        launch_scrcpy
      else
        new_conn
        launch_scrcpy
      fi
    else
      new_conn
      launch_scrcpy
    fi
  fi
}

main
