#!/usr/bin/env bash
# mpv-manager.sh - compositor-aware MPV helper
# - Hyprland: window management via hyprctl (move/stick/wallpaper + IPC controls)
# - Niri/other: IPC controls (start/playback/play-yt/save-yt), best-effort helpers

set -euo pipefail

SOCKET_PATH="/tmp/mpvsocket"
DOWNLOADS_DIR="${HOME}/Downloads"
NOTIFICATION_TIMEOUT=1200

compositor() {
  if [[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
    echo "hyprland"
    return
  fi
  if [[ -n "${NIRI_SOCKET:-}" ]]; then
    echo "niri"
    return
  fi
  case "${XDG_CURRENT_DESKTOP:-}${XDG_SESSION_DESKTOP:-}" in
    *Hyprland*|*hyprland*) echo "hyprland" ;;
    *niri*|*Niri*) echo "niri" ;;
    *) echo "unknown" ;;
  esac
}

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

sign() {
  local n="$1"
  if [[ "$n" -ge 0 ]]; then
    echo "+$n"
  else
    echo "$n"
  fi
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

Window management (Hyprland; limited elsewhere):
  move | stick | wallpaper
EOF
}

require_hypr() {
  command -v hyprctl >/dev/null 2>&1 || die "hyprctl not found"
  command -v jq >/dev/null 2>&1 || die "jq not found"
}

hypr_find_mpv_window() {
  hyprctl clients -j | jq -c 'map(select(.initialClass == "mpv" or .class == "mpv")) | .[0] // empty'
}

hypr_focus_mpv() {
  local window_info address
  window_info="$(hypr_find_mpv_window)"
  address="$(echo "$window_info" | jq -r '.address // empty')"
  [[ -n "$address" ]] || return 1
  hyprctl dispatch focuswindow "address:$address" >/dev/null
  return 0
}

hypr_start_mpv() {
  require_hypr
  command -v mpv >/dev/null 2>&1 || die "mpv not found"

  if hypr_focus_mpv; then
    notify "mpv-manager" "MPV zaten çalışıyor"
    return 0
  fi

  rm -f "$SOCKET_PATH" 2>/dev/null || true
  mpv --player-operation-mode=pseudo-gui --input-ipc-server="$SOCKET_PATH" --idle -- >/dev/null 2>&1 &
  disown || true
  notify "mpv-manager" "MPV başlatıldı"
}

hypr_move_window() {
  require_hypr

  local window_info address x_pos y_pos size
  window_info="$(hypr_find_mpv_window)"
  address="$(echo "$window_info" | jq -r '.address // empty')"
  [[ -n "$address" ]] || die "MPV penceresi bulunamadı"

  hyprctl dispatch focuswindow "address:$address" >/dev/null
  sleep 0.1

  x_pos="$(echo "$window_info" | jq -r '.at[0] // 0')"
  y_pos="$(echo "$window_info" | jq -r '.at[1] // 0')"
  size="$(echo "$window_info" | jq -r '.size[0] // 0')"

  if [[ "$size" -gt 300 ]]; then
    if [[ "$x_pos" -lt 500 && "$y_pos" -lt 500 ]]; then
      hyprctl dispatch moveactive exact 80% 7% >/dev/null
    elif [[ "$x_pos" -gt 1000 && "$y_pos" -lt 500 ]]; then
      hyprctl dispatch moveactive exact 80% 77% >/dev/null
    elif [[ "$x_pos" -gt 1000 && "$y_pos" -gt 500 ]]; then
      hyprctl dispatch moveactive exact 1% 77% >/dev/null
    else
      hyprctl dispatch moveactive exact 1% 7% >/dev/null
    fi
  else
    if [[ "$x_pos" -lt 500 && "$y_pos" -lt 500 ]]; then
      hyprctl dispatch moveactive exact 84% 7% >/dev/null
    elif [[ "$x_pos" -gt 1000 && "$y_pos" -lt 500 ]]; then
      hyprctl dispatch moveactive exact 84% 80% >/dev/null
    elif [[ "$x_pos" -gt 1000 && "$y_pos" -gt 500 ]]; then
      hyprctl dispatch moveactive exact 3% 80% >/dev/null
    else
      hyprctl dispatch moveactive exact 3% 7% >/dev/null
    fi
  fi

  notify "mpv-manager" "Pencere konumu güncellendi"
}

hypr_toggle_stick() {
  require_hypr
  hyprctl dispatch pin mpv >/dev/null
  notify "mpv-manager" "Pencere durumu değiştirildi"
}

hypr_wallpaper() {
  command -v mpvpaper >/dev/null 2>&1 || die "mpvpaper not found"
  command -v wl-paste >/dev/null 2>&1 || die "wl-paste not found"

  local output="${MPV_WALLPAPER_OUTPUT:-eDP-1}"
  local source
  source="$(wl-paste 2>/dev/null || true)"
  [[ -n "$source" ]] || die "Panoda video/URL yok"

  mpvpaper "$output" "$source" >/dev/null 2>&1 || die "mpvpaper başarısız oldu (output=$output)"
  notify "mpv-manager" "Wallpaper ayarlandı ($output)"
}

niri_require() {
  command -v niri >/dev/null 2>&1 || die "niri not found in PATH"
}

