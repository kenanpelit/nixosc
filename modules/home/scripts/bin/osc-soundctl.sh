#!/usr/bin/env bash
#===============================================================================
#
#   Script: HyprFlow PipeWire Audio Switcher
#   Version: 2.5.0
#   Date: 2025-07-18
#   Original Author: Kenan Pelit
#   Original Repository: https://github.com/kenanpelit/nixosc
#   Description: Advanced audio output switcher for Hyprland with PipeWire
#                integration
#
#   Features:
#   - Dynamic sink detection and switching for PipeWire
#   - Desktop notifications with icon support
#   - Automatic sink input migration
#   - Colored terminal output
#   - Volume and microphone control
#   - Enhanced error handling
#   - Configuration file support
#   - Init mode for setting default audio levels
#   - Profile management
#   - Interactive device selection with fzf
#   - Device filtering and prioritization
#
#   License: MIT
#
#===============================================================================

# Script terminates on error
set -e

# Configuration
CONFIG_DIR="$HOME/.config/hyprflow"
CONFIG_FILE="$CONFIG_DIR/audio_switcher.conf"
PROFILES_DIR="$CONFIG_DIR/profiles"
STATE_FILE="$CONFIG_DIR/audio_state"

# Color definitions
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
BLUE=$(tput setaf 4)
CYAN=$(tput setaf 6)
MAGENTA=$(tput setaf 5)
BOLD=$(tput bold)
RESET=$(tput sgr0)

# Icons
ICON_SPEAKER="🔊"
ICON_HEADPHONES="🎧"
ICON_MICROPHONE="🎤"
ICON_BLUETOOTH="🔷"
ICON_CHECK="✓"
ICON_CROSS="✗"
ICON_WARNING="⚠️"

# Debug mode
DEBUG=false

# Version
VERSION="2.5.0"

# Default init values
DEFAULT_VOLUME=15
DEFAULT_MIC_VOLUME=5

# Create config directory if it doesn't exist
if [ ! -d "$CONFIG_DIR" ]; then
	mkdir -p "$CONFIG_DIR"
fi

# Create profiles directory if it doesn't exist
if [ ! -d "$PROFILES_DIR" ]; then
	mkdir -p "$PROFILES_DIR"
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

# Enable device icons in notifications (true/false)
ENABLE_ICONS=true

# Prefer Bluetooth devices when available (true/false)
PREFER_BLUETOOTH=false

# Save last used devices (true/false)
SAVE_PREFERENCES=true
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

# Enable icons
ENABLE_ICONS=${ENABLE_ICONS:-true}

# Device preferences
PREFER_BLUETOOTH=${PREFER_BLUETOOTH:-false}
SAVE_PREFERENCES=${SAVE_PREFERENCES:-true}

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

# Info message
info() {
	echo "${CYAN}ℹ $1${RESET}"
}

# Success message
success() {
	echo "${GREEN}${ICON_CHECK} $1${RESET}"
}

# Warning message
warning() {
	echo "${YELLOW}${ICON_WARNING} $1${RESET}"
}

# Error message
error() {
	echo "${RED}${ICON_CROSS} Error: $1${RESET}" >&2
}

# Check command exists
check_command() {
	if ! command -v "$1" &>/dev/null; then
		error "$1 is required but not found. Please install it."
		return 1
	fi
	return 0
}

# Safe notification function
notify() {
	local title="$1"
	local message="$2"
	local icon="${3:-}"

	if command -v notify-send &>/dev/null; then
		if [ "$ENABLE_ICONS" = true ] && [ -n "$icon" ]; then
			notify-send -t "$NOTIFICATION_TIMEOUT" -i "$icon" "$title" "$message"
		else
			notify-send -t "$NOTIFICATION_TIMEOUT" "$title" "$message"
		fi
	fi
	info "$title: $message"
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
	local has_errors=false

	# Check for PipeWire
	if ! check_command "pw-cli"; then
		warning "pw-cli not found. Falling back to PulseAudio compatibility layer."
	fi

	# Check for pactl (PulseAudio compatibility layer)
	if ! check_command "pactl"; then
		error "pactl not found. Please install PipeWire and its PulseAudio compatibility layer."
		has_errors=true
	fi

	# Check for notify-send (optional)
	if ! command -v notify-send &>/dev/null; then
		warning "notify-send not found. Notifications will be disabled."
	fi

	# Check for fzf (optional)
	if ! command -v fzf &>/dev/null; then
		debug_print "Info" "fzf not found. Interactive mode will be disabled."
	fi

	if [ "$has_errors" = true ]; then
		exit 1
	fi
}

