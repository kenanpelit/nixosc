#!/usr/bin/env bash
#===============================================================================
#
#   Script: OSC Mullvad VPN Relay Manager
#   Version: 2.0.0
#   Date: 2024-03-04
#   Author: Kenan Pelit
#   Repository: https://github.com/kenanpelit/nixosc
#   Description: Advanced Mullvad VPN relay management utility for switching
#                between protocols and locations with smart relay selection
#
#   Features:
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

# Configuration directories and files
LOG_DIR="$HOME/.logs/mullvad"
CONFIG_DIR="$HOME/.config/mrelay"
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

# Function to show help
function show_help() {
	echo -e "${BLUE}===== Mullvad VPN Relay Manager v2.0.0 =====${NC}"
	echo -e ""
	echo -e "${CYAN}Usage:${NC} $(basename $0) [COMMAND] [ARGUMENTS]"
	echo -e ""
	echo -e "${YELLOW}Basic Commands:${NC}"
	echo -e "    ${GREEN}toggle${NC}            Toggle between OpenVPN and WireGuard for current location"
	echo -e "    ${GREEN}random${NC}            Switch to a random relay from all available relays"
	echo -e "    ${GREEN}status${NC}            Show current connection status and details"
	echo -e "    ${GREEN}test${NC}              Test current connection for leaks/issues"
	echo -e "    ${GREEN}help${NC}              Show this help message"
	echo -e ""
	echo -e "${YELLOW}Location Selection:${NC}"
	echo -e "    ${GREEN}<country>${NC}         Switch to a random relay in a specific country (e.g., us, fr, jp)"
	echo -e "    ${GREEN}<country> <city>${NC}  Switch to a random relay in a specific city (e.g., us nyc, de fra)"
	echo -e ""
	echo -e "${YELLOW}Advanced Selection:${NC}"
	echo -e "    ${GREEN}fastest${NC} [country]  Find and connect to the fastest relay (optionally in a specific country)"
	echo -e "    ${GREEN}owned${NC} [country]    Connect to a Mullvad-owned relay (not rented)"
	echo -e "    ${GREEN}rented${NC} [country]   Connect to a rented relay infrastructure"
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
	echo -e "    ${GREEN}$(basename $0) toggle${NC}           # Switch between OpenVPN/WireGuard"
	echo -e "    ${GREEN}$(basename $0) random${NC}           # Switch to any random relay"
	echo -e "    ${GREEN}$(basename $0) fr${NC}               # Switch to French relay"
	echo -e "    ${GREEN}$(basename $0) us nyc${NC}           # Switch to a New York relay"
	echo -e "    ${GREEN}$(basename $0) fastest de${NC}       # Find fastest German relay"
	echo -e "    ${GREEN}$(basename $0) timer 30${NC}         # Change relay every 30 minutes"
	echo -e ""
	echo -e "${YELLOW}Available Countries:${NC}"
	echo -e "    ${CYAN}Europe:${NC} at be bg ch cz de dk ee es fi fr gb gr hr hu ie it nl no pl pt ro rs se si sk tr ua"
	echo -e "    ${CYAN}Americas:${NC} br ca cl co mx pe us"
	echo -e "    ${CYAN}Asia/Pacific:${NC} au hk id jp my ph sg th"
	echo -e "    ${CYAN}Africa/ME:${NC} il ng za"
	echo -e "    ${CYAN}Other:${NC} nz"
}

# Logging function
function log_action() {
	local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
	local message="$timestamp $1"
	echo "$message" >>"$HISTORY_FILE"

	# Keep log file size reasonable (last 1000 entries)
	if [ "$(wc -l <"$HISTORY_FILE")" -gt 1000 ]; then
		tail -1000 "$HISTORY_FILE" >"$HISTORY_FILE.tmp"
		mv "$HISTORY_FILE.tmp" "$HISTORY_FILE"
	fi
}

