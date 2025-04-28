#!/usr/bin/env bash
#===============================================================================
#
#   Script: vv - Günlük Not Alma Aracı
#   Version: 1.0.0
#   Date: 2025-04-28
#   Author: Kenan Pelit
#   Description: Otomatik numaralandırma ile günlük not tutma aracı
#
#   Features:
#   - Tarih bazlı otomatik dosya numaralandırma
#   - fzf ile hızlı dosya seçimi
#   - Vim entegrasyonu ile kolay düzenleme
#
#   License: MIT
#
#===============================================================================

# Yardım metni görüntüleme fonksiyonu
show_help() {
	echo "Kullanım: vv [SEÇENEK]"
	echo
	echo "Seçenekler:"
	echo "  -h, --help     Bu yardım metnini göster"
	echo "  [DOSYA]        Belirtilen dosyayı aç (belirtilmezse otomatik numara verilir)"
	echo
	echo "Açıklama:"
	echo "  vv, ~/Tmp/vv/ dizininde otomatik olarak numaralandırılmış günlük notlar"
	echo "  oluşturmak ve düzenlemek için kullanılan bir araçtır."
	echo "  Komut parametresiz kullanıldığında bugünün tarihiyle yeni bir not dosyası oluşturur"
	echo "  veya mevcut dosyalardan fzf ile seçim yapmanızı sağlar."
	echo
}

# Parametreleri kontrol et
if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
	show_help
	exit 0
fi

# Tmp dizininin varlığını kontrol et, yoksa oluştur
VV_DIR="$HOME/Tmp/vv"
if [ ! -d "$VV_DIR" ]; then
	mkdir -p "$VV_DIR"
fi

# Bugünün tarihini al
TODAY=$(date +'%Y%m%d')

# Parametre kontrolü
if [ -z "$1" ]; then
	# Parametre yoksa fzf ile dosya seçimi sunalım
	if command -v fzf >/dev/null 2>&1; then
		SELECTED_FILE=$(find "$VV_DIR" -type f | sort -r | fzf --reverse --preview 'cat {}' --prompt="Düzenlemek için dosya seçin: ")

		if [ -n "$SELECTED_FILE" ]; then
			# Dosya seçildiyse düzenlemeye aç
			vim -c "set paste" "$SELECTED_FILE"
			exit 0
		fi
	else
		echo "fzf bulunamadı. Yeni dosya oluşturuluyor."
	fi

	# Seçim yapılmadıysa yeni dosya oluştur
	NEXT_NUM="01"

	# Bugüne ait son dosyayı bul ve bir sonraki numarayı hesapla
	LAST_FILE=$(find "$VV_DIR" -type f -name "[0-9][0-9]_$TODAY.txt" 2>/dev/null | sort -r | head -n 1)

	if [ -n "$LAST_FILE" ]; then
		# Son dosyadan numarayı çıkar ve bir artır
		LAST_NUM=$(basename "$LAST_FILE" | cut -d'_' -f1)
		NEXT_NUM=$(printf "%02d" $((10#$LAST_NUM + 1)))
	fi

	# Yeni dosyayı oluştur
	NEW_FILE="$VV_DIR/${NEXT_NUM}_${TODAY}.txt"
	touch "$NEW_FILE"
	chmod 755 "$NEW_FILE"

	# Vim ile düzenlemeye aç
	vim -c "set paste" "$NEW_FILE"
else
	# Özel dosya adı verilmişse doğrudan onu kullan
	FILE_PATH="$VV_DIR/$1"
	[ ! -f "$FILE_PATH" ] && touch "$FILE_PATH"
	chmod 755 "$FILE_PATH"
	vim -c "set paste" "$FILE_PATH"
fi
