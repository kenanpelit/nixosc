#!/usr/bin/env bash

# Directory definitions
WOFI_DIR="$HOME/.config/wofi"
FIREFOX_DIR="$HOME/.mozilla/firefox"

generate_menu() {
  # Read profiles from profiles.ini and format them for display
  while IFS= read -r profile_dir; do
    profile_name=$(basename "$profile_dir")
    # Skip special directories
    if [[ "$profile_name" != "Crash Reports" && "$profile_name" != "Pending Pings" && "$profile_name" != "profiles.ini" && "$profile_name" != "installs.ini" ]]; then
      echo "🦊 $profile_name"
    fi
  done < <(find "$FIREFOX_DIR" -maxdepth 1 -type d | sort)
}

configure_session_restore() {
  local profile_name="$1"
  local profile_dir="$FIREFOX_DIR/$profile_name"
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
  local profile_name="${selected#🦊 }" # Remove emoji prefix

  # Configure session restoration
  configure_session_restore "$profile_name"

  # Launch Firefox with selected profile
  firefox -P "$profile_name" --new-instance &

  # Log the launch
  echo "[$(date)] Launched Firefox with profile: $profile_name" >>"$HOME/.mozilla/firefox/launcher.log"
}

# Show wofi menu with proper styling
selected=$(generate_menu | wofi \
  --dmenu \
  --style "$WOFI_DIR/styles/style.css" \
  --conf "$WOFI_DIR/configs/zen" \
  --cache-file=/dev/null \
  --prompt "Firefox Profile:")

# Launch browser if selection was made
if [ ! -z "$selected" ]; then
  launch_browser "$selected"
fi
