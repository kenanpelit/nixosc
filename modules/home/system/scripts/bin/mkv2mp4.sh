#!/usr/bin/env bash

# Renkler
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# ffmpeg kontrolü
if ! command -v ffmpeg &>/dev/null; then
	echo -e "${RED}ffmpeg bulunamadı! Lütfen ffmpeg'i yükleyin:${NC}"
	echo "sudo pacman -S ffmpeg"
	exit 1
fi

# CPU çekirdek sayısını al
THREADS=$(nproc)

# Kullanım kontrolü
if [ $# -eq 0 ]; then
	echo -e "${RED}Kullanım: $0 <dizin>${NC}"
	exit 1
fi

# İlerleme çubuğu fonksiyonu
show_progress() {
	local duration=$1
	local current_time=$2
	local progress=$((current_time * 100 / duration))
	printf "\rİlerleme: %d%%" "$progress"
}

# MKV'den MP4'e dönüştürme fonksiyonu
convert_mkv() {
	local input_file="$1"
	local output_file="${input_file%.mkv}.mp4"

	echo -e "${YELLOW}----------------------------------------"
	echo "Dönüştürülüyor: $input_file"
	echo -e "----------------------------------------${NC}"

	# Video süresini al (saniye olarak)
	duration=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$input_file")
	duration=${duration%.*}

	# Video bilgilerini al
	local video_info=$(ffprobe -v error -select_streams v:0 -show_entries stream=width,height,r_frame_rate -of csv=p=0 "$input_file")
	IFS=',' read -r width height frame_rate <<<"$video_info"

	echo -e "${BLUE}Çözünürlük: ${width}x${height}${NC}"

	ffmpeg -i "$input_file" \
		-c:v libx264 \
		-preset ultrafast \
		-crf 25 \
		-c:a aac \
		-b:a 128k \
		-threads $THREADS \
		-movflags +faststart \
		-progress - \
		"$output_file" 2>/dev/null |
		while read -r line; do
			if [[ $line =~ out_time=([0-9:.]+) ]]; then
				time="${BASH_REMATCH[1]}"
				current_seconds=$(echo "$time" | awk -F: '{ print ($1 * 3600) + ($2 * 60) + $3 }')
				show_progress "$duration" "${current_seconds%.*}"
			fi
		done

	if [ -f "$output_file" ]; then
		echo -e "\n${GREEN}Dönüştürme başarılı: $output_file${NC}"

		# Orijinal ve yeni dosya boyutlarını göster
		original_size=$(du -h "$input_file" | cut -f1)
		new_size=$(du -h "$output_file" | cut -f1)
		echo -e "${YELLOW}Orijinal Boyut: $original_size"
		echo -e "Yeni Boyut: $new_size${NC}"

		# Kullanıcıya sor
		echo -e "\nOrijinal MKV dosyası silinsin mi?"
		echo "1) Evet, sil"
		echo "2) Hayır, sakla"
		read -p "Seçiminiz (1/2): " choice

		case $choice in
		1)
			rm "$input_file"
			echo -e "${RED}Orijinal dosya silindi: $input_file${NC}"
			;;
		2)
			echo -e "${GREEN}Orijinal dosya saklandı: $input_file${NC}"
			;;
		*)
			echo -e "${YELLOW}Geçersiz seçim. Orijinal dosya saklandı.${NC}"
			;;
		esac
	else
		echo -e "\n${RED}Dönüştürme başarısız: $input_file${NC}"
	fi
	echo ""
}

# Ana işlem
if [ -d "$1" ]; then
	echo -e "${YELLOW}Dizin taranıyor: $1${NC}"
	echo -e "${GREEN}Dönüştürme başlıyor. Devam etmek istiyor musunuz? (e/h)${NC}"
	read -p "Seçiminiz: " start_choice

	if [ "$start_choice" = "e" ] || [ "$start_choice" = "E" ]; then
		find "$1" -type f -name "*.mkv" | while read -r file; do
			convert_mkv "$file"
		done
		echo -e "${GREEN}Tüm dönüştürmeler tamamlandı!${NC}"
	else
		echo -e "${YELLOW}İşlem iptal edildi.${NC}"
		exit 0
	fi
else
	echo -e "${RED}Hata: '$1' geçerli bir dizin değil.${NC}"
	exit 1
fi
