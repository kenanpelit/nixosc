#!/usr/bin/env bash
#######################################
#
# Version: 1.0.0
# Date: 2024-12-12
# Author: Kenan Pelit
# Repository: github.com/kenanpelit/dotfiles
# Description: SystemChroot - Çoklu Sistem Chroot Yöneticisi
#
# Bu script farklı Linux sistemleri için chroot ortamı hazırlayan
# bir araçtır. Temel özellikleri:
#
# - Sistem Desteği:
#   - Arch Linux (subvolume yapılandırmalı)
#   - ArchTo (özel yapılandırma)
#   - ROG sistem desteği
#   - NixOS desteği
#
# - Mount Yönetimi:
#   - BTRFS subvolume desteği
#   - Otomatik partition algılama
#   - Sanal dosya sistemi bağlama
#   - DNS yapılandırması
#
# - Güvenlik ve Kontroller:
#   - Root yetkisi kontrolü
#   - Disk ve partition doğrulama
#   - Hata yönetimi ve temizlik
#   - Mount noktası kontrolü
#
# License: MIT
#
#######################################

# Renk tanımlamaları
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m' # No Color

# Kullanım bilgisi
usage() {
	cat <<EOF
Kullanım: $(basename "$0") -t <sistem_tipi> -d <disk> -m <hedef_dizin>

Seçenekler:
  -t, --type        Sistem tipi (arch, archto, rog, nixos)
  -d, --disk        Disk aygıtı (örn: /dev/nvme0n1, /dev/sda)
  -m, --mount       Chroot için hedef mount noktası
  -h, --help        Bu yardım mesajını gösterir

Örnekler:
  $(basename "$0") -t arch -d /dev/nvme0n1 -m /mnt/arch     # Arch sistemine chroot
  $(basename "$0") -t archto -d /dev/sda -m /mnt/archto     # Archto sistemine chroot
  $(basename "$0") -t rog -d /dev/nvme0n2 -m /mnt/rog       # ROG sistemine chroot
  $(basename "$0") -t nixos -d /dev/sdb -m /mnt/nixos       # NixOS sistemine chroot
EOF
	exit 1
}

# Hata mesajı fonksiyonu
error() {
	echo -e "${RED}Hata:${NC} $1" >&2
	exit 1
}

# Bilgi mesajı fonksiyonu
info() {
	echo -e "${GREEN}Bilgi:${NC} $1"
}

# Uyarı mesajı fonksiyonu
warning() {
	echo -e "${YELLOW}Uyarı:${NC} $1"
}

# Root yetkisi kontrolü
check_root() {
	if [ "$(id -u)" -ne 0 ]; then
		exec sudo "$0" "$@"
	fi
}

# Temizlik fonksiyonu
cleanup() {
	warning "Script kesintiye uğradı, mount noktaları temizleniyor..."
	umount -R "$TARGET_DIR" 2>/dev/null || true
}

# Mount fonksiyonu
mount_if_not_mounted() {
	local device=$1
	local target=$2
	local options=$3

	if [ ! -b "$device" ]; then
		error "$device disk bölümü bulunamadı!"
	fi

	if [ ! -d "$target" ]; then
		mkdir -p "$target"
	fi

	if mountpoint -q "$target"; then
		warning "$target zaten bağlı."
		return 0
	fi

	if ! mount $options "$device" "$target"; then
		error "$target bağlanamadı!"
	fi

	info "$target başarıyla bağlandı."
}

# Sanal dosya sistemlerini bağlama
mount_virtual_filesystems() {
	local target=$1
	info "Sanal dosya sistemleri bağlanıyor..."

	mkdir -p "$target"/{proc,sys,dev,run}

	mount --types proc /proc "$target/proc"
	mount --rbind /sys "$target/sys"
	mount --make-rslave "$target/sys"
	mount --rbind /dev "$target/dev"
	mount --make-rslave "$target/dev"
	mount --bind /run "$target/run"
	mount --make-slave "$target/run"
}

# DNS yapılandırması
setup_dns() {
	local target=$1
	if [[ -e /etc/resolv.conf ]]; then
		if [ -L "$target/etc/resolv.conf" ] || [ -f "$target/etc/resolv.conf" ]; then
			rm -f "$target/etc/resolv.conf"
		fi
		cp -L /etc/resolv.conf "$target/etc/resolv.conf"
		chmod 644 "$target/etc/resolv.conf"
		info "DNS yapılandırması chroot ortamına kopyalandı."
	else
		error "/etc/resolv.conf bulunamadı!"
	fi
}

