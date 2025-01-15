#!/usr/bin/env bash

# Dizin tanımlamaları
WOFI_DIR="$HOME/.config/wofi"
SCRIPTS_DIR="$HOME/.bin"

# Menü öğelerini oluştur
generate_menu() {
  echo ">>> Terminals"
  echo "⌨️  Kitty"
  echo "⌨️  Alacritty"
  echo "⌨️  Foot"
  echo ""
  echo ">>> Options"
  echo "🔍 Float"
  echo "📏 Tiled"
}

# Menüyü göster
show_menu() {
  generate_menu | wofi \
    --dmenu \
    --style "$WOFI_DIR/styles/style.css" \
    --conf "$WOFI_DIR/configs/size-small" \
    --cache-file=/dev/null \
    --prompt "Terminal:"
}

# Seçimi işle
handle_selection() {
  case "$1" in
  "⌨️  Kitty")
    exec kitty
    ;;
  "⌨️  Alacritty")
    exec alacritty
    ;;
  "⌨️  Foot")
    exec foot
    ;;
  "🔍 Float")
    hyprctl dispatch togglefloating
    ;;
  "📏 Tiled")
    hyprctl dispatch pseudo
    ;;
  esac
}

# Ana program
main() {
  # Terminal varlığını kontrol et
  for term in kitty alacritty foot; do
    if ! command -v "$term" &>/dev/null; then
      notify-send "Warning" "$term is not installed"
    fi
  done

  # Menüyü göster ve seçimi işle
  if choice=$(show_menu); then
    [[ -n "$choice" ]] && handle_selection "$choice"
  fi
}

# Programı çalıştır
main
