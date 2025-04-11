#!/usr/bin/env bash
#===============================================================================
#
#   Script: HyprFlow PipeWire Audio Switcher
#   Version: 2.1.0
#   Date: 2025-04-11
#   Original Author: Kenan Pelit
#   Original Repository: https://github.com/kenanpelit/nixosc
#   Description: Advanced audio output switcher for Hyprland with PipeWire
#                integration
#
#   Features:
#   - Dynamic sink detection and switching for PipeWire
#   - Desktop notifications
#   - Automatic sink input migration
#   - Colored terminal output
#   - Volume and microphone control
#   - Enhanced error handling
#   - Configuration file support
#   - Init mode for setting default audio levels
#
#   License: MIT
#
#===============================================================================

# Script terminates on error
set -e

# Configuration
CONFIG_DIR="$HOME/.config/hyprflow"
CONFIG_FILE="$CONFIG_DIR/audio_switcher.conf"

# Color definitions
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
BLUE=$(tput setaf 4)
CYAN=$(tput setaf 6)
RESET=$(tput sgr0)

# Debug mode
DEBUG=false

# Version
VERSION="2.1.0"

# Default init values
DEFAULT_VOLUME=15
DEFAULT_MIC_VOLUME=5

# Create config directory if it doesn't exist
if [ ! -d "$CONFIG_DIR" ]; then
	mkdir -p "$CONFIG_DIR"
fi

# Create default config file if it doesn't exist
if [ ! -f "$CONFIG_FILE" ]; then
	cat >"$CONFIG_FILE" <<EOF
# HyprFlow Audio Switcher Configuration

# Debug mode (true/false)
DEBUG=false

# Volume step percentage
VOLUME_STEP=5

# Notification timeout in milliseconds
NOTIFICATION_TIMEOUT=3000

# Default volume level for init command (0-100)
DEFAULT_VOLUME=15

# Default microphone level for init command (0-100)
DEFAULT_MIC_VOLUME=5
EOF
fi

# Load configuration
if [ -f "$CONFIG_FILE" ]; then
	source "$CONFIG_FILE"
fi

# Volume step from config or default
VOLUME_STEP=${VOLUME_STEP:-5}

# Notification timeout
NOTIFICATION_TIMEOUT=${NOTIFICATION_TIMEOUT:-3000}

# Default init values from config
DEFAULT_VOLUME=${DEFAULT_VOLUME:-15}
DEFAULT_MIC_VOLUME=${DEFAULT_MIC_VOLUME:-5}

# Debug function
debug_print() {
	if [ "$DEBUG" = true ]; then
		echo
		echo "${BLUE}=========================================${RESET}"
		echo "${CYAN} $1 ${RESET}"
		echo "${BLUE}=========================================${RESET}"
		shift
		printf "${GREEN}$@${RESET}\n"
	fi
}

# Check command exists
check_command() {
	if ! command -v "$1" &>/dev/null; then
		echo "${RED}Error: $1 is required but not found. Please install it.${RESET}"
		return 1
	fi
	return 0
}

# Safe notification function
notify() {
	if command -v notify-send &>/dev/null; then
		notify-send -t "$NOTIFICATION_TIMEOUT" "$1" "$2"
	fi
	echo "${GREEN}$1: $2${RESET}"
}

# Check arguments
for arg in "$@"; do
	if [ "$arg" = "-d" ] || [ "$arg" = "--debug" ]; then
		DEBUG=true
		# Remove argument
		set -- "${@/$arg/}"
	fi
done

# Check dependencies
check_dependencies() {
	# Check for PipeWire
	if ! check_command "pw-cli"; then
		echo "${YELLOW}Warning: pw-cli not found. Falling back to PulseAudio compatibility layer.${RESET}"
	fi

	# Check for pactl (PulseAudio compatibility layer)
	if ! check_command "pactl"; then
		echo "${RED}Error: pactl not found. Please install PipeWire and its PulseAudio compatibility layer.${RESET}"
		exit 1
	fi

	# Check for notify-send (optional)
	if ! command -v notify-send &>/dev/null; then
		echo "${YELLOW}Warning: notify-send not found. Notifications will be disabled.${RESET}"
	fi
}

