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
  if [[ -z "${NIRI_SOCKET:-}" || ! -S "${NIRI_SOCKET:-/dev/null}" ]]; then
    local runtime candidate
    runtime="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
    for candidate in \
      "$runtime"/niri.*.sock \
      "$runtime"/niri.wayland-*.sock \
      "$runtime"/niri*.sock; do
      if [[ -S "$candidate" && "$candidate" != *nirius* ]]; then
        export NIRI_SOCKET="$candidate"
        break
      fi
    done
  fi

  niri msg version >/dev/null 2>&1 || die "niri IPC erişilemiyor (NIRI_SOCKET yok/erişim yok)"
}

niri_find_window_id_by_app_id() {
  niri_require
  local app_id="$1"
  local id=""

  if command -v jq >/dev/null 2>&1; then
    id="$(
      niri msg -j windows 2>/dev/null \
        | jq -r --arg app "$app_id" '.. | objects | select(.app_id? == $app) | .id? // empty' \
        | head -n1
    )"
    [[ -n "$id" ]] && { echo "$id"; return 0; }
  fi

  id="$(
    niri msg windows 2>/dev/null | awk -v app="$app_id" '
      /^Window ID[[:space:]]+/ {
        id=$3
        gsub(":", "", id)
        inwin=1
        next
      }
      inwin && /App ID:/ {
        if ($0 ~ "\"" app "\"") { print id; exit }
        inwin=0
      }
    '
  )"

  [[ -n "$id" ]] || return 1
  echo "$id"
}

niri_focused_window_xywh() {
  # Output: "x y w h" from `niri msg focused-window`
  local info x y w h
  if command -v jq >/dev/null 2>&1; then
    info="$(niri msg -j focused-window 2>/dev/null || true)"
    if [[ -n "$info" ]]; then
      x="$(jq -r '.workspace_view_position.x? // empty' <<<"$info" 2>/dev/null | head -n1)"
      y="$(jq -r '.workspace_view_position.y? // empty' <<<"$info" 2>/dev/null | head -n1)"
      w="$(jq -r '.window_size.width? // empty' <<<"$info" 2>/dev/null | head -n1)"
      h="$(jq -r '.window_size.height? // empty' <<<"$info" 2>/dev/null | head -n1)"
      if [[ -n "$x" && -n "$y" && -n "$w" && -n "$h" ]]; then
        echo "$x $y $w $h"
        return 0
      fi
    fi
  fi

  info="$(niri msg focused-window 2>/dev/null || true)"

  # Not: Pencere ekrandan taşınca niri negatif koordinat basabiliyor; o yüzden -? kullanıyoruz.
  # Ayrıca bazı sürümlerde "Workspace view position" yazımı görülebiliyor.
  x="$(echo "$info" | sed -n 's/^[[:space:]]*Workspace[- ]view position:[[:space:]]*\\(-\\{0,1\\}[0-9]\\+\\)[, ][[:space:]]*\\(-\\{0,1\\}[0-9]\\+\\).*$/\\1/p' | tail -n1)"
  y="$(echo "$info" | sed -n 's/^[[:space:]]*Workspace[- ]view position:[[:space:]]*\\(-\\{0,1\\}[0-9]\\+\\)[, ][[:space:]]*\\(-\\{0,1\\}[0-9]\\+\\).*$/\\2/p' | tail -n1)"
  w="$(echo "$info" | sed -n 's/^[[:space:]]*Window size:[[:space:]]*\\([0-9]\\+\\)[[:space:]]*x[[:space:]]*\\([0-9]\\+\\).*$/\\1/p' | tail -n1)"
  h="$(echo "$info" | sed -n 's/^[[:space:]]*Window size:[[:space:]]*\\([0-9]\\+\\)[[:space:]]*x[[:space:]]*\\([0-9]\\+\\).*$/\\2/p' | tail -n1)"

  [[ -n "$x" && -n "$y" && -n "$w" && -n "$h" ]] || return 1
  echo "$x $y $w $h"
}

