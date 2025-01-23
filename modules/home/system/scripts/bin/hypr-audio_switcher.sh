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

# Başlık Yazdırma Fonksiyonu
print_header() {
	echo
	echo "${BLUE}=========================================${RESET}"
	echo "${CYAN} $1 ${RESET}"
	echo "${BLUE}=========================================${RESET}"
}

# Mimari Tespit Etme
print_header "Mimari Tespit Ediliyor"
case "$SNAP_ARCH" in
"amd64")
	ARCH="x86_64-linux-gnu"
	;;
"armhf")
	ARCH="arm-linux-gnueabihf"
	;;
"arm64")
	ARCH="aarch64-linux-gnu"
	;;
*)
	ARCH="$SNAP_ARCH-linux-gnu"
	;;
esac
echo "${GREEN}Mimari: $ARCH${RESET}"

# Pulseaudio ayarları
print_header "Pulseaudio Ortam Değişkenleri Ayarlanıyor"
export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:$SNAP/usr/lib/$ARCH/pulseaudio"
export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:$SNAP/lib/$ARCH"
echo "${GREEN}LD_LIBRARY_PATH: $LD_LIBRARY_PATH${RESET}"

# Ses Çıkışları (Sinks) ve Çıkışların Durumu
print_header "Ses Çıkışları ve Durumu Kontrol Ediliyor"
SINKS=($(pactl list sinks short | awk '{print $1}'))
RUNNING_SINK=$(pactl list sinks short | grep RUNNING | awk '{print $1}')
INPUTS=($(pactl list sink-inputs short | awk '{print $1}'))
SINKS_COUNT=${#SINKS[@]}

echo "${YELLOW}Toplam Ses Çıkışı Sayısı: $SINKS_COUNT${RESET}"

# Çalışan Ses Çıkışını Bulma
for i in "${!SINKS[@]}"; do
	if [[ ${SINKS[$i]} == "$RUNNING_SINK" ]]; then
		SINK_INDEX=$i
		break
	fi
done

# Ses Çıkışını Değiştirme Fonksiyonu
switch_sink() {
	local target_sink=$1
	pactl set-default-sink "$target_sink"
	for input in "${INPUTS[@]}"; do
		pactl move-sink-input "$input" "$target_sink"
	done
	# Aygıtın device.description alanını tam olarak alıyoruz
	local sink_name=$(pactl list sinks | awk -v sink_name="$target_sink" '
    $1 == "Sink" && $2 == "#"sink_name {found=1} 
    found && /device.description/ {match($0, /device.description = "(.*)"/, arr); print arr[1]; exit}')
	notify-send "Ses Çıkışı Değiştirildi" "Yeni Ses Çıkışı: $sink_name"
	echo "${GREEN}Yeni Ses Çıkışı: $sink_name${RESET}"
}

# Ses Çıkışını Döngüsel Olarak Değiştir
if [[ $SINKS_COUNT -ne 0 ]]; then
	if [[ ${SINKS[-1]} -eq "$RUNNING_SINK" ]]; then
		echo "${YELLOW}En son ses çıkışı aktif. İlk çıkışa geçiliyor...${RESET}"
		switch_sink "${SINKS[0]}"
	else
		NEW_INDEX=$((SINK_INDEX + 1))
		echo "${YELLOW}Sonraki ses çıkışına geçiliyor...${RESET}"
		switch_sink "${SINKS[$NEW_INDEX]}"
	fi
else
	echo "${RED}Ses çıkışları bulunamadı.${RESET}"
	notify-send "Hata" "Ses çıkışı bulunamadı."
fi
