#!/usr/bin/env bash

# =============================================================================
#   Spotify Controller Script for Linux
#   This script uses dbus-send to control Spotify via MPRIS interface
# =============================================================================

# -----------------------------------------------------------------------------
# Configuration
# -----------------------------------------------------------------------------

# Ses artırma/azaltma için yüzde değeri
VOL_INCREMENT=10

# Renklendirme için ANSI escape kodları
bold=$(tput bold)
green=$(tput setaf 2)
reset=$(tput sgr0)

# -----------------------------------------------------------------------------
# Yardımcı Fonksiyonlar
# -----------------------------------------------------------------------------

# Renkli çıktı için yardımcı fonksiyon
cecho() {
	echo "${bold}${green}$1${reset}"
}

# Yardım mesajını göster
showHelp() {
	echo "Kullanım:"
	echo
	echo "  $(basename $0) <komut>"
	echo
	echo "Komutlar:"
	echo
	echo "  play                         # Spotify'ı oynat"
	echo "  pause                        # Duraklat/devam et"
	echo "  next                         # Sonraki şarkı"
	echo "  prev                         # Önceki şarkı"
	echo "  stop                         # Oynatmayı durdur"
	echo "  status                       # Mevcut durumu göster"
	echo "  vol up                       # Sesi ${VOL_INCREMENT}% artır"
	echo "  vol down                     # Sesi ${VOL_INCREMENT}% azalt"
	echo "  vol <0-100>                 # Sesi belirtilen seviyeye ayarla"
	echo "  vol [show]                   # Mevcut ses seviyesini göster"
	echo "  toggle shuffle               # Karıştırma modunu aç/kapat"
	echo "  toggle repeat                # Tekrar modunu değiştir"
	echo "  share                        # Çalan şarkının URL ve URI'sini göster"
	echo "  quit                         # Spotify'ı kapat"
}

# -----------------------------------------------------------------------------
# Metadata ve Durum Fonksiyonları
# -----------------------------------------------------------------------------

# Spotify'ın oynatma durumunu al
getSpotifyStatus() {
	dbus-send --print-reply --dest=org.mpris.MediaPlayer2.spotify \
		/org/mpris/MediaPlayer2 \
		org.freedesktop.DBus.Properties.Get \
		string:'org.mpris.MediaPlayer2.Player' \
		string:'PlaybackStatus' |
		grep -o '".*"' | cut -d'"' -f2
}

# Çalan şarkının sanatçısını göster
showArtist() {
	dbus-send --print-reply --dest=org.mpris.MediaPlayer2.spotify \
		/org/mpris/MediaPlayer2 \
		org.freedesktop.DBus.Properties.Get \
		string:'org.mpris.MediaPlayer2.Player' \
		string:'Metadata' |
		awk -F '"' '/xesam:artist/ {getline; getline; print $2}'
}

# Çalan şarkının albümünü göster
showAlbum() {
	dbus-send --print-reply --dest=org.mpris.MediaPlayer2.spotify \
		/org/mpris/MediaPlayer2 \
		org.freedesktop.DBus.Properties.Get \
		string:'org.mpris.MediaPlayer2.Player' \
		string:'Metadata' |
		awk -F '"' '/xesam:album/ {getline; print $2}'
}

# Çalan şarkının adını göster
showTrack() {
	dbus-send --print-reply --dest=org.mpris.MediaPlayer2.spotify \
		/org/mpris/MediaPlayer2 \
		org.freedesktop.DBus.Properties.Get \
		string:'org.mpris.MediaPlayer2.Player' \
		string:'Metadata' |
		awk -F '"' '/xesam:title/ {getline; print $2}'
}

# Detaylı durum bilgisi göster
showStatus() {
	state=$(getSpotifyStatus)
	cecho "Spotify durumu: $state"
	artist=$(showArtist)
	album=$(showAlbum)
	track=$(showTrack)
	echo -e "Sanatçı: $artist\nAlbüm: $album\nŞarkı: $track"
}

# -----------------------------------------------------------------------------
# Ana Program
# -----------------------------------------------------------------------------

