#!/usr/bin/env bash
# =================================================================
# Çoklu Masaüstü Oturumu Başlatma Yöneticisi
# =================================================================
# Amaç:
# Farklı TTY'lerde farklı masaüstü ortamlarını başlatmak ve yönetmek
#
# Oturum Dağılımı:
# TTY1: Hyprland - Modern Wayland pencere yöneticisi
# TTY2: QEMU NixOS VM (Sway ile)
# TTY3: QEMU Arch VM (Sway ile)
# TTY4: QEMU Ubuntu VM (Sway ile)
# TTY5: GNOME masaüstü ortamı
# TTY6: COSMIC masaüstü ortamı - System76 tarafından geliştirilen Rust tabanlı DE
# =================================================================

# Sabit değişkenler ve yapılandırmalar
readonly LOG_DIR="$HOME/.logs"
readonly CONFIG_DIR="$HOME/.config"
readonly STARTUP_LOG="$LOG_DIR/startup-manager.log"

# Vconsole yapılandırması - Türkçe F-klavye ayarları
readonly VCONSOLE_CONFIG="# Written by systemd-localed(8) or systemd-firstboot(1)
FONT=ter-v20b
KEYMAP=trf
XKBLAYOUT=tr
XKBVARIANT=f
XKBOPTIONS=ctrl:nocaps"

# Terminal renk kodları
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly PURPLE='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m' # No Color

# =================================================================
# Yardımcı Fonksiyonlar
# =================================================================

# Log fonksiyonu - Belirtilen seviyede log kaydı oluşturur
log() {
	local level=$1
	local message=$2
	local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
	echo -e "${timestamp} [${level}] ${message}" >>"$STARTUP_LOG"
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
	echo -e "${BLUE}$(printf ' %.0s' $(seq 1 $padding))${CYAN}${text}${NC}"
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
		error "XDG_VTNR tanımlanmamış. Bu script TTY oturumunda çalıştırılmalıdır."
	fi

	info "Sistem kontrolü tamamlandı, TTY$XDG_VTNR üzerinde çalışılıyor"
}

# =================================================================
# Oturum Başlatma Fonksiyonları
# =================================================================

# Hyprland masaüstü ortamını başlat (TTY1)
start_hyprland() {
	print_header "HYPRLAND BAŞLATILIYOR (TTY1)"
	info "Hyprland başlatma scripti çalıştırılıyor..."

	# Hyprland için gerekli ortam değişkenleri
	export XDG_SESSION_TYPE="wayland"
	export XDG_SESSION_DESKTOP="Hyprland"
	export XDG_CURRENT_DESKTOP="Hyprland"

	# Hyprland_tty scriptini çalıştır (PATH'de olacak)
	if command -v hyprland_tty &>/dev/null; then
		info "hyprland_tty scripti PATH'de bulundu, çalıştırılıyor..."
		exec hyprland_tty >>"$LOG_DIR/hyprland.log" 2>&1
	else
		# Alternatif: Doğrudan Hyprland'i başlat
		info "hyprland_tty scripti bulunamadı, doğrudan Hyprland başlatılıyor..."
		if command -v Hyprland &>/dev/null; then
			exec Hyprland >>"$LOG_DIR/hyprland.log" 2>&1
		elif command -v hyprland &>/dev/null; then
			exec hyprland >>"$LOG_DIR/hyprland.log" 2>&1
		else
			error "Hyprland binary bulunamadı! Lütfen kurulumu kontrol edin."
		fi
	fi
}

# QEMU NixOS sanal makine ortamını başlat (TTY2)
start_qemu_nixos() {
	print_header "QEMU NIXOS SANAL MAKİNE ORTAMI BAŞLATILIYOR (TTY2)"
	info "Sway pencere yöneticisi QEMU NixOS konfigürasyonu ile başlatılıyor..."

	# Sway için gerekli ortam değişkenleri
	export XDG_SESSION_TYPE="wayland"
	export XDG_SESSION_DESKTOP="sway"
	export XDG_CURRENT_DESKTOP="sway"
	export DESKTOP_SESSION="sway"

	# Sway'i özel konfigürasyon ile başlat
	exec sway -c "$CONFIG_DIR/sway/qemu_vmnixos" >>"$LOG_DIR/qemu-nixos-session.log" 2>&1
}

