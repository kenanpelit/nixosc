#!/usr/bin/env bash
# =================================================================
# Hyprland TTY Başlatma Scripti - Sade Versiyon (Güncellenmiş)
# =================================================================
# ThinkPad E14 Gen 6 + Intel Arc Graphics + NixOS için optimize edilmiş
# =================================================================
set -euo pipefail

# Sabit değişkenler
readonly LOG_DIR="$HOME/.logs"
readonly HYPRLAND_LOG="$LOG_DIR/hyprland.log"
readonly DEBUG_LOG="$LOG_DIR/hyprland_debug.log"

# Terminal renk kodları
readonly GREEN='\033[0;32m'
readonly BLUE='\033[0;34m'
readonly YELLOW='\033[1;33m'
readonly RED='\033[0;31m'
readonly NC='\033[0m'

# =================================================================
# Yardımcı Fonksiyonlar
# =================================================================

# Debug log fonksiyonu - her zaman çalışır
debug_log() {
	local message="$1"
	local timestamp=$(date '+%Y-%m-%d %H:%M:%S')

	# Log dizinini yoksa oluştur
	[[ -d "$LOG_DIR" ]] || mkdir -p "$LOG_DIR"

	# Debug log dosyasına yaz
	echo "[${timestamp}] DEBUG: ${message}" >>"$DEBUG_LOG" 2>/dev/null || {
		# Fallback - stderr'e yaz
		echo "[${timestamp}] DEBUG: ${message}" >&2
	}

	# Ayrıca stderr'e de yaz
	echo "[${timestamp}] DEBUG: ${message}" >&2
}

# Güvenli log fonksiyonu
log() {
	local level=$1
	local message=$2
	local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
	local log_entry="[${timestamp}] [${level}] ${message}"

	# Önce debug log'a yaz
	debug_log "LOG: $log_entry"

	# Ana log dosyasına yazma denemesi
	if [[ -d "$(dirname "$HYPRLAND_LOG")" ]]; then
		echo "$log_entry" >>"$HYPRLAND_LOG" 2>/dev/null || {
			debug_log "Ana log dosyasına yazılamadı: $HYPRLAND_LOG"
		}
	else
		debug_log "Log dizini yok: $(dirname "$HYPRLAND_LOG")"
	fi
}

info() {
	echo -e "${GREEN}[INFO]${NC} $1"
	log "INFO" "$1"
}

warn() {
	echo -e "${YELLOW}[WARN]${NC} $1"
	log "WARN" "$1"
}

error() {
	echo -e "${RED}[ERROR]${NC} $1"
	log "ERROR" "$1"
	debug_log "FATAL ERROR: $1"
	exit 1
}

print_header() {
	local text="$1"
	echo
	echo -e "${BLUE}===============================================${NC}"
	echo -e "${BLUE}  ${GREEN}${text}${NC}"
	echo -e "${BLUE}===============================================${NC}"
	echo
}

# =================================================================
# Sistem Hazırlık
# =================================================================

setup_directories() {
	debug_log "setup_directories başlıyor"
	debug_log "LOG_DIR: $LOG_DIR"
	debug_log "HYPRLAND_LOG: $HYPRLAND_LOG"
	debug_log "Mevcut kullanıcı: $USER"
	debug_log "HOME dizini: $HOME"
	debug_log "Mevcut dizin: $(pwd)"

	# Ana log dizinini oluştur
	if mkdir -p "$LOG_DIR"; then
		debug_log "Log dizini başarıyla oluşturuldu: $LOG_DIR"

		# Dizin izinlerini kontrol et
		if [[ -w "$LOG_DIR" ]]; then
			debug_log "Log dizinine yazma izni var"
		else
			debug_log "Log dizinine yazma izni YOK!"
		fi

		# Log dosyasını oluştur
		if touch "$HYPRLAND_LOG"; then
			debug_log "Log dosyası başarıyla oluşturuldu: $HYPRLAND_LOG"
		else
			debug_log "Log dosyası oluşturulamadı: $HYPRLAND_LOG"
		fi
	else
		debug_log "HATA: Log dizini oluşturulamadı: $LOG_DIR"
		error "Log dizini oluşturulamadı: $LOG_DIR"
	fi

	# Log rotasyonu - 10MB üzerindeyse yedekle
	if [[ -f "$HYPRLAND_LOG" ]]; then
		local file_size=$(stat -c%s "$HYPRLAND_LOG" 2>/dev/null || echo 0)
		debug_log "Mevcut log dosyası boyutu: $file_size bytes"
		if [[ $file_size -gt 10485760 ]]; then
			debug_log "Log dosyası 10MB'den büyük, yedekleniyor"
			mv "$HYPRLAND_LOG" "${HYPRLAND_LOG}.old"
			debug_log "Log dosyası yedeklendi: ${HYPRLAND_LOG}.old"
		fi
	fi

	debug_log "setup_directories tamamlandı"
}

