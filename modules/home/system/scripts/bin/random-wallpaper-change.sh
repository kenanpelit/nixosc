#!/usr/bin/env bash

# Varsayılan değer (saniye)
INTERVAL=180 # 3 dakika

# Yapılandırma
WALLPAPER_PATH="$HOME/Pictures/wallpapers"
WALLPAPERS_FOLDER="$HOME/Pictures/wallpapers/others"
WALLPAPER_LINK="$WALLPAPER_PATH/wallpaper"

# Renk tanımlamaları
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Kullanım bilgisi
show_usage() {
	echo "Kullanım: $(basename "$0") [süre]"
	echo "süre: Duvar kağıdı değişim süresi (saniye), varsayılan: 180"
	echo "Örnek: $(basename "$0") 300  # 5 dakikada bir değiştirir"
	exit 1
}

# Parametreleri kontrol et
if [[ "$1" =~ ^[0-9]+$ ]]; then
	INTERVAL=$1
elif [[ -n "$1" ]]; then
	show_usage
fi

# Dizin kontrolü
if [ ! -d "$WALLPAPERS_FOLDER" ]; then
	echo -e "${RED}HATA: Duvar kağıdı dizini bulunamadı: $WALLPAPERS_FOLDER${NC}" >&2
	exit 1
fi

# Ana dizini oluştur
mkdir -p "$WALLPAPER_PATH"

# CTRL+C ile temiz çıkış
trap 'echo -e "\n${YELLOW}Duvar kağıdı döngüsü durduruldu${NC}"; exit 0' INT TERM

# Ana döngü
echo -e "${GREEN}Duvar kağıdı değişimi başlatıldı (${INTERVAL} saniye aralıkla)${NC}"
while true; do
	# Mevcut duvar kağıdını al
	current_wallpaper=$(readlink "$WALLPAPER_LINK" 2>/dev/null)
	current_wallpaper_name=$(basename "$current_wallpaper" 2>/dev/null)

	# Duvar kağıtlarını listele
	mapfile -t wallpaper_list < <(find "$WALLPAPERS_FOLDER" -type f \( -name "*.jpg" -o -name "*.jpeg" -o -name "*.png" \))
	wallpaper_count=${#wallpaper_list[@]}

	if [ $wallpaper_count -eq 0 ]; then
		echo -e "${RED}HATA: Duvar kağıdı bulunamadı: $WALLPAPERS_FOLDER${NC}" >&2
		exit 1
	fi

	# Yeni duvar kağıdı seç
	max_attempts=10
	attempt=0
	while [ $attempt -lt $max_attempts ]; do
		selected_wallpaper="${wallpaper_list[RANDOM % wallpaper_count]}"
		selected_name=$(basename "$selected_wallpaper")

		if [[ "$selected_name" != "$current_wallpaper_name" ]]; then
			break
		fi
		((attempt++))
	done

	# Duvar kağıdını değiştir
	ln -sf "$selected_wallpaper" "$WALLPAPER_LINK"
	wall-change "$WALLPAPER_LINK"
	echo -e "${GREEN}Duvar kağıdı değiştirildi: $selected_name${NC}"

	# Sonraki değişim için bekle
	sleep $INTERVAL
done
