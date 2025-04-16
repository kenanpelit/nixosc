#!/usr/bin/env bash
#set -x
#===============================================================================
#
#   Script: Integrated Mullvad VPN Manager
#   Version: 3.0.0
#   Date: 2025-04-13
#   Author: Kenan Pelit
#   Repository: https://github.com/kenanpelit/nixosc
#   Description: Comprehensive Mullvad VPN management utility combining basic
#                connection management with advanced relay selection and control
#
#   Features:
#   - Basic VPN connection controls (connect, disconnect, toggle, status)
#   - Protocol toggle between OpenVPN and WireGuard
#   - Random relay selection from global pool
#   - Country-specific relay selection
#   - City-specific relay selection
#   - Smart protocol switching for current location
#   - Favorites management
#   - Fastest relay selection with ping tests
#   - Log tracking for connections
#   - Auto-retry for failed connections
#   - Relay filtering (owned vs rented)
#   - Connection status and testing
#   - Timer-based automatic relay switching
#   - System notifications for connection events
#   - Timeout control for connections
#
#   License: MIT
#
#===============================================================================

# Set color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration and settings
VERSION="3.0.0"
SCRIPT_NAME=$(basename "$0")
TIMEOUT=30 # Seconds to wait for connection before timeout
CONNECTION_RETRIES=3

# Configuration directories and files
LOG_DIR="$HOME/.logs/mullvad"
CONFIG_DIR="$HOME/.config/mullvad"
FAVORITES_FILE="$CONFIG_DIR/favorites.txt"
HISTORY_FILE="$LOG_DIR/connection_history.log"

# Create directories if they don't exist
mkdir -p "$LOG_DIR"
mkdir -p "$CONFIG_DIR"
touch "$FAVORITES_FILE"

# Europe countries
EUROPE_COUNTRIES=("at" "be" "bg" "ch" "cz" "de" "dk" "ee" "es" "fi" "fr" "gb" "gr" "hr" "hu" "ie" "it" "nl" "no" "pl" "pt" "ro" "rs" "se" "si" "sk" "tr" "ua")
# Americas countries
AMERICAS_COUNTRIES=("br" "ca" "cl" "co" "mx" "pe" "us")
# Asia & Pacific countries
ASIA_COUNTRIES=("au" "hk" "id" "jp" "my" "ph" "sg" "th")
# Africa & Middle East
AFRICA_ME_COUNTRIES=("il" "za" "ng")
# Misc countries
MISC_COUNTRIES=("nz")

# Combine all countries for case statement checking
ALL_COUNTRIES=("${EUROPE_COUNTRIES[@]}" "${AMERICAS_COUNTRIES[@]}" "${ASIA_COUNTRIES[@]}" "${AFRICA_ME_COUNTRIES[@]}" "${MISC_COUNTRIES[@]}")

# Script sourcing kontrolü
[[ "${BASH_SOURCE[0]}" != "$0" ]] && echo "Script source edilemez!" && exit 1

# ----------------------------------------------------------------------------
# Basic functions from original mullvad-manager script
# ----------------------------------------------------------------------------

# Gerekli komutların varlığını kontrol et
check_requirements() {
	command -v mullvad >/dev/null 2>&1 || {
		echo -e "${RED}Hata: Mullvad VPN kurulu değil!${NC}"
		exit 1
	}

	# notify-send optional olabilir
	if ! command -v notify-send >/dev/null 2>&1; then
		echo -e "${YELLOW}Uyarı: notify-send bulunamadı, bildirimler devre dışı olacak.${NC}"
		# Bildirim fonksiyonunu override et
		notify() { :; }
	fi

	command -v jq >/dev/null 2>&1 || {
		echo -e "${YELLOW}Warning: jq is not installed. Some features will be limited${NC}"
	}
	command -v bc >/dev/null 2>&1 || {
		echo -e "${YELLOW}Warning: bc is not installed. 'fastest' feature will not work properly${NC}"
	}
}

# Bildirim gönderme fonksiyonu (daha esnek)
notify() {
	local title="$1"
	local message="$2"
	local icon="$3"

	notify-send -t 5000 "$title" "$message" -i "$icon"
}

# Loglama fonksiyonu
log() {
	local message="$1"
	local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
	local log_message="$timestamp $message"

	echo "$log_message"
	echo "$log_message" >>"$HISTORY_FILE"

	# Keep log file size reasonable (last 1000 entries)
	if [ "$(wc -l <"$HISTORY_FILE")" -gt 1000 ]; then
		tail -1000 "$HISTORY_FILE" >"$HISTORY_FILE.tmp"
		mv "$HISTORY_FILE.tmp" "$HISTORY_FILE"
	fi
}

# Mullvad VPN durumunu kontrol et
check_vpn_status() {
	local full_status
	full_status=$(mullvad status 2>/dev/null)

	if [[ $? -ne 0 ]]; then
		log "Hata: Mullvad VPN durum kontrolü başarısız oldu."
		return 2
	fi

	if echo "$full_status" | grep -q "Connected"; then
		# Bağlantı aktif
		return 0
	elif echo "$full_status" | grep -q "Connecting"; then
		# Bağlanıyor
		return 3
	elif echo "$full_status" | grep -q "Disconnecting"; then
		# Bağlantı kesiliyor
		return 4
	else
		# Bağlantı yok
		return 1
	fi
}

# Detaylı VPN durumunu göster (basic version)
show_basic_vpn_status() {
	local status_output
	status_output=$(mullvad status 2>/dev/null)

	if [[ $? -ne 0 ]]; then
		log "Hata: Mullvad VPN durum kontrolü başarısız oldu."
		notify "❌ MULLVAD VPN" "Status check failed" "security-low"
		return 1
	fi

	log "Mullvad VPN Durumu:"
	log "$status_output"

	if echo "$status_output" | grep -q "Connected"; then
		# Bağlantı konumunu çıkart
		local location
		location=$(echo "$status_output" | grep -o "in [^)]*" | sed 's/in //')
		notify "🔒 MULLVAD VPN" "Connected to $location" "security-high"
	else
		notify "🔓 MULLVAD VPN" "Disconnected" "security-medium"
	fi

	echo "$status_output"
}

