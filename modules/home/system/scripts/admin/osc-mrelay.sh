#!/usr/bin/env bash
#===============================================================================
#
#   Script: OSC Mullvad VPN Relay Manager
#   Version: 1.0.0
#   Date: 2024-01-23
#   Author: Kenan Pelit
#   Repository: https://github.com/kenanpelit/nixosc
#   Description: Advanced Mullvad VPN relay management utility for switching
#                between protocols and locations with smart relay selection
#
#   Features:
#   - Protocol toggle between OpenVPN and WireGuard
#   - Random relay selection from global pool
#   - Country-specific relay selection
#   - Smart protocol switching for current location
#   - Supports multiple European and Asian locations
#   - Simple command-line interface
#
#   License: MIT
#
#===============================================================================

function show_help() {
	cat <<EOF
Mullvad VPN Relay Toggle Script

Usage: $(basename $0) [COMMAND]

Commands:
    toggle    Toggle between OpenVPN and WireGuard for current location
    random    Switch to a random relay from all available relays
    ch        Switch to a random Swiss relay
    se        Switch to a random Swedish relay
    fr        Switch to a random French relay
    jp        Switch to a random Japanese relay
    de        Switch to a random German relay
    tr        Switch to a random Turkish relay
    dk        Switch to a random Danish relay
    no        Switch to a random Norwegian relay
    help      Show this help message

Examples:
    $(basename $0) toggle    # Switch between OpenVPN/WireGuard
    $(basename $0) random    # Switch to any random relay
    $(basename $0) fr        # Switch to French relay
EOF
}

function get_random_relay() {
	local country=$1
	if [[ -n $country ]]; then
		readarray -t relays < <(mullvad relay list | grep -E "^[[:space:]]*$country-[a-z]{3}-(wg|ovpn)-" | awk '{print $1}')
	else
		readarray -t relays < <(mullvad relay list | grep -E '^[[:space:]]*[a-z]{2}-[a-z]{3}-(wg|ovpn)-' | awk '{print $1}')
	fi

	if [ ${#relays[@]} -gt 0 ]; then
		echo "${relays[RANDOM % ${#relays[@]}]}"
	else
		echo ""
	fi
}

function get_current_relay() {
	mullvad relay get | grep 'Location:' | awk -F'hostname ' '{print $2}'
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
		mullvad relay set location $country $city $new_relay >/dev/null 2>&1
		echo "Switched to $new_type: $new_relay"
	else
		echo "No alternative protocol found for this location"
	fi
}

case "$1" in
"random")
	relay=$(get_random_relay $2)
	if [[ -n $relay ]]; then
		country=$(echo $relay | cut -d'-' -f1)
		city=$(echo $relay | cut -d'-' -f2)
		mullvad relay set location $country $city $relay >/dev/null 2>&1
		echo "Set to random relay: $relay"
	else
		echo "Error: No relays found"
	fi
	;;
"toggle")
	toggle_protocol
	;;
"ch" | "se" | "fr" | "jp" | "de" | "tr" | "dk" | "no")
	relay=$(get_random_relay $1)
	if [[ -n $relay ]]; then
		country=$(echo $relay | cut -d'-' -f1)
		city=$(echo $relay | cut -d'-' -f2)
		mullvad relay set location $country $city $relay >/dev/null 2>&1
		echo "Set to $1 relay: $relay"
	else
		echo "Error: No relays found for $1"
	fi
	;;
"help" | "-h" | "--help")
	show_help
	;;
*)
	show_help
	;;
esac
