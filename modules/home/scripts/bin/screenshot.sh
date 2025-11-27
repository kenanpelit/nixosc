#!/usr/bin/env bash

#######################################
#
# Version: 2.4.0
# Date: 2025-11-27
# Author: Kenan Pelit
# Repository: github.com/kenanpelit/dotfiles
# Description: HyprFlow & GnomeFlow - Gelişmiş Ekran Görüntüsü Aracı
#
# License: MIT
#
#######################################

# Yapılandırma Ayarları
SAVE_DIR="$HOME/Pictures/screenshots"
TEMP_DIR="/tmp/hyprflow"
BORDER_COLOR="#3584e4b0"        # Daha modern bir mavi ton
SELECTION_COLOR="#00000040"     # Hafif şeffaf siyah selection fill
BORDER_WIDTH="3"                # Daha kalın sınır
COLOR_PICKER_BORDER="#e01b24ff" # Canlı kırmızı

# Düzenleyici uygulamaları (öncelik sırasına göre)
EDITORS=("swappy" "satty" "gimp" "krita")

# Dosya adı formatı
FILENAME_FORMAT="screenshot_%Y-%m-%d_%H-%M-%S.png"

# Hata kodları
EXIT_SUCCESS=0
EXIT_INVALID_OPTION=1
EXIT_MISSING_DEPENDENCY=2
EXIT_CANCELLED=3

# Ortam Algılama
detect_env() {
	if [ "$XDG_CURRENT_DESKTOP" = "GNOME" ]; then
		echo "gnome"
	elif [ "$XDG_CURRENT_DESKTOP" = "Hyprland" ]; then
		echo "hyprland"
	elif [ "$XDG_CURRENT_DESKTOP" = "sway" ]; then
		echo "sway"
	else
		# Fallback check
		if pgrep -x "gnome-shell" >/dev/null; then
			echo "gnome"
		elif pgrep -x "Hyprland" >/dev/null; then
			echo "hyprland"
		elif pgrep -x "sway" >/dev/null; then
			echo "sway"
		else
			echo "unknown"
		fi
	fi
}

CURRENT_ENV=$(detect_env)

# GNOME Handler - Basitleştirilmiş Mod
handle_gnome() {
    # GNOME ortamında karmaşık CLI işlemleri yerine
    # güvenilir olan interaktif arayüzü başlatıyoruz.
    if command -v gnome-screenshot &>/dev/null; then
        gnome-screenshot -i
        exit $EXIT_SUCCESS
    else
        notify-send "Hata" "gnome-screenshot yüklü değil!" "critical"
        exit $EXIT_MISSING_DEPENDENCY
    fi
}

# En iyi düzenleyiciyi bul
select_editor() {
	for editor in "${EDITORS[@]}"; do
		if command -v "$editor" &>/dev/null; then
			echo "$editor"
			return
		fi
	done
	echo "none"
}

EDITOR=$(select_editor)

# Geçici dizin oluştur
create_temp_dir() {
	if [[ ! -d "$TEMP_DIR" ]]; then
		mkdir -p "$TEMP_DIR"
	fi
}

