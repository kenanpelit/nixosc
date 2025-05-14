#!/usr/bin/env bash

# =================================================================
# Çoklu Masaüstü Oturumu Başlatma Yöneticisi
# =================================================================
# Version: 1.0.0
# Date: 2025-05-10
# Author: Kenan Pelit
# Repository: https://github.com/kenanpelit/nixosc
#
# Amaç:
# Farklı TTY'lerde farklı masaüstü ortamlarını başlatmak ve yönetmek
#
# Oturum Dağılımı:
# TTY1: Hyprland - Modern Wayland pencere yöneticisi (birincil ekran)
# TTY2: Hyprland - Modern Wayland pencere yöneticisi (ikincil ekran)
# TTY3: COSMIC masaüstü ortamı - System76 tarafından geliştirilen Rust tabanlı DE
# TTY4: QEMU Ubuntu VM (Sway ile)
# TTY5: QEMU NixOS VM (Sway ile)
# TTY6: QEMU Arch VM (Sway ile)
# =================================================================

# Sabit değişkenler ve yapılandırmalar
readonly SCRIPT_NAME=$(basename "$0")
readonly SCRIPT_VERSION="1.0.0"
readonly LOG_DIR="$HOME/.logs"
readonly CONFIG_DIR="$HOME/.config"
readonly STARTUP_LOG="$LOG_DIR/startup-manager.log"
readonly VM_CONFIG_DIR="$CONFIG_DIR/sway"

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

	# Log dizininin varlığını kontrol et
	if [[ ! -d "$LOG_DIR" ]]; then
		mkdir -p "$LOG_DIR" 2>/dev/null
		if [[ $? -ne 0 ]]; then
			echo "UYARI: Log dizini oluşturulamadı: $LOG_DIR"
		fi
	fi

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
	local width=70
	local padding=$(((width - ${#text}) / 2))

	echo
	echo -e "${BLUE}$(printf '=%.0s' $(seq 1 $width))${NC}"
	echo -e "${BLUE}$(printf ' %.0s' $(seq 1 $padding))${CYAN}${text}${NC}"
	echo -e "${BLUE}$(printf '=%.0s' $(seq 1 $width))${NC}"
	echo
}

# Komut varlığını kontrol eder
check_command() {
	local cmd="$1"
	if ! command -v "$cmd" &>/dev/null; then
		warn "$cmd komutu bulunamadı!"
		return 1
	fi
	return 0
}

# =================================================================
# Sistem Hazırlık Fonksiyonları
# =================================================================

# Gereken dizinleri oluştur
setup_directories() {
	mkdir -p "$LOG_DIR" || warn "Log dizini oluşturulamadı: $LOG_DIR"
	mkdir -p "$VM_CONFIG_DIR" || warn "VM konfigürasyon dizini oluşturulamadı: $VM_CONFIG_DIR"
	info "Dizin yapılandırması tamamlandı"
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

	# Gerekli komutların kontrolü
	if [ "$XDG_VTNR" = "1" ] || [ "$XDG_VTNR" = "2" ]; then
		check_command "hyprland" || check_command "Hyprland" || warn "Hyprland binary bulunamadı!"
	elif [ "$XDG_VTNR" = "3" ]; then
		check_command "cosmic-session" || warn "Cosmic binary bulunamadı!"
	elif [ "$XDG_VTNR" -ge 4 ] && [ "$XDG_VTNR" -le 6 ]; then
		check_command "sway" || warn "Sway binary bulunamadı!"
	fi

	info "Sistem kontrolü tamamlandı, TTY$XDG_VTNR üzerinde çalışılıyor"
}

# =================================================================
# Oturum Başlatma Fonksiyonları
# =================================================================

# Hyprland masaüstü ortamını başlat (TTY1 veya TTY2)
start_hyprland() {
	local display_num="$1"
	local config_file="$CONFIG_DIR/hypr"

	if [ "$display_num" = "primary" ]; then
		print_header "HYPRLAND BAŞLATILIYOR (BİRİNCİL EKRAN - TTY1)"
		config_file="${config_file}/hyprland.conf"
	else
		print_header "HYPRLAND BAŞLATILIYOR (İKİNCİL EKRAN - TTY2)"
		config_file="${config_file}/hyprland_secondary.conf"
	fi

	info "Hyprland başlatma için hazırlanıyor..."

	# Hyprland için gerekli ortam değişkenleri
	export XDG_SESSION_TYPE="wayland"
	export XDG_SESSION_DESKTOP="Hyprland"
	export XDG_CURRENT_DESKTOP="Hyprland"

	# Özel config dosyasının varlığını kontrol et
	if [ -f "$config_file" ]; then
		info "Hyprland konfigürasyonu kullanılıyor: $config_file"
		HYPRLAND_CONF="$config_file"
		export HYPRLAND_CONF
	else
		info "Özel Hyprland konfigürasyonu bulunamadı, varsayılan kullanılacak"
	fi

	# Hyprland başlatma
	if check_command "hyprland_tty"; then
		info "hyprland_tty scripti kullanılıyor..."
		exec hyprland_tty >>"$LOG_DIR/hyprland_tty${display_num}.log" 2>&1
	elif check_command "Hyprland"; then
		info "Hyprland başlatılıyor..."
		exec Hyprland >>"$LOG_DIR/hyprland_${display_num}.log" 2>&1
	elif check_command "hyprland"; then
		info "hyprland başlatılıyor..."
		exec hyprland >>"$LOG_DIR/hyprland_${display_num}.log" 2>&1
	else
		error "Hyprland binary bulunamadı! Lütfen kurulumu kontrol edin."
	fi
}

# COSMIC masaüstü ortamını başlat (TTY3)
start_cosmic() {
	print_header "COSMIC MASAÜSTÜ ORTAMI BAŞLATILIYOR (TTY3)"
	info "COSMIC oturumu için ortam hazırlanıyor..."

	# COSMIC için gerekli ortam değişkenleri
	export XDG_SESSION_TYPE="wayland"
	export XDG_SESSION_DESKTOP="cosmic"
	export XDG_CURRENT_DESKTOP="COSMIC"
	export DESKTOP_SESSION="cosmic"

	# Klavye yapılandırması
	info "Türkçe F-klavye yapılandırması kontrol ediliyor..."
	if [ -f "/etc/vconsole.conf" ]; then
		if ! grep -q "KEYMAP=trf" /etc/vconsole.conf; then
			info "Klavye yapılandırması güncelleniyor..."
			echo "$VCONSOLE_CONFIG" | sudo tee /etc/vconsole.conf >/dev/null
		fi
	else
		info "Klavye yapılandırması oluşturuluyor..."
		echo "$VCONSOLE_CONFIG" | sudo tee /etc/vconsole.conf >/dev/null
	fi

	# COSMIC oturumunu başlat
	if check_command "cosmic-session"; then
		info "COSMIC oturumu başlatılıyor..."
		exec cosmic-session >>"$LOG_DIR/cosmic-session.log" 2>&1
	else
		error "COSMIC binary bulunamadı! Lütfen kurulumu kontrol edin."
	fi
}

# Sway ile QEMU sanal makine ortamını başlat (TTY4-6)
start_qemu_vm() {
	local vm_type="$1"
	local tty_num="$2"
	local config_name=""
	local log_name=""

	case "$vm_type" in
	"ubuntu")
		print_header "QEMU UBUNTU SANAL MAKİNE ORTAMI BAŞLATILIYOR (TTY4)"
		config_name="qemu_vmubuntu"
		log_name="qemu-ubuntu-session"
		;;
	"nixos")
		print_header "QEMU NIXOS SANAL MAKİNE ORTAMI BAŞLATILIYOR (TTY5)"
		config_name="qemu_vmnixos"
		log_name="qemu-nixos-session"
		;;
	"arch")
		print_header "QEMU ARCH SANAL MAKİNE ORTAMI BAŞLATILIYOR (TTY6)"
		config_name="qemu_vmarch"
		log_name="qemu-arch-session"
		;;
	*)
		error "Bilinmeyen VM tipi: $vm_type"
		;;
	esac

	info "Sway pencere yöneticisi QEMU $vm_type konfigürasyonu ile başlatılıyor..."

	# VM başlatma için gerekli ortam değişkenleri
	export XDG_SESSION_TYPE="wayland"
	export XDG_SESSION_DESKTOP="sway"
	export XDG_CURRENT_DESKTOP="sway"
	export DESKTOP_SESSION="sway"

	# Konfigürasyon dosyasının varlığını kontrol et
	local config_file="$VM_CONFIG_DIR/$config_name"
	if [ ! -f "$config_file" ]; then
		warn "Sway konfigürasyon dosyası bulunamadı: $config_file"
		warn "Varsayılan sway yapılandırması kullanılacak"
		config_file=""
	fi

	# Sway'i başlat
	if check_command "sway"; then
		if [ -n "$config_file" ]; then
			info "Sway başlatılıyor ($config_name konfigürasyonu ile)..."
			exec sway -c "$config_file" >>"$LOG_DIR/${log_name}.log" 2>&1
		else
			info "Sway başlatılıyor (varsayılan konfigürasyon ile)..."
			exec sway >>"$LOG_DIR/${log_name}.log" 2>&1
		fi
	else
		error "Sway binary bulunamadı! Lütfen kurulumu kontrol edin."
	fi
}

