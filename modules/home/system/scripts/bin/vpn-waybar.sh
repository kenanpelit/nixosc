#!/usr/bin/env bash

# osc-waybar -  waybar yardımcı programı
# Kullanım: osc-waybar [komut]

VERSION="1.0.0"

# Yardım bilgilerini görüntüle
show_help() {
	echo "Kullanım: osc-waybar [komut]"
	echo ""
	echo "Komutlar:"
	echo "  vpn-mullvad            Mullvad VPN durumunu kontrol et"
	echo "  vpn-other              Diğer VPN bağlantılarını kontrol et"
	echo "  vpn-status             Genel VPN durumunu kontrol et"
	echo "  help                   Bu yardım mesajını göster"
	echo "  version                Sürüm bilgisini göster"
	echo ""
}

# Sürüm bilgisini göster
show_version() {
	echo "osc-waybar sürüm $VERSION"
}

# Komutu kontrol et ve ilgili fonksiyonu çalıştır
case "$1" in
vpn-mullvad)
	## Icon definitions
	#ICON_CONNECTED="󰦝 "    # Shield with check mark
	ICON_DISCONNECTED="󰦞 " # Shield with x mark
	# Mullvad için özel
	ICON_MULLVAD="󰒃 "     # Shield
	ICON_MULLVAD_ALT="󰯄 " # Alternatif Shield
	# Check Mullvad status
	status_output=$(mullvad status 2>/dev/null)
	# Function to check if interface has IP
	check_interface_has_ip() {
		local interface=$1
		ip addr show dev "$interface" 2>/dev/null | grep -q "inet "
		return $?
	}
	if echo "$status_output" | grep -q "Connected\|Connecting"; then
		relay_line=$(echo "$status_output" | grep "Relay:" | tr -d ' ')
		if echo "$relay_line" | grep -q "ovpn"; then
			if [ -d "/proc/sys/net/ipv4/conf/tun0" ] && check_interface_has_ip "tun0"; then
				interface="M-TUN0"
				text=$(echo "$relay_line" | cut -d':' -f2)
				echo "{\"text\": \"$interface $ICON_MULLVAD\", \"class\": \"connected\", \"tooltip\": \"Mullvad: $text\"}"
				exit 0
			fi
		elif echo "$relay_line" | grep -q "wg"; then
			if [ -d "/proc/sys/net/ipv4/conf/wg0-mullvad" ] && check_interface_has_ip "wg0-mullvad"; then
				interface="M-WG0"
				text=$(echo "$relay_line" | cut -d':' -f2)
				echo "{\"text\": \"$interface $ICON_MULLVAD\", \"class\": \"connected\", \"tooltip\": \"Mullvad: $text\"}"
				exit 0
			fi
		fi
	fi
	echo "{\"text\": \"MVN $ICON_DISCONNECTED\", \"class\": \"disconnected\", \"tooltip\": \"Mullvad Disconnected\"}"
	;;

vpn-other)
	# Klasik lock tarzı ikonlar
	ICON_CONNECTED="󰒃 "    # Locked padlock
	ICON_DISCONNECTED="󰦞 " # Shield with x mark
	ICON_WARNING="󰀦 "      # Warning icon
	# Function to check if interface has IP
	check_interface_has_ip() {
		local interface=$1
		ip addr show dev "$interface" 2>/dev/null | grep -q "inet "
		return $?
	}
	# Function to check Mullvad status
	check_mullvad_status() {
		if mullvad status 2>/dev/null | grep -q "Connected\|Connecting"; then
			return 0
		fi
		return 1
	}
	# Function to format interface name
	format_interface_name() {
		local interface=$1
		local base_name=$(echo "$interface" | sed 's/[0-9]*$//')
		local number=$(echo "$interface" | grep -o '[0-9]*$')
		echo "${base_name^^}${number}"
	}
	# Get Mullvad status
	mullvad_active=false
	if check_mullvad_status; then
		mullvad_active=true
	fi
	# Check for all VPN interfaces
	other_vpn_active=false
	other_vpn_interface=""
	other_vpn_ip=""
	while read -r interface; do
		# Temizle interface adını
		interface=$(echo "$interface" | tr -d '[:space:]')
		# If Mullvad is not active, treat tun0 as a potential other VPN interface
		if check_interface_has_ip "$interface"; then
			if [ "$mullvad_active" = false ] || [[ "$interface" != "wg0-mullvad" && "$interface" != "tun0" ]]; then
				other_vpn_active=true
				other_vpn_interface=$interface
				other_vpn_ip=$(ip addr show dev "$interface" | grep "inet " | awk '{print $2}' | cut -d/ -f1)
				break
			fi
		fi
	done < <(ip link show | grep -E "tun|wg|gpd" | grep "UP" | cut -d: -f2 | awk '{print $1}')
	# Determine status and output appropriate message
	if [ "$mullvad_active" = true ] && [ "$other_vpn_active" = true ]; then
		# Both Mullvad and other VPN are active
		formatted_name=$(format_interface_name "$other_vpn_interface")
		echo "{\"text\": \"DUAL $ICON_WARNING\", \"class\": \"warning\", \"tooltip\": \"Multiple VPNs Active - Mullvad and $formatted_name ($other_vpn_ip)\"}"
	elif [ "$mullvad_active" = true ]; then
		# Only Mullvad is active
		echo "{\"text\": \"MVN $ICON_CONNECTED\", \"class\": \"mullvad-connected\", \"tooltip\": \"Mullvad VPN Active\"}"
	elif [ "$other_vpn_active" = true ]; then
		# Only other VPN is active (including tun0 when Mullvad is not active)
		formatted_name=$(format_interface_name "$other_vpn_interface")
		echo "{\"text\": \"$formatted_name $ICON_CONNECTED\", \"class\": \"vpn-connected\", \"tooltip\": \"$other_vpn_interface: $other_vpn_ip\"}"
	else
		# No VPN is active
		echo "{\"text\": \"OVN $ICON_DISCONNECTED\", \"class\": \"disconnected\", \"tooltip\": \"No VPN Connected\"}"
	fi
	;;

vpn-status)
	# Modern shield/lock tarzı VPN ikonları
	ICON_CONNECTED="󰦝 "    # Shield with check mark
	ICON_DISCONNECTED="󰦞 " # Shield with x mark
	# Function to check if any VPN interface is active
	check_vpn_active() {
		# Check for any active VPN interface (tun, wg, gpd)
		if ip link show | grep -E "tun|wg|gpd" | grep -q "UP"; then
			return 0
		fi
		return 1
	}
	if check_vpn_active; then
		echo "{\"text\": \"VPN $ICON_CONNECTED\", \"class\": \"connected\", \"tooltip\": \"VPN Connected\"}"
	else
		echo "{\"text\": \"VPN $ICON_DISCONNECTED\", \"class\": \"disconnected\", \"tooltip\": \"VPN Disconnected\"}"
	fi
	;;

version)
	show_version
	;;

help | --help | -h | *)
	show_help
	;;
esac
