#!/usr/bin/env bash
########################################
#
# Version: 1.1.0
# Date: 2025-03-10
# Author: Kenan Pelit
# Repository: github.com/kenanpelit/dotfiles
# Description: HyprFlow - VLC Medya Kontrolü
#
# License: MIT
#
########################################

# Renkler ve semboller
SUCCESS='\033[0;32m'
ERROR='\033[0;31m'
INFO='\033[0;34m'
NC='\033[0m'
MUSIC_EMOJI="🎵"
PAUSE_EMOJI="⏸️"
PLAY_EMOJI="▶️"
ERROR_EMOJI="❌"

# Yapılandırma
NOTIFICATION_TIMEOUT=3000
NOTIFICATION_ICON="vlc"
PLAYER="vlc"
MAX_TITLE_LENGTH=40

# Debug modu (1=aktif, 0=pasif)
DEBUG=0

# Debug mesajlarını yazdır
debug() {
	if [ "$DEBUG" -eq 1 ]; then
		echo -e "${INFO}[DEBUG] $1${NC}" >&2
	fi
}

# Hata kontrolü - geliştirilmiş versiyon
check_vlc_running() {
	# Daha geniş bir arama yap
	if ! ps aux | grep -v grep | grep -i "vlc" >/dev/null; then
		debug "VLC işlemi bulunamadı"
		notify-send -i $NOTIFICATION_ICON -t $NOTIFICATION_TIMEOUT \
			"$ERROR_EMOJI VLC Hatası" "VLC çalışmıyor. Oynatıcıyı başlatın."
		exit 1
	else
		debug "VLC işlemi bulundu"
		# Playerctl'ın VLC'yi tanıyıp tanımadığını kontrol et
		if ! playerctl -l 2>/dev/null | grep -i "$PLAYER" >/dev/null; then
			debug "Playerctl VLC oynatıcısını bulamadı, genel kontrol kullanılıyor"
			PLAYER="" # Eğer playerctl özel olarak VLC'yi bulamazsa, tüm oynatıcılar için komut göndeririz
		fi
	fi
}

# Metni kısalt (çok uzunsa)
truncate_text() {
	local text=$1
	local max_length=$2
	if [ ${#text} -gt $max_length ]; then
		echo "${text:0:$max_length}..."
	else
		echo "$text"
	fi
}

# Medya bilgilerini al
get_media_info() {
	local player_param=""
	if [ -n "$PLAYER" ]; then
		player_param="--player=$PLAYER"
	fi

	debug "Playerctl parametresi: $player_param"

	local title=$(playerctl $player_param metadata title 2>/dev/null)
	local artist=$(playerctl $player_param metadata artist 2>/dev/null)
	local album=$(playerctl $player_param metadata album 2>/dev/null)

	debug "Ham başlık: $title"
	debug "Ham sanatçı: $artist"

	# Bazı medya dosyaları sadece başlık içerir, sanatçı veya albüm olmayabilir
	if [ -z "$title" ]; then
		# Başlık bilgisi yoksa dosya adını almaya çalış
		title=$(playerctl $player_param metadata xesam:url 2>/dev/null | awk -F/ '{print $NF}' | sed 's/%20/ /g')

		# Hala boşsa, hyprctl ile aktif pencere başlığını almayı dene
		if [ -z "$title" ]; then
			debug "Metadata bulunamadı, pencere başlığından almayı deneyeceğim"
			title=$(hyprctl activewindow -j 2>/dev/null | jq -r '.title' 2>/dev/null | grep -i "vlc" | sed 's/ - VLC media player//')
		fi

		# Son çare olarak varsayılan değer kullan
		if [ -z "$title" ]; then
			debug "Başlık bilgisi bulunamadı, varsayılan değer kullanılıyor"
			title="Bilinmeyen Parça"
		fi
	fi

	# Metinleri kısalt
	title=$(truncate_text "$title" $MAX_TITLE_LENGTH)
	artist=$(truncate_text "$artist" $MAX_TITLE_LENGTH)

	# Sonuçları döndür (global değişkenlere atama)
	TITLE="$title"
	ARTIST="$artist"
	ALBUM="$album"

	debug "İşlenmiş başlık: $TITLE"
	debug "İşlenmiş sanatçı: $ARTIST"
}

# Oynatma durumunu değiştir
toggle_playback() {
	local player_param=""
	if [ -n "$PLAYER" ]; then
		player_param="--player=$PLAYER"
	fi

	# Önce durumu kontrol et
	local prev_state=$(playerctl $player_param status 2>/dev/null)
	debug "Önceki durum: $prev_state"

	# Oynat/Duraklat komutunu gönder
	playerctl $player_param play-pause 2>/dev/null || {
		debug "Playerctl komutu başarısız, alternatif metot deneniyor"
		# Alternatif: VLC için dbus-send kullanma
		if dbus-send --print-reply --dest=org.mpris.MediaPlayer2.vlc /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.PlayPause >/dev/null 2>&1; then
			debug "dbus-send başarılı"
		else
			debug "dbus-send başarısız, XF86AudioPlay simülasyonu deneniyor"
			# Son çare: XF86AudioPlay tuşunu simüle et
			DISPLAY=:0 xdotool key XF86AudioPlay 2>/dev/null
		fi
	}

	# Kısa bir gecikme (durumun güncellenmesi için)
	sleep 0.2
}

# Ana işlev
main() {
	# VLC çalışıyor mu kontrol et
	check_vlc_running

	# Medya bilgilerini al
	get_media_info

	# Oynatma durumunu değiştir
	toggle_playback

	# Güncel durumu al
	local player_param=""
	if [ -n "$PLAYER" ]; then
		player_param="--player=$PLAYER"
	fi
	local current_state=$(playerctl $player_param status 2>/dev/null)
	debug "Güncel durum: $current_state"

	# Durum alınamazsa, önceki durumun tersini tahmin et
	if [ -z "$current_state" ]; then
		debug "Durum alınamadı, durum tahmini yapılıyor"
		if [ -n "$(ps aux | grep -v grep | grep -i 'vlc' | grep -v 'paused')" ]; then
			current_state="Playing"
			debug "Tahmin edilen durum: $current_state"
		else
			current_state="Paused"
			debug "Tahmin edilen durum: $current_state"
		fi
	fi

	# Bildirim mesajını hazırla
	local notification_title
	local notification_body

	if [ "$current_state" = "Playing" ]; then
		notification_title="$PLAY_EMOJI Oynatılıyor"
		if [ -n "$ARTIST" ]; then
			notification_body="$TITLE - $ARTIST"
		else
			notification_body="$TITLE"
		fi

		if [ -n "$ALBUM" ]; then
			notification_body="$notification_body\nAlbüm: $ALBUM"
		fi
	elif [ "$current_state" = "Paused" ]; then
		notification_title="$PAUSE_EMOJI Duraklatıldı"
		if [ -n "$ARTIST" ]; then
			notification_body="$TITLE - $ARTIST"
		else
			notification_body="$TITLE"
		fi
	else
		notification_title="$MUSIC_EMOJI VLC Medya"
		notification_body="$TITLE"
	fi

	# Bildirimi göster
	notify-send -i $NOTIFICATION_ICON -t $NOTIFICATION_TIMEOUT "$notification_title" "$notification_body"

	# Konsolda da göster (isteğe bağlı)
	echo -e "${INFO}$notification_title${NC}"
	echo -e "${SUCCESS}$notification_body${NC}"
}

# Programı çalıştır
main
