#!/usr/bin/env bash

# Dizin tanımlamaları
WOFI_DIR="$HOME/.config/wofi"
SCRIPTS_DIR="$HOME/.bin"

# Menü öğelerini oluştur
generate_menu() {
  echo ">>> Settings"
  echo "⚙️  System Settings"
  echo "🖥️  Monitor Layout"
  echo "🎨 Theme Switcher"
  echo ""
  echo ">>> Network"
  echo "📶 WiFi Settings"
  echo "🔄 Restart Network"
  echo ""
  echo ">>> Bluetooth"
  echo "󰂯 Bluetooth Settings"
  echo "🔄 Restart Bluetooth"
}

# Menüyü göster
show_menu() {
  generate_menu | wofi \
    --dmenu \
    --style "$WOFI_DIR/styles/style.css" \
    --conf "$WOFI_DIR/configs/system" \
    --cache-file=/dev/null \
    --prompt "System:"
}

# Seçimi işle
handle_selection() {
  case "$1" in
  "⚙️  System Settings")
    if command -v gnome-control-center &>/dev/null; then
      XDG_CURRENT_DESKTOP=gnome gnome-control-center
    else
      notify-send "Error" "gnome-control-center is not installed"
    fi
    ;;
  "🖥️  Monitor Layout")
    if [[ -x "$SCRIPTS_DIR/monitor_layout.sh" ]]; then
      "$SCRIPTS_DIR/monitor_layout.sh"
    else
      notify-send "Error" "monitor_layout.sh not found or not executable"
    fi
    ;;
  "🎨 Theme Switcher")
    if [[ -x "$SCRIPTS_DIR/wofi-themewofi.sh" ]]; then
      "$SCRIPTS_DIR/wofi-themewofi.sh"
    else
      notify-send "Error" "wofi-themewofi.sh not found or not executable"
    fi
    ;;
  "📶 WiFi Settings")
    if command -v nm-connection-editor &>/dev/null; then
      nm-connection-editor
    else
      notify-send "Error" "nm-connection-editor is not installed"
    fi
    ;;
  "🔄 Restart Network")
    if command -v pkexec &>/dev/null; then
      pkexec systemctl restart NetworkManager
      notify-send "Network" "NetworkManager restarted"
    else
      notify-send "Error" "pkexec is not installed"
    fi
    ;;
  "󰂯 Bluetooth Settings")
    if command -v blueman-manager &>/dev/null; then
      blueman-manager
    else
      notify-send "Error" "blueman-manager is not installed"
    fi
    ;;
  "🔄 Restart Bluetooth")
    if command -v pkexec &>/dev/null; then
      pkexec systemctl restart bluetooth
      notify-send "Bluetooth" "Bluetooth service restarted"
    else
      notify-send "Error" "pkexec is not installed"
    fi
    ;;
  esac
}

# Ana program
main() {
  # Gerekli programları kontrol et
  local missing_deps=()

  for cmd in gnome-control-center nm-connection-editor blueman-manager pkexec; do
    if ! command -v "$cmd" &>/dev/null; then
      missing_deps+=("$cmd")
    fi
  done

  # Gerekli scriptleri kontrol et
  for script in "$SCRIPTS_DIR/monitor_layout.sh" "$SCRIPTS_DIR/theme_switcher.sh"; do
    if [[ ! -x "$script" ]]; then
      missing_deps+=("${script##*/}")
    fi
  done

  #  # Eksik bağımlılıklar varsa bildir
  #  if [ ${#missing_deps[@]} -ne 0 ]; then
  #    notify-send "Warning" "Missing commands/scripts:\n${missing_deps[*]}"
  #  fi

  # Menüyü göster ve seçimi işle
  if choice=$(show_menu); then
    [[ -n "$choice" ]] && handle_selection "$choice"
  fi
}

# Programı çalıştır
main