niri_wait_focused_window_xywh() {
  local out
  for _ in {1..30}; do
    if out="$(niri_focused_window_xywh 2>/dev/null)"; then
      echo "$out"
      return 0
    fi
    sleep 0.05
  done
  return 1
}

niri_maybe_resize_mpv() {
  # Large mpv windows can end up huge when coming from tiling -> floating.
  # Hyprland tarafındaki davranışa benzetmek için "büyükse" 640x360'a çekiyoruz.
  niri_require

  local id="$1"
  local x y w h
  local target_w target_h
  target_w="${MPV_NIRI_WIDTH:-640}"
  target_h="${MPV_NIRI_HEIGHT:-360}"

  read -r x y w h <<<"$(niri_wait_focused_window_xywh)" || return 1

  # Küçük pencere (PiP gibi) ise elleme.
  if [[ "$w" -le 700 && "$h" -le 500 ]]; then
    return 0
  fi

  niri msg action set-window-width --id "$id" "$target_w" >/dev/null 2>&1 || true
  niri msg action set-window-height --id "$id" "$target_h" >/dev/null 2>&1 || true

  # Resize sonrası state'in oturması için kısa bekle.
  niri_wait_focused_window_xywh >/dev/null 2>&1 || true
}

niri_focused_output_wh() {
  # Output: "W H" for the focused output.
  # Try focused-output, then fall back to outputs list.
  local info mode w h

  if command -v jq >/dev/null 2>&1; then
    info="$(niri msg -j focused-output 2>/dev/null || true)"
    if [[ -n "$info" ]]; then
      w="$(jq -r '.current_mode.width? // .mode.width? // empty' <<<"$info" 2>/dev/null | head -n1)"
      h="$(jq -r '.current_mode.height? // .mode.height? // empty' <<<"$info" 2>/dev/null | head -n1)"
      if [[ -n "$w" && -n "$h" ]]; then
        echo "$w $h"
        return 0
      fi
    fi
  fi

  info="$(niri msg focused-output 2>/dev/null || true)"
  mode="$(echo "$info" | sed -n 's/.*\\([0-9]\\{3,5\\}x[0-9]\\{3,5\\}\\).*/\\1/p' | head -n1)"

  if [[ -z "$mode" ]]; then
    info="$(niri msg outputs 2>/dev/null || true)"
    mode="$(
      awk '
        BEGIN { focused = 0 }
        /Focused:[[:space:]]+yes/ { focused = 1 }
        focused && match($0, /([0-9]{3,5}x[0-9]{3,5})/, m) { print m[1]; exit }
      ' <<<"$info"
    )"
    if [[ -z "$mode" ]]; then
      mode="$(echo "$info" | sed -n 's/.*\\([0-9]\\{3,5\\}x[0-9]\\{3,5\\}\\).*/\\1/p' | head -n1)"
    fi
  fi

  w="${mode%x*}"
  h="${mode#*x}"
  [[ -n "$w" && -n "$h" && "$w" != "$mode" ]] || return 1
  echo "$w $h"
}

niri_abs() {
  local n="$1"
  if [[ "$n" -lt 0 ]]; then
    echo $(( -n ))
  else
    echo "$n"
  fi
}

niri_clamp() {
  local n="$1"
  local min="$2"
  local max="$3"
  if [[ "$max" -lt "$min" ]]; then
    max="$min"
  fi
  if [[ "$n" -lt "$min" ]]; then
    echo "$min"
  elif [[ "$n" -gt "$max" ]]; then
    echo "$max"
  else
    echo "$n"
  fi
}

