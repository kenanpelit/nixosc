#!/usr/bin/env bash

#######################################
#
# Version: 1.3.0
# Date: 2025-04-26
# Author: Kenan Pelit
# Repository: github.com/kenanpelit/dotfiles
# Description: HyprFlow - Gelişmiş Ekran Görüntüsü Aracı
#
# License: MIT
#
#######################################

# Yapılandırma Ayarları
SAVE_DIR="$HOME/Pictures/screenshots" # Yazım hatası düzeltildi: ssreenshots -> screenshots
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

	# Temel bağımlılıklar
	for cmd in grim slurp wl-copy notify-send; do
		if ! command -v "$cmd" &>/dev/null; then
			missing_deps+=("$cmd")
		fi
	done

	# Düzenleyici kontrolü
	if [ "$EDITOR" = "none" ]; then
		missing_deps+=("swappy/satty")
	fi

	# ImageMagick kontrolü (magick veya convert)
	if ! command -v magick &>/dev/null; then
		if ! command -v convert &>/dev/null; then
			missing_deps+=("imagemagick")
		else
			# convert mevcut, magick alias'ını tanımla
			magick() {
				convert "$@"
			}
			export -f magick
		fi
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
│       HyprFlow Screenshot Tool     │
│             Sürüm 1.3.0            │
╰────────────────────────────────────╯

Kullanım: $(basename "$0") [SEÇENEK]

BÖLGE KOMUTLARI:
  rc    Bölge Kopyala      - Seçilen bölgeyi panoya kopyalar
  rf    Bölge Dosya        - Seçilen bölgeyi dosyaya kaydeder
  ri    Bölge Interaktif   - Seçilen bölgeyi düzenleyicide açar
  rec   Bölge Edit+Kopyala - Seçilen bölgeyi düzenle ve panoya kopyala

EKRAN KOMUTLARI:
  sc    Ekran Kopyala      - Tüm ekranı panoya kopyalar
  sf    Ekran Dosya        - Tüm ekranı dosyaya kaydeder
  si    Ekran Interaktif   - Tüm ekranı düzenleyicide açar
  sec   Ekran Edit+Kopyala - Tüm ekranı düzenle ve panoya kopyala

PENCERE KOMUTLARI:
  wc    Pencere Kopyala    - Aktif pencereyi panoya kopyalar
  wf    Pencere Dosya      - Aktif pencereyi dosyaya kaydeder
  wi    Pencere Interaktif - Aktif pencereyi düzenleyicide açar

DİĞER KOMUTLARI:
  p     Renk Seç           - Ekrandan renk seçer ve panoya kopyalar
  o     Aç                 - Son ekran görüntüsünü açar
  d     Dizin Aç           - Ekran görüntüleri dizinini açar
  help  Yardım             - Bu yardım mesajını gösterir

ÖRNEKLER:
  $(basename "$0") rc    # Seçilen alanı panoya kopyalar
  $(basename "$0") sf    # Tüm ekranı dosyaya kaydeder
  $(basename "$0") p     # Renk seçer
  $(basename "$0") wi    # Aktif pencereyi düzenleyicide açar

NOTLAR:
- Kayıt dizini: $SAVE_DIR
- Kullanılan düzenleyici: $EDITOR
- Dosya formatı: $FILENAME_FORMAT

Geliştiren: Kenan Pelit
EOF
}

# Aktif pencere screenshot alma fonksiyonu
take_active_window_screenshot() {
	local filename="$1"
	local success=false
	local active_window

	# Hyprland aktif pencere ID'sini al
	if command -v hyprctl &>/dev/null; then
		active_window=$(hyprctl activewindow -j | jq -r '"\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"')
		if [ -n "$active_window" ] && [ "$active_window" != "null" ]; then
			grim -g "$active_window" "$filename" && success=true
		else
			show_notification "Hata" "Aktif pencere bulunamadı" "critical"
			return 1
		fi
	# Sway aktif pencere ID'sini al
	elif command -v swaymsg &>/dev/null; then
		active_window=$(swaymsg -t get_tree | jq -r '.. | select(.focused?) | .rect | "\(.x),\(.y) \(.width)x\(.height)"')
		if [ -n "$active_window" ] && [ "$active_window" != "null" ]; then
			grim -g "$active_window" "$filename" && success=true
		else
			show_notification "Hata" "Aktif pencere bulunamadı" "critical"
			return 1
		fi
	else
		show_notification "Hata" "Hyprland veya Sway bulunamadı" "critical"
		return 1
	fi

	if [ "$success" = true ]; then
		return $EXIT_SUCCESS
	else
		show_notification "Hata" "Pencere görüntüsü alınamadı" "critical"
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

	# SwayNC için özel bildirim süresi parametreleri ve standart parametre
	notify-send -h string:x-canonical-private-synchronous:hyprflow-screenshot \
		-h int:transient:1 \
		-h int:expire-time:2000 \
		-t 2000 \
		-u "$urgency" -i "$icon" "$title" "$message"
}

