#!/usr/bin/env bash
#===============================================================================
#
#   Script: OSC Subliminal Subtitle Downloader
#   Version: 1.0.0
#   Date: 2024-01-23
#   Author: Kenan Pelit
#   Repository: https://github.com/kenanpelit/nixosc
#   Description: An automated subtitle downloader using Subliminal for video files,
#                supporting multiple languages and batch processing
#
#   Features:
#   - Downloads subtitles for individual video files or entire directories
#   - Supports multiple languages (default: English and Turkish)
#   - Force download option to update existing subtitles
#   - Color-coded output for better readability
#   - Smart video file type detection
#
#   License: MIT
#
#===============================================================================

# Renkli çıktı için
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Varsayılan diller
LANGUAGES=("eng" "tur")

# Kullanım fonksiyonu
usage() {
	echo -e "${YELLOW}Kullanım:${NC}"
	echo -e "  $0 [seçenekler] <dosya_veya_klasör>"
	echo -e "\n${YELLOW}Seçenekler:${NC}"
	echo "  -h, --help          Bu yardım mesajını gösterir"
	echo "  -l, --languages     İndirilecek dilleri belirtir (varsayılan: eng,tur)"
	echo "  -f, --force         Mevcut altyazıları yeniden indirir"
	echo -e "\n${YELLOW}Örnekler:${NC}"
	echo "  $0 movie.mkv"
	echo "  $0 -l eng,fra movie.mkv"
	echo "  $0 /path/to/movies/"
	exit 1
}

# Hata fonksiyonu
error() {
	echo -e "${RED}Hata:${NC} $1" >&2
	exit 1
}

# Video dosyası kontrolü
is_video() {
	local file=$1
	local ext="${file##*.}"
	local video_extensions=("mkv" "mp4" "m4v" "avi" "mov" "wmv")

	for valid_ext in "${video_extensions[@]}"; do
		if [[ "${ext,,}" == "${valid_ext}" ]]; then
			return 0
		fi
	done
	return 1
}

# Altyazı indirme fonksiyonu
download_subtitles() {
	local target=$1
	local force=$2
	local lang_param=""

	# Dil parametrelerini oluştur
	for lang in "${LANGUAGES[@]}"; do
		lang_param="$lang_param -l $lang"
	done

	if [ -f "$target" ]; then
		if is_video "$target"; then
			echo -e "${GREEN}İndiriliyor:${NC} $target"
			if [ "$force" = true ]; then
				subliminal download $lang_param --force "$target"
			else
				subliminal download $lang_param "$target"
			fi
		fi
	elif [ -d "$target" ]; then
		echo -e "${GREEN}Klasör taranıyor:${NC} $target"
		find "$target" -type f | while read -r file; do
			if is_video "$file"; then
				echo -e "${GREEN}İndiriliyor:${NC} $file"
				if [ "$force" = true ]; then
					subliminal download $lang_param --force "$file"
				else
					subliminal download $lang_param "$file"
				fi
			fi
		done
	else
		error "Geçersiz dosya veya klasör: $target"
	fi
}

# Ana program
main() {
	local force=false
	local target=""

	# Parametre kontrolü
	while [[ $# -gt 0 ]]; do
		case $1 in
		-h | --help)
			usage
			;;
		-l | --languages)
			if [ -z "$2" ]; then
				error "Dil parametresi eksik"
			fi
			IFS=',' read -ra LANGUAGES <<<"$2"
			shift 2
			;;
		-f | --force)
			force=true
			shift
			;;
		*)
			if [ -z "$target" ]; then
				target="$1"
			else
				error "Birden fazla hedef belirtilemez"
			fi
			shift
			;;
		esac
	done

	# Hedef kontrolü
	if [ -z "$target" ]; then
		error "Dosya veya klasör belirtilmedi"
	fi

	# Altyazıları indir
	download_subtitles "$target" "$force"
}

# Programı çalıştır
main "$@"
