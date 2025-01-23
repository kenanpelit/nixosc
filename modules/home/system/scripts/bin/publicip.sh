#!/usr/bin/env bash
#===============================================================================
#
#   Script: OSC Public IP Checker
#   Version: 1.0.0
#   Date: 2024-01-23
#   Author: Kenan Pelit
#   Repository: https://github.com/kenanpelit/nixosc
#   Description: Advanced public IP address checker with VPN detection and
#                location reporting via desktop notifications
#
#   Features:
#   - Mullvad VPN status detection
#   - Country resolution via ipapi.co
#   - Desktop notifications integration
#   - Color-coded terminal output
#   - VPN vs regular IP comparison
#   - Comprehensive status reporting
#
#   License: MIT
#
#===============================================================================

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

notify() {
	notify-send "$1" "$2"
}

get_country() {
	local ip=$1
	if country=$(curl -s "https://ipapi.co/$ip/country_name"); then
		echo "$country"
	fi
}

check_ip() {
	real_ip=$(curl -s https://ipinfo.io/ip)
	status_output=$(mullvad status)

	if echo "$status_output" | grep -q "Connected"; then
		vpn_ip=$(echo "$status_output" | grep -oP "IPv4: \K[0-9.]+")
		if [ "$real_ip" != "$vpn_ip" ]; then
			country=$(get_country "$real_ip")
			message="Regular IP: $real_ip"
			notify "IP Status" "$message\nCountry: $country"
			echo -e "${GREEN}Regular IP:${NC} $real_ip"
			echo -e "Country: ${GREEN}$country${NC}"
		else
			country=$(get_country "$vpn_ip")
			message="Mullvad IP: $vpn_ip"
			notify "IP Status" "$message\nCountry: $country"
			echo -e "${GREEN}Mullvad IP:${NC} $vpn_ip"
			echo -e "Country: ${GREEN}$country${NC}"
		fi
		return 0
	else
		country=$(get_country "$real_ip")
		message="Regular IP: $real_ip"
		notify "IP Status" "$message\nCountry: $country"
		echo -e "${GREEN}Regular IP:${NC} $real_ip"
		echo -e "Country: ${GREEN}$country${NC}"
		return 0
	fi
}

check_ip
