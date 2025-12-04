#!/usr/bin/env bash
#######################################
#
# Version: 2.0.0
# Date: 2025-04-20
# Original Author: Kenan Pelit
# Updated By: Claude
# Repository: github.com/kenanpelit/dotfiles
# Description: SystemChroot - Çoklu Sistem Chroot Yöneticisi (Otomatik Sürüm)
#
# Bu script farklı Linux sistemleri için chroot ortamı otomatik olarak hazırlayan
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
#   - Otomatik sistem algılama
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
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Kullanım bilgisi
usage() {
	cat <<EOF
Kullanım: $(basename "$0") [seçenekler]

Seçenekler:
  -t, --type        Sistem tipi (arch, archto, rog, nixos) [otomatik tespit edilebilir]
  -d, --disk        Disk aygıtı (örn: /dev/nvme0n1, /dev/sda) [otomatik tespit edilebilir]
  -p, --part        Root partition (örn: /dev/nvme0n1p2) [otomatik tespit edilebilir]
  -m, --mount       Chroot için hedef mount noktası [varsayılan: /mnt/chroot]
  -l, --list        Mevcut sistemleri listele ve çık
  -a, --auto        Tam otomatik mod (sistemi ve diski otomatik seç)
  -h, --help        Bu yardım mesajını gösterir

Örnekler:
  $(basename "$0") -a                                       # Tam otomatik mod
  $(basename "$0") -t arch                                  # Arch sistemini otomatik bul ve mount et
  $(basename "$0") -t nixos -m /mnt/nixos                   # NixOS sistemini otomatik bul ve belirtilen dizine mount et
  $(basename "$0") -d /dev/nvme0n1                          # Belirtilen diskteki sistemleri otomatik tespit et
  $(basename "$0") -p /dev/nvme0n1p3                        # Belirtilen partitiondaki sistemi tespit et
  $(basename "$0") -t arch -d /dev/nvme0n1 -m /mnt/arch     # Klasik kullanım (tam manuel)
EOF
	exit 1
}

# Hata mesajı fonksiyonu
error() {
	echo -e "${RED}Hata:${NC} $1" >&2
	[ -n "$2" ] && exit "$2" || exit 1
}

# Bilgi mesajı fonksiyonu
info() {
	echo -e "${GREEN}Bilgi:${NC} $1"
}

# Uyarı mesajı fonksiyonu
warning() {
	echo -e "${YELLOW}Uyarı:${NC} $1"
}

# Debug mesajı fonksiyonu
debug() {
	if [ "$DEBUG" = "true" ]; then
		echo -e "${BLUE}Debug:${NC} $1"
	fi
}

# Root yetkisi kontrolü
check_root() {
	if [ "$(id -u)" -ne 0 ]; then
		exec sudo "$0" "$@"
	fi
}

# Temizlik fonksiyonu
cleanup() {
	local exit_code=$?
	if [ $exit_code -ne 0 ]; then
		warning "Script kesintiye uğradı (kod: $exit_code), mount noktaları temizleniyor..."
		if [ -n "$TARGET_DIR" ] && [ -d "$TARGET_DIR" ]; then
			umount -R "$TARGET_DIR" 2>/dev/null || true
		fi
	fi
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

	if [ -z "$options" ]; then
		mount_cmd="mount"
	else
		mount_cmd="mount $options"
	fi

	debug "$mount_cmd \"$device\" \"$target\""
	if ! $mount_cmd "$device" "$target"; then
		error "$target bağlanamadı!"
	fi

	info "$device --> $target başarıyla bağlandı."
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

		mkdir -p "$target/etc"
		cp -L /etc/resolv.conf "$target/etc/resolv.conf"
		chmod 644 "$target/etc/resolv.conf"
		info "DNS yapılandırması chroot ortamına kopyalandı."
	else
		warning "/etc/resolv.conf bulunamadı, DNS yapılandırması atlanıyor."
	fi
}

