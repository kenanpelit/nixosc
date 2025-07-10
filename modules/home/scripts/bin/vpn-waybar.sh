#!/usr/bin/env bash

# osc-waybar - waybar yardımcı programı
# Kullanım: osc-waybar [komut]

set -euo pipefail # Hata yönetimi için

VERSION="1.1.0"

# Renkler ve loglar için
readonly LOG_FILE="/tmp/osc-waybar.log"
readonly CACHE_DIR="/tmp/osc-waybar-cache"
readonly CACHE_TTL=5 # saniye

# İkon tanımlamaları
declare -A ICONS=(
	["connected"]="󰦝 "
	["disconnected"]="󰦞 "
	["mullvad"]="󰒃 "
	["mullvad_alt"]="󰯄 "
	["locked"]="󰒃 "
	["warning"]="󰀦 "
)

# Logging fonksiyonu
log_message() {
	local level="$1"
	local message="$2"
	echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $message" >>"$LOG_FILE"
}

# Cache kontrol fonksiyonu
check_cache() {
	local cache_key="$1"
	local cache_file="$CACHE_DIR/$cache_key"

	if [[ -f "$cache_file" ]]; then
		local cache_age=$(($(date +%s) - $(stat -c %Y "$cache_file" 2>/dev/null || echo 0)))
		if [[ $cache_age -lt $CACHE_TTL ]]; then
			cat "$cache_file"
			return 0
		fi
	fi
	return 1
}

# Cache yazma fonksiyonu
write_cache() {
	local cache_key="$1"
	local content="$2"

	mkdir -p "$CACHE_DIR"
	echo "$content" >"$CACHE_DIR/$cache_key"
}

# JSON output fonksiyonu
json_output() {
	local text="$1"
	local class="$2"
	local tooltip="$3"

	printf '{"text": "%s", "class": "%s", "tooltip": "%s"}\n' "$text" "$class" "$tooltip"
}

# Interface IP kontrolü
check_interface_ip() {
	local interface="$1"

	if [[ ! -d "/proc/sys/net/ipv4/conf/$interface" ]]; then
		return 1
	fi

	ip addr show dev "$interface" 2>/dev/null | grep -q "inet " || return 1
	return 0
}

# Interface adı formatlama
format_interface_name() {
	local interface="$1"
	local base_name
	local number

	base_name=$(echo "$interface" | sed 's/[0-9]*$//')
	number=$(echo "$interface" | grep -o '[0-9]*$' || echo "")

	echo "${base_name^^}${number}"
}

# Mullvad durumu kontrol
check_mullvad_status() {
	local cache_result

	# Cache kontrol et
	if cache_result=$(check_cache "mullvad_status"); then
		echo "$cache_result"
		return 0
	fi

	local status_output
	local result

	if ! status_output=$(timeout 5 mullvad status 2>/dev/null); then
		log_message "ERROR" "Mullvad komut çalıştırılamadı"
		result="disconnected"
	elif echo "$status_output" | grep -q "Connected\|Connecting"; then
		local relay_line
		relay_line=$(echo "$status_output" | grep "Relay:" | tr -d ' ')

		if echo "$relay_line" | grep -q "ovpn" && check_interface_ip "tun0"; then
			local text
			text=$(echo "$relay_line" | cut -d':' -f2)
			result=$(json_output "M-TUN0 ${ICONS[mullvad]}" "connected" "Mullvad: $text")
		elif echo "$relay_line" | grep -q "wg" && check_interface_ip "wg0-mullvad"; then
			local text
			text=$(echo "$relay_line" | cut -d':' -f2)
			result=$(json_output "M-WG0 ${ICONS[mullvad]}" "connected" "Mullvad: $text")
		else
			result=$(json_output "MVN ${ICONS[disconnected]}" "disconnected" "Mullvad Bağlantı Problemi")
		fi
	else
		result=$(json_output "MVN ${ICONS[disconnected]}" "disconnected" "Mullvad Bağlantısız")
	fi

	# Cache'e yaz
	write_cache "mullvad_status" "$result"
	echo "$result"
}

