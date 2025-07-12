#!/usr/bin/env bash

# osc-waybar - waybar yardımcı programı
# Kullanım: osc-waybar [komut]

# vpn-waybar - cache'siz, basit, çalışan versiyon

set -euo pipefail

# İkon tanımlamaları
declare -A ICONS=(
	["connected"]="󰦝 "
	["disconnected"]="󰦞 "
	["mullvad"]="󰒃 "
	["warning"]="󰀦 "
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
check_mullvad_status() {
	if ! command -v mullvad >/dev/null 2>&1; then
		json_output "MVN ${ICONS[disconnected]}" "disconnected" "Mullvad Yüklü Değil"
		return
	fi

	local status_output
	if ! status_output=$(timeout 5 mullvad status 2>/dev/null); then
		json_output "MVN ${ICONS[disconnected]}" "disconnected" "Mullvad Komut Hatası"
		return
	fi

	if echo "$status_output" | grep -q "Connected\|Connecting"; then
		local relay_info
		relay_info=$(echo "$status_output" | grep "Relay:" | head -1 | cut -d: -f2- | tr -d ' ' 2>/dev/null || echo "unknown")

		if check_interface_ip "wg0-mullvad"; then
			json_output "M-WG0 ${ICONS[mullvad]}" "connected" "Mullvad WireGuard: $relay_info"
		elif check_interface_ip "tun0"; then
			json_output "M-TUN0 ${ICONS[mullvad]}" "connected" "Mullvad OpenVPN: $relay_info"
		else
			json_output "MVN ${ICONS[warning]}" "warning" "Mullvad Bağlantı Problemi"
		fi
	else
		json_output "MVN ${ICONS[disconnected]}" "disconnected" "Mullvad Bağlantısız"
	fi
}

# Mullvad aktif mi kontrol et
is_mullvad_active() {
	if command -v mullvad >/dev/null 2>&1; then
		local status_output
		if status_output=$(timeout 3 mullvad status 2>/dev/null); then
			echo "$status_output" | grep -q "Connected\|Connecting"
		else
			return 1
		fi
	else
		return 1
	fi
}

# Diğer VPN'leri kontrol et
check_other_vpns() {
	local mullvad_active=false
	local other_vpn_active=false
	local other_vpn_interface=""
	local other_vpn_ip=""

	# Mullvad durumunu kontrol et
	if is_mullvad_active; then
		mullvad_active=true
	fi

	# Aktif VPN interface'lerini bul
	while IFS= read -r interface; do
		interface=$(echo "$interface" | tr -d '[:space:]')
		[[ -z "$interface" ]] && continue

		if check_interface_ip "$interface"; then
			# Mullvad aktif değilse veya interface Mullvad'a ait değilse
			if [[ "$mullvad_active" == false ]] || [[ "$interface" != "wg0-mullvad" && "$interface" != "tun0" ]]; then
				other_vpn_active=true
				other_vpn_interface="$interface"
				other_vpn_ip=$(ip addr show dev "$interface" 2>/dev/null | grep "inet " | awk '{print $2}' | cut -d/ -f1 | head -1)
				break
			fi
		fi
	done < <(ip link show 2>/dev/null | grep -E "tun|wg|gpd" | grep "UP" | cut -d: -f2 | awk '{print $1}')

	# Duruma göre sonuç üret
	if [[ "$mullvad_active" == true && "$other_vpn_active" == true ]]; then
		local formatted_name
		formatted_name=$(format_interface_name "$other_vpn_interface")
		json_output "DUAL ${ICONS[warning]}" "warning" "Çoklu VPN Aktif - Mullvad ve $formatted_name ($other_vpn_ip)"
	elif [[ "$mullvad_active" == true ]]; then
		json_output "MVN ${ICONS[connected]}" "mullvad-connected" "Mullvad VPN Aktif"
	elif [[ "$other_vpn_active" == true ]]; then
		local formatted_name
		formatted_name=$(format_interface_name "$other_vpn_interface")
		json_output "$formatted_name ${ICONS[connected]}" "vpn-connected" "$other_vpn_interface: $other_vpn_ip"
	else
		json_output "OVN ${ICONS[disconnected]}" "disconnected" "VPN Bağlantısı Yok"
	fi
}

# Genel VPN durumunu kontrol et
check_vpn_status() {
	if ip link show 2>/dev/null | grep -E "tun|wg|gpd" | grep -q "UP"; then
		json_output "VPN ${ICONS[connected]}" "connected" "VPN Bağlı"
	else
		json_output "VPN ${ICONS[disconnected]}" "disconnected" "VPN Bağlantısız"
	fi
}

# Yardım bilgilerini göster
show_help() {
	cat <<EOF
Kullanım: vpn-waybar [komut]

Komutlar:
  vpn-mullvad            Mullvad VPN durumunu kontrol et
  vpn-other              Diğer VPN bağlantılarını kontrol et
  vpn-status             Genel VPN durumunu kontrol et
  help                   Bu yardım mesajını göster
EOF
}

# Ana kontrol
main() {
	case "${1:-help}" in
	"vpn-mullvad") check_mullvad_status ;;
	"vpn-other") check_other_vpns ;;
	"vpn-status") check_vpn_status ;;
	*) show_help ;;
	esac
}

# Script'i çalıştır
main "$@"
