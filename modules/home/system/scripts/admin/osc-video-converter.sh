#!/usr/bin/env bash
#===============================================================================
#
#   Script: VideoAlchemist
#   Version: 1.0.0
#   Date: 2024-03-28
#   Author: Kenan Pelit
#   Repository: https://github.com/kenanpelit/nixosc
#   Description: Comprehensive video format conversion utility that transforms
#                between MP4 and MKV formats with enhanced user experience
#
#   Features:
#   - Converts between MP4 and MKV formats without quality loss
#   - Supports both single file and batch directory conversions
#   - Interactive progress bar with visual feedback
#   - File management options (keep or delete original files)
#   - Optimized encoding settings for different conversion types
#   - Multi-threaded processing for improved performance
#
#   License: MIT
#
#===============================================================================

# Renkler
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # Renk yok

# FFmpeg kontrolü
if ! command -v ffmpeg &>/dev/null; then
	echo -e "${RED}FFmpeg yüklü değil.${NC}"
	exit 1
fi

# CPU çekirdek sayısını al
THREADS=$(nproc 2>/dev/null || echo "2")

# İlerleme çubuğu fonksiyonu
show_progress() {
	local duration=$1
	local current_time=$2
	local progress=$((current_time * 100 / duration))
	local bar_length=50
	local filled_length=$((progress * bar_length / 100))
	local bar=""

	for ((i = 0; i < filled_length; i++)); do
		bar="${bar}█"
	done
	for ((i = filled_length; i < bar_length; i++)); do
		bar="${bar}░"
	done

	printf "\r[%s] %d%%" "$bar" "$progress"
}

# Yardım mesajı
show_help() {
	echo -e "${CYAN}╔════════════════════════════════════════╗${NC}"
	echo -e "${CYAN}║     Video Format Dönüştürücü v1.0      ║${NC}"
	echo -e "${CYAN}╚════════════════════════════════════════╝${NC}"
	echo -e "${YELLOW}Kullanım:${NC}"
	echo -e "  $0 mp4tomkv <dosya.mp4 veya dizin>"
	echo -e "  $0 mkvtomp4 <dosya.mkv veya dizin>"
	echo -e "\n${YELLOW}Örnekler:${NC}"
	echo -e "  $0 mp4tomkv video.mp4     ${GREEN}# Tek bir MP4 dosyasını MKV'ye dönüştür${NC}"
	echo -e "  $0 mkvtomp4 /home/videos  ${GREEN}# Dizindeki tüm MKV dosyalarını MP4'e dönüştür${NC}"
}

