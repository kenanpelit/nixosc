#!/usr/bin/env bash
# osc-radio.sh - İnternet radyo oynatıcı
# mpv ile ön tanımlı istasyonları çalar, arayüzden seçim ve bildirim sağlar.

# tradio - Terminal Based Radio Player
# ===================================
#
# Description:
# -----------
# tradio is a lightweight, terminal-based radio player that allows users to listen
# to various online radio stations directly from their terminal. It provides an
# easy-to-use interface with features like favorites, history tracking, and
# volume control.
#
# Features:
# --------
# - Simple and clean terminal user interface
# - Support for multiple radio stations
# - Favorites system for quick access to preferred stations
# - History tracking of played stations
# - Volume control integration
# - Search functionality
# - Support for both MPV and VLC players
# - Automatic dependency checking
# - Notification system integration
# - Cross-platform compatibility (Linux, BSD, macOS)
# - Special support for NixOS environments
# - CLI interface with toggle support
#
# Version: 1.1
# Author: Kenan Pelit | https://github.com/kenanpelit/tradio
# License: MIT
#

# Disable debug output
set +x

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Radio stations - Virgin Radio first, rest alphabetically sorted
declare -A RADIOS
RADIOS=(
	["Virgin Radio"]="http://playerservices.streamtheworld.com/api/livestream-redirect/VIRGIN_RADIO_SC"
	["Joy FM"]="http://playerservices.streamtheworld.com/api/livestream-redirect/JOY_FM_SC"
	["Joy Jazz"]="http://playerservices.streamtheworld.com/api/livestream-redirect/JOY_JAZZ_SC"
	["Kral 45lik"]="https://ssldyg.radyotvonline.com/kralweb/smil:kral45lik.smil/chunklist_w1544647566_b64000.m3u8"
	["Metro FM"]="http://playerservices.streamtheworld.com/api/livestream-redirect/METRO_FM_SC"
	["NTV Radyo"]="http://ntvrdsc.radyotvonline.com/"
	["Pal Akustik"]="http://shoutcast.radyogrup.com:2030/"
	["Pal Dance"]="http://shoutcast.radyogrup.com:2040/"
	["Pal Nostalji"]="http://shoutcast.radyogrup.com:1010/"
	["Pal Orient"]="http://shoutcast.radyogrup.com:1050/"
	["Pal Slow"]="http://shoutcast.radyogrup.com:2020/"
	["Pal Station"]="http://shoutcast.radyogrup.com:1020/"
	["Radyo 45lik"]="http://104.236.16.158:3060/"
	["Radyo Dejavu"]="http://radyodejavu.canliyayinda.com:8054/"
	["Radyo Voyage"]="http://voyagewmp.radyotvonline.com:80/"
	["Retro Türk"]="http://playerservices.streamtheworld.com/api/livestream-redirect/RETROTURK_SC"
	["World Hits"]="http://37.247.98.8/stream/34/.mp3"
)

# Configuration files
CONFIG_DIR="$HOME/.config/tradio"
CONFIG_FILE="$CONFIG_DIR/config"
HISTORY_FILE="$CONFIG_DIR/history"
FAVORITES_FILE="$CONFIG_DIR/favorites"
PID_FILE="/tmp/tradio_player.pid"
NOW_PLAYING_FILE="/tmp/tradio_current.txt"

# Default volume
VOLUME=100

# Default player (can be 'cvlc' or 'mpv')
PLAYER="cvlc"

