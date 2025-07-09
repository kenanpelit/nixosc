#!/usr/bin/env bash
# cdiff.sh - Varsayılan olarak vimdiff ile clipboard geçmişini karşılaştır

# Varsayılan değerler
NUM_ITEMS=2 # Varsayılan: son 2 öğeyi karşılaştır

# Argümanları işle
while [[ $# -gt 0 ]]; do
	case "$1" in
	-n | --number)
		NUM_ITEMS="$2"
		shift 2
		;;
	--no-vim)
		USE_VIM=false # Vim kullanma
		shift
		;;
	-h | --help)
		echo "Kullanım: $0 [seçenekler]"
		echo "Clipboard geçmişindeki öğeleri karşılaştır"
		echo ""
		echo "Seçenekler:"
		echo "  -n, --number SAYI   Karşılaştırılacak öğe sayısı (varsayılan: 2)"
		echo "  --no-vim            Vimdiff yerine normal diff kullan"
		echo "  -h, --help          Bu yardım mesajını göster"
		exit 0
		;;
	*)
		echo "Bilinmeyen seçenek: $1"
		exit 1
		;;
	esac
done

# Sayı kontrolü
if ! [[ "$NUM_ITEMS" =~ ^[2-9]$ ]]; then
	echo "Hata: Sayı 2 ile 9 arasında olmalı" >&2
	exit 1
fi

# Clipboard öğelerini al
items=()
for ((i = 1; i <= NUM_ITEMS; i++)); do
	item=$(cliphist list | sed -n "${i}p" | cliphist decode)
	if [[ -z "$item" ]]; then
		echo "Hata: Clipboard geçmişinde yeterli öğe yok" >&2
		exit 1
	fi
	items+=("$item")
done

# Geçici dosyalar oluştur
temp_files=()
for ((i = 0; i < NUM_ITEMS; i++)); do
	tf=$(mktemp)
	echo "${items[$i]}" >"$tf"
	temp_files+=("$tf")
done

# Karşılaştırma yap
if [[ "$USE_VIM" != false ]]; then
	nvim -d "${temp_files[@]}"
else
	case $NUM_ITEMS in
	2)
		diff --side-by-side --color=always "${temp_files[0]}" "${temp_files[1]}" | less -R
		;;
	3)
		diff3 --color=always "${temp_files[0]}" "${temp_files[1]}" "${temp_files[2]}" | less -R
		;;
	*)
		echo "Son $NUM_ITEMS öğe gösteriliyor:"
		paste "${temp_files[@]}" | column -t -s $'\t' | less -R
		;;
	esac
fi

# Temizlik
rm -f "${temp_files[@]}"
