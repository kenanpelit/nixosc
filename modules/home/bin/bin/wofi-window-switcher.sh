#!/usr/bin/env bash
WOFI_DIR="$HOME/.config/wofi"

# Hyprland pencere listesini formatla ve address bilgisini sakla
generate_window_list() {
  hyprctl clients -j | jq -r '.[] | select(.mapped==true) | "\(.title) [\(.class)] {\(.address)}"' |
    while read -r window; do
      # Boş başlıkları filtrele
      if [ "$window" != " []" ] && [ -n "$window" ]; then
        echo "$window"
      fi
    done
}

show_menu() {
  generate_window_list | wofi \
    --dmenu \
    --style "$WOFI_DIR/styles/style.css" \
    --conf "$WOFI_DIR/configs/window-switcher" \
    --cache-file=/dev/null \
    --prompt "Windows:" \
    --allow-markup \
    --hide-scroll \
    --matching=fuzzy
}

handle_selection() {
  local selection="$1"
  if [ -n "$selection" ]; then
    # Pencere adresini al
    local window_address=$(echo "$selection" | grep -o '{[^}]*}' | tr -d '{}')
    if [ -n "$window_address" ]; then
      # Doğrudan adres ile pencereye odaklan
      hyprctl dispatch focuswindow "address:$window_address"
    fi
  fi
}

main() {
  # Gerekli komutları kontrol et
  for cmd in hyprctl jq wofi; do
    if ! command -v "$cmd" &>/dev/null; then
      notify-send "Error" "$cmd is not installed"
      exit 1
    fi
  done

  # Pencere listesini göster ve seçimi işle
  if choice=$(show_menu); then
    handle_selection "$choice"
  fi
}

main
