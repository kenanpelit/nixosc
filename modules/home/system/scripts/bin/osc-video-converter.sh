#!/usr/bin/env bash
#===============================================================================
#
#   Script: Kompakt Video Dönüştürücü
#   Version: 2.0.1
#   Date: 2025-04-24
#   Description: Basitleştirilmiş video format dönüştürme aracı
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
	echo -e "${CYAN}╔═══════════════════════════════════════════╗${NC}"
	echo -e "${CYAN}║     Kompakt Video Dönüştürücü v2.0.1      ║${NC}"
	echo -e "${CYAN}╚═══════════════════════════════════════════╝${NC}"
	echo -e "${YELLOW}Kullanım:${NC}"
	echo -e "  $0 tv <dosya>           ${GREEN}# Normal TV uyumlu dönüştürme${NC}"
	echo -e "  $0 tvfast <dosya>       ${GREEN}# Hızlı TV uyumlu dönüştürme${NC}"
	echo -e "  $0 mp4tomkv <dosya>     ${GREEN}# MP4 → MKV dönüştürme${NC}"
	echo -e "  $0 mkvtomp4 <dosya>     ${GREEN}# MKV → MP4 dönüştürme${NC}"
}

# Video süresini al (saniye olarak)
get_duration() {
	local input_file="$1"
	local duration=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$input_file")
	echo ${duration%.*}
}

# Video bilgilerini göster
show_video_info() {
	local input_file="$1"

	echo -e "${BLUE}Video Bilgileri:${NC}"
	echo -e "${YELLOW}------------------------${NC}"

	# Video kodeki
	local video_codec=$(ffprobe -v error -select_streams v:0 -show_entries stream=codec_name -of default=noprint_wrappers=1:nokey=1 "$input_file")
	echo -e "${BLUE}Video Kodeki:${NC} $video_codec"

	# Ses kodeki
	local audio_codec=$(ffprobe -v error -select_streams a:0 -show_entries stream=codec_name -of default=noprint_wrappers=1:nokey=1 "$input_file")
	echo -e "${BLUE}Ses Kodeki:${NC} $audio_codec"

	# Çözünürlük
	local resolution=$(ffprobe -v error -select_streams v:0 -show_entries stream=width,height -of csv=s=x:p=0 "$input_file")
	echo -e "${BLUE}Çözünürlük:${NC} $resolution"

	# Video boyutu ve süre
	local size=$(du -h "$input_file" | cut -f1)
	local duration_sec=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$input_file")
	local hours=$((${duration_sec%.*} / 3600))
	local minutes=$(((${duration_sec%.*} % 3600) / 60))
	local seconds=$((${duration_sec%.*} % 60))

	echo -e "${BLUE}Dosya Boyutu:${NC} $size"
	echo -e "${BLUE}Süre:${NC} $hours:$minutes:$seconds"
	echo -e "${YELLOW}------------------------${NC}"
}

# TV Uyumlu Formata Dönüştür (Normal)
convert_tv() {
	local input_file="$1"
	local filename=$(basename "$input_file")
	local dirname=$(dirname "$input_file")
	local basename="${filename%.*}"
	local output_file="${dirname}/${basename}_TV_UYUMLU.mp4"

	echo -e "\n${YELLOW}╔════════════════════════════════════════════════════════╗${NC}"
	echo -e "${YELLOW}║ Dönüştürülüyor: $(basename "$input_file")${NC}"
	echo -e "${YELLOW}╚════════════════════════════════════════════════════════╝${NC}"

	# Video bilgilerini göster ve süreyi al
	show_video_info "$input_file"
	local duration=$(get_duration "$input_file")

	echo -e "${BLUE}Dönüşüm tipi: Orijinal → TV Uyumlu MP4 (H.264/AAC)${NC}"
	echo -e "${BLUE}Çıktı dosyası: ${output_file}${NC}"

	# Dönüştür
	ffmpeg -i "$input_file" \
		-c:v libx264 \
		-profile:v high \
		-level:v 4.0 \
		-preset medium \
		-crf 23 \
		-c:a aac \
		-b:a 192k \
		-ac 2 \
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

	if [ $? -eq 0 ] && [ -f "$output_file" ]; then
		echo -e "\n${GREEN}Başarıyla dönüştürüldü: $(basename "$output_file")${NC}"
		echo -e "${YELLOW}Orijinal boyut: $(du -h "$input_file" | cut -f1)${NC}"
		echo -e "${YELLOW}Yeni boyut: $(du -h "$output_file" | cut -f1)${NC}"
	else
		echo -e "\n${RED}Hata: Dönüştürme işlemi başarısız oldu.${NC}"
		[ -f "$output_file" ] && rm -f "$output_file"
	fi
}