# Dosya sistemi tipini kontrol et
get_fs_type() {
	local device=$1
	if [ ! -b "$device" ]; then
		echo "unknown"
		return 1
	fi

	# lsblk ile filesystem tipini al
	local fs_type
	fs_type=$(lsblk -no FSTYPE "$device" 2>/dev/null)

	if [ -z "$fs_type" ]; then
		# blkid ile tekrar dene
		fs_type=$(blkid -o value -s TYPE "$device" 2>/dev/null)
	fi

	echo "$fs_type"
}

# Diskteki tüm partitionları bul
get_all_partitions() {
	local disk=$1

	# Disk formatını kontrol et
	if [[ ! "$disk" =~ ^/dev/ ]]; then
		disk="/dev/$disk"
	fi

	# Disk tipini kontrol et (nvme vs sata/usb)
	if [[ "$disk" =~ nvme ]]; then
		# NVME diskleri için partition deseni farkli
		echo "$(ls "${disk}p"* 2>/dev/null || ls "${disk}"[0-9]* 2>/dev/null)"
	else
		# Normal diskler için partition deseni
		echo "$(ls "${disk}"[0-9]* 2>/dev/null)"
	fi
}

# BTRFS subvolume'leri tespit et
detect_btrfs_subvolumes() {
	local device=$1
	local temp_mount="/tmp/btrfs_detect_$$"

	mkdir -p "$temp_mount"

	if ! mount -o ro "$device" "$temp_mount" 2>/dev/null; then
		rmdir "$temp_mount"
		return 1
	fi

	# Subvolume'leri liste olarak döndür
	btrfs subvolume list "$temp_mount" | awk '{print $NF}'

	umount "$temp_mount"
	rmdir "$temp_mount"
}

# Arch sistemi tespiti
detect_arch_system() {
	local device=$1
	local fs_type=$(get_fs_type "$device")

	# Arch genellikle BTRFS üzerinde subvolume yapısı kullanır
	if [ "$fs_type" = "btrfs" ]; then
		local temp_mount="/tmp/arch_detect_$$"
		mkdir -p "$temp_mount"

		if ! mount -o ro "$device" "$temp_mount" 2>/dev/null; then
			rmdir "$temp_mount"
			return 1
		fi

		# Arch Linux için tipik subvolume yapısı
		local arch_subvols=("@" "@home" "@root" "@cache" "@log" "@tmp")
		local found_subvols=0

		# Subvolume'leri kontrol et
		for subvol in $(btrfs subvolume list "$temp_mount" | awk '{print $NF}'); do
			for arch_subvol in "${arch_subvols[@]}"; do
				if [ "$subvol" = "$arch_subvol" ]; then
					found_subvols=$((found_subvols + 1))
				fi
			done
		done

		umount "$temp_mount"
		rmdir "$temp_mount"

		# En az 3 subvolume varsa muhtemelen Arch
		if [ $found_subvols -ge 3 ]; then
			return 0
		fi
	fi

	return 1
}

# ArchTo sistemi tespiti
detect_archto_system() {
	local device=$1
	local fs_type=$(get_fs_type "$device")

	# ArchTo da genellikle BTRFS kullanır ama özel yapılandırmaya sahiptir
	if [ "$fs_type" = "btrfs" ]; then
		local temp_mount="/tmp/archto_detect_$$"
		mkdir -p "$temp_mount"

		if ! mount -o ro "$device" "$temp_mount" 2>/dev/null; then
			rmdir "$temp_mount"
			return 1
		fi

		# ArchTo için dosya kontrolü
		if [ -f "$temp_mount/etc/archto-release" ]; then
			umount "$temp_mount"
			rmdir "$temp_mount"
			return 0
		fi

		umount "$temp_mount"
		rmdir "$temp_mount"
	fi

	return 1
}

# ROG sistemi tespiti
detect_rog_system() {
	local device=$1
	local fs_type=$(get_fs_type "$device")

	# ROG da genellikle BTRFS kullanır
	if [ "$fs_type" = "btrfs" ]; then
		local temp_mount="/tmp/rog_detect_$$"
		mkdir -p "$temp_mount"

		if ! mount -o ro "$device" "$temp_mount" 2>/dev/null; then
			rmdir "$temp_mount"
			return 1
		fi

		# ROG için dosya kontrolü
		if [ -d "$temp_mount/ROG" ] || grep -q "ROG" "$temp_mount/etc/os-release" 2>/dev/null; then
			umount "$temp_mount"
			rmdir "$temp_mount"
			return 0
		fi

		umount "$temp_mount"
		rmdir "$temp_mount"
	fi

	return 1
}

