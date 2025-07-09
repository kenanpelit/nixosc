#!/usr/bin/env bash
# chist.sh - Gelişmiş Clipboard Yönetim Aracı (fzf + rofi + vimdiff)

# Bağımlılık kontrolü
command_exists() {
	command -v "$1" &>/dev/null
}

for cmd in cliphist wl-copy; do
	if ! command_exists "$cmd"; then
		echo "Hata: $cmd bulunamadı!" >&2
		exit 1
	fi
done

# Pager seçimi (Hyprland için otomatik algılama)
if [[ -n "$HYPRLAND_INSTANCE_SIGNATURE" ]] && command_exists "rofi"; then
	PAGER="rofi -dmenu -i -theme-str 'window {width: 50%;}' -theme-str 'listview {columns: 1;}'"
elif [[ -t 1 ]] && command_exists "fzf"; then
	PAGER="fzf --height 40% --reverse"
elif command_exists "rofi"; then
	PAGER="rofi -dmenu -i"
else
	command_exists "fzf" && PAGER="fzf" || {
		echo "Hata: Ne fzf ne de rofi bulunamadı!" >&2
		exit 1
	}
fi

NOTIFY_CMD="notify-send"
TEMP_DIR="/tmp/cliphist-$(date +%s)"
mkdir -p "$TEMP_DIR"
trap 'rm -rf "$TEMP_DIR"' EXIT

# Yardımcı fonksiyonlar
extract_id() {
	awk '{print $1}' <<<"$1" | tr -d '\n'
}

select_item() {
	local prompt="$1" items="$2"
	case "$PAGER" in
	rofi*) echo "$items" | eval "$PAGER -p \"$prompt\"" ;;
	fzf*) echo "$items" | eval "$PAGER --prompt=\"$prompt > \"" ;;
	esac
}

# İşlevler
text_history() {
	local selected=$(select_item "Metin Geçmişi" "$(cliphist list | grep -v 'binary data')")
	[[ -n "$selected" ]] || return
	cliphist decode $(extract_id "$selected") | wl-copy
	$NOTIFY_CMD "Clipboard" "Metin kopyalandı"
}

full_history() {
	local selected=$(select_item "Tüm Geçmiş" "$(cliphist list)")
	[[ -n "$selected" ]] || return
	cliphist decode $(extract_id "$selected") | wl-copy
	$NOTIFY_CMD "Clipboard" "İçerik kopyalandı"
}

image_preview() {
	local selected=$(select_item "Resimler" "$(cliphist list | grep -P 'binary data.*(jpeg|jpg|png|bmp)')")
	[[ -n "$selected" ]] || return

	local img="$TEMP_DIR/preview-$(date +%s).png"
	cliphist decode $(extract_id "$selected") >"$img" || return

	if command_exists "swappy"; then
		swappy -f "$img" -o "$img" && [[ -f "$img" ]] && {
			cat "$img" | wl-copy
			$NOTIFY_CMD "Clipboard" "Resim kopyalandı"
		}
	elif command_exists "imv"; then
		imv "$img"
	elif command_exists "feh"; then
		feh "$img"
	else
		$NOTIFY_CMD "Hata" "Görüntüleyici bulunamadı"
	fi
}

wipe_history() {
	local confirm
	if [ "$PAGER" = "fzf" ]; then
		confirm=$(echo -e "Hayır\nEvet" | fzf --prompt="Geçmişi temizle? " --height=20%)
	else
		confirm=$(echo -e "Hayır\nEvet" | eval "$PAGER -p \"Geçmişi temizle?\"")
	fi

	[[ "$confirm" == "Evet" ]] && {
		cliphist wipe
		$NOTIFY_CMD "Clipboard" "Geçmiş temizlendi"
	} || $NOTIFY_CMD "Clipboard" "İşlem iptal edildi"
}

fzf_search() {
	local selected=$(cliphist list | fzf --height 50% --reverse \
		--preview "cliphist decode {1}" --preview-window right:50%:wrap)
	[[ -n "$selected" ]] || return
	cliphist decode $(extract_id "$selected") | wl-copy
	$NOTIFY_CMD "Clipboard" "İçerik kopyalandı"
}

inspect_item() {
	local selected=$(select_item "İncele" "$(cliphist list)")
	[[ -n "$selected" ]] || return

	local id=$(extract_id "$selected")
	local content=$(cliphist decode "$id")
	local temp_file="$TEMP_DIR/inspect-$(date +%s).txt"

	echo "$content" >"$temp_file"
	nvim "$temp_file"
}

clipdiff() {
	local selected=$(select_item "Karşılaştır" "$(cliphist list | head -n 2)")
	[[ -n "$selected" ]] || return

	local id1=$(extract_id "$(cliphist list | sed -n 1p)")
	local id2=$(extract_id "$(cliphist list | sed -n 2p)")
	local file1="$TEMP_DIR/diff1-$(date +%s).txt"
	local file2="$TEMP_DIR/diff2-$(date +%s).txt"

	cliphist decode "$id1" >"$file1"
	cliphist decode "$id2" >"$file2"
	nvim -d "$file1" "$file2"
}

# Ana yönlendirme
case "${1:-text}" in
text) text_history ;;
all) full_history ;;
preview) image_preview ;;
wipe) wipe_history ;;
search) fzf_search ;;
inspect) inspect_item ;;
diff) clipdiff ;;
help | --help | -h)
	echo "Kullanım: $0 [komut]"
	echo "Komutlar:"
	echo "  text     - Metin geçmişi"
	echo "  all      - Tüm geçmiş"
	echo "  preview  - Resim önizleme"
	echo "  wipe     - Geçmişi temizle"
	echo "  search   - fzf ile arama"
	echo "  inspect  - Öğeyi incele"
	echo "  diff     - Son 2 öğeyi karşılaştır"
	exit 0
	;;
*)
	echo "Geçersiz komut: $1" >&2
	echo "Yardım için: $0 help" >&2
	exit 1
	;;
esac