niri_move_cycle_corners() {
  niri_require

  local mpv_id
  if mpv_id="$(niri_find_window_id_by_app_id "mpv" 2>/dev/null)"; then
    niri msg action focus-window --id "$mpv_id" >/dev/null 2>&1 || true
    niri msg action move-window-to-floating --id "$mpv_id" >/dev/null 2>&1 || true
    niri_maybe_resize_mpv "$mpv_id" || true
  else
    mpv_id=""
    niri msg action move-window-to-floating >/dev/null 2>&1 || true
  fi

  local margin_x margin_y x y w h ow oh
  # Varsayılanlar: kullanıcının örneğine yakın (x≈1887, y≈105, 640x360, 2560w ekran)
  margin_x="${MPV_NIRI_MARGIN_X:-33}"
  margin_y="${MPV_NIRI_MARGIN_Y:-105}"

  read -r x y w h <<<"$(niri_wait_focused_window_xywh)" || die "Niri: focused-window okunamadı"
  read -r ow oh <<<"$(niri_focused_output_wh)" || die "Niri: output boyutu okunamadı"

  local max_x max_y
  max_x=$((ow - w))
  max_y=$((oh - h))
  if [[ "$max_x" -lt 0 ]]; then max_x=0; fi
  if [[ "$max_y" -lt 0 ]]; then max_y=0; fi

  # Corner targets (BL -> TR -> BR -> TL -> BL)
  local tl_x tl_y tr_x tr_y br_x br_y bl_x bl_y
  tl_x=$margin_x; tl_y=$margin_y
  tr_x=$((ow - w - margin_x)); tr_y=$margin_y
  br_x=$((ow - w - margin_x)); br_y=$((oh - h - margin_y))
  bl_x=$margin_x; bl_y=$((oh - h - margin_y))

  # Clamp to keep fully visible on screen
  tl_x="$(niri_clamp "$tl_x" 0 "$max_x")"
  tr_x="$(niri_clamp "$tr_x" 0 "$max_x")"
  br_x="$(niri_clamp "$br_x" 0 "$max_x")"
  bl_x="$(niri_clamp "$bl_x" 0 "$max_x")"
  tl_y="$(niri_clamp "$tl_y" 0 "$max_y")"
  tr_y="$(niri_clamp "$tr_y" 0 "$max_y")"
  br_y="$(niri_clamp "$br_y" 0 "$max_y")"
  bl_y="$(niri_clamp "$bl_y" 0 "$max_y")"

  local d_tl d_tr d_br d_bl current next tx ty
  d_tl=$(( $(niri_abs $((x - tl_x))) + $(niri_abs $((y - tl_y))) ))
  d_tr=$(( $(niri_abs $((x - tr_x))) + $(niri_abs $((y - tr_y))) ))
  d_br=$(( $(niri_abs $((x - br_x))) + $(niri_abs $((y - br_y))) ))
  d_bl=$(( $(niri_abs $((x - bl_x))) + $(niri_abs $((y - bl_y))) ))

  # Determine nearest
  current="tl"
  if [[ "$d_tr" -le "$d_tl" && "$d_tr" -le "$d_br" && "$d_tr" -le "$d_bl" ]]; then
    current="tr"
  elif [[ "$d_br" -le "$d_tl" && "$d_br" -le "$d_tr" && "$d_br" -le "$d_bl" ]]; then
    current="br"
  elif [[ "$d_bl" -le "$d_tl" && "$d_bl" -le "$d_tr" && "$d_bl" -le "$d_br" ]]; then
    current="bl"
  fi

  case "$current" in
    bl) next="tr"; tx=$tr_x; ty=$tr_y ;;
    tr) next="br"; tx=$br_x; ty=$br_y ;;
    br) next="tl"; tx=$tl_x; ty=$tl_y ;;
    tl) next="bl"; tx=$bl_x; ty=$bl_y ;;
  esac

  local dx dy
  dx=$((tx - x))
  dy=$((ty - y))
  if [[ -n "${mpv_id:-}" ]]; then
    niri msg action move-floating-window --id "$mpv_id" -x "$(printf '%+d' "$dx")" -y "$(printf '%+d' "$dy")" >/dev/null 2>&1 \
      || die "Niri: move-floating-window başarısız"
  else
    niri msg action move-floating-window -x "$(printf '%+d' "$dx")" -y "$(printf '%+d' "$dy")" >/dev/null 2>&1 \
      || die "Niri: move-floating-window başarısız"
  fi

  # Second pass to converge after resize/clamp
  read -r x y w h <<<"$(niri_focused_window_xywh)" 2>/dev/null || true
  if [[ -n "${x:-}" && -n "${y:-}" ]]; then
    dx=$((tx - x))
    dy=$((ty - y))
    if [[ -n "${mpv_id:-}" ]]; then
      niri msg action move-floating-window --id "$mpv_id" -x "$(printf '%+d' "$dx")" -y "$(printf '%+d' "$dy")" >/dev/null 2>&1 || true
    else
      niri msg action move-floating-window -x "$(printf '%+d' "$dx")" -y "$(printf '%+d' "$dy")" >/dev/null 2>&1 || true
    fi
  fi

  notify "mpv-manager" "Niri: ${current} -> ${next}"
}

