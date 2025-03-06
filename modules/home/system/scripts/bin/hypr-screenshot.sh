#!/usr/bin/env bash

#######################################
#
# Version: 1.1.0
# Date: 2025-03-07
# Author: Kenan Pelit
# Repository: github.com/kenanpelit/dotfiles
# Description: HyprFlow - Advanced Screenshot Utility
#
# License: MIT
#
#######################################

# Yapılandırma Ayarları
SAVE_DIR="$HOME/Pictures/ss"
BORDER_COLOR="#3584e4b0"        # Daha modern bir mavi ton
SELECTION_COLOR="#00000040"     # Hafif şeffaf siyah selection fill
BORDER_WIDTH="3"                # Daha kalın sınır
COLOR_PICKER_BORDER="#e01b24ff" # Canlı kırmızı

# Dosya adı formatı
FILENAME_FORMAT="screenshot_%Y-%m-%d_%H-%M-%S.png"
EDITOR="swappy" # Düzenleyici uygulaması

# Hata kodları
EXIT_SUCCESS=0
EXIT_INVALID_OPTION=1
EXIT_MISSING_DEPENDENCY=2

# Bağımlılıkları kontrol et
check_dependencies() {
	local missing_deps=()
	for cmd in grim slurp wl-copy notify-send magick "$EDITOR"; do
		if ! command -v "$cmd" &>/dev/null; then
			missing_deps+=("$cmd")
		fi
	done

	if [ ${#missing_deps[@]} -ne 0 ]; then
		show_notification "Eksik Bağımlılıklar" "Lütfen yükleyin: ${missing_deps[*]}" "critical"
		exit $EXIT_MISSING_DEPENDENCY
	fi
}

# Yardım fonksiyonu
show_help() {
	cat <<EOF
╭────────────────────────────────────╮
│       HyprFlow Screenshot Tool     │
╰────────────────────────────────────╯

Kullanım: $(basename "$0") [SEÇENEK]

BÖLGE KOMUTLARI:
  rc    Bölge Kopyala      - Seçilen bölgeyi panoya kopyalar
  rf    Bölge Dosya        - Seçilen bölgeyi dosyaya kaydeder
  ri    Bölge Interaktif   - Seçilen bölgeyi düzenleyicide açar

EKRAN KOMUTLARI:
  sc    Ekran Kopyala      - Tüm ekranı panoya kopyalar
  sf    Ekran Dosya        - Tüm ekranı dosyaya kaydeder
  si    Ekran Interaktif   - Tüm ekranı düzenleyicide açar

DİĞER KOMUTLAR:
  p     Renk Seç           - Ekrandan renk seçer ve panoya kopyalar
  help  Yardım             - Bu yardım mesajını gösterir

ÖRNEKLER:
  $(basename "$0") rc    # Seçilen alanı panoya kopyalar
  $(basename "$0") sf    # Tüm ekranı dosyaya kaydeder
  $(basename "$0") p     # Renk seçer

NOTLAR:
- Kayıt dizini: $SAVE_DIR
- Interaktif mod $EDITOR kullanır
- Dosya formatı: $FILENAME_FORMAT

Geliştiren: Kenan Pelit
EOF
}

# Screenshot alma fonksiyonu
take_screenshot() {
	local filename="$1"
	local success=false

	grim -g "$(slurp -b "$BORDER_COLOR" -c "$SELECTION_COLOR" -w "$BORDER_WIDTH")" "$filename" && success=true

	if [ "$success" = true ]; then
		return $EXIT_SUCCESS
	else
		show_notification "Hata" "Ekran görüntüsü alınamadı" "critical"
		return 1
	fi
}

# Klasör oluşturma fonksiyonu
create_screenshot_dir() {
	if [[ ! -d "$SAVE_DIR" ]]; then
		mkdir -p "$SAVE_DIR"
		if [ $? -ne 0 ]; then
			show_notification "Hata" "Dizin oluşturulamadı: $SAVE_DIR" "critical"
			exit 1
		fi
	fi
}

# Timestamp oluşturma fonksiyonu
get_filename() {
	local format="${1:-$FILENAME_FORMAT}"
	date +"$format"
}

# Bildirim gösterme fonksiyonu
show_notification() {
	local title="$1"
	local message="$2"
	local urgency="${3:-normal}"
	local icon="${4:-preferences-desktop-screensaver}"

	notify-send -h string:x-canonical-private-synchronous:hyprflow-screenshot \
		-u "$urgency" -i "$icon" "$title" "$message"
}

# Renk seçme fonksiyonu
pick_color() {
	local color
	color=$(slurp -p -b '#00000000' -c "$COLOR_PICKER_BORDER" -w "$BORDER_WIDTH" |
		grim -g - -t ppm - |
		magick - -format '%[pixel:p{0,0}]' txt:- 2>/dev/null |
		tail -n1 | cut -d' ' -f4)

	echo "$color"
}

# Son ekran görüntüsünü açma fonksiyonu
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

# Başlangıçta bağımlılıkları kontrol et
check_dependencies

# Ana işlem kontrolü
case $1 in
rc) # Bölgeyi kopyala
	temp_file=$(mktemp)
	if take_screenshot "$temp_file"; then
		cat "$temp_file" | wl-copy
		rm -f "$temp_file"
		show_notification "Screenshot" "Panoya kopyalandı" "normal" "edit-copy"
	fi
	;;

rf) # Bölgeyi dosyaya kaydet
	create_screenshot_dir
	filename="$SAVE_DIR/$(get_filename)"
	if take_screenshot "$filename"; then
		show_notification "Screenshot" "Kaydedildi: $(basename "$filename")" "normal" "document-save"
	fi
	;;

