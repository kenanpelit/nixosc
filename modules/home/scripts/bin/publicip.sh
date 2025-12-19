#!/usr/bin/env bash
#===============================================================================
#
#   Script: OSC Public IP Checker
#   Version: 1.3.0
#   Date: 2025-12-19
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
#   - Tries to show "real" IP by bypassing VPN (if possible)
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
	command -v notify-send >/dev/null 2>&1 || return 0
	notify-send -i network-vpn "$1" "$2" 2>/dev/null || true
}

curl_ip() {
	curl -fsS --connect-timeout 2 --max-time 5 "$@"
}

get_mullvad_status() {
	command -v mullvad >/dev/null 2>&1 || return 0
	mullvad status 2>/dev/null || true
}

get_country() {
	local ip=$1
	[[ -n "${ip:-}" ]] || { echo "Unknown"; return 0; }
	if country="$(curl_ip "https://ipapi.co/${ip}/country_name" 2>/dev/null | tr -d '\n' || true)"; then
		[[ -n "$country" ]] && echo "$country" || echo "Unknown"
	else
		echo "Unknown"
	fi
}

get_real_ip() {
	curl_ip https://ipinfo.io/ip | tr -d '\n'
}

get_physical_iface() {
	# Try to pick a non-tunnel interface that's up.
	# This is best-effort; if Mullvad (or another VPN) blocks direct traffic, it may still fail.
	ip -o link show up 2>/dev/null \
		| awk -F': ' '{print $2}' \
		| awk '{print $1}' \
		| grep -Ev '^(lo|mullvad|wg[0-9]*|tun[0-9]*|tap[0-9]*|docker[0-9]*|veth.*|br-.*|virbr.*)$' \
		| head -n 1
}

get_real_ip_bypass_vpn() {
	local ip=""

	# Mullvad provides mullvad-exclude for split tunneling (best option if present).
	if command -v mullvad-exclude >/dev/null 2>&1; then
		ip="$(mullvad-exclude bash -lc 'curl -fsS --connect-timeout 2 --max-time 5 https://ipinfo.io/ip' 2>/dev/null | tr -d '\n' || true)"
	fi

	# Fallback: force a physical interface (may still fail under VPN lockdown).
	if [[ -z "$ip" ]]; then
		local iface
		iface="$(get_physical_iface)"
		if [[ -n "$iface" ]]; then
			ip="$(curl_ip --interface "$iface" https://ipinfo.io/ip 2>/dev/null | tr -d '\n' || true)"
		fi
	fi

	echo "$ip"
}

check_ip() {
	status_output="$(get_mullvad_status)"
	current_ip=$(get_real_ip)

	print_header "IP ADDRESS STATUS"

	if [[ -n "$status_output" ]] && echo "$status_output" | grep -q "Connected"; then
		# VPN is connected
		vpn_ip=$(echo "$status_output" | grep -oP "IPv4: \K[0-9.]+")

		# Try to bypass VPN to get the "real" public IP
		real_ip="$(get_real_ip_bypass_vpn)"
		if [[ -z "$real_ip" ]]; then
			real_ip="$current_ip"
			real_ip_note="(VPN bypass unavailable)"
		elif [[ -n "$vpn_ip" && "$real_ip" == "$vpn_ip" ]]; then
			real_ip_note="(VPN bypass returned VPN IP)"
		else
			real_ip_note=""
		fi

		# Get country information for both IPs
		vpn_country=$(get_country "$vpn_ip")
		real_country=$(get_country "$real_ip")

		# Display notification
		message="VPN IP: $vpn_ip ($vpn_country)\nReal IP: $real_ip ($real_country) $real_ip_note"
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
		print_status "$GLOBE" "IP Address" "$real_ip ${real_ip_note:-}" "${YELLOW}"
		print_status "$GLOBE" "Location" "$real_country" "${YELLOW}"

	else
		# VPN is not connected
		country=$(get_country "$current_ip")

		# Display notification
		notify "VPN Disconnected" "Regular IP: $current_ip ($country)"

		# Display VPN Status
		print_status "$WARNING" "VPN Status" "Disconnected" "${RED}"
		print_divider

		# Display Real IP Info
		echo -e " ${BOLD}${CYAN}CURRENT CONNECTION:${RESET}"
		print_status "$GLOBE" "IP Address" "$current_ip" "${YELLOW}"
		print_status "$GLOBE" "Location" "$country" "${YELLOW}"
	fi

	echo
	return 0
}

check_ip
