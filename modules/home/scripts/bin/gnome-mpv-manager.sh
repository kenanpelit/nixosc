#!/usr/bin/env bash

########################################
#
# Version: 1.1.0-gnome
# Date: 2025-01-05
# Author: Kenan Pelit (GNOME adaptation)
# Repository: github.com/kenanpelit/dotfiles
# Description: GNOME-Flow - MPV Yönetim Aracı (GNOME Edition)
#
# License: MIT
#
#######################################
# GNOME-Flow - MPV Yönetim Aracı
# GNOME masaüstü ortamında MPV pencere ve medya yönetimi için kapsamlı bir araç.
#
# Özellikler:
# - Akıllı pencere konumlandırma ve döndürme (GNOME/Wayland)
# - Pencere sabitleme ve odaklama
# - Medya kontrolü (oynat/duraklat)
# - YouTube video yönetimi (oynatma ve indirme)
# - GNOME/Wayland uyumlu pencere yönetimi
#
# Gereksinimler:
# - mpv: Medya oynatıcı
# - wmctrl: X11/XWayland pencere yönetimi
# - gdbus: GNOME Shell API erişimi (Wayland)
# - jq: JSON işleme
# - socat: Socket iletişimi
# - wl-clipboard: Pano yönetimi (Wayland)
# - xclip: Pano yönetimi (X11 fallback)
# - yt-dlp: YouTube video indirme
# - libnotify: Masaüstü bildirimleri

# Renk ve sembol tanımları
SUCCESS='\033[0;32m'
ERROR='\033[0;31m'
INFO='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'
CHECK_MARK="✓"
CROSS_MARK="✗"
ARROW_MARK="→"

# Yapılandırma değişkenleri
SOCKET_PATH="/tmp/mpvsocket"
DOWNLOADS_DIR="$HOME/Downloads"
NOTIFICATION_TIMEOUT=1000

# Session type detection
SESSION_TYPE="${XDG_SESSION_TYPE:-x11}"

# Kullanım kılavuzu
show_usage() {
	cat <<EOF
GNOME-Flow - MPV Yönetim Aracı v1.1.0-gnome

Kullanım: $(basename "$0") <komut>

Komutlar:
    start       MPV'yi başlat veya aktif hale getir
    move        MPV penceresini akıllıca konumlandır (GNOME)
    stick       Pencereyi always-on-top yap/kaldır
    playback    Medya oynatımını duraklat/devam ettir
    play-yt     Panodaki YouTube URL'sini oynat
    save-yt     Panodaki YouTube videosunu indir
    resize      MPV penceresini yeniden boyutlandır
    center      MPV penceresini ortala

Örnekler:
    $(basename "$0") start     # MPV'yi başlat
    $(basename "$0") move      # Pencereyi bir sonraki köşeye taşır
    $(basename "$0") play-yt   # Kopyalanan YouTube linkini oynatır
    $(basename "$0") resize    # Pencereyi %40 boyutunda ortalar

GNOME/Wayland Uyumluluk:
    Bu araç hem X11 hem de Wayland session'larında çalışır.
EOF
	exit 1
}

# Başarı mesajı gösterme
show_success() {
	echo -e "${SUCCESS}$CHECK_MARK $1${NC}"
	notify-send -t $NOTIFICATION_TIMEOUT "GNOME-Flow" "$1"
}

# Hata mesajı gösterme
show_error() {
	echo -e "${ERROR}$CROSS_MARK Hata: $1${NC}" >&2
	notify-send -u critical -t $NOTIFICATION_TIMEOUT "GNOME-Flow Hata" "$1"
}

# Bilgi mesajı gösterme
show_info() {
	echo -e "${INFO}$ARROW_MARK $1${NC}"
	notify-send -t $NOTIFICATION_TIMEOUT "GNOME-Flow" "$1"
}

# Proses kontrolü
check_process() {
	local process_name="$1"
	pgrep -x "$process_name" >/dev/null
}

# MPV durumunu kontrol et
check_mpv() {
	if ! check_process "mpv"; then
		show_error "MPV çalışmıyor"
		return 1
	fi
	return 0
}

