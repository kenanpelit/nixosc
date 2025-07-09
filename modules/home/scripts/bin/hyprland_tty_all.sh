#!/usr/bin/env bash
# =================================================================
# Hyprland TTY Başlatma Scripti
# =================================================================
# Amaç:
# TTY1'de Hyprland masaüstü ortamını başlatmak ve gerekli ortam
# değişkenlerini ayarlamak
# =================================================================

# Sabit değişkenler ve yapılandırmalar
readonly LOG_DIR="$HOME/.logs"
readonly CONFIG_DIR="$HOME/.config"
readonly HYPRLAND_LOG="$LOG_DIR/hyprland.log"

# Terminal renk kodları
readonly GREEN='\033[0;32m'
readonly BLUE='\033[0;34m'
readonly YELLOW='\033[1;33m'
readonly RED='\033[0;31m'
readonly NC='\033[0m' # No Color

# =================================================================
# Yardımcı Fonksiyonlar
# =================================================================

# Log fonksiyonu - Belirtilen seviyede log kaydı oluşturur
log() {
	local level=$1
	local message=$2
	local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
	echo -e "${timestamp} [${level}] ${message}" >>"$HYPRLAND_LOG"
}

# Bilgi mesajı - Standart çıktıya ve log dosyasına yazar
info() {
	echo -e "${GREEN}[INFO]${NC} $1"
	log "INFO" "$1"
}

# Uyarı mesajı - Standart çıktıya ve log dosyasına yazar
warn() {
	echo -e "${YELLOW}[WARN]${NC} $1"
	log "WARN" "$1"
}

# Hata mesajı - Standart çıktıya ve log dosyasına yazar, programı sonlandırır
error() {
	echo -e "${RED}[ERROR]${NC} $1"
	log "ERROR" "$1"
	exit 1
}

# Başlık yazdırma fonksiyonu - Dekoratif başlık gösterir
print_header() {
	local text="$1"
	local width=60
	local padding=$(((width - ${#text}) / 2))

	echo
	echo -e "${BLUE}$(printf '=%.0s' $(seq 1 $width))${NC}"
	echo -e "${BLUE}$(printf ' %.0s' $(seq 1 $padding))${GREEN}${text}${NC}"
	echo -e "${BLUE}$(printf '=%.0s' $(seq 1 $width))${NC}"
	echo
}

# =================================================================
# Sistem Hazırlık Fonksiyonları
# =================================================================

# Gereken dizinleri oluştur
setup_directories() {
	mkdir -p "$LOG_DIR" || error "Log dizini oluşturulamadı: $LOG_DIR"
	info "Log dizini hazır: $LOG_DIR"
}

# Sistem durumunu kontrol et
check_system() {
	# XDG_RUNTIME_DIR kontrolü
	if [ -z "$XDG_RUNTIME_DIR" ]; then
		export XDG_RUNTIME_DIR="/run/user/$(id -u)"
		warn "XDG_RUNTIME_DIR tanımlanmamış, varsayılan değer atandı: $XDG_RUNTIME_DIR"
	fi

	# TTY kontrolü
	if [ -z "$XDG_VTNR" ]; then
		warn "XDG_VTNR tanımlanmamış. TTY1 varsayılan olarak kullanılacak."
		export XDG_VTNR=1
	else
		info "TTY$XDG_VTNR üzerinde çalışılıyor"
	fi
}

# =================================================================
# Hyprland Başlatma Fonksiyonları
# =================================================================

# Ortam değişkenlerini ayarla
setup_environment() {
	print_header "HYPRLAND ORTAMI AYARLANIYOR"

	# Temel Wayland ortam değişkenleri
	export XDG_SESSION_TYPE="wayland"
	export XDG_SESSION_DESKTOP="Hyprland"
	export XDG_CURRENT_DESKTOP="Hyprland"

	# Wayland özel ayarlar
	export MOZ_ENABLE_WAYLAND=1
	export QT_QPA_PLATFORM=wayland
	export QT_WAYLAND_DISABLE_WINDOWDECORATION=1
	export GDK_BACKEND=wayland
	export SDL_VIDEODRIVER=wayland
	export _JAVA_AWT_WM_NONREPARENTING=1
	export CLUTTER_BACKEND=wayland
	export OZONE_PLATFORM=wayland

	# Konfigürasyonunuzdan alınan ek değişkenler
	export GTK_THEME=catppuccin-mocha-blue-standard
	export GTK_USE_PORTAL=1
	export GTK_APPLICATION_PREFER_DARK_THEME=1
	export QT_QPA_PLATFORMTHEME=gtk3
	export QT_STYLE_OVERRIDE=kvantum
	export QT_AUTO_SCREEN_SCALE_FACTOR=1

	# Türkçe F-klavye ayarı
	export XKB_DEFAULT_LAYOUT=tr
	export XKB_DEFAULT_VARIANT=f
	export XKB_DEFAULT_OPTIONS=ctrl:nocaps

	# Hyprland loglama
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

# Hyprland başlatma
start_hyprland() {
	print_header "HYPRLAND BAŞLATILIYOR"

	# Wayland entegrasyonu için systemd ve dbus güncellemeleri
	info "Systemd ve DBus entegrasyonu yapılandırılıyor..."
	systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE XDG_SESSION_DESKTOP
	dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE XDG_SESSION_DESKTOP HYPRLAND_INSTANCE_SIGNATURE

	# İşlem sonrası yapılacaklar için trap oluştur
	trap cleanup EXIT TERM INT

	# Hyprland'i başlat
	info "Hyprland başlatılıyor..."
	if [ -x "$(command -v Hyprland)" ]; then
		exec Hyprland >>"$HYPRLAND_LOG" 2>&1
	elif [ -x "$(command -v hyprland)" ]; then
		exec hyprland >>"$HYPRLAND_LOG" 2>&1
	else
		error "Hyprland binary bulunamadı. Lütfen kurulumu kontrol edin."
	fi
}

# Temizleme işlemleri
cleanup() {
	info "Hyprland oturumu sonlandırılıyor..."
	# Oturum kapandığında gerekli temizlik işlemleri burada yapılabilir
}

# =================================================================
# Ana Fonksiyon
# =================================================================
main() {
	print_header "HYPRLAND TTY BAŞLATMA SCRIPTI"

	# Sistemi hazırla
	setup_directories
	check_system

	# Hyprland için ortam değişkenlerini ayarla ve başlat
	setup_environment
	start_hyprland
}

# Scripti çalıştır
main "$@"