# Get audio sinks
get_sinks() {
	check_command "pactl" || exit 1
	SINKS=($(pactl list sinks short | awk '{print $1}'))
	RUNNING_SINK=$(pactl list sinks short | grep RUNNING | awk '{print $1}')

	# If no running sink found, use the default sink
	if [ -z "$RUNNING_SINK" ]; then
		RUNNING_SINK=$(pactl get-default-sink)
	fi

	INPUTS=($(pactl list sink-inputs short | awk '{print $1}'))

	SINKS_COUNT=${#SINKS[@]}
	debug_print "Ses Çıkışları" "Toplam: $SINKS_COUNT"

	# Find running sink index
	for i in "${!SINKS[@]}"; do
		if [[ ${SINKS[$i]} == "$RUNNING_SINK" ]]; then
			SINK_INDEX=$i
			break
		fi
	done
}

# Get audio sources (microphones)
get_sources() {
	check_command "pactl" || exit 1
	# Get all sources but exclude monitors (which are just outputs of other streams)
	SOURCES=($(pactl list sources short | grep -v "monitor" | awk '{print $1}'))
	DEFAULT_SOURCE=$(pactl get-default-source)

	SOURCES_COUNT=${#SOURCES[@]}
	debug_print "Mikrofonlar" "Toplam: $SOURCES_COUNT"

	# Find default source index
	for i in "${!SOURCES[@]}"; do
		if [[ ${SOURCES[$i]} == "$DEFAULT_SOURCE" ]]; then
			SOURCE_INDEX=$i
			break
		fi
	done
}

# Get sink name
get_sink_name() {
	local sink_id=$1
	pactl list sinks | awk -v sink_name="$sink_id" '
    $1 == "Sink" && $2 == "#"sink_name {found=1} 
    found && /device.description/ {match($0, /device.description = "(.*)"/, arr); print arr[1]; exit}'
}

# Get source name
get_source_name() {
	local source_id=$1
	pactl list sources | awk -v source_name="$source_id" '
    $1 == "Source" && $2 == "#"source_name {found=1} 
    found && /device.description/ {match($0, /device.description = "(.*)"/, arr); print arr[1]; exit}'
}

# Switch audio output
switch_sink() {
	local target_sink=$1

	# Set default sink
	if ! pactl set-default-sink "$target_sink"; then
		echo "${RED}Failed to set default sink to $target_sink${RESET}"
		return 1
	fi

	# Move all inputs to the new sink
	for input in "${INPUTS[@]}"; do
		pactl move-sink-input "$input" "$target_sink" || true
	done

	local sink_name=$(get_sink_name "$target_sink")
	notify "Ses Çıkışı Değiştirildi" "Yeni Ses Çıkışı: $sink_name"
	return 0
}

# Switch microphone input
switch_source() {
	local target_source=$1

	# Set default source
	if ! pactl set-default-source "$target_source"; then
		echo "${RED}Failed to set default source to $target_source${RESET}"
		return 1
	fi

	local source_name=$(get_source_name "$target_source")
	notify "Mikrofon Değiştirildi" "Yeni Mikrofon: $source_name"
	return 0
}

# Volume control
control_volume() {
	check_command "pactl" || exit 1

	case $1 in
	"up")
		pactl set-sink-volume @DEFAULT_SINK@ +${VOLUME_STEP}% || echo "${RED}Failed to increase volume${RESET}"
		notify_volume
		;;
	"down")
		pactl set-sink-volume @DEFAULT_SINK@ -${VOLUME_STEP}% || echo "${RED}Failed to decrease volume${RESET}"
		notify_volume
		;;
	"set")
		if [[ $2 =~ ^[0-9]+$ ]] && [ "$2" -le 100 ]; then
			pactl set-sink-volume @DEFAULT_SINK@ ${2}% || echo "${RED}Failed to set volume${RESET}"
			notify_volume
		else
			echo "${RED}Hata: Geçersiz ses seviyesi (0-100)${RESET}"
		fi
		;;
	"mute")
		pactl set-sink-mute @DEFAULT_SINK@ toggle || echo "${RED}Failed to toggle mute${RESET}"
		notify_mute
		;;
	esac
}

