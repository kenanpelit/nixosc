#!/usr/bin/env bash
# mpv-manager.sh - compositor-agnostic MPV helper
# - Hyprland: delegates to hypr-mpv-manager if available (full feature set)
# - Niri/other: provides core MPV controls via IPC (start/playback/play-yt/save-yt)

set -euo pipefail

SOCKET_PATH="/tmp/mpvsocket"
DOWNLOADS_DIR="${HOME}/Downloads"
NOTIFICATION_TIMEOUT=1200

notify() {
  local title="$1"
  local message="$2"
  if command -v notify-send >/dev/null 2>&1; then
    notify-send -t "$NOTIFICATION_TIMEOUT" "$title" "$message" 2>/dev/null || true
  fi
}

die() {
  echo "mpv-manager: $*" >&2
  notify "mpv-manager" "$*"
  exit 1
}

have_socket() {
  [[ -S "$SOCKET_PATH" ]]
}

mpv_running() {
  pgrep -x mpv >/dev/null 2>&1
}

mpv_ipc() {
  local json="$1"
  command -v socat >/dev/null 2>&1 || die "socat not found"
  echo "$json" | socat - "$SOCKET_PATH" >/dev/null
}

usage() {
  cat <<'EOF'
Usage: mpv-manager <command>

Commands:
  start       Start MPV (pseudo-gui + IPC socket)
  playback    Toggle pause/play via IPC
  play-yt     Play YouTube URL from clipboard
  save-yt     Download YouTube URL from clipboard (yt-dlp)

Hyprland-only (delegated to hypr-mpv-manager when present):
  move | stick | wallpaper
EOF
}

maybe_delegate_to_hypr() {
  if [[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]] && command -v hypr-mpv-manager >/dev/null 2>&1; then
    exec hypr-mpv-manager "$@"
  fi
}

start_mpv() {
  command -v mpv >/dev/null 2>&1 || die "mpv not found"

  if mpv_running && have_socket; then
    notify "mpv-manager" "MPV zaten çalışıyor"
    return 0
  fi

  rm -f "$SOCKET_PATH" 2>/dev/null || true
  mpv --player-operation-mode=pseudo-gui --input-ipc-server="$SOCKET_PATH" --idle -- >/dev/null 2>&1 &
  disown || true
  notify "mpv-manager" "MPV başlatıldı"
}

toggle_playback() {
  mpv_running || die "MPV çalışmıyor"
  have_socket || die "MPV IPC socket yok: $SOCKET_PATH"
  mpv_ipc '{ "command": ["cycle", "pause"] }'
  notify "mpv-manager" "Play/Pause"
}

read_clipboard() {
  command -v wl-paste >/dev/null 2>&1 || die "wl-paste not found"
  wl-paste 2>/dev/null || true
}

play_youtube() {
  command -v yt-dlp >/dev/null 2>&1 || die "yt-dlp not found"
  command -v mpv >/dev/null 2>&1 || die "mpv not found"

  local url
  url="$(read_clipboard)"
  [[ "$url" =~ ^https?://(www\.)?(youtube\.com|youtu\.?be)/ ]] || die "Panodaki URL YouTube değil"

  if mpv_running && have_socket; then
    mpv_ipc "{ \"command\": [\"loadfile\", \"$url\", \"replace\"] }"
    notify "mpv-manager" "YouTube yüklendi (replace)"
    return 0
  fi

  rm -f "$SOCKET_PATH" 2>/dev/null || true
  mpv --player-operation-mode=pseudo-gui \
    --input-ipc-server="$SOCKET_PATH" \
    --idle \
    --no-audio-display \
    "$url" >/dev/null 2>&1 &
  disown || true
  notify "mpv-manager" "YouTube oynatılıyor"
}

download_youtube() {
  command -v yt-dlp >/dev/null 2>&1 || die "yt-dlp not found"

  local url
  url="$(read_clipboard)"
  [[ "$url" =~ ^https?://(www\.)?(youtube\.com|youtu\.?be)/ ]] || die "Panodaki URL YouTube değil"

  mkdir -p "$DOWNLOADS_DIR"
  (cd "$DOWNLOADS_DIR" && yt-dlp -f "bestvideo+bestaudio/best" --merge-output-format mp4 --embed-thumbnail --add-metadata "$url")
  notify "mpv-manager" "İndirme tamamlandı: $DOWNLOADS_DIR"
}

main() {
  [[ $# -ge 1 ]] || { usage; exit 1; }
  cmd="$1"
  shift

  case "$cmd" in
    move|stick|wallpaper)
      maybe_delegate_to_hypr "$cmd" "$@"
      die "Bu komut Hyprland için (hypr-mpv-manager) destekleniyor: $cmd"
      ;;
    start)
      start_mpv
      ;;
    playback)
      toggle_playback
      ;;
    play-yt)
      play_youtube
      ;;
    save-yt)
      download_youtube
      ;;
    -h|--help|help)
      usage
      ;;
    *)
      usage
      die "Bilinmeyen komut: $cmd"
      ;;
  esac
}

main "$@"

