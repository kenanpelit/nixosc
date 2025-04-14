#!/usr/bin/env bash
#===============================================================================
#
#   Script: OSC Public IP Checker
#   Version: 1.2.0
#   Date: 2024-04-14
#   Author: Kenan Pelit
#   Repository: https://github.com/kenanpelit/nixosc
#   Description: Advanced public IP address checker with VPN detection and
#                location reporting via desktop notifications
#
#   Features:
#   - Mullvad VPN status detection
#   - Country resolution via ipapi.co
#   - Desktop notifications integration
#   - Stylish terminal output with Unicode symbols
#   - VPN vs regular IP comparison
#   - Comprehensive status reporting
#   - Shows both VPN and regular IP when VPN is connected
#
#   License: MIT
#
#===============================================================================
# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

# Symbols
CHECK_MARK="✓"
CROSS_MARK="✗"
GLOBE="🌐"
SHIELD="🔒"
WARNING="⚠️"
ARROW="→"

# Fixed width for headers and dividers
HEADER_WIDTH=40

# Print a stylish header
print_header() {
	local title="$1"
	local title_len=${#title}
	local padding=$(((HEADER_WIDTH - title_len - 4) / 2))
	local extra_pad=$(((HEADER_WIDTH - title_len - 4) % 2))

	echo
	printf "%${padding}s" "" | tr " " "="
	printf " ${BOLD}${BLUE}%s${RESET} " "$title"
	printf "%$((padding + extra_pad))s\n" "" | tr " " "="
	echo
}

# Print a divider line
print_divider() {
	printf "%.${HEADER_WIDTH}s\n" "" | tr " " "-"
}

# Print status item with icon
print_status() {
	local icon="$1"
	local label="$2"
	local value="$3"
	local color="$4"

	printf " ${BOLD}%s ${PURPLE}%s:${RESET} ${color}%s${RESET}\n" "$icon" "$label" "$value"
}

notify() {
	notify-send -i network-vpn "$1" "$2"
}

get_country() {
	local ip=$1
	if country=$(curl -s "https://ipapi.co/$ip/country_name"); then
		echo "$country"
	else
		echo "Unknown"
	fi
}

get_real_ip() {
	curl -s https://ipinfo.io/ip
}

check_ip() {
	real_ip=$(get_real_ip)
	status_output=$(mullvad status)

	print_header "IP ADDRESS STATUS"

	if echo "$status_output" | grep -q "Connected"; then
		# VPN is connected
		vpn_ip=$(echo "$status_output" | grep -oP "IPv4: \K[0-9.]+")

		# Get country information for both IPs
		vpn_country=$(get_country "$vpn_ip")
		real_country=$(get_country "$real_ip")

		# Display notification
		message="VPN IP: $vpn_ip ($vpn_country)\nRegular IP: $real_ip ($real_country)"
		notify "VPN Connected" "$message"

		# Display VPN Status
		print_status "$SHIELD" "VPN Status" "Connected" "${GREEN}"
		print_divider

		# Display VPN Info
		echo -e " ${BOLD}${CYAN}VPN CONNECTION:${RESET}"
		print_status "$GLOBE" "IP Address" "$vpn_ip" "${GREEN}"
		print_status "$GLOBE" "Location" "$vpn_country" "${GREEN}"
		print_divider

		# Display Real IP Info
		echo -e " ${BOLD}${CYAN}REAL CONNECTION:${RESET}"
		print_status "$GLOBE" "IP Address" "$real_ip" "${YELLOW}"
		print_status "$GLOBE" "Location" "$real_country" "${YELLOW}"

	else
		# VPN is not connected
		country=$(get_country "$real_ip")

		# Display notification
		notify "VPN Disconnected" "Regular IP: $real_ip ($country)"

		# Display VPN Status
		print_status "$WARNING" "VPN Status" "Disconnected" "${RED}"
		print_divider

		# Display Real IP Info
		echo -e " ${BOLD}${CYAN}CURRENT CONNECTION:${RESET}"
		print_status "$GLOBE" "IP Address" "$real_ip" "${YELLOW}"
		print_status "$GLOBE" "Location" "$country" "${YELLOW}"
	fi

	echo
	return 0
}

check_ip
