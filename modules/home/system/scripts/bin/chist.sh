#!/usr/bin/env bash
# chist.sh - Cliphist Yardımcı Scripti (fzf entegrasyonlu)

# Bağımlılık kontrolü
command_exists() {
	command -v "$1" &>/dev/null
}

for cmd in cliphist wl-copy notify-send; do
	if ! command_exists "$cmd"; then
		echo "Hata: $cmd bulunamadı!" >&2
		exit 1
	fi
done

# Pager seçimi (fzf veya rofi)
if command_exists "fzf"; then
	PAGER="fzf"
elif command_exists "rofi"; then
	PAGER="rofi -dmenu -i -theme-str 'window {width: 50%;}' -theme-str 'listview {columns: 1;}'"
else
	echo "Hata: Ne fzf ne de rofi bulunamadı!" >&2
	exit 1
fi

NOTIFY_CMD="notify-send"

# ID'yi temizle
extract_id() {
	echo "$1" | awk '{print $1}' | tr -d '\n'
}

# Geçici klasör
TEMP_DIR="/tmp/cliphist-$(date +%s)"
mkdir -p "$TEMP_DIR"
trap 'rm -rf "$TEMP_DIR"' EXIT

# Seçim yapma fonksiyonu (fzf/rofi uyumlu)
select_item() {
	local prompt="$1"
	local items="$2"

	if [ "$PAGER" = "fzf" ]; then
		echo "$items" | fzf --prompt="$prompt " --height=40% --reverse
	else
		echo "$items" | eval "$PAGER -p \"$prompt\""
	fi
}

# Ana fonksiyonlar
show_text_history() {
	local selected id
	selected=$(select_item "Metin Geçmişi" "$(cliphist list | grep -v 'binary data')")
	[ -n "$selected" ] || return
	id=$(extract_id "$selected")
	cliphist decode "$id" | wl-copy || $NOTIFY_CMD "Hata" "Kopyalama başarısız"
	$NOTIFY_CMD "Clipboard" "Metin kopyalandı"
}

show_all_history() {
	local selected id
	selected=$(select_item "Tüm Geçmiş" "$(cliphist list)")
	[ -n "$selected" ] || return
	id=$(extract_id "$selected")
	cliphist decode "$id" | wl-copy || $NOTIFY_CMD "Hata" "Kopyalama başarısız"
	$NOTIFY_CMD "Clipboard" "İçerik kopyalandı"
}

wipe_history() {
	local confirm
	if [ "$PAGER" = "fzf" ]; then
		confirm=$(echo -e "Hayır\nEvet" | fzf --prompt="Tüm geçmişi silmek istiyor musunuz? " --height=20%)
	else
		confirm=$(echo -e "Hayır\nEvet" | eval "$PAGER -p \"Tüm geçmişi sil?\"")
	fi

	[ "$confirm" = "Evet" ] || {
		$NOTIFY_CMD "Clipboard" "İşlem iptal edildi"
		return
	}
	cliphist wipe && $NOTIFY_CMD "Clipboard" "Geçmiş temizlendi"
}

preview_image() {
	local selected id image_file
	selected=$(select_item "Resim Seç" "$(cliphist list | grep -P 'binary data.*(jpeg|jpg|png|bmp)')")
	[ -n "$selected" ] || return

	id=$(extract_id "$selected")
	image_file="$TEMP_DIR/preview-$(date +%s).png"

	cliphist decode "$id" >"$image_file" || {
		$NOTIFY_CMD "Hata" "Resim oluşturulamadı"
		return 1
	}

	if command_exists "swappy"; then
		swappy -f "$image_file" -o "$image_file" && [ -f "$image_file" ] && {
			cat "$image_file" | wl-copy
			$NOTIFY_CMD "Clipboard" "Resim kopyalandı"
		}
	elif command_exists "imv"; then
		imv "$image_file"
	elif command_exists "feh"; then
		feh "$image_file"
	else
		$NOTIFY_CMD "Hata" "Görüntüleyici bulunamadı"
	fi
}

# fzf özel fonksiyonu
fzf_search() {
	local selected id
	selected=$(cliphist list | fzf --prompt="Ara: " --height=50% --reverse --preview "cliphist decode {1}" --preview-window=right:50%:wrap)
	[ -n "$selected" ] || return
	id=$(extract_id "$selected")
	cliphist decode "$id" | wl-copy || $NOTIFY_CMD "Hata" "Kopyalama başarısız"
	$NOTIFY_CMD "Clipboard" "İçerik kopyalandı"
}

# Komut seçimi
case "${1:-text}" in
text) show_text_history ;;
preview) preview_image ;;
all) show_all_history ;;
wipe) wipe_history ;;
search) fzf_search ;;
*) echo "Kullanım: $0 [text|preview|all|wipe|search]" >&2 ;;
esac
