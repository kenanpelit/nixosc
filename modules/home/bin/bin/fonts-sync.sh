#!/bin/bash

# Kullanım kontrolü
if [ "$#" -ne 2 ]; then
	echo "Kullanım: $0 <birinci_dizin> <ikinci_dizin>"
	echo "Örnek: $0 /usr/share/fonts /home/user/.local/share/fonts"
	exit 1
fi

DIR1="$1"
DIR2="$2"

# Dizinlerin varlığını kontrol et
if [ ! -d "$DIR1" ] || [ ! -d "$DIR2" ]; then
	echo "Hata: Dizinlerden biri veya her ikisi mevcut değil!"
	exit 1
fi

# Geçici dosyalar için dizin oluştur
TEMP_DIR=$(mktemp -d)
FONTS1="$TEMP_DIR/fonts1.txt"
FONTS2="$TEMP_DIR/fonts2.txt"
DUPLICATES="$TEMP_DIR/duplicates.txt"

echo "Font dosyaları taranıyor..."

# Her iki dizindeki fontları listele (tam yol ve dosya adı olarak)
find "$DIR1" -type f \( -name "*.ttf" -o -name "*.otf" \) -exec basename {} \; | sort >"$FONTS1"
find "$DIR2" -type f \( -name "*.ttf" -o -name "*.otf" \) -exec basename {} \; | sort >"$FONTS2"

# Ortak fontları bul
comm -12 "$FONTS1" "$FONTS2" >"$DUPLICATES"

# Yedek dizini oluştur
BACKUP_DIR="$HOME/font_backups/$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

# Ortak fontları ikinci dizinden sil
DUPLICATE_COUNT=0
while IFS= read -r font; do
	# İkinci dizinde fontu bul
	find "$DIR2" -type f -name "$font" | while read -r font_path; do
		# Yedekle ve sil
		echo "Yedekleniyor ve siliniyor: $font_path"
		cp "$font_path" "$BACKUP_DIR/"
		rm "$font_path"
		((DUPLICATE_COUNT++))
	done
done <"$DUPLICATES"

# Boş dizinleri temizle
find "$DIR2" -type d -empty -delete

echo "İşlem tamamlandı!"
echo "Toplam $DUPLICATE_COUNT adet çift font dosyası temizlendi."
echo "Yedekler şurada: $BACKUP_DIR"

# Geçici dosyaları temizle
rm -rf "$TEMP_DIR"

# Font önbelleğini yenile
if command -v fc-cache >/dev/null 2>&1; then
	echo "Font önbelleği yenileniyor..."
	fc-cache -f
fi
