#!/usr/bin/env bash
#===============================================================================
#
#   Script: OSC HyprFlow Audio Switcher
#   Version: 1.0.0
#   Date: 2024-01-23
#   Author: Kenan Pelit
#   Repository: https://github.com/kenanpelit/nixosc
#   Description: Advanced audio output switcher for Hyprland with PulseAudio
#                integration and architecture-aware library handling
#
#   Features:
#   - Dynamic sink detection and switching
#   - Architecture-aware library path handling
#   - PulseAudio environment configuration
#   - Desktop notifications
#   - Automatic sink input migration
#   - Colored terminal output
#   - Volume and microphone control
#
#   License: MIT
#
#===============================================================================

# Renk tanımları
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
BLUE=$(tput setaf 4)
CYAN=$(tput setaf 6)
RESET=$(tput sgr0)

# Debug modu
DEBUG=false

# Debug fonksiyonu
debug_print() {
	if [ "$DEBUG" = true ]; then
		echo
		echo "${BLUE}=========================================${RESET}"
		echo "${CYAN} $1 ${RESET}"
		echo "${BLUE}=========================================${RESET}"
		shift
		echo "${GREEN}$@${RESET}"
	fi
}

# Argümanları kontrol et
for arg in "$@"; do
	if [ "$arg" = "-d" ] || [ "$arg" = "--debug" ]; then
		DEBUG=true
		# Argümanı kaldır
		set -- "${@/$arg/}"
	fi
done

# Mimari
case "$SNAP_ARCH" in
"amd64") ARCH="x86_64-linux-gnu" ;;
"armhf") ARCH="arm-linux-gnueabihf" ;;
"arm64") ARCH="aarch64-linux-gnu" ;;
*) ARCH="$SNAP_ARCH-linux-gnu" ;;
esac

debug_print "Mimari Tespit Ediliyor" "$ARCH"

# Pulseaudio ayarları
export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:$SNAP/usr/lib/$ARCH/pulseaudio"
export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:$SNAP/lib/$ARCH"
debug_print "Pulseaudio Ortam Değişkenleri" "$LD_LIBRARY_PATH"

# Ses çıkışları
SINKS=($(pactl list sinks short | awk '{print $1}'))
RUNNING_SINK=$(pactl list sinks short | grep RUNNING | awk '{print $1}')
INPUTS=($(pactl list sink-inputs short | awk '{print $1}'))
SINKS_COUNT=${#SINKS[@]}
debug_print "Ses Çıkışları" "Toplam: $SINKS_COUNT"

# Çalışan ses çıkışını bul
for i in "${!SINKS[@]}"; do
	if [[ ${SINKS[$i]} == "$RUNNING_SINK" ]]; then
		SINK_INDEX=$i
		break
	fi
done

# Ses çıkışı değiştirme
switch_sink() {
	local target_sink=$1
	pactl set-default-sink "$target_sink"
	for input in "${INPUTS[@]}"; do
		pactl move-sink-input "$input" "$target_sink"
	done
	local sink_name=$(pactl list sinks | awk -v sink_name="$target_sink" '
    $1 == "Sink" && $2 == "#"sink_name {found=1} 
    found && /device.description/ {match($0, /device.description = "(.*)"/, arr); print arr[1]; exit}')
	notify-send "Ses Çıkışı Değiştirildi" "Yeni Ses Çıkışı: $sink_name"
	echo "${GREEN}Yeni Ses Çıkışı: $sink_name${RESET}"
}

# Ses kontrolü
control_volume() {
	case $1 in
	"up")
		pactl set-sink-volume @DEFAULT_SINK@ +5%
		notify_volume
		;;
	"down")
		pactl set-sink-volume @DEFAULT_SINK@ -5%
		notify_volume
		;;
	"set")
		if [[ $2 =~ ^[0-9]+$ ]] && [ "$2" -le 100 ]; then
			pactl set-sink-volume @DEFAULT_SINK@ ${2}%
			notify_volume
		else
			echo "${RED}Hata: Geçersiz ses seviyesi (0-100)${RESET}"
		fi
		;;
	"mute")
		pactl set-sink-mute @DEFAULT_SINK@ toggle
		notify_mute
		;;
	esac
}