# Partition numaralarını belirle
get_partitions() {
	local disk=$1

	# Eğer tam partition verilmişse (örn: /dev/nvme0n1p3) direkt kullan
	if [[ "$disk" =~ p[0-9]+$ ]] || [[ "$disk" =~ [0-9]+$ ]]; then
		ROOT_PART="$disk"
		# Ana diskin yolunu çıkar
		local base_disk
		if [[ "$disk" =~ (.*p)[0-9]+$ ]]; then
			base_disk="${BASH_REMATCH[1]}"
		else
			base_disk="${disk%[0-9]}"
		fi

		case $SYSTEM_TYPE in
		arch)
			BOOT_PART="${base_disk}1"
			REPO_PART="${base_disk}4"
			KENP_PART="${base_disk}5"
			;;
		archto)
			BOOT_PART="${base_disk}1"
			;;
		rog)
			REPO_PART="${base_disk}3"
			;;
		nixos)
			BOOT_PART="${base_disk}1"
			HOME_PART="${base_disk}3"
			;;
		esac
	else
		# Tam disk verilmişse partition numaralarını ekle
		local partnum_suffix=""
		if [[ "$disk" =~ "nvme" ]]; then
			partnum_suffix="p"
		fi

		local base="${disk}${partnum_suffix}"
		case $SYSTEM_TYPE in
		arch)
			BOOT_PART="${base}1"
			ROOT_PART="${base}2"
			REPO_PART="${base}4"
			KENP_PART="${base}5"
			;;
		archto)
			BOOT_PART="${base}1"
			ROOT_PART="${base}3"
			;;
		rog)
			ROOT_PART="${base}2"
			REPO_PART="${base}3"
			;;
		nixos)
			BOOT_PART="${base}1"
			ROOT_PART="${base}2"
			HOME_PART="${base}3" # Eğer varsa
			;;
		esac
	fi
}

# Arch sistemi için mount işlemleri
setup_arch() {
	mkdir -p "$TARGET_DIR"/{home,repo,kenp,proc,sys,dev,run,boot/efi,root,srv,var/{cache,log,tmp}}

	info "Disk bölümleri bağlanıyor..."
	mount_if_not_mounted "$ROOT_PART" "$TARGET_DIR" "-o subvol=@"
	mount_if_not_mounted "$ROOT_PART" "$TARGET_DIR/home" "-o subvol=@home"
	mount_if_not_mounted "$ROOT_PART" "$TARGET_DIR/root" "-o subvol=@root"
	mount_if_not_mounted "$ROOT_PART" "$TARGET_DIR/srv" "-o subvol=@srv"
	mount_if_not_mounted "$ROOT_PART" "$TARGET_DIR/var/cache" "-o subvol=@cache"
	mount_if_not_mounted "$ROOT_PART" "$TARGET_DIR/var/log" "-o subvol=@log"
	mount_if_not_mounted "$ROOT_PART" "$TARGET_DIR/var/tmp" "-o subvol=@tmp"
	mount_if_not_mounted "$BOOT_PART" "$TARGET_DIR/boot/efi" ""
	mount_if_not_mounted "$REPO_PART" "$TARGET_DIR/repo" ""
	mount_if_not_mounted "$KENP_PART" "$TARGET_DIR/kenp" ""
}

# Archto sistemi için mount işlemleri
setup_archto() {
	mkdir -p "$TARGET_DIR"/{proc,sys,dev,run,etc,root,home,srv,var/{cache,log,tmp}}

	info "Disk bölümü bağlanıyor..."
	mount_if_not_mounted "$ROOT_PART" "$TARGET_DIR" "-o subvol=@"
	mount_if_not_mounted "$ROOT_PART" "$TARGET_DIR/home" "-o subvol=@home"
	mount_if_not_mounted "$ROOT_PART" "$TARGET_DIR/root" "-o subvol=@root"
	mount_if_not_mounted "$ROOT_PART" "$TARGET_DIR/srv" "-o subvol=@srv"
	mount_if_not_mounted "$ROOT_PART" "$TARGET_DIR/var/cache" "-o subvol=@cache"
	mount_if_not_mounted "$ROOT_PART" "$TARGET_DIR/var/log" "-o subvol=@log"
	mount_if_not_mounted "$ROOT_PART" "$TARGET_DIR/var/tmp" "-o subvol=@tmp"
}

