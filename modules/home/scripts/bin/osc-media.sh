#!/usr/bin/env bash
# osc-media.sh - Unified media entrypoint (Spotify/MPC/VLC/MPV/Radio/Lo-Fi)
#
# This script intentionally consolidates several older helpers into a single
# command. Keybinds should target `osc-media` instead of individual scripts.

set -Eeuo pipefail

show_help() {
	cat <<'EOF'
osc-media - unified media controls

Usage:
  osc-media <command> [args...]

Commands:
  spotify [subcmd]     Spotify controller (playerctl/dbus). Subcommands match old osc-spotify.
  mpc <subcmd>         MPD/mpc controller (toggle/next/prev/vol/...)
  vlc                 VLC play/pause toggle
  mpv <subcmd>         MPV helper (IPC + compositor-aware window management)
  radio [args...]      Internet radio player (interactive by default)
  lofi                 Toggle Lo-Fi stream via mpv --no-video

Examples:
  osc-media spotify                 # play/pause
  osc-media spotify next
  osc-media mpc toggle
  osc-media vlc
  osc-media mpv playback
  osc-media radio                   # interactive menu
  osc-media lofi
EOF
}

die() {
	echo "osc-media: $*" >&2
	exit 1
}

osc_media_lofi() (
	# Formerly: lofi.sh
	if pgrep -x mpv >/dev/null 2>&1; then
		pkill mpv
	else
		command -v runbg >/dev/null 2>&1 || die "runbg not found"
		runbg mpv --no-video "https://www.youtube.com/live/jfKfPfyJRdk?si=OF0HKrYFFj33BzMo"
	fi
)

osc_media_mpv() (
	# Formerly: mpv-manager.sh
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
		*Hyprland* | *hyprland*) echo "hyprland" ;;
		*niri* | *Niri*) echo "niri" ;;
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
Usage: osc-media mpv <command>

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
				if [[ -S "$candidate" && "$candidate" != *niri-flow* ]]; then
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
			[[ -n "$id" ]] && {
				echo "$id"
				return 0
			}
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
		niri_require
		local x y w h

		if command -v jq >/dev/null 2>&1; then
			niri msg -j focused-window 2>/dev/null \
				| jq -r '[.x, .y, .width, .height] | @tsv' 2>/dev/null
			return
		fi

		x="$(
			niri msg focused-window 2>/dev/null | awk -F: '/X:/ {gsub(/ /,"",$2); print $2}'
		)"
		y="$(
			niri msg focused-window 2>/dev/null | awk -F: '/Y:/ {gsub(/ /,"",$2); print $2}'
		)"
		w="$(
			niri msg focused-window 2>/dev/null | awk -F: '/Width:/ {gsub(/ /,"",$2); print $2}'
		)"
		h="$(
			niri msg focused-window 2>/dev/null | awk -F: '/Height:/ {gsub(/ /,"",$2); print $2}'
		)"
		echo "$x $y $w $h"
	}

	niri_focused_output_wh() {
		niri_require
		if command -v jq >/dev/null 2>&1; then
			niri msg -j focused-output 2>/dev/null \
				| jq -r '[.width, .height] | @tsv' 2>/dev/null
			return
		fi
		niri msg focused-output 2>/dev/null | awk -F: '
      /Width:/ {gsub(/ /,"",$2); w=$2}
      /Height:/ {gsub(/ /,"",$2); h=$2}
      END {print w, h}
    '
	}

	niri_clamp() {
		local value="$1"
		local min="$2"
		local max="$3"
		if [[ "$value" -lt "$min" ]]; then
			echo "$min"
		elif [[ "$value" -gt "$max" ]]; then
			echo "$max"
		else
			echo "$value"
		fi
	}

	niri_move_cycle_corners() {
		niri_require

		# Ensure focused window is floating so we can move it.
		niri msg action move-window-to-floating >/dev/null 2>&1 || true

		# Basic corner cycling based on current position.
		local margin_x margin_y x y w h ow oh next current tx ty dx dy
		margin_x="${MPV_NIRI_MARGIN_X:-33}"
		margin_y="${MPV_NIRI_MARGIN_Y:-105}"

		read -r x y w h <<<"$(niri_focused_window_xywh)" || {
			notify "mpv-manager" "Niri: focused-window okunamadı"
			return 1
		}
		read -r ow oh <<<"$(niri_focused_output_wh)" || die "Niri: output boyutu okunamadı"

		local tl_x tl_y tr_x tr_y br_x br_y bl_x bl_y
		tl_x=$((margin_x))
		tl_y=$((margin_y))
		tr_x=$((ow - w - margin_x))
		tr_y=$((margin_y))
		br_x=$((ow - w - margin_x))
		br_y=$((oh - h - margin_y))
		bl_x=$((margin_x))
		bl_y=$((oh - h - margin_y))

		tr_x="$(niri_clamp "$tr_x" 0 $((ow - w > 0 ? ow - w : 0)))"
		br_x="$(niri_clamp "$br_x" 0 $((ow - w > 0 ? ow - w : 0)))"
		br_y="$(niri_clamp "$br_y" 0 $((oh - h > 0 ? oh - h : 0)))"
		bl_y="$(niri_clamp "$bl_y" 0 $((oh - h > 0 ? oh - h : 0)))"

		current="top-left"
		if [[ "$x" -gt $((ow / 2)) && "$y" -lt $((oh / 2)) ]]; then current="top-right"; fi
		if [[ "$x" -gt $((ow / 2)) && "$y" -gt $((oh / 2)) ]]; then current="bottom-right"; fi
		if [[ "$x" -lt $((ow / 2)) && "$y" -gt $((oh / 2)) ]]; then current="bottom-left"; fi

		case "$current" in
		top-left) next="top-right" ;;
		top-right) next="bottom-right" ;;
		bottom-right) next="bottom-left" ;;
		*) next="top-left" ;;
		esac

		case "$next" in
		top-left)
			tx="$tl_x"
			ty="$tl_y"
			;;
		top-right)
			tx="$tr_x"
			ty="$tr_y"
			;;
		bottom-right)
			tx="$br_x"
			ty="$br_y"
			;;
		bottom-left)
			tx="$bl_x"
			ty="$bl_y"
			;;
		esac

		dx=$((tx - x))
		dy=$((ty - y))
		niri msg action move-floating-window -x "$(printf '%+d' "$dx")" -y "$(printf '%+d' "$dy")" >/dev/null 2>&1 || true

		notify "mpv-manager" "Niri: ${current} -> ${next}"
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
		(
			cd "$DOWNLOADS_DIR" && yt-dlp -f "bestvideo+bestaudio/best" --merge-output-format mp4 --embed-thumbnail --add-metadata "$url"
		)
		notify "mpv-manager" "İndirme tamamlandı: $DOWNLOADS_DIR"
	}

	main() {
		[[ $# -ge 1 ]] || {
			usage
			exit 1
		}
		cmd="$1"
		shift

		case "$cmd" in
		move | stick | wallpaper)
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
		-h | --help | help)
			usage
			;;
		*)
			usage
			die "Bilinmeyen komut: $cmd"
			;;
		esac
	}

	main "$@"
)