# VPN'e bağlan (timeout'lu)
connect_basic_vpn() {
	log "Mullvad VPN'e bağlanılıyor..."
	mullvad connect >/dev/null 2>&1 &
	local pid=$!
	disown

	# Bağlantı için timeout ile bekle
	local counter=0
	while ((counter < TIMEOUT)); do
		sleep 1
		((counter++))

		check_vpn_status
		local status=$?

		if [[ $status -eq 0 ]]; then
			log "VPN bağlantısı başarıyla kuruldu."
			local location
			location=$(mullvad status | grep -o "in [^)]*" | sed 's/in //' || echo "VPN")
			notify "🔒 MULLVAD VPN" "Connected to $location" "security-high"
			return 0
		elif [[ $status -eq 1 ]]; then
			# Hala bağlı değil, devam et
			continue
		elif [[ $status -eq 2 ]]; then
			log "Hata: VPN durum kontrolü başarısız oldu."
			notify "❌ MULLVAD VPN" "Connection failed" "security-low"
			return 1
		fi
	done

	log "Hata: VPN bağlantısı zaman aşımına uğradı."
	notify "❌ MULLVAD VPN" "Connection timeout" "security-low"
	return 1
}

# VPN bağlantısını kes (basic)
disconnect_basic_vpn() {
	log "Mullvad VPN bağlantısı kesiliyor..."
	mullvad disconnect >/dev/null 2>&1 &
	local pid=$!
	disown

	# Bağlantı kesilmesi için kısa bir süre bekle
	sleep 2

	check_vpn_status
	if [[ $? -eq 1 ]]; then
		log "VPN bağlantısı başarıyla kesildi."
		notify "🔓 MULLVAD VPN" "Disconnected" "security-medium"
		return 0
	else
		log "Uyarı: VPN bağlantısı kesilirken bir sorun oluştu."
		notify "⚠️ MULLVAD VPN" "Disconnect issue" "security-low"
		return 1
	fi
}

# VPN bağlantısını aç/kapa (basic toggle)
toggle_basic_vpn() {
	check_vpn_status
	local status=$?

	if [[ $status -eq 0 ]]; then
		disconnect_basic_vpn
	elif [[ $status -eq 1 ]]; then
		connect_basic_vpn
	elif [[ $status -eq 3 ]]; then
		log "VPN şu anda bağlanıyor, lütfen bekleyin."
		notify "⏳ MULLVAD VPN" "Currently connecting..." "security-medium"
	elif [[ $status -eq 4 ]]; then
		log "VPN şu anda bağlantı kesiliyor, lütfen bekleyin."
		notify "⏳ MULLVAD VPN" "Currently disconnecting..." "security-medium"
	else
		log "Hata: VPN durumu belirlenemedi."
		notify "❌ MULLVAD VPN" "Status unknown" "security-low"
	fi
}

# ----------------------------------------------------------------------------
# Advanced functions from OSC Mullvad VPN Relay Manager
# ----------------------------------------------------------------------------

# Function to convert country code to name
get_country_name() {
	local country_code=$1
	case "$country_code" in
	"al") echo "Albania" ;;
	"au") echo "Australia" ;;
	"at") echo "Austria" ;;
	"be") echo "Belgium" ;;
	"br") echo "Brazil" ;;
	"bg") echo "Bulgaria" ;;
	"ca") echo "Canada" ;;
	"cl") echo "Chile" ;;
	"co") echo "Colombia" ;;
	"hr") echo "Croatia" ;;
	"cy") echo "Cyprus" ;;
	"cz") echo "Czech Republic" ;;
	"dk") echo "Denmark" ;;
	"ee") echo "Estonia" ;;
	"fi") echo "Finland" ;;
	"fr") echo "France" ;;
	"de") echo "Germany" ;;
	"gr") echo "Greece" ;;
	"hk") echo "Hong Kong" ;;
	"hu") echo "Hungary" ;;
	"id") echo "Indonesia" ;;
	"ie") echo "Ireland" ;;
	"il") echo "Israel" ;;
	"it") echo "Italy" ;;
	"jp") echo "Japan" ;;
	"my") echo "Malaysia" ;;
	"mx") echo "Mexico" ;;
	"nl") echo "Netherlands" ;;
	"nz") echo "New Zealand" ;;
	"ng") echo "Nigeria" ;;
	"no") echo "Norway" ;;
	"pe") echo "Peru" ;;
	"ph") echo "Philippines" ;;
	"pl") echo "Poland" ;;
	"pt") echo "Portugal" ;;
	"ro") echo "Romania" ;;
	"rs") echo "Serbia" ;;
	"sg") echo "Singapore" ;;
	"sk") echo "Slovakia" ;;
	"si") echo "Slovenia" ;;
	"za") echo "South Africa" ;;
	"es") echo "Spain" ;;
	"se") echo "Sweden" ;;
	"ch") echo "Switzerland" ;;
	"th") echo "Thailand" ;;
	"tr") echo "Turkey" ;;
	"ua") echo "Ukraine" ;;
	"gb") echo "United Kingdom" ;;
	"us") echo "United States" ;;
	*) echo "$country_code" ;;
	esac
}