# =================================================================
# Yardım ve Versiyon Bilgisi
# =================================================================

print_version() {
	echo -e "${CYAN}${SCRIPT_NAME}${NC} versiyon ${GREEN}${SCRIPT_VERSION}${NC}"
	echo "Çoklu Masaüstü Oturumu Başlatma Yöneticisi"
	echo "Geliştirilme: $(date '+%Y')"
}

print_help() {
	print_version
	echo
	echo -e "Kullanım: ${CYAN}${SCRIPT_NAME}${NC} [SEÇENEKLER]"
	echo
	echo "Seçenekler:"
	echo "  -h, --help          Bu yardım mesajını göster ve çık"
	echo "  -v, --version       Versiyon bilgisini göster ve çık"
	echo "  -t, --tty NUM       Belirtilen TTY numarasını kullanarak başlat"
	echo "  -l, --list          Desteklenen masaüstü ortamlarını listele"
	echo
	echo "TTY Dağılımı:"
	echo "  TTY1: Hyprland (birincil ekran)"
	echo "  TTY2: Hyprland (ikincil ekran)"
	echo "  TTY3: COSMIC masaüstü ortamı"
	echo "  TTY4: QEMU Ubuntu VM (Sway ile)"
	echo "  TTY5: QEMU NixOS VM (Sway ile)"
	echo "  TTY6: QEMU Arch VM (Sway ile)"
	echo
	echo "Bu script, farklı TTY'lerde farklı masaüstü ortamlarını"
	echo "başlatmak ve yönetmek için kullanılır."
}

