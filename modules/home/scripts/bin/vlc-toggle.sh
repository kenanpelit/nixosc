#!/usr/bin/env bash
########################################
#
# Name: hypr-vlc-toggle
# Version: 1.2.0
# Date: 2025-12-27
# Author: Kenan Pelit
# Repository: github.com/kenanpelit/dotfiles
# Description: Hyprland + VLC play/pause toggle with robust MPRIS detection, fallbacks, and notifications
# License: MIT
#
########################################

set -Eeuo pipefail

# -------------------------
# Styling (keep it simple + consistent)
# -------------------------
SUCCESS='\033[0;32m'
ERROR='\033[0;31m'
INFO='\033[0;34m'
NC='\033[0m'

MUSIC_EMOJI="🎵"
PAUSE_EMOJI="⏸️"
PLAY_EMOJI="▶️"
ERROR_EMOJI="❌"

# -------------------------
# Config
# -------------------------
NOTIFICATION_TIMEOUT=3000
NOTIFICATION_ICON="vlc"
MAX_TITLE_LENGTH=40

# Debug (1=on, 0=off) — can be overridden: DEBUG=1 hypr-vlc-toggle
DEBUG="${DEBUG:-0}"

# If you really want to force a specific player name, set FORCE_PLAYER.
# Example: FORCE_PLAYER="vlc" or FORCE_PLAYER="vlc.instance1234"
FORCE_PLAYER="${FORCE_PLAYER:-}"

# -------------------------
# Helpers
# -------------------------
debug() {
  if [[ "${DEBUG}" == "1" ]]; then
    echo -e "${INFO}[DEBUG]${NC} $*" >&2
  fi
}

die() {
  notify-send -i "${NOTIFICATION_ICON}" -t "${NOTIFICATION_TIMEOUT}" \
    "${ERROR_EMOJI} VLC Hatası" "$*"
  echo -e "${ERROR}[ERROR]${NC} $*" >&2
  exit 1
}

need() {
  command -v "$1" >/dev/null 2>&1 || die "Gerekli komut bulunamadı: $1"
}

