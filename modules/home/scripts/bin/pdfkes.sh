#!/usr/bin/env bash
#===============================================================================
#
#   Script: OSC PDF Splitter
#   Version: 2.0.0
#   Date: 2024-01-23
#   Author: Kenan Pelit
#   Repository: https://github.com/kenanpelit/nixosc
#   Description: Advanced PDF file management and splitting utility with
#                interactive TUI interface and batch processing capabilities
#
#   Features:
#   - Interactive TUI with beautiful styling
#   - Multiple splitting modes (chunk, range, custom)
#   - Detailed PDF metadata viewing
#   - Batch processing via command line
#   - Robust error handling and validation
#   - Progress tracking and colorful output
#
#   License: MIT
#
#===============================================================================

# Renk tanımlamaları
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
GRAY='\033[0;90m'
WHITE='\033[1;37m'
BOLD='\033[1m'
NC='\033[0m'

# Varsayılan değerler
DEFAULT_OUTPUT_DIR="bolunmus"
VERSION="2.0.0"

# ASCII Logo ve Program Başlığı
show_logo() {
	clear
	echo -e "${BLUE}"
	echo '    ____  ____  ______   _____       _ _ __  __            '
	echo '   / __ \/ __ \/ ____/  / ___/____  / (_) /_/ /____  _____ '
	echo '  / /_/ / / / / /_      \__ \/ __ \/ / / __/ __/ _ \/ ___/ '
	echo ' / ____/ /_/ / __/     ___/ / /_/ / / / /_/ /_/  __/ /     '
	echo '/_/    \____/_/       /____/ .___/_/_/\__/\__/\___/_/      '
	echo '                          /_/                               '
	echo -e "${NC}"
	echo -e "${GRAY}PDF Dosya Bölme ve Yönetim Aracı - v${VERSION}${NC}"
	echo
}

# Hata yönetimi
error_exit() {
	echo -e "${RED}✘ Hata: $1${NC}" >&2
	exit 1
}

# Başarı mesajı
success_msg() {
	echo -e "${GREEN}✔ $1${NC}"
}

# Bilgi mesajı
info_msg() {
	echo -e "${CYAN}ℹ $1${NC}"
}

# Uyarı mesajı
warning_msg() {
	echo -e "${YELLOW}⚠ $1${NC}"
}

# Gerekli komut kontrolü
check_requirements() {
	if ! command -v pdftk &>/dev/null; then
		error_exit "pdftk komutu bulunamadı. Lütfen önce pdftk'yı yükleyin."
	fi
}

# PDF dosya kontrolü
validate_pdf() {
	local file="$1"
	if [ ! -f "$file" ]; then
		error_exit "PDF dosyası bulunamadı: $file"
	fi
	if ! pdftk "$file" dump_data &>/dev/null; then
		error_exit "Geçersiz PDF dosyası: $file"
	fi
}

# Dizin oluşturma
ensure_directory() {
	if [ ! -d "$1" ]; then
		mkdir -p "$1" || error_exit "Dizin oluşturulamadı: $1"
	fi
}

# PDF sayfa sayısını al
get_total_pages() {
	pdftk "$1" dump_data | grep NumberOfPages | awk '{print $2}'
}

# Menü başlığı göster
show_menu_header() {
	local pdf_file=$1
	local total_pages=$2
	local width=65
	local line=$(printf '%*s' "$width" | tr ' ' '─')

	echo -e "${BLUE}┌${line}┐${NC}"
	echo -e "${BLUE}│${NC}${BOLD} PDF İŞLEM MENÜSÜ$(printf '%*s' $((width - 16)) ' ')${BLUE}│${NC}"
	echo -e "${BLUE}├${line}┤${NC}"
	echo -e "${BLUE}│${NC} Dosya    : ${GREEN}$(basename "$pdf_file")${NC}"
	echo -e "${BLUE}│${NC} Boyut    : ${YELLOW}$(du -h "$pdf_file" | cut -f1)${NC}"
	echo -e "${BLUE}│${NC} Sayfalar : ${YELLOW}${total_pages} sayfa${NC}"
	echo -e "${BLUE}└${line}┘${NC}"
	echo
}

# İşlem başlığı göster (section header için de aynı düzeltme)
show_section_header() {
	local title="$1"
	local width=45
	local line=$(printf '%*s' "$width" | tr ' ' '─')

	echo
	echo -e "${BLUE}┌${line}┐${NC}"
	echo -e "${BLUE}│${NC} $title$(printf '%*s' $((width - ${#title} - 1)) ' ')${BLUE}│${NC}"
	echo -e "${BLUE}└${line}┘${NC}"
	echo
}

