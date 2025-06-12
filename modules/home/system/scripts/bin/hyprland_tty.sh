#!/usr/bin/env bash
# =================================================================
# Hyprland TTY Başlatma Scripti - Sade Versiyon
# =================================================================
# ThinkPad E14 Gen 6 + Intel Arc Graphics + NixOS için optimize edilmiş
# =================================================================

set -euo pipefail

# Sabit değişkenler
readonly LOG_DIR="$HOME/.logs"
readonly HYPRLAND_LOG="$LOG_DIR/hyprland.log"

# Terminal renk kodları
readonly GREEN='\033[0;32m'
readonly BLUE='\033[0;34m'
readonly YELLOW='\033[1;33m'
readonly RED='\033[0;31m'
readonly NC='\033[0m'

# =================================================================
# Yardımcı Fonksiyonlar
# =================================================================

log() {
	local level=$1
	local message=$2
	local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
	echo "[${timestamp}] [${level}] ${message}" >>"$HYPRLAND_LOG"
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
	mkdir -p "$LOG_DIR" || error "Log dizini oluşturulamadı: $LOG_DIR"

	# Log rotasyonu - 10MB üzerindeyse yedekle
	if [[ -f "$HYPRLAND_LOG" ]] && [[ $(stat -c%s "$HYPRLAND_LOG" 2>/dev/null || echo 0) -gt 10485760 ]]; then
		mv "$HYPRLAND_LOG" "${HYPRLAND_LOG}.old"
	fi
}

check_system() {
	# XDG_RUNTIME_DIR kontrolü
	if [[ -z "${XDG_RUNTIME_DIR:-}" ]]; then
		export XDG_RUNTIME_DIR="/run/user/$(id -u)"
		warn "XDG_RUNTIME_DIR atandı: $XDG_RUNTIME_DIR"
	fi

	# TTY kontrolü
	if [[ -z "${XDG_VTNR:-}" ]]; then
		export XDG_VTNR=1
		warn "XDG_VTNR=1 atandı"
	fi

	# Intel Arc için özel kontrol
	if lspci | grep -i "arc\|meteor" &>/dev/null; then
		info "Intel Arc Graphics tespit edildi"
		# Intel Arc crash fix ayarları
		export WLR_DRM_NO_ATOMIC=1
		export WLR_RENDERER=gles2
		export INTEL_DEBUG=norbc
		info "Intel Arc uyumluluk modları aktif"
	fi

	# Hyprland binary kontrolü
	if command -v Hyprland &>/dev/null; then
		export HYPRLAND_BINARY="Hyprland"
	elif command -v hyprland &>/dev/null; then
		export HYPRLAND_BINARY="hyprland"
	else
		error "Hyprland binary bulunamadı"
	fi

	info "Sistem kontrolleri başarılı"
}

# =================================================================
# Ortam Değişkenleri
# =================================================================

setup_environment() {
	print_header "ORTAM DEĞİŞKENLERİ AYARLANIYOR"

	# Temel Wayland ortam değişkenleri
	export XDG_SESSION_TYPE="wayland"
	export XDG_SESSION_DESKTOP="Hyprland"
	export XDG_CURRENT_DESKTOP="Hyprland"

	# Wayland backend ayarları
	export MOZ_ENABLE_WAYLAND=1
	export QT_QPA_PLATFORM="wayland;xcb"
	export QT_WAYLAND_DISABLE_WINDOWDECORATION=1
	export GDK_BACKEND=wayland
	export SDL_VIDEODRIVER=wayland
	export _JAVA_AWT_WM_NONREPARENTING=1
	export CLUTTER_BACKEND=wayland
	export OZONE_PLATFORM=wayland

	# GTK ve Qt tema ayarları
	export GTK_THEME=catppuccin-mocha-blue-standard
	export GTK_USE_PORTAL=1
	export GTK_APPLICATION_PREFER_DARK_THEME=1
	export QT_QPA_PLATFORMTHEME=gtk3
	export QT_STYLE_OVERRIDE=kvantum
	export QT_AUTO_SCREEN_SCALE_FACTOR=1

	# Türkçe F-klavye
	export XKB_DEFAULT_LAYOUT=tr
	export XKB_DEFAULT_VARIANT=f
	export XKB_DEFAULT_OPTIONS=ctrl:nocaps

	# Hyprland ayarları
	export HYPRLAND_LOG_WLR=1
	export HYPRLAND_NO_RT=1
	export HYPRLAND_NO_SD_NOTIFY=1

	# Varsayılan uygulamalar
	export EDITOR=nvim
	export VISUAL=nvim
	export TERMINAL=kitty
	export TERM=xterm-kitty
	export BROWSER=brave

	# Font rendering
	export FREETYPE_PROPERTIES="truetype:interpreter-version=40"

	info "Ortam değişkenleri ayarlandı"
}

# =================================================================
# Hyprland Başlatma
# =================================================================

start_hyprland() {
	print_header "HYPRLAND BAŞLATILIYOR"

	# Eski Hyprland proseslerini temizle
	local old_pids=$(pgrep -f "Hyprland\|hyprland" || true)
	if [[ -n "$old_pids" ]]; then
		warn "Eski Hyprland prosesleri sonlandırılıyor: $old_pids"
		echo "$old_pids" | xargs -r kill -TERM 2>/dev/null || true
		sleep 1
		echo "$old_pids" | xargs -r kill -KILL 2>/dev/null || true
	fi

	# Systemd ve DBus entegrasyonu
	info "Systemd entegrasyonu yapılandırılıyor..."
	systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE XDG_SESSION_DESKTOP || true
	dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE XDG_SESSION_DESKTOP HYPRLAND_INSTANCE_SIGNATURE || true

	# Temizlik için trap
	trap cleanup EXIT TERM INT

	# Hyprland başlat
	info "Hyprland başlatılıyor: $HYPRLAND_BINARY"
	exec "$HYPRLAND_BINARY" >>"$HYPRLAND_LOG" 2>&1
}

# =================================================================
# Temizlik
# =================================================================

cleanup() {
	info "Hyprland oturumu sonlandırılıyor..."
	# Gerekirse temizlik işlemleri burada
}

# =================================================================
# Ana Fonksiyon
# =================================================================

main() {
	# Debug modu kontrolü
	if [[ "${1:-}" == "-d" || "${1:-}" == "--debug" ]]; then
		set -x
		info "Debug modu aktif"
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

	# Ana işlem adımları
	setup_directories
	check_system
	setup_environment
	start_hyprland
}

# TTY kontrolü (isteğe bağlı)
if [[ "${FORCE:-0}" != "1" && "$(tty)" != "/dev/tty1" ]]; then
	warn "Bu script TTY1 için tasarlandı, mevcut TTY: $(tty)"
	read -p "Devam edilsin mi? (y/N): " -n 1 -r
	echo
	if [[ ! $REPLY =~ ^[Yy]$ ]]; then
		info "İptal edildi"
		exit 0
	fi
fi

# Script'i çalıştır
main "$@"