# Argüman kontrolü
if [ $# = 0 ]; then
	showHelp
	exit 0
fi

# Spotify yüklü mü kontrol et
if ! command -v spotify &>/dev/null; then
	echo "Spotify uygulaması yüklü değil!"
	exit 1
fi

# Spotify çalışmıyorsa başlat
if ! pgrep -x "spotify" >/dev/null; then
	spotify &
	sleep 2
fi

# Komut işleme
while [ $# -gt 0 ]; do
	case "$1" in
	"play")
		dbus-send --print-reply --dest=org.mpris.MediaPlayer2.spotify \
			/org/mpris/MediaPlayer2 \
			org.mpris.MediaPlayer2.Player.Play >/dev/null
		cecho "Spotify oynatılıyor."
		;;

	"pause")
		dbus-send --print-reply --dest=org.mpris.MediaPlayer2.spotify \
			/org/mpris/MediaPlayer2 \
			org.mpris.MediaPlayer2.Player.PlayPause >/dev/null
		cecho "Oynatma durumu değiştirildi."
		;;

	"stop")
		dbus-send --print-reply --dest=org.mpris.MediaPlayer2.spotify \
			/org/mpris/MediaPlayer2 \
			org.mpris.MediaPlayer2.Player.Stop >/dev/null
		cecho "Spotify durduruldu."
		;;

	"next")
		dbus-send --print-reply --dest=org.mpris.MediaPlayer2.spotify \
			/org/mpris/MediaPlayer2 \
			org.mpris.MediaPlayer2.Player.Next >/dev/null
		cecho "Sonraki şarkıya geçildi."
		showStatus
		;;

	"prev")
		dbus-send --print-reply --dest=org.mpris.MediaPlayer2.spotify \
			/org/mpris/MediaPlayer2 \
			org.mpris.MediaPlayer2.Player.Previous >/dev/null
		cecho "Önceki şarkıya geçildi."
		showStatus
		;;

	"vol")
		shift
		if [[ $1 = "" || $1 = "show" ]]; then
			vol=$(pactl list sinks | grep -A 15 "$(pactl info | grep "Default Sink" | cut -d: -f2)" |
				grep "Volume:" | grep -o "[0-9]*%" | head -1 | cut -d'%' -f1)
			cecho "Mevcut ses seviyesi: $vol%"
		elif [ "$1" = "up" ]; then
			pactl set-sink-volume @DEFAULT_SINK@ +${VOL_INCREMENT}%
			cecho "Ses ${VOL_INCREMENT}% artırıldı."
		elif [ "$1" = "down" ]; then
			pactl set-sink-volume @DEFAULT_SINK@ -${VOL_INCREMENT}%
			cecho "Ses ${VOL_INCREMENT}% azaltıldı."
		elif [[ $1 =~ ^[0-9]+$ ]] && [[ $1 -ge 0 && $1 -le 100 ]]; then
			pactl set-sink-volume @DEFAULT_SINK@ ${1}%
			cecho "Ses seviyesi $1% olarak ayarlandı."
		else
			echo "Hatalı 'vol' komutu kullanımı!"
			echo "Kullanım:"
			echo "  vol up                  # Sesi ${VOL_INCREMENT}% artır"
			echo "  vol down                # Sesi ${VOL_INCREMENT}% azalt"
			echo "  vol <0-100>             # Sesi belirtilen seviyeye ayarla"
			echo "  vol [show]              # Mevcut ses seviyesini göster"
			exit 1
		fi
		;;

	"toggle")
		shift
		if [ "$1" = "shuffle" ]; then
			# Mevcut karıştırma durumunu al
			current_shuffle=$(dbus-send --print-reply \
				--dest=org.mpris.MediaPlayer2.spotify \
				/org/mpris/MediaPlayer2 \
				org.freedesktop.DBus.Properties.Get \
				string:'org.mpris.MediaPlayer2.Player' \
				string:'Shuffle' | awk '/boolean/ {print $2}')

			# Durumu tersine çevir
			new_shuffle=$([ "$current_shuffle" = "true" ] && echo "false" || echo "true")

			# Yeni durumu ayarla
			dbus-send --print-reply --dest=org.mpris.MediaPlayer2.spotify \
				/org/mpris/MediaPlayer2 \
				org.freedesktop.DBus.Properties.Set \
				string:'org.mpris.MediaPlayer2.Player' \
				string:'Shuffle' \
				variant:boolean:$new_shuffle >/dev/null

			cecho "Karıştırma modu: $new_shuffle"

		elif [ "$1" = "repeat" ]; then
			# Mevcut tekrar durumunu al
			current_loop=$(dbus-send --print-reply \
				--dest=org.mpris.MediaPlayer2.spotify \
				/org/mpris/MediaPlayer2 \
				org.freedesktop.DBus.Properties.Get \
				string:'org.mpris.MediaPlayer2.Player' \
				string:'LoopStatus' | awk -F '"' '{print $2}')

			# Durumu döngüsel olarak değiştir
			case "$current_loop" in
			"None")
				new_loop="Track"
				;;
			"Track")
				new_loop="Playlist"
				;;
			*)
				new_loop="None"
				;;
			esac

			# Yeni durumu ayarla
			dbus-send --print-reply --dest=org.mpris.MediaPlayer2.spotify \
				/org/mpris/MediaPlayer2 \
				org.freedesktop.DBus.Properties.Set \
				string:'org.mpris.MediaPlayer2.Player' \
				string:'LoopStatus' \
				variant:string:$new_loop >/dev/null

			cecho "Tekrar modu: $new_loop"
		fi
		;;

	"share")
		# Metadata'dan URL'i al
		url=$(dbus-send --print-reply --dest=org.mpris.MediaPlayer2.spotify \
			/org/mpris/MediaPlayer2 \
			org.freedesktop.DBus.Properties.Get \
			string:'org.mpris.MediaPlayer2.Player' \
			string:'Metadata' | awk -F '"' '/xesam:url/ {getline; print $2}')

		if [[ "$url" == "https://open.spotify.com/track/"* ]]; then
			track_id="${url##*/}"
			uri="spotify:track:$track_id"
			cecho "Spotify URL: $url"
			cecho "Spotify URI: $uri"
		else
			cecho "Şu anda çalan şarkı yok."
		fi
		;;

	"status")
		showStatus
		;;

	"quit")
		cecho "Spotify kapatılıyor."
		killall spotify
		exit 0
		;;

	"help")
		showHelp
		;;

	*)
		showHelp
		exit 1
		;;
	esac
	shift
done
