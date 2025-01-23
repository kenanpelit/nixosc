#!/usr/bin/env bash
#===============================================================================
#
#   Script: OSC Lesson Playlist Generator
#   Version: 1.1.0
#   Date: 2024-01-23
#   Author: Kenan Pelit
#   Repository: https://github.com/kenanpelit/nixosc
#   Description: M3U playlist generator for lesson audio files with grouping
#                and formatting support for educational content
#
#   Features:
#   - Smart lesson grouping and titling
#   - Multiple audio format support
#   - Relative path handling
#   - Custom playlist naming
#   - Sorting capabilities
#   - Detailed file counting
#
#   License: MIT
#
#===============================================================================

## Sadece MP3'leri ekle
#./playlist.sh -f mp3 /muzik/klasorum
## Sıralı liste oluştur
#./playlist.sh -s -o siralimuzik.m3u /muzik/klasorum
## Sadece mevcut dizindeki dosyalar
#./playlist.sh --recursive false .

VERSION="1.1"

# Renkli çıktı için ANSI kodları
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

usage() {
	echo -e "${BLUE}Lesson Playlist Oluşturucu v${VERSION}${NC}"
	echo "Ders dosyalarından başlıklı ve gruplu M3U playlist oluşturur."
	echo
	echo "Kullanım: $(basename "$0") [seçenekler] [dizin_yolu]"
	echo
	echo "Seçenekler:"
	echo "  -o, --output DOSYA     Çıktı dosyası adı (varsayılan: playlist.m3u)"
	echo "  -s, --sort             Dosyaları alfabetik sırala"
	echo "  -g, --group            Dosyaları grupla ve başlık ekle"
	echo "  -f, --format BİÇİM     Sadece belirtilen dosya formatını ekle"
	echo "  -h, --help             Bu yardım mesajını göster"
	exit 1
}

# Varsayılan değerler
DIR="."
PLAYLIST="playlist.m3u"
SORT=false
GROUP=true
FORMAT="mp3"

# Parametre işleme
while [[ $# -gt 0 ]]; do
	case $1 in
	-o | --output)
		PLAYLIST="$2"
		shift 2
		;;
	-s | --sort)
		SORT=true
		shift
		;;
	-g | --group)
		GROUP=true
		shift
		;;
	-f | --format)
		FORMAT="$2"
		shift 2
		;;
	-h | --help)
		usage
		;;
	*)
		DIR="$1"
		shift
		;;
	esac
done

# Dizin yolunu tam yol olarak al
DIR=$(realpath "$DIR")

# Playlist başlangıcı
echo "#EXTM3U" >"$PLAYLIST"

# Dosyaları topla ve grupla
process_files() {
	local current_lesson=""

	while IFS= read -r -d $'\0' file; do
		# Ana dizin adını al
		main_dir=$(basename "$DIR")

		# Dizin yapısından ders başlığını çıkar
		lesson_dir=$(dirname "$file")
		lesson_name=$(basename "$lesson_dir" | sed -E 's/^[0-9]+_[0-9]+_//; s/-/ /g')

		# Yeni ders başladığında başlık ekle
		if [ "$current_lesson" != "$lesson_name" ]; then
			echo -e "\n#EXTINF:-1,=== $lesson_name ===" >>"$PLAYLIST"
			current_lesson="$lesson_name"
		fi

		# Dosya tipini belirle (fast/normal/slow)
		file_type=$(basename "$file" | sed -E 's/.*\.(fast|normal|slow)\.mp3/\1/')

		# Göreceli yolu ana dizinden başlayarak oluştur
		relative_path="$main_dir/$(realpath --relative-to="$DIR" "$file")"
		echo "#EXTINF:-1,$file_type" >>"$PLAYLIST"
		echo "$relative_path" >>"$PLAYLIST"
	done
}

if [ "$SORT" = true ]; then
	find "$DIR" -type f -name "*.$FORMAT" -print0 | sort -z | process_files
else
	find "$DIR" -type f -name "*.$FORMAT" -print0 | process_files
fi

# Sonuç bildirimi
TOTAL_SONGS=$(grep -v "#EXT" "$PLAYLIST" | wc -l)
echo -e "${GREEN}Playlist oluşturuldu: $PLAYLIST${NC}"
echo -e "${GREEN}Toplam ders sayısı: $(grep "===" "$PLAYLIST" | wc -l)${NC}"
echo -e "${GREEN}Toplam dosya sayısı: $TOTAL_SONGS${NC}"