# Function to convert city code to name
get_city_name() {
	local city_code=$1
	case "$city_code" in
	"tia") echo "Tirana" ;;
	"adl") echo "Adelaide" ;;
	"bne") echo "Brisbane" ;;
	"mel") echo "Melbourne" ;;
	"per") echo "Perth" ;;
	"syd") echo "Sydney" ;;
	"vie") echo "Vienna" ;;
	"bru") echo "Brussels" ;;
	"sao") echo "Sao Paulo" ;;
	"sof") echo "Sofia" ;;
	"yyc") echo "Calgary" ;;
	"mtr") echo "Montreal" ;;
	"tor") echo "Toronto" ;;
	"van") echo "Vancouver" ;;
	"scl") echo "Santiago" ;;
	"bog") echo "Bogota" ;;
	"zag") echo "Zagreb" ;;
	"nic") echo "Nicosia" ;;
	"prg") echo "Prague" ;;
	"cph") echo "Copenhagen" ;;
	"tll") echo "Tallinn" ;;
	"hel") echo "Helsinki" ;;
	"bod") echo "Bordeaux" ;;
	"mrs") echo "Marseille" ;;
	"par") echo "Paris" ;;
	"ber") echo "Berlin" ;;
	"dus") echo "Dusseldorf" ;;
	"fra") echo "Frankfurt" ;;
	"ath") echo "Athens" ;;
	"hkg") echo "Hong Kong" ;;
	"bud") echo "Budapest" ;;
	"jpu") echo "Jakarta" ;;
	"dub") echo "Dublin" ;;
	"tlv") echo "Tel Aviv" ;;
	"mil") echo "Milan" ;;
	"pmo") echo "Palermo" ;;
	"osa") echo "Osaka" ;;
	"tyo") echo "Tokyo" ;;
	"kul") echo "Kuala Lumpur" ;;
	"qro") echo "Queretaro" ;;
	"ams") echo "Amsterdam" ;;
	"akl") echo "Auckland" ;;
	"los") echo "Lagos" ;;
	"osl") echo "Oslo" ;;
	"svg") echo "Stavanger" ;;
	"lim") echo "Lima" ;;
	"mnl") echo "Manila" ;;
	"waw") echo "Warsaw" ;;
	"lis") echo "Lisbon" ;;
	"buh") echo "Bucharest" ;;
	"beg") echo "Belgrade" ;;
	"sin") echo "Singapore" ;;
	"bts") echo "Bratislava" ;;
	"lju") echo "Ljubljana" ;;
	"jnb") echo "Johannesburg" ;;
	"bcn") echo "Barcelona" ;;
	"mad") echo "Madrid" ;;
	"vlc") echo "Valencia" ;;
	"got") echo "Gothenburg" ;;
	"mma") echo "Malmö" ;;
	"sto") echo "Stockholm" ;;
	"zrh") echo "Zurich" ;;
	"bkk") echo "Bangkok" ;;
	"ist") echo "Istanbul" ;;
	"glw") echo "Glasgow" ;;
	"lon") echo "London" ;;
	"mnc") echo "Manchester" ;;
	"iev") echo "Kyiv" ;;
	"qas") echo "Ashburn" ;;
	"atl") echo "Atlanta" ;;
	"bos") echo "Boston" ;;
	"chi") echo "Chicago" ;;
	"dal") echo "Dallas" ;;
	"den") echo "Denver" ;;
	"det") echo "Detroit" ;;
	"hou") echo "Houston" ;;
	"lax") echo "Los Angeles" ;;
	"txc") echo "McAllen" ;;
	"mia") echo "Miami" ;;
	"nyc") echo "New York" ;;
	"phx") echo "Phoenix" ;;
	"rag") echo "Raleigh" ;;
	"slc") echo "Salt Lake City" ;;
	"sjc") echo "San Jose" ;;
	"sea") echo "Seattle" ;;
	"uyk") echo "Secaucus" ;;
	"was") echo "Washington DC" ;;
	*) echo "$city_code" ;;
	esac
}

# Get current relay
get_current_relay() {
	mullvad relay get | grep 'Location:' | awk -F'hostname ' '{print $2}'
}

