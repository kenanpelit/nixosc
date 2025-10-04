#!/usr/bin/env bash
# ==============================================================================
# Rofi Özel Komut Başlatıcı
# ==============================================================================
# Bu script, belirli prefix'lere sahip komutları listeleyip rofi ile çalıştırır.
# - start-* ile başlayan komutlar
# - gnome-* ile başlayan komutlar
# ==============================================================================

# rofi-frecency kontrolü
if ! command -v rofi-frecency &>/dev/null; then
	echo "Uyarı: rofi-frecency bulunamadı. Frekans özelliği çalışmayabilir."
fi

# Tema ve konfigürasyon dosyaları için kontrol
CONFIG_DIR="$HOME/.config/rofi"
THEME_FILE="$CONFIG_DIR/themes/launcher.rasi"

# Özel tema kullanımı (varsa)
THEME_PARAM=""
if [ -f "$THEME_FILE" ]; then
	THEME_PARAM="-theme $THEME_FILE"
fi

# ==============================================================================
# Komutları Toplama
# ==============================================================================

# PATH içindeki tüm dizinleri tara
COMMANDS=""

# /etc/profiles/per-user/kenan/bin dizinini kontrol et
CUSTOM_BIN="/etc/profiles/per-user/kenan/bin"
if [ -d "$CUSTOM_BIN" ]; then
	# start-* ile başlayan komutları ekle
	for cmd in "$CUSTOM_BIN"/start-*; do
		if [ -x "$cmd" ]; then
			COMMANDS+="$(basename "$cmd")"$'\n'
		fi
	done

	# gnome-* ile başlayan komutları ekle
	for cmd in "$CUSTOM_BIN"/gnome-*; do
		if [ -x "$cmd" ]; then
			COMMANDS+="$(basename "$cmd")"$'\n'
		fi
	done
fi

# PATH içindeki diğer dizinleri de tara
IFS=':' read -ra PATHS <<<"$PATH"
for dir in "${PATHS[@]}"; do
	if [ -d "$dir" ]; then
		# start-* komutları
		for cmd in "$dir"/start-*; do
			if [ -x "$cmd" ]; then
				cmdname=$(basename "$cmd")
				# Tekrar eklemeden önce kontrol et
				if ! echo "$COMMANDS" | grep -q "^${cmdname}$"; then
					COMMANDS+="$cmdname"$'\n'
				fi
			fi
		done

		# gnome-* komutları
		for cmd in "$dir"/gnome-*; do
			if [ -x "$cmd" ]; then
				cmdname=$(basename "$cmd")
				# Tekrar eklemeden önce kontrol et
				if ! echo "$COMMANDS" | grep -q "^${cmdname}$"; then
					COMMANDS+="$cmdname"$'\n'
				fi
			fi
		done
	fi
done

# Komutları sırala ve boş satırları kaldır
COMMANDS=$(echo "$COMMANDS" | sort -u | grep -v '^$')

# ==============================================================================
# Rofi ile Göster
# ==============================================================================

if [ -z "$COMMANDS" ]; then
	notify-send "Rofi Launcher" "start-* veya gnome-* ile başlayan komut bulunamadı" -i dialog-warning
	exit 1
fi

SELECTED=$(echo "$COMMANDS" | rofi \
	-dmenu \
	-p "Komut Seç" \
	-i \
	-matching fuzzy \
	-sort \
	-no-custom \
	$THEME_PARAM)

# ==============================================================================
# Seçimi Çalıştır
# ==============================================================================

if [ -n "$SELECTED" ]; then
	# Seçilen komutu frekans listesine ekle (varsa)
	if command -v rofi-frecency &>/dev/null; then
		rofi-frecency --add "$SELECTED"
	fi

	# Seçilen komutu arka planda çalıştır
	$SELECTED >/dev/null 2>&1 &

	# Başlatma durumunu kontrol et
	if [ $? -ne 0 ]; then
		notify-send "Rofi Launcher" "Komut başlatılırken hata oluştu: $SELECTED" -i error
	fi
fi

exit 0