# NixOS sistemi tespiti
detect_nixos_system() {
	local device=$1
	local fs_type=$(get_fs_type "$device")

	# NixOS herhangi bir filesystem üzerinde olabilir
	local temp_mount="/tmp/nixos_detect_$$"
	mkdir -p "$temp_mount"

	if ! mount -o ro "$device" "$temp_mount" 2>/dev/null; then
		rmdir "$temp_mount"
		return 1
	fi

	# NixOS için dosya kontrolü
	if [ -d "$temp_mount/nix" ] || [ -f "$temp_mount/etc/NIXOS" ] ||
		[ -f "$temp_mount/etc/nixos/configuration.nix" ] ||
		grep -q "NixOS" "$temp_mount/etc/os-release" 2>/dev/null; then
		umount "$temp_mount"
		rmdir "$temp_mount"
		return 0
	fi

	umount "$temp_mount"
	rmdir "$temp_mount"
	return 1
}

# Sistem tipini tespit et
detect_system_type() {
	local device=$1

	if detect_nixos_system "$device"; then
		echo "nixos"
	elif detect_arch_system "$device"; then
		echo "arch"
	elif detect_rog_system "$device"; then
		echo "rog"
	elif detect_archto_system "$device"; then
		echo "archto"
	else
		echo "unknown"
	fi
}

# Tüm diskleri listele
list_all_disks() {
	# Sadece fiziksel diskleri listele (ramdisk, loop hariç)
	lsblk -dno NAME,SIZE,MODEL | grep -v "^loop\|^zram" | sort
}

# Kullanılabilir sistemleri tespit et ve listele
detect_available_systems() {
	local do_mount=${1:-false}

	info "Kullanılabilir sistemler taranıyor..."
	echo "--------------------------------------"
	printf "%-6s %-15s %-10s %-30s %-10s\n" "DISK" "PARTITION" "TİP" "BOYUT" "SİSTEM"
	echo "--------------------------------------"

	# Tüm diskleri al
	local disks=$(list_all_disks | awk '{print $1}')

	for disk in $disks; do
		local partitions=$(get_all_partitions "/dev/$disk")

		for part in $partitions; do
			# Swap ve boot partitionlarını atla
			local fs_type=$(get_fs_type "$part")
			if [ "$fs_type" = "swap" ]; then
				continue
			fi

			# Size bilgisini al
			local size=$(lsblk -no SIZE "$part" 2>/dev/null | head -1)

			# Sistem tipini tespit et
			local sys_type=$(detect_system_type "$part")

			if [ "$sys_type" != "unknown" ]; then
				printf "%-6s %-15s %-10s %-30s %-10s\n" "$disk" "$(basename "$part")" "$fs_type" "$size" "$sys_type"

				# Eğer tam otomatik modda isek ve hala bir root partition seçilmedi ise
				if [ "$do_mount" = "true" ] && [ -z "$ROOT_PART" ]; then
					ROOT_PART="$part"
					SYSTEM_TYPE="$sys_type"
					debug "Otomatik seçilen sistem: $SYSTEM_TYPE ($ROOT_PART)"
				fi
			fi
		done
	done
	echo "--------------------------------------"
}

