#!/usr/bin/env bash

# Directory definitions
WOFI_DIR="$HOME/.config/wofi"
SCRIPTS_DIR="$HOME/.bin"
ZEN_DIR="$HOME/.zen"

generate_menu() {
  echo "🌐 Zen-Kenp"
  echo "🌐 Zen-CompecTA"
  echo "🌐 Zen-Discord"
  echo "🌐 Zen-NoVpn"
  echo "🌐 Zen-Whats"
  echo "🌐 Zen-Proxy"
  echo "🌐 Zen-Spotify"
  echo "🌐 Zen-ChatGPT"
}

configure_session_restore() {
  local profile_name="$1"
  local profile_dir="$ZEN_DIR/${profile_name}"
  local prefs_file="$profile_dir/prefs.js"

  # Create prefs file if it doesn't exist
  if [ ! -f "$prefs_file" ]; then
    touch "$prefs_file"
  fi

  # Check and add session restoration settings
  if ! grep -q "browser.startup.page" "$prefs_file"; then
    echo 'user_pref("browser.startup.page", 3);' >>"$prefs_file"
  fi
  if ! grep -q "browser.sessionstore.resume_session_once" "$prefs_file"; then
    echo 'user_pref("browser.sessionstore.resume_session_once", false);' >>"$prefs_file"
  fi
  if ! grep -q "browser.sessionstore.resume_from_crash" "$prefs_file"; then
    echo 'user_pref("browser.sessionstore.resume_from_crash", true);' >>"$prefs_file"
  fi
}

launch_browser() {
  local selected="$1"
  local profile_name="${selected#🌐 Zen-}" # Remove emoji and "Zen-" prefix

  # Configure session restoration
  configure_session_restore "$profile_name"

  # Launch browser
  zen-browser -P "$profile_name" --restore-session &

  # Log the launch
  echo "[$(date)] Launched Zen Browser with profile: $profile_name" >>"$HOME/.zen/launcher.log"
}

# Show wofi menu with proper styling
selected=$(generate_menu | wofi \
  --dmenu \
  --style "$WOFI_DIR/styles/style.css" \
  --conf "$WOFI_DIR/configs/zen" \
  --cache-file=/dev/null \
  --prompt "Zen Profil:")

# Launch browser if selection was made
if [ ! -z "$selected" ]; then
  launch_browser "$selected"
fi