check_system() {
	debug_log "check_system başlıyor"

	# XDG_RUNTIME_DIR kontrolü
	if [[ -z "${XDG_RUNTIME_DIR:-}" ]]; then
		export XDG_RUNTIME_DIR="/run/user/$(id -u)"
		warn "XDG_RUNTIME_DIR atandı: $XDG_RUNTIME_DIR"
		debug_log "XDG_RUNTIME_DIR atandı: $XDG_RUNTIME_DIR"
	else
		debug_log "XDG_RUNTIME_DIR mevcut: $XDG_RUNTIME_DIR"
	fi

	# TTY kontrolü
	if [[ -z "${XDG_VTNR:-}" ]]; then
		export XDG_VTNR=1
		warn "XDG_VTNR=1 atandı"
		debug_log "XDG_VTNR=1 atandı"
	else
		debug_log "XDG_VTNR mevcut: $XDG_VTNR"
	fi

	# Intel Arc için özel kontrol
	if lspci | grep -i "arc\|meteor" &>/dev/null; then
		info "Intel Arc Graphics tespit edildi"
		debug_log "Intel Arc Graphics tespit edildi"

		# Intel Arc crash fix ayarları
		export WLR_DRM_NO_ATOMIC=1
		export WLR_RENDERER=gles2
		export INTEL_DEBUG=norbc
		info "Intel Arc uyumluluk modları aktif"
		debug_log "Intel Arc uyumluluk modları aktif"
	else
		debug_log "Intel Arc Graphics tespit edilmedi"
	fi

	# Hyprland binary kontrolü
	if command -v Hyprland &>/dev/null; then
		export HYPRLAND_BINARY="Hyprland"
		debug_log "Hyprland binary bulundu: Hyprland"
	elif command -v hyprland &>/dev/null; then
		export HYPRLAND_BINARY="hyprland"
		debug_log "Hyprland binary bulundu: hyprland"
	else
		debug_log "HATA: Hyprland binary bulunamadı"
		error "Hyprland binary bulunamadı"
	fi

	info "Sistem kontrolleri başarılı"
	debug_log "check_system tamamlandı"
}

# =================================================================
# Ortam Değişkenleri
# =================================================================

setup_environment() {
	print_header "ORTAM DEĞİŞKENLERİ AYARLANIYOR"
	debug_log "setup_environment başlıyor"

	# Temel Wayland ortam değişkenleri
	export XDG_SESSION_TYPE="wayland"
	export XDG_SESSION_DESKTOP="Hyprland"
	export XDG_CURRENT_DESKTOP="Hyprland"
	debug_log "Temel Wayland değişkenleri ayarlandı"

	# Wayland backend ayarları
	export MOZ_ENABLE_WAYLAND=1
	export QT_QPA_PLATFORM="wayland;xcb"
	export QT_WAYLAND_DISABLE_WINDOWDECORATION=1
	export GDK_BACKEND=wayland
	export SDL_VIDEODRIVER=wayland
	export JAVA_AWT_WM_NONREPARENTING=1 # FIX: * işareti kaldırıldı
	export CLUTTER_BACKEND=wayland
	export OZONE_PLATFORM=wayland
	debug_log "Wayland backend ayarları yapıldı"

	# GTK ve Qt tema ayarları
	export GTK_THEME=catppuccin-mocha-blue-standard
	export GTK_USE_PORTAL=1
	export GTK_APPLICATION_PREFER_DARK_THEME=1
	export QT_QPA_PLATFORMTHEME=gtk3
	export QT_STYLE_OVERRIDE=kvantum
	export QT_AUTO_SCREEN_SCALE_FACTOR=1
	debug_log "GTK ve Qt tema ayarları yapıldı"

	# Türkçe F-klavye
	export XKB_DEFAULT_LAYOUT=tr
	export XKB_DEFAULT_VARIANT=f
	export XKB_DEFAULT_OPTIONS=ctrl:nocaps
	debug_log "Türkçe F-klavye ayarları yapıldı"

	# Hyprland ayarları
	export HYPRLAND_LOG_WLR=1
	export HYPRLAND_NO_RT=1
	export HYPRLAND_NO_SD_NOTIFY=1
	debug_log "Hyprland özel ayarları yapıldı"

	# Varsayılan uygulamalar
	export EDITOR=nvim
	export VISUAL=nvim
	export TERMINAL=kitty
	export TERM=xterm-kitty
	export BROWSER=brave
	debug_log "Varsayılan uygulamalar ayarlandı"

	# Font rendering
	export FREETYPE_PROPERTIES="truetype:interpreter-version=40"
	debug_log "Font rendering ayarları yapıldı"

	info "Ortam değişkenleri ayarlandı"
	debug_log "setup_environment tamamlandı"
}