# Partition ve ana diskleri bul
find_related_partitions() {
	local root_part=$1
	local sys_type=$2

	# Ana diskin yolunu çıkar
	local disk_base
	if [[ "$root_part" =~ nvme ]]; then
		if [[ "$root_part" =~ (.*p)[0-9]+$ ]]; then
			disk_base="${BASH_REMATCH[1]}"
			disk="${root_part%p*}"
		else
			disk_base="${root_part%[0-9]*}"
			disk="${root_part%[0-9]*}"
		fi
	else
		disk_base="${root_part%[0-9]*}"
		disk="${root_part%[0-9]*}"
	fi

	debug "Disk tabanı: $disk_base, Disk: $disk"

	# Root partition numarası
	local root_num
	if [[ "$root_part" =~ nvme ]]; then
		if [[ "$root_part" =~ .*p([0-9]+)$ ]]; then
			root_num="${BASH_REMATCH[1]}"
		else
			root_num="${root_part##*[^0-9]}"
		fi
	else
		root_num="${root_part##*[^0-9]}"
	fi

	debug "Root partition numarası: $root_num"

	# İlgili partitionları bul
	local all_parts=$(get_all_partitions "$disk")

	# Partition numaralarını al
	local part_nums=()
	for part in $all_parts; do
		if [[ "$part" =~ nvme ]]; then
			if [[ "$part" =~ .*p([0-9]+)$ ]]; then
				part_nums+=("${BASH_REMATCH[1]}")
			else
				part_nums+=("${part##*[^0-9]}")
			fi
		else
			part_nums+=("${part##*[^0-9]}")
		fi
	done

	# Sistem tipine göre özel partitionları belirle
	case $sys_type in
	arch)
		for num in "${part_nums[@]}"; do
			local curr_part="${disk_base}${num}"

			if [[ "$num" -ne "$root_num" ]]; then
				local fs_type=$(get_fs_type "$curr_part")
				if [ "$fs_type" = "vfat" ] || [ "$fs_type" = "fat32" ] || [ "$fs_type" = "fat" ]; then
					BOOT_PART="$curr_part"
					debug "Boot partition tespit edildi: $BOOT_PART"
				fi

				# Repo ve Kenp partitionlarını tespit et
				if [ "$num" -gt "$root_num" ]; then
					if [ -z "$REPO_PART" ]; then
						REPO_PART="$curr_part"
						debug "Repo partition tespit edildi: $REPO_PART"
					elif [ -z "$KENP_PART" ]; then
						KENP_PART="$curr_part"
						debug "Kenp partition tespit edildi: $KENP_PART"
					fi
				fi
			fi
		done
		;;
	archto)
		for num in "${part_nums[@]}"; do
			local curr_part="${disk_base}${num}"

			if [[ "$num" -ne "$root_num" ]]; then
				local fs_type=$(get_fs_type "$curr_part")
				if [ "$fs_type" = "vfat" ] || [ "$fs_type" = "fat32" ] || [ "$fs_type" = "fat" ]; then
					BOOT_PART="$curr_part"
					debug "Boot partition tespit edildi: $BOOT_PART"
				fi
			fi
		done
		;;
	rog)
		for num in "${part_nums[@]}"; do
			local curr_part="${disk_base}${num}"

			if [[ "$num" -ne "$root_num" ]]; then
				if [ "$num" -gt "$root_num" ]; then
					if [ -z "$REPO_PART" ]; then
						REPO_PART="$curr_part"
						debug "Repo partition tespit edildi: $REPO_PART"
					fi
				fi
			fi
		done
		;;
	nixos)
		for num in "${part_nums[@]}"; do
			local curr_part="${disk_base}${num}"

			if [[ "$num" -ne "$root_num" ]]; then
				local fs_type=$(get_fs_type "$curr_part")
				if [ "$fs_type" = "vfat" ] || [ "$fs_type" = "fat32" ] || [ "$fs_type" = "fat" ]; then
					BOOT_PART="$curr_part"
					debug "Boot partition tespit edildi: $BOOT_PART"
				elif [ "$num" -gt "$root_num" ]; then
					if [ -z "$HOME_PART" ]; then
						HOME_PART="$curr_part"
						debug "Home partition tespit edildi: $HOME_PART"
					fi
				fi
			fi
		done
		;;
	esac
}

