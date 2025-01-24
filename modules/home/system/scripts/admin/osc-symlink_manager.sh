#!/usr/bin/env bash
#===============================================================================
#
#   Script: OSC Symlink Manager
#   Version: 1.0.0
#   Date: 2024-01-23
#   Author: Kenan Pelit
#   Repository: https://github.com/kenanpelit/nixosc
#   Description: Manages symbolic links for configured directories between a
#                source repository and target location with backup functionality
#
#   Features:
#   - Creates symbolic links from source to target directories
#   - Automatic backup of existing directories
#   - Configurable directory list
#   - Dry-run mode for testing
#   - Color-coded status output
#   - Safety checks and confirmations
#
#   License: MIT
#
#===============================================================================

# Hata ayıklama için
set -euo pipefail

# Renk tanımlamaları
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Kaynak ve hedef dizinleri
SOURCE_ROOT="/repo/archive"
TARGET_ROOT="$HOME"

# Link yapılacak dizinlerin listesi
DIRS=(
	"Documents"
	"Music"
	"Work"
	"Tmp"
	# Buraya yeni dizinler eklenebilir
)

# Yardım mesajı
show_help() {
	echo -e "${BLUE}Symlink Yönetici${NC}"
	echo "Kullanım: $(basename "$0") [SEÇENEKLER]"
	echo
	echo "Seçenekler:"
	echo "  -l, --list     Mevcut array ve linkleri göster"
	echo "  -d, --dry-run  Yapılacak işlemleri göster ama uygulama"
	echo "  -h, --help     Bu yardım mesajını göster"
	echo
}

# Log fonksiyonu
log() {
	echo -e "${2:-$BLUE}$1${NC}"
}

# Array listesini göster
show_array() {
	log "\nYapılandırılmış dizinler:" "$BLUE"
	for dir in "${DIRS[@]}"; do
		echo "  - $dir"
	done
}

# Mevcut linkleri göster
show_links() {
	log "\nMevcut sembolik linkler:" "$BLUE"
	for dir in "${DIRS[@]}"; do
		if [[ -L "$TARGET_ROOT/$dir" ]]; then
			echo -e "${GREEN}✓${NC} $dir -> $(readlink "$TARGET_ROOT/$dir")"
		else
			echo -e "${RED}✗${NC} $dir (link yok)"
		fi
	done
}

# Hata kontrolü fonksiyonu
check_source_dir() {
	if [[ ! -d "$SOURCE_ROOT" ]]; then
		log "Kaynak dizin ($SOURCE_ROOT) bulunamadı!" "$RED"
		exit 1
	fi
}

# Yedekleme fonksiyonu
backup_dir() {
	local dir="$1"
	local backup_name="${dir}_backup_$(date +%Y%m%d_%H%M%S)"

	if [[ -d "$TARGET_ROOT/$dir" && ! -L "$TARGET_ROOT/$dir" ]]; then
		if [[ "$DRY_RUN" == "true" ]]; then
			log "[DRY-RUN] Yedeklenecek: $dir -> $backup_name" "$YELLOW"
		else
			log "Yedekleniyor: $dir -> $backup_name" "$YELLOW"
			mv "$TARGET_ROOT/$dir" "$TARGET_ROOT/$backup_name"
		fi
	fi
}

# Link oluşturma fonksiyonu
create_link() {
	local dir="$1"
	local source="$SOURCE_ROOT/$dir"
	local target="$TARGET_ROOT/$dir"

	# Kaynak dizin kontrolü
	if [[ ! -d "$source" ]]; then
		if [[ "$DRY_RUN" == "true" ]]; then
			log "[DRY-RUN] Kaynak dizin oluşturulacak: $source" "$YELLOW"
		else
			log "Uyarı: Kaynak dizin mevcut değil: $source" "$YELLOW"
			read -p "Kaynak dizin oluşturulsun mu? (e/h) " -n 1 -r
			echo
			if [[ $REPLY =~ ^[Ee]$ ]]; then
				mkdir -p "$source"
			else
				return 1
			fi
		fi
	fi

	# Mevcut link kontrolü
	if [[ -L "$target" ]]; then
		log "Link zaten mevcut: $target -> $(readlink "$target")" "$YELLOW"
		return 0
	fi

	# Link oluşturma
	if [[ "$DRY_RUN" == "true" ]]; then
		log "[DRY-RUN] Link oluşturulacak: $target -> $source" "$GREEN"
	else
		ln -s "$source" "$target"
		log "Link oluşturuldu: $target -> $source" "$GREEN"
	fi
}

# Ana fonksiyon
main() {
	local DRY_RUN=false

	# Parametre kontrolü
	while [[ $# -gt 0 ]]; do
		case $1 in
		-l | --list)
			show_array
			show_links
			exit 0
			;;
		-d | --dry-run)
			DRY_RUN=true
			shift
			;;
		-h | --help)
			show_help
			exit 0
			;;
		*)
			log "Bilinmeyen parametre: $1" "$RED"
			show_help
			exit 1
			;;
		esac
	done

	if [[ "$DRY_RUN" == "true" ]]; then
		log "DRY RUN MODU - Herhangi bir değişiklik yapılmayacak" "$YELLOW"
	fi

	log "Sembolik link oluşturma işlemi başlıyor..." "$BLUE"

	# Kaynak dizin kontrolü
	check_source_dir

	# Her dizin için işlem
	for dir in "${DIRS[@]}"; do
		log "\nİşleniyor: $dir" "$BLUE"
		backup_dir "$dir"
		create_link "$dir" || log "Link oluşturulamadı: $dir" "$RED"
	done

	show_links
}

# Scripti çalıştır
main "$@"
