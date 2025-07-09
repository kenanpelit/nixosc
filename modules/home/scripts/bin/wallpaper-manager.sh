#!/usr/bin/env bash

# Varsayılan değer (saniye)
INTERVAL=300 # 5 dakika

# Yapılandırma
WALLPAPER_PATH="$HOME/Pictures/wallpapers"
WALLPAPERS_FOLDER="$HOME/Pictures/wallpapers/others"
WALLPAPER_LINK="$WALLPAPER_PATH/wallpaper"
PID_FILE="/tmp/wallpaper-changer.pid"
HISTORY_DIR="$HOME/.cache/wallpapers"
HISTORY_FILE="$HISTORY_DIR/history.txt"
TOTAL_FILE="$HISTORY_DIR/total_wallpapers.txt"

# Renk tanımlamaları
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# SWWW animasyonları
animations=("outer" "center" "any" "wipe")

# Kullanım bilgisi
show_usage() {
	echo "Kullanım: $(basename "$0") [komut] [süre]"
	echo "Komutlar:"
	echo "  start [süre]  : Servisi başlatır (süre saniye cinsinden, varsayılan: 300)"
	echo "  stop          : Servisi durdurur"
	echo "  status        : Servis durumunu gösterir"
	echo "  select        : Rofi ile duvar kağıdı seç"
	echo "  Boş          : Tek seferlik rastgele duvar kağıdı değiştirir"
	echo "Örnek: $(basename "$0") start 300  # 5 dakikada bir değiştirir"
	exit 1
}