# Desteklenen masaüstü ortamlarını listele
list_desktop_environments() {
	print_header "DESTEKLENEN MASAÜSTÜ ORTAMLARI"

	echo -e "${CYAN}1. Hyprland${NC}"
	echo "   Modern, yapılandırılabilir Wayland pencere yöneticisi"
	if check_command "hyprland" || check_command "Hyprland"; then
		echo -e "   Durum: ${GREEN}Kurulu${NC}"
	else
		echo -e "   Durum: ${RED}Kurulu değil${NC}"
	fi
	echo

	echo -e "${CYAN}2. COSMIC${NC}"
	echo "   System76 tarafından geliştirilen Rust tabanlı masaüstü ortamı"
	if check_command "cosmic-session"; then
		echo -e "   Durum: ${GREEN}Kurulu${NC}"
	else
		echo -e "   Durum: ${RED}Kurulu değil${NC}"
	fi
	echo

	echo -e "${CYAN}3. Sway (QEMU VM'ler için)${NC}"
	echo "   i3-benzeri modern Wayland pencere yöneticisi"
	if check_command "sway"; then
		echo -e "   Durum: ${GREEN}Kurulu${NC}"
	else
		echo -e "   Durum: ${RED}Kurulu değil${NC}"
	fi
	echo
}

# =================================================================
# Ana Fonksiyon
# =================================================================
main() {
	# Komut satırı argümanlarını işle
	while [[ $# -gt 0 ]]; do
		case "$1" in
		-h | --help)
			print_help
			exit 0
			;;
		-v | --version)
			print_version
			exit 0
			;;
		-l | --list)
			list_desktop_environments
			exit 0
			;;
		-t | --tty)
			if [[ -n "$2" && "$2" =~ ^[1-6]$ ]]; then
				export XDG_VTNR="$2"
				shift
			else
				error "Geçersiz TTY numarası. 1-6 arasında bir değer belirtin."
			fi
			;;
		*)
			warn "Bilinmeyen seçenek: $1"
			echo "Yardım için --help kullanın"
			exit 1
			;;
		esac
		shift
	done

	# Sistemi hazırla
	setup_directories
	check_system

	# TTY numarasına göre uygun masaüstü ortamını başlat
	case "${XDG_VTNR}" in
	1) start_hyprland "primary" ;;
	2) start_hyprland "secondary" ;;
	3) start_cosmic ;;
	4) start_qemu_vm "ubuntu" 4 ;;
	5) start_qemu_vm "nixos" 5 ;;
	6) start_qemu_vm "arch" 6 ;;
	*)
		error "TTY${XDG_VTNR} için yapılandırılmış masaüstü oturumu bulunmuyor. Desteklenen TTY'ler: 1-6"
		;;
	esac
}

# Dosya doğrudan çalıştırıldıysa scripti çalıştır
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
	main "$@"
fi
