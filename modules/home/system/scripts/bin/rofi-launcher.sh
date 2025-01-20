# modules/home/scripts/bin/rofi-launcher.sh
#!/usr/bin/env bash

# Cache dizinini tanımla
CACHE_DIR="$HOME/.cache/rofi"
FREQ_FILE="$CACHE_DIR/frequently_used.txt"

# Cache dizinini oluştur
mkdir -p "$CACHE_DIR"
touch "$FREQ_FILE"

if [[ "$1" == "--Keys" ]]; then
	hypr-keybinds | rofi -dmenu -theme-str 'window {width: 50%;} listview {columns: 1;}'
else
	# Sık kullanılanları önce göster
	rofi \
		-show combi \
		-combi-modi 'drun,run,window,filebrowser,ssh' \
		-modi "combi,drun,run,window,filebrowser,Keys:hypr-keybinds,ssh" \
		-show-icons \
		-matching fuzzy \
		-sort \
		-sorting-method "fzf" \
		-drun-use-desktop-cache true \
		-drun-reload-desktop-cache true \
		-drun-cache-file "$CACHE_DIR/drun.cache" \
		-cache-dir "$CACHE_DIR" \
		-disable-history false \
		-history-size 100 \
		-freq-update true
fi