# Clipboard content alma (xclip öncelikli)
get_clipboard() {
	if command -v xclip >/dev/null 2>&1; then
		xclip -selection clipboard -o 2>/dev/null || echo ""
	elif command -v wl-paste >/dev/null 2>&1 && [[ "$SESSION_TYPE" == "wayland" ]]; then
		wl-paste 2>/dev/null || echo ""
	else
		show_error "Clipboard erişimi için xclip veya wl-paste gerekli"
		return 1
	fi
}

# MPV pencere ID'sini bul
get_mpv_window_id() {
	if command -v wmctrl >/dev/null 2>&1; then
		wmctrl -l | grep -i mpv | head -1 | awk '{print $1}'
	else
		show_error "wmctrl bulunamadı, pencere yönetimi için gerekli"
		return 1
	fi
}

# GNOME Shell ile pencere yönetimi (Wayland)
gnome_shell_eval() {
	local script="$1"
	if command -v gdbus >/dev/null 2>&1; then
		gdbus call --session --dest org.gnome.Shell \
			--object-path /org/gnome/Shell \
			--method org.gnome.Shell.Eval "$script" 2>/dev/null
	fi
}

# MPV'yi başlat veya aktif hale getir
start_mpv() {
	local window_id
	window_id=$(get_mpv_window_id)

	if [[ -n "$window_id" ]]; then
		echo -e "${CYAN}MPV zaten çalışıyor.${NC} Pencere aktif hale getiriliyor."
		notify-send -i mpv -t 1000 "MPV Zaten Çalışıyor" "MPV aktif durumda, pencere öne getiriliyor."

		# Pencereyi aktif hale getir
		if command -v wmctrl >/dev/null 2>&1; then
			wmctrl -i -a "$window_id"
		fi
	else
		mpv --geometry=40%+50%+50% \
			--player-operation-mode=pseudo-gui \
			--input-ipc-server="$SOCKET_PATH" \
			--idle \
			--ontop \
			-- >/dev/null 2>&1 &
		disown
		notify-send -i mpv -t 1000 "MPV Başlatılıyor" "MPV oynatıcı başlatıldı ve hazır."
	fi
}

# Pencere konumunu değiştir (GNOME versiyonu)
move_window() {
	local window_id
	window_id=$(get_mpv_window_id)

	if [[ -z "$window_id" ]]; then
		show_error "MPV penceresi bulunamadı"
		return 1
	fi

	# Pencereyi aktif hale getir
	wmctrl -i -a "$window_id" 2>/dev/null
	sleep 0.2

	# Mevcut pencere pozisyonunu al
	local window_info
	window_info=$(wmctrl -lG | grep "$window_id")
	local x_pos=$(echo "$window_info" | awk '{print $3}')
	local y_pos=$(echo "$window_info" | awk '{print $4}')

	# Ekran boyutunu al
	local screen_width screen_height
	if command -v xrandr >/dev/null 2>&1; then
		screen_width=$(xrandr | grep '*' | awk '{print $1}' | cut -d'x' -f1 | head -1)
		screen_height=$(xrandr | grep '*' | awk '{print $1}' | cut -d'x' -f2 | head -1)
	else
		screen_width=1920
		screen_height=1080
	fi

	# Pencere boyutları (%40 ekran boyutu)
	local window_width=$((screen_width * 40 / 100))
	local window_height=$((screen_height * 40 / 100))
	local margin=50

	# Döngüsel konum belirleme (4 köşe)
	if [[ $x_pos -lt $((screen_width / 2)) && $y_pos -lt $((screen_height / 2)) ]]; then
		# Sol üst → Sağ üst
		local new_x=$((screen_width - window_width - margin))
		local new_y=$margin
	elif [[ $x_pos -gt $((screen_width / 2)) && $y_pos -lt $((screen_height / 2)) ]]; then
		# Sağ üst → Sağ alt
		local new_x=$((screen_width - window_width - margin))
		local new_y=$((screen_height - window_height - margin))
	elif [[ $x_pos -gt $((screen_width / 2)) && $y_pos -gt $((screen_height / 2)) ]]; then
		# Sağ alt → Sol alt
		local new_x=$margin
		local new_y=$((screen_height - window_height - margin))
	else
		# Sol alt → Sol üst (başa dön)
		local new_x=$margin
		local new_y=$margin
	fi

	# Pencereyi taşı ve boyutlandır
	wmctrl -i -r "$window_id" -e "0,$new_x,$new_y,$window_width,$window_height"

	show_success "Pencere konumu güncellendi ($new_x,$new_y)"
}