niri_focused_window_geometry() {
  # Outputs: "x y w h" from `niri msg focused-window`
  # Example lines:
  #   Workspace-view position: 32, 490
  #   Window size: 2160 x 1224
  local info x y w h
  info="$(niri msg focused-window 2>/dev/null || true)"

  x="$(echo "$info" | sed -n 's/^[[:space:]]*Workspace-view position:[[:space:]]*\\([0-9]\\+\\),[[:space:]]*\\([0-9]\\+\\)$/\\1/p' | tail -n1)"
  y="$(echo "$info" | sed -n 's/^[[:space:]]*Workspace-view position:[[:space:]]*\\([0-9]\\+\\),[[:space:]]*\\([0-9]\\+\\)$/\\2/p' | tail -n1)"
  w="$(echo "$info" | sed -n 's/^[[:space:]]*Window size:[[:space:]]*\\([0-9]\\+\\)[[:space:]]*x[[:space:]]*\\([0-9]\\+\\)$/\\1/p' | tail -n1)"
  h="$(echo "$info" | sed -n 's/^[[:space:]]*Window size:[[:space:]]*\\([0-9]\\+\\)[[:space:]]*x[[:space:]]*\\([0-9]\\+\\)$/\\2/p' | tail -n1)"

  [[ -n "$x" && -n "$y" && -n "$w" && -n "$h" ]] || return 1
  echo "$x $y $w $h"
}

niri_focused_output_size() {
  # Output: "W H" from `niri msg focused-output`
  # Try to parse "<W>x<H>@" from a "Mode:" line.
  local info mode w h
  info="$(niri msg focused-output 2>/dev/null || true)"
  mode="$(echo "$info" | sed -n 's/^[[:space:]]*Mode:[[:space:]]*\\([0-9]\\+x[0-9]\\+\\)@.*$/\\1/p' | head -n1)"
  w="${mode%x*}"
  h="${mode#*x}"
  [[ -n "$w" && -n "$h" && "$w" != "$mode" ]] || return 1
  echo "$w $h"
}

niri_move_floating_cycle_corners() {
  niri_require

  # Ensure focused window is floating so we can move it.
  niri msg action move-window-to-floating >/dev/null 2>&1 || true

  # Best-effort: force a sane PiP-ish size in Niri.
  niri msg action set-window-width 640 >/dev/null 2>&1 || true
  niri msg action set-window-height 360 >/dev/null 2>&1 || true

  local geo out x y w h ow oh margin_x margin_y corner next tx ty dx dy
  geo="$(niri_focused_window_geometry)" || {
    # Fallback: just push window to top-right; niri will clamp.
    niri msg action move-floating-window -x +99999 -y -99999 >/dev/null 2>&1 || true
    notify "mpv-manager" "Niri: top-right (fallback)"
    return 0
  }
  out="$(niri_focused_output_size)" || {
    niri msg action move-floating-window -x +99999 -y -99999 >/dev/null 2>&1 || true
    notify "mpv-manager" "Niri: top-right (fallback)"
    return 0
  }

  read -r x y w h <<<"$geo"
  read -r ow oh <<<"$out"

  margin_x=32
  margin_y=96

  # Determine quadrant and cycle TL -> TR -> BR -> BL -> TL
  if [[ "$x" -lt $((ow / 2)) && "$y" -lt $((oh / 2)) ]]; then
    corner="tl"
  elif [[ "$x" -ge $((ow / 2)) && "$y" -lt $((oh / 2)) ]]; then
    corner="tr"
  elif [[ "$x" -ge $((ow / 2)) && "$y" -ge $((oh / 2)) ]]; then
    corner="br"
  else
    corner="bl"
  fi

  case "$corner" in
    tl) next="tr" ;;
    tr) next="br" ;;
    br) next="bl" ;;
    bl) next="tl" ;;
  esac

  case "$next" in
    tl) tx=$margin_x; ty=$margin_y ;;
    tr) tx=$((ow - w - margin_x)); ty=$margin_y ;;
    br) tx=$((ow - w - margin_x)); ty=$((oh - h - margin_x)) ;;
    bl) tx=$margin_x; ty=$((oh - h - margin_x)) ;;
  esac

  dx=$((tx - x))
  dy=$((ty - y))

  niri msg action move-floating-window -x "$(sign "$dx")" -y "$(sign "$dy")" >/dev/null 2>&1 || die "Niri: move-floating-window başarısız"
  notify "mpv-manager" "Niri: MPV taşındı ($next)"
}

start_mpv() {
  case "$(compositor)" in
    hyprland) hypr_start_mpv ;;
    *) 
      command -v mpv >/dev/null 2>&1 || die "mpv not found"
      if mpv_running && have_socket; then
        notify "mpv-manager" "MPV zaten çalışıyor"
        return 0
      fi
      rm -f "$SOCKET_PATH" 2>/dev/null || true
      mpv --player-operation-mode=pseudo-gui --input-ipc-server="$SOCKET_PATH" --idle -- >/dev/null 2>&1 &
      disown || true
      notify "mpv-manager" "MPV başlatıldı"
      ;;
  esac
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
      case "$(compositor)" in
        hyprland)
          case "$cmd" in
            move) hypr_move_window ;;
            stick) hypr_toggle_stick ;;
            wallpaper) hypr_wallpaper ;;
          esac
          ;;
        niri)
          case "$cmd" in
            move) niri_move_floating_cycle_corners ;;
            stick)
              # Niri'de Hyprland'daki "pin" yok; en yakın karşılık pencereyi floating'e almak.
              niri_require
              niri msg action move-window-to-floating >/dev/null 2>&1 || true
              notify "mpv-manager" "Niri: window -> floating"
              ;;
            *)
              die "Bu komut Niri'de desteklenmiyor: $cmd"
              ;;
          esac
          ;;
        *)
          die "Bu komut bu ortamda desteklenmiyor: $cmd"
          ;;
      esac
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