# Get random relay
get_random_relay() {
	local country=$1
	local city=$2
	local type=$3 # "owned" or "rented" or empty for any

	# Basic command to get relays
	local grep_pattern=""

	# Build the grep pattern based on parameters
	if [[ -n $country && -n $city ]]; then
		grep_pattern="^[[:space:]]*$country-$city-(wg|ovpn)-"
	elif [[ -n $country ]]; then
		grep_pattern="^[[:space:]]*$country-[a-z]{3}-(wg|ovpn)-"
	else
		grep_pattern="^[[:space:]]*[a-z]{2}-[a-z]{3}-(wg|ovpn)-"
	fi

	# Add filter for owned/rented if specified
	local awk_filter='{print $1}'
	if [[ "$type" == "owned" ]]; then
		awk_filter='{if ($NF ~ /\(Mullvad-owned\)/) print $1}'
	elif [[ "$type" == "rented" ]]; then
		awk_filter='{if ($NF ~ /\(rented\)/) print $1}'
	fi

	readarray -t relays < <(mullvad relay list | grep -E "$grep_pattern" | awk "$awk_filter")

	if [ ${#relays[@]} -gt 0 ]; then
		echo "${relays[RANDOM % ${#relays[@]}]}"
	else
		echo ""
	fi
}

# Toggle between protocols
toggle_protocol() {
	local current_relay=$(get_current_relay)
	local country_city=$(echo $current_relay | cut -d'-' -f1,2)

	if [[ $current_relay == *"ovpn"* ]]; then
		readarray -t new_relays < <(mullvad relay list | grep "$country_city-wg" | awk '{print $1}')
		local new_type="WireGuard"
	else
		readarray -t new_relays < <(mullvad relay list | grep "$country_city-ovpn" | awk '{print $1}')
		local new_type="OpenVPN"
	fi

	if [ ${#new_relays[@]} -gt 0 ]; then
		local new_relay="${new_relays[RANDOM % ${#new_relays[@]}]}"
		local country=$(echo $new_relay | cut -d'-' -f1)
		local city=$(echo $new_relay | cut -d'-' -f2)

		log "Switching from ${current_relay} to ${new_relay}..."

		mullvad relay set location $country $city $new_relay >/dev/null 2>&1

		if [ $? -eq 0 ]; then
			log "Successfully switched to $new_type: $new_relay"
			notify "🔄 MULLVAD VPN" "Switched to $new_type: $new_relay" "security-high"
		else
			log "Failed to switch protocol"
			notify "❌ MULLVAD VPN" "Failed to switch protocol" "security-low"
		fi
	else
		log "No alternative protocol found for this location"
		notify "⚠️ MULLVAD VPN" "No alternative protocol available" "security-medium"
	fi
}

# Connect to a specific relay
connect_to_relay() {
	local relay=$1
	local max_retries=$CONNECTION_RETRIES
	local retry_count=0

	if [[ -z "$relay" ]]; then
		log "No relay specified or found"
		notify "❌ MULLVAD VPN" "No relay specified or found" "security-low"
		return 1
	fi

	local country=$(echo $relay | cut -d'-' -f1)
	local city=$(echo $relay | cut -d'-' -f2)
	local protocol=$(echo $relay | cut -d'-' -f3)

	log "Connecting to relay: $relay (${protocol^^} in $(get_city_name $city), $(get_country_name $country))"
	notify "🔄 MULLVAD VPN" "Connecting to $(get_city_name $city), $(get_country_name $country)" "security-medium"

	while [ $retry_count -lt $max_retries ]; do
		mullvad relay set location $country $city $relay >/dev/null 2>&1

		if [ $? -eq 0 ]; then
			log "Successfully connected to: $relay"
			notify "🔒 MULLVAD VPN" "Connected to $(get_city_name $city), $(get_country_name $country)" "security-high"
			return 0
		else
			retry_count=$((retry_count + 1))
			log "Connection attempt $retry_count failed. Retrying..."
			sleep 1
		fi
	done

	log "Failed to connect after $max_retries attempts."

	# Try a different relay in the same city
	log "Trying a different relay..."
	local alternate_relay=$(get_random_relay $country $city)

	if [[ -n "$alternate_relay" && "$alternate_relay" != "$relay" ]]; then
		log "Trying alternate relay: $alternate_relay"
		connect_to_relay "$alternate_relay"
	else
		log "No alternative relays available in $city, $country."
		notify "❌ MULLVAD VPN" "Failed to connect" "security-low"
		return 1
	fi
}

# Manage favorite relays
manage_favorites() {
	local action=$1
	local current_relay=$(get_current_relay)

	case "$action" in
	"add")
		if [[ -z "$current_relay" ]]; then
			log "No active relay to add"
			notify "❌ MULLVAD VPN" "No active relay to add to favorites" "security-low"
			return 1
		fi

		# Check if relay is already in favorites
		if grep -q "^$current_relay|" "$FAVORITES_FILE" || grep -q "^$current_relay$" "$FAVORITES_FILE"; then
			log "Relay $current_relay is already in favorites"
			notify "ℹ️ MULLVAD VPN" "Relay already in favorites" "security-medium"
		else
			# Ping ile kaydetmek için ping testi yap
			local ip=$(mullvad relay list | grep -E "^[[:space:]]*$current_relay" | awk '{print $2}' | tr -d '(),')
			local ping_avg="N/A"

			if [[ -n "$ip" && "$ip" != *":"* ]]; then
				ping_result=$(ping -c 3 -W 2 $ip 2>/dev/null | grep 'avg' | awk -F '/' '{print $5}')
				if [[ -n "$ping_result" ]]; then
					ping_avg=$ping_result
				fi
			fi

			echo "$current_relay|$ping_avg" >>"$FAVORITES_FILE"
			log "Added $current_relay to favorites (ping: $ping_avg ms)"
			notify "⭐ MULLVAD VPN" "Added relay to favorites (ping: $ping_avg ms)" "security-high"
		fi
		;;

	"remove")
		if [[ ! -s "$FAVORITES_FILE" ]]; then
			log "Favorites list is empty"
			notify "ℹ️ MULLVAD VPN" "Favorites list is empty" "security-medium"
			return 1
		fi

		echo -e "${CYAN}Select relay to remove:${NC}"
		local i=1
		while IFS="|" read -r relay ping_time; do
			local country=$(echo "$relay" | cut -d'-' -f1)
			local city=$(echo "$relay" | cut -d'-' -f2)
			local protocol=$(echo "$relay" | cut -d'-' -f3)

			local ping_display=""
			if [[ -n "$ping_time" && "$ping_time" != "N/A" ]]; then
				ping_display=" ${PURPLE}[${ping_time} ms]${NC}"
			fi

			echo -e "${YELLOW}$i)${NC} $relay (${GREEN}$(get_country_name $country)${NC}, ${GREEN}$(get_city_name $city)${NC}, ${BLUE}${protocol^^}${NC})${ping_display}"
			i=$((i + 1))
		done <"$FAVORITES_FILE"

		echo -e "${CYAN}Enter number (1-$((i - 1))) or 'q' to cancel:${NC} "
		read -r choice

		if [[ "$choice" == "q" ]]; then
			log "Operation cancelled"
			return 0
		fi

		if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -lt "$i" ]; then
			local removed_relay=$(sed -n "${choice}p" "$FAVORITES_FILE" | cut -d"|" -f1)
			sed -i "${choice}d" "$FAVORITES_FILE"
			log "Removed $removed_relay from favorites"
			notify "🗑️ MULLVAD VPN" "Removed relay from favorites" "security-medium"
		else
			log "Invalid selection"
			notify "❌ MULLVAD VPN" "Invalid selection" "security-low"
		fi
		;;

	"list")
		if [[ ! -s "$FAVORITES_FILE" ]]; then
			log "Favorites list is empty"
			return 1
		fi

		echo -e "${CYAN}Favorite relays:${NC}"
		local i=1
		while IFS="|" read -r relay ping_time; do
			local country=$(echo "$relay" | cut -d'-' -f1)
			local city=$(echo "$relay" | cut -d'-' -f2)
			local protocol=$(echo "$relay" | cut -d'-' -f3)

			local ping_display=""
			if [[ -n "$ping_time" && "$ping_time" != "N/A" ]]; then
				ping_display=" ${PURPLE}[${ping_time} ms]${NC}"
			fi

			echo -e "${YELLOW}$i)${NC} $relay (${GREEN}$(get_country_name $country)${NC}, ${GREEN}$(get_city_name $city)${NC}, ${BLUE}${protocol^^}${NC})${ping_display}"
			i=$((i + 1))
		done <"$FAVORITES_FILE"
		;;

	"connect")
		if [[ ! -s "$FAVORITES_FILE" ]]; then
			log "Favorites list is empty"
			notify "ℹ️ MULLVAD VPN" "Favorites list is empty" "security-medium"
			return 1
		fi

		echo -e "${CYAN}Select relay to connect to:${NC}"
		local i=1
		while IFS="|" read -r relay ping_time; do
			local country=$(echo "$relay" | cut -d'-' -f1)
			local city=$(echo "$relay" | cut -d'-' -f2)
			local protocol=$(echo "$relay" | cut -d'-' -f3)

			local ping_display=""
			if [[ -n "$ping_time" && "$ping_time" != "N/A" ]]; then
				ping_display=" ${PURPLE}[${ping_time} ms]${NC}"
			fi

			echo -e "${YELLOW}$i)${NC} $relay (${GREEN}$(get_country_name $country)${NC}, ${GREEN}$(get_city_name $city)${NC}, ${BLUE}${protocol^^}${NC})${ping_display}"
			i=$((i + 1))
		done <"$FAVORITES_FILE"

		echo -e "${CYAN}Enter number (1-$((i - 1))) or 'q' to cancel:${NC} "
		read -r choice

		if [[ "$choice" == "q" ]]; then
			log "Operation cancelled"
			return 0
		fi

		if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -lt "$i" ]; then
			local selected_relay=$(sed -n "${choice}p" "$FAVORITES_FILE" | cut -d"|" -f1)
			connect_to_relay "$selected_relay"
		else
			log "Invalid selection"
			notify "❌ MULLVAD VPN" "Invalid selection" "security-low"
		fi
		;;

	*)
		echo -e "${RED}Unknown favorites action: $action${NC}"
		echo -e "${YELLOW}Available actions: add, remove, list, connect${NC}"
		;;
	esac
}

