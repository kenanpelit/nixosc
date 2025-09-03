#!/usr/bin/env bash
#===============================================================================
#
#   Script: HyprFlow PipeWire Audio Switcher
#   Version: 3.0.0
#   Date: 2025-09-03
#   Original Author: Kenan Pelit
#   Original Repository: https://github.com/kenanpelit/nixosc
#   Description: Advanced audio output switcher for Hyprland with PipeWire
#                integration using wpctl
#
#   Features:
#   - Native wpctl support for PipeWire
#   - Dynamic sink detection and switching
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
VERSION="3.0.0"

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

	# Check for wpctl (PipeWire)
	if ! check_command "wpctl"; then
		error "wpctl not found. Please install PipeWire."
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

	if [ "$SAVE_PREFERENCES" = true ] && [ -n "$value" ]; then
		# Geçici dosyaya yaz
		touch "$STATE_FILE.tmp"

		# Eski değerleri filtrele ve yeni değeri ekle
		if [ -f "$STATE_FILE" ]; then
			grep -v "^$key=" "$STATE_FILE" >>"$STATE_FILE.tmp" 2>/dev/null || true
		fi

		echo "$key=$value" >>"$STATE_FILE.tmp"
		mv "$STATE_FILE.tmp" "$STATE_FILE"
	fi
}

# Load state
load_state() {
	local key="$1"

	if [ -f "$STATE_FILE" ]; then
		local value=$(grep "^$key=" "$STATE_FILE" 2>/dev/null | cut -d'=' -f2)
		# Boş veya sadece whitespace içeren değerleri döndürme
		if [ -n "$value" ] && [ "$(echo "$value" | tr -d '[:space:]')" != "" ]; then
			echo "$value"
		fi
	fi
}

