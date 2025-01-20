#!/usr/bin/env bash

# Yapılandırma
WALLPAPER_PATH="$HOME/Pictures/wallpapers"
WALLPAPERS_FOLDER="$HOME/Pictures/wallpapers/others"
WALLPAPER_LINK="$WALLPAPER_PATH/wallpaper"

# Renk tanımlamaları
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Hata kontrolü fonksiyonu
check_error() {
	if [ $? -ne 0 ]; then
		echo -e "${RED}HATA: $1${NC}" >&2
		exit 1
	fi
}

# Dizin kontrolü
if [ ! -d "$WALLPAPERS_FOLDER" ]; then
	echo -e "${RED}HATA: Duvar kağıdı dizini bulunamadı: $WALLPAPERS_FOLDER${NC}" >&2
	exit 1
fi

# Ana dizini oluştur
mkdir -p "$WALLPAPER_PATH"
check_error "Duvar kağıdı ana dizini oluşturulamadı"

# Mevcut duvar kağıdını al
current_wallpaper=$(readlink "$WALLPAPER_LINK" 2>/dev/null)
current_wallpaper_name=$(basename "$current_wallpaper" 2>/dev/null)

# Duvar kağıtlarını listele (sadece resim dosyalarını)
mapfile -t wallpaper_list < <(find "$WALLPAPERS_FOLDER" -type f \( -name "*.jpg" -o -name "*.jpeg" -o -name "*.png" \))
wallpaper_count=${#wallpaper_list[@]}

# Duvar kağıdı kontrolü
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

	# Aynı duvar kağıdı değilse
	if [[ "$selected_name" != "$current_wallpaper_name" ]]; then
		break
	fi
	((attempt++))
done

if [ $attempt -eq $max_attempts ]; then
	echo -e "${RED}HATA: Uygun duvar kağıdı bulunamadı${NC}" >&2
	exit 1
fi

# Duvar kağıdını değiştir
ln -sf "$selected_wallpaper" "$WALLPAPER_LINK"
check_error "Sembolik bağlantı oluşturulamadı"

# Duvar kağıdını uygula
wall-change "$WALLPAPER_LINK" &

echo -e "${GREEN}Duvar kağıdı değiştirildi: $selected_name${NC}"
