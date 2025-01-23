#!/usr/bin/env bash
#===============================================================================
#
#   Script: OSC Transmission Blocklist Manager
#   Version: 1.0.0
#   Date: 2024-01-23
#   Author: Kenan Pelit
#   Repository: https://github.com/kenanpelit/nixosc
#   Description: Comprehensive blocklist management utility for Transmission
#                that aggregates and processes multiple IP blocklists
#
#   Features:
#   - Multiple blocklist sources (Bluetack, FireHol, etc.)
#   - Smart list processing with deduplication
#   - Support for both user and system Transmission instances
#   - Automatic service restart after updates
#   - Timestamped backups
#   - Robust error handling
#
#   License: MIT
#
#===============================================================================

set -euo pipefail

URLS=(
	# Bluetack Temel Listeler
	"http://list.iblocklist.com/?list=bt_level1"    # Genel kötü eşler
	"http://list.iblocklist.com/?list=bt_level2"    # Genel istenmeyen eşler
	"http://list.iblocklist.com/?list=bt_level3"    # Düşük riskli eşler
	"http://list.iblocklist.com/?list=bt_bogon"     # Geçersiz IP aralıkları
	"http://list.iblocklist.com/?list=bt_dshield"   # DShield tarafından tanımlanan IP'ler
	"http://list.iblocklist.com/?list=bt_hijacked"  # Ele geçirilmiş sistemler
	"http://list.iblocklist.com/?list=bt_microsoft" # Microsoft kötü IP'leri
	"http://list.iblocklist.com/?list=bt_templist"  # Geçici engel listesi
	"http://list.iblocklist.com/?list=bt_spyware"   # Bilinen zararlı yazılım

	# Ek Tehdit Listeleri
	"http://list.iblocklist.com/?list=ijfqtofzixtwayqovmxn" # Primary Threats
	"http://list.iblocklist.com/?list=ecqbsykllnadihkdirsh" # Pedophiles
	"http://list.iblocklist.com/?list=tbnuqfclfkemqivekikv" # Internet Storm Center
	"http://list.iblocklist.com/?list=ewqglwibdgjttwttrinl" # Bogons

	# FireHol Listesi
	"https://raw.githubusercontent.com/firehol/blocklist-ipsets/master/firehol_level1.netset"
)

# Blocklist directories
DIRS=(
	"${HOME}/.config/transmission/blocklists"
	"${HOME}/.config/transmission-daemon/blocklists"
)

# Create directories if they don't exist
for DIR in "${DIRS[@]}"; do
	mkdir -p "${DIR}"
done

# Generate timestamp
TIMESTAMP=$(date +%Y%m%d-%H%M)

# Download and process blocklists once
echo "Downloading and processing blocklists..."
TEMP_FILE=$(mktemp)
if ! wget "${URLS[@]}" -O - | gunzip | LC_ALL=C sort -u >"${TEMP_FILE}"; then
	echo "Error: Failed to download or process blocklists"
	rm -f "${TEMP_FILE}"
	exit 1
fi

# Copy to both directories
for DIR in "${DIRS[@]}"; do
	# Remove old blocklists
	rm -f "${DIR}"/extras* "${DIR}"/blocklist*

	# Copy as extras with timestamp
	cp "${TEMP_FILE}" "${DIR}/extras-${TIMESTAMP}.txt"

	# Copy as blocklist
	cp "${TEMP_FILE}" "${DIR}/blocklist"

	echo "Updated blocklists in: ${DIR}"
done

# Clean up
rm -f "${TEMP_FILE}"

echo "Successfully updated all blocklists"

# Restart transmission-daemon to apply changes
if systemctl --user is-active transmission.service &>/dev/null; then
	echo "Restarting transmission user service..."
	systemctl --user restart transmission.service
elif systemctl is-active transmission-daemon.service &>/dev/null; then
	echo "Restarting transmission system service..."
	sudo systemctl restart transmission-daemon.service
fi
