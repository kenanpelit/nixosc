#!/usr/bin/env bash
#===============================================================================
#
#   Script: OSC Lesson Playlist Generator
#   Version: 1.2.0
#   Date: 2025-03-10
#   Original Author: Kenan Pelit
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
#   - Progress feedback
#   - Multiple format support
#
#   License: MIT
#
#===============================================================================
## Örnekler:
## Sadece MP3'leri ekle
#./playlist.sh -f mp3 /muzik/klasorum
## Sıralı liste oluştur
#./playlist.sh -s -o siralimuzik.m3u /muzik/klasorum
## Sadece mevcut dizindeki dosyalar (özyinelemesiz)
#./playlist.sh -r false .
## Farklı formatları birlikte ekle
#./playlist.sh -f "mp3,ogg,flac" /muzik/klasorum
## Gruplamayı devre dışı bırak
#./playlist.sh -g false /muzik/klasorum

VERSION="1.2.0"

# Renkli çıktı için ANSI kodları
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'
BOLD='\033[1m'

# Başlık metni
print_header() {
	echo -e "${BLUE}${BOLD}Lesson Playlist Oluşturucu v${VERSION}${NC}"
	echo -e "${CYAN}$(date +"%Y-%m-%d %H:%M:%S")${NC}"
	echo
}

# Yardım metni
usage() {
	print_header
	echo "Ders dosyalarından başlıklı ve gruplu M3U playlist oluşturur."
	echo
	echo "Kullanım: $(basename "$0") [seçenekler] [dizin_yolu]"
	echo
	echo "Seçenekler:"
	echo "  -o, --output DOSYA     Çıktı dosyası adı (varsayılan: playlist.m3u)"
	echo "  -s, --sort             Dosyaları alfabetik sırala"
	echo "  -g, --group BOOLE      Dosyaları grupla ve başlık ekle (true/false, varsayılan: true)"
	echo "  -f, --format BİÇİM     Sadece belirtilen dosya formatını ekle (virgülle ayrılmış liste olabilir)"
	echo "  -r, --recursive BOOLE  Alt dizinleri tara (true/false, varsayılan: true)"
	echo "  -p, --prefix METİN     Tüm dosya yollarına önek ekle"
	echo "  -h, --help             Bu yardım mesajını göster"
	echo
	echo "Örnekler:"
	echo "  $(basename "$0") -f mp3 /muzik/klasorum      # Sadece MP3 dosyalarını ekle"
	echo "  $(basename "$0") -s -o muzik.m3u .           # Sıralı liste oluştur"
	echo "  $(basename "$0") -f \"mp3,ogg\" -g false .     # MP3 ve OGG dosyalarını ekle, gruplamadan"
	exit 1
}

# Hata mesajı
error() {
	echo -e "${RED}HATA: $1${NC}" >&2
	exit 1
}

# İlerleme göstergesi
show_progress() {
	local current="$1"
	local total="$2"
	local percent=$((current * 100 / total))
	local progress=$((current * 30 / total))

	echo -ne "\r["
	for ((i = 0; i < 30; i++)); do
		if [ $i -lt $progress ]; then
			echo -ne "="
		else
			echo -ne " "
		fi
	done
	echo -ne "] $percent% ($current/$total)"
}

# Varsayılan değerler
DIR="."
PLAYLIST="playlist.m3u"
SORT=false
GROUP=true
FORMAT="mp3"
RECURSIVE=true
PREFIX=""

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
		if [[ "$2" == "false" ]]; then
			GROUP=false
		else
			GROUP=true
		fi
		shift 2
		;;
	-f | --format)
		FORMAT="$2"
		shift 2
		;;
	-r | --recursive)
		if [[ "$2" == "false" ]]; then
			RECURSIVE=false
		else
			RECURSIVE=true
		fi
		shift 2
		;;
	-p | --prefix)
		PREFIX="$2"
		shift 2
		;;
	-h | --help)
		usage
		;;
	-*)
		error "Bilinmeyen seçenek: $1"
		;;
	*)
		DIR="$1"
		shift
		;;
	esac
done

# Dizin kontrolü
if [ ! -d "$DIR" ]; then
	error "Belirtilen dizin bulunamadı: $DIR"
fi

# Dizin yolunu tam yol olarak al
DIR=$(realpath "$DIR")

# Çıktı dosyası kontrolü
if [[ -f "$PLAYLIST" ]]; then
	echo -e "${YELLOW}Uyarı: $PLAYLIST dosyası zaten var ve üzerine yazılacak.${NC}"
	read -p "Devam etmek istiyor musunuz? (e/h): " confirm
	if [[ $confirm != [eE] ]]; then
		echo "İşlem iptal edildi."
		exit 0
	fi
fi

