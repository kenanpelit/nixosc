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
# - Kullanım Özellikleri:
#   - Detaylı parametre sistemi
#   - Yardım menüsü
#   - İnteraktif kullanım
#   - Otomatik temizleme
#
# Kullanım:
# ./chroot-manager.sh -t <sistem_tipi> -d <disk> -m <hedef_dizin>
#
# License: MIT
#
#######################################

# Kullanım bilgisi
usage() {
  echo "Kullanım: $0 -t <sistem_tipi> -d <disk> -m <hedef_dizin>"
  echo "Seçenekler:"
  echo "  -t, --type        Sistem tipi (arch, archto, rog)"
  echo "  -d, --disk        Disk aygıtı (örn: /dev/nvme0n1, /dev/sda, /dev/sdb)"
  echo "  -m, --mount       Chroot için hedef mount noktası"
  echo "  -h, --help        Bu yardım mesajını gösterir"
  echo
  echo "Örnekler:"
  echo "  $0 -t arch -d /dev/nvme0n1 -m /mnt/arch       # Arch sistemine chroot"
  echo "  $0 -t archto -d /dev/nvme0n3 -m /mnt/archto   # Archto sistemine chroot"
  echo "  $0 -t rog -d /dev/sda -m /mnt/rog             # ROG sistemine chroot"
  exit 1
}

# Root yetkisi kontrolü
if [ "$(id -u)" -ne 0 ]; then
  exec sudo "$0" "$@"
fi

# Hata durumunda scripti durdur
set -e

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
    echo "Hata: Bilinmeyen parametre: $1"
    usage
    ;;
  esac
done

# Gerekli parametrelerin kontrolü
if [ -z "$SYSTEM_TYPE" ] || [ -z "$DISK" ] || [ -z "$TARGET_DIR" ]; then
  echo "Hata: Sistem tipi (-t), disk (-d) ve hedef dizin (-m) belirtilmelidir!"
  usage
fi

# Disk kontrolü
if [ ! -b "$DISK" ]; then
  echo "Hata: $DISK bulunamadı!"
  exit 1
fi

# Temizlik fonksiyonu
cleanup() {
  echo "Script kesintiye uğradı, mount noktaları temizleniyor..."
  umount -R "$TARGET_DIR" 2>/dev/null || true
}

# SIGINT ve SIGTERM sinyallerini yakala
trap cleanup INT TERM

# Mount fonksiyonu
mount_if_not_mounted() {
  local device=$1
  local target=$2
  local options=$3

  if [ ! -b "$device" ]; then
    echo "Hata: $device disk bölümü bulunamadı!"
    exit 1
  fi

  if [ ! -d "$target" ]; then
    mkdir -p "$target"
  fi

  if mountpoint -q "$target"; then
    echo "$target zaten bağlı."
  else
    if mount $options "$device" "$target"; then
      echo "$target başarıyla bağlandı."
    else
      echo "Hata: $target bağlanamadı!"
      exit 1
    fi
  fi
}

# Sanal dosya sistemlerini bağlama
mount_virtual_filesystems() {
  local target=$1
  echo "Sanal dosya sistemleri bağlanıyor..."

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
    cp -L /etc/resolv.conf "$target/etc/resolv.conf"
    echo "DNS yapılandırması chroot ortamına kopyalandı."
  else
    echo "Hata: /etc/resolv.conf bulunamadı!"
    exit 1
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
    esac
  fi
}

# Arch sistemi için mount işlemleri
setup_arch() {
  mkdir -p "$TARGET_DIR"/{home,repo,kenp,proc,sys,dev,run,boot/efi,root,srv,var/{cache,log,tmp}}

  echo "Disk bölümleri bağlanıyor..."
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
  # Temel dizinleri oluştur
  mkdir -p "$TARGET_DIR"/{proc,sys,dev,run,etc,root,home,srv,var/{cache,log,tmp}}

  echo "Disk bölümü bağlanıyor..."
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

  echo "Disk bölümleri bağlanıyor..."
  mount_if_not_mounted "$ROOT_PART" "$TARGET_DIR" "-o subvol=@"
  mount_if_not_mounted "$ROOT_PART" "$TARGET_DIR/home" "-o subvol=@home"
  mount_if_not_mounted "$REPO_PART" "$TARGET_DIR/repo" ""
}

# Ana işlem
echo "Chroot hazırlanıyor..."

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
*)
  echo "Hata: Geçersiz sistem tipi: $SYSTEM_TYPE"
  usage
  ;;
esac

# Ortak işlemler
mount_virtual_filesystems "$TARGET_DIR"
setup_dns "$TARGET_DIR"

echo "Chroot ortamı hazır. Sisteme giriş yapmak için şu komutları kullanabilirsiniz:"
echo
echo "1. arch-chroot ile (önerilen):"
echo "   arch-chroot $TARGET_DIR"
echo
echo "2. Klasik chroot ile:"
echo "   chroot $TARGET_DIR /bin/bash"
echo
echo "Not: Çıkış yaptıktan sonra mount noktalarını temizlemek için:"
echo "   exit                           # Chroot'dan çık"
echo "   cd                             # Hedef dizinden uzaklaş"
echo "   umount -R $TARGET_DIR         # Tüm mount noktalarını temizle"