# Ana menü seçenekleri
show_menu_options() {
	echo -e "${CYAN}Kullanılabilir İşlemler:${NC}"
	echo
	echo -e "${WHITE}1)${NC} Eşit Parçalara Böl ${GRAY}(Chunk Modu)${NC}"
	echo -e "   └─ PDF'i belirtilen sayfa sayısına göre eşit parçalara böler"
	echo
	echo -e "${WHITE}2)${NC} Sayfa Aralığı Al ${GRAY}(Range Modu)${NC}"
	echo -e "   └─ PDF'ten belirli sayfa aralığını yeni dosyaya aktarır"
	echo
	echo -e "${WHITE}3)${NC} Özel Bölme ${GRAY}(Manuel Mod)${NC}"
	echo -e "   └─ Birden fazla sayfa aralığını ayrı ayrı böler"
	echo
	echo -e "${WHITE}4)${NC} PDF Bilgileri ${GRAY}(Metadata)${NC}"
	echo -e "   └─ PDF dosyasının detaylı bilgilerini gösterir"
	echo
	echo -e "${WHITE}q)${NC} Çıkış"
	echo
}

# Sayfa aralığı kontrolü
validate_range() {
	local start=$1
	local end=$2
	local total=$3

	if [[ ! $start =~ ^[0-9]+$ ]] || [[ ! $end =~ ^[0-9]+$ ]]; then
		return 1
	fi

	if [ $start -lt 1 ] || [ $start -gt $total ] ||
		[ $end -lt $start ] || [ $end -gt $total ]; then
		return 1
	fi
	return 0
}

# PDF bölme işlemi - Range modu
split_range() {
	local input=$1
	local range=$2
	local output_dir=$3
	local prefix=$4

	local output_file="${output_dir}/${prefix}_${range}.pdf"
	info_msg "Bölünüyor: ${range} → $(basename "$output_file")"

	if pdftk "$input" cat $range output "$output_file" 2>/dev/null; then
		success_msg "Dosya oluşturuldu: $(basename "$output_file")"
	else
		error_exit "PDF bölme işlemi başarısız oldu"
	fi
}

# PDF bölme işlemi - Chunk modu
split_chunks() {
	local input=$1
	local chunk_size=$2
	local prefix=$3
	local output_dir=$4
	local total_pages=$5

	local chunk_count=$(((total_pages + chunk_size - 1) / chunk_size))
	info_msg "Toplam ${chunk_count} parça oluşturulacak..."

	for ((i = 1; i <= chunk_count; i++)); do
		local start=$(((i - 1) * chunk_size + 1))
		local end=$((i * chunk_size))
		[ $end -gt $total_pages ] && end=$total_pages

		echo -e "${GRAY}İşleniyor: $i/$chunk_count ${NC}"
		split_range "$input" "$start-$end" "$output_dir" "${prefix}_bolum$i"
	done

	success_msg "Tüm parçalar oluşturuldu"
}

# Chunk modu işlemi
process_chunk_mode() {
	local pdf_file=$1
	local total_pages=$2

	show_section_header "Eşit Parçalara Bölme İşlemi"

	echo -e "${CYAN}PDF Bilgileri:${NC}"
	echo -e "• Toplam Sayfa: ${YELLOW}$total_pages${NC}"
	echo -e "• Önerilen Bölme Sayıları: ${GRAY}5, 7, 10, 15, 20, 25, 30${NC}"
	echo

	read -p "$(echo -e "${WHITE}Her parça kaç sayfa olsun?: ${NC}")" chunk_size

	if [[ ! $chunk_size =~ ^[0-9]+$ ]] || [ $chunk_size -lt 1 ]; then
		warning_msg "Geçersiz sayfa sayısı!"
		return 1
	fi

	read -p "$(echo -e "${WHITE}Çıktı dosyaları için ön ek: ${NC}")" prefix

	ensure_directory "$DEFAULT_OUTPUT_DIR"
	split_chunks "$pdf_file" "$chunk_size" "$prefix" "$DEFAULT_OUTPUT_DIR" "$total_pages"
}