# =================================================================
# Hyprland Başlatma
# =================================================================

start_hyprland() {
	print_header "HYPRLAND BAŞLATILIYOR"
	debug_log "start_hyprland başlıyor"

	# Eski Hyprland proseslerini temizle
	local old_pids=$(pgrep -f "Hyprland\|hyprland" || true)
	if [[ -n "$old_pids" ]]; then
		warn "Eski Hyprland prosesleri sonlandırılıyor: $old_pids"
		debug_log "Eski Hyprland prosesleri bulundu: $old_pids"
		echo "$old_pids" | xargs -r kill -TERM 2>/dev/null || true
		sleep 1
		echo "$old_pids" | xargs -r kill -KILL 2>/dev/null || true
		debug_log "Eski prosesler temizlendi"
	else
		debug_log "Eski Hyprland prosesi bulunamadı"
	fi

	# Systemd ve DBus entegrasyonu
	info "Systemd entegrasyonu yapılandırılıyor..."
	debug_log "Systemd entegrasyonu başlıyor"

	systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE XDG_SESSION_DESKTOP 2>/dev/null || {
		debug_log "systemctl --user import-environment başarısız"
	}

	dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE XDG_SESSION_DESKTOP HYPRLAND_INSTANCE_SIGNATURE 2>/dev/null || {
		debug_log "dbus-update-activation-environment başarısız"
	}

	debug_log "Systemd entegrasyonu tamamlandı"

	# Temizlik için trap
	trap cleanup EXIT TERM INT
	debug_log "Cleanup trap ayarlandı"

	# Son kontroller
	debug_log "HYPRLAND_BINARY: $HYPRLAND_BINARY"
	debug_log "Log dosyası: $HYPRLAND_LOG"
	debug_log "Log dosyası mevcut: $(test -f "$HYPRLAND_LOG" && echo "EVET" || echo "HAYIR")"
	debug_log "Log dizini yazılabilir: $(test -w "$(dirname "$HYPRLAND_LOG")" && echo "EVET" || echo "HAYIR")"

	# Hyprland başlat
	info "Hyprland başlatılıyor: $HYPRLAND_BINARY"
	debug_log "Hyprland başlatılıyor: $HYPRLAND_BINARY"
	debug_log "Hyprland çıktısı $HYPRLAND_LOG dosyasına yönlendiriliyor"

	exec "$HYPRLAND_BINARY" >>"$HYPRLAND_LOG" 2>&1
}

# =================================================================
# Temizlik
# =================================================================

cleanup() {
	info "Hyprland oturumu sonlandırılıyor..."
	debug_log "cleanup fonksiyonu çağrıldı"
	# Gerekirse temizlik işlemleri burada
}

# =================================================================
# Ana Fonksiyon
# =================================================================

main() {
	# Debug log başlat - EN BAŞTA
	debug_log "Script başlatıldı: $(date)"
	debug_log "Kullanıcı: $USER"
	debug_log "PWD: $(pwd)"
	debug_log "Args: $*"

	# Debug modu kontrolü
	if [[ "${1:-}" == "-d" || "${1:-}" == "--debug" ]]; then
		set -x
		info "Debug modu aktif"
		debug_log "Bash debug modu aktif"
	fi

	# Yardım
	if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
		echo "Kullanım: $0 [-d|--debug] [-h|--help]"
		echo "  -d, --debug    Debug modu"
		echo "  -h, --help     Bu yardım"
		exit 0
	fi

	print_header "HYPRLAND TTY BAŞLATMA - ThinkPad E14 Gen 6"
	info "Başlatma zamanı: $(date)"
	info "Kullanıcı: $USER | TTY: $(tty 2>/dev/null || echo 'bilinmiyor')"

	debug_log "Ana işlem adımları başlıyor"

	# Ana işlem adımları
	setup_directories
	check_system
	setup_environment
	start_hyprland
}

# TTY kontrolü kaldırıldı - her yerden çalışabilir

# Script'i çalıştır
main "$@"