# Arch sistemi için mount işlemleri
setup_arch() {
	mkdir -p "$TARGET_DIR"/{home,proc,sys,dev,run,boot/efi,root,srv,var/{cache,log,tmp}}

	info "Disk bölümleri bağlanıyor..."
	mount_if_not_mounted "$ROOT_PART" "$TARGET_DIR" "-o subvol=@"
	mount_if_not_mounted "$ROOT_PART" "$TARGET_DIR/home" "-o subvol=@home"
	mount_if_not_mounted "$ROOT_PART" "$TARGET_DIR/root" "-o subvol=@root"
	mount_if_not_mounted "$ROOT_PART" "$TARGET_DIR/srv" "-o subvol=@srv"
	mount_if_not_mounted "$ROOT_PART" "$TARGET_DIR/var/cache" "-o subvol=@cache"
	mount_if_not_mounted "$ROOT_PART" "$TARGET_DIR/var/log" "-o subvol=@log"
	mount_if_not_mounted "$ROOT_PART" "$TARGET_DIR/var/tmp" "-o subvol=@tmp"

	if [ -n "$BOOT_PART" ]; then
		mount_if_not_mounted "$BOOT_PART" "$TARGET_DIR/boot/efi" ""
	fi

	if [ -n "$REPO_PART" ]; then
		mkdir -p "$TARGET_DIR/repo"
		mount_if_not_mounted "$REPO_PART" "$TARGET_DIR/repo" ""
	fi

	if [ -n "$KENP_PART" ]; then
		mkdir -p "$TARGET_DIR/kenp"
		mount_if_not_mounted "$KENP_PART" "$TARGET_DIR/kenp" ""
	fi
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

	if [ -n "$BOOT_PART" ]; then
		mkdir -p "$TARGET_DIR/boot"
		mount_if_not_mounted "$BOOT_PART" "$TARGET_DIR/boot" ""
	fi
}

# ROG sistemi için mount işlemleri
setup_rog() {
	mkdir -p "$TARGET_DIR"/{home,proc,sys,dev,run}

	info "Disk bölümleri bağlanıyor..."
	mount_if_not_mounted "$ROOT_PART" "$TARGET_DIR" "-o subvol=@"
	mount_if_not_mounted "$ROOT_PART" "$TARGET_DIR/home" "-o subvol=@home"

	if [ -n "$REPO_PART" ]; then
		mkdir -p "$TARGET_DIR/repo"
		mount_if_not_mounted "$REPO_PART" "$TARGET_DIR/repo" ""
	fi
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

# Sistemi tespit et (disk veya partitiona göre)
auto_detect_system() {
	local src=$1
	local specified_type=$2

	if [ -z "$src" ]; then
		# Tam otomatik mod
		detect_available_systems true
		if [ -z "$ROOT_PART" ]; then
			error "Hiçbir sistem tespit edilemedi!"
		fi
		info "Otomatik olarak tespit edilen sistem: $SYSTEM_TYPE ($ROOT_PART)"
	elif [ -b "$src" ]; then
		# Belirli bir disk veya partition
		if [[ "$src" =~ .*[0-9]+$ ]]; then
			# Bu bir partition
			ROOT_PART="$src"

			if [ -n "$specified_type" ]; then
				SYSTEM_TYPE="$specified_type"
			else
				SYSTEM_TYPE=$(detect_system_type "$ROOT_PART")
				if [ "$SYSTEM_TYPE" = "unknown" ]; then
					error "$ROOT_PART üzerinde desteklenen bir sistem bulunamadı!"
				fi
			fi

			info "Tespit edilen sistem: $SYSTEM_TYPE ($ROOT_PART)"
		else
			# Bu bir disk, ilk uygun sistemi seç
			local found=false
			local partitions=$(get_all_partitions "$src")

			for part in $partitions; do
				local sys_type

				if [ -n "$specified_type" ]; then
					sys_type="$specified_type"
					# Belirtilen tipte mi kontrol et
					case $sys_type in
					arch)
						detect_arch_system "$part" || continue
						;;
					archto)
						detect_archto_system "$part" || continue
						;;
					rog)
						detect_rog_system "$part" || continue
						;;
					nixos)
						detect_nixos_system "$part" || continue
						;;
					esac
				else
					sys_type=$(detect_system_type "$part")
					[ "$sys_type" = "unknown" ] && continue
				fi

				ROOT_PART="$part"
				SYSTEM_TYPE="$sys_type"
				found=true
				break
			done

			if [ "$found" = "false" ]; then
				if [ -n "$specified_type" ]; then
					error "$src üzerinde $specified_type sistemi bulunamadı!"
				else
					error "$src üzerinde desteklenen bir sistem bulunamadı!"
				fi
			fi

			info "Tespit edilen sistem: $SYSTEM_TYPE ($ROOT_PART)"
		fi
	else
		error "$src geçerli bir disk veya partition değil!"
	fi
}

