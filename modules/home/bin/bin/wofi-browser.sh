#!/usr/bin/env bash
WOFI_DIR="$HOME/.config/wofi"
SCRIPTS_DIR="$HOME/.bin"

generate_menu() {
  echo ">>> Browsers"
  echo "🌐 Firefox"
  echo "🌐 Chromium"
  echo ""
  echo ">>> Zen Profiles"
  echo "🌐 Zen-CompecTA"
  echo "🌐 Zen-Discord"
  echo "🌐 Zen-Kenp"
  echo "🌐 Zen-NoVpn"
  echo "🌐 Zen-Proxy"
  echo "🌐 Zen-Spotify"
  echo "🌐 Zen-Whatsapp"
  echo "🌐 Zen-ChatGPT"
}

show_menu() {
  generate_menu | wofi \
    --dmenu \
    --style "$WOFI_DIR/styles/style.css" \
    --conf "$WOFI_DIR/configs/config" \
    --cache-file=/dev/null \
    --prompt "Browser:"
}

handle_selection() {
  case "$1" in
  "🌐 Firefox") firefox ;;
  "🌐 Chromium") chromium ;;
  "🌐 Zen-"*)
    profile=${1#"🌐 Zen-"}
    exec "$SCRIPTS_DIR/zen_profile_launcher.sh" "$profile"
    ;;
  esac
}

choice=$(show_menu)
[[ -n "$choice" ]] && handle_selection "$choice"