# Eski favori dosyası formatını güncelleyen bir fonksiyon:
migrate_favorites_format() {
	if [[ ! -s "$FAVORITES_FILE" ]]; then
		return 0 # Dosya boş veya yok, bir şey yapmaya gerek yok
	fi

	local temp_file="${FAVORITES_FILE}.tmp"

	while read -r line; do
		# Eğer satır zaten | içeriyorsa, yeni formatta demektir
		if [[ "$line" == *"|"* ]]; then
			echo "$line" >>"$temp_file"
		else
			# Eski formatta, ping bilgisini ekle
			echo "${line}|N/A" >>"$temp_file"
		fi
	done <"$FAVORITES_FILE"

	mv "$temp_file" "$FAVORITES_FILE"
	log "Favorites file format updated to include ping times"
}

# Function to show comprehensive connection status
show_status() {
	echo -e "${BLUE}=== Mullvad VPN Connection Status ===${NC}"

	# Check if connected to Mullvad
	local connection_status=$(mullvad status)
	if [[ "$connection_status" == *"Connected"* ]]; then
		echo -e "${GREEN}Status: Connected${NC}"

		# Get current relay details
		local current_relay=$(get_current_relay)
		local country=$(echo $current_relay | cut -d'-' -f1)
		local city=$(echo $current_relay | cut -d'-' -f2)
		local protocol=$(echo $current_relay | cut -d'-' -f3)

		echo -e "Current relay: ${CYAN}$current_relay${NC}"
		echo -e "Country: ${YELLOW}$(get_country_name $country)${NC}"
		echo -e "City: ${YELLOW}$(get_city_name $city)${NC}"
		echo -e "Protocol: ${YELLOW}${protocol^^}${NC}"

		# Get IP information
		echo -e "\n${BLUE}IP Information:${NC}"
		curl -s https://am.i.mullvad.net/json | jq -r '. | "Public IP: \(.ip)\nLocation: \(.city), \(.country)\nMullvad Server: \(.mullvad_exit_ip)"' 2>/dev/null || echo -e "${RED}Could not fetch IP information${NC}"
	else
		echo -e "${RED}Status: Not Connected${NC}"
		echo -e "Your real IP is exposed!"

		# Show real IP
		echo -e "\n${BLUE}IP Information:${NC}"
		curl -s https://ipinfo.io | jq -r '. | "Public IP: \(.ip)\nLocation: \(.city), \(.region), \(.country)"' 2>/dev/null || echo -e "${RED}Could not fetch IP information${NC}"
	fi
}

# Timer variables
TIMER_PID=""
TIMER_FILE="$CONFIG_DIR/timer.pid"