truncate_text() {
  local text="${1:-}"
  local max_len="${2:-40}"
  if (( ${#text} > max_len )); then
    printf "%s...\n" "${text:0:max_len}"
  else
    printf "%s\n" "${text}"
  fi
}

# -------------------------
# Dependency checks
# -------------------------
need notify-send
need playerctl

# Optional deps (only used if needed)
has_cmd() { command -v "$1" >/dev/null 2>&1; }

# -------------------------
# Pick VLC player robustly
# -------------------------
pick_vlc_player() {
  if [[ -n "${FORCE_PLAYER}" ]]; then
    debug "FORCE_PLAYER set: ${FORCE_PLAYER}"
    echo "${FORCE_PLAYER}"
    return 0
  fi

  # playerctl -l outputs available MPRIS players
  # We prefer anything containing "vlc" (case-insensitive)
  local picked=""
  picked="$(playerctl -l 2>/dev/null | awk 'tolower($0) ~ /vlc/ {print; exit}')"

  if [[ -n "${picked}" ]]; then
    debug "Picked VLC player from playerctl: ${picked}"
    echo "${picked}"
    return 0
  fi

  # If VLC is running but MPRIS player name is not matched, return empty and rely on dbus fallback
  debug "No VLC-like player found via playerctl -l"
  echo ""
}

# -------------------------
# Check VLC process (cleaner than ps|grep)
# -------------------------
check_vlc_running() {
  if pgrep -x vlc >/dev/null 2>&1 || pgrep -f "vlc" >/dev/null 2>&1; then
    debug "VLC process seems running"
    return 0
  fi
  die "VLC çalışmıyor. Oynatıcıyı başlatın."
}

# -------------------------
# Get media info via MPRIS if possible
# -------------------------
get_media_info() {
  local player="${1:-}"
  local title="" artist="" album=""

  if [[ -n "${player}" ]]; then
    title="$(playerctl --player="${player}" metadata title 2>/dev/null || true)"
    artist="$(playerctl --player="${player}" metadata artist 2>/dev/null || true)"
    album="$(playerctl --player="${player}" metadata album 2>/dev/null || true)"
  else
    # Try generic (any player) if we couldn't pick VLC explicitly
    title="$(playerctl metadata title 2>/dev/null || true)"
    artist="$(playerctl metadata artist 2>/dev/null || true)"
    album="$(playerctl metadata album 2>/dev/null || true)"
  fi

  debug "Raw title:  ${title}"
  debug "Raw artist: ${artist}"
  debug "Raw album:  ${album}"

  if [[ -z "${title}" ]]; then
    # Try URL -> filename
    local url=""
    if [[ -n "${player}" ]]; then
      url="$(playerctl --player="${player}" metadata xesam:url 2>/dev/null || true)"
    else
      url="$(playerctl metadata xesam:url 2>/dev/null || true)"
    fi

    if [[ -n "${url}" ]]; then
      title="$(printf "%s" "${url}" | awk -F/ '{print $NF}' | sed 's/%20/ /g')"
      debug "Title from url: ${title}"
    fi
  fi

  if [[ -z "${title}" && $(has_cmd hyprctl && has_cmd jq; echo $?) -eq 0 ]]; then
    # Fallback: active window title
    local wt=""
    wt="$(hyprctl activewindow -j 2>/dev/null | jq -r '.title // empty' 2>/dev/null || true)"
    if [[ -n "${wt}" && "${wt,,}" == *"vlc"* ]]; then
      title="$(printf "%s" "${wt}" | sed 's/ - VLC media player//')"
      debug "Title from window: ${title}"
    fi
  fi

  [[ -z "${title}" ]] && title="Bilinmeyen Parça"

  TITLE="$(truncate_text "${title}" "${MAX_TITLE_LENGTH}")"
  ARTIST="$(truncate_text "${artist}" "${MAX_TITLE_LENGTH}")"
  ALBUM="${album}"

  debug "Processed TITLE:  ${TITLE}"
  debug "Processed ARTIST: ${ARTIST}"
}

# -------------------------
# Toggle playback with fallbacks
# -------------------------
toggle_playback() {
  local player="${1:-}"

  # 1) playerctl (preferred)
  if [[ -n "${player}" ]]; then
    if playerctl --player="${player}" play-pause >/dev/null 2>&1; then
      debug "playerctl play-pause OK (player=${player})"
      return 0
    fi
  else
    if playerctl play-pause >/dev/null 2>&1; then
      debug "playerctl play-pause OK (generic)"
      return 0
    fi
  fi

  debug "playerctl failed, trying dbus-send"

  # 2) dbus-send (VLC MPRIS well-known name)
  if has_cmd dbus-send; then
    if dbus-send --print-reply \
      --dest=org.mpris.MediaPlayer2.vlc \
      /org/mpris/MediaPlayer2 \
      org.mpris.MediaPlayer2.Player.PlayPause >/dev/null 2>&1; then
      debug "dbus-send PlayPause OK"
      return 0
    fi
  fi

  debug "dbus-send failed, trying XF86AudioPlay key"

  # 3) last resort: media key
  if has_cmd xdotool; then
    DISPLAY="${DISPLAY:-:0}" xdotool key XF86AudioPlay >/dev/null 2>&1 && return 0
  fi

  die "Oynatma durumu değiştirilemedi (playerctl/dbus/xdotool başarısız)."
}

# -------------------------
# Read state (Playing/Paused)
# -------------------------
get_state() {
  local player="${1:-}"
  local st=""

  if [[ -n "${player}" ]]; then
    st="$(playerctl --player="${player}" status 2>/dev/null || true)"
  else
    st="$(playerctl status 2>/dev/null || true)"
  fi

  # Normalize
  if [[ "${st}" != "Playing" && "${st}" != "Paused" ]]; then
    st=""
  fi
  echo "${st}"
}

# -------------------------
# Notifications
# -------------------------
notify_state() {
  local state="${1:-}"
  local title="" body=""

  if [[ "${state}" == "Playing" ]]; then
    title="${PLAY_EMOJI} Oynatılıyor"
  elif [[ "${state}" == "Paused" ]]; then
    title="${PAUSE_EMOJI} Duraklatıldı"
  else
    title="${MUSIC_EMOJI} VLC Medya"
  fi

  if [[ -n "${ARTIST}" ]]; then
    body="${TITLE} - ${ARTIST}"
  else
    body="${TITLE}"
  fi

  if [[ -n "${ALBUM}" ]]; then
    body="${body}\nAlbüm: ${ALBUM}"
  fi

  notify-send -i "${NOTIFICATION_ICON}" -t "${NOTIFICATION_TIMEOUT}" "${title}" "${body}"

  echo -e "${INFO}${title}${NC}"
  echo -e "${SUCCESS}${body}${NC}"
}

# -------------------------
# Main
# -------------------------
main() {
  check_vlc_running

  local player=""
  player="$(pick_vlc_player)"
  debug "Final player: '${player}'"

  get_media_info "${player}"

  local prev=""
  prev="$(get_state "${player}")"
  debug "Prev state: '${prev}'"

  toggle_playback "${player}"

  sleep 0.15

  local cur=""
  cur="$(get_state "${player}")"
  debug "Cur state: '${cur}'"

  # If we still can't read state, show generic notification (don’t invent with ps)
  notify_state "${cur}"
}

main "$@"

