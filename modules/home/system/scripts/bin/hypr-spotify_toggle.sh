#!/usr/bin/env bash
#######################################
#
# Version: 2.0.0
# Date: 2025-03-11
# Original Author: Kenan Pelit
# Improvements by: Claude
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
NC='\033[0m' # No Color

# Yapılandırma değişkenleri
PLAYER="spotify"
TIMEOUT=10                                                    # Spotify'ın başlaması için maksimum bekleme süresi (saniye)
ICON_PATH="/usr/share/icons/hicolor/256x256/apps/spotify.png" # Spotify icon path (varsa)
COMMAND="$1"                                                  # Komut satırı parametresi

# Hyprland için pencere kontrolü
HYPR_ACTIVE=$(command -v hyprctl &>/dev/null && echo "true" || echo "false")

# Yardım fonksiyonu
function show_help {
	echo -e "${BLUE}HyprFlow Spotify Kontrolcü${NC} - Hyprland & Wayland Edition"
	echo "Kullanım: $(basename $0) [KOMUT]"
	echo ""
	echo "Komutlar:"
	echo "  play-pause    Oynatma/duraklatma düğmesi (parametre verilmezse varsayılan)"
	echo "  next          Sonraki şarkıya geç"
	echo "  prev          Önceki şarkıya geç"
	echo "  stop          Spotify'ı durdur"
	echo "  volume-up     Ses seviyesini artır"
	echo "  volume-down   Ses seviyesini azalt"
	echo "  status        Durum bilgisini göster"
	echo "  focus         Spotify penceresini odakla"
	echo "  info          Aktif Spotify penceresi hakkında bilgi göster"
	echo "  help          Bu yardım mesajını göster"
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

# Şarkı bilgilerini alma fonksiyonu
function get_track_info {
	local artist=$(playerctl -p "$PLAYER" metadata artist 2>/dev/null)
	local title=$(playerctl -p "$PLAYER" metadata title 2>/dev/null)
	local album=$(playerctl -p "$PLAYER" metadata album 2>/dev/null)

	if [ -n "$artist" ] && [ -n "$title" ]; then
		echo "$title - $artist ($album)"
		return 0
	else
		return 1
	fi
}

# Spotify'ın çalışıp çalışmadığını kontrol et
function check_spotify_running {
	if ! pgrep "$PLAYER" >/dev/null; then
		send_notification "Spotify" "❗ Spotify çalışmıyor, başlatılıyor..." "normal" 3000
		start-spotify-default &

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

# Play/Pause işlevi
function toggle_playback {
	check_spotify_running || return 1
	check_spotify_ready || return 1

	STATUS=$(playerctl -p "$PLAYER" status 2>/dev/null)

	case $STATUS in
	"Playing")
		playerctl -p "$PLAYER" pause
		send_notification "Spotify" "⏸ Durduruldu"
		;;
	"Paused")
		playerctl -p "$PLAYER" play

		# Şarkı bilgisini göster
		if track_info=$(get_track_info); then
			send_notification "▶ Oynatılıyor" "$track_info" "normal" 3000
		else
			send_notification "Spotify" "▶ Oynatılıyor"
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
		send_notification "Spotify - Sonraki Parça" "$track_info" "normal" 3000
	else
		send_notification "Spotify" "⏭ Sonraki parçaya geçildi"
	fi
}

# Önceki şarkıya geç
function previous_track {
	check_spotify_running || return 1
	check_spotify_ready || return 1

	playerctl -p "$PLAYER" previous
	sleep 0.5 # Metadata'nın güncellenmesi için bekle

	if track_info=$(get_track_info); then
		send_notification "Spotify - Önceki Parça" "$track_info" "normal" 3000
	else
		send_notification "Spotify" "⏮ Önceki parçaya geçildi"
	fi
}

# Spotify'ı durdur
function stop_playback {
	check_spotify_running || return 1
	check_spotify_ready || return 1

	playerctl -p "$PLAYER" stop
	send_notification "Spotify" "⏹ Durduruldu"
}

# Ses seviyesini artır
function volume_up {
	check_spotify_running || return 1
	check_spotify_ready || return 1

	# Mevcut ses seviyesini al
	current_vol=$(playerctl -p "$PLAYER" volume 2>/dev/null)
	# 10% artır, en fazla 1.0 (100%)
	new_vol=$(echo "$current_vol + 0.1" | bc | awk '{if ($1 > 1.0) print 1.0; else print $1}')

	playerctl -p "$PLAYER" volume "$new_vol"
	vol_percent=$(echo "$new_vol * 100" | bc | cut -d. -f1)
	send_notification "Spotify" "🔊 Ses: $vol_percent%"
}

# Ses seviyesini azalt
function volume_down {
	check_spotify_running || return 1
	check_spotify_ready || return 1

	# Mevcut ses seviyesini al
	current_vol=$(playerctl -p "$PLAYER" volume 2>/dev/null)
	# 10% azalt, en az 0.0 (0%)
	new_vol=$(echo "$current_vol - 0.1" | bc | awk '{if ($1 < 0.0) print 0.0; else print $1}')

	playerctl -p "$PLAYER" volume "$new_vol"
	vol_percent=$(echo "$new_vol * 100" | bc | cut -d. -f1)
	send_notification "Spotify" "🔉 Ses: $vol_percent%"
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
		vol_percent=$(echo "$vol * 100" | bc | cut -d. -f1)

		# Durum simgesini belirle
		status_icon="⏸"
		if [ "$STATUS" = "Playing" ]; then
			status_icon="▶"
		fi

		send_notification "Spotify - $status_icon $STATUS" "$track_info\nSes: $vol_percent%" "normal" 5000
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
			send_notification "Spotify" "🎵 Spotify penceresi odaklandı"
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

			send_notification "Spotify Pencere Bilgisi" "ID: $WINDOW_ID\nÇalışma Alanı: $WORKSPACE\nBaşlık: $TITLE" "normal" 5000
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
"stop")
	stop_playback
	;;
"volume-up")
	volume_up
	;;
"volume-down")
	volume_down
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
"help" | "-h" | "--help")
	show_help
	;;
"play-pause" | "")
	toggle_playback
	;;
*)
	echo -e "${RED}Hata: Geçersiz komut '${COMMAND}'${NC}"
	show_help
	;;
esac

exit 0