# Range modu işlemi
process_range_mode() {
	local pdf_file=$1
	local total_pages=$2

	show_section_header "Sayfa Aralığı Seçme İşlemi"

	echo -e "${CYAN}PDF Bilgileri:${NC}"
	echo -e "• Toplam Sayfa: ${YELLOW}$total_pages${NC}"
	echo

	read -p "$(echo -e "${WHITE}Başlangıç sayfası: ${NC}")" start_page
	read -p "$(echo -e "${WHITE}Bitiş sayfası: ${NC}")" end_page

	if ! validate_range "$start_page" "$end_page" "$total_pages"; then
		warning_msg "Geçersiz sayfa aralığı! (1-$total_pages arası olmalı)"
		return 1
	fi

	read -p "$(echo -e "${WHITE}Çıktı dosyası için ön ek: ${NC}")" prefix

	ensure_directory "$DEFAULT_OUTPUT_DIR"
	split_range "$pdf_file" "$start_page-$end_page" "$DEFAULT_OUTPUT_DIR" "$prefix"
}

# Özel bölme modu işlemi
process_custom_mode() {
	local pdf_file=$1
	local total_pages=$2

	show_section_header "Özel Bölme İşlemi"

	echo -e "${CYAN}PDF Bilgileri:${NC}"
	echo -e "• Toplam Sayfa: ${YELLOW}$total_pages${NC}"
	echo
	echo -e "${WHITE}Her satıra bir aralık girin (örn: 1-10).${NC}"
	echo -e "${GRAY}Bitirmek için 'q' yazın.${NC}"
	echo

	ensure_directory "$DEFAULT_OUTPUT_DIR"

	while true; do
		read -p "$(echo -e "${WHITE}Sayfa aralığı (veya q): ${NC}")" range

		[ "$range" = "q" ] && break

		if [[ $range =~ ^([0-9]+)-([0-9]+)$ ]]; then
			local start="${BASH_REMATCH[1]}"
			local end="${BASH_REMATCH[2]}"

			if validate_range "$start" "$end" "$total_pages"; then
				read -p "$(echo -e "${WHITE}Bu bölüm için dosya adı: ${NC}")" prefix
				split_range "$pdf_file" "$range" "$DEFAULT_OUTPUT_DIR" "$prefix"
			else
				warning_msg "Geçersiz aralık! (1-$total_pages arası olmalı)"
			fi
		else
			warning_msg "Geçersiz format! Örnek: 1-10"
		fi
	done
}

# Metadata görüntüleme işlemi
show_metadata() {
	local pdf_file=$1

	show_section_header "PDF Dosya Bilgileri"

	local metadata=$(pdftk "$pdf_file" dump_data)

	echo -e "${CYAN}Temel Bilgiler:${NC}"
	echo -e "• Dosya: ${YELLOW}$(basename "$pdf_file")${NC}"
	echo -e "• Boyut: ${YELLOW}$(du -h "$pdf_file" | cut -f1)${NC}"
	echo -e "• Sayfalar: ${YELLOW}$(echo "$metadata" | grep NumberOfPages | awk '{print $2}')${NC}"
	echo

	echo -e "${CYAN}Metadata Bilgileri:${NC}"
	echo "$metadata" | grep -E "^(Info|Title|Author|Subject|Producer|Creator)" | while read -r line; do
		local key=$(echo "$line" | cut -d: -f1)
		local value=$(echo "$line" | cut -d: -f2-)
		echo -e "• ${WHITE}${key}:${NC}${value}"
	done

	echo
	read -p "$(echo -e "${GRAY}Devam etmek için Enter'a basın...${NC}")"
}

# Ana menü
show_main_menu() {
	local pdf_file=$1
	local total_pages=$(get_total_pages "$pdf_file")

	while true; do
		show_logo
		show_menu_header "$pdf_file" "$total_pages"
		show_menu_options

		read -p "$(echo -e "${WHITE}Seçiminiz: ${NC}")" choice

		case $choice in
		1) process_chunk_mode "$pdf_file" "$total_pages" ;;
		2) process_range_mode "$pdf_file" "$total_pages" ;;
		3) process_custom_mode "$pdf_file" "$total_pages" ;;
		4) show_metadata "$pdf_file" ;;
		q | Q)
			success_msg "Program sonlandırılıyor..."
			exit 0
			;;
		*)
			warning_msg "Geçersiz seçim!"
			sleep 1
			;;
		esac
	done
}