print_header
echo -e "${CYAN}Yapılandırma:${NC}"
echo "Dizin: $DIR"
echo "Playlist: $PLAYLIST"
echo "Format: $FORMAT"
echo "Sıralama: $SORT"
echo "Gruplama: $GROUP"
echo "Alt dizinler: $RECURSIVE"
if [ -n "$PREFIX" ]; then
	echo "Önek: $PREFIX"
fi
echo

# Playlist başlangıcı
echo "#EXTM3U" >"$PLAYLIST"
echo -e "${CYAN}Dosyalar taranıyor...${NC}"

# Format listesi oluştur
IFS=',' read -ra FORMAT_ARRAY <<<"$FORMAT"
FORMAT_PATTERN=$(
	IFS='|'
	echo "${FORMAT_ARRAY[*]}"
)

# Dosya bulma komutu
if [ "$RECURSIVE" = true ]; then
	find_cmd="find \"$DIR\" -type f"
else
	find_cmd="find \"$DIR\" -maxdepth 1 -type f"
fi

# Dosya formatı filtresi
find_cmd+=" -regextype posix-extended -regex \".*\\.($FORMAT_PATTERN)\$\""

# Dosyaları tara ve geçici bir dosyaya listeyi oluştur
temp_file=$(mktemp)
eval $find_cmd >"$temp_file"

# Toplam dosya sayısını al
total_files=$(wc -l <"$temp_file")

if [ "$total_files" -eq 0 ]; then
	rm "$temp_file"
	error "Belirtilen dizinde uygun dosya bulunamadı."
fi

echo -e "${GREEN}Toplam $total_files dosya bulundu.${NC}"

# Dosyaları sırala
if [ "$SORT" = true ]; then
	echo -e "${CYAN}Dosyalar sıralanıyor...${NC}"
	sort "$temp_file" -o "$temp_file"
fi

# Dosyaları işle
process_files() {
	local current_lesson=""
	local counter=0

	while IFS= read -r file; do
		((counter++))
		show_progress $counter $total_files

		# Ana dizin adını al
		main_dir=$(basename "$DIR")

		# Dizin yapısından ders başlığını çıkar
		lesson_dir=$(dirname "$file")
		lesson_name=$(basename "$lesson_dir" | sed -E 's/^[0-9]+_[0-9]+_//; s/-/ /g')

		# Yeni ders başladığında başlık ekle
		if [ "$GROUP" = true ] && [ "$current_lesson" != "$lesson_name" ]; then
			echo -e "\n#EXTINF:-1,=== $lesson_name ===" >>"$PLAYLIST"
			current_lesson="$lesson_name"
		fi

		# Dosya adını al
		file_basename=$(basename "$file")

		# Dosya tipini basit bir şekilde al (dosya adını kullan)
		file_type="${file_basename%.*}"

		# Tam dosya yolunu kullan - göreli yol yerine
		if [ -n "$PREFIX" ]; then
			# Önek varsa ekle
			relative_path="$PREFIX/$(realpath --relative-to="$DIR" "$file")"
		else
			# Tam mutlak yolu kullan
			relative_path="$file"
		fi

		echo "#EXTINF:-1,$file_type" >>"$PLAYLIST"
		echo "$relative_path" >>"$PLAYLIST"
	done <"$temp_file"

	echo -e "\n"
}

process_files

# Geçici dosyayı temizle
rm "$temp_file"

# Grupları say
if [ "$GROUP" = true ]; then
	lesson_count=$(grep -c "===" "$PLAYLIST")
else
	lesson_count="Gruplama devre dışı"
fi

# Dosya yollarını doğrula
echo -e "${CYAN}Dosya yolları kontrol ediliyor...${NC}"
invalid_paths=0
while IFS= read -r line; do
	# #EXTINF ile başlamayan ve boş olmayan satırları kontrol et
	if [[ ! "$line" =~ ^#EXTINF && -n "$line" && ! "$line" =~ ^#EXTM3U ]]; then
		if [ ! -f "$line" ]; then
			echo -e "${YELLOW}Uyarı: Dosya bulunamadı: $line${NC}"
			((invalid_paths++))
		fi
	fi
done <"$PLAYLIST"

# Sonuç bildirimi
song_count=$(grep -c -v "#EXT" "$PLAYLIST")
echo -e "${GREEN}${BOLD}Playlist oluşturuldu: $PLAYLIST${NC}"
echo -e "${GREEN}Toplam ders sayısı: $lesson_count${NC}"
echo -e "${GREEN}Toplam dosya sayısı: $song_count${NC}"

if [ $invalid_paths -gt 0 ]; then
	echo -e "${YELLOW}Uyarı: $invalid_paths dosya yolu bulunamadı.${NC}"
else
	echo -e "${GREEN}Tüm dosya yolları doğrulandı.${NC}"
fi

echo -e "${GREEN}İşlem tamamlandı.${NC}"
echo
echo -e "${CYAN}Nasıl çalıştırmalı:${NC}"
echo -e "  vlc \"$PLAYLIST\" --intf minimal"
echo -e "  cvlc \"$PLAYLIST\""
