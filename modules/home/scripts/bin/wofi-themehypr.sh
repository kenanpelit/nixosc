#!/usr/bin/env bash

# Dizin tanımlamaları
WOFI_DIR="$HOME/.config/wofi"
HYPR_CONFIG="$HOME/.config/hypr/config"
THEMES_FILE="$HYPR_CONFIG/04_themes.conf"

# Tema renk paletleri
declare -A THEMES=(
  ["🎭 Kenp"]="kenp"
  ["🌑 Mocha"]="mocha"
  ["🦇 Dracula"]="dracula"
  ["🌑 Macchiato"]="macchiato"
  ["🌑 Frappe"]="frappe"
  ["🌑 Latte"]="latte"
)

# Menüyü oluştur
generate_menu() {
  echo ">>> Current Theme"
  echo "📋 Show Active Theme"
  echo ""
  echo ">>> Available Themes"
  for theme in "${!THEMES[@]}"; do
    echo "$theme"
  done
}

# Menüyü göster
show_menu() {
  generate_menu | wofi \
    --dmenu \
    --style "$WOFI_DIR/styles/style.css" \
    --conf "$WOFI_DIR/configs/theme" \
    --cache-file=/dev/null \
    --prompt "Select Theme:" \
    --insensitive
}

# Mevcut temayı göster
show_current_theme() {
  local current_theme=$(grep "^source.*themes" "$THEMES_FILE" | sed 's/.*\/\([^/]*\)\.conf.*/\1/')
  notify-send "Current Theme" "Active theme: $current_theme"
}

# Temayı uygula
apply_theme() {
  local theme_name="$1"
  local theme_file="${THEMES[$theme_name]}.conf"

  # Tema dosyasının varlığını kontrol et
  if [[ ! -f "$HYPR_CONFIG/themes/$theme_file" ]]; then
    notify-send "Error" "Theme file not found: $theme_file"
    exit 1
  fi

  # 08_themes.conf dosyasını güncelle
  sed -i "s|source = .*themes/.*\.conf|source = $HYPR_CONFIG/themes/$theme_file|" "$THEMES_FILE"

  # Hyprland'ı yenile
  hyprctl reload

  notify-send "Theme Changed" "Applied $theme_name theme"
}

# Ana program
main() {
  # Tema seç
  local choice
  if ! choice=$(show_menu); then
    exit 0
  fi

  # Seçime göre işlem yap
  case "$choice" in
  "📋 Show Active Theme")
    show_current_theme
    ;;
  *)
    if [[ -n "$choice" ]] && [[ "$choice" != ">>> "* ]]; then
      apply_theme "$choice"
    fi
    ;;
  esac
}

main