# Microphone control
control_mic() {
	check_command "pactl" || exit 1

	case $1 in
	"up")
		pactl set-source-volume @DEFAULT_SOURCE@ +${VOLUME_STEP}% || echo "${RED}Failed to increase mic volume${RESET}"
		notify_mic
		;;
	"down")
		pactl set-source-volume @DEFAULT_SOURCE@ -${VOLUME_STEP}% || echo "${RED}Failed to decrease mic volume${RESET}"
		notify_mic
		;;
	"set")
		if [[ $2 =~ ^[0-9]+$ ]] && [ "$2" -le 100 ]; then
			pactl set-source-volume @DEFAULT_SOURCE@ ${2}% || echo "${RED}Failed to set mic volume${RESET}"
			notify_mic
		else
			echo "${RED}Hata: Geçersiz mikrofon seviyesi (0-100)${RESET}"
		fi
		;;
	"mute")
		pactl set-source-mute @DEFAULT_SOURCE@ toggle || echo "${RED}Failed to toggle mic mute${RESET}"
		notify_mic_mute
		;;
	esac
}

# Initialize audio levels
initialize_audio() {
	check_command "pactl" || exit 1

	# Set default volume
	debug_print "Başlangıç" "Ses seviyesi %$DEFAULT_VOLUME olarak ayarlanıyor..."
	pactl set-sink-volume @DEFAULT_SINK@ ${DEFAULT_VOLUME}% || echo "${RED}Failed to set initial volume${RESET}"

	# Set default microphone volume
	debug_print "Başlangıç" "Mikrofon seviyesi %$DEFAULT_MIC_VOLUME olarak ayarlanıyor..."
	pactl set-source-volume @DEFAULT_SOURCE@ ${DEFAULT_MIC_VOLUME}% || echo "${RED}Failed to set initial mic volume${RESET}"

	# Ensure audio is not muted
	pactl set-sink-mute @DEFAULT_SINK@ 0 || echo "${RED}Failed to unmute audio${RESET}"

	notify "Ses Ayarları" "Ses: %$DEFAULT_VOLUME, Mikrofon: %$DEFAULT_MIC_VOLUME olarak ayarlandı"
}

# Notifications
notify_volume() {
	local vol=$(pactl get-sink-volume @DEFAULT_SINK@ | grep -oP '\d+(?=%)' | head -1)
	notify "Ses Seviyesi" "Ses: ${vol}%"
}

notify_mute() {
	local mute=$(pactl get-sink-mute @DEFAULT_SINK@ | awk '{print $2}')
	if [ "$mute" = "yes" ]; then
		notify "Ses" "Ses Kapatıldı"
	else
		notify "Ses" "Ses Açıldı"
	fi
}

notify_mic() {
	local vol=$(pactl get-source-volume @DEFAULT_SOURCE@ | grep -oP '\d+(?=%)' | head -1)
	notify "Mikrofon Seviyesi" "Mikrofon: ${vol}%"
}

notify_mic_mute() {
	local mute=$(pactl get-source-mute @DEFAULT_SOURCE@ | awk '{print $2}')
	if [ "$mute" = "yes" ]; then
		notify "Mikrofon" "Mikrofon Kapatıldı"
	else
		notify "Mikrofon" "Mikrofon Açıldı"
	fi
}