ri) # Bölgeyi interaktif düzenleme ile al
	create_screenshot_dir
	filename="$SAVE_DIR/$(get_filename)"
	grim -g "$(slurp -b "$BORDER_COLOR" -c "$SELECTION_COLOR" -w "$BORDER_WIDTH")" - |
		"$EDITOR" -f - -o "$filename" &&
		show_notification "Screenshot" "Kaydedildi: $(basename "$filename")" "normal" "document-edit"
	;;

sc) # Ekranın tamamını kopyala
	grim - | wl-copy &&
		show_notification "Screenshot" "Tam ekran panoya kopyalandı" "normal" "edit-copy"
	;;

sf) # Ekranın tamamını dosyaya kaydet
	create_screenshot_dir
	filename="$SAVE_DIR/$(get_filename)"
	grim "$filename" &&
		show_notification "Screenshot" "Tam ekran kaydedildi: $(basename "$filename")" "normal" "document-save"
	;;

si) # Ekranın tamamını interaktif düzenleme ile al
	create_screenshot_dir
	filename="$SAVE_DIR/$(get_filename)"
	grim - | "$EDITOR" -f - -o "$filename" &&
		show_notification "Screenshot" "Kaydedildi: $(basename "$filename")" "normal" "document-edit"
	;;

p) # Renk seçme ve önizleme
	color=$(pick_color)
	if [ -n "$color" ]; then
		echo -n "$color" | wl-copy
		image="/tmp/color_preview_${color//[#\/\\]/}.png"
		magick -size 64x64 xc:"$color" -bordercolor black -border 1 "$image" 2>/dev/null

		if [ -f "$image" ]; then
			show_notification "$color" "Renk panoya kopyalandı" "normal" "$image"
		else
			show_notification "$color" "Renk panoya kopyalandı" "normal" "color-select"
		fi
		rm -f "$image" 2>/dev/null
	else
		show_notification "Hata" "Renk seçilemedi" "critical"
	fi
	;;

o | open) # Son ekran görüntüsünü aç
	open_last_screenshot
	;;

help | --help | -h)
	show_help
	;;

*)
	show_notification "Hata" "Geçersiz seçenek: '$1'. Yardım için '$(basename "$0") help' komutunu kullanın." "critical"
	exit $EXIT_INVALID_OPTION
	;;
esac

exit $EXIT_SUCCESS