osc_media_spotify() (
	# Formerly: osc-spotify.sh
	#######################################
	#
	# Version: 2.3.0
	# Date: 2025-07-19
	# Original Author: Kenan Pelit
	# Repository: github.com/kenanpelit/dotfiles
	# Description: Geliştirilmiş HyprFlow Spotify Controller (Hyprland & Wayland)
	#
	# License: MIT
	#
	#######################################

	# Renk tanımlamaları
	GREEN='\033[0;32m'
	YELLOW='\033[1;33m'
	BLUE='\033[0;34m'
	RED='\033[0;31m'
	CYAN='\033[0;36m'
	PURPLE='\033[0;35m'
	NC='\033[0m' # No Color

	# Yapılandırma değişkenleri
	PLAYER="spotify"
	TIMEOUT=10                                                    # Spotify'ın başlaması için maksimum bekleme süresi (saniye)
	ICON_PATH="/usr/share/icons/hicolor/256x256/apps/spotify.png" # Spotify icon path (varsa)
	COMMAND="${1:-}"                                              # Komut satırı parametresi
	VOL_INCREMENT=10                                              # Ses artışı yüzdesi

	# Hyprland için pencere kontrolü
	HYPR_ACTIVE=$(command -v hyprctl &>/dev/null && echo "true" || echo "false")

	# MPRIS için destek kontrolü
	MPRIS_SUPPORT=$(command -v dbus-send &>/dev/null && echo "true" || echo "false")

	# bc komutunun varlığını kontrol et
	BC_AVAILABLE=$(command -v bc &>/dev/null && echo "true" || echo "false")

	# Yardım fonksiyonu
	function show_help {
		echo -e "${BLUE}HyprFlow Spotify Kontrolcü${NC} - Hyprland & Wayland Edition"
		echo -e "${CYAN}Version: 2.3.0${NC}"
		echo "Kullanım: $(basename $0) spotify [KOMUT]"
		echo ""
		echo -e "${YELLOW}Temel Kontroller:${NC}"
		echo "  play           Oynatmaya başla"
		echo "  pause          Duraklat"
		echo "  play-pause     Oynatma/duraklatma geçişi yap (parametre verilmezse varsayılan)"
		echo "  toggle         Oynatma/duraklatma geçişi yap (play-pause ile aynı)"
		echo "  next           Sonraki şarkıya geç"
		echo "  prev           Önceki şarkıya geç"
		echo "  stop           Spotify'ı durdur"
		echo ""
		echo -e "${YELLOW}Ses Kontrolleri:${NC}"
		echo "  volume-up      Ses seviyesini artır"
		echo "  volume-down    Ses seviyesini azalt"
		echo "  volume <0-100> Ses seviyesini ayarla (0-100 arası değer)"
		echo ""
		echo -e "${YELLOW}Özellik Kontrolleri:${NC}"
		echo "  toggle-shuffle Karıştırma modunu aç/kapat"
		echo "  toggle-repeat  Tekrar modunu değiştir"
		echo ""
		echo -e "${YELLOW}Bilgi ve Paylaşım:${NC}"
		echo "  status         Durum bilgisini göster"
		echo "  share          Çalan şarkının URL ve URI'sini göster"
		echo ""
		echo -e "${YELLOW}Pencere Yönetimi:${NC}"
		echo "  focus          Spotify penceresini odakla"
		echo "  info           Aktif Spotify penceresi hakkında bilgi göster"
		echo ""
		echo -e "${YELLOW}Sistem:${NC}"
		echo "  quit           Spotify'ı kapat"
		echo "  help           Bu yardım mesajını göster"
		exit 0
	}

	# Gelişmiş bildirim gönderme fonksiyonu
	function send_notification {
		local title="$1"
		local message="$2"
		local urgency="${3:-normal}"
		local timeout="${4:-2000}"

		# İkon varsa kullan
		if [ -f "$ICON_PATH" ]; then
			notify-send -t "$timeout" -u "$urgency" "$title" "$message" -i "$ICON_PATH" -h string:x-canonical-private-synchronous:spotify-control
		else
			notify-send -t "$timeout" -u "$urgency" "$title" "$message" -h string:x-canonical-private-synchronous:spotify-control
		fi
	}

	# Şarkı bilgilerini alma fonksiyonu - Düzeltilmiş
	function get_track_info {
		local artist=$(playerctl -p "$PLAYER" metadata artist 2>/dev/null)
		local title=$(playerctl -p "$PLAYER" metadata title 2>/dev/null)
		local album=$(playerctl -p "$PLAYER" metadata album 2>/dev/null)

		# En azından title varsa devam et
		if [ -n "$title" ]; then
			if [ -n "$artist" ] && [ -n "$album" ]; then
				echo "$title - $artist ($album)"
			elif [ -n "$artist" ]; then
				echo "$title - $artist"
			elif [ -n "$album" ]; then
				echo "$title ($album)"
			else
				echo "$title" # Sadece başlık varsa bile göster (podcast için)
			fi
			return 0
		else
			return 1
		fi
	}

	# Çalan şarkının URL ve URI'sini alma fonksiyonu
	function get_track_url {
		# MPRIS ile URL'yi al
		if [ "$MPRIS_SUPPORT" = "true" ]; then
			url=$(dbus-send --print-reply --dest=org.mpris.MediaPlayer2.spotify \
				/org/mpris/MediaPlayer2 \
				org.freedesktop.DBus.Properties.Get \
				string:'org.mpris.MediaPlayer2.Player' \
				string:'Metadata' | awk -F '"' '/xesam:url/ {getline; print $2}' 2>/dev/null)

			if [[ "$url" == "https://open.spotify.com/track/"* ]]; then
				track_id="${url##*/}"
				uri="spotify:track:$track_id"
				echo -e "${GREEN}Spotify URL:${NC} $url"
				echo -e "${GREEN}Spotify URI:${NC} $uri"

				# URL'yi panoya kopyala (eğer xclip varsa)
				if command -v xclip &>/dev/null; then
					echo "$url" | xclip -selection clipboard
					send_notification "Spotify Bağlantıları" "📋 URL panoya kopyalandı\nURL: $url\nURI: $uri" "normal" 5000
				else
					send_notification "Spotify Bağlantıları" "URL: $url\nURI: $uri" "normal" 5000
				fi
				return 0
			else
				echo -e "${RED}Şu anda çalan şarkı yok veya bilgi alınamadı.${NC}"
				send_notification "Spotify" "⚠️ Şarkı bilgisi alınamadı" "critical"
				return 1
			fi
		else
			echo -e "${RED}DBUS desteği yok. Bu özellik kullanılamıyor.${NC}"
			send_notification "Spotify" "⚠️ DBUS desteği yok" "critical"
			return 1
		fi
	}

	# Karıştırma modunu değiştir
	function toggle_shuffle {
		if [ "$MPRIS_SUPPORT" = "true" ]; then
			# Mevcut karıştırma durumunu al
			current_shuffle=$(dbus-send --print-reply \
				--dest=org.mpris.MediaPlayer2.spotify \
				/org/mpris/MediaPlayer2 \
				org.freedesktop.DBus.Properties.Get \
				string:'org.mpris.MediaPlayer2.Player' \
				string:'Shuffle' | awk '/boolean/ {print $2}' 2>/dev/null)

			# Durumu tersine çevir
			new_shuffle=$([ "$current_shuffle" = "true" ] && echo "false" || echo "true")

			# Yeni durumu ayarla
			dbus-send --print-reply --dest=org.mpris.MediaPlayer2.spotify \
				/org/mpris/MediaPlayer2 \
				org.freedesktop.DBus.Properties.Set \
				string:'org.mpris.MediaPlayer2.Player' \
				string:'Shuffle' \
				variant:boolean:$new_shuffle >/dev/null

			# Bildirim gönder
			if [ "$new_shuffle" = "true" ]; then
				send_notification "Spotify" "🔀 Karıştırma açık"
			else
				send_notification "Spotify" "➡️ Karıştırma kapalı"
			fi
		else
			echo -e "${RED}DBUS desteği yok. Bu özellik kullanılamıyor.${NC}"
			send_notification "Spotify" "⚠️ DBUS desteği yok" "critical"
			return 1
		fi
	}

	# Tekrar modunu değiştir
	function toggle_repeat {
		if [ "$MPRIS_SUPPORT" = "true" ]; then
			# Mevcut tekrar durumunu al
			current_loop=$(dbus-send --print-reply \
				--dest=org.mpris.MediaPlayer2.spotify \
				/org/mpris/MediaPlayer2 \
				org.freedesktop.DBus.Properties.Get \
				string:'org.mpris.MediaPlayer2.Player' \
				string:'LoopStatus' | awk -F '"' '{print $2}' 2>/dev/null)

			# Durumu döngüsel olarak değiştir
			case "$current_loop" in
			"None")
				new_loop="Track"
				message="🔂 Parça tekrarı açık"
				;;
			"Track")
				new_loop="Playlist"
				message="🔁 Liste tekrarı açık"
				;;
			*)
				new_loop="None"
				message="➡️ Tekrar kapalı"
				;;
			esac

			# Yeni durumu ayarla
			dbus-send --print-reply --dest=org.mpris.MediaPlayer2.spotify \
				/org/mpris/MediaPlayer2 \
				org.freedesktop.DBus.Properties.Set \
				string:'org.mpris.MediaPlayer2.Player' \
				string:'LoopStatus' \
				variant:string:$new_loop >/dev/null

			# Bildirim gönder
			send_notification "Spotify" "$message"
		else
			echo -e "${RED}DBUS desteği yok. Bu özellik kullanılamıyor.${NC}"
			send_notification "Spotify" "⚠️ DBUS desteği yok" "critical"
			return 1
		fi
	}

	# Spotify'ı kapat
	function quit_spotify {
		if pgrep "$PLAYER" >/dev/null; then
			killall "$PLAYER" 2>/dev/null
			send_notification "Spotify" "❌ Spotify kapatıldı"
			return 0
		else
			send_notification "Spotify" "ℹ️ Spotify zaten çalışmıyor"
			return 1
		fi
	}

	# Spotify'ın çalışıp çalışmadığını kontrol et
	function check_spotify_running {
		if ! pgrep "$PLAYER" >/dev/null; then
			send_notification "Spotify" "🚀 Spotify çalışmıyor, başlatılıyor..." "normal" 3000
			spotify &>/dev/null &

			# Spotify'ın başlamasını bekle
			echo -e "${YELLOW}Spotify başlatılıyor...${NC}"
			for i in $(seq 1 $TIMEOUT); do
				if pgrep "$PLAYER" >/dev/null; then
					echo -e "${GREEN}Spotify başlatıldı.${NC}"
					# Spotify process çalışıyor, ama playerctl'in hazır olmasını bekle
					sleep 3
					return 0
				fi
				echo -n "."
				sleep 1
			done

			echo -e "\n${RED}Hata: Spotify başlatılamadı veya çok uzun sürdü.${NC}"
			send_notification "Spotify" "⚠️ Başlatma zaman aşımına uğradı" "critical" 4000
			return 1
		fi
		return 0
	}

	# Spotify'ın hazır olup olmadığını kontrol et
	function check_spotify_ready {
		for i in $(seq 1 $TIMEOUT); do
			if playerctl -p "$PLAYER" status &>/dev/null; then
				return 0
			fi
			sleep 0.5
		done

		send_notification "Spotify" "⚠️ Spotify hazır değil, komut gönderilemedi" "critical" 3000
		return 1
	}

	# Sadece oynat
	function play_music {
		check_spotify_running || return 1
		check_spotify_ready || return 1

		playerctl -p "$PLAYER" play

		# Şarkı bilgisini göster
		if track_info=$(get_track_info); then
			send_notification "Spotify" "▶️ Oynatılıyor: $track_info" "normal" 3000
		else
			send_notification "Spotify" "▶️ Oynatılıyor"
		fi
	}

	# Sadece duraklat
	function pause_music {
		check_spotify_running || return 1
		check_spotify_ready || return 1

		playerctl -p "$PLAYER" pause
		send_notification "Spotify" "⏸️ Duraklatıldı"
	}

	# Play/Pause işlevi - Temiz Versiyon
	function toggle_playback {
		check_spotify_running || return 1
		check_spotify_ready || return 1

		STATUS=$(playerctl -p "$PLAYER" status 2>/dev/null)

		# Önce şarkı bilgisini al (her durumda)
		track_info=$(get_track_info)

		case $STATUS in
		"Playing")
			playerctl -p "$PLAYER" pause
			if [ -n "$track_info" ]; then
				send_notification "Spotify" "⏸️ Duraklatıldı: $track_info" "normal" 3000
			else
				send_notification "Spotify" "⏸️ Duraklatıldı"
			fi
			;;
		"Paused")
			playerctl -p "$PLAYER" play
			if [ -n "$track_info" ]; then
				send_notification "Spotify" "▶️ Oynatılıyor: $track_info" "normal" 3000
			else
				send_notification "Spotify" "▶️ Oynatılıyor"
			fi
			;;
		*)
			# Spotify açık ama yanıt vermiyorsa
			send_notification "Spotify" "⚠️ Spotify yanıt vermiyor, yeniden başlatın" "critical"
			;;
		esac
	}

	# Sonraki şarkıya geç
	function next_track {
		check_spotify_running || return 1
		check_spotify_ready || return 1

		playerctl -p "$PLAYER" next
		sleep 0.5 # Metadata'nın güncellenmesi için bekle

		if track_info=$(get_track_info); then
			send_notification "Spotify" "⏭️ Sonraki parça: $track_info" "normal" 3000
		else
			send_notification "Spotify" "⏭️ Sonraki parçaya geçildi"
		fi
	}

	# Önceki şarkıya geç
	function previous_track {
		check_spotify_running || return 1
		check_spotify_ready || return 1

		playerctl -p "$PLAYER" previous
		sleep 0.5 # Metadata'nın güncellenmesi için bekle

		if track_info=$(get_track_info); then
			send_notification "Spotify" "⏮️ Önceki parça: $track_info" "normal" 3000
		else
			send_notification "Spotify" "⏮️ Önceki parçaya geçildi"
		fi
	}

	# Spotify'ı durdur
	function stop_playback {
		check_spotify_running || return 1
		check_spotify_ready || return 1

		playerctl -p "$PLAYER" stop
		send_notification "Spotify" "⏹️ Durduruldu"
	}

	# Ses seviyesini artır
	function volume_up {
		check_spotify_running || return 1
		check_spotify_ready || return 1

		# Mevcut ses seviyesini al
		current_vol=$(playerctl -p "$PLAYER" volume 2>/dev/null)

		current_percent=$(echo "$current_vol * 100" | awk '{printf "%.0f", $1}')
		new_percent=$((current_percent + VOL_INCREMENT))
		if [ $new_percent -gt 100 ]; then
			new_percent=100
		fi
		new_vol=$(echo "$new_percent / 100" | awk '{printf "%.2f", $1}')
		vol_percent=$new_percent

		playerctl -p "$PLAYER" volume "$new_vol"
		send_notification "Spotify" "🔊 Ses: $vol_percent%"
	}

	# Ses seviyesini azalt
	function volume_down {
		check_spotify_running || return 1
		check_spotify_ready || return 1

		# Mevcut ses seviyesini al
		current_vol=$(playerctl -p "$PLAYER" volume 2>/dev/null)

		current_percent=$(echo "$current_vol * 100" | awk '{printf "%.0f", $1}')
		new_percent=$((current_percent - VOL_INCREMENT))
		if [ $new_percent -lt 0 ]; then
			new_percent=0
		fi
		new_vol=$(echo "$new_percent / 100" | awk '{printf "%.2f", $1}')
		vol_percent=$new_percent

		playerctl -p "$PLAYER" volume "$new_vol"
		send_notification "Spotify" "🔉 Ses: $vol_percent%"
	}

	# Ses seviyesini belirli bir değere ayarla
	function set_volume {
		check_spotify_running || return 1
		check_spotify_ready || return 1

		# Parametre kontrolü
		if [[ $1 =~ ^[0-9]+$ ]] && [[ $1 -ge 0 && $1 -le 100 ]]; then
			new_vol=$(echo "$1 / 100" | awk '{printf "%.2f", $1}')
			playerctl -p "$PLAYER" volume "$new_vol"
			send_notification "Spotify" "🎵 Ses: $1%"
		else
			echo -e "${RED}Hatalı ses seviyesi değeri. 0-100 arası bir değer girin.${NC}"
			send_notification "Spotify" "⚠️ Hatalı ses seviyesi değeri" "critical"
			return 1
		fi
	}

	# Durum bilgisini göster
	function show_status {
		check_spotify_running || return 1
		check_spotify_ready || return 1

		STATUS=$(playerctl -p "$PLAYER" status 2>/dev/null)

		# Şarkı bilgilerini al
		if track_info=$(get_track_info); then
			# Ses seviyesini al
			vol=$(playerctl -p "$PLAYER" volume 2>/dev/null)
			vol_percent=$(echo "$vol * 100" | awk '{printf "%.0f", $1}')

			# Durum simgesini belirle
			status_icon="⏸️"
			if [ "$STATUS" = "Playing" ]; then
				status_icon="▶️"
			fi

			send_notification "Spotify - $status_icon $STATUS" "$track_info\n🎵 Ses: $vol_percent%" "normal" 5000
		else
			send_notification "Spotify" "⚠️ Şarkı bilgisi alınamadı" "critical"
		fi
	}

	# Hyprland ile Spotify penceresini odakla
	function focus_spotify {
		check_spotify_running || return 1

		if [ "$HYPR_ACTIVE" = "true" ]; then
			# Spotify penceresini bul ve odakla
			SPOTIFY_WINDOW=$(hyprctl clients | grep -B 12 "class: Spotify" | grep "Window" | awk '{print $2}')

			if [ -n "$SPOTIFY_WINDOW" ]; then
				hyprctl dispatch focuswindow "class:^(Spotify)$"
				send_notification "Spotify" "🎯 Spotify penceresi odaklandı"
			else
				send_notification "Spotify" "⚠️ Spotify penceresi bulunamadı" "critical"
			fi
		else
			send_notification "Spotify" "⚠️ Hyprland aktif değil veya hyprctl bulunamadı" "critical"
		fi
	}

	# Hyprland ile Spotify pencere bilgilerini göster
	function spotify_window_info {
		check_spotify_running || return 1

		if [ "$HYPR_ACTIVE" = "true" ]; then
			# Spotify pencere bilgisini al
			SPOTIFY_INFO=$(hyprctl clients | grep -A 20 "class: Spotify")

			if [ -n "$SPOTIFY_INFO" ]; then
				echo -e "${BLUE}Spotify Pencere Bilgisi:${NC}"
				echo "$SPOTIFY_INFO"

				# Ayrıca bildirim olarak da gönder
				WINDOW_ID=$(echo "$SPOTIFY_INFO" | grep "Window" | awk '{print $2}')
				WORKSPACE=$(echo "$SPOTIFY_INFO" | grep "workspace:" | awk '{print $2}')
				TITLE=$(echo "$SPOTIFY_INFO" | grep "title:" | cut -d':' -f2-)

				send_notification "Spotify Pencere Bilgisi" "🪟 ID: $WINDOW_ID\n🖥️ Çalışma Alanı: $WORKSPACE\n📝 Başlık: $TITLE" "normal" 5000
			else
				echo -e "${RED}Spotify penceresi bulunamadı.${NC}"
				send_notification "Spotify" "⚠️ Spotify penceresi bulunamadı" "critical"
			fi
		else
			echo -e "${RED}Hyprland aktif değil veya hyprctl bulunamadı.${NC}"
			send_notification "Spotify" "⚠️ Hyprland aktif değil veya hyprctl bulunamadı" "critical"
		fi
	}

	# Ana işlev
	case $COMMAND in
	"next")
		next_track
		;;
	"prev" | "previous")
		previous_track
		;;
	"play")
		play_music
		;;
	"pause")
		pause_music
		;;
	"stop")
		stop_playback
		;;
	"volume-up")
		volume_up
		;;
	"volume-down")
		volume_down
		;;
	"volume")
		shift
		set_volume "${1:-}"
		;;
	"status")
		show_status
		;;
	"focus")
		focus_spotify
		;;
	"info")
		spotify_window_info
		;;
	"share")
		get_track_url
		;;
	"toggle-shuffle")
		toggle_shuffle
		;;
	"toggle-repeat")
		toggle_repeat
		;;
	"quit")
		quit_spotify
		;;
	"help" | "-h" | "--help")
		show_help
		;;
	"play-pause" | "toggle" | "")
		toggle_playback
		;;
	*)
		echo -e "${RED}Hata: Geçersiz komut '${COMMAND}'${NC}"
		show_help
		;;
	esac

	exit 0
)

