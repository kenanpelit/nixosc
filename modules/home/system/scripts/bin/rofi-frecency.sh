# modules/home/scripts/bin/rofi-frecency
#!/usr/bin/env bash

CACHE_FILE="$HOME/.cache/rofi/frecency.txt"
mkdir -p "$(dirname "$CACHE_FILE")"
touch "$CACHE_FILE"

if [[ $1 == "--add" && -n $2 ]]; then
	# Yeni giriş ekle veya var olanı güncelle
	ENTRY="$2"
	COUNT=$(grep "^$ENTRY:" "$CACHE_FILE" | cut -d: -f2 || echo 0)
	COUNT=$((COUNT + 1))
	grep -v "^$ENTRY:" "$CACHE_FILE" >"$CACHE_FILE.tmp"
	echo "$ENTRY:$COUNT" >>"$CACHE_FILE.tmp"
	sort -t: -k2 -nr "$CACHE_FILE.tmp" >"$CACHE_FILE"
	rm "$CACHE_FILE.tmp"
elif [[ $1 == "--list" ]]; then
	# Sıralanmış listeyi göster
	cut -d: -f1 "$CACHE_FILE"
fi
