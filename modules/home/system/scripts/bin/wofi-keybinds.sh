#!/usr/bin/env bash

# Dizin tanımlamaları
WOFI_DIR="$HOME/.config/wofi"
HYPR_CONFIG="$HOME/.config/hypr/config"
KEYBINDS_FILE="$HYPR_CONFIG/06_keybinds.conf"

# Kategoriler ve ikonlar
declare -A CATEGORIES=(
  ["APPLICATIONS"]="📱 Applications"
  ["WINDOW"]="🪟 Window Management"
  ["WORKSPACE"]="🖥️ Workspace Control"
  ["MEDIA"]="🎵 Media Controls"
  ["SCREENSHOT"]="📸 Screenshot"
  ["SYSTEM"]="⚙️ System Controls"
  ["LAUNCHER"]="🚀 Launchers"
)

# Keybind'ları kategorilere ayır ve formatla
format_keybinds() {
  local keybinds_content
  keybinds_content=$(grep -oP '(?<=bind = ).*' "$KEYBINDS_FILE")

  # Her kategori için keybind'ları işle
  for category in "${!CATEGORIES[@]}"; do
    local category_binds
    category_binds=$(echo "$keybinds_content" | grep -i "$category" || true)

    if [[ -n "$category_binds" ]]; then
      echo ">>> ${CATEGORIES[$category]}"
      echo "$category_binds" | while read -r line; do
        formatted_line=$(echo "$line" |
          sed 's/,\([^,]*\)$/ = \1/' |
          sed 's/, exec//g' |
          sed 's/^,//g' |
          sed 's/^/$mainMod /; s/\([^=]*\) = \(.*\)/\1: \2/' |
          sed 's/SUPER/Super/g' |
          sed 's/SHIFT/Shift/g' |
          sed 's/CTRL/Ctrl/g' |
          sed 's/ALT/Alt/g' |
          sed 's/RETURN/Enter/g' |
          sed 's/SPACE/Space/g')

        echo "    $formatted_line"
      done
      echo ""
    fi
  done

  # Kategorize edilmemiş keybind'ları göster
  echo ">>> 🔣 Other Bindings"
  echo "$keybinds_content" | while read -r line; do
    local categorized=false
    for category in "${!CATEGORIES[@]}"; do
      if echo "$line" | grep -qi "$category"; then
        categorized=true
        break
      fi
    done

    if ! $categorized; then
      formatted_line=$(echo "$line" |
        sed 's/,\([^,]*\)$/ = \1/' |
        sed 's/, exec//g' |
        sed 's/^,//g' |
        sed 's/^/$mainMod /; s/\([^=]*\) = \(.*\)/\1: \2/' |
        sed 's/SUPER/Super/g' |
        sed 's/SHIFT/Shift/g' |
        sed 's/CTRL/Ctrl/g' |
        sed 's/ALT/Alt/g' |
        sed 's/RETURN/Enter/g' |
        sed 's/SPACE/Space/g')

      echo "    $formatted_line"
    fi
  done
}

# Keybind'ları göster
format_keybinds | wofi \
  --dmenu \
  --style "$WOFI_DIR/styles/keybinds.css" \
  --conf "$WOFI_DIR/configs/keybinds" \
  --cache-file=/dev/null \
  --prompt "Search Keybinds:" \
  --insensitive
