#!/usr/bin/env bash
WOFI_DIR="$HOME/.config/wofi"

generate_menu() {
  echo "⚡ Lock"
  echo "⚡ Sleep"
  echo "⚡ Restart"
  echo "⚡ Logout"
  echo "⚡ Shutdown"
}

show_menu() {
  generate_menu | wofi \
    --dmenu \
    --style "$WOFI_DIR/styles/style.css" \
    --conf "$WOFI_DIR/configs/power" \
    --cache-file=/dev/null \
    --prompt "Power:"
}

handle_selection() {
  case "$1" in
  "⚡ Lock") exec swaylock ;;
  "⚡ Sleep") exec systemctl suspend ;;
  "⚡ Restart") exec systemctl reboot ;;
  "⚡ Logout") exec hyprctl dispatch exit ;;
  "⚡ Shutdown") exec systemctl poweroff ;;
  esac
}

choice=$(show_menu)
[[ -n "$choice" ]] && handle_selection "$choice"
