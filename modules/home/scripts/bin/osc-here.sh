#!/usr/bin/env bash
# ==============================================================================
# osc-here.sh - Bring window here OR launch it if it's not running
# ==============================================================================
# Usage:
#   osc-here.sh <app-id>
#   osc-here.sh all [app1,app2,...]
#
# Example:
#   osc-here.sh Kenp
#   osc-here.sh all
#   osc-here.sh all "Kenp,TmuxKenp"
# ==============================================================================

set -euo pipefail

# Default list for 'all' command
DEFAULT_APPS=(
  "Kenp"
  "TmuxKenp"
  "Ai"
  "CompecTA"
  "WebCord"
  #"org.telegram.desktop"
  "brave-youtube.com__-Default"
  "spotify"
  "ferdium"
)

# Helper function to process a single app
process_app() {
  local APP_ID="$1"

  # --- 1. Try to pull existing window (Nirius) ---
  if nirius move-to-current-workspace --app-id "^${APP_ID}$" --focus >/dev/null 2>&1; then
    return 0
  fi

  # --- 2. Check if it's already here but not focused ---
  if command -v niri >/dev/null 2>&1 && command -v jq >/dev/null 2>&1; then
    window_id=$(niri msg -j windows | jq -r --arg app "$APP_ID" '.[] | select(.app_id == $app) | .id' | head -n1)
    if [[ -n "$window_id" ]]; then
      niri msg action focus-window --id "$window_id"
      return 0
    fi
  fi

  # --- 3. Launching logic (Window not found) ---
  case "$APP_ID" in
  "Kenp") start-brave-kenp & ;;
  "TmuxKenp") start-kkenp & ;;
  "Ai") start-brave-ai & ;;
  "CompecTA") start-brave-compecta & ;;
  "WebCord") start-webcord & ;;
  #"org.telegram.desktop") Telegram & ;;
  "brave-youtube.com__-Default") start-brave-youtube & ;;
  "spotify") start-spotify & ;;
  "ferdium") start-ferdium & ;;
  "discord") start-discord & ;;
  "kitty") kitty & ;;
  *)
    if command -v "$APP_ID" >/dev/null 2>&1; then
      "$APP_ID" &
    fi
    ;;
  esac
}

APP_ID="${1:-}"
LIST="${2:-}"

if [[ -z "$APP_ID" ]]; then
  echo "Error: App ID is required."
  exit 1
fi

if [[ "$APP_ID" == "all" ]]; then
  # Process list
  if [[ -n "$LIST" ]]; then
    IFS=',' read -ra APPS <<<"$LIST"
  else
    APPS=("${DEFAULT_APPS[@]}")
  fi

  for app in "${APPS[@]}"; do
    process_app "$app"
    # Small delay to let Niri process moves smoothly
    sleep 0.1
  done

  if command -v notify-send >/dev/null 2>&1; then
    notify-send -t 2000 -i "system-run" "Niri" "All specified apps gathered here."
  fi
else
  # Process single app
  process_app "$APP_ID"

  if command -v notify-send >/dev/null 2>&1; then
    notify-send -t 2000 -i "system-run" "Niri" "<b>$APP_ID</b> processed."
  fi
fi

exit 0

