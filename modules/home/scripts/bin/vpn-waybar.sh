#!/usr/bin/env bash

# vpn-waybar - unified VPN status display
# Tek çıktıda tüm VPN durumlarını gösterir

set -euo pipefail

# İkon tanımlamaları
declare -A ICONS=(
	["connected"]="󰦝"
	["disconnected"]="󰦞"
	["mullvad"]="󰒃"
	["warning"]="󰀦"
	["dual"]="󰓅"
	["off"]="󰲛"
)

# JSON output fonksiyonu
json_output() {
	local text="$1"
	local class="$2"
	local tooltip="$3"
	printf '{"text": "%s", "class": "%s", "tooltip": "%s"}' "$text" "$class" "$tooltip"
}

# Interface IP kontrolü
check_interface_ip() {
	local interface="$1"
	[[ -d "/proc/sys/net/ipv4/conf/$interface" ]] && ip addr show dev "$interface" 2>/dev/null | grep -q "inet "
}

# Interface adı formatlama
format_interface_name() {
	local interface="$1"
	local base_name number
	base_name=$(echo "$interface" | sed 's/[0-9]*$//')
	number=$(echo "$interface" | grep -o '[0-9]*$' || echo "")
	echo "${base_name^^}${number}"
}

# Mullvad durumu kontrol
get_mullvad_status() {
	local mullvad_status="disconnected"
	local mullvad_info=""
	local mullvad_interface=""

	if command -v mullvad >/dev/null 2>&1; then
		local status_output
		if status_output=$(timeout 5 mullvad status 2>/dev/null); then
			if echo "$status_output" | grep -q "Connected\|Connecting"; then
				local relay_info
				relay_info=$(echo "$status_output" | grep "Relay:" | head -1 | cut -d: -f2- | tr -d ' ' 2>/dev/null || echo "unknown")

				if check_interface_ip "wg0-mullvad"; then
					mullvad_status="connected"
					mullvad_interface="wg0-mullvad"
					mullvad_info="WireGuard: $relay_info"
				elif check_interface_ip "tun0"; then
					mullvad_status="connected"
					mullvad_interface="tun0"
					mullvad_info="OpenVPN: $relay_info"
				else
					mullvad_status="warning"
					mullvad_info="Connection Problem"
				fi
			fi
		else
			mullvad_status="error"
			mullvad_info="Command Error"
		fi
	else
		mullvad_status="not_installed"
		mullvad_info="Not Installed"
	fi

	echo "$mullvad_status|$mullvad_info|$mullvad_interface"
}

# Diğer VPN'leri kontrol et
get_other_vpns() {
	local other_vpns=()
	local mullvad_interfaces=("wg0-mullvad" "tun0")

	while IFS= read -r interface; do
		interface=$(echo "$interface" | tr -d '[:space:]')
		[[ -z "$interface" ]] && continue

		# Mullvad interface'i değilse ve IP'si varsa
		if [[ ! " ${mullvad_interfaces[*]} " =~ " ${interface} " ]] && check_interface_ip "$interface"; then
			local ip
			ip=$(ip addr show dev "$interface" 2>/dev/null | grep "inet " | awk '{print $2}' | cut -d/ -f1 | head -1)
			local formatted_name
			formatted_name=$(format_interface_name "$interface")
			other_vpns+=("$formatted_name:$ip")
		fi
	done < <(ip link show 2>/dev/null | grep -E "tun|wg|gpd" | grep "UP" | cut -d: -f2 | awk '{print $1}')

	printf '%s\n' "${other_vpns[@]}"
}

# Ana VPN durumu analizi
analyze_vpn_status() {
	local mullvad_result other_vpns_result
	mullvad_result=$(get_mullvad_status)
	other_vpns_result=$(get_other_vpns)

	IFS='|' read -r mullvad_status mullvad_info mullvad_interface <<<"$mullvad_result"

	local text="" class="" tooltip=""

	# Mullvad ve diğer VPN'ler aynı anda aktif
	if [[ "$mullvad_status" == "connected" ]] && [[ -n "$other_vpns_result" ]]; then
		local other_count
		other_count=$(echo "$other_vpns_result" | wc -l)
		local first_other
		first_other=$(echo "$other_vpns_result" | head -1 | cut -d: -f1)

		text="${ICONS[dual]} M+$first_other"
		class="warning"
		tooltip="⚠️ Multiple VPN Active\n\n"
		tooltip+="🔵 Mullvad: $mullvad_info\n"
		tooltip+="🟡 Other VPNs ($other_count):\n"
		while IFS= read -r vpn_line; do
			[[ -n "$vpn_line" ]] && tooltip+="  • $(echo "$vpn_line" | tr ':' ' - ')\n"
		done <<<"$other_vpns_result"
		tooltip+="\n⚠️ This may cause routing conflicts!"

	# Sadece Mullvad aktif
	elif [[ "$mullvad_status" == "connected" ]]; then
		text="${ICONS[mullvad]} M"
		class="connected"
		tooltip="🔵 Mullvad VPN Connected\n\n"
		tooltip+="📡 $mullvad_info\n"
		tooltip+="🔌 Interface: $mullvad_interface"

	# Sadece diğer VPN'ler aktif
	elif [[ -n "$other_vpns_result" ]]; then
		local vpn_count first_vpn
		vpn_count=$(echo "$other_vpns_result" | wc -l)
		first_vpn=$(echo "$other_vpns_result" | head -1)

		if [[ $vpn_count -eq 1 ]]; then
			text="${ICONS[connected]} $(echo "$first_vpn" | cut -d: -f1)"
			class="connected"
			tooltip="🟢 VPN Connected\n\n"
			tooltip+="📡 $(echo "$first_vpn" | tr ':' ' - ')"
		else
			text="${ICONS[connected]} VPN×$vpn_count"
			class="connected"
			tooltip="🟢 Multiple VPNs Active ($vpn_count)\n\n"
			while IFS= read -r vpn_line; do
				[[ -n "$vpn_line" ]] && tooltip+="  • $(echo "$vpn_line" | tr ':' ' - ')\n"
			done <<<"$other_vpns_result"
		fi

	# Mullvad problemi
	elif [[ "$mullvad_status" == "warning" ]]; then
		text="${ICONS[warning]} M-Error"
		class="warning"
		tooltip="⚠️ Mullvad Connection Issue\n\n"
		tooltip+="Problem: $mullvad_info\n"
		tooltip+="Try reconnecting Mullvad"

	# Hiç VPN yok
	else
		text="${ICONS[off]} No VPN"
		class="disconnected"
		tooltip="🔴 No VPN Connection\n\n"
		if [[ "$mullvad_status" == "not_installed" ]]; then
			tooltip+="📱 Mullvad: Not Installed\n"
		else
			tooltip+="📱 Mullvad: Disconnected\n"
		fi
		tooltip+="🌐 Other VPNs: None Active\n\n"
		tooltip+="Click to manage VPN connections"
	fi

	json_output "$text" "$class" "$tooltip"
}

# Script'i çalıştır
analyze_vpn_status