# Duvar kağıdını ayarla
set_wallpaper() {
	local wallpaper="$1"
	local random_animation=${animations[RANDOM % ${#animations[@]}]}

	if [[ "$random_animation" == "wipe" ]]; then
		swww img --transition-type="wipe" --transition-angle=135 "$wallpaper"
	else
		swww img --transition-type="$random_animation" "$wallpaper"
	fi
}

# Geçmiş dizinini ve dosyalarını oluştur
init_history() {
	mkdir -p "$HISTORY_DIR"
	touch "$HISTORY_FILE"
	touch "$TOTAL_FILE"
}

# Duvar kağıdı sayısını güncelle
update_total_wallpapers() {
	local total=$(find "$WALLPAPERS_FOLDER" -type f \( -name "*.jpg" -o -name "*.jpeg" -o -name "*.png" \) | wc -l)
	echo "$total" >"$TOTAL_FILE"

	# Wallpaper listesini de kaydet
	find "$WALLPAPERS_FOLDER" -type f \( -name "*.jpg" -o -name "*.jpeg" -o -name "*.png" \) -exec basename {} \; >"$HISTORY_DIR/available_wallpapers.txt"
}

# Servis durumunu kontrol et
check_status() {
	if [ -f "$PID_FILE" ]; then
		pid=$(cat "$PID_FILE")
		if ps -p "$pid" >/dev/null 2>&1; then
			if pgrep -P "$pid" >/dev/null 2>&1; then
				echo -e "${GREEN}Servis çalışıyor (PID: $pid)${NC}"
				return 0
			fi
		fi
		rm -f "$PID_FILE"
		echo -e "${YELLOW}Servis çalışmıyor (eski PID dosyası temizlendi)${NC}"
		return 1
	else
		echo -e "${YELLOW}Servis çalışmıyor${NC}"
		return 1
	fi
}

# Duvar kağıdı değiştirme fonksiyonu
change_wallpaper() {
	# Geçmiş dizinini kontrol et
	init_history

	# Mevcut duvar kağıdını al
	current_wallpaper=$(readlink "$WALLPAPER_LINK" 2>/dev/null)
	current_wallpaper_name=$(basename "$current_wallpaper" 2>/dev/null)

	# Duvar kağıtlarını listele
	mapfile -t wallpaper_list < <(find "$WALLPAPERS_FOLDER" -type f \( -name "*.jpg" -o -name "*.jpeg" -o -name "*.png" \))
	wallpaper_count=${#wallpaper_list[@]}

	# Toplam duvar kağıdı sayısını güncelle
	update_total_wallpapers

	if [ $wallpaper_count -eq 0 ]; then
		echo -e "${RED}HATA: Duvar kağıdı bulunamadı: $WALLPAPERS_FOLDER${NC}" >&2
		return 1
	fi

	# Son kullanılan duvar kağıtlarını oku (son 10 adet)
	mapfile -t recent_wallpapers < <(tail -n 10 "$HISTORY_FILE" 2>/dev/null)

	# Yeni duvar kağıdı seç (son kullanılanları hariç tut)
	max_attempts=20
	attempt=0
	while [ $attempt -lt $max_attempts ]; do
		selected_wallpaper="${wallpaper_list[RANDOM % wallpaper_count]}"
		selected_name=$(basename "$selected_wallpaper")

		# Son kullanılanlar listesinde var mı kontrol et
		if ! printf '%s\n' "${recent_wallpapers[@]}" | grep -q "^${selected_name}$"; then
			break
		fi
		((attempt++))
	done

	# Duvar kağıdını değiştir
	ln -sf "$selected_wallpaper" "$WALLPAPER_LINK"
	set_wallpaper "$selected_wallpaper"

	# Geçmişe ekle
	echo "$selected_name" >>"$HISTORY_FILE"

	echo -e "${GREEN}Duvar kağıdı değiştirildi: $selected_name${NC}"
}

# Servisi başlat
start_service() {
	if check_status >/dev/null; then
		echo -e "${YELLOW}Servis zaten çalışıyor${NC}"
		exit 1
	fi

	# Dizin kontrolü
	if [ ! -d "$WALLPAPERS_FOLDER" ]; then
		echo -e "${RED}HATA: Duvar kağıdı dizini bulunamadı: $WALLPAPERS_FOLDER${NC}" >&2
		exit 1
	fi

	# Ana dizini oluştur
	mkdir -p "$WALLPAPER_PATH"

	# Ana süreç
	(
		while true; do
			change_wallpaper
			sleep $INTERVAL
		done
	) >>/tmp/wallpaper-changer.log 2>&1 &

	# Ana sürecin PID'ini kaydet
	echo $! >"$PID_FILE"

	# PID'in yazılmasını bekle
	sleep 1
	if [ -f "$PID_FILE" ] && ps -p $(cat "$PID_FILE") >/dev/null 2>&1; then
		echo -e "${GREEN}Servis başlatıldı${NC}"
	else
		echo -e "${RED}Servis başlatılamadı${NC}"
		rm -f "$PID_FILE"
		exit 1
	fi
}

# Servisi durdur
stop_service() {
	if [ -f "$PID_FILE" ]; then
		pid=$(cat "$PID_FILE")
		if ps -p "$pid" >/dev/null 2>&1; then
			kill -TERM "$pid"
			rm -f "$PID_FILE"
			echo -e "${GREEN}Servis durduruldu${NC}"
		else
			rm -f "$PID_FILE"
			echo -e "${YELLOW}Servis zaten durmuş (eski PID dosyası temizlendi)${NC}"
		fi
	else
		echo -e "${YELLOW}Servis zaten çalışmıyor${NC}"
	fi
}

# Rofi ile duvar kağıdı seç
select_wallpaper() {
	wallpaper_name="$(ls $WALLPAPERS_FOLDER | rofi -dmenu -p "Select wallpaper" || pkill rofi)"
	if [[ -f "$WALLPAPERS_FOLDER/$wallpaper_name" ]]; then
		ln -sf "$WALLPAPERS_FOLDER/$wallpaper_name" "$WALLPAPER_LINK"
		set_wallpaper "$WALLPAPERS_FOLDER/$wallpaper_name"

		# Geçmişe ekle
		init_history
		echo "$wallpaper_name" >>"$HISTORY_FILE"

		echo -e "${GREEN}Duvar kağıdı değiştirildi: $wallpaper_name${NC}"
	else
		echo -e "${RED}Geçersiz seçim veya iptal edildi${NC}"
		exit 1
	fi
}

# Ana komut kontrolü
case "$1" in
start)
	if [[ "$2" =~ ^[0-9]+$ ]]; then
		INTERVAL=$2
	elif [[ -n "$2" ]]; then
		show_usage
	fi
	start_service
	;;
stop)
	stop_service
	;;
status)
	check_status
	;;
select)
	select_wallpaper
	;;
*)
	# Parametre verilmemişse tek seferlik değişim yap
	if [ -z "$1" ]; then
		change_wallpaper
	else
		show_usage
	fi
	;;
esac