# Ana program başlangıcı
main() {
	check_root "$@"

	# Hata durumunda temizlik yapmak için trap ayarla
	trap cleanup EXIT

	# Varsayılan değerler
	SYSTEM_TYPE=""
	DISK=""
	ROOT_PART=""
	TARGET_DIR="/mnt/chroot"
	AUTO_MODE=false
	DEBUG=false

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
		-p | --part)
			ROOT_PART="$2"
			shift 2
			;;
		-m | --mount)
			TARGET_DIR="$2"
			shift 2
			;;
		-l | --list)
			detect_available_systems
			exit 0
			;;
		-a | --auto)
			AUTO_MODE=true
			shift 1
			;;
		--debug)
			DEBUG=true
			shift 1
			;;
		-h | --help)
			usage
			;;
		*)
			error "Bilinmeyen parametre: $1"
			;;
		esac
	done

	# Sistem tespiti
	if [ "$AUTO_MODE" = "true" ]; then
		info "Tam otomatik mod aktif, uygun sistem aranıyor..."
		auto_detect_system "" ""
	elif [ -n "$ROOT_PART" ]; then
		# Root partition belirtilmiş, tipi kontrol et
		if [ ! -b "$ROOT_PART" ]; then
			error "$ROOT_PART geçerli bir disk bölümü değil!"
		fi
		if [ -z "$SYSTEM_TYPE" ]; then
			SYSTEM_TYPE=$(detect_system_type "$ROOT_PART")
			if [ "$SYSTEM_TYPE" = "unknown" ]; then
				error "$ROOT_PART üzerinde desteklenen bir sistem bulunamadı!"
			fi
		fi
	elif [ -n "$DISK" ]; then
		# Disk belirtilmiş, uygun sistemi bul
		auto_detect_system "$DISK" "$SYSTEM_TYPE"
	elif [ -n "$SYSTEM_TYPE" ]; then
		# Sadece sistem tipi belirtilmiş, uygun diski bul
		info "Sistem tipi '$SYSTEM_TYPE' için uygun disk aranıyor..."
		local found=false
		local disks=$(list_all_disks | awk '{print $1}')

		for disk in $disks; do
			disk="/dev/$disk"
			local partitions=$(get_all_partitions "$disk")

			for part in $partitions; do
				case $SYSTEM_TYPE in
				arch)
					if detect_arch_system "$part"; then
						ROOT_PART="$part"
						found=true
						break 2
					fi
					;;
				archto)
					if detect_archto_system "$part"; then
						ROOT_PART="$part"
						found=true
						break 2
					fi
					;;
				rog)
					if detect_rog_system "$part"; then
						ROOT_PART="$part"
						found=true
						break 2
					fi
					;;
				nixos)
					if detect_nixos_system "$part"; then
						ROOT_PART="$part"
						found=true
						break 2
					fi
					;;
				esac
			done
		done

		if [ "$found" = "false" ]; then
			error "$SYSTEM_TYPE türünde bir sistem bulunamadı!"
		fi

		info "Bulunan sistem: $ROOT_PART"
	else
		# Hiçbir parametre belirtilmemiş
		warning "Hiçbir hedef belirtilmedi. Kullanılabilir sistemler listeleniyor..."
		detect_available_systems
		exit 0
	fi

	# İlgili partitionları tespit et
	find_related_partitions "$ROOT_PART" "$SYSTEM_TYPE"

	# Hedef dizini hazırla
	mkdir -p "$TARGET_DIR"

	# Sistem tipine göre mount işlemleri
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
		error "Desteklenmeyen sistem tipi: $SYSTEM_TYPE"
		;;
	esac

	# Ortak işlemler
	mount_virtual_filesystems "$TARGET_DIR"
	setup_dns "$TARGET_DIR"

	# Chroot komutu öner
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
