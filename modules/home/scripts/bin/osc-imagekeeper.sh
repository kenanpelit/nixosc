#!/usr/bin/env bash

# ImageKeeper - Görsel Dosya Yönetim Aracı
# Bozuk ve duplicate görsel dosyaları tespit eder

# Renk tanımlamaları
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# Varsayılan değerler
SEARCH_PATH="."
DEBUG=0
VERBOSE=0

# Yardım fonksiyonu
show_help() {
	echo -e "${BOLD}ImageKeeper - Görsel Dosya Yönetim Aracı${NC}"
	echo ""
	echo "Kullanım: $0 [SEÇENEKLER]"
	echo ""
	echo "Seçenekler:"
	echo "  -p, --path PATH    Aranacak dizin yolu (varsayılan: mevcut dizin)"
	echo "  -d, --debug        Debug bilgileri göster"
	echo "  -v, --verbose      Detaylı çıktı"
	echo "  -h, --help         Bu yardım mesajını göster"
	echo ""
	echo "Özellikler:"
	echo "  • Bozuk görsel dosyalarını tespit eder ve silme seçeneği sunar"
	echo "  • Duplicate (kopya) görsel dosyalarını bulur ve temizleme imkanı verir"
	echo "  • PNG, JPG, JPEG formatlarını destekler"
	echo ""
}

# Parametre işleme
while [ "$1" != "" ]; do
	case $1 in
	-p | --path)
		shift
		SEARCH_PATH=$1
		;;
	-d | --debug)
		DEBUG=1
		;;
	-v | --verbose)
		VERBOSE=1
		;;
	-h | --help)
		show_help
		exit 0
		;;
	*)
		echo -e "${RED}Hata: Bilinmeyen parametre '$1'${NC}"
		show_help
		exit 1
		;;
	esac
	shift
done

# Dizin kontrolü
if [ ! -d "$SEARCH_PATH" ]; then
	echo -e "${RED}Hata: '$SEARCH_PATH' dizini bulunamadı${NC}"
	exit 1
fi

# Gerekli araçları kontrol et
check_dependencies() {
	if ! command -v identify &>/dev/null; then
		echo -e "${RED}Hata: ImageMagick (identify komutu) bulunamadı${NC}"
		echo "Lütfen ImageMagick'i yükleyin: apt-get install imagemagick veya brew install imagemagick"
		exit 1
	fi

	if ! command -v md5sum &>/dev/null; then
		echo -e "${RED}Hata: md5sum komutu bulunamadı${NC}"
		exit 1
	fi
}

