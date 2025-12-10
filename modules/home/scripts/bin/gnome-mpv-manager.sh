#!/usr/bin/env bash
# gnome-mpv-manager.sh - GNOME/Wayland MPV kontrol aracı
# MPV oynatıcıyı play/pause, ses, altyazı ve pencere davranışlarıyla
# yönetir; Wayland uyumlu komut setiyle çalışır.

########################################
#
# Version: 1.2.0-wayland
# Date: 2025-11-02
# Author: Kenan Pelit (Wayland adaptation)
# Repository: github.com/kenanpelit/dotfiles
# Description: GNOME-Flow - MPV Yönetim Aracı (Pure Wayland Edition)
#
# License: MIT
#
#######################################

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

# Kullanım kılavuzu
show_usage() {
	cat <<EOF
GNOME-Flow - MPV Yönetim Aracı v1.2.0-wayland

Kullanım: $(basename "$0") <komut>

Komutlar:
    start       MPV'yi başlat veya aktif hale getir
    move        MPV penceresini akıllıca konumlandır
    stick       Pencereyi always-on-top yap/kaldır
    playback    Medya oynatımını duraklat/devam ettir
    play-yt     Panodaki YouTube URL'sini oynat
    save-yt     Panodaki YouTube videosunu indir
    resize      MPV penceresini yeniden boyutlandır (40%)
    center      MPV penceresini ortala
    maximize    MPV penceresini maximize et
    unmaximize  MPV penceresini unmaximize et

Örnekler:
    $(basename "$0") start     # MPV'yi başlat
    $(basename "$0") move      # Pencereyi bir sonraki köşeye taşır
    $(basename "$0") play-yt   # Kopyalanan YouTube linkini oynatır

Pure Wayland/GNOME:
    Bu versiyon tamamen GNOME Shell JavaScript API kullanır.
EOF
	exit 1
}

# Başarı mesajı
show_success() {
	echo -e "${SUCCESS}$CHECK_MARK $1${NC}"
	notify-send -t $NOTIFICATION_TIMEOUT "GNOME-Flow" "$1"
}

# Hata mesajı
show_error() {
	echo -e "${ERROR}$CROSS_MARK Hata: $1${NC}" >&2
	notify-send -u critical -t $NOTIFICATION_TIMEOUT "GNOME-Flow Hata" "$1"
}

# Bilgi mesajı
show_info() {
	echo -e "${INFO}$ARROW_MARK $1${NC}"
	notify-send -t $NOTIFICATION_TIMEOUT "GNOME-Flow" "$1"
}

# Proses kontrolü
check_process() {
	pgrep -x "$1" >/dev/null
}

# MPV durumu kontrol
check_mpv() {
	if ! check_process "mpv"; then
		show_error "MPV çalışmıyor"
		return 1
	fi
	return 0
}

# Clipboard'dan içerik al
get_clipboard() {
	if command -v wl-paste >/dev/null 2>&1; then
		wl-paste 2>/dev/null || echo ""
	else
		show_error "wl-clipboard gerekli (wl-paste)"
		return 1
	fi
}

# GNOME Shell eval wrapper
gnome_eval() {
	local script="$1"
	gdbus call --session \
		--dest org.gnome.Shell \
		--object-path /org/gnome/Shell \
		--method org.gnome.Shell.Eval \
		"$script" 2>/dev/null
}