# QEMU Arch sanal makine ortamını başlat (TTY3)
start_qemu_arch() {
	print_header "QEMU ARCH SANAL MAKİNE ORTAMI BAŞLATILIYOR (TTY3)"
	info "Sway pencere yöneticisi QEMU Arch konfigürasyonu ile başlatılıyor..."

	# Sway için gerekli ortam değişkenleri
	export XDG_SESSION_TYPE="wayland"
	export XDG_SESSION_DESKTOP="sway"
	export XDG_CURRENT_DESKTOP="sway"
	export DESKTOP_SESSION="sway"

	# Sway'i özel konfigürasyon ile başlat
	exec sway -c "$CONFIG_DIR/sway/qemu_vmarch" >>"$LOG_DIR/qemu-arch-session.log" 2>&1
}

# QEMU Ubuntu sanal makine ortamını başlat (TTY4)
start_qemu_ubuntu() {
	print_header "QEMU UBUNTU SANAL MAKİNE ORTAMI BAŞLATILIYOR (TTY4)"
	info "Sway pencere yöneticisi QEMU Ubuntu konfigürasyonu ile başlatılıyor..."

	# Sway için gerekli ortam değişkenleri
	export XDG_SESSION_TYPE="wayland"
	export XDG_SESSION_DESKTOP="sway"
	export XDG_CURRENT_DESKTOP="sway"
	export DESKTOP_SESSION="sway"

	# Sway'i özel konfigürasyon ile başlat
	exec sway -c "$CONFIG_DIR/sway/qemu_vmubuntu" >>"$LOG_DIR/qemu-ubuntu-session.log" 2>&1
}

# GNOME masaüstü ortamını başlat (TTY5)
start_gnome() {
	print_header "GNOME MASAÜSTÜ ORTAMI BAŞLATILIYOR (TTY5)"
	info "GNOME oturumu için ortam değişkenleri ayarlanıyor..."

	# GNOME için gerekli ortam değişkenleri
	export XDG_SESSION_TYPE="wayland"
	export XDG_SESSION_DESKTOP="gnome"
	export XDG_CURRENT_DESKTOP="GNOME"
	export DESKTOP_SESSION="gnome"

	# DBus ve systemd entegrasyonu
	info "DBus ve systemd entegrasyonu yapılandırılıyor..."
	dbus-update-activation-environment --systemd XDG_CURRENT_DESKTOP
	systemctl --user import-environment XDG_CURRENT_DESKTOP

	# GNOME oturumunu başlat
	info "GNOME oturumu başlatılıyor..."
	exec gnome-session >>"$LOG_DIR/gnome-session.log" 2>&1
}

# COSMIC masaüstü ortamını başlat (TTY6)
start_cosmic() {
	print_header "COSMIC MASAÜSTÜ ORTAMI BAŞLATILIYOR (TTY6)"
	info "COSMIC oturumu için ortam hazırlanıyor..."

	# COSMIC için gerekli ortam değişkenleri
	export XDG_SESSION_TYPE="wayland"
	export XDG_SESSION_DESKTOP="cosmic"
	export XDG_CURRENT_DESKTOP="COSMIC"
	export DESKTOP_SESSION="cosmic"

	# Klavye yapılandırması
	info "Türkçe F-klavye yapılandırması ayarlanıyor..."
	echo "$VCONSOLE_CONFIG" | sudo tee /etc/vconsole.conf >/dev/null

	# COSMIC oturumunu başlat
	info "COSMIC oturumu başlatılıyor..."
	exec cosmic-session >>"$LOG_DIR/cosmic-session.log" 2>&1
}

# =================================================================
# Ana Fonksiyon
# =================================================================
main() {
	# Sistemi hazırla
	setup_directories
	check_system

	# TTY numarasına göre uygun masaüstü ortamını başlat
	case "${XDG_VTNR}" in
	1) start_hyprland ;;
	2) start_qemu_nixos ;;
	3) start_qemu_arch ;;
	4) start_qemu_ubuntu ;;
	5) start_gnome ;;
	6) start_cosmic ;;
	*)
		error "TTY${XDG_VTNR} için yapılandırılmış masaüstü oturumu bulunmuyor"
		;;
	esac
}

# Scripti çalıştır
main "$@"