# MP4'ten MKV'ye dönüştürme fonksiyonu
convert_mp4_to_mkv() {
	local input_file="$1"
	local output_file="${input_file%.*}.mkv"

	# Eğer dosya zaten mkv ise atla
	if [ "${input_file##*.}" = "mkv" ]; then
		echo -e "${YELLOW}Atlanıyor: $input_file zaten MKV formatında.${NC}"
		return
	fi

	echo -e "\n${YELLOW}╔════════════════════════════════════════════════════════╗${NC}"
	echo -e "${YELLOW}║ Dönüştürülüyor: $(basename "$input_file")${NC}"
	echo -e "${YELLOW}╚════════════════════════════════════════════════════════╝${NC}"

	# Video süresini al (saniye olarak)
	duration=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$input_file")
	duration=${duration%.*}

	# Video bilgilerini al
	local video_info=$(ffprobe -v error -select_streams v:0 -show_entries stream=width,height,r_frame_rate -of csv=p=0 "$input_file")
	IFS=',' read -r width height frame_rate <<<"$video_info"
	echo -e "${BLUE}Çözünürlük: ${width}x${height}${NC}"
	echo -e "${BLUE}Dönüşüm tipi: MP4 → MKV (kopyalama)${NC}"

	# FFmpeg ile dönüştürme (kalite kaybı olmadan)
	ffmpeg -i "$input_file" \
		-c:v copy \
		-c:a copy \
		-c:s copy \
		-progress - \
		"$output_file" 2>/dev/null |
		while read -r line; do
			if [[ $line =~ out_time=([0-9:.]+) ]]; then
				time="${BASH_REMATCH[1]}"
				current_seconds=$(echo "$time" | awk -F: '{ print ($1 * 3600) + ($2 * 60) + $3 }')
				show_progress "$duration" "${current_seconds%.*}"
			fi
		done

	# Dönüştürme başarılı mı kontrol et
	if [ $? -eq 0 ] && [ -f "$output_file" ]; then
		echo -e "\n${GREEN}Başarıyla dönüştürüldü: $(basename "$output_file")${NC}"
		# Orijinal dosyanın ve yeni dosyanın boyutlarını göster
		original_size=$(du -h "$input_file" | cut -f1)
		new_size=$(du -h "$output_file" | cut -f1)
		echo -e "${YELLOW}Orijinal boyut: $original_size${NC}"
		echo -e "${YELLOW}Yeni boyut: $new_size${NC}"

		# Kullanıcıya sor
		echo -e "\nOrijinal MP4 dosyası silinsin mi?"
		echo -e "1) ${GREEN}Evet, sil${NC}"
		echo -e "2) ${BLUE}Hayır, sakla${NC}"
		read -p "Seçiminiz (1/2): " choice
		case $choice in
		1)
			rm "$input_file"
			echo -e "${RED}Orijinal dosya silindi: $(basename "$input_file")${NC}"
			;;
		2)
			echo -e "${GREEN}Orijinal dosya saklandı: $(basename "$input_file")${NC}"
			;;
		*)
			echo -e "${YELLOW}Geçersiz seçim. Orijinal dosya saklandı.${NC}"
			;;
		esac
	else
		echo -e "\n${RED}Hata: $input_file dönüştürülemedi${NC}"
	fi
}

# MKV'den MP4'e dönüştürme fonksiyonu
convert_mkv_to_mp4() {
	local input_file="$1"
	local output_file="${input_file%.mkv}.mp4"

	# Eğer dosya zaten mp4 ise atla
	if [ "${input_file##*.}" = "mp4" ]; then
		echo -e "${YELLOW}Atlanıyor: $input_file zaten MP4 formatında.${NC}"
		return
	fi

	echo -e "\n${YELLOW}╔════════════════════════════════════════════════════════╗${NC}"
	echo -e "${YELLOW}║ Dönüştürülüyor: $(basename "$input_file")${NC}"
	echo -e "${YELLOW}╚════════════════════════════════════════════════════════╝${NC}"

	# Video süresini al (saniye olarak)
	duration=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$input_file")
	duration=${duration%.*}

	# Video bilgilerini al
	local video_info=$(ffprobe -v error -select_streams v:0 -show_entries stream=width,height,r_frame_rate -of csv=p=0 "$input_file")
	IFS=',' read -r width height frame_rate <<<"$video_info"
	echo -e "${BLUE}Çözünürlük: ${width}x${height}${NC}"
	echo -e "${BLUE}Dönüşüm tipi: MKV → MP4 (yeniden kodlama)${NC}"

	# FFmpeg ile dönüştürme (yeniden kodlama ile)
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

	# Dönüştürme başarılı mı kontrol et
	if [ $? -eq 0 ] && [ -f "$output_file" ]; then
		echo -e "\n${GREEN}Başarıyla dönüştürüldü: $(basename "$output_file")${NC}"
		# Orijinal dosyanın ve yeni dosyanın boyutlarını göster
		original_size=$(du -h "$input_file" | cut -f1)
		new_size=$(du -h "$output_file" | cut -f1)
		echo -e "${YELLOW}Orijinal boyut: $original_size${NC}"
		echo -e "${YELLOW}Yeni boyut: $new_size${NC}"

		# Kullanıcıya sor
		echo -e "\nOrijinal MKV dosyası silinsin mi?"
		echo -e "1) ${GREEN}Evet, sil${NC}"
		echo -e "2) ${BLUE}Hayır, sakla${NC}"
		read -p "Seçiminiz (1/2): " choice
		case $choice in
		1)
			rm "$input_file"
			echo -e "${RED}Orijinal dosya silindi: $(basename "$input_file")${NC}"
			;;
		2)
			echo -e "${GREEN}Orijinal dosya saklandı: $(basename "$input_file")${NC}"
			;;
		*)
			echo -e "${YELLOW}Geçersiz seçim. Orijinal dosya saklandı.${NC}"
			;;
		esac
	else
		echo -e "\n${RED}Hata: $input_file dönüştürülemedi${NC}"
	fi
}