# Function to start the auto-switching timer
start_timer() {
	local minutes=$1

	# Check if timer is already running
	if [[ -f "$TIMER_FILE" ]]; then
		local pid=$(cat "$TIMER_FILE")
		if ps -p $pid >/dev/null; then
			log "Timer already running with PID $pid"
			echo -e "${YELLOW}Timer already running with PID $pid${NC}"
			echo -e "Stop it first with: ${GREEN}$SCRIPT_NAME timer stop${NC}"
			return 1
		else
			# PID file exists but process doesn't, clean up
			rm -f "$TIMER_FILE"
		fi
	fi

	# Validate input
	if ! [[ "$minutes" =~ ^[0-9]+$ ]]; then
		log "Error: Minutes must be a positive integer"
		echo -e "${RED}Error: Minutes must be a positive integer${NC}"
		return 1
	fi

	if [ "$minutes" -lt 5 ]; then
		log "Warning: Short intervals may lead to connection instability"
		echo -e "${YELLOW}Warning: Short intervals may lead to connection instability${NC}"
	fi

	# Start the timer process in the background
	{
		while true; do
			sleep $((minutes * 60))
			echo "$(date): Auto-switching relay..." >>"$LOG_DIR/timer.log"

			# Choose random relay and connect
			local relay=$(get_random_relay)
			local country=$(echo $relay | cut -d'-' -f1)
			local city=$(echo $relay | cut -d'-' -f2)

			mullvad relay set location $country $city $relay >/dev/null 2>&1
			log "Timer auto-switched to $relay"
			notify "🔄 MULLVAD VPN" "Auto-switched to a new relay" "security-medium"
		done
	} &

	TIMER_PID=$!
	echo $TIMER_PID >"$TIMER_FILE"

	log "Timer started. Will switch relay every $minutes minutes."
	echo -e "${GREEN}Timer started. Will switch relay every $minutes minutes.${NC}"
	echo -e "Timer running with PID $TIMER_PID"
	echo -e "To stop, run: ${CYAN}$SCRIPT_NAME timer stop${NC}"
	notify "⏱️ MULLVAD VPN" "Auto-switch timer started ($minutes min)" "security-medium"
}

# Function to stop the auto-switching timer
stop_timer() {
	if [[ -f "$TIMER_FILE" ]]; then
		local pid=$(cat "$TIMER_FILE")
		if ps -p $pid >/dev/null; then
			kill $pid
			log "Timer stopped"
			echo -e "${GREEN}Timer stopped${NC}"
			notify "⏱️ MULLVAD VPN" "Auto-switch timer stopped" "security-medium"
		else
			log "Timer process is not running but PID file exists"
			echo -e "${YELLOW}Timer process is not running but PID file exists${NC}"
		fi
		rm -f "$TIMER_FILE"
	else
		log "No timer is currently running"
		echo -e "${RED}No timer is currently running${NC}"
		notify "ℹ️ MULLVAD VPN" "No timer is running" "security-medium"
	fi
}