# Bağımlılıkları kontrol et
check_dependencies() {
	local missing_deps=()

	# Ortak bağımlılıklar
	if ! command -v notify-send &>/dev/null; then missing_deps+=("notify-send"); fi
	if ! command -v wl-copy &>/dev/null; then missing_deps+=("wl-copy"); fi

	# Ortama özel bağımlılıklar
    # GNOME kontrolü handle_gnome içinde yapılıyor.
	if [ "$CURRENT_ENV" = "hyprland" ] || [ "$CURRENT_ENV" = "sway" ]; then
		for cmd in grim slurp; do
			if ! command -v "$cmd" &>/dev/null; then missing_deps+=("$cmd"); fi
		done
		if [ "$CURRENT_ENV" = "hyprland" ] && ! command -v hyprctl &>/dev/null; then missing_deps+=("hyprctl"); fi
		if [ "$CURRENT_ENV" = "sway" ] && ! command -v swaymsg &>/dev/null; then missing_deps+=("swaymsg"); fi
	fi

	# Düzenleyici kontrolü
	if [ "$EDITOR" = "none" ]; then
		missing_deps+=("swappy/satty")
	fi

	if [ ${#missing_deps[@]} -ne 0 ]; then
		show_notification "Eksik Bağımlılıklar" "Lütfen yükleyin: ${missing_deps[*]}" "critical"
		exit $EXIT_MISSING_DEPENDENCY
	fi
}

# Yardım fonksiyonu
show_help() {
	cat <<EOF
╭────────────────────────────────────╮
│   HyprFlow & GnomeFlow Screenshot  │
│             Sürüm 2.4.0            │
│         Ortam: $CURRENT_ENV        │
╰────────────────────────────────────╯

Kullanım: $(basename "$0") [SEÇENEK]

KOMUTLAR (Hyprland/Sway):
  rc, rf, ri, rec - Bölge işlemleri
  sc, sf, si, sec - Tam ekran işlemleri
  wc, wf, wi      - Pencere işlemleri
  p               - Renk seçici

GNOME MODU:
  Bu ortamda ($CURRENT_ENV), tüm komutlar
  'gnome-screenshot -i' arayüzünü başlatır.

NOTLAR:
- Kayıt dizini: $SAVE_DIR
- Kullanılan düzenleyici: $EDITOR
EOF
}

# Bildirim gösterme fonksiyonu
show_notification() {
	local title="$1"
	local message="$2"
	local urgency="${3:-normal}"
	local icon="${4:-preferences-desktop-screensaver}"

	notify-send -h string:x-canonical-private-synchronous:screenshot-tool \
		-t 2000 \
		-u "$urgency" -i "$icon" "$title" "$message"
}

# Aktif pencere screenshot alma fonksiyonu
take_active_window_screenshot() {
	local filename="$1"
	local success=false

	if [ "$CURRENT_ENV" = "hyprland" ]; then
		local active_window
		active_window=$(hyprctl activewindow -j | jq -r '"\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"')
		if [ -n "$active_window" ] && [ "$active_window" != "null" ]; then
			grim -g "$active_window" "$filename" && success=true
		fi
	elif [ "$CURRENT_ENV" = "sway" ]; then
		local active_window
		active_window=$(swaymsg -t get_tree | jq -r '.. | select(.focused?) | .rect | "\(.x),\(.y) \(.width)x\(.height)"')
		if [ -n "$active_window" ] && [ "$active_window" != "null" ]; then
			grim -g "$active_window" "$filename" && success=true
		fi
	fi

	if [ "$success" = true ]; then
		return $EXIT_SUCCESS
	else
		show_notification "Hata" "Pencere görüntüsü alınamadı" "critical"
		return 1
	fi
}

# Screenshot alma fonksiyonu (Bölge Seçimi)
take_region_screenshot() {
	local filename="$1"
	local slurp_output
	slurp_output=$(slurp -b "$BORDER_COLOR" -c "$SELECTION_COLOR" -w "$BORDER_WIDTH" 2>&1)

	if [ $? -ne 0 ]; then
		return $EXIT_CANCELLED
	fi

	if grim -g "$slurp_output" "$filename"; then
		return $EXIT_SUCCESS
	else
		return 1
	fi
}

# Tam ekran screenshot alma fonksiyonu
take_fullscreen_screenshot() {
	local filename="$1"
	if grim "$filename"; then
		return $EXIT_SUCCESS
	else
		return 1
	fi
}

# Klasör oluşturma ve yardımcılar
create_screenshot_dir() {
	if [[ ! -d "$SAVE_DIR" ]]; then
		mkdir -p "$SAVE_DIR"
	fi
}

get_filename() {
	date +"$FILENAME_FORMAT"
}

open_in_editor() {
	local input="$1"
	local output="$2"

	case "$EDITOR" in
	swappy)
		"$EDITOR" -f "$input" -o "$output"
		;;
	satty)
		"$EDITOR" --filename "$input" --output-filename "$output"
		;;
	gimp | krita)
		"$EDITOR" "$input" &
		show_notification "Düzenleyici" "$EDITOR ile açıldı."
		;;
	*)
		show_notification "Hata" "Düzenleyici bulunamadı" "critical"
		return 1
		;;
	esac
}