# Screenshot alma fonksiyonu
take_screenshot() {
	local filename="$1"

	# Çıktıyı yakalayarak slurp komutunu çalıştır
	local slurp_output
	slurp_output=$(slurp -b "$BORDER_COLOR" -c "$SELECTION_COLOR" -w "$BORDER_WIDTH" 2>&1)

	# Slurp'un çıkış kodunu kontrol et
	if [ $? -ne 0 ]; then
		# Slurp başarısız olduysa (ESC ile çıkış veya başka bir iptal durumu)
		# Hiçbir bildirim gösterme ve sessizce çık
		return $EXIT_CANCELLED
	fi

	# Slurp başarılı olduysa, grim ile ekran görüntüsü al
	if grim -g "$slurp_output" "$filename"; then
		return $EXIT_SUCCESS
	else
		show_notification "Hata" "Ekran görüntüsü alınamadı" "critical"
		return 1
	fi
}

# Renk seçme fonksiyonu - İyileştirilmiş sürüm
pick_color() {
	local color
	local slurp_output

	# Renk seçme - İptal edilme durumunu işle
	slurp_output=$(slurp -p -b '#00000000' -c "$COLOR_PICKER_BORDER" -w "$BORDER_WIDTH" 2>&1)

	# Slurp'un çıkış kodunu kontrol et
	if [ $? -ne 0 ]; then
		# İptal edildi, sessizce çık
		return $EXIT_CANCELLED
	fi

	# Renk seçimi başarılıysa grim ile görüntü al
	color=$(echo "$slurp_output" | grim -g - -t ppm - 2>/dev/null)

	if [ $? -ne 0 ]; then
		return 1
	fi

	# ImageMagick ile renk değerini çıkarma
	if command -v magick &>/dev/null; then
		color=$(echo "$color" | magick - -format '%[pixel:p{0,0}]' txt:- 2>/dev/null | tail -n1 | cut -d' ' -f4)
	elif command -v convert &>/dev/null; then
		color=$(echo "$color" | convert - -format '%[pixel:p{0,0}]' txt:- 2>/dev/null | tail -n1 | cut -d' ' -f4)
	else
		show_notification "Hata" "ImageMagick bulunamadı, renk seçimi yapılamıyor" "critical"
		return 1
	fi

	echo "$color"
}

# Görüntüyü düzenleyici ile açma fonksiyonu
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
		show_notification "Düzenleyici" "$EDITOR ile açıldı. Kaydetmeyi unutmayın."
		;;
	*)
		show_notification "Hata" "Desteklenen düzenleyici bulunamadı" "critical"
		return 1
		;;
	esac
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

# Ekran görüntüleri dizinini açma fonksiyonu
open_screenshots_dir() {
	if [ -d "$SAVE_DIR" ]; then
		xdg-open "$SAVE_DIR" &
		show_notification "Dizin Açıldı" "$SAVE_DIR"
	else
		create_screenshot_dir
		xdg-open "$SAVE_DIR" &
		show_notification "Dizin Açıldı" "$SAVE_DIR"
	fi
}

# Geçici dosyaları temizle
cleanup_temp_files() {
	find "$TEMP_DIR" -type f -mtime +1 -name "hyprflow_*.png" -exec rm {} \;
}

# Bağımlılıkları kontrol et ve geçici dizini oluştur
check_dependencies
create_temp_dir
cleanup_temp_files

# Ana işlem kontrolü
case $1 in
rc) # Bölgeyi kopyala
	temp_file=$(mktemp "$TEMP_DIR/hyprflow_XXXXXX.png")
	if take_screenshot "$temp_file"; then
		cat "$temp_file" | wl-copy
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
	temp_file=$(mktemp "$TEMP_DIR/hyprflow_XXXXXX.png")
	filename="$SAVE_DIR/$(get_filename)"

	if take_screenshot "$temp_file"; then
		if open_in_editor "$temp_file" "$filename"; then
			show_notification "Screenshot" "Kaydedildi: $(basename "$filename")" "normal" "document-edit"
		fi
	fi
	;;