# MPV penceresini bul ve işlem yap
mpv_window_action() {
	local action="$1"
	local result

	result=$(gnome_eval "
		const windows = global.get_window_actors();
		let mpvWindow = null;
		
		for (let w of windows) {
			const metaWindow = w.get_meta_window();
			const wmClass = metaWindow.get_wm_class();
			if (wmClass && wmClass.toLowerCase().includes('mpv')) {
				mpvWindow = metaWindow;
				break;
			}
		}
		
		if (!mpvWindow) {
			'NOT_FOUND';
		} else {
			$action
		}
	")

	echo "$result"
}

# MPV'yi başlat
start_mpv() {
	if check_process "mpv"; then
		show_info "MPV zaten çalışıyor, aktif hale getiriliyor"
		mpv_window_action "mpvWindow.activate(global.get_current_time()); 'ACTIVATED';"
		return 0
	fi

	mpv --geometry=40%+50%+50% \
		--player-operation-mode=pseudo-gui \
		--input-ipc-server="$SOCKET_PATH" \
		--idle \
		--ontop \
		-- >/dev/null 2>&1 &
	disown

	show_success "MPV başlatıldı"
}

# Pencereyi döngüsel olarak taşı (4 köşe)
move_window() {
	check_mpv || return 1

	local result
	result=$(gnome_eval "
		const windows = global.get_window_actors();
		let mpvWindow = null;
		
		for (let w of windows) {
			const metaWindow = w.get_meta_window();
			const wmClass = metaWindow.get_wm_class();
			if (wmClass && wmClass.toLowerCase().includes('mpv')) {
				mpvWindow = metaWindow;
				break;
			}
		}
		
		if (!mpvWindow) {
			'NOT_FOUND';
		} else {
			const monitor = mpvWindow.get_monitor();
			const workArea = mpvWindow.get_work_area_for_monitor(monitor);
			const frame = mpvWindow.get_frame_rect();
			
			// Pencere boyutu (ekranın %40'ı)
			const targetWidth = Math.floor(workArea.width * 0.4);
			const targetHeight = Math.floor(workArea.height * 0.4);
			const margin = 50;
			
			// Mevcut pozisyona göre hedef belirleme
			const centerX = frame.x + frame.width / 2;
			const centerY = frame.y + frame.height / 2;
			const screenCenterX = workArea.x + workArea.width / 2;
			const screenCenterY = workArea.y + workArea.height / 2;
			
			let newX, newY;
			
			if (centerX < screenCenterX && centerY < screenCenterY) {
				// Sol üst -> Sağ üst
				newX = workArea.x + workArea.width - targetWidth - margin;
				newY = workArea.y + margin;
			} else if (centerX > screenCenterX && centerY < screenCenterY) {
				// Sağ üst -> Sağ alt
				newX = workArea.x + workArea.width - targetWidth - margin;
				newY = workArea.y + workArea.height - targetHeight - margin;
			} else if (centerX > screenCenterX && centerY > screenCenterY) {
				// Sağ alt -> Sol alt
				newX = workArea.x + margin;
				newY = workArea.y + workArea.height - targetHeight - margin;
			} else {
				// Sol alt -> Sol üst
				newX = workArea.x + margin;
				newY = workArea.y + margin;
			}
			
			mpvWindow.unmaximize(Meta.MaximizeFlags.BOTH);
			mpvWindow.move_resize_frame(true, newX, newY, targetWidth, targetHeight);
			mpvWindow.activate(global.get_current_time());
			
			'MOVED:' + newX + ',' + newY;
		}
	")

	if [[ "$result" == *"NOT_FOUND"* ]]; then
		show_error "MPV penceresi bulunamadı"
		return 1
	elif [[ "$result" == *"MOVED:"* ]]; then
		show_success "Pencere konumu güncellendi"
	fi
}

# Always-on-top toggle
toggle_stick() {
	check_mpv || return 1

	local result
	result=$(gnome_eval "
		const windows = global.get_window_actors();
		let mpvWindow = null;
		
		for (let w of windows) {
			const metaWindow = w.get_meta_window();
			const wmClass = metaWindow.get_wm_class();
			if (wmClass && wmClass.toLowerCase().includes('mpv')) {
				mpvWindow = metaWindow;
				break;
			}
		}
		
		if (!mpvWindow) {
			'NOT_FOUND';
		} else {
			if (mpvWindow.is_above()) {
				mpvWindow.unmake_above();
				'REMOVED';
			} else {
				mpvWindow.make_above();
				'ADDED';
			}
		}
	")

	if [[ "$result" == *"ADDED"* ]]; then
		show_success "Pencere always-on-top aktif"
	elif [[ "$result" == *"REMOVED"* ]]; then
		show_success "Pencere always-on-top kaldırıldı"
	else
		show_error "MPV penceresi bulunamadı"
	fi
}

# Pencereyi resize et ve ortala (%40)
resize_window() {
	check_mpv || return 1

	local result
	result=$(gnome_eval "
		const windows = global.get_window_actors();
		let mpvWindow = null;
		
		for (let w of windows) {
			const metaWindow = w.get_meta_window();
			const wmClass = metaWindow.get_wm_class();
			if (wmClass && wmClass.toLowerCase().includes('mpv')) {
				mpvWindow = metaWindow;
				break;
			}
		}
		
		if (!mpvWindow) {
			'NOT_FOUND';
		} else {
			const monitor = mpvWindow.get_monitor();
			const workArea = mpvWindow.get_work_area_for_monitor(monitor);
			
			const width = Math.floor(workArea.width * 0.4);
			const height = Math.floor(workArea.height * 0.4);
			const x = workArea.x + Math.floor((workArea.width - width) / 2);
			const y = workArea.y + Math.floor((workArea.height - height) / 2);
			
			mpvWindow.unmaximize(Meta.MaximizeFlags.BOTH);
			mpvWindow.move_resize_frame(true, x, y, width, height);
			mpvWindow.activate(global.get_current_time());
			
			'RESIZED';
		}
	")

	if [[ "$result" == *"RESIZED"* ]]; then
		show_success "Pencere %40 boyutunda ortalandı"
	else
		show_error "MPV penceresi bulunamadı"
	fi
}

# Pencereyi ortala (mevcut boyutla)
center_window() {
	check_mpv || return 1

	local result
	result=$(gnome_eval "
		const windows = global.get_window_actors();
		let mpvWindow = null;
		
		for (let w of windows) {
			const metaWindow = w.get_meta_window();
			const wmClass = metaWindow.get_wm_class();
			if (wmClass && wmClass.toLowerCase().includes('mpv')) {
				mpvWindow = metaWindow;
				break;
			}
		}
		
		if (!mpvWindow) {
			'NOT_FOUND';
		} else {
			const monitor = mpvWindow.get_monitor();
			const workArea = mpvWindow.get_work_area_for_monitor(monitor);
			const frame = mpvWindow.get_frame_rect();
			
			const x = workArea.x + Math.floor((workArea.width - frame.width) / 2);
			const y = workArea.y + Math.floor((workArea.height - frame.height) / 2);
			
			mpvWindow.move_frame(true, x, y);
			mpvWindow.activate(global.get_current_time());
			
			'CENTERED';
		}
	")

	if [[ "$result" == *"CENTERED"* ]]; then
		show_success "Pencere ortalandı"
	else
		show_error "MPV penceresi bulunamadı"
	fi
}

# Maximize
maximize_window() {
	check_mpv || return 1

	mpv_window_action "mpvWindow.maximize(Meta.MaximizeFlags.BOTH); 'MAXIMIZED';"
	show_success "Pencere maximize edildi"
}

# Unmaximize
unmaximize_window() {
	check_mpv || return 1

	mpv_window_action "mpvWindow.unmaximize(Meta.MaximizeFlags.BOTH); 'UNMAXIMIZED';"
	show_success "Pencere unmaximize edildi"
}

# Oynatma toggle
toggle_playback() {
	check_mpv || return 1

	if [[ ! -S "$SOCKET_PATH" ]]; then
		show_error "MPV socket bulunamadı"
		return 1
	fi

	local status
	status=$(echo '{ "command": ["get_property", "pause"] }' | socat - "$SOCKET_PATH" 2>/dev/null | grep -o '"data":true')

	echo '{ "command": ["cycle", "pause"] }' | socat - "$SOCKET_PATH" >/dev/null 2>&1

	if [[ "$status" == '"data":true' ]]; then
		show_success "Oynatma devam ediyor"
	else
		show_success "Oynatma duraklatıldı"
	fi
}

# YouTube oynat
play_youtube() {
	local video_url
	video_url=$(get_clipboard)

	if ! [[ "$video_url" =~ ^https?://(www\.)?(youtube\.com|youtu\.?be)/ ]]; then
		show_error "Geçerli bir YouTube URL'si değil"
		return 1
	fi

	local video_name
	video_name=$(yt-dlp --get-title "$video_url" 2>/dev/null || echo "YouTube Video")

	show_info "Oynatılıyor: $video_name"

	mpv --geometry=40%+50%+50% \
		--player-operation-mode=pseudo-gui \
		--input-ipc-server="$SOCKET_PATH" \
		--idle \
		--ontop \
		--no-audio-display \
		--speed=1 \
		--af=rubberband=pitch-scale=0.981818181818181 \
		"$video_url" >/dev/null 2>&1 &
	disown

	sleep 1
	show_success "Video oynatılıyor: $video_name"
}

# YouTube indir
download_youtube() {
	local video_url
	video_url=$(get_clipboard)

	if ! [[ "$video_url" =~ ^https?://(www\.)?(youtube\.com|youtu\.?be)/ ]]; then
		show_error "Geçerli bir YouTube URL'si değil"
		return 1
	fi

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

# Dependency kontrolü
check_dependencies() {
	local missing_deps=()

	if ! command -v mpv >/dev/null 2>&1; then
		missing_deps+=("mpv")
	fi

	if ! command -v gdbus >/dev/null 2>&1; then
		missing_deps+=("glib2")
	fi

	if ! command -v socat >/dev/null 2>&1; then
		missing_deps+=("socat")
	fi

	if ! command -v yt-dlp >/dev/null 2>&1; then
		missing_deps+=("yt-dlp")
	fi

	if ! command -v wl-paste >/dev/null 2>&1; then
		missing_deps+=("wl-clipboard")
	fi

	if [[ ${#missing_deps[@]} -gt 0 ]]; then
		show_error "Eksik bağımlılıklar: ${missing_deps[*]}"
		echo "Arch'ta kurmak için: sudo pacman -S ${missing_deps[*]}"
		exit 1
	fi
}

# Ana fonksiyon
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
	"maximize")
		maximize_window
		;;
	"unmaximize")
		unmaximize_window
		;;
	*)
		show_usage
		;;
	esac
}

# Script başlangıcı
if [[ $# -eq 0 ]]; then
	show_usage
fi

check_dependencies
main "$1"