# Mikrofon kontrolü
control_mic() {
	case $1 in
	"up")
		pactl set-source-volume @DEFAULT_SOURCE@ +5%
		notify_mic
		;;
	"down")
		pactl set-source-volume @DEFAULT_SOURCE@ -5%
		notify_mic
		;;
	"set")
		if [[ $2 =~ ^[0-9]+$ ]] && [ "$2" -le 100 ]; then
			pactl set-source-volume @DEFAULT_SOURCE@ ${2}%
			notify_mic
		else
			echo "${RED}Hata: Geçersiz mikrofon seviyesi (0-100)${RESET}"
		fi
		;;
	"mute")
		pactl set-source-mute @DEFAULT_SOURCE@ toggle
		notify_mic_mute
		;;
	esac
}

# Bildirimler
notify_volume() {
	local vol=$(pactl get-sink-volume @DEFAULT_SINK@ | awk '{print $5}' | tr -d '%')
	notify-send "Ses Seviyesi" "Ses: ${vol}%"
	echo "${GREEN}Ses Seviyesi: ${vol}%${RESET}"
}

notify_mute() {
	local mute=$(pactl get-sink-mute @DEFAULT_SINK@ | awk '{print $2}')
	if [ "$mute" = "yes" ]; then
		notify-send "Ses" "Ses Kapatıldı"
		echo "${YELLOW}Ses Kapatıldı${RESET}"
	else
		notify-send "Ses" "Ses Açıldı"
		echo "${GREEN}Ses Açıldı${RESET}"
	fi
}

notify_mic() {
	local vol=$(pactl get-source-volume @DEFAULT_SOURCE@ | awk '{print $5}' | tr -d '%')
	notify-send "Mikrofon Seviyesi" "Mikrofon: ${vol}%"
	echo "${GREEN}Mikrofon Seviyesi: ${vol}%${RESET}"
}

notify_mic_mute() {
	local mute=$(pactl get-source-mute @DEFAULT_SOURCE@ | awk '{print $2}')
	if [ "$mute" = "yes" ]; then
		notify-send "Mikrofon" "Mikrofon Kapatıldı"
		echo "${YELLOW}Mikrofon Kapatıldı${RESET}"
	else
		notify-send "Mikrofon" "Mikrofon Açıldı"
		echo "${GREEN}Mikrofon Açıldı${RESET}"
	fi
}

# Yardım
print_help() {
	echo "Kullanım: $0 [-d|--debug] [seçenek] [değer]"
	echo "Seçenekler:"
	echo "  volume up     - Sesi artır"
	echo "  volume down   - Sesi azalt"
	echo "  volume set N  - Sesi N% olarak ayarla (0-100)"
	echo "  volume mute   - Sesi aç/kapat"
	echo "  mic up        - Mikrofon sesini artır"
	echo "  mic down      - Mikrofon sesini azalt"
	echo "  mic set N     - Mikrofon sesini N% olarak ayarla (0-100)"
	echo "  mic mute      - Mikrofonu aç/kapat"
	echo "  switch        - Ses çıkışını değiştir"
	echo "  help         - Bu yardım mesajını göster"
}

# Ses çıkışı değiştirme
handle_switch() {
	if [[ $SINKS_COUNT -ne 0 ]]; then
		if [[ ${SINKS[-1]} -eq "$RUNNING_SINK" ]]; then
			debug_print "Çıkış Değiştiriliyor" "İlk çıkışa geçiliyor..."
			switch_sink "${SINKS[0]}"
		else
			NEW_INDEX=$((SINK_INDEX + 1))
			debug_print "Çıkış Değiştiriliyor" "Sonraki çıkışa geçiliyor..."
			switch_sink "${SINKS[$NEW_INDEX]}"
		fi
	else
		echo "${RED}Ses çıkışları bulunamadı.${RESET}"
		notify-send "Hata" "Ses çıkışı bulunamadı."
	fi
}

# Ana kontrol
case $1 in
"volume")
	control_volume "$2" "$3"
	;;
"mic")
	control_mic "$2" "$3"
	;;
"switch")
	handle_switch
	;;
"help" | *)
	print_help
	;;
esac
