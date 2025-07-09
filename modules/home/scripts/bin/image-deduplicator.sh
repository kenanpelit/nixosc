#!/usr/bin/env bash

show_help() {
	echo "Usage: $0 [OPTION]"
	echo "  -p, --path PATH    Dizin yolu (varsayılan: mevcut dizin)"
	echo "  -d, --debug        Debug bilgileri"
	echo "  -v, --verbose      Detaylı çıktı"
	echo "  -h, --help         Yardım"
}

SEARCH_PATH="."
DEBUG=0
VERBOSE=0

while [ "$1" != "" ]; do
	case $1 in
	-p | --path)
		shift
		SEARCH_PATH=$1
		;;
	-d | --debug)
		DEBUG=1
		;;
	-v | --verbose)
		VERBOSE=1
		;;
	-h | --help)
		show_help
		exit
		;;
	*)
		show_help
		exit 1
		;;
	esac
	shift
done

[ ! -d "$SEARCH_PATH" ] && {
	echo "Hata: '$SEARCH_PATH' dizini bulunamadı"
	exit 1
}

TMP_FILE=$(mktemp)
[ $DEBUG -eq 1 ] && echo "Geçici dosya: $TMP_FILE"

# Tüm görüntü dosyalarını bul
if [ $VERBOSE -eq 1 ]; then
	echo "Görüntü dosyaları aranıyor..."
	echo "Aranan dizin: $SEARCH_PATH"
fi

find "$SEARCH_PATH" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \) | while read -r file; do
	if [ $VERBOSE -eq 1 ]; then
		echo "İşleniyor: $file"
		echo "Dosya boyutu: $(stat -f %z "$file") bytes"
	fi
	md5sum "$file"
done | sort >"$TMP_FILE"

if [ $VERBOSE -eq 1 ]; then
	echo "Bulunan toplam dosya sayısı: $(wc -l <"$TMP_FILE")"
	echo "MD5 hash'leri hesaplandı"
fi

declare -A SEEN
FOUND_DUPLICATES=0

while IFS=' ' read -r hash file; do
	if [ -n "${SEEN[$hash]}" ]; then
		FOUND_DUPLICATES=1
		echo -e "\nDuplicate bulundu:"
		echo "1: ${SEEN[$hash]}"
		echo "2: $file"
		if [ $VERBOSE -eq 1 ]; then
			echo "MD5 hash: $hash"
			echo "1. dosya boyutu: $(stat -f %z "${SEEN[$hash]}") bytes"
			echo "2. dosya boyutu: $(stat -f %z "$file") bytes"
		fi
		read -p "2 numaralı dosya silinsin mi? (e/h): " answer
		if [ "$answer" = "e" ]; then
			rm -v "$file"
		fi
	else
		SEEN[$hash]="$file"
	fi
done <"$TMP_FILE"

[ $FOUND_DUPLICATES -eq 0 ] && echo "Duplicate dosya bulunamadı."
[ $DEBUG -eq 1 ] && echo "Geçici dosya siliniyor: $TMP_FILE"
rm "$TMP_FILE"