# Return 0 if $1 exists in the rest of the args (array check)
id_in_array() {
	local needle="$1"
	shift
	for x in "$@"; do
		[[ "$x" == "$needle" ]] && return 0
	done
	return 1
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

# Get audio sinks using wpctl
get_sinks() {
	check_command "wpctl" || exit 1

	# Parse wpctl status for sinks
	local status=$(wpctl status)

	# Extract sink IDs and names
	SINKS=()
	SINK_IDS=()

	while IFS= read -r line; do
		if [[ "$line" =~ ^[[:space:]]*([0-9]+)\.[[:space:]]+(.*) ]]; then
			local id="${BASH_REMATCH[1]}"
			local name="${BASH_REMATCH[2]}"
			# Clean up the name
			name=$(echo "$name" | sed -e 's/\[.*\]//g' -e 's/^[[:space:]]*//g' -e 's/[[:space:]]*$//g')
			if [ -n "$name" ]; then
				SINK_IDS+=("$id")
				SINKS+=("$name")
			fi
		fi
	done < <(echo "$status" | sed -n '/Sinks:/,/│.*Sources:/p' | grep -E '^\s*[0-9]+\.')

	SINKS_COUNT=${#SINKS[@]}
	debug_print "Ses Çıkışları" "Toplam: $SINKS_COUNT"

	# Find default sink
	RUNNING_SINK=""
	SINK_INDEX=-1
	local default_line=$(echo "$status" | grep -E '^\s*\*\s*[0-9]+\.' | head -1)
	if [[ "$default_line" =~ ([0-9]+)\. ]]; then
		local default_id="${BASH_REMATCH[1]}"
		for i in "${!SINK_IDS[@]}"; do
			if [[ "${SINK_IDS[$i]}" == "$default_id" ]]; then
				SINK_INDEX=$i
				RUNNING_SINK="${SINKS[$i]}"
				break
			fi
		done
	fi
}

# Get audio sources (microphones) using wpctl
get_sources() {
	check_command "wpctl" || exit 1

	# Parse wpctl status for sources
	local status=$(wpctl status)

	# Extract source IDs and names (excluding monitors)
	SOURCES=()
	SOURCE_IDS=()

	while IFS= read -r line; do
		if [[ "$line" =~ ^[[:space:]]*([0-9]+)\.[[:space:]]+(.*) ]]; then
			local id="${BASH_REMATCH[1]}"
			local name="${BASH_REMATCH[2]}"
			# Skip monitor sources
			if [[ ! "$name" =~ "Monitor" ]]; then
				# Clean up the name
				name=$(echo "$name" | sed -e 's/\[.*\]//g' -e 's/^[[:space:]]*//g' -e 's/[[:space:]]*$//g')
				if [ -n "$name" ]; then
					SOURCE_IDS+=("$id")
					SOURCES+=("$name")
				fi
			fi
		fi
	done < <(echo "$status" | sed -n '/│.*Sources:/,/│.*Filters:/p' | grep -E '^\s*[0-9]+\.')

	SOURCES_COUNT=${#SOURCES[@]}
	debug_print "Mikrofonlar" "Toplam: $SOURCES_COUNT"

	# Find default source
	DEFAULT_SOURCE=""
	SOURCE_INDEX=-1
	local default_line=$(echo "$status" | sed -n '/│.*Sources:/,/│.*Filters:/p' | grep -E '^\s*\*\s*[0-9]+\.' | head -1)
	if [[ "$default_line" =~ ([0-9]+)\. ]]; then
		local default_id="${BASH_REMATCH[1]}"
		for i in "${!SOURCE_IDS[@]}"; do
			if [[ "${SOURCE_IDS[$i]}" == "$default_id" ]]; then
				SOURCE_INDEX=$i
				DEFAULT_SOURCE="${SOURCES[$i]}"
				break
			fi
		done
	fi
}

# Get sink display name
get_sink_display_name() {
	local sink_name="$1"
	local sink_id="$2"

	# Clean up the name
	local description="$sink_name"
	description=$(echo "$description" | sed -e 's/bluez_output\.//' -e 's/alsa_output\.//' -e 's/\.analog-stereo//')

	local icon=$(get_device_icon "$description")
	echo "$icon $description"
}

# Get source display name
get_source_display_name() {
	local source_name="$1"
	local source_id="$2"

	# Clean up the name
	local description="$source_name"
	description=$(echo "$description" | sed -e 's/bluez_input\.//' -e 's/alsa_input\.//' -e 's/\.analog-stereo//')

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

	if [[ $index -ge 0 ]] && [[ $index -lt ${#SINK_IDS[@]} ]]; then
		switch_sink "${SINK_IDS[$index]}"
	else
		error "Invalid sink index: $index"
		return 1
	fi
}

# Switch to specific source by index
switch_to_source_index() {
	local index="$1"

	if [[ $index -ge 0 ]] && [[ $index -lt ${#SOURCE_IDS[@]} ]]; then
		switch_source "${SOURCE_IDS[$index]}"
	else
		error "Invalid source index: $index"
		return 1
	fi
}

# Switch audio output
switch_sink() {
	local target_sink_id=$1

	# Set default sink
	if ! wpctl set-default "$target_sink_id"; then
		error "Failed to set default sink to ID $target_sink_id"
		return 1
	fi

	# Save preference
	save_state "last_sink" "$target_sink_id"

	# Get display name for notification
	local display_name=""
	for i in "${!SINK_IDS[@]}"; do
		if [[ "${SINK_IDS[$i]}" == "$target_sink_id" ]]; then
			display_name=$(get_sink_display_name "${SINKS[$i]}" "$target_sink_id")
			break
		fi
	done

	notify "Ses Çıkışı Değiştirildi" "$display_name" "audio-card"
	return 0
}

# Switch microphone input
switch_source() {
	local target_source_id=$1

	# Set default source
	if ! wpctl set-default "$target_source_id"; then
		error "Failed to set default source to ID $target_source_id"
		return 1
	fi

	# Save preference
	save_state "last_source" "$target_source_id"

	# Get display name for notification
	local display_name=""
	for i in "${!SOURCE_IDS[@]}"; do
		if [[ "${SOURCE_IDS[$i]}" == "$target_source_id" ]]; then
			display_name=$(get_source_display_name "${SOURCES[$i]}" "$target_source_id")
			break
		fi
	done

	notify "Mikrofon Değiştirildi" "$display_name" "audio-input-microphone"
	return 0
}

# Volume control using wpctl
control_volume() {
	check_command "wpctl" || exit 1

	case $1 in
	"up")
		wpctl set-volume @DEFAULT_AUDIO_SINK@ ${VOLUME_STEP}%+
		notify_volume
		;;
	"down")
		wpctl set-volume @DEFAULT_AUDIO_SINK@ ${VOLUME_STEP}%-
		notify_volume
		;;
	"set")
		if [[ $2 =~ ^[0-9]+$ ]] && [ "$2" -le 100 ]; then
			wpctl set-volume @DEFAULT_AUDIO_SINK@ ${2}%
			notify_volume
		else
			error "Invalid volume level (0-100)"
		fi
		;;
	"mute")
		wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
		notify_mute
		;;
	esac
}

# Microphone control using wpctl
control_mic() {
	check_command "wpctl" || exit 1

	case $1 in
	"up")
		wpctl set-volume @DEFAULT_AUDIO_SOURCE@ ${VOLUME_STEP}%+
		notify_mic
		;;
	"down")
		wpctl set-volume @DEFAULT_AUDIO_SOURCE@ ${VOLUME_STEP}%-
		notify_mic
		;;
	"set")
		if [[ $2 =~ ^[0-9]+$ ]] && [ "$2" -le 100 ]; then
			wpctl set-volume @DEFAULT_AUDIO_SOURCE@ ${2}%
			notify_mic
		else
			error "Invalid microphone level (0-100)"
		fi
		;;
	"mute")
		wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle
		notify_mic_mute
		;;
	esac
}

initialize_audio() {
	check_command "wpctl" || exit 1

	info "Initializing audio levels..."

	# 1) Varsayılan seviyeleri uygula
	debug_print "Başlangıç" "Ses seviyesi %$DEFAULT_VOLUME olarak ayarlanıyor..."
	wpctl set-volume @DEFAULT_AUDIO_SINK@ ${DEFAULT_VOLUME}%

	debug_print "Başlangıç" "Mikrofon seviyesi %$DEFAULT_MIC_VOLUME olarak ayarlanıyor..."
	wpctl set-volume @DEFAULT_AUDIO_SOURCE@ ${DEFAULT_MIC_VOLUME}%

	# 2) Mevcut cihazları oku (doğrulama için)
	get_sinks
	get_sources

	# 3) Tercihleri yalnızca GEÇERLİ ise uygula
	if [ "$SAVE_PREFERENCES" = true ] && [ -f "$STATE_FILE" ]; then
		local last_sink="$(load_state "last_sink")"
		local last_source="$(load_state "last_source")"

		# Sink: sayı mı ve şu anki SINK_IDS içinde var mı?
		if [[ -n "$last_sink" && "$last_sink" =~ ^[0-9]+$ ]] && id_in_array "$last_sink" "${SINK_IDS[@]}"; then
			wpctl set-default "$last_sink" >/dev/null 2>&1 ||
				debug_print "Uyarı" "Sink ayarlanamadı: $last_sink"
		elif [ -n "$last_sink" ]; then
			debug_print "Uyarı" "Geçersiz sink ID: '$last_sink' — yoksayılıyor."
		fi

		# Source: sayı mı ve şu anki SOURCE_IDS içinde var mı?
		if [[ -n "$last_source" && "$last_source" =~ ^[0-9]+$ ]] && id_in_array "$last_source" "${SOURCE_IDS[@]}"; then
			wpctl set-default "$last_source" >/dev/null 2>&1 ||
				debug_print "Uyarı" "Source ayarlanamadı: $last_source"
		elif [ -n "$last_source" ]; then
			debug_print "Uyarı" "Geçersiz source ID: '$last_source' — yoksayılıyor."
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

	# Get current settings using wpctl
	local current_sink=""
	local current_source=""

	# Get default sink ID
	get_sinks
	if [[ $SINK_INDEX -ge 0 ]]; then
		current_sink="${SINK_IDS[$SINK_INDEX]}"
	fi

	# Get default source ID
	get_sources
	if [[ $SOURCE_INDEX -ge 0 ]]; then
		current_source="${SOURCE_IDS[$SOURCE_INDEX]}"
	fi

	# Get volumes (wpctl doesn't have direct command, so we estimate)
	local sink_volume="${DEFAULT_VOLUME}"
	local source_volume="${DEFAULT_MIC_VOLUME}"

	# Save to profile file
	cat >"$profile_file" <<EOF
# Audio Profile: $profile_name
# Created: $(date)

PROFILE_SINK="$current_sink"
PROFILE_SOURCE="$current_source"
PROFILE_SINK_VOLUME="$sink_volume"
PROFILE_SOURCE_VOLUME="$source_volume"
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
		wpctl set-default "$PROFILE_SINK" 2>/dev/null || warning "Could not set sink: $PROFILE_SINK"
	fi

	if [ -n "$PROFILE_SOURCE" ]; then
		wpctl set-default "$PROFILE_SOURCE" 2>/dev/null || warning "Could not set source: $PROFILE_SOURCE"
	fi

	if [ -n "$PROFILE_SINK_VOLUME" ]; then
		wpctl set-volume @DEFAULT_AUDIO_SINK@ "${PROFILE_SINK_VOLUME}%" 2>/dev/null || true
	fi

	if [ -n "$PROFILE_SOURCE_VOLUME" ]; then
		wpctl set-volume @DEFAULT_AUDIO_SOURCE@ "${PROFILE_SOURCE_VOLUME}%" 2>/dev/null || true
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
	# wpctl doesn't provide direct volume query, so we estimate
	local vol="${DEFAULT_VOLUME}"
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
	notify "Ses" "Ses Durumu Değiştirildi" "audio-volume-muted"
}

notify_mic() {
	local vol="${DEFAULT_MIC_VOLUME}"
	notify "Mikrofon Seviyesi" "Mikrofon: ${vol}%" "audio-input-microphone"
}

notify_mic_mute() {
	notify "Mikrofon" "Mikrofon Durumu Değiştirildi" "microphone-disabled"
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
