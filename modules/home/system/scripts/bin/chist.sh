#!/usr/bin/env bash
# chist.sh - Cliphist Yardımcı Scripti
#
# Kullanım: ./chist.sh [komut]
#
# Komutlar:
#   text       - Metin geçmişini göster ve seçilen metni kopyala
#   preview    - Seçilen resmi swappy ile önizle ve düzenle
#   all        - Tüm geçmişi göster ve seç
#   wipe       - Tüm cliphist veritabanını temizle
#   inspect    - Bir öğenin detaylı bilgilerini göster

# Basit tema ayarı - tek tırnak içinde ve kısa
LAUNCHER="rofi -dmenu -i -theme-str 'window {width: 50%;} listview {columns: 1;}'"
NOTIFY_CMD="notify-send"

# Komut var mı kontrol et
command_exists() {
	command -v "$1" &>/dev/null
}

# ID'yi temizle ve sadece ID değerini al
extract_id() {
	echo "$1" | awk '{print $1}' | tr -d '\n'
}

# Geçici klasör
TEMP_DIR="/tmp/cliphist-helper"
mkdir -p "$TEMP_DIR"

# Ana fonksiyonlar
show_text_history() {
	local selected
	selected=$(cliphist list | grep -v 'binary data' | eval $LAUNCHER -p \"Metin Geçmişi\")
	if [ -n "$selected" ]; then
		id=$(extract_id "$selected")
		cliphist decode "$id" | wl-copy
		$NOTIFY_CMD "Clipboard" "Metin kopyalandı"
	fi
}

show_all_history() {
	local selected
	selected=$(cliphist list | eval $LAUNCHER -p \"Tüm Geçmiş\")
	if [ -n "$selected" ]; then
		id=$(extract_id "$selected")
		cliphist decode "$id" | wl-copy
		$NOTIFY_CMD "Clipboard" "İçerik kopyalandı"
	fi
}

wipe_history() {
	local confirm
	confirm=$(echo -e "Hayır\nEvet" | eval $LAUNCHER -p \"Tüm clipboard geçmişini temizle?\")
	if [ "$confirm" = "Evet" ]; then
		cliphist wipe
		$NOTIFY_CMD "Clipboard" "Geçmiş temizlendi"
	else
		$NOTIFY_CMD "Clipboard" "İşlem iptal edildi"
	fi
}

preview_image() {
	local selected
	selected=$(cliphist list | grep -P '^\d+\s+\[\[\s*binary data .*(jpeg|jpg|png|bmp)' | eval $LAUNCHER -p \"Önizleme için bir resim seçin\")

	if [ -n "$selected" ]; then
		id=$(extract_id "$selected")
		image_file="$TEMP_DIR/preview.png"

		if command_exists "swappy"; then
			cliphist decode "$id" >"$image_file"
			swappy -f "$image_file" -o "$image_file"

			if [ -f "$image_file" ]; then
				cat "$image_file" | wl-copy
				$NOTIFY_CMD "Clipboard" "Düzenlenen resim kopyalandı"
			fi
		elif command_exists "imv"; then
			cliphist decode "$id" >"$image_file"
			imv "$image_file"
			$NOTIFY_CMD "Clipboard" "Görüntü kopyalandı"
		elif command_exists "feh"; then
			cliphist decode "$id" >"$image_file"
			feh "$image_file"
			$NOTIFY_CMD "Clipboard" "Görüntü kopyalandı"
		else
			$NOTIFY_CMD "Clipboard" "Resim görüntüleyici bulunamadı"
		fi
	fi
}

inspect_item() {
	local selected
	selected=$(cliphist list | eval $LAUNCHER -p \"İncelenecek öğeyi seçin\")
	if [ -n "$selected" ]; then
		id=$(extract_id "$selected")
		cliphist decode "$id" >"$TEMP_DIR/content.txt"
		cat "$TEMP_DIR/content.txt" | eval $LAUNCHER -p \"İçerik İnceleme\"
	fi
}

# Komut argümanlarını kontrol et
ACTION="${1:-text}"

case "$ACTION" in
text)
	show_text_history
	;;
preview)
	preview_image
	;;
all)
	show_all_history
	;;
wipe)
	wipe_history
	;;
inspect)
	inspect_item
	;;
help | --help | -h)
	echo "Cliphist Helper - Clipboard Yönetim Aracı"
	echo ""
	echo "Kullanım: $0 [komut]"
	echo ""
	echo "Komutlar:"
	echo "  text     - Metin geçmişini göster"
	echo "  preview  - Swappy ile resim önizle ve düzenle"
	echo "  all      - Tüm geçmişi göster"
	echo "  wipe     - Geçmişi temizle"
	echo "  inspect  - Öğeyi incele"
	echo "  help     - Bu yardım mesajını göster"
	;;
*)
	echo "Bilinmeyen komut: $ACTION"
	echo "Yardım için: $0 help"
	exit 1
	;;
esac

exit 0
