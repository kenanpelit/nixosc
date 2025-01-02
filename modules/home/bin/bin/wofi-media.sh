#!/usr/bin/env bash
WOFI_DIR="$HOME/.config/wofi"

generate_menu() {
  echo "🎵 Play/Pause"
  echo "🎵 Next Track"
  echo "🎵 Previous Track"
  echo ""
  echo "🔊 Volume Up"
  echo "🔊 Volume Down"
  echo "🔇 Toggle Mute"
}

show_menu() {
  generate_menu | wofi \
    --dmenu \
    --style "$WOFI_DIR/styles/style.css" \
    --conf "$WOFI_DIR/configs/media" \
    --cache-file=/dev/null \
    --prompt "Media:"
}

handle_selection() {
  case "$1" in
  "🎵 Play/Pause") playerctl play-pause ;;
  "🎵 Next Track") playerctl next ;;
  "🎵 Previous Track") playerctl previous ;;
  "🔊 Volume Up") pactl set-sink-volume @DEFAULT_SINK@ +5% ;;
  "🔊 Volume Down") pactl set-sink-volume @DEFAULT_SINK@ -5% ;;
  "🔇 Toggle Mute") pactl set-sink-mute @DEFAULT_SINK@ toggle ;;
  esac
}

choice=$(show_menu)
[[ -n "$choice" ]] && handle_selection "$choice"