# Dependency check with generic instructions
check_dependencies() {
	local deps=("$PLAYER" "mpv")
	local missing=()

	for dep in "${deps[@]}"; do
		if ! command -v "$dep" >/dev/null 2>&1; then
			missing+=("$dep")
		fi
	done

	if [ ${#missing[@]} -ne 0 ]; then
		echo -e "${RED}Missing dependencies: ${missing[*]}${NC}"
		echo "Please install the following packages using your system's package manager:"
		for dep in "${missing[@]}"; do
			echo "- $dep"
		done
		exit 1
	fi
}

# Configuration management
init_config() {
	mkdir -p "$CONFIG_DIR"
	[ ! -f "$CONFIG_FILE" ] && echo "volume=$VOLUME" >"$CONFIG_FILE"
	[ ! -f "$HISTORY_FILE" ] && touch "$HISTORY_FILE"
	[ ! -f "$FAVORITES_FILE" ] && touch "$FAVORITES_FILE"

	# Read configuration
	source "$CONFIG_FILE"
}

# Create the ordered station list
create_station_list() {
	# First, include Virgin Radio
	SORTED_STATIONS=("Virgin Radio")

	# Then add all other stations alphabetically
	local temp_stations=()
	for station in "${!RADIOS[@]}"; do
		if [ "$station" != "Virgin Radio" ]; then
			temp_stations+=("$station")
		fi
	done

	# Sort the temporary array
	IFS=$'\n' sorted=($(sort <<<"${temp_stations[*]}"))
	unset IFS

	# Combine arrays
	SORTED_STATIONS+=("${sorted[@]}")
}

# History management
add_to_history() {
	local name=$1
	echo "$(date '+%Y-%m-%d %H:%M:%S') - $name" >>"$HISTORY_FILE"
}

# Favorites management
add_to_favorites() {
	local name=$1
	if ! grep -q "^$name$" "$FAVORITES_FILE"; then
		echo "$name" >>"$FAVORITES_FILE"
		echo -e "${GREEN}Added $name to favorites${NC}"
	fi
}

remove_from_favorites() {
	local name=$1
	sed -i "/^$name$/d" "$FAVORITES_FILE"
	echo -e "${YELLOW}Removed $name from favorites${NC}"
}

# Function to check if radio is playing
is_radio_playing() {
	if [ -f "$PID_FILE" ]; then
		local pid
		pid=$(cat "$PID_FILE")
		if ps -p "$pid" >/dev/null 2>&1; then
			return 0 # Radio is playing
		fi
	fi
	return 1 # Radio is not playing
}

# Function to stop playing radio
stop_radio() {
	if [ -f "$PID_FILE" ]; then
		local pid
		pid=$(cat "$PID_FILE")
		if ps -p "$pid" >/dev/null 2>&1; then
			echo -e "${YELLOW}Stopping radio...${NC}"
			kill "$pid" >/dev/null 2>&1
			rm -f "$PID_FILE"
			rm -f "$NOW_PLAYING_FILE"
		fi
	fi
}

# Volume control for various environments
change_volume() {
	local new_vol=$1
	VOLUME=$new_vol
	sed -i "s/volume=.*/volume=$VOLUME/" "$CONFIG_FILE"

	# Try different volume control methods
	if command -v pactl >/dev/null 2>&1; then
		pactl set-sink-volume @DEFAULT_SINK@ "${VOLUME}%"
	elif command -v amixer >/dev/null 2>&1; then
		amixer -q sset Master "${VOLUME}%" 2>/dev/null
	fi
}

# Enhanced radio playback function with PID tracking
play_radio() {
	local url=$1
	local name=$2
	local toggle=$3
	local play_status=0

	# Validate input parameters
	if [[ -z "$url" || -z "$name" ]]; then
		echo -e "${RED}Error: Missing required parameters${NC}"
		return 1
	fi

	# Handle toggle logic
	if [[ "$toggle" = "true" && -f "$NOW_PLAYING_FILE" ]]; then
		local current_station
		current_station=$(cat "$NOW_PLAYING_FILE" 2>/dev/null)

		if [[ -n "$current_station" && "$current_station" = "$name" ]]; then
			stop_radio
			return 0
		elif is_radio_playing; then
			stop_radio
		fi
	fi

	# Notification and history
	echo -e "${GREEN}Starting: $name${NC}"
	if command -v notify-send >/dev/null 2>&1; then
		notify-send -i "audio-x-generic" "🎵 Radio Player" "Now playing: $name" -t 2000
	fi
	add_to_history "$name"

	# Start player based on selected player
	if [[ "$PLAYER" == "cvlc" ]]; then
		cvlc --no-video \
			--play-and-exit \
			--quiet \
			--intf dummy \
			--volume="$VOLUME" \
			"$url" 2>/dev/null &
		play_status=$?
	elif [[ "$PLAYER" == "mpv" ]]; then
		mpv --no-video \
			--quiet \
			--volume="$VOLUME" \
			"$url" 2>/dev/null &
		play_status=$?
	else
		echo -e "${RED}Unsupported player: $PLAYER${NC}"
		return 1
	fi

	# Handle player start status
	if [[ $play_status -eq 0 ]]; then
		# Save PID and current station
		echo $! >"$PID_FILE"
		echo "$name" >"$NOW_PLAYING_FILE"
		chmod 600 "$PID_FILE" "$NOW_PLAYING_FILE"

		# Verify player is actually running
		sleep 1
		if ! is_radio_playing; then
			rm -f "$PID_FILE" "$NOW_PLAYING_FILE"
			echo -e "${RED}Failed to start playback${NC}"
			return 1
		fi
		return 0
	else
		rm -f "$PID_FILE" "$NOW_PLAYING_FILE"
		echo -e "${RED}Failed to start player${NC}"
		return 1
	fi
}

# Function to play station by number
play_station_by_number() {
	local number=$1
	local toggle=$2

	if [ "$number" -gt 0 ] && [ "$number" -le ${#SORTED_STATIONS[@]} ]; then
		local station_name="${SORTED_STATIONS[$((number - 1))]}"
		play_radio "${RADIOS[$station_name]}" "$station_name" "$toggle"

		# Clear and show minimal info
		clear
		echo -e "${BOLD}🎵 Terminal Radio Player v1.1${NC}"
		echo "----------------------------------------"
		echo -e "Volume: $VOLUME%"
		echo -e "Now Playing: $station_name"
		echo -e "Player: $PLAYER"
		echo "----------------------------------------"

		exit 0
	else
		echo -e "${RED}Invalid station number: $number${NC}"
		echo "Available stations: 1-${#SORTED_STATIONS[@]}"
		exit 1
	fi
}

# Search function
search_radio() {
	local search_term=$1
	local matches=()

	for name in "${!RADIOS[@]}"; do
		if [[ ${name,,} =~ ${search_term,,} ]]; then
			matches+=("$name")
		fi
	done

	if [ ${#matches[@]} -eq 0 ]; then
		echo -e "${RED}No results found${NC}"
		return
	fi

	echo -e "${GREEN}Found stations:${NC}"
	local i=1
	for match in "${matches[@]}"; do
		echo -e "${BLUE}$i)${NC} $match"
		((i++))
	done

	echo -e "\nSelect station to play (0 to cancel): "
	read -r choice

	if [ "$choice" -gt 0 ] && [ "$choice" -le ${#matches[@]} ]; then
		play_radio "${RADIOS[${matches[$((choice - 1))]}]}" "${matches[$((choice - 1))]}"
	fi
}

# Improved menu display with better formatting
show_menu() {
	clear
	echo -e "${BOLD}🎵 Terminal Radio Player v1.1${NC}"
	echo "----------------------------------------"
	echo -e "${YELLOW}Volume: $VOLUME%${NC}"
	echo -e "${YELLOW}Player: $PLAYER${NC}"

	# Show current playback status
	if is_radio_playing && [ -f "$NOW_PLAYING_FILE" ]; then
		local current_station
		current_station=$(cat "$NOW_PLAYING_FILE" 2>/dev/null)
		echo -e "${GREEN}Now Playing: $current_station${NC}"
	else
		echo -e "${YELLOW}No station playing${NC}"
	fi
	echo "----------------------------------------"
	echo -e "${BLUE}Available Radio Stations:${NC}"
	echo "----------------------------------------"

	# Calculate the maximum station name length
	local max_length=0
	for name in "${!RADIOS[@]}"; do
		local name_length=${#name}
		[ "$name_length" -gt "$max_length" ] && max_length=$name_length
	done

	# Add padding for proper alignment
	local padding=$((max_length + 5))
	local columns=2 # Reduced columns for better readability
	local i=1
	local col=1

	# Display stations based on sorted array
	for name in "${SORTED_STATIONS[@]}"; do
		local number_pad=""
		[ $i -lt 10 ] && number_pad=" "

		# Add star for favorites
		local star=""
		grep -q "^$name$" "$FAVORITES_FILE" && star="★ "

		printf "(%s%d) %-${padding}s %s" "$number_pad" "$i" "$name" "$star"

		if [ $col -eq $columns ]; then
			echo ""
			col=1
		else
			col=$((col + 1))
			printf "    "
		fi
		((i++))
	done

	# Complete the last line if necessary
	[ $col -ne 1 ] && echo ""

	echo -e "\n${BLUE}Commands:${NC}"
	echo -e "r) Random Play    s) Search"
	echo -e "f) Favorites      h) History"
	echo -e "v) Volume         p) Toggle Player (cvlc/mpv)"
	echo -e "q) Quit"
	echo -e "\nYour choice: "
}

# Main program with argument handling
main() {
	check_dependencies
	init_config
	create_station_list

	# Handle command line arguments
	if [ $# -gt 0 ]; then
		case $1 in
		-h | --help)
			echo "Usage: tradio [OPTION] [NUMBER]"
			echo "Options:"
			echo "  -h, --help     Show this help"
			echo "  -t, --toggle   Toggle play/stop for given station"
			echo "  -s, --stop     Stop currently playing station"
			echo "  -l, --list     List all available stations"
			echo "  -p, --player   Switch player (cvlc/mpv)"
			echo "  NUMBER         Play station number (1-${#SORTED_STATIONS[@]})"
			exit 0
			;;
		-t | --toggle)
			if [ $# -eq 2 ]; then
				play_station_by_number "$2" "true"
			else
				echo -e "${RED}Error: Station number required for toggle${NC}"
				exit 1
			fi
			;;
		-s | --stop)
			stop_radio
			exit 0
			;;
		-l | --list)
			echo -e "${BLUE}Available Radio Stations:${NC}"
			local i=1
			for station in "${SORTED_STATIONS[@]}"; do
				echo "$i) $station"
				((i++))
			done
			exit 0
			;;
		-p | --player)
			# Toggle between VLC and MPV
			if [[ "$PLAYER" == "cvlc" ]]; then
				PLAYER="mpv"
				echo -e "${GREEN}Switched to MPV player${NC}"
			else
				PLAYER="cvlc"
				echo -e "${GREEN}Switched to VLC player${NC}"
			fi
			exit 0
			;;
		*)
			if [[ $1 =~ ^[0-9]+$ ]]; then
				play_station_by_number "$1" "false"
			else
				echo -e "${RED}Invalid argument: $1${NC}"
				exit 1
			fi
			;;
		esac
	fi

	# Interactive menu mode
	while true; do
		show_menu
		read -r choice

		case $choice in
		[0-9]*)
			if [ "$choice" -gt 0 ] && [ "$choice" -le ${#SORTED_STATIONS[@]} ]; then
				choice=$((choice - 1))
				station_name="${SORTED_STATIONS[$choice]}"
				play_radio "${RADIOS[$station_name]}" "$station_name" "true"
				# Wait for user input before returning to the menu
				echo -e "${GREEN}Press any key to return to the menu...${NC}"
				read -n 1 -s
			else
				echo -e "${RED}Invalid station number!${NC}"
				sleep 1
			fi
			;;
		r | R)
			random_idx=$((RANDOM % ${#SORTED_STATIONS[@]}))
			random_station="${SORTED_STATIONS[$random_idx]}"
			echo -e "${GREEN}Randomly selected: $random_station${NC}"
			play_radio "${RADIOS[$random_station]}" "$random_station" "true"
			# Wait for user input before returning to the menu
			echo -e "${GREEN}Press any key to return to the menu...${NC}"
			read -n 1 -s
			;;
		s | S)
			echo -e "Enter search term: "
			read -r search_term
			search_radio "$search_term"
			# Wait for user input before returning to the menu
			echo -e "${GREEN}Press any key to return to the menu...${NC}"
			read -n 1 -s
			;;
		f | F)
			echo -e "${BLUE}Favorites:${NC}"
			while read -r favorite; do
				if [ -n "$favorite" ]; then
					echo "$favorite"
					echo "1) Play  2) Remove  3) Next"
					read -r fchoice
					case $fchoice in
					1)
						play_radio "${RADIOS[$favorite]}" "$favorite" "true"
						# Wait for user input before returning to the menu
						echo -e "${GREEN}Press any key to return to the menu...${NC}"
						read -n 1 -s
						break
						;;
					2) remove_from_favorites "$favorite" ;;
					*) continue ;;
					esac
				fi
			done <"$FAVORITES_FILE"
			;;
		h | H)
			echo -e "${BLUE}Recently played:${NC}"
			tail -n 10 "$HISTORY_FILE"
			read -r
			;;
		v | V)
			echo -e "Enter new volume (0-100): "
			read -r new_vol
			if [[ "$new_vol" =~ ^[0-9]+$ ]] && [ "$new_vol" -ge 0 ] && [ "$new_vol" -le 100 ]; then
				change_volume "$new_vol"
			else
				echo -e "${RED}Invalid volume level!${NC}"
				sleep 1
			fi
			;;
		p | P)
			# Toggle between VLC and MPV
			if [[ "$PLAYER" == "cvlc" ]]; then
				PLAYER="mpv"
				echo -e "${GREEN}Switched to MPV player${NC}"
			else
				PLAYER="cvlc"
				echo -e "${GREEN}Switched to VLC player${NC}"
			fi
			sleep 1
			;;
		q | Q)
			echo -e "${GREEN}Goodbye!${NC}"
			cleanup
			;;
		*)
			echo -e "${RED}Invalid choice!${NC}"
			sleep 1
			;;
		esac
	done
}

# Cleanup function
cleanup() {
	stop_radio
	echo -e "\n${GREEN}Exiting...${NC}"
	exit 0
}

# Set up exit trap
trap cleanup INT TERM

# Start the program with all arguments
main "$@"