osc_media_mpc() (
	# Formerly: mpc-control.sh
	# mpc-control.sh - mpd/mpc kontrol kısayolu
	# Çalma, duraklatma, ileri/geri ve ses ayarlarını hızlı komutlarla yönetir.

	# İkon tanımlamaları (Nerd Font ikonları)
	PLAY_ICON="󰐊"
	PAUSE_ICON="󰏤"
	STOP_ICON="󰓛"
	NEXT_ICON="󰒭"
	PREV_ICON="󰒮"
	VOLUME_UP_ICON="󰝝"
	VOLUME_DOWN_ICON="󰝞"
	VOLUME_MUTE_ICON="󰝟"
	MUSIC_ICON="󱍙"
	ERROR_ICON="󰀩"

	# Bildirim süreleri (milisaniye)
	NOTIFY_TIMEOUT_NORMAL=3000 # Normal bildirimler
	NOTIFY_TIMEOUT_SHORT=1500  # Ses değişimi
	NOTIFY_TIMEOUT_LONG=5000   # Hata bildirimleri

	# Renk tanımlamaları
	RED='\033[0;31m'
	GREEN='\033[0;32m'
	BLUE='\033[0;34m'
	NC='\033[0m'

	# Song Info Format
	format() {
		local info
		info=$(mpc status -f "[[%artist% - ]%title%]|[%file%]" | head -n1)
		# Dosya adıysa .mp3 uzantısını kaldır
		echo "${info%.mp3}"
	}

	# Progress bar oluştur
	create_progress_bar() {
		local current_time total_time percentage
		current_time=$(mpc status | awk 'NR==2 {print $3}' | cut -d'/' -f1)
		total_time=$(mpc status | awk 'NR==2 {print $3}' | cut -d'/' -f2)
		percentage=$(mpc status | awk 'NR==2 {print $4}' | tr -d '()%')
		echo "$current_time / $total_time ($percentage%)"
	}

	# Gelişmiş notification gönder
	send_notification() {
		local title="$1"
		local message="$2"
		local icon="$3"
		local timeout="${4:-$NOTIFY_TIMEOUT_NORMAL}"
		local urgency="${5:-normal}"

		notify-send -t "$timeout" \
			-h string:x-canonical-private-synchronous:mpd \
			-u "$urgency" \
			"$title" \
			"$message" \
			-i "$icon"
	}

	# Durum bilgisi
	status() {
		local state current_song progress
		state=$(mpc status | sed -n 2p | awk '{print $1}' | tr -d '[]')
		current_song="$(format)"
		progress="$(create_progress_bar)"

		case $state in
		"playing")
			echo -e "${GREEN}$PLAY_ICON${NC} $current_song"
			send_notification \
				"$PLAY_ICON Şimdi Çalıyor" \
				"$current_song\n$progress" \
				"media-playback-start" \
				"$NOTIFY_TIMEOUT_NORMAL"
			;;
		"paused")
			echo -e "${BLUE}$PAUSE_ICON${NC} $current_song"
			send_notification \
				"$PAUSE_ICON Duraklatıldı" \
				"$current_song\n$progress" \
				"media-playback-pause" \
				"$NOTIFY_TIMEOUT_NORMAL"
			;;
		*)
			echo -e "${RED}$STOP_ICON${NC} Stopped"
			send_notification \
				"$STOP_ICON Durduruldu" \
				"MPD durduruldu" \
				"media-playback-stop" \
				"$NOTIFY_TIMEOUT_SHORT"
			;;
		esac
	}

	# Ses kontrolü
	volume() {
		local vol vol_icon
		vol=$(mpc volume | cut -d':' -f2 | tr -d ' %')

		if [ "$vol" -ge 70 ]; then
			vol_icon="󰕾"
		elif [ "$vol" -ge 30 ]; then
			vol_icon="󰖀"
		else
			vol_icon="󰕿"
		fi

		echo "$vol%"
		return "$vol"
	}

	# Kullanım mesajı
	usage() {
		echo "Kullanım: osc-media mpc [KOMUT]"
		echo
		echo "Komutlar:"
		echo "  toggle    - Oynat/Duraklat"
		echo "  play      - Oynat"
		echo "  pause     - Duraklat"
		echo "  stop      - Durdur"
		echo "  next      - Sonraki parça"
		echo "  prev      - Önceki parça"
		echo "  status    - Durum bilgisi"
		echo "  vol up    - Sesi artır"
		echo "  vol down  - Sesi azalt"
		echo "  help      - Bu mesajı göster"
		exit 1
	}

	# Ana kontrol fonksiyonu
	case "${1:-}" in
	"toggle")
		mpc toggle >/dev/null
		status
		;;
	"play")
		mpc play >/dev/null
		status
		;;
	"pause")
		mpc pause >/dev/null
		status
		;;
	"stop")
		mpc stop >/dev/null
		status
		;;
	"next")
		mpc next >/dev/null
		song_info="$(format)"
		progress="$(create_progress_bar)"
		echo -e "$NEXT_ICON $song_info"
		send_notification \
			"$NEXT_ICON Sonraki Parça" \
			"$song_info\n$progress" \
			"media-skip-forward" \
			"$NOTIFY_TIMEOUT_NORMAL"
		;;
	"prev")
		mpc prev >/dev/null
		song_info="$(format)"
		progress="$(create_progress_bar)"
		echo -e "$PREV_ICON $song_info"
		send_notification \
			"$PREV_ICON Önceki Parça" \
			"$song_info\n$progress" \
			"media-skip-backward" \
			"$NOTIFY_TIMEOUT_NORMAL"
		;;
	"status")
		status
		;;
	"vol")
		case "${2:-}" in
		"up")
			mpc volume +5 >/dev/null
			vol=$(volume)
			send_notification \
				"$VOLUME_UP_ICON Ses Artırıldı" \
				"Ses Seviyesi: $vol" \
				"audio-volume-high" \
				"$NOTIFY_TIMEOUT_SHORT"
			echo "$vol"
			;;
		"down")
			mpc volume -5 >/dev/null
			vol=$(volume)
			send_notification \
				"$VOLUME_DOWN_ICON Ses Azaltıldı" \
				"Ses Seviyesi: $vol" \
				"audio-volume-low" \
				"$NOTIFY_TIMEOUT_SHORT"
			echo "$vol"
			;;
		*)
			volume
			;;
		esac
		;;
	*)
		usage
		;;
	esac
)