# Pencereyi always-on-top yap/kaldır
toggle_stick() {
	check_mpv || return 1

	local window_id
	window_id=$(get_mpv_window_id)

	if [[ -n "$window_id" ]]; then
		wmctrl -i -r "$window_id" -b toggle,above
		show_success "Pencere always-on-top durumu değiştirildi"
	else
		show_error "MPV penceresi bulunamadı"
	fi
}

# MPV penceresini yeniden boyutlandır ve ortala
resize_window() {
	local window_id
	window_id=$(get_mpv_window_id)

	if [[ -z "$window_id" ]]; then
		show_error "MPV penceresi bulunamadı"
		return 1
	fi

	# Ekran boyutunu al
	local screen_width screen_height
	if command -v xrandr >/dev/null 2>&1; then
		screen_width=$(xrandr | grep '*' | awk '{print $1}' | cut -d'x' -f1 | head -1)
		screen_height=$(xrandr | grep '*' | awk '{print $1}' | cut -d'x' -f2 | head -1)
	else
		screen_width=1920
		screen_height=1080
	fi

	# %40 boyutunda ortala
	local window_width=$((screen_width * 40 / 100))
	local window_height=$((screen_height * 40 / 100))
	local center_x=$(((screen_width - window_width) / 2))
	local center_y=$(((screen_height - window_height) / 2))

	wmctrl -i -r "$window_id" -e "0,$center_x,$center_y,$window_width,$window_height"
	wmctrl -i -a "$window_id"

	show_success "Pencere %40 boyutunda ortalandı"
}

# Pencereyi ortala (mevcut boyutla)
center_window() {
	local window_id
	window_id=$(get_mpv_window_id)

	if [[ -z "$window_id" ]]; then
		show_error "MPV penceresi bulunamadı"
		return 1
	fi

	# Mevcut pencere bilgilerini al
	local window_info
	window_info=$(wmctrl -lG | grep "$window_id")
	local window_width=$(echo "$window_info" | awk '{print $5}')
	local window_height=$(echo "$window_info" | awk '{print $6}')

	# Ekran boyutunu al
	local screen_width screen_height
	if command -v xrandr >/dev/null 2>&1; then
		screen_width=$(xrandr | grep '*' | awk '{print $1}' | cut -d'x' -f1 | head -1)
		screen_height=$(xrandr | grep '*' | awk '{print $1}' | cut -d'x' -f2 | head -1)
	else
		screen_width=1920
		screen_height=1080
	fi

	# Ortala
	local center_x=$(((screen_width - window_width) / 2))
	local center_y=$(((screen_height - window_height) / 2))

	wmctrl -i -r "$window_id" -e "0,$center_x,$center_y,$window_width,$window_height"
	wmctrl -i -a "$window_id"

	show_success "Pencere ortalandı"
}

# Oynatma durumunu değiştir
toggle_playback() {
	check_mpv || return 1

	if [[ ! -S "$SOCKET_PATH" ]]; then
		show_error "MPV socket bulunamadı"
		return 1
	fi

	# MPV'nin mevcut durumunu kontrol et
	local status
	status=$(echo '{ "command": ["get_property", "pause"] }' | socat - "$SOCKET_PATH" 2>/dev/null | grep -o '"data":true')

	if [[ "$status" == '"data":true' ]]; then
		echo '{ "command": ["cycle", "pause"] }' | socat - "$SOCKET_PATH" >/dev/null 2>&1
		show_success "Oynatma devam ediyor"
	else
		echo '{ "command": ["cycle", "pause"] }' | socat - "$SOCKET_PATH" >/dev/null 2>&1
		show_success "Oynatma duraklatıldı"
	fi
}

