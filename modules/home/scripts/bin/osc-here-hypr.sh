#!/usr/bin/env bash
# ==============================================================================
# osc-here-hypr.sh - Bring window here OR launch it if it's not running (Hyprland)
# ==============================================================================
# Usage: osc-here-hypr.sh <class/app-id>
#        osc-here-hypr.sh all [comma,separated,apps]
# Example: osc-here-hypr.sh Kenp
# ==============================================================================

set -euo pipefail

APP_ID="${1:-}"
LIST="${2:-}"

# Notification setting: 0 (off), 1 (on)
NOTIFY_ENABLED="${OSC_HERE_NOTIFY:-0}"

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

if [[ -z "${APP_ID}" ]]; then
  echo "Error: App ID is required." >&2
  exit 1
fi

send_notify() {
  local msg="$1"
  local urgency="${2:-normal}"

  # Only show normal notifications if enabled (parity with niri-set here)
  if [[ "$urgency" == "normal" && "$NOTIFY_ENABLED" != "1" ]]; then
    return 0
  fi

  if command -v notify-send >/dev/null 2>&1; then
    notify-send -t 2000 -u "$urgency" -i "system-run" "Hyprland" "$msg" >/dev/null 2>&1 || true
  fi
}

if [[ "${APP_ID}" == "all" ]]; then
  if [[ -n "${LIST}" ]]; then
    IFS=',' read -ra APPS <<<"${LIST}"
  else
    APPS=("${DEFAULT_APPS[@]}")
  fi

  for app in "${APPS[@]}"; do
    "${0}" "${app}" || true
    sleep 0.1
  done

  # Explicit workflow: always end focused on Kenp.
  "${0}" "Kenp" || true

  send_notify "All specified apps gathered here."
  exit 0
fi

ensure_hypr_env() {
  : "${XDG_RUNTIME_DIR:="/run/user/$(id -u)"}"

  if [[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
    return 0
  fi

  local sig
  sig="$(ls "$XDG_RUNTIME_DIR"/hypr 2>/dev/null | head -n1 || true)"
  if [[ -n "${sig:-}" ]]; then
    export HYPRLAND_INSTANCE_SIGNATURE="$sig"
  fi
}

launch_app() {
  send_notify "Launching <b>${APP_ID}</b>..."

  case "$APP_ID" in
    "Kenp")
      start-brave-kenp &
      ;;
    "TmuxKenp")
      start-kkenp &
      ;;
    "Ai")
      start-brave-ai &
      ;;
    "CompecTA")
      start-brave-compecta &
      ;;
    "WebCord")
      start-webcord &
      ;;
    "org.telegram.desktop")
      Telegram &
      ;;
    "brave-youtube.com__-Default")
      start-brave-youtube &
      ;;
    "spotify")
      start-spotify &
      ;;
    "ferdium")
      start-ferdium &
      ;;
    "discord")
      start-discord &
      ;;
    "kitty")
      kitty &
      ;;
    *)
      if command -v "$APP_ID" >/dev/null 2>&1; then
        "$APP_ID" &
      else
        send_notify "Error: No start command found for <b>${APP_ID}</b>" "critical"
        exit 1
      fi
      ;;
  esac
}

ensure_hypr_env || true

if ! command -v hyprctl >/dev/null 2>&1 || ! hyprctl version >/dev/null 2>&1; then
  launch_app
  exit 0
fi

if ! command -v jq >/dev/null 2>&1; then
  launch_app
  exit 0
fi

current_ws="$(
  hyprctl activeworkspace -j 2>/dev/null \
    | jq -r '.id // empty' \
    || true
)"

if [[ -z "${current_ws}" || "${current_ws}" == "null" || ! "${current_ws}" =~ ^-?[0-9]+$ ]]; then
  current_ws="-1"
fi

clients="$(hyprctl clients -j 2>/dev/null || echo '[]')"

# 1) If it's already on the current workspace, just focus it.
addr_here="$(
  echo "$clients" \
    | jq -r --arg app "$APP_ID" --arg ws "$current_ws" '
        .[]
        | select(((.class // "") | ascii_downcase) == ($app | ascii_downcase)
              or ((.initialClass // "") | ascii_downcase) == ($app | ascii_downcase))
        | select(.workspace.id == ($ws | tonumber))
        | .address
      ' \
    | head -n1 \
    || true
)"

if [[ -n "${addr_here}" && "${addr_here}" != "null" ]]; then
  hyprctl dispatch focuswindow "address:${addr_here}" >/dev/null 2>&1 || true
  send_notify "<b>${APP_ID}</b> focused."
  exit 0
fi

# 2) Otherwise, move one matching window to the current workspace and focus it.
addr_any="$(
  echo "$clients" \
    | jq -r --arg app "$APP_ID" '
        .[]
        | select(((.class // "") | ascii_downcase) == ($app | ascii_downcase)
              or ((.initialClass // "") | ascii_downcase) == ($app | ascii_downcase))
        | .address
      ' \
    | head -n1 \
    || true
)"

if [[ -n "${addr_any}" && "${addr_any}" != "null" && "${current_ws}" != "-1" ]]; then
  hyprctl dispatch movetoworkspace "${current_ws},address:${addr_any}" >/dev/null 2>&1 || true
  hyprctl dispatch focuswindow "address:${addr_any}" >/dev/null 2>&1 || true
  send_notify "<b>${APP_ID}</b> moved to current workspace."
  exit 0
fi

# 3) Not found: launch it.
launch_app

exit 0
