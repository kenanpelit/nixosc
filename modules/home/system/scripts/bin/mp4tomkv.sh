#!/usr/bin/env bash

# mp4-to-mkv.sh
# Kalite kaybı olmadan MP4 dosyalarını MKV formatına dönüştürür.
# Tek dosya veya dizin içindeki tüm MP4'ler için kullanılabilir.
# Kullanım: ./mp4-to-mkv.sh <dosya.mp4 veya dizin>

# Renk kodları
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # Renk yok

# FFmpeg kontrolü
if ! command -v ffmpeg &>/dev/null; then
	echo -e "${RED}FFmpeg yüklü değil.${NC}"
	exit 1
fi

# Kullanım bilgisi fonksiyonu
show_usage() {
	echo -e "${YELLOW}Kullanım:${NC}"
	echo "  $0 <input_directory>"
	echo "  $0 <input_file.mp4>"
	echo -e "\n${YELLOW}Örnekler:${NC}"
	echo "  $0 video.mp4"
	echo "  $0 /home/user/videos"
}

# Parametre kontrolü
if [ $# -eq 0 ]; then
	echo -e "${RED}Hata: Lütfen bir dosya veya dizin belirtin.${NC}"
	show_usage
	exit 1
fi

# Girdi yolu
input_path="$1"

# Dönüştürme fonksiyonu
convert_to_mkv() {
	local input_file="$1"
	local output_file="${input_file%.*}.mkv"

	# Eğer dosya zaten mkv ise atla
	if [ "${input_file##*.}" = "mkv" ]; then
		echo -e "${YELLOW}Atlanıyor: $input_file zaten MKV formatında.${NC}"
		return
	fi

	echo -e "${GREEN}Dönüştürülüyor: $input_file${NC}"

	# FFmpeg ile dönüştürme (kalite kaybı olmadan)
	ffmpeg -i "$input_file" \
		-c:v copy \
		-c:a copy \
		-c:s copy \
		"$output_file" \
		-hide_banner \
		-loglevel warning

	# Dönüştürme başarılı mı kontrol et
	if [ $? -eq 0 ]; then
		echo -e "${GREEN}Başarıyla dönüştürüldü: $output_file${NC}"
		# Orijinal dosyanın ve yeni dosyanın boyutlarını göster
		original_size=$(du -h "$input_file" | cut -f1)
		new_size=$(du -h "$output_file" | cut -f1)
		echo -e "Orijinal boyut: $original_size"
		echo -e "Yeni boyut: $new_size"
	else
		echo -e "${RED}Hata: $input_file dönüştürülemedi${NC}"
	fi
}

# Eğer girdi bir dizin ise
if [ -d "$input_path" ]; then
	echo -e "${GREEN}Dizindeki tüm MP4 dosyaları dönüştürülüyor...${NC}"
	find "$input_path" -type f -name "*.mp4" | while read -r file; do
		convert_to_mkv "$file"
	done
# Eğer girdi bir dosya ise
elif [ -f "$input_path" ]; then
	if [[ "$input_path" == *.mp4 ]]; then
		convert_to_mkv "$input_path"
	else
		echo -e "${RED}Hata: Lütfen bir MP4 dosyası seçin.${NC}"
		exit 1
	fi
else
	echo -e "${RED}Hata: Geçersiz dosya veya dizin.${NC}"
	exit 1
fi

echo -e "${GREEN}İşlem tamamlandı!${NC}"