# Bozuk dosyaları tespit et
check_corrupted_files() {
	echo -e "${BLUE}${BOLD}=== Bozuk Görsel Dosyaları Tespit Aracı ===${NC}"
	echo -e "Aranan dizin: ${CYAN}$SEARCH_PATH${NC}"
	echo ""

	local total=0
	local corrupted=0
	local deleted=0

	# Geçici dosya oluştur
	local temp_file=$(mktemp)

	[ $DEBUG -eq 1 ] && echo -e "${YELLOW}Debug: Geçici dosya oluşturuldu: $temp_file${NC}"

	# Görsel dosyaları bul
	find "$SEARCH_PATH" \( -iname "*.png" -o -iname "*.jpg" -o -iname "*.jpeg" \) -type f >"$temp_file"

	local total_files=$(wc -l <"$temp_file")
	echo -e "Bulunan görsel dosya sayısı: ${CYAN}$total_files${NC}"
	echo ""

	while IFS= read -r file; do
		((total++))

		if [ $VERBOSE -eq 1 ]; then
			echo -e "\n${YELLOW}[$total/$total_files] Kontrol ediliyor:${NC} $file"
		else
			printf "\r${YELLOW}İlerleme: %d/%d${NC}" "$total" "$total_files"
		fi

		# identify ile dosyayı kontrol et
		if ! identify "$file" &>/dev/null; then
			((corrupted++))
			echo -e "\n\n${RED}${BOLD}Bozuk dosya bulundu!${NC}"
			echo -e "Dosya: ${CYAN}$file${NC}"

			# Dosya boyutunu göster
			if [ -f "$file" ]; then
				local size=$(ls -lh "$file" | awk '{print $5}')
				echo -e "Boyut: $size"
			fi

			# Kullanıcıya sor
			echo -n "Bu dosyayı silmek istiyor musunuz? (e/h/q-çık): "
			read -n 1 -r reply
			echo ""

			case $reply in
			[Ee])
				if rm "$file" 2>/dev/null; then
					((deleted++))
					echo -e "${GREEN}✓ Dosya silindi${NC}"
				else
					echo -e "${RED}✗ Dosya silinirken hata oluştu${NC}"
				fi
				;;
			[Qq])
				echo -e "${YELLOW}İşlem iptal edildi${NC}"
				break
				;;
			*)
				echo -e "${YELLOW}Dosya atlandı${NC}"
				;;
			esac
		fi
	done <"$temp_file"

	# Temizlik
	rm "$temp_file"

	# İstatistikleri göster
	echo -e "\n\n${BLUE}${BOLD}=== Bozuk Dosya Kontrolü Tamamlandı ===${NC}"
	echo -e "Toplam kontrol edilen: ${CYAN}$total${NC} dosya"
	echo -e "Bozuk bulunan: ${RED}$corrupted${NC} dosya"
	echo -e "Silinen: ${GREEN}$deleted${NC} dosya"
}

# Duplicate dosyaları bul
find_duplicate_files() {
	echo -e "${BLUE}${BOLD}=== Duplicate Görsel Dosyaları Tespit Aracı ===${NC}"
	echo -e "Aranan dizin: ${CYAN}$SEARCH_PATH${NC}"
	echo ""

	local temp_file=$(mktemp)
	local found_duplicates=0
	local deleted_duplicates=0

	[ $DEBUG -eq 1 ] && echo -e "${YELLOW}Debug: Geçici dosya: $temp_file${NC}"

	# Tüm görüntü dosyalarını bul ve hash hesapla
	if [ $VERBOSE -eq 1 ]; then
		echo "Görüntü dosyaları aranıyor ve hash değerleri hesaplanıyor..."
	fi

	local file_count=0
	find "$SEARCH_PATH" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \) | while read -r file; do
		((file_count++))
		if [ $VERBOSE -eq 1 ]; then
			echo -e "${YELLOW}İşleniyor [$file_count]:${NC} $file"
			echo "  Dosya boyutu: $(stat -c %s "$file" 2>/dev/null || stat -f %z "$file" 2>/dev/null) bytes"
		else
			printf "\r${YELLOW}Hash hesaplanıyor: %d dosya${NC}" "$file_count"
		fi
		md5sum "$file" 2>/dev/null
	done | sort >"$temp_file"

	echo ""
	local total_files=$(wc -l <"$temp_file")
	echo -e "Toplam dosya sayısı: ${CYAN}$total_files${NC}"

	if [ $total_files -eq 0 ]; then
		echo -e "${YELLOW}Hiç görsel dosya bulunamadı${NC}"
		rm "$temp_file"
		return
	fi

	# Duplicate'leri bul
	declare -A seen
	while IFS=' ' read -r hash file; do
		if [ -n "${seen[$hash]}" ]; then
			found_duplicates=1
			echo -e "\n${RED}${BOLD}Duplicate dosyalar bulundu:${NC}"
			echo -e "${GREEN}Orijinal:${NC} ${seen[$hash]}"
			echo -e "${YELLOW}Kopya   :${NC} $file"

			if [ $VERBOSE -eq 1 ]; then
				echo -e "MD5 hash: $hash"
				echo -e "Orijinal boyut: $(stat -c %s "${seen[$hash]}" 2>/dev/null || stat -f %z "${seen[$hash]}" 2>/dev/null) bytes"
				echo -e "Kopya boyut   : $(stat -c %s "$file" 2>/dev/null || stat -f %z "$file" 2>/dev/null) bytes"
			fi

			echo -n "Kopya dosyayı silmek istiyor musunuz? (e/h/q-çık): "
			read -n 1 -r answer
			echo ""

			case $answer in
			[Ee])
				if rm "$file" 2>/dev/null; then
					((deleted_duplicates++))
					echo -e "${GREEN}✓ Kopya dosya silindi${NC}"
				else
					echo -e "${RED}✗ Dosya silinirken hata oluştu${NC}"
				fi
				;;
			[Qq])
				echo -e "${YELLOW}İşlem iptal edildi${NC}"
				break
				;;
			*)
				echo -e "${YELLOW}Dosya atlandı${NC}"
				;;
			esac
		else
			seen[$hash]="$file"
		fi
	done <"$temp_file"

	# Temizlik
	[ $DEBUG -eq 1 ] && echo -e "${YELLOW}Debug: Geçici dosya siliniyor: $temp_file${NC}"
	rm "$temp_file"

	# Sonuçları göster
	echo -e "\n${BLUE}${BOLD}=== Duplicate Kontrolü Tamamlandı ===${NC}"
	if [ $found_duplicates -eq 0 ]; then
		echo -e "${GREEN}✓ Duplicate dosya bulunamadı${NC}"
	else
		echo -e "Silinen duplicate dosya: ${GREEN}$deleted_duplicates${NC}"
	fi
}

