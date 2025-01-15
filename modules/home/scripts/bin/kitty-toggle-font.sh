#!/usr/bin/env bash

KITTY_CONFIG_DIR="$HOME/.config/kitty"
FONT_CONF="$KITTY_CONFIG_DIR/font.conf"

# Mevcut fontu kontrol et
check_current_font() {
	if [ -L "$FONT_CONF" ] && readlink "$FONT_CONF" | grep -q "jetbrains"; then
		echo "jetbrains"
	else
		echo "hacknerd"
	fi
}

# Fontu değiştir
toggle_font() {
	current_font=$(check_current_font)

	# Mevcut sembolik linki kaldır
	rm -f "$FONT_CONF"

	if [ "$current_font" = "jetbrains" ]; then
		# Hack Nerd Font'a geç
		ln -s "$KITTY_CONFIG_DIR/fonts/hacknerd.conf" "$FONT_CONF"
		echo "Switched to Hack Nerd Font"
	else
		# JetBrains Mono'ya geç
		ln -s "$KITTY_CONFIG_DIR/fonts/jetbrains.conf" "$FONT_CONF"
		echo "Switched to JetBrains Mono"
	fi

	# Kitty'yi yeniden yükle
	killall -SIGUSR1 kitty
}

# Ana script
if [ ! -d "$KITTY_CONFIG_DIR/fonts" ]; then
	echo "Fonts directory not found!"
	exit 1
fi

toggle_font
