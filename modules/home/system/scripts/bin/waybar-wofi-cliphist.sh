#!/usr/bin/env bash
WOFI_DIR="$HOME/.config/wofi"

# Cliphist çıktısını temizle
clean_clipboard_data() {
  sed 's/&/&amp;/g; s/</&lt;/g; s/>/&gt;/g' |
    sed 's/\x1b\[[0-9;]*m//g'
}

show_menu() {
  cliphist list | clean_clipboard_data | wofi \
    --dmenu \
    --style "$WOFI_DIR/styles/style.css" \
    --conf "$WOFI_DIR/configs/cliphist" \
    --cache-file=/dev/null \
    --prompt "Clipboard:"
}

# Ana program
if ! command -v cliphist &>/dev/null || ! command -v wl-copy &>/dev/null; then
  notify-send "Error" "cliphist or wl-copy not found"
  exit 1
fi

if selected_item=$(show_menu); then
  if [[ -n "$selected_item" ]]; then
    echo "$selected_item" | cliphist decode | wl-copy
    notify-send "Clipboard" "Copied selection to clipboard"
  fi
fi
