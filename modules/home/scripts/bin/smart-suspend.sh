#!/usr/bin/env bash

LOG_DIR="$HOME/.log"
LOG_FILE="$LOG_DIR/smart-suspend.log"
mkdir -p "$LOG_DIR"
touch "$LOG_FILE"

# Log rotasyonu
if [ -f "$LOG_FILE" ]; then
  for i in {4..1}; do
    if [ -f "$LOG_FILE.$i" ]; then
      mv "$LOG_FILE.$i" "$LOG_FILE.$((i + 1))"
    fi
  done
  mv "$LOG_FILE" "$LOG_FILE.1"
fi

exec 1> >(tee -a "$LOG_FILE")
exec 2>&1

echo "$(date): Hyprland suspend kontrolü başlatıldı"

# Hyprland spesifik fonksiyonlar
save_hyprland_state() {
  if command -v hyprctl >/dev/null 2>&1; then
    # Workspace bilgilerini kaydet
    hyprctl workspaces >"$HOME/.cache/hypr_workspace_state"
    # Aktif pencere bilgilerini kaydet
    hyprctl clients >"$HOME/.cache/hypr_clients_state"
    return 0
  else
    echo "Hyprctl bulunamadı"
    return 1
  fi
}

check_hyprland_active() {
  if [[ "$DESKTOP_SESSION" == *"hyprland"* ]] || [[ "$XDG_CURRENT_DESKTOP" == *"Hyprland"* ]]; then
    echo "Hyprland masaüstü ortamı tespit edildi"
    return 0
  else
    echo "Hyprland masaüstü ortamı bulunamadı!"
    return 1
  fi
}

check_battery() {
  if [ -d "/sys/class/power_supply/BAT0" ]; then
    battery_level=$(cat /sys/class/power_supply/BAT0/capacity)
    charging_status=$(cat /sys/class/power_supply/BAT0/status)
    echo "Pil seviyesi: $battery_level%"
    echo "Şarj durumu: $charging_status"
  fi
  return 0
}

check_processes() {
  important_processes=("rsync" "mv" "git" "npm" "yarn" "cargo")

  for proc in "${important_processes[@]}"; do
    if pgrep -f "$proc" >/dev/null; then
      echo "Önemli işlem çalışıyor: $proc"
      notify-send -u critical "Uyarı" "$proc işlemi çalışıyor. İşlem bitene kadar bekleyin."
      return 1
    fi
  done
  return 0
}

check_active_windows() {
  if command -v hyprctl >/dev/null 2>&1; then
    active_windows=$(hyprctl clients | grep -c "class:")
    if [ "$active_windows" -gt 0 ]; then
      echo "Aktif pencere sayısı: $active_windows"
      hyprctl clients | grep "class:" | cut -d'>' -f2 | while read -r window; do
        echo "Aktif pencere: $window"
      done
    fi
  fi
}

prepare_suspend() {
  # Hyprland özel hazırlıkları
  if command -v hyprctl >/dev/null 2>&1; then
    # Ekranı kitle
    hyprctl dispatch dpms off
    # Animasyonları geçici olarak kapat
    hyprctl animations disable
  fi

  # Ses seviyesini kaydet
  if command -v pamixer >/dev/null 2>&1; then
    current_volume=$(pamixer --get-volume)
    echo "$current_volume" >"$HOME/.cache/pre_suspend_volume"
  fi

  # Bluetooth durumunu kaydet
  if command -v bluetoothctl >/dev/null 2>&1; then
    bluetoothctl show | grep "Powered" >"$HOME/.cache/pre_suspend_bluetooth"
  fi
}

restore_after_wake() {
  # Hyprland özel restorasyon
  if command -v hyprctl >/dev/null 2>&1; then
    # Ekranı aç
    hyprctl dispatch dpms on
    # Animasyonları geri aç
    hyprctl animations enable
  fi

  # Ses seviyesini geri yükle
  if [ -f "$HOME/.cache/pre_suspend_volume" ]; then
    volume=$(cat "$HOME/.cache/pre_suspend_volume")
    pamixer --set-volume "$volume"
  fi

  # Bluetooth durumunu geri yükle
  if [ -f "$HOME/.cache/pre_suspend_bluetooth" ]; then
    if grep -q "Powered: yes" "$HOME/.cache/pre_suspend_bluetooth"; then
      bluetoothctl power on
    fi
  fi
}

main() {
  # Hyprland kontrolü
  check_hyprland_active || exit 1

  # Temel kontroller
  check_battery
  check_processes || exit 1

  # Aktif pencereleri göster
  check_active_windows

  # Suspend öncesi hazırlıklar
  echo "$(date): Suspend hazırlıkları başlatılıyor..."
  save_hyprland_state
  prepare_suspend

  echo "$(date): Sistem askıya alınıyor..."
  notify-send "Bilgi" "Sistem askıya alınıyor..."
  sleep 1

  # Suspend işlemi
  systemctl suspend

  # Uyanma sonrası işlemler
  restore_after_wake

  echo "$(date): Sistem uyandırıldı ve restore edildi"
  notify-send "Bilgi" "Sistem başarıyla uyandırıldı"
}

trap restore_after_wake SIGINT SIGTERM

main

exit 0