# TV Uyumlu Formata Dönüştür (Hızlı)
convert_tv_fast() {
	local input_file="$1"
	local filename=$(basename "$input_file")
	local dirname=$(dirname "$input_file")
	local basename="${filename%.*}"
	local output_file="${dirname}/${basename}_TV_UYUMLU.mp4"

	echo -e "\n${YELLOW}╔════════════════════════════════════════════════════════╗${NC}"
	echo -e "${YELLOW}║ Dönüştürülüyor (HIZLI MOD): $(basename "$input_file")${NC}"
	echo -e "${YELLOW}╚════════════════════════════════════════════════════════╝${NC}"

	# Video bilgilerini göster ve süreyi al
	show_video_info "$input_file"
	local duration=$(get_duration "$input_file")

	# Video çözünürlüğünü al
	local video_resolution=$(ffprobe -v error -select_streams v:0 -show_entries stream=width,height -of csv=s=x:p=0 "$input_file")
	IFS='x' read -r width height <<<"$video_resolution"

	# Çözünürlük yüksekse, azalt (720p'ye düşür)
	local scale_option=""
	if [ "$height" -gt 720 ]; then
		echo -e "${YELLOW}Yüksek çözünürlük tespit edildi. İşlemi hızlandırmak için 720p'ye düşürülüyor.${NC}"
		scale_option="-vf scale=-2:720"
	fi

	echo -e "${BLUE}Dönüşüm tipi: Orijinal → TV Uyumlu MP4 (H.264/AAC) - HIZLI MOD${NC}"
	echo -e "${BLUE}Çıktı dosyası: ${output_file}${NC}"

	# Hızlı dönüştürme
	ffmpeg -i "$input_file" \
		-c:v libx264 \
		-profile:v main \
		-level:v 4.0 \
		-preset ultrafast \
		-crf 28 \
		$scale_option \
		-c:a aac \
		-b:a 128k \
		-ac 2 \
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

	if [ $? -eq 0 ] && [ -f "$output_file" ]; then
		echo -e "\n${GREEN}Başarıyla dönüştürüldü: $(basename "$output_file")${NC}"
		echo -e "${YELLOW}Orijinal boyut: $(du -h "$input_file" | cut -f1)${NC}"
		echo -e "${YELLOW}Yeni boyut: $(du -h "$output_file" | cut -f1)${NC}"
	else
		echo -e "\n${RED}Hata: Dönüştürme işlemi başarısız oldu.${NC}"
		[ -f "$output_file" ] && rm -f "$output_file"
	fi
}

# MP4 → MKV Dönüştürme
convert_mp4_to_mkv() {
	local input_file="$1"
	local filename=$(basename "$input_file")
	local dirname=$(dirname "$input_file")
	local basename="${filename%.*}"
	local output_file="${dirname}/${basename}.mkv"

	# Uzantı kontrolü
	if [ "${input_file##*.}" != "mp4" ]; then
		echo -e "${RED}Hata: Lütfen bir MP4 dosyası seçin.${NC}"
		exit 1
	fi

	echo -e "\n${YELLOW}╔════════════════════════════════════════════════════════╗${NC}"
	echo -e "${YELLOW}║ Dönüştürülüyor: $(basename "$input_file")${NC}"
	echo -e "${YELLOW}╚════════════════════════════════════════════════════════╝${NC}"

	# Video bilgilerini göster ve süreyi al
	show_video_info "$input_file"
	local duration=$(get_duration "$input_file")

	# Kodek bilgisini al
	local codec=$(ffprobe -v error -select_streams v:0 -show_entries stream=codec_name -of default=noprint_wrappers=1:nokey=1 "$input_file")
	echo -e "${BLUE}Dönüşüm tipi: MP4 → MKV${NC}"

	# Dönüştür
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

	if [ $? -eq 0 ] && [ -f "$output_file" ] && [ $(du -k "$output_file" | cut -f1) -gt 100 ]; then
		echo -e "\n${GREEN}Başarıyla dönüştürüldü: $(basename "$output_file")${NC}"
		echo -e "${YELLOW}Orijinal boyut: $(du -h "$input_file" | cut -f1)${NC}"
		echo -e "${YELLOW}Yeni boyut: $(du -h "$output_file" | cut -f1)${NC}"

		# Kullanıcıya sor
		echo -e "\nOrijinal MP4 dosyası silinsin mi?"
		echo -e "1) ${GREEN}Evet, sil${NC}"
		echo -e "2) ${BLUE}Hayır, sakla${NC}"
		read -p "Seçiminiz (1/2): " choice
		if [ "$choice" = "1" ]; then
			rm "$input_file"
			echo -e "${RED}Orijinal dosya silindi: $(basename "$input_file")${NC}"
		else
			echo -e "${GREEN}Orijinal dosya saklandı: $(basename "$input_file")${NC}"
		fi
	else
		echo -e "\n${RED}Hata: Dönüştürme işlemi başarısız oldu.${NC}"
		[ -f "$output_file" ] && rm -f "$output_file"
	fi
}