# Save state
save_state() {
	local key="$1"
	local value="$2"

	if [ "$SAVE_PREFERENCES" = true ]; then
		echo "$key=$value" >>"$STATE_FILE.tmp"
		grep -v "^$key=" "$STATE_FILE" 2>/dev/null >>"$STATE_FILE.tmp" || true
		mv "$STATE_FILE.tmp" "$STATE_FILE"
	fi
}

# Load state
load_state() {
	local key="$1"

	if [ -f "$STATE_FILE" ]; then
		grep "^$key=" "$STATE_FILE" 2>/dev/null | cut -d'=' -f2 || echo ""
	else
		echo ""
	fi
}

# Get device icon
get_device_icon() {
	local device_name="$1"

	case "$device_name" in
	*[Bb]luetooth*) echo "$ICON_BLUETOOTH" ;;
	*[Hh]eadphone* | *[Hh]eadset*) echo "$ICON_HEADPHONES" ;;
	*[Mm]ic* | *[Mm]icrophone*) echo "$ICON_MICROPHONE" ;;
	*) echo "$ICON_SPEAKER" ;;
	esac
}

# Get audio sinks
get_sinks() {
	check_command "pactl" || exit 1
	SINKS=($(pactl list sinks short | awk '{print $2}'))
	SINK_IDS=($(pactl list sinks short | awk '{print $1}'))
	RUNNING_SINK=$(pactl get-default-sink)

	INPUTS=($(pactl list sink-inputs short | awk '{print $1}'))

	SINKS_COUNT=${#SINKS[@]}
	debug_print "Ses Çıkışları" "Toplam: $SINKS_COUNT"

	# Find running sink index
	SINK_INDEX=-1
	for i in "${!SINKS[@]}"; do
		if [[ "${SINKS[$i]}" == "$RUNNING_SINK" ]]; then
			SINK_INDEX=$i
			break
		fi
	done
}

# Get audio sources (microphones)
get_sources() {
	check_command "pactl" || exit 1

	# Get all sources but exclude monitors - we want actual input devices only
	SOURCES=($(pactl list sources short | grep -v "monitor" | awk '{print $2}'))
	SOURCE_IDS=($(pactl list sources short | grep -v "monitor" | awk '{print $1}'))
	DEFAULT_SOURCE=$(pactl get-default-source)

	SOURCES_COUNT=${#SOURCES[@]}
	debug_print "Mikrofonlar" "Toplam: $SOURCES_COUNT"

	# Find default source index
	SOURCE_INDEX=-1
	for i in "${!SOURCES[@]}"; do
		if [[ "${SOURCES[$i]}" == "$DEFAULT_SOURCE" ]]; then
			SOURCE_INDEX=$i
			break
		fi
	done

	debug_print "Aktif Mikrofon" "Index: $SOURCE_INDEX, Adı: $DEFAULT_SOURCE"
}

# Get sink name with icon
get_sink_display_name() {
	local sink_name="$1"
	local sink_id="$2"

	# Get human-readable description
	local description=$(pactl list sinks | awk -v id="$sink_id" '
		$1 == "Sink" && $2 == "#"id {found=1}
		found && /Description:/ {
			sub(/^[[:space:]]*Description:[[:space:]]*/, "")
			print
			exit
		}
	')

	local icon=$(get_device_icon "$description")
	echo "$icon $description"
}

# Get source name with icon
get_source_display_name() {
	local source_name="$1"
	local source_id="$2"

	# Get human-readable description
	local description=$(pactl list sources | awk -v id="$source_id" '
		$1 == "Source" && $2 == "#"id {found=1}
		found && /Description:/ {
			sub(/^[[:space:]]*Description:[[:space:]]*/, "")
			print
			exit
		}
	')

	local icon=$(get_device_icon "$description")
	echo "$icon $description"
}

# Interactive sink selection
select_sink_interactive() {
	if ! command -v fzf &>/dev/null; then
		warning "fzf not found. Please install fzf for interactive mode."
		return 1
	fi

	get_sinks

	if [[ $SINKS_COUNT -eq 0 ]]; then
		error "No audio outputs found."
		return 1
	fi

	# Create selection list
	local selection_list=""
	for i in "${!SINKS[@]}"; do
		local display_name=$(get_sink_display_name "${SINKS[$i]}" "${SINK_IDS[$i]}")
		local marker=""
		if [[ $i -eq $SINK_INDEX ]]; then
			marker=" ${GREEN}[current]${RESET}"
		fi
		selection_list+="$i: $display_name$marker\n"
	done

	# Show selection dialog
	local selected=$(echo -e "$selection_list" | fzf --ansi --height=10 --layout=reverse --header="Select Audio Output")

	if [ -n "$selected" ]; then
		local selected_index=$(echo "$selected" | cut -d':' -f1)
		switch_to_sink_index "$selected_index"
		return 0
	fi

	return 1
}

# Interactive source selection
select_source_interactive() {
	if ! command -v fzf &>/dev/null; then
		warning "fzf not found. Please install fzf for interactive mode."
		return 1
	fi

	get_sources

	if [[ $SOURCES_COUNT -eq 0 ]]; then
		error "No microphones found."
		return 1
	fi

	# Create selection list
	local selection_list=""
	for i in "${!SOURCES[@]}"; do
		local display_name=$(get_source_display_name "${SOURCES[$i]}" "${SOURCE_IDS[$i]}")
		local marker=""
		if [[ $i -eq $SOURCE_INDEX ]]; then
			marker=" ${GREEN}[current]${RESET}"
		fi
		selection_list+="$i: $display_name$marker\n"
	done

	# Show selection dialog
	local selected=$(echo -e "$selection_list" | fzf --ansi --height=10 --layout=reverse --header="Select Microphone")

	if [ -n "$selected" ]; then
		local selected_index=$(echo "$selected" | cut -d':' -f1)
		switch_to_source_index "$selected_index"
		return 0
	fi

	return 1
}

# Switch to specific sink by index
switch_to_sink_index() {
	local index="$1"

	if [[ $index -ge 0 ]] && [[ $index -lt ${#SINKS[@]} ]]; then
		switch_sink "${SINKS[$index]}"
	else
		error "Invalid sink index: $index"
		return 1
	fi
}

# Switch to specific source by index
switch_to_source_index() {
	local index="$1"

	if [[ $index -ge 0 ]] && [[ $index -lt ${#SOURCES[@]} ]]; then
		switch_source "${SOURCES[$index]}"
	else
		error "Invalid source index: $index"
		return 1
	fi
}

# Switch audio output
switch_sink() {
	local target_sink=$1

	# Set default sink
	if ! pactl set-default-sink "$target_sink"; then
		error "Failed to set default sink to $target_sink"
		return 1
	fi

	# Move all inputs to the new sink
	for input in "${INPUTS[@]}"; do
		pactl move-sink-input "$input" "$target_sink" 2>/dev/null || true
	done

	# Save preference
	save_state "last_sink" "$target_sink"

	# Get display name for notification
	local display_name=$(get_sink_display_name "$target_sink" "")
	notify "Ses Çıkışı Değiştirildi" "$display_name" "audio-card"
	return 0
}

# Switch microphone input
switch_source() {
	local target_source=$1

	# Set default source
	if ! pactl set-default-source "$target_source"; then
		error "Failed to set default source to $target_source"
		return 1
	fi

	# Save preference
	save_state "last_source" "$target_source"

	# Get display name for notification
	local display_name=$(get_source_display_name "$target_source" "")
	notify "Mikrofon Değiştirildi" "$display_name" "audio-input-microphone"
	return 0
}

# Volume control
control_volume() {
	check_command "pactl" || exit 1

	case $1 in
	"up")
		pactl set-sink-volume @DEFAULT_SINK@ +${VOLUME_STEP}%
		notify_volume
		;;
	"down")
		pactl set-sink-volume @DEFAULT_SINK@ -${VOLUME_STEP}%
		notify_volume
		;;
	"set")
		if [[ $2 =~ ^[0-9]+$ ]] && [ "$2" -le 100 ]; then
			pactl set-sink-volume @DEFAULT_SINK@ ${2}%
			notify_volume
		else
			error "Invalid volume level (0-100)"
		fi
		;;
	"mute")
		pactl set-sink-mute @DEFAULT_SINK@ toggle
		notify_mute
		;;
	esac
}

# Microphone control
control_mic() {
	check_command "pactl" || exit 1

	case $1 in
	"up")
		pactl set-source-volume @DEFAULT_SOURCE@ +${VOLUME_STEP}%
		notify_mic
		;;
	"down")
		pactl set-source-volume @DEFAULT_SOURCE@ -${VOLUME_STEP}%
		notify_mic
		;;
	"set")
		if [[ $2 =~ ^[0-9]+$ ]] && [ "$2" -le 100 ]; then
			pactl set-source-volume @DEFAULT_SOURCE@ ${2}%
			notify_mic
		else
			error "Invalid microphone level (0-100)"
		fi
		;;
	"mute")
		pactl set-source-mute @DEFAULT_SOURCE@ toggle
		notify_mic_mute
		;;
	esac
}

# Initialize audio levels
initialize_audio() {
	check_command "pactl" || exit 1

	info "Initializing audio levels..."

	# Set default volume
	debug_print "Başlangıç" "Ses seviyesi %$DEFAULT_VOLUME olarak ayarlanıyor..."
	pactl set-sink-volume @DEFAULT_SINK@ ${DEFAULT_VOLUME}%

	# Set default microphone volume
	debug_print "Başlangıç" "Mikrofon seviyesi %$DEFAULT_MIC_VOLUME olarak ayarlanıyor..."
	pactl set-source-volume @DEFAULT_SOURCE@ ${DEFAULT_MIC_VOLUME}%

	# Ensure audio is not muted
	pactl set-sink-mute @DEFAULT_SINK@ 0

	# Load last used devices if available
	if [ "$SAVE_PREFERENCES" = true ]; then
		local last_sink=$(load_state "last_sink")
		local last_source=$(load_state "last_source")

		if [ -n "$last_sink" ]; then
			pactl set-default-sink "$last_sink" 2>/dev/null || true
		fi

		if [ -n "$last_source" ]; then
			pactl set-default-source "$last_source" 2>/dev/null || true
		fi
	fi

	notify "Ses Ayarları" "Ses: %$DEFAULT_VOLUME, Mikrofon: %$DEFAULT_MIC_VOLUME" "audio-volume-medium"
	success "Audio initialized successfully"
}

# Profile management
save_profile() {
	local profile_name="${1:-default}"
	local profile_file="$PROFILES_DIR/$profile_name.profile"

	info "Saving profile: $profile_name"

	# Get current settings
	local current_sink=$(pactl get-default-sink)
	local current_source=$(pactl get-default-source)
	local sink_volume=$(pactl get-sink-volume @DEFAULT_SINK@ | grep -oP '\d+(?=%)' | head -1)
	local source_volume=$(pactl get-source-volume @DEFAULT_SOURCE@ | grep -oP '\d+(?=%)' | head -1)
	local sink_muted=$(pactl get-sink-mute @DEFAULT_SINK@ | awk '{print $2}')
	local source_muted=$(pactl get-source-mute @DEFAULT_SOURCE@ | awk '{print $2}')

	# Save to profile file
	cat >"$profile_file" <<EOF
# Audio Profile: $profile_name
# Created: $(date)

PROFILE_SINK="$current_sink"
PROFILE_SOURCE="$current_source"
PROFILE_SINK_VOLUME="$sink_volume"
PROFILE_SOURCE_VOLUME="$source_volume"
PROFILE_SINK_MUTED="$sink_muted"
PROFILE_SOURCE_MUTED="$source_muted"
EOF

	notify "Profile Saved" "$profile_name" "document-save"
	success "Profile '$profile_name' saved successfully"
}

# Load profile
load_profile() {
	local profile_name="${1:-default}"
	local profile_file="$PROFILES_DIR/$profile_name.profile"

	if [ ! -f "$profile_file" ]; then
		error "Profile not found: $profile_name"
		return 1
	fi

	info "Loading profile: $profile_name"

	# Load profile settings
	source "$profile_file"

	# Apply settings
	if [ -n "$PROFILE_SINK" ]; then
		pactl set-default-sink "$PROFILE_SINK" 2>/dev/null || warning "Could not set sink: $PROFILE_SINK"
	fi

	if [ -n "$PROFILE_SOURCE" ]; then
		pactl set-default-source "$PROFILE_SOURCE" 2>/dev/null || warning "Could not set source: $PROFILE_SOURCE"
	fi

	if [ -n "$PROFILE_SINK_VOLUME" ]; then
		pactl set-sink-volume @DEFAULT_SINK@ "${PROFILE_SINK_VOLUME}%" 2>/dev/null || true
	fi

	if [ -n "$PROFILE_SOURCE_VOLUME" ]; then
		pactl set-source-volume @DEFAULT_SOURCE@ "${PROFILE_SOURCE_VOLUME}%" 2>/dev/null || true
	fi

	if [ "$PROFILE_SINK_MUTED" = "yes" ]; then
		pactl set-sink-mute @DEFAULT_SINK@ 1 2>/dev/null || true
	else
		pactl set-sink-mute @DEFAULT_SINK@ 0 2>/dev/null || true
	fi

	if [ "$PROFILE_SOURCE_MUTED" = "yes" ]; then
		pactl set-source-mute @DEFAULT_SOURCE@ 1 2>/dev/null || true
	else
		pactl set-source-mute @DEFAULT_SOURCE@ 0 2>/dev/null || true
	fi

	notify "Profile Loaded" "$profile_name" "document-open"
	success "Profile '$profile_name' loaded successfully"
}

# List profiles
list_profiles() {
	info "Available profiles:"

	if [ ! -d "$PROFILES_DIR" ] || [ -z "$(ls -A "$PROFILES_DIR" 2>/dev/null)" ]; then
		echo "  No profiles found"
		return
	fi

	for profile in "$PROFILES_DIR"/*.profile; do
		if [ -f "$profile" ]; then
			local profile_name=$(basename "$profile" .profile)
			local created=$(grep "# Created:" "$profile" | cut -d: -f2-)
			echo "  ${GREEN}$profile_name${RESET} - Created:$created"
		fi
	done
}

# Notifications
notify_volume() {
	local vol=$(pactl get-sink-volume @DEFAULT_SINK@ | grep -oP '\d+(?=%)' | head -1)
	local icon="audio-volume-high"

	if [ "$vol" -eq 0 ]; then
		icon="audio-volume-muted"
	elif [ "$vol" -lt 30 ]; then
		icon="audio-volume-low"
	elif [ "$vol" -lt 70 ]; then
		icon="audio-volume-medium"
	fi

	notify "Ses Seviyesi" "Ses: ${vol}%" "$icon"
}

notify_mute() {
	local mute=$(pactl get-sink-mute @DEFAULT_SINK@ | awk '{print $2}')
	if [ "$mute" = "yes" ]; then
		notify "Ses" "Ses Kapatıldı" "audio-volume-muted"
	else
		notify "Ses" "Ses Açıldı" "audio-volume-high"
	fi
}

notify_mic() {
	local vol=$(pactl get-source-volume @DEFAULT_SOURCE@ | grep -oP '\d+(?=%)' | head -1)
	notify "Mikrofon Seviyesi" "Mikrofon: ${vol}%" "audio-input-microphone"
}

notify_mic_mute() {
	local mute=$(pactl get-source-mute @DEFAULT_SOURCE@ | awk '{print $2}')
	if [ "$mute" = "yes" ]; then
		notify "Mikrofon" "Mikrofon Kapatıldı" "microphone-disabled"
	else
		notify "Mikrofon" "Mikrofon Açıldı" "audio-input-microphone"
	fi
}

# List devices
list_devices() {
	echo "${BOLD}Ses Çıkışları:${RESET}"
	echo "─────────────────────────"

	get_sinks
	for i in "${!SINKS[@]}"; do
		local display_name=$(get_sink_display_name "${SINKS[$i]}" "${SINK_IDS[$i]}")
		local marker=""
		if [[ $i -eq $SINK_INDEX ]]; then
			marker=" ${GREEN}[aktif]${RESET}"
		fi
		echo "$i: $display_name$marker"
	done

	echo
	echo "${BOLD}Mikrofonlar:${RESET}"
	echo "─────────────────────────"

	get_sources
	for i in "${!SOURCES[@]}"; do
		local display_name=$(get_source_display_name "${SOURCES[$i]}" "${SOURCE_IDS[$i]}")
		local marker=""
		if [[ $i -eq $SOURCE_INDEX ]]; then
			marker=" ${GREEN}[aktif]${RESET}"
		fi
		echo "$i: $display_name$marker"
	done
}

# Help
print_help() {
	cat <<EOF
${BOLD}HyprFlow PipeWire Audio Switcher v$VERSION${RESET}

${BOLD}Kullanım:${RESET}
  $0 [-d|--debug] [komut] [parametreler]

${BOLD}Komutlar:${RESET}
  ${CYAN}Ses Çıkışı:${RESET}
    switch              Sonraki ses çıkışına geç
    switch-interactive  İnteraktif ses çıkışı seçimi (fzf gerektirir)
    
  ${CYAN}Mikrofon:${RESET}
    switch-mic          Sonraki mikrofona geç
    mic-interactive     İnteraktif mikrofon seçimi (fzf gerektirir)
    
  ${CYAN}Ses Kontrolü:${RESET}
    volume up           Sesi artır
    volume down         Sesi azalt
    volume set N        Sesi %N olarak ayarla (0-100)
    volume mute         Sesi aç/kapat
    
  ${CYAN}Mikrofon Kontrolü:${RESET}
    mic up              Mikrofon sesini artır
    mic down            Mikrofon sesini azalt
    mic set N           Mikrofon sesini %N olarak ayarla (0-100)
    mic mute            Mikrofonu aç/kapat
    
  ${CYAN}Profiller:${RESET}
    save-profile [isim] Mevcut ayarları profil olarak kaydet
    load-profile [isim] Profili yükle
    list-profiles       Mevcut profilleri listele
    
  ${CYAN}Diğer:${RESET}
    init                Ses ayarlarını başlangıç değerlerine getir
    list                Tüm ses cihazlarını listele
    help                Bu yardım mesajını göster
    version             Versiyon bilgisini göster

${BOLD}Örnekler:${RESET}
  # Ses çıkışını değiştir
  $0 switch
  
  # İnteraktif seçim
  $0 switch-interactive
  
  # Ses seviyesini %50 yap
  $0 volume set 50
  
  # Gaming profili kaydet
  $0 save-profile gaming
  
  # Gaming profilini yükle
  $0 load-profile gaming

${BOLD}Konfigürasyon:${RESET}
  Ayar dosyası: $CONFIG_FILE
  Profiller: $PROFILES_DIR/

EOF
}

# Version info
print_version() {
	echo "${BOLD}HyprFlow PipeWire Audio Switcher${RESET}"
	echo "Version: $VERSION"
	echo "Config: $CONFIG_FILE"
	echo "Profiles: $PROFILES_DIR"
}

# Switch audio output
handle_switch() {
	get_sinks

	if [[ $SINKS_COUNT -eq 0 ]]; then
		error "No audio outputs found."
		notify "Hata" "Ses çıkışı bulunamadı." "dialog-error"
		return 1
	fi

	if [[ $SINK_INDEX -lt 0 ]]; then
		# If no sink index found, use the first sink
		debug_print "Çıkış Değiştiriliyor" "İlk çıkışa geçiliyor..."
		switch_to_sink_index 0
	elif [[ $SINK_INDEX -eq $(($SINKS_COUNT - 1)) ]]; then
		# If we're at the last sink, go to the first one
		debug_print "Çıkış Değiştiriliyor" "İlk çıkışa geçiliyor..."
		switch_to_sink_index 0
	else
		# Go to the next sink
		local new_index=$(($SINK_INDEX + 1))
		debug_print "Çıkış Değiştiriliyor" "Sonraki çıkışa geçiliyor..."
		switch_to_sink_index $new_index
	fi
}

# Switch microphone input
handle_switch_mic() {
	get_sources

	if [[ $SOURCES_COUNT -eq 0 ]]; then
		error "No microphones found."
		notify "Hata" "Mikrofon bulunamadı." "dialog-error"
		return 1
	fi

	if [ "$DEBUG" = true ]; then
		echo "${CYAN}Mevcut mikrofonlar:${RESET}"
		for i in "${!SOURCES[@]}"; do
			local display_name=$(get_source_display_name "${SOURCES[$i]}" "${SOURCE_IDS[$i]}")
			echo "$i: $display_name"
			if [[ $i -eq $SOURCE_INDEX ]]; then
				echo "   ${GREEN}[aktif]${RESET}"
			fi
		done
	fi

	# If no source index found or invalid, use the first source
	if [[ $SOURCE_INDEX -lt 0 ]]; then
		debug_print "Mikrofon Değiştiriliyor" "İlk mikrofona geçiliyor..."
		switch_to_source_index 0
		return 0
	fi

	# Calculate next index with proper modulo for cycling
	local next_index=$(((SOURCE_INDEX + 1) % SOURCES_COUNT))

	debug_print "Mikrofon Değiştiriliyor" "Index $SOURCE_INDEX -> $next_index"
	switch_to_source_index $next_index
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
	"switch-interactive")
		select_sink_interactive
		;;
	"switch-mic")
		handle_switch_mic
		;;
	"mic-interactive")
		select_source_interactive
		;;
	"init")
		initialize_audio
		;;
	"save-profile")
		save_profile "$2"
		;;
	"load-profile")
		load_profile "$2"
		;;
	"list-profiles")
		list_profiles
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