open_last_screenshot() {
	local latest
	latest=$(find "$SAVE_DIR" -type f -name "*.png" -printf "%T@ %p\n" | sort -n | tail -1 | cut -d' ' -f2-)

	if [ -n "$latest" ]; then
		xdg-open "$latest" &
		show_notification "Görüntü Açıldı" "$(basename "$latest")"
	else
		show_notification "Hata" "Görüntü bulunamadı" "critical"
	fi
}

open_screenshots_dir() {
	create_screenshot_dir
	xdg-open "$SAVE_DIR" &
	show_notification "Dizin Açıldı" "$SAVE_DIR"
}

# Renk seçme
pick_color() {
	local color
	local slurp_output
	slurp_output=$(slurp -p -b '#00000000' -c "$COLOR_PICKER_BORDER" -w "$BORDER_WIDTH" 2>&1)
	if [ $? -ne 0 ]; then return $EXIT_CANCELLED; fi
	
	color=$(echo "$slurp_output" | grim -g - -t ppm - 2>/dev/null)
	if command -v magick &>/dev/null; then
		color=$(echo "$color" | magick - -format '%[pixel:p{0,0}]' txt:- 2>/dev/null | tail -n1 | cut -d' ' -f4)
	elif command -v convert &>/dev/null; then
		color=$(echo "$color" | convert - -format '%[pixel:p{0,0}]' txt:- 2>/dev/null | tail -n1 | cut -d' ' -f4)
	else
		return 1
	fi
	echo "$color"
}

# --- Main Logic ---

# GNOME ise direkt handle_gnome'a git ve çık
if [ "$CURRENT_ENV" = "gnome" ]; then
    # Eğer help isteniyorsa aşağı devam etsin, diğer tüm durumlarda gnome-screenshot aç
    if [[ "$1" != "help" && "$1" != "--help" && "$1" != "-h" ]]; then
        handle_gnome
    fi
fi

check_dependencies
create_temp_dir

# Geçici dosyaları temizle
find "$TEMP_DIR" -type f -mtime +1 -name "screenshot_*.png" -exec rm {} \;

case $1 in
rc) # Bölge Kopyala
	temp_file=$(mktemp "$TEMP_DIR/screenshot_XXXXXX.png")
	if take_region_screenshot "$temp_file"; then
		cat "$temp_file" | wl-copy
		show_notification "Screenshot" "Bölge panoya kopyalandı" "normal" "edit-copy"
		rm "$temp_file"
	fi
	;;

rf) # Bölge Kaydet
	create_screenshot_dir
	filename="$SAVE_DIR/$(get_filename)"
	if take_region_screenshot "$filename"; then
		show_notification "Screenshot" "Bölge kaydedildi: $(basename "$filename")" "normal" "document-save"
	fi
	;;

ri) # Bölge İnteraktif
	create_screenshot_dir
	temp_file=$(mktemp "$TEMP_DIR/screenshot_XXXXXX.png")
	filename="$SAVE_DIR/$(get_filename)"
	if take_region_screenshot "$temp_file"; then
		if open_in_editor "$temp_file" "$filename"; then
			show_notification "Screenshot" "Düzenlendi ve kaydedildi" "normal" "document-edit"
		fi
		rm "$temp_file"
	fi
	;;