# Ana işlev - Tek dosya veya dizindeki tüm dosyaları dönüştür
process_input() {
	local mode="$1"
	local input_path="$2"
	local extension=""

	if [ "$mode" = "mp4tomkv" ]; then
		convert_func="convert_mp4_to_mkv"
		extension="mp4"
	elif [ "$mode" = "mkvtomp4" ]; then
		convert_func="convert_mkv_to_mp4"
		extension="mkv"
	else
		echo -e "${RED}Hata: Geçersiz dönüşüm modu.${NC}"
		show_help
		exit 1
	fi

	# Eğer girdi bir dizin ise
	if [ -d "$input_path" ]; then
		echo -e "${CYAN}╔═══════════════════════════════════════════════════════╗${NC}"
		echo -e "${CYAN}║ Dizindeki tüm .$extension dosyaları dönüştürülecek...  ║${NC}"
		echo -e "${CYAN}╚═══════════════════════════════════════════════════════╝${NC}"

		# Dosya sayısını bul
		file_count=$(find "$input_path" -type f -name "*.$extension" | wc -l)

		if [ "$file_count" -eq 0 ]; then
			echo -e "${RED}Hata: Dizinde .$extension dosyası bulunamadı.${NC}"
			exit 1
		fi

		echo -e "${GREEN}Toplam $file_count adet .$extension dosyası bulundu.${NC}"
		echo -e "${YELLOW}Dönüştürme başlıyor. Devam etmek istiyor musunuz? (e/h)${NC}"
		read -p "Seçiminiz: " start_choice

		if [ "$start_choice" = "e" ] || [ "$start_choice" = "E" ]; then
			current=1
			find "$input_path" -type f -name "*.$extension" | while read -r file; do
				echo -e "${CYAN}İşleniyor: $current / $file_count${NC}"
				$convert_func "$file"
				current=$((current + 1))
			done
			echo -e "\n${GREEN}╔═══════════════════════════════════════════════════════╗${NC}"
			echo -e "${GREEN}║           Tüm dönüştürmeler tamamlandı!               ║${NC}"
			echo -e "${GREEN}╚═══════════════════════════════════════════════════════╝${NC}"
		else
			echo -e "${YELLOW}İşlem iptal edildi.${NC}"
			exit 0
		fi
	# Eğer girdi bir dosya ise
	elif [ -f "$input_path" ]; then
		if [[ "$input_path" == *.$extension ]]; then
			$convert_func "$input_path"
			echo -e "\n${GREEN}╔═══════════════════════════════════════════════════════╗${NC}"
			echo -e "${GREEN}║                İşlem tamamlandı!                      ║${NC}"
			echo -e "${GREEN}╚═══════════════════════════════════════════════════════╝${NC}"
		else
			echo -e "${RED}Hata: Lütfen bir .$extension dosyası seçin.${NC}"
			exit 1
		fi
	else
		echo -e "${RED}Hata: Geçersiz dosya veya dizin.${NC}"
		exit 1
	fi
}

# Ana program
# Parametre kontrolü
if [ $# -lt 2 ]; then
	show_help
	exit 1
fi

mode="$1"
input_path="$2"

case "$mode" in
mp4tomkv | mkvtomp4)
	process_input "$mode" "$input_path"
	;;
help | -h | --help)
	show_help
	;;
*)
	echo -e "${RED}Hata: Geçersiz mod.${NC}"
	show_help
	exit 1
	;;
esac

exit 0