# YouTube video oynatma fonksiyonu
play_youtube() {
	local video_url
	video_url=$(get_clipboard)

	# YouTube URL'si olup olmadığını kontrol et
	if ! [[ "$video_url" =~ ^https?://(www\.)?(youtube\.com|youtu\.?be)/ ]]; then
		show_error "Kopyalanan URL geçerli bir YouTube URL'si değil."
		return 1
	fi

	# Video adını al
	local video_name
	video_name=$(yt-dlp --get-title "$video_url" 2>/dev/null || echo "YouTube Video")

	notify-send -t 5000 "Playing Video" "$video_name"

	# MPV'yi YouTube video ile başlat
	mpv --geometry=40%+50%+50% \
		--player-operation-mode=pseudo-gui \
		--input-ipc-server="$SOCKET_PATH" \
		--idle \
		--ontop \
		--no-audio-display \
		--speed=1 \
		--af=rubberband=pitch-scale=0.981818181818181 \
		"$video_url" >/dev/null 2>&1 &

	sleep 2
	show_info "Video GNOME'da oynatılıyor: $video_name"
}

# YouTube video indirme fonksiyonu
download_youtube() {
	local video_url
	video_url=$(get_clipboard)

	# YouTube URL'si olup olmadığını kontrol et
	if ! [[ "$video_url" =~ ^https?://(www\.)?(youtube\.com|youtu\.?be)/ ]]; then
		show_error "Kopyalanan URL geçerli bir YouTube URL'si değil."
		return 1
	fi

	# Video adını al
	local video_title
	video_title=$(yt-dlp --get-title "$video_url" 2>/dev/null || echo "Video")

	cd "$DOWNLOADS_DIR" || {
		show_error "İndirme klasörüne erişilemiyor: $DOWNLOADS_DIR"
		return 1
	}

	show_info "İndiriliyor: $video_title"

	if yt-dlp -f "bestvideo+bestaudio/best" \
		--merge-output-format mp4 \
		--embed-thumbnail \
		--add-metadata \
		"$video_url"; then
		show_success "$video_title başarıyla indirildi!"
		notify-send -t 3000 "İndirme Tamamlandı" "$video_title\n$DOWNLOADS_DIR klasöründe"
	else
		show_error "Video indirilemedi: $video_title"
	fi
}

# Ana program fonksiyonu
main() {
	case "$1" in
	"start")
		start_mpv
		;;
	"move")
		move_window
		;;
	"stick")
		toggle_stick
		;;
	"playback")
		toggle_playback
		;;
	"play-yt")
		play_youtube
		;;
	"save-yt")
		download_youtube
		;;
	"resize")
		resize_window
		;;
	"center")
		center_window
		;;
	*)
		show_usage
		;;
	esac
}

# Dependency check
check_dependencies() {
	local missing_deps=()

	if ! command -v mpv >/dev/null 2>&1; then
		missing_deps+=("mpv")
	fi

	if ! command -v wmctrl >/dev/null 2>&1; then
		missing_deps+=("wmctrl")
	fi

	if ! command -v socat >/dev/null 2>&1; then
		missing_deps+=("socat")
	fi

	if ! command -v yt-dlp >/dev/null 2>&1; then
		missing_deps+=("yt-dlp")
	fi

	# xclip öncelikli clipboard kontrolü
	if ! command -v xclip >/dev/null 2>&1 && ! command -v wl-paste >/dev/null 2>&1; then
		missing_deps+=("xclip")
	fi

	if [[ ${#missing_deps[@]} -gt 0 ]]; then
		show_error "Eksik bağımlılıklar: ${missing_deps[*]}"
		echo "NixOS'ta kurmak için: nix-env -iA nixpkgs.{${missing_deps[*]}}"
		exit 1
	fi
}

# Gerekli argüman kontrolü ve dependency check
if [[ $# -eq 0 ]]; then
	show_usage
fi

check_dependencies
main "$1"