# Function to convert country code to name
function get_country_name() {
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
function get_city_name() {
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

function get_current_relay() {
	mullvad relay get | grep 'Location:' | awk -F'hostname ' '{print $2}'
}

function get_random_relay() {
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

function toggle_protocol() {
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

		echo -e "${YELLOW}Switching from ${current_relay} to ${new_relay}...${NC}"

		mullvad relay set location $country $city $new_relay >/dev/null 2>&1

		if [ $? -eq 0 ]; then
			echo -e "${GREEN}Successfully switched to $new_type: $new_relay${NC}"
			log_action "Switched protocol from $current_relay to $new_relay"
		else
			echo -e "${RED}Failed to switch protocol${NC}"
		fi
	else
		echo -e "${RED}No alternative protocol found for this location${NC}"
	fi
}

function connect_to_relay() {
	local relay=$1
	local max_retries=3
	local retry_count=0

	if [[ -z "$relay" ]]; then
		echo -e "${RED}No relay specified or found${NC}"
		return 1
	fi

	local country=$(echo $relay | cut -d'-' -f1)
	local city=$(echo $relay | cut -d'-' -f2)

	echo -e "${YELLOW}Connecting to relay: $relay${NC}"

	while [ $retry_count -lt $max_retries ]; do
		mullvad relay set location $country $city $relay >/dev/null 2>&1

		if [ $? -eq 0 ]; then
			echo -e "${GREEN}Successfully connected to: $relay ${NC}"
			log_action "Connected to $relay"
			return 0
		else
			retry_count=$((retry_count + 1))
			echo -e "${RED}Connection attempt $retry_count failed. Retrying...${NC}"
			sleep 1
		fi
	done

	echo -e "${RED}Failed to connect after $max_retries attempts.${NC}"
	echo -e "${YELLOW}Trying a different relay...${NC}"

	# Try a different relay in the same city
	local alternate_relay=$(get_random_relay $country $city)

	if [[ -n "$alternate_relay" && "$alternate_relay" != "$relay" ]]; then
		echo -e "${YELLOW}Trying alternate relay: $alternate_relay${NC}"
		connect_to_relay "$alternate_relay"
	else
		echo -e "${RED}No alternative relays available in $city, $country.${NC}"
		return 1
	fi
}

function manage_favorites() {
	local action=$1
	local current_relay=$(get_current_relay)

	case "$action" in
	"add")
		if [[ -z "$current_relay" ]]; then
			echo -e "${RED}No active relay to add${NC}"
			return 1
		fi

		# Check if relay is already in favorites
		if grep -q "^$current_relay$" "$FAVORITES_FILE"; then
			echo -e "${YELLOW}Relay $current_relay is already in favorites${NC}"
		else
			echo "$current_relay" >>"$FAVORITES_FILE"
			echo -e "${GREEN}Added $current_relay to favorites${NC}"
		fi
		;;

	"remove")
		if [[ ! -s "$FAVORITES_FILE" ]]; then
			echo -e "${RED}Favorites list is empty${NC}"
			return 1
		fi

		echo -e "${CYAN}Select relay to remove:${NC}"
		local i=1
		while read -r line; do
			echo -e "${YELLOW}$i)${NC} $line"
			i=$((i + 1))
		done <"$FAVORITES_FILE"

		echo -e "${CYAN}Enter number (1-$((i - 1))) or 'q' to cancel:${NC} "
		read -r choice

		if [[ "$choice" == "q" ]]; then
			echo -e "${YELLOW}Operation cancelled${NC}"
			return 0
		fi

		if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -lt "$i" ]; then
			local removed_relay=$(sed -n "${choice}p" "$FAVORITES_FILE")
			sed -i "${choice}d" "$FAVORITES_FILE"
			echo -e "${GREEN}Removed $removed_relay from favorites${NC}"
		else
			echo -e "${RED}Invalid selection${NC}"
		fi
		;;

	"list")
		if [[ ! -s "$FAVORITES_FILE" ]]; then
			echo -e "${RED}Favorites list is empty${NC}"
			return 1
		fi

		echo -e "${CYAN}Favorite relays:${NC}"
		local i=1
		while read -r line; do
			local country=$(echo "$line" | cut -d'-' -f1)
			local city=$(echo "$line" | cut -d'-' -f2)
			local protocol=$(echo "$line" | cut -d'-' -f3)
			echo -e "${YELLOW}$i)${NC} $line (${GREEN}$(get_country_name $country)${NC}, ${GREEN}$(get_city_name $city)${NC}, ${BLUE}${protocol^^}${NC})"
			i=$((i + 1))
		done <"$FAVORITES_FILE"
		;;

	"connect")
		if [[ ! -s "$FAVORITES_FILE" ]]; then
			echo -e "${RED}Favorites list is empty${NC}"
			return 1
		fi

		echo -e "${CYAN}Select relay to connect to:${NC}"
		local i=1
		while read -r line; do
			local country=$(echo "$line" | cut -d'-' -f1)
			local city=$(echo "$line" | cut -d'-' -f2)
			local protocol=$(echo "$line" | cut -d'-' -f3)
			echo -e "${YELLOW}$i)${NC} $line (${GREEN}$(get_country_name $country)${NC}, ${GREEN}$(get_city_name $city)${NC}, ${BLUE}${protocol^^}${NC})"
			i=$((i + 1))
		done <"$FAVORITES_FILE"

		echo -e "${CYAN}Enter number (1-$((i - 1))) or 'q' to cancel:${NC} "
		read -r choice

		if [[ "$choice" == "q" ]]; then
			echo -e "${YELLOW}Operation cancelled${NC}"
			return 0
		fi

		if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -lt "$i" ]; then
			local selected_relay=$(sed -n "${choice}p" "$FAVORITES_FILE")
			connect_to_relay "$selected_relay"
		else
			echo -e "${RED}Invalid selection${NC}"
		fi
		;;

	*)
		echo -e "${RED}Unknown favorites action: $action${NC}"
		echo -e "${YELLOW}Available actions: add, remove, list, connect${NC}"
		;;
	esac
}