# Ana menü
show_menu() {
	echo -e "${BOLD}${BLUE}"
	echo "╔══════════════════════════════════════╗"
	echo "║            ImageKeeper               ║"
	echo "║      Görsel Dosya Yönetim Aracı     ║"
	echo "╚══════════════════════════════════════╝"
	echo -e "${NC}"
	echo "Ne yapmak istiyorsunuz?"
	echo ""
	echo -e "${CYAN}1.${NC} Bozuk görsel dosyalarını tespit et"
	echo -e "${CYAN}2.${NC} Duplicate görsel dosyalarını bul"
	echo -e "${CYAN}3.${NC} Her ikisini de çalıştır (önce bozuk, sonra duplicate)"
	echo -e "${CYAN}q.${NC} Çıkış"
	echo ""
	echo -e "Seçiminiz: "
}

# Gerekli araçları kontrol et
check_dependencies

# Ana program
echo -e "Çalışma dizini: ${CYAN}$(realpath "$SEARCH_PATH")${NC}"
[ $DEBUG -eq 1 ] && echo -e "${YELLOW}Debug modu aktif${NC}"
[ $VERBOSE -eq 1 ] && echo -e "${YELLOW}Verbose modu aktif${NC}"
echo ""

while true; do
	show_menu
	read -n 1 -r choice
	echo ""

	case $choice in
	1)
		echo ""
		check_corrupted_files
		echo ""
		echo -e "${YELLOW}Devam etmek için Enter'a basın...${NC}"
		read
		;;
	2)
		echo ""
		find_duplicate_files
		echo ""
		echo -e "${YELLOW}Devam etmek için Enter'a basın...${NC}"
		read
		;;
	3)
		echo ""
		check_corrupted_files
		echo ""
		echo -e "${YELLOW}Şimdi duplicate kontrolüne geçiliyor...${NC}"
		echo -e "${YELLOW}Devam etmek için Enter'a basın...${NC}"
		read
		echo ""
		find_duplicate_files
		echo ""
		echo -e "${YELLOW}Devam etmek için Enter'a basın...${NC}"
		read
		;;
	[Qq])
		echo -e "${GREEN}ImageKeeper'dan çıkılıyor. İyi günler!${NC}"
		exit 0
		;;
	*)
		echo -e "${RED}Geçersiz seçim. Lütfen 1, 2, 3 veya q seçin.${NC}"
		;;
	esac
done
