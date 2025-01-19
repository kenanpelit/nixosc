#!/usr/bin/env bash

# Dizin tanımlamaları
WOFI_DIR="$HOME/.config/wofi"

# Varsayılan font boyutları
SIZES=(
  "12px - Tiny"
  "14px - Small"
  "16px - Default"
  "18px - Medium"
  "20px - Large"
  "22px - Extra Large"
  "24px - Huge"
)

# Menüyü göster
show_menu() {
  printf "%s\n" \
    ">>> Current Size" \
    "📏 Show Current Font Size" \
    "" \
    ">>> Preset Sizes" \
    "${SIZES[@]}" \
    "" \
    ">>> Custom" \
    "✏️  Enter Custom Size" \
    "🔄 Reset to Default (16px)" |
    wofi \
      --dmenu \
      --style "$WOFI_DIR/styles/style.css" \
      --conf "$WOFI_DIR/configs/size-small" \
      --prompt "Select Font Size:" \
      --cache-file=/dev/null
}

# Mevcut font boyutunu göster
show_current_size() {
  local css_size=$(grep -r "font-size:" "$WOFI_DIR" | grep -oP '\d+' | head -n 1)
  local config_size=$(grep -r "font=" "$WOFI_DIR/configs" | grep -oP '\d+' | head -n 1)

  echo "Current Sizes:" | wofi --dmenu --prompt "Font Sizes"
  echo "CSS files: ${css_size}px" | wofi --dmenu --prompt "Font Sizes"
  echo "Config files: ${config_size}" | wofi --dmenu --prompt "Font Sizes"
}

# Custom boyut giriş menüsü
get_custom_size() {
  echo "" | wofi --dmenu --prompt "Enter font size (px):"
}

# Font boyutunu değiştir
change_font_size() {
  local new_size="$1"

  # CSS dosyalarını güncelle
  find "$WOFI_DIR" -type f -name "*.css" -exec \
    sed -i "s/font-size:\s*[0-9]\+px/font-size: ${new_size}px/g" {} \;

  # Config dosyalarını güncelle
  find "$WOFI_DIR/configs" -type f -exec \
    sed -i "s/\(font=.*\s\)[0-9]\+/\1${new_size}/" {} \;

  notify-send "Wofi Font Size" "Changed to ${new_size}px"
}

# Ana fonksiyon
main() {
  choice=$(show_menu)

  case "$choice" in
  "📏 Show Current Font Size")
    show_current_size
    ;;
  "✏️  Enter Custom Size")
    custom_size=$(get_custom_size)
    if [[ "$custom_size" =~ ^[0-9]+$ ]]; then
      change_font_size "$custom_size"
    else
      notify-send "Error" "Invalid font size"
    fi
    ;;
  "🔄 Reset to Default (16px)")
    change_font_size "16"
    ;;
  *"px -"*)
    size=$(echo "$choice" | grep -oP '\d+')
    change_font_size "$size"
    ;;
  esac
}

# Programı çalıştır
main