# MKV → MP4 Dönüştürme
convert_mkv_to_mp4() {
	local input_file="$1"
	local filename=$(basename "$input_file")
	local dirname=$(dirname "$input_file")
	local basename="${filename%.*}"
	local output_file="${dirname}/${basename}.mp4"

	# Uzantı kontrolü
	if [ "${input_file##*.}" != "mkv" ]; then
		echo -e "${RED}Hata: Lütfen bir MKV dosyası seçin.${NC}"
		exit 1
	fi

	echo -e "\n${YELLOW}╔════════════════════════════════════════════════════════╗${NC}"
	echo -e "${YELLOW}║ Dönüştürülüyor: $(basename "$input_file")${NC}"
	echo -e "${YELLOW}╚════════════════════════════════════════════════════════╝${NC}"

	# Video bilgilerini göster ve süreyi al
	show_video_info "$input_file"
	local duration=$(get_duration "$input_file")

	# Kodek bilgisini al
	local codec=$(ffprobe -v error -select_streams v:0 -show_entries stream=codec_name -of default=noprint_wrappers=1:nokey=1 "$input_file")
	echo -e "${BLUE}Dönüşüm tipi: MKV → MP4${NC}"

	# Dönüştür
	ffmpeg -i "$input_file" \
		-c:v libx264 \
		-preset ultrafast \
		-crf 23 \
		-c:a aac \
		-b:a 192k \
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

	if [ $? -eq 0 ] && [ -f "$output_file" ] && [ $(du -k "$output_file" | cut -f1) -gt 100 ]; then
		echo -e "\n${GREEN}Başarıyla dönüştürüldü: $(basename "$output_file")${NC}"
		echo -e "${YELLOW}Orijinal boyut: $(du -h "$input_file" | cut -f1)${NC}"
		echo -e "${YELLOW}Yeni boyut: $(du -h "$output_file" | cut -f1)${NC}"

		# Kullanıcıya sor
		echo -e "\nOrijinal MKV dosyası silinsin mi?"
		echo -e "1) ${GREEN}Evet, sil${NC}"
		echo -e "2) ${BLUE}Hayır, sakla${NC}"
		read -p "Seçiminiz (1/2): " choice
		if [ "$choice" = "1" ]; then
			rm "$input_file"
			echo -e "${RED}Orijinal dosya silindi: $(basename "$input_file")${NC}"
		else
			echo -e "${GREEN}Orijinal dosya saklandı: $(basename "$input_file")${NC}"
		fi
	else
		echo -e "\n${RED}Hata: Dönüştürme işlemi başarısız oldu.${NC}"
		[ -f "$output_file" ] && rm -f "$output_file"
	fi
}

# Ana program
if [ $# -lt 2 ]; then
	show_help
	exit 1
fi

command="$1"
input_file="$2"

if [ ! -f "$input_file" ]; then
	echo -e "${RED}Hata: Dosya bulunamadı - $input_file${NC}"
	exit 1
fi

case "$command" in
tv)
	convert_tv "$input_file"
	;;
tvfast)
	convert_tv_fast "$input_file"
	;;
mp4tomkv)
	convert_mp4_to_mkv "$input_file"
	;;
mkvtomp4)
	convert_mkv_to_mp4 "$input_file"
	;;
help | -h | --help)
	show_help
	;;
*)
	echo -e "${RED}Hata: Geçersiz komut.${NC}"
	show_help
	exit 1
	;;
esac

echo -e "\n${GREEN}╔═══════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                İşlem tamamlandı!                      ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════════════════════╝${NC}"

exit 0
