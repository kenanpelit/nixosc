#!/usr/bin/env bash

# Shader dosya yolu
SHADER_PATH="$HOME/.config/hypr/shaders"
KENP_SHADER="$SHADER_PATH/kenp-blue-light-filter.glsl"
TOGGLE_FILE="/tmp/.hyprshade_active"

# Shader dosyasının var olup olmadığını kontrol et
if [ ! -f "$KENP_SHADER" ]; then
	notify-send -t 2000 -u critical "Hyprshade Hatası" "Kenp shader dosyası bulunamadı!"
	echo "Kenp shader dosyası bulunamadı: $KENP_SHADER"
	exit 1
fi

# Hyprshade'in aktif olup olmadığını kontrol et
if [ -f "$TOGGLE_FILE" ]; then
	# Eğer aktifse kapat
	hyprshade off
	rm -f "$TOGGLE_FILE"
	notify-send -t 1000 -u low "Hyprshade Kapatıldı" "Kenp Blue Light Filter devre dışı"
	echo "Kenp Blue Light Filter devre dışı bırakıldı."
else
	# Eğer aktif değilse başlat
	hyprshade on "$KENP_SHADER"
	touch "$TOGGLE_FILE"
	notify-send -t 1000 -u low "Hyprshade Açıldı" "Kenp Blue Light Filter aktif"
	echo "Kenp Blue Light Filter etkinleştirildi."
fi