# Help
print_help() {
	echo "Kullanım: $0 [-d|--debug] [seçenek] [değer]"
	echo "Seçenekler:"
	echo "  init          - Ses ve mikrofon seviyelerini varsayılan değerlere ayarla"
	echo "  volume up     - Sesi artır"
	echo "  volume down   - Sesi azalt"
	echo "  volume set N  - Sesi N% olarak ayarla (0-100)"
	echo "  volume mute   - Sesi aç/kapat"
	echo "  mic up        - Mikrofon sesini artır"
	echo "  mic down      - Mikrofon sesini azalt"
	echo "  mic set N     - Mikrofon sesini N% olarak ayarla (0-100)"
	echo "  mic mute      - Mikrofonu aç/kapat"
	echo "  switch        - Ses çıkışını değiştir"
	echo "  switch-mic    - Mikrofonlar arasında geçiş yap"
	echo "  help          - Bu yardım mesajını göster"
	echo "  version       - Versiyon bilgisini göster"
	echo "  list          - Tüm ses çıkışları ve mikrofonları listele"
}

# Version info
print_version() {
	echo "HyprFlow PipeWire Audio Switcher v$VERSION"
}

# List audio devices
list_devices() {
	echo "Ses Çıkışları:"
	echo "-------------------------"
	pactl list sinks short
	echo -e "Aktif çıkış: $(pactl get-default-sink)"

	echo -e "\nMikrofonlar:"
	echo "-------------------------"
	pactl list sources short | grep -v monitor
	echo -e "Aktif mikrofon: $(pactl get-default-source)"
}

# Switch audio output
handle_switch() {
	get_sinks

	if [[ $SINKS_COUNT -eq 0 ]]; then
		echo "${RED}Hata: Ses çıkışları bulunamadı.${RESET}"
		notify "Hata" "Ses çıkışı bulunamadı."
		return 1
	fi

	if [[ -z "$SINK_INDEX" ]]; then
		# If no sink index found, use the first sink
		debug_print "Çıkış Değiştiriliyor" "İlk çıkışa geçiliyor..."
		switch_sink "${SINKS[0]}"
	elif [[ $SINK_INDEX -eq $(($SINKS_COUNT - 1)) ]]; then
		# If we're at the last sink, go to the first one
		debug_print "Çıkış Değiştiriliyor" "İlk çıkışa geçiliyor..."
		switch_sink "${SINKS[0]}"
	else
		# Go to the next sink
		local new_index=$(($SINK_INDEX + 1))
		debug_print "Çıkış Değiştiriliyor" "Sonraki çıkışa geçiliyor..."
		switch_sink "${SINKS[$new_index]}"
	fi
}

# Switch microphone input
handle_switch_mic() {
	get_sources

	if [[ $SOURCES_COUNT -eq 0 ]]; then
		echo "${RED}Hata: Mikrofonlar bulunamadı.${RESET}"
		notify "Hata" "Mikrofon bulunamadı."
		return 1
	fi

	if [[ -z "$SOURCE_INDEX" ]]; then
		# If no source index found, use the first source
		debug_print "Mikrofon Değiştiriliyor" "İlk mikrofona geçiliyor..."
		switch_source "${SOURCES[0]}"
	elif [[ $SOURCE_INDEX -eq $(($SOURCES_COUNT - 1)) ]]; then
		# If we're at the last source, go to the first one
		debug_print "Mikrofon Değiştiriliyor" "İlk mikrofona geçiliyor..."
		switch_source "${SOURCES[0]}"
	else
		# Go to the next source
		local new_index=$(($SOURCE_INDEX + 1))
		debug_print "Mikrofon Değiştiriliyor" "Sonraki mikrofona geçiliyor..."
		switch_source "${SOURCES[$new_index]}"
	fi
}

# Main function
main() {
	# Check dependencies
	check_dependencies

	# Process command
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
	"switch-mic")
		handle_switch_mic
		;;
	"init")
		initialize_audio
		;;
	"version")
		print_version
		;;
	"list")
		list_devices
		;;
	"help" | *)
		print_help
		;;
	esac
}

# Run main function
main "$@"
