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

# Screenshot Settings
SAVE_DIR="$HOME/Pictures/ss"
BORDER_COLOR="#000000b0"
SELECTION_COLOR="#00000000"
BORDER_WIDTH="2"
COLOR_PICKER_BORDER="#ff0000ff"

# Yardım fonksiyonu
show_help() {
  cat <<EOF
Screenshot Tool Help:
--------------------
Usage: $0 [OPTION]

Options:
  rc    Region Copy        - Seçilen bölgenin ekran görüntüsünü panoya kopyalar
  rf    Region File        - Seçilen bölgenin ekran görüntüsünü dosyaya kaydeder
  ri    Region Interactive - Seçilen bölgenin ekran görüntüsünü düzenleyicide açar
  sc    Screen Copy        - Tüm ekranın görüntüsünü panoya kopyalar
  sf    Screen File        - Tüm ekranın görüntüsünü dosyaya kaydeder
  si    Screen Interactive - Tüm ekranın görüntüsünü düzenleyicide açar
  p     Pick Color         - Ekrandan renk seçer ve renk kodunu panoya kopyalar
  help  Show Help          - Bu yardım mesajını gösterir

Examples:
  $0 rc    # Seçilen alanı panoya kopyalar
  $0 sf    # Tüm ekranı dosyaya kaydeder
  $0 p     # Renk seçer

Notes:
- Screenshots are saved to: $SAVE_DIR
- Interactive mode uses swappy editor
- Color picker shows preview notification
EOF
}

# Screenshot alma fonksiyonu
take_screenshot() {
  local filename="$1"
  grim -g "$(slurp -b "$BORDER_COLOR" -c "$SELECTION_COLOR" -w "$BORDER_WIDTH")" "$filename"
}

# Klasör oluşturma fonksiyonu
create_screenshot_dir() {
  if [[ ! -d "$SAVE_DIR" ]]; then
    mkdir -p "$SAVE_DIR"
  fi
}

# Timestamp oluşturma fonksiyonu
get_timestamp() {
  date +%Y-%m-%d_%H-%M-%S
}

# Bildirim gösterme fonksiyonu
show_notification() {
  local title="$1"
  local message="$2"
  local urgency="${3:-low}"
  local icon="${4:-}"

  if [ -n "$icon" ]; then
    notify-send -h string:x-canonical-private-synchronous:sys-notify -u "$urgency" -i "$icon" "$title" "$message"
  else
    notify-send -h string:x-canonical-private-synchronous:sys-notify -u "$urgency" "$title" "$message"
  fi
}

# Renk seçme fonksiyonu
pick_color() {
  slurp -p -b '#00000000' -c "$COLOR_PICKER_BORDER" -w "$BORDER_WIDTH" |
    grim -g - -t ppm - |
    magick - -format '%[pixel:p{0,0}]' txt:- 2>/dev/null |
    tail -n1 | cut -d' ' -f4
}

# Ana işlem kontrolü
case $1 in
rc) # Bölgeyi kopyala
  grim -g "$(slurp -b "$BORDER_COLOR" -c "$SELECTION_COLOR" -w "$BORDER_WIDTH")" - | wl-copy
  show_notification "Screenshot" "Copied to clipboard"
  ;;

rf) # Bölgeyi dosyaya kaydet
  create_screenshot_dir
  filename="$SAVE_DIR/$(get_timestamp).png"
  take_screenshot "$filename"
  show_notification "Screenshot" "Saved as: $filename"
  ;;

ri) # Bölgeyi interaktif düzenleme ile al
  create_screenshot_dir
  filename="$SAVE_DIR/swappy-$(get_timestamp).png"
  grim -g "$(slurp -b "$BORDER_COLOR" -c "$SELECTION_COLOR" -w "$BORDER_WIDTH")" - | swappy -f - -o "$filename"
  show_notification "Screenshot" "Saved as: $filename"
  ;;

sc) # Ekranın tamamını kopyala
  grim - | wl-copy
  show_notification "Screenshot" "Full screen copied to clipboard"
  ;;

sf) # Ekranın tamamını dosyaya kaydet
  create_screenshot_dir
  filename="$SAVE_DIR/$(get_timestamp).png"
  grim "$filename"
  show_notification "Screenshot" "Full screen saved as: $filename"
  ;;

si) # Ekranın tamamını interaktif düzenleme ile al
  create_screenshot_dir
  filename="$SAVE_DIR/swappy-$(get_timestamp).png"
  grim - | swappy -f - -o "$filename"
  show_notification "Screenshot" "Saved as: $filename"
  ;;

p) # Renk seçme ve önizleme
  color=$(pick_color)
  if [ -n "$color" ]; then
    echo -n "$color" | wl-copy
    image="/tmp/color_preview_${color//[#\/\\]/}.png"
    magick -size 48x48 xc:"$color" "$image" 2>/dev/null

    if [ -f "$image" ]; then
      show_notification "$color" "Color copied to clipboard" "low" "$image"
    else
      show_notification "$color" "Color copied to clipboard"
    fi
    rm -f "$image"
  else
    show_notification "Error" "Failed to capture color" "critical"
  fi
  ;;

help | --help | -h)
  show_help
  ;;

*)
  show_notification "Error" "Invalid option. Use '$0 help' for usage information." "critical"
  exit 1
  ;;
esac