osc_media_vlc() (
	# Formerly: vlc-toggle.sh
	########################################
	#
	# Name: vlc-toggle
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

	# Debug (1=on, 0=off) — can be overridden: DEBUG=1 vlc-toggle
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
		if ((${#text} > max_len)); then
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

		if [[ -z "${title}" && $(has_cmd hyprctl && has_cmd jq && echo 0 || echo 1) -eq 0 ]]; then
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

		notify-send -i "${NOTIFICATION_ICON}" -t "${NOTIFICATION_TIMEOUT}" \
			"${title}" "${body}"
	}

	main() {
		check_vlc_running

		local player state
		player="$(pick_vlc_player)"
		get_media_info "${player}"

		# Toggle and then read state
		toggle_playback "${player}"
		state="$(get_state "${player}")"

		notify_state "${state}"
	}

	main "$@"
)

osc_media_radio() (
	# Formerly: osc-radio.sh
	# NOTE: this is the original "tradio" script body kept intact.

	# osc-radio.sh - İnternet radyo oynatıcı
	# mpv ile ön tanımlı istasyonları çalar, arayüzden seçim ve bildirim sağlar.

	# Disable debug output
	set +x

	# Color definitions
	RED='\033[0;31m'
	GREEN='\033[0;32m'
	BLUE='\033[0;34m'
	YELLOW='\033[1;33m'
	NC='\033[0m' # No Color
	BOLD='\033[1m'

	# Radio stations - Virgin Radio first, rest alphabetically sorted
	declare -A RADIOS
	RADIOS=(
		["Virgin Radio"]="http://playerservices.streamtheworld.com/api/livestream-redirect/VIRGIN_RADIO_SC"
		["Joy FM"]="http://playerservices.streamtheworld.com/api/livestream-redirect/JOY_FM_SC"
		["Joy Jazz"]="http://playerservices.streamtheworld.com/api/livestream-redirect/JOY_JAZZ_SC"
		["Kral 45lik"]="https://ssldyg.radyotvonline.com/kralweb/smil:kral45lik.smil/chunklist_w1544647566_b64000.m3u8"
		["Metro FM"]="http://playerservices.streamtheworld.com/api/livestream-redirect/METRO_FM_SC"
		["NTV Radyo"]="http://ntvrdsc.radyotvonline.com/"
		["Pal Akustik"]="http://shoutcast.radyogrup.com:2030/"
		["Pal Dance"]="http://shoutcast.radyogrup.com:2040/"
		["Pal Nostalji"]="http://shoutcast.radyogrup.com:1010/"
		["Pal Orient"]="http://shoutcast.radyogrup.com:1050/"
		["Pal Slow"]="http://shoutcast.radyogrup.com:2020/"
		["Pal Station"]="http://shoutcast.radyogrup.com:1020/"
		["Radyo 45lik"]="http://104.236.16.158:3060/"
		["Radyo Dejavu"]="http://radyodejavu.canliyayinda.com:8054/"
		["Radyo Voyage"]="http://voyagewmp.radyotvonline.com:80/"
		["Retro Türk"]="http://playerservices.streamtheworld.com/api/livestream-redirect/RETROTURK_SC"
		["World Hits"]="http://37.247.98.8/stream/34/.mp3"
	)

	# Configuration files
	CONFIG_DIR="$HOME/.config/tradio"
	CONFIG_FILE="$CONFIG_DIR/config"
	HISTORY_FILE="$CONFIG_DIR/history"
	FAVORITES_FILE="$CONFIG_DIR/favorites"
	PID_FILE="/tmp/tradio_player.pid"
	NOW_PLAYING_FILE="/tmp/tradio_current.txt"

	# Default volume
	VOLUME=100

	# Default player (can be 'cvlc' or 'mpv')
	PLAYER="cvlc"

	# Dependency check with generic instructions
	check_dependencies() {
		local deps=("$PLAYER" "mpv")
		local missing=()

		for dep in "${deps[@]}"; do
			if ! command -v "$dep" >/dev/null 2>&1; then
				missing+=("$dep")
			fi
		done

		if [ ${#missing[@]} -ne 0 ]; then
			echo -e "${RED}Missing dependencies: ${missing[*]}${NC}"
			echo "Please install the following packages using your system's package manager:"
			for dep in "${missing[@]}"; do
				echo "- $dep"
			done
			exit 1
		fi
	}

	# Configuration management
	init_config() {
		mkdir -p "$CONFIG_DIR"
		[ ! -f "$CONFIG_FILE" ] && echo "volume=$VOLUME" >"$CONFIG_FILE"
		[ ! -f "$HISTORY_FILE" ] && touch "$HISTORY_FILE"
		[ ! -f "$FAVORITES_FILE" ] && touch "$FAVORITES_FILE"

		# Read configuration
		source "$CONFIG_FILE"
	}

	# Create the ordered station list
	create_station_list() {
		# First, include Virgin Radio
		SORTED_STATIONS=("Virgin Radio")

		# Then add all other stations alphabetically
		local temp_stations=()
		for station in "${!RADIOS[@]}"; do
			if [ "$station" != "Virgin Radio" ]; then
				temp_stations+=("$station")
			fi
		done

		# Sort the temporary array
		IFS=$'\n' sorted=($(sort <<<"${temp_stations[*]}"))
		unset IFS

		# Combine arrays
		SORTED_STATIONS+=("${sorted[@]}")
	}

	# History management
	add_to_history() {
		local name=$1
		echo "$(date '+%Y-%m-%d %H:%M:%S') - $name" >>"$HISTORY_FILE"
	}

	# Favorites management
	add_to_favorites() {
		local name=$1
		if ! grep -q "^$name$" "$FAVORITES_FILE"; then
			echo "$name" >>"$FAVORITES_FILE"
			echo -e "${GREEN}Added $name to favorites${NC}"
		fi
	}

	remove_from_favorites() {
		local name=$1
		sed -i "/^$name$/d" "$FAVORITES_FILE"
		echo -e "${YELLOW}Removed $name from favorites${NC}"
	}

	# Function to check if radio is playing
	is_radio_playing() {
		if [ -f "$PID_FILE" ]; then
			local pid
			pid=$(cat "$PID_FILE")
			if ps -p "$pid" >/dev/null 2>&1; then
				return 0 # Radio is playing
			fi
		fi
		return 1 # Radio is not playing
	}

	# Function to stop playing radio
	stop_radio() {
		if [ -f "$PID_FILE" ]; then
			local pid
			pid=$(cat "$PID_FILE")
			if ps -p "$pid" >/dev/null 2>&1; then
				echo -e "${YELLOW}Stopping radio...${NC}"
				kill "$pid" >/dev/null 2>&1
				rm -f "$PID_FILE"
				rm -f "$NOW_PLAYING_FILE"
			fi
		fi
	}

	# Volume control for various environments
	change_volume() {
		local new_vol=$1
		VOLUME=$new_vol
		sed -i "s/volume=.*/volume=$VOLUME/" "$CONFIG_FILE"

		# Try different volume control methods
		if command -v pactl >/dev/null 2>&1; then
			pactl set-sink-volume @DEFAULT_SINK@ "${VOLUME}%"
		elif command -v amixer >/dev/null 2>&1; then
			amixer -q sset Master "${VOLUME}%" 2>/dev/null
		fi
	}

	# Enhanced radio playback function with PID tracking
	play_radio() {
		local url=$1
		local name=$2
		local toggle=$3
		local play_status=0

		# Validate input parameters
		if [[ -z "$url" || -z "$name" ]]; then
			echo -e "${RED}Error: Missing required parameters${NC}"
			return 1
		fi

		# Handle toggle logic
		if [[ "$toggle" = "true" && -f "$NOW_PLAYING_FILE" ]]; then
			local current_station
			current_station=$(cat "$NOW_PLAYING_FILE" 2>/dev/null)

			if [[ -n "$current_station" && "$current_station" = "$name" ]]; then
				stop_radio
				return 0
			elif is_radio_playing; then
				stop_radio
			fi
		fi

		# Notification and history
		echo -e "${GREEN}Starting: $name${NC}"
		if command -v notify-send >/dev/null 2>&1; then
			notify-send -i "audio-x-generic" "🎵 Radio Player" "Now playing: $name" -t 2000
		fi
		add_to_history "$name"

		# Start player based on selected player
		if [[ "$PLAYER" == "cvlc" ]]; then
			cvlc --no-video \
				--play-and-exit \
				--quiet \
				--intf dummy \
				--volume="$VOLUME" \
				"$url" 2>/dev/null &
			play_status=$?
		elif [[ "$PLAYER" == "mpv" ]]; then
			mpv --no-video \
				--quiet \
				--volume="$VOLUME" \
				"$url" 2>/dev/null &
			play_status=$?
		else
			echo -e "${RED}Unsupported player: $PLAYER${NC}"
			return 1
		fi

		# Handle player start status
		if [[ $play_status -eq 0 ]]; then
			# Save PID and current station
			echo $! >"$PID_FILE"
			echo "$name" >"$NOW_PLAYING_FILE"
			chmod 600 "$PID_FILE" "$NOW_PLAYING_FILE"

			# Verify player is actually running
			sleep 1
			if ! is_radio_playing; then
				rm -f "$PID_FILE" "$NOW_PLAYING_FILE"
				echo -e "${RED}Failed to start playback${NC}"
				return 1
			fi
			return 0
		else
			echo -e "${RED}Error: Failed to start player${NC}"
			return 1
		fi
	}

	# Station selection by number
	play_station_by_number() {
		local station_num=$1
		local toggle=$2

		if [[ "$station_num" -gt 0 && "$station_num" -le ${#SORTED_STATIONS[@]} ]]; then
			local idx=$((station_num - 1))
			local station_name="${SORTED_STATIONS[$idx]}"
			play_radio "${RADIOS[$station_name]}" "$station_name" "$toggle"
		else
			echo -e "${RED}Invalid station number: $station_num${NC}"
			return 1
		fi
	}

	# Search functionality
	search_stations() {
		echo -e "${BLUE}Search stations:${NC}"
		read -r search_term

		if [[ -z "$search_term" ]]; then
			return
		fi

		echo -e "${GREEN}Results for '$search_term':${NC}"
		local i=1
		local matches=()

		for station in "${SORTED_STATIONS[@]}"; do
			if [[ "${station,,}" == *"${search_term,,}"* ]]; then
				echo "$i) $station"
				matches+=("$station")
				((i++))
			fi
		done

		if [[ ${#matches[@]} -eq 0 ]]; then
			echo -e "${YELLOW}No matches found${NC}"
			sleep 1
			return
		fi

		echo -e "${BLUE}Enter number to play (or press Enter to cancel):${NC}"
		read -r choice

		if [[ "$choice" =~ ^[0-9]+$ && "$choice" -gt 0 && "$choice" -le ${#matches[@]} ]]; then
			local selected="${matches[$((choice - 1))]}"
			play_radio "${RADIOS[$selected]}" "$selected" "true"
			echo -e "${GREEN}Press any key to return to the menu...${NC}"
			read -n 1 -s
		fi
	}

	# Display favorites
	show_favorites() {
		clear
		echo -e "${BOLD}${BLUE}Favorites${NC}"
		echo "---------------------------------"

		if [[ ! -s "$FAVORITES_FILE" ]]; then
			echo -e "${YELLOW}No favorites yet.${NC}"
			echo -e "\nPress any key to return..."
			read -n 1 -s
			return
		fi

		local favs=()
		while IFS= read -r line; do
			[[ -n "$line" ]] && favs+=("$line")
		done <"$FAVORITES_FILE"

		local i=1
		for fav in "${favs[@]}"; do
			echo "$i) $fav"
			((i++))
		done

		echo -e "\n${BLUE}Enter number to play, d<number> to delete, or q to go back:${NC}"
		read -r choice

		case "$choice" in
		q | Q | "")
			return
			;;
		d*)
			local num="${choice#d}"
			if [[ "$num" =~ ^[0-9]+$ && "$num" -gt 0 && "$num" -le ${#favs[@]} ]]; then
				remove_from_favorites "${favs[$((num - 1))]}"
				sleep 1
			fi
			;;
		*)
			if [[ "$choice" =~ ^[0-9]+$ && "$choice" -gt 0 && "$choice" -le ${#favs[@]} ]]; then
				local selected="${favs[$((choice - 1))]}"
				play_radio "${RADIOS[$selected]}" "$selected" "true"
				echo -e "${GREEN}Press any key to return...${NC}"
				read -n 1 -s
			fi
			;;
		esac
	}

	# History display
	show_history() {
		clear
		echo -e "${BOLD}${BLUE}History${NC}"
		echo "---------------------------------"

		if [[ ! -s "$HISTORY_FILE" ]]; then
			echo -e "${YELLOW}No history yet.${NC}"
			echo -e "\nPress any key to return..."
			read -n 1 -s
			return
		fi

		tail -n 20 "$HISTORY_FILE"
		echo -e "\nPress any key to return..."
		read -n 1 -s
	}

	# Toggle player
	toggle_player() {
		if [[ "$PLAYER" == "cvlc" ]]; then
			PLAYER="mpv"
			echo -e "${GREEN}Switched to MPV player${NC}"
		else
			PLAYER="cvlc"
			echo -e "${GREEN}Switched to VLC player${NC}"
		fi
		sleep 1
	}

	# Volume menu
	volume_menu() {
		clear
		echo -e "${BOLD}${BLUE}Volume Control${NC}"
		echo "---------------------------------"
		echo "Current volume: $VOLUME%"
		echo
		echo "Enter new volume (0-200) or press Enter to cancel:"
		read -r new_vol

		if [[ -z "$new_vol" ]]; then
			return
		fi

		if [[ "$new_vol" =~ ^[0-9]+$ && "$new_vol" -ge 0 && "$new_vol" -le 200 ]]; then
			change_volume "$new_vol"
			echo -e "${GREEN}Volume set to $VOLUME%${NC}"
			sleep 1
		else
			echo -e "${RED}Invalid volume${NC}"
			sleep 1
		fi
	}

	# Display menu
	show_menu() {
		clear
		echo -e "${BOLD}${BLUE}tradio - Terminal Radio Player${NC}"
		echo "---------------------------------"

		# Display current playing
		if [[ -f "$NOW_PLAYING_FILE" ]]; then
			local current
			current=$(cat "$NOW_PLAYING_FILE")
			echo -e "${GREEN}Now playing: ${BOLD}$current${NC}"
		else
			echo -e "${YELLOW}Not playing${NC}"
		fi

		echo -e "\n${BLUE}Stations:${NC}"

		# Determine columns based on terminal width
		local term_width
		term_width=$(tput cols)
		local columns=2
		[[ $term_width -gt 120 ]] && columns=3
		[[ $term_width -gt 180 ]] && columns=4

		# Calculate padding for station names
		local padding=$((term_width / columns - 10))
		[[ $padding -lt 20 ]] && padding=20

		# Display stations in columns
		local i=1 col=1

		# Display stations based on sorted array
		for name in "${SORTED_STATIONS[@]}"; do
			local number_pad=""
			[ $i -lt 10 ] && number_pad=" "

			# Add star for favorites
			local star=""
			grep -q "^$name$" "$FAVORITES_FILE" && star="★ "

			printf "(%s%d) %-${padding}s %s" "$number_pad" "$i" "$name" "$star"

			if [ $col -eq $columns ]; then
				echo ""
				col=1
			else
				col=$((col + 1))
				printf "    "
			fi
			((i++))
		done

		# Complete the last line if necessary
		[ $col -ne 1 ] && echo ""

		echo -e "\n${BLUE}Commands:${NC}"
		echo -e "r) Random Play    s) Search"
		echo -e "f) Favorites      h) History"
		echo -e "v) Volume         p) Toggle Player (cvlc/mpv)"
		echo -e "q) Quit"
		echo -e "\nYour choice: "
	}

	# Main program with argument handling
	main() {
		check_dependencies
		init_config
		create_station_list

		# Handle command line arguments
		if [ $# -gt 0 ]; then
			case $1 in
			-h | --help)
				echo "Usage: osc-media radio [OPTION] [NUMBER]"
				echo "Options:"
				echo "  -h, --help     Show this help"
				echo "  -t, --toggle   Toggle play/stop for given station"
				echo "  -s, --stop     Stop currently playing station"
				echo "  -l, --list     List all available stations"
				echo "  -p, --player   Switch player (cvlc/mpv)"
				echo "  NUMBER         Play station number (1-${#SORTED_STATIONS[@]})"
				exit 0
				;;
			-t | --toggle)
				if [ $# -eq 2 ]; then
					play_station_by_number "$2" "true"
				else
					echo -e "${RED}Error: Station number required for toggle${NC}"
					exit 1
				fi
				;;
			-s | --stop)
				stop_radio
				exit 0
				;;
			-l | --list)
				echo -e "${BLUE}Available Radio Stations:${NC}"
				local i=1
				for station in "${SORTED_STATIONS[@]}"; do
					echo "$i) $station"
					((i++))
				done
				exit 0
				;;
			-p | --player)
				toggle_player
				exit 0
				;;
			*)
				if [[ $1 =~ ^[0-9]+$ ]]; then
					play_station_by_number "$1" "false"
				else
					echo -e "${RED}Invalid argument: $1${NC}"
					exit 1
				fi
				;;
			esac
		fi

		# Interactive menu mode
		while true; do
			show_menu
			read -r choice

			case $choice in
			[0-9]*)
				if [ "$choice" -gt 0 ] && [ "$choice" -le ${#SORTED_STATIONS[@]} ]; then
					choice=$((choice - 1))
					station_name="${SORTED_STATIONS[$choice]}"
					play_radio "${RADIOS[$station_name]}" "$station_name" "true"
					# Wait for user input before returning to the menu
					echo -e "${GREEN}Press any key to return to the menu...${NC}"
					read -n 1 -s
				else
					echo -e "${RED}Invalid station number!${NC}"
					sleep 1
				fi
				;;
			r | R)
				random_idx=$((RANDOM % ${#SORTED_STATIONS[@]}))
				random_station="${SORTED_STATIONS[$random_idx]}"
				echo -e "${GREEN}Randomly selected: $random_station${NC}"
				play_radio "${RADIOS[$random_station]}" "$random_station" "true"
				echo -e "${GREEN}Press any key to return to the menu...${NC}"
				read -n 1 -s
				;;
			s | S)
				search_stations
				;;
			f | F)
				show_favorites
				;;
			h | H)
				show_history
				;;
			v | V)
				volume_menu
				;;
			p | P)
				toggle_player
				;;
			q | Q)
				clear
				echo -e "${GREEN}Goodbye!${NC}"
				exit 0
				;;
			*)
				echo -e "${RED}Invalid choice!${NC}"
				sleep 1
				;;
			esac
		done
	}

	main "$@"
)

main() {
	local cmd="${1:-}"
	shift || true

	case "$cmd" in
	"" | -h | --help | help)
		show_help
		return 0
		;;
	spotify)
		osc_media_spotify "$@"
		;;
	mpc)
		osc_media_mpc "$@"
		;;
	vlc)
		osc_media_vlc "$@"
		;;
	mpv)
		osc_media_mpv "$@"
		;;
	radio)
		osc_media_radio "$@"
		;;
	lofi)
		osc_media_lofi "$@"
		;;
	*)
		die "unknown command: $cmd"
		;;
	esac
}

main "$@"