# ROG sistemi için mount işlemleri
setup_rog() {
	mkdir -p "$TARGET_DIR"/{home,repo,proc,sys,dev,run}

	info "Disk bölümleri bağlanıyor..."
	mount_if_not_mounted "$ROOT_PART" "$TARGET_DIR" "-o subvol=@"
	mount_if_not_mounted "$ROOT_PART" "$TARGET_DIR/home" "-o subvol=@home"
	mount_if_not_mounted "$REPO_PART" "$TARGET_DIR/repo" ""
}

# NixOS sistemi için mount işlemleri
setup_nixos() {
	mkdir -p "$TARGET_DIR"/{boot,nix,home,etc,proc,sys,dev,run}

	info "Disk bölümleri bağlanıyor..."
	mount_if_not_mounted "$ROOT_PART" "$TARGET_DIR" ""

	if [ -n "$BOOT_PART" ]; then
		mount_if_not_mounted "$BOOT_PART" "$TARGET_DIR/boot" ""
	fi

	if [ -n "$HOME_PART" ]; then
		mount_if_not_mounted "$HOME_PART" "$TARGET_DIR/home" ""
	fi

	# Gerekli dizinlerin varlığını kontrol et
	mkdir -p "$TARGET_DIR/etc/static"

	# Resolv.conf için özel işlem
	if [ -L "$TARGET_DIR/etc/resolv.conf" ]; then
		rm -f "$TARGET_DIR/etc/resolv.conf"
	fi

	# Sanal dosya sistemleri için izinleri ayarla
	chmod 755 "$TARGET_DIR"/{dev,sys,proc}
}

# Ana program başlangıcı
main() {
	check_root "$@"

	# Hata durumunda scripti durdur
	set -e

	# SIGINT ve SIGTERM sinyallerini yakala
	trap cleanup INT TERM

	# Varsayılan değerler
	SYSTEM_TYPE=""
	DISK=""
	TARGET_DIR=""

	# Parametre ayrıştırma
	while [[ $# -gt 0 ]]; do
		case $1 in
		-t | --type)
			SYSTEM_TYPE="$2"
			shift 2
			;;
		-d | --disk)
			DISK="$2"
			shift 2
			;;
		-m | --mount)
			TARGET_DIR="$2"
			shift 2
			;;
		-h | --help)
			usage
			;;
		*)
			error "Bilinmeyen parametre: $1"
			;;
		esac
	done

	# Gerekli parametrelerin kontrolü
	if [ -z "$SYSTEM_TYPE" ] || [ -z "$DISK" ] || [ -z "$TARGET_DIR" ]; then
		error "Sistem tipi (-t), disk (-d) ve hedef dizin (-m) belirtilmelidir!"
	fi

	# Disk kontrolü
	if [ ! -b "$DISK" ]; then
		error "$DISK bulunamadı!"
	fi

	info "Chroot hazırlanıyor..."

	# Partition numaralarını belirle
	get_partitions "$DISK"

	# Sistem tipine göre mount işlemlerini gerçekleştir
	case $SYSTEM_TYPE in
	arch)
		setup_arch
		;;
	archto)
		setup_archto
		;;
	rog)
		setup_rog
		;;
	nixos)
		setup_nixos
		;;
	*)
		error "Geçersiz sistem tipi: $SYSTEM_TYPE"
		;;
	esac

	# Ortak işlemler
	mount_virtual_filesystems "$TARGET_DIR"
	setup_dns "$TARGET_DIR"

	info "Chroot ortamı hazır. Sisteme giriş yapmak için şu komutları kullanabilirsiniz:"
	echo
	case $SYSTEM_TYPE in
	nixos)
		echo "NixOS için:"
		echo "   nixos-enter --root $TARGET_DIR"
		;;
	*)
		echo "1. arch-chroot ile (önerilen):"
		echo "   arch-chroot $TARGET_DIR"
		echo
		echo "2. Klasik chroot ile:"
		echo "   chroot $TARGET_DIR /bin/bash"
		;;
	esac
	echo
	echo "Not: Çıkış yaptıktan sonra mount noktalarını temizlemek için:"
	echo "   exit                           # Chroot'dan çık"
	echo "   cd                             # Hedef dizinden uzaklaş"
	echo "   umount -R $TARGET_DIR         # Tüm mount noktalarını temizle"
}

# Programı çalıştır
main "$@"