function find_fastest_relay() {
	local country=$1
	local timeout=2     # Timeout in seconds for ping
	local iterations=3  # Number of pings per relay
	local max_relays=10 # Maximum number of relays to test

	echo -e "${BLUE}Finding fastest relay...${NC}"

	# Get relays to test
	local relays=()
	if [[ -n "$country" ]]; then
		readarray -t relays < <(mullvad relay list | grep -E "^[[:space:]]*$country-[a-z]{3}-(wg|ovpn)-" | awk '{print $1}' | shuf -n $max_relays)
		echo -e "${YELLOW}Testing up to $max_relays relays in $(get_country_name $country)...${NC}"
	else
		readarray -t relays < <(mullvad relay list | grep -E "^[[:space:]]*[a-z]{2}-[a-z]{3}-(wg|ovpn)-" | awk '{print $1}' | shuf -n $max_relays)
		echo -e "${YELLOW}Testing up to $max_relays relays globally...${NC}"
	fi

	if [ ${#relays[@]} -eq 0 ]; then
		echo -e "${RED}No relays found for testing${NC}"
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
		connect_to_relay "$best_relay"
	else
		echo -e "${RED}Could not find a responsive relay${NC}"
		return 1
	fi
}

# Function to show connection status
function show_status() {
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

# Function to test connection for leaks
function test_connection() {
	echo -e "${BLUE}=== Testing Mullvad VPN Connection ===${NC}"

	# Check if connected to Mullvad
	local connection_status=$(mullvad status)
	if [[ "$connection_status" != *"Connected"* ]]; then
		echo -e "${RED}Not connected to Mullvad VPN. Test aborted.${NC}"
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
	else
		echo -e "${RED}✗ Not properly connected to Mullvad network!${NC}"
	fi

	echo -e "\n${BLUE}Test complete. For comprehensive testing, visit https://mullvad.net/check/ in your browser.${NC}"
}

# Timer variables
TIMER_PID=""
TIMER_FILE="$CONFIG_DIR/timer.pid"

function start_timer() {
	local minutes=$1

	# Check if timer is already running
	if [[ -f "$TIMER_FILE" ]]; then
		local pid=$(cat "$TIMER_FILE")
		if ps -p $pid >/dev/null; then
			echo -e "${YELLOW}Timer already running with PID $pid${NC}"
			echo -e "Stop it first with: ${GREEN}$(basename $0) timer stop${NC}"
			return 1
		else
			# PID file exists but process doesn't, clean up
			rm -f "$TIMER_FILE"
		fi
	fi

	# Validate input
	if ! [[ "$minutes" =~ ^[0-9]+$ ]]; then
		echo -e "${RED}Error: Minutes must be a positive integer${NC}"
		return 1
	fi

	if [ "$minutes" -lt 5 ]; then
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
			log_action "Timer auto-switched to $relay"
		done
	} &

	TIMER_PID=$!
	echo $TIMER_PID >"$TIMER_FILE"

	echo -e "${GREEN}Timer started. Will switch relay every $minutes minutes.${NC}"
	echo -e "Timer running with PID $TIMER_PID"
	echo -e "To stop, run: ${CYAN}$(basename $0) timer stop${NC}"
}

function stop_timer() {
	if [[ -f "$TIMER_FILE" ]]; then
		local pid=$(cat "$TIMER_FILE")
		if ps -p $pid >/dev/null; then
			kill $pid
			echo -e "${GREEN}Timer stopped${NC}"
		else
			echo -e "${YELLOW}Timer process is not running but PID file exists${NC}"
		fi
		rm -f "$TIMER_FILE"
	else
		echo -e "${RED}No timer is currently running${NC}"
	fi
}

# Check dependencies
command -v mullvad >/dev/null 2>&1 || {
	echo -e "${RED}Error: Mullvad CLI client is not installed or not in your PATH${NC}"
	exit 1
}
command -v jq >/dev/null 2>&1 || { echo -e "${YELLOW}Warning: jq is not installed. Some features will be limited${NC}"; }
command -v bc >/dev/null 2>&1 || { echo -e "${YELLOW}Warning: bc is not installed. 'fastest' feature will not work properly${NC}"; }

# Main logic
case "$1" in
"status")
	show_status
	;;
"test")
	test_connection
	;;
"random")
	relay=$(get_random_relay)
	if [[ -n $relay ]]; then
		connect_to_relay "$relay"
	else
		echo -e "${RED}Error: No relays found${NC}"
	fi
	;;
"toggle")
	toggle_protocol
	;;
"favorite")
	if [[ -z "$2" ]]; then
		echo -e "${RED}Error: Missing favorite action${NC}"
		echo -e "${YELLOW}Available actions: add, remove, list, connect${NC}"
		exit 1
	fi
	manage_favorites "$2"
	;;
"fastest")
	find_fastest_relay "$2"
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
"timer")
	if [[ "$2" == "stop" ]]; then
		stop_timer
	elif [[ -n "$2" ]]; then
		start_timer "$2"
	else
		echo -e "${RED}Error: Missing timer duration or 'stop' command${NC}"
		echo -e "Usage: ${YELLOW}$(basename $0) timer <minutes|stop>${NC}"
	fi
	;;
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
	elif [[ "$1" == "help" || "$1" == "-h" || "$1" == "--help" || -z "$1" ]]; then
		show_help
	else
		echo -e "${RED}Unknown command: $1${NC}"
		echo -e "Use '${GREEN}help${NC}' command to see available options"
	fi
	;;
esac

exit 0