# Function to test connection for leaks
test_connection() {
	echo -e "${BLUE}=== Testing Mullvad VPN Connection ===${NC}"

	# Check if connected to Mullvad
	local connection_status=$(mullvad status)
	if [[ "$connection_status" != *"Connected"* ]]; then
		echo -e "${RED}Not connected to Mullvad VPN. Test aborted.${NC}"
		notify "⚠️ MULLVAD VPN" "Not connected, test aborted" "security-low"
		return 1
	fi

	echo -e "${YELLOW}Running leak tests...${NC}"

	# Test DNS leaks
	echo -e "\n${CYAN}DNS Leak Test:${NC}"
	local dns_servers=$(dig +short whoami.akamai.net)
	if [[ -z "$dns_servers" ]]; then
		echo -e "${RED}Could not perform DNS leak test${NC}"
	else
		echo -e "DNS Servers: $dns_servers"

		# Check if DNS servers are Mullvad's
		if [[ "$dns_servers" == *"mullvad"* ]]; then
			echo -e "${GREEN}✓ DNS is secure through Mullvad${NC}"
		else
			echo -e "${RED}✗ Possible DNS leak detected!${NC}"
			notify "⚠️ MULLVAD VPN" "Possible DNS leak detected" "security-low"
		fi
	fi

	# Test for WebRTC leaks (simplified, just a reminder)
	echo -e "\n${CYAN}WebRTC Leak:${NC}"
	echo -e "${YELLOW}Note: WebRTC leaks cannot be tested from CLI. Please visit https://mullvad.net/check/ in your browser.${NC}"

	# Check Mullvad API to confirm we're using their service
	echo -e "\n${CYAN}Mullvad Connection Check:${NC}"
	local mullvad_check=$(curl -s https://am.i.mullvad.net/connected)
	if [[ "$mullvad_check" == *"You are connected"* ]]; then
		echo -e "${GREEN}✓ Confirmed connected to Mullvad network${NC}"
		notify "✅ MULLVAD VPN" "Connection test passed" "security-high"
	else
		echo -e "${RED}✗ Not properly connected to Mullvad network!${NC}"
		notify "⚠️ MULLVAD VPN" "Connection test failed" "security-low"
	fi

	echo -e "\n${BLUE}Test complete. For comprehensive testing, visit https://mullvad.net/check/ in your browser.${NC}"
}

# Find_fastest_relay fonksiyonunu düzenleme
find_fastest_relay() {
	local country=$1
	local add_to_favorites=$2 # Yeni parametre: favorilere eklemek için
	local timeout=2           # Timeout in seconds for ping
	local iterations=3        # Number of pings per relay
	local max_relays=10       # Maximum number of relays to test

	log "Finding fastest relay..."
	notify "🔍 MULLVAD VPN" "Finding fastest relay..." "security-medium"

	# Get relays to test
	local relays=()
	if [[ -n "$country" ]]; then
		readarray -t relays < <(mullvad relay list | grep -E "^[[:space:]]*$country-[a-z]{3}-(wg|ovpn)-" | awk '{print $1}' | shuf -n $max_relays)
		log "Testing up to $max_relays relays in $(get_country_name $country)..."
	else
		readarray -t relays < <(mullvad relay list | grep -E "^[[:space:]]*[a-z]{2}-[a-z]{3}-(wg|ovpn)-" | awk '{print $1}' | shuf -n $max_relays)
		log "Testing up to $max_relays relays globally..."
	fi

	if [ ${#relays[@]} -eq 0 ]; then
		log "No relays found for testing"
		notify "❌ MULLVAD VPN" "No relays found for testing" "security-low"
		return 1
	fi

	local best_relay=""
	local best_avg=9999

	for relay in "${relays[@]}"; do
		local ip=$(mullvad relay list | grep -E "^[[:space:]]*$relay" | awk '{print $2}' | tr -d '(),')

		# Skip if we can't extract an IP
		if [[ -z "$ip" || "$ip" == *":"* ]]; then # Skip IPv6 addresses
			continue
		fi

		local country=$(echo $relay | cut -d'-' -f1)
		local city=$(echo $relay | cut -d'-' -f2)

		echo -en "${CYAN}Testing $relay (${YELLOW}$(get_city_name $city), $(get_country_name $country)${CYAN})...${NC} "

		# Run ping and get average
		local ping_result=$(ping -c $iterations -W $timeout $ip 2>/dev/null | grep 'avg' | awk -F '/' '{print $5}')

		if [[ -n "$ping_result" ]]; then
			echo -e "${GREEN}${ping_result} ms${NC}"

			# Check if this is better than our current best
			if (($(echo "$ping_result < $best_avg" | bc -l))); then
				best_avg=$ping_result
				best_relay=$relay
			fi
		else
			echo -e "${RED}timeout${NC}"
		fi
	done

	if [[ -n "$best_relay" ]]; then
		echo -e "\n${GREEN}Best relay: $best_relay with average ping ${best_avg} ms${NC}"

		# Bağlantıyı kur
		connect_to_relay "$best_relay"

		if [[ "$add_to_favorites" == "true" ]]; then
			# Relay ping süresiyle birlikte kaydet
			local relay_with_ping="${best_relay}|${best_avg}"

			# Favorilerde olup olmadığını kontrol et
			if grep -q "^${best_relay}|" "$FAVORITES_FILE"; then
				log "Relay $best_relay is already in favorites, updating ping time"
				# Mevcut satırı güncelle
				sed -i "s|^${best_relay}|.*|${relay_with_ping}|" "$FAVORITES_FILE"
				notify "ℹ️ MULLVAD VPN" "Relay ping time updated in favorites (${best_avg} ms)" "security-medium"
			else
				echo "$relay_with_ping" >>"$FAVORITES_FILE"
				log "Added $best_relay to favorites (ping: ${best_avg} ms)"
				notify "⭐ MULLVAD VPN" "Added fastest relay to favorites (${best_avg} ms)" "security-high"
			fi
		fi
	else
		echo -e "${RED}Could not find a responsive relay${NC}"
		notify "❌ MULLVAD VPN" "No responsive relay found" "security-low"
		return 1
	fi
}

# Function to show help message
show_help() {
	echo -e "${BLUE}===== Integrated Mullvad VPN Manager v$VERSION =====${NC}"
	echo -e ""
	echo -e "${CYAN}Usage:${NC} $SCRIPT_NAME [COMMAND] [ARGUMENTS]"
	echo -e ""
	echo -e "${YELLOW}Basic Connection Commands:${NC}"
	echo -e "    ${GREEN}connect${NC}           Connect to Mullvad VPN using default settings"
	echo -e "    ${GREEN}disconnect${NC}        Disconnect from Mullvad VPN"
	echo -e "    ${GREEN}toggle${NC}            Toggle VPN connection on/off"
	echo -e "    ${GREEN}status${NC}            Show current connection status and details"
	echo -e "    ${GREEN}test${NC}              Test current connection for leaks/issues"
	echo -e "    ${GREEN}help${NC}              Show this help message"
	echo -e ""
	echo -e "${YELLOW}Protocol Commands:${NC}"
	echo -e "    ${GREEN}protocol${NC}          Toggle between OpenVPN and WireGuard for current location"
	echo -e ""
	echo -e "${YELLOW}Location Selection:${NC}"
	echo -e "    ${GREEN}random${NC}            Switch to a random relay from all available relays"
	echo -e "    ${GREEN}<country>${NC}         Switch to a random relay in a specific country (e.g., us, fr, jp)"
	echo -e "    ${GREEN}<country> <city>${NC}  Switch to a random relay in a specific city (e.g., us nyc, de fra)"
	echo -e ""
	echo -e "${YELLOW}Advanced Selection:${NC}"
	echo -e "    ${GREEN}fastest${NC} [country]            Find and connect to the fastest relay (optionally in a specific country)"
	echo -e "    ${GREEN}fastest-fav${NC} [country]       Find fastest relay, connect and add to favorites"
	echo -e "    ${GREEN}owned${NC} [country]              Connect to a Mullvad-owned relay (not rented)"
	echo -e "    ${GREEN}rented${NC} [country]             Connect to a rented relay infrastructure"
	echo -e ""
	echo -e "${YELLOW}Favorites Management:${NC}"
	echo -e "    ${GREEN}favorite add${NC}       Add current relay to favorites"
	echo -e "    ${GREEN}favorite remove${NC}    Remove a relay from favorites (interactive)"
	echo -e "    ${GREEN}favorite list${NC}      List all favorite relays"
	echo -e "    ${GREEN}favorite connect${NC}   Connect to a favorite relay (interactive)"
	echo -e ""
	echo -e "${YELLOW}Automatic Switching:${NC}"
	echo -e "    ${GREEN}timer${NC} <minutes>    Switch relays automatically every X minutes"
	echo -e "    ${GREEN}timer stop${NC}         Stop the automatic switching timer"
	echo -e ""
	echo -e "${YELLOW}Examples:${NC}"
	echo -e "    ${GREEN}$SCRIPT_NAME connect${NC}           # Connect to VPN with default settings"
	echo -e "    ${GREEN}$SCRIPT_NAME disconnect${NC}        # Disconnect from VPN"
	echo -e "    ${GREEN}$SCRIPT_NAME toggle${NC}            # Toggle VPN connection on/off"
	echo -e "    ${GREEN}$SCRIPT_NAME protocol${NC}          # Switch between OpenVPN/WireGuard"
	echo -e "    ${GREEN}$SCRIPT_NAME random${NC}            # Switch to any random relay"
	echo -e "    ${GREEN}$SCRIPT_NAME fr${NC}                # Switch to French relay"
	echo -e "    ${GREEN}$SCRIPT_NAME us nyc${NC}            # Switch to a New York relay"
	echo -e "    ${GREEN}$SCRIPT_NAME fastest de${NC}        # Find fastest German relay"
	echo -e "    ${GREEN}$SCRIPT_NAME fastest-fav${NC}       # Find fastest relay and add to favorites"
	echo -e "    ${GREEN}$SCRIPT_NAME favorite add${NC}      # Add current relay to favorites"
	echo -e "    ${GREEN}$SCRIPT_NAME timer 30${NC}          # Change relay every 30 minutes"
	echo -e ""
	echo -e "${YELLOW}Available Countries:${NC}"
	echo -e "    ${CYAN}Europe:${NC} at be bg ch cz de dk ee es fi fr gb gr hr hu ie it nl no pl pt ro rs se si sk tr ua"
	echo -e "    ${CYAN}Americas:${NC} br ca cl co mx pe us"
	echo -e "    ${CYAN}Asia/Pacific:${NC} au hk id jp my ph sg th"
	echo -e "    ${CYAN}Africa/ME:${NC} il ng za"
	echo -e "    ${CYAN}Other:${NC} nz"
}

# Main function to handle all commands
main() {
	# Check requirements first
	check_requirements
	migrate_favorites_format

	# Process command line arguments
	case "${1:-help}" in
	# Basic connection commands
	"connect")
		check_vpn_status
		if [[ $? -eq 0 ]]; then
			log "VPN already connected."
			notify "ℹ️ MULLVAD VPN" "Already connected" "security-high"
		else
			connect_basic_vpn
		fi
		;;
	"disconnect")
		check_vpn_status
		if [[ $? -eq 1 ]]; then
			log "VPN already disconnected."
			notify "ℹ️ MULLVAD VPN" "Already disconnected" "security-medium"
		else
			disconnect_basic_vpn
		fi
		;;
	"toggle")
		toggle_basic_vpn
		;;
	"status")
		show_status
		;;
	"test")
		test_connection
		;;

	# Protocol commands
	"protocol")
		toggle_protocol
		;;

	# Location selection
	"random")
		relay=$(get_random_relay)
		if [[ -n $relay ]]; then
			connect_to_relay "$relay"
		else
			echo -e "${RED}Error: No relays found${NC}"
		fi
		;;

	# Favorites management
	"favorite")
		if [[ -z "$2" ]]; then
			echo -e "${RED}Error: Missing favorite action${NC}"
			echo -e "${YELLOW}Available actions: add, remove, list, connect${NC}"
			exit 1
		fi
		manage_favorites "$2"
		;;

	# Advanced selection
	"fastest")
		find_fastest_relay "$2" "false"
		;;
	"fastest-fav")
		find_fastest_relay "$2" "true"
		;;
	"owned")
		relay=$(get_random_relay "$2" "" "owned")
		if [[ -n $relay ]]; then
			connect_to_relay "$relay"
		else
			echo -e "${RED}Error: No Mullvad-owned relays found${NC}"
		fi
		;;
	"rented")
		relay=$(get_random_relay "$2" "" "rented")
		if [[ -n $relay ]]; then
			connect_to_relay "$relay"
		else
			echo -e "${RED}Error: No rented relays found${NC}"
		fi
		;;

	# Timer functions
	"timer")
		if [[ "$2" == "stop" ]]; then
			stop_timer
		elif [[ -n "$2" ]]; then
			start_timer "$2"
		else
			echo -e "${RED}Error: Missing timer duration or 'stop' command${NC}"
			echo -e "Usage: ${YELLOW}$SCRIPT_NAME timer <minutes|stop>${NC}"
		fi
		;;

	# Help and version info
	"help" | "-h" | "--help")
		show_help
		;;
	"version" | "-v" | "--version")
		echo -e "${BLUE}Integrated Mullvad VPN Manager v$VERSION${NC}"
		;;

	# Country code handling
	*)
		# Check if it's a country code
		if [[ " ${ALL_COUNTRIES[*]} " =~ " $1 " ]]; then
			# If there's a second parameter, it's a city
			if [[ -n "$2" ]]; then
				relay=$(get_random_relay "$1" "$2")
				if [[ -n $relay ]]; then
					connect_to_relay "$relay"
				else
					echo -e "${RED}Error: No relays found for $1-$2${NC}"
				fi
			else
				relay=$(get_random_relay "$1")
				if [[ -n $relay ]]; then
					connect_to_relay "$relay"
				else
					echo -e "${RED}Error: No relays found for $1${NC}"
				fi
			fi
		else
			echo -e "${RED}Unknown command: $1${NC}"
			echo -e "Use '${GREEN}help${NC}' command to see available options"
		fi
		;;
	esac
}

# Execute main function with all arguments
main "$@"

# Exit successfully
exit 0