# Mullvad aktif mi kontrol et
is_mullvad_active() {
	local status_output

	if status_output=$(timeout 3 mullvad status 2>/dev/null); then
		echo "$status_output" | grep -q "Connected\|Connecting"
	else
		return 1
	fi
}

# Diğer VPN'leri kontrol et
check_other_vpns() {
	local cache_result

	# Cache kontrol et
	if cache_result=$(check_cache "other_vpns"); then
		echo "$cache_result"
		return 0
	fi

	local mullvad_active=false
	local other_vpn_active=false
	local other_vpn_interface=""
	local other_vpn_ip=""
	local result

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
		result=$(json_output "DUAL ${ICONS[warning]}" "warning" "Çoklu VPN Aktif - Mullvad ve $formatted_name ($other_vpn_ip)")
	elif [[ "$mullvad_active" == true ]]; then
		result=$(json_output "MVN ${ICONS[connected]}" "mullvad-connected" "Mullvad VPN Aktif")
	elif [[ "$other_vpn_active" == true ]]; then
		local formatted_name
		formatted_name=$(format_interface_name "$other_vpn_interface")
		result=$(json_output "$formatted_name ${ICONS[connected]}" "vpn-connected" "$other_vpn_interface: $other_vpn_ip")
	else
		result=$(json_output "OVN ${ICONS[disconnected]}" "disconnected" "VPN Bağlantısı Yok")
	fi

	# Cache'e yaz
	write_cache "other_vpns" "$result"
	echo "$result"
}

# Genel VPN durumunu kontrol et
check_vpn_status() {
	local cache_result

	# Cache kontrol et
	if cache_result=$(check_cache "vpn_status"); then
		echo "$cache_result"
		return 0
	fi

	local result

	# Herhangi bir VPN interface'i aktif mi kontrol et
	if ip link show 2>/dev/null | grep -E "tun|wg|gpd" | grep -q "UP"; then
		result=$(json_output "VPN ${ICONS[connected]}" "connected" "VPN Bağlı")
	else
		result=$(json_output "VPN ${ICONS[disconnected]}" "disconnected" "VPN Bağlantısız")
	fi

	# Cache'e yaz
	write_cache "vpn_status" "$result"
	echo "$result"
}

# Yardım bilgilerini göster
show_help() {
	cat <<EOF
Kullanım: osc-waybar [komut]

Komutlar:
  vpn-mullvad            Mullvad VPN durumunu kontrol et
  vpn-other              Diğer VPN bağlantılarını kontrol et
  vpn-status             Genel VPN durumunu kontrol et
  clear-cache            Cache'i temizle
  help                   Bu yardım mesajını göster
  version                Sürüm bilgisini göster

Özellikler:
  • 5 saniye cache ile performans optimizasyonu
  • Detaylı hata günlüğü tutma
  • Timeout koruması
  • Gelişmiş hata yönetimi

Cache dosyası: $CACHE_DIR
Log dosyası: $LOG_FILE
EOF
}

# Cache temizleme
clear_cache() {
	if [[ -d "$CACHE_DIR" ]]; then
		rm -rf "$CACHE_DIR"
		echo "Cache temizlendi."
	else
		echo "Cache bulunamadı."
	fi
}

# Sürüm bilgisini göster
show_version() {
	echo "osc-waybar sürüm $VERSION"
	echo "Geliştirilmiş versiyon - cache, logging ve hata yönetimi ile"
}

# Ana kontrol
main() {
	case "${1:-help}" in
	"vpn-mullvad")
		check_mullvad_status
		;;
	"vpn-other")
		check_other_vpns
		;;
	"vpn-status")
		check_vpn_status
		;;
	"clear-cache")
		clear_cache
		;;
	"version")
		show_version
		;;
	"help" | "--help" | "-h" | *)
		show_help
		;;
	esac
}

# Script'i çalıştır
main "$@"