# Yardım mesajını göster
show_help() {
	echo -e "${BLUE}PDF Splitter - PDF Dosya Bölme Aracı${NC}"
	echo
	echo "Kullanım:"
	echo -e "  ${WHITE}$0 <pdf_dosyası>${NC}         : İnteraktif mod"
	echo -e "  ${WHITE}$0 [seçenekler] <pdf>${NC}    : Komut satırı modu"
	echo
	echo "Seçenekler:"
	echo -e "  ${WHITE}-m, --mode${NC} <mod>         Bölme modu (chunk|range|custom)"
	echo -e "  ${WHITE}-s, --size${NC} <sayı>        Chunk modunda sayfa sayısı"
	echo -e "  ${WHITE}-r, --range${NC} <x-y>        Range modunda sayfa aralığı"
	echo -e "  ${WHITE}-p, --prefix${NC} <metin>     Çıktı dosya ön eki"
	echo -e "  ${WHITE}-o, --output${NC} <dizin>     Çıktı dizini"
	echo -e "  ${WHITE}-h, --help${NC}               Bu yardım mesajını göster"
	echo
	echo "Örnekler:"
	echo -e "  ${GRAY}# İnteraktif mod${NC}"
	echo -e "  $0 belge.pdf"
	echo
	echo -e "  ${GRAY}# 7'şer sayfalık parçalara böl${NC}"
	echo -e "  $0 -m chunk -s 7 -p bolum belge.pdf"
	echo
	echo -e "  ${GRAY}# Belirli sayfa aralığını al${NC}"
	echo -e "  $0 -m range -r 1-10 -p ilk_bolum belge.pdf"
}

# Komut satırı modu işlemi
process_commandline() {
	local MODE=""
	local CHUNK_SIZE=""
	local RANGE=""
	local PREFIX="bolum"
	local OUTPUT_DIR="$DEFAULT_OUTPUT_DIR"
	local INPUT_FILE=""

	while [[ $# -gt 0 ]]; do
		case $1 in
		-m | --mode)
			MODE="$2"
			shift 2
			;;
		-s | --size)
			CHUNK_SIZE="$2"
			shift 2
			;;
		-r | --range)
			RANGE="$2"
			shift 2
			;;
		-p | --prefix)
			PREFIX="$2"
			shift 2
			;;
		-o | --output)
			OUTPUT_DIR="$2"
			shift 2
			;;
		-h | --help)
			show_help
			exit 0
			;;
		*.pdf)
			INPUT_FILE="$1"
			shift
			;;
		*)
			error_exit "Bilinmeyen parametre: $1"
			;;
		esac
	done

	# PDF dosya kontrolü
	[ -z "$INPUT_FILE" ] && error_exit "PDF dosyası belirtilmedi"
	validate_pdf "$INPUT_FILE"

	# Çıktı dizinini oluştur
	ensure_directory "$OUTPUT_DIR"

	# Moda göre işlem yap
	local total_pages=$(get_total_pages "$INPUT_FILE")

	case $MODE in
	chunk)
		[ -z "$CHUNK_SIZE" ] && error_exit "Chunk modu için -s|--size gerekli"
		split_chunks "$INPUT_FILE" "$CHUNK_SIZE" "$PREFIX" "$OUTPUT_DIR" "$total_pages"
		;;
	range)
		[ -z "$RANGE" ] && error_exit "Range modu için -r|--range gerekli"
		if [[ $RANGE =~ ^([0-9]+)-([0-9]+)$ ]]; then
			local start="${BASH_REMATCH[1]}"
			local end="${BASH_REMATCH[2]}"
			if validate_range "$start" "$end" "$total_pages"; then
				split_range "$INPUT_FILE" "$RANGE" "$OUTPUT_DIR" "$PREFIX"
			else
				error_exit "Geçersiz sayfa aralığı: $RANGE (Toplam: $total_pages sayfa)"
			fi
		else
			error_exit "Geçersiz range formatı. Örnek: 1-10"
		fi
		;;
	custom)
		process_custom_mode "$INPUT_FILE" "$total_pages"
		;;
	*)
		error_exit "Geçersiz mod. Kullanılabilir modlar: chunk, range, custom"
		;;
	esac
}

# Ana program
main() {
	# Gereksinimleri kontrol et
	check_requirements

	# Parametre kontrolü
	if [ $# -eq 0 ]; then
		error_exit "Kullanım: $0 <pdf_dosyası> veya $0 --help"
	fi

	# Yardım kontrolü
	if [ "$1" == "-h" ] || [ "$1" == "--help" ]; then
		show_help
		exit 0
	fi

	# PDF dosyası ve interaktif mod kontrolü
	if [ $# -eq 1 ] && [[ $1 == *.pdf ]]; then
		validate_pdf "$1"
		show_main_menu "$1"
	else
		process_commandline "$@"
	fi
}

# Programı başlat
main "$@"