rec) # Bölgeyi düzenle ve kopyala
	create_screenshot_dir
	temp_file=$(mktemp "$TEMP_DIR/hyprflow_XXXXXX.png")
	filename="$SAVE_DIR/$(get_filename)"

	if take_screenshot "$temp_file"; then
		# Kopyalama işlemi
		cat "$temp_file" | wl-copy
		show_notification "Screenshot" "Panoya kopyalandı" "normal" "edit-copy"

		# Düzenleme işlemi
		if open_in_editor "$temp_file" "$filename"; then
			show_notification "Screenshot" "Düzenlenmiş görüntü kaydedildi: $(basename "$filename")" "normal" "document-edit"
		fi
	fi
	;;

sc) # Ekranın tamamını kopyala
	temp_file=$(mktemp "$TEMP_DIR/hyprflow_XXXXXX.png")
	grim "$temp_file" && cat "$temp_file" | wl-copy &&
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
	temp_file=$(mktemp "$TEMP_DIR/hyprflow_XXXXXX.png")
	filename="$SAVE_DIR/$(get_filename)"

	if grim "$temp_file"; then
		if open_in_editor "$temp_file" "$filename"; then
			show_notification "Screenshot" "Düzenlenmiş tam ekran kaydedildi: $(basename "$filename")" "normal" "document-edit"
		fi
	fi
	;;

sec) # Ekranı düzenle ve kopyala
	create_screenshot_dir
	temp_file=$(mktemp "$TEMP_DIR/hyprflow_XXXXXX.png")
	filename="$SAVE_DIR/$(get_filename)"

	if grim "$temp_file"; then
		# Kopyalama işlemi
		cat "$temp_file" | wl-copy
		show_notification "Screenshot" "Tam ekran panoya kopyalandı" "normal" "edit-copy"

		# Düzenleme işlemi
		if open_in_editor "$temp_file" "$filename"; then
			show_notification "Screenshot" "Düzenlenmiş tam ekran kaydedildi: $(basename "$filename")" "normal" "document-edit"
		fi
	fi
	;;

wc) # Aktif pencereyi kopyala
	temp_file=$(mktemp "$TEMP_DIR/hyprflow_XXXXXX.png")
	if take_active_window_screenshot "$temp_file"; then
		cat "$temp_file" | wl-copy
		show_notification "Screenshot" "Aktif pencere panoya kopyalandı" "normal" "edit-copy"
	fi
	;;

wf) # Aktif pencereyi dosyaya kaydet
	create_screenshot_dir
	filename="$SAVE_DIR/$(get_filename)"
	if take_active_window_screenshot "$filename"; then
		show_notification "Screenshot" "Aktif pencere kaydedildi: $(basename "$filename")" "normal" "document-save"
	fi
	;;

wi) # Aktif pencereyi interaktif düzenleme ile al
	create_screenshot_dir
	temp_file=$(mktemp "$TEMP_DIR/hyprflow_XXXXXX.png")
	filename="$SAVE_DIR/$(get_filename)"

	if take_active_window_screenshot "$temp_file"; then
		if open_in_editor "$temp_file" "$filename"; then
			show_notification "Screenshot" "Düzenlenmiş pencere kaydedildi: $(basename "$filename")" "normal" "document-edit"
		fi
	fi
	;;

p) # Renk seçme ve önizleme
	color=$(pick_color)

	# İptal edilmişse sessizce çık
	if [ $? -eq $EXIT_CANCELLED ]; then
		exit $EXIT_SUCCESS
	fi

	if [ -n "$color" ]; then
		echo -n "$color" | wl-copy
		image="$TEMP_DIR/color_preview_${color//[#\/\\]/}.png"

		# Renk önizleme görüntüsü oluştur
		if command -v magick &>/dev/null; then
			magick -size 64x64 xc:"$color" -bordercolor black -border 1 "$image" 2>/dev/null
		elif command -v convert &>/dev/null; then
			convert -size 64x64 xc:"$color" -bordercolor black -border 1 "$image" 2>/dev/null
		else
			# ImageMagick yoksa önizleme olmadan bildirim göster
			show_notification "$color" "Renk panoya kopyalandı" "normal" "color-select"
			exit $EXIT_SUCCESS
		fi

		if [ -f "$image" ]; then
			show_notification "$color" "Renk panoya kopyalandı" "normal" "$image"
		else
			show_notification "$color" "Renk panoya kopyalandı" "normal" "color-select"
		fi
	else
		show_notification "Hata" "Renk seçilemedi" "critical"
	fi
	;;

o | open) # Son ekran görüntüsünü aç
	open_last_screenshot
	;;

d | dir) # Ekran görüntüleri dizinini aç
	open_screenshots_dir
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