rec) # Bölge Düzenle + Kopyala
	create_screenshot_dir
	temp_file=$(mktemp "$TEMP_DIR/screenshot_XXXXXX.png")
	filename="$SAVE_DIR/$(get_filename)"
	if take_region_screenshot "$temp_file"; then
		# Önce düzenleyici aç
		if open_in_editor "$temp_file" "$filename"; then
            if [ -f "$filename" ] && [ -s "$filename" ]; then
			    cat "$filename" | wl-copy
			    show_notification "Screenshot" "Düzenlendi, kaydedildi ve kopyalandı" "normal" "edit-copy"
            else
                 show_notification "Screenshot" "Düzenleyici kapandı." "normal"
            fi
		fi
		rm "$temp_file"
	fi
	;;

sc) # Ekran Kopyala
	temp_file=$(mktemp "$TEMP_DIR/screenshot_XXXXXX.png")
	if take_fullscreen_screenshot "$temp_file"; then
		cat "$temp_file" | wl-copy
		show_notification "Screenshot" "Tam ekran panoya kopyalandı" "normal" "edit-copy"
		rm "$temp_file"
	fi
	;;

sf) # Ekran Kaydet
	create_screenshot_dir
	filename="$SAVE_DIR/$(get_filename)"
	if take_fullscreen_screenshot "$filename"; then
		show_notification "Screenshot" "Tam ekran kaydedildi: $(basename "$filename")" "normal" "document-save"
	fi
	;;

si | sec) # Ekran İnteraktif / Edit+Copy
	create_screenshot_dir
	temp_file=$(mktemp "$TEMP_DIR/screenshot_XXXXXX.png")
	filename="$SAVE_DIR/$(get_filename)"
	if take_fullscreen_screenshot "$temp_file"; then
		if open_in_editor "$temp_file" "$filename"; then
             if [ "$1" = "sec" ] && [ -f "$filename" ] && [ -s "$filename" ]; then
                cat "$filename" | wl-copy
			    show_notification "Screenshot" "Düzenlendi, kaydedildi ve kopyalandı" "normal" "edit-copy"
             else
			    show_notification "Screenshot" "İşlem tamamlandı" "normal" "document-edit"
             fi
		fi
		rm "$temp_file"
	fi
	;;

wc) # Pencere Kopyala
	temp_file=$(mktemp "$TEMP_DIR/screenshot_XXXXXX.png")
	if take_active_window_screenshot "$temp_file"; then
		cat "$temp_file" | wl-copy
		show_notification "Screenshot" "Pencere panoya kopyalandı" "normal" "edit-copy"
		rm "$temp_file"
	fi
	;;

wf) # Pencere Kaydet
	create_screenshot_dir
	filename="$SAVE_DIR/$(get_filename)"
	if take_active_window_screenshot "$filename"; then
		show_notification "Screenshot" "Pencere kaydedildi: $(basename "$filename")" "normal" "document-save"
	fi
	;;

wi) # Pencere İnteraktif
	create_screenshot_dir
	temp_file=$(mktemp "$TEMP_DIR/screenshot_XXXXXX.png")
	filename="$SAVE_DIR/$(get_filename)"
	if take_active_window_screenshot "$temp_file"; then
		if open_in_editor "$temp_file" "$filename"; then
			show_notification "Screenshot" "Pencere düzenlendi ve kaydedildi" "normal" "document-edit"
		fi
		rm "$temp_file"
	fi
	;;

p) # Renk Seç
	color=$(pick_color)
	if [ $? -eq $EXIT_CANCELLED ]; then exit $EXIT_SUCCESS; fi
	if [ -n "$color" ]; then
		echo -n "$color" | wl-copy
		show_notification "$color" "Renk kopyalandı" "normal" "color-select"
	fi
	;;

o | open) open_last_screenshot ;; 
d | dir) open_screenshots_dir ;; 
help | --help | -h) show_help ;; 
*)
	show_notification "Hata" "Geçersiz seçenek: $1" "critical"
	exit $EXIT_INVALID_OPTION
	;;
esac

exit $EXIT_SUCCESS