niri_move_top_right() {
  niri_require

  # Ensure focused window is floating so we can move it.
  niri msg action move-window-to-floating >/dev/null 2>&1 || true

  # Compute target position based on focused output size + current window size.
  local margin_x margin_y x y w h ow oh tx ty dx dy
  margin_x="${MPV_NIRI_MARGIN_X:-33}"
  margin_y="${MPV_NIRI_MARGIN_Y:-105}"

  read -r x y w h <<<"$(niri_focused_window_xywh)" || {
    notify "mpv-manager" "Niri: focused-window okunamadı"
    return 1
  }
  if read -r ow oh <<<"$(niri_focused_output_wh)"; then
    tx=$((ow - w - margin_x))
    ty=$((margin_y))

    # Clamp (keep visible even if sizes are weird)
    local max_x max_y
    max_x=$((ow - w))
    max_y=$((oh - h))
    if [[ "$max_x" -lt 0 ]]; then max_x=0; fi
    if [[ "$max_y" -lt 0 ]]; then max_y=0; fi
    tx="$(niri_clamp "$tx" 0 "$max_x")"
    ty="$(niri_clamp "$ty" 0 "$max_y")"
  else
    die "Niri: output boyutu okunamadı"
  fi

  dx=$((tx - x))
  dy=$((ty - y))

  # Apply twice to converge if niri adjusts/clamps after resize.
  niri msg action move-floating-window -x "$(printf '%+d' "$dx")" -y "$(printf '%+d' "$dy")" >/dev/null 2>&1 || true
  read -r x y w h <<<"$(niri_focused_window_xywh)" 2>/dev/null || true
  if [[ -n "${x:-}" && -n "${y:-}" ]]; then
    dx=$((tx - x))
    dy=$((ty - y))
    niri msg action move-floating-window -x "$(printf '%+d' "$dx")" -y "$(printf '%+d' "$dy")" >/dev/null 2>&1 || true
  fi

  notify "mpv-manager" "Niri: mpv -> (${tx}, ${ty})"
}

start_mpv() {
  case "$(compositor)" in
    hyprland) hypr_start_mpv ;;
    niri)
      command -v mpv >/dev/null 2>&1 || die "mpv not found"
      if mpv_running && have_socket; then
        notify "mpv-manager" "MPV zaten çalışıyor"
        return 0
      fi
      rm -f "$SOCKET_PATH" 2>/dev/null || true
      mpv --player-operation-mode=pseudo-gui \
        --input-ipc-server="$SOCKET_PATH" \
        --idle \
        --autofit=640x360 \
        --autofit-larger=640x360 \
        -- >/dev/null 2>&1 &
      disown || true
      notify "mpv-manager" "MPV başlatıldı (Niri 640x360)"
      ;;
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
  if [[ "$(compositor)" == "niri" ]]; then
    mpv --player-operation-mode=pseudo-gui \
      --input-ipc-server="$SOCKET_PATH" \
      --idle \
      --no-audio-display \
      --autofit=640x360 \
      --autofit-larger=640x360 \
      "$url" >/dev/null 2>&1 &
  else
    mpv --player-operation-mode=pseudo-gui \
      --input-ipc-server="$SOCKET_PATH" \
      --idle \
      --no-audio-display \
      "$url" >/dev/null 2>&1 &
  fi
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
            move) niri_move_cycle_corners ;;
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
