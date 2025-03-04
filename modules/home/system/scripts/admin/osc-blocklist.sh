#!/usr/bin/env bash
#===============================================================================
#
#   Script: OSC Transmission Blocklist Manager
#   Version: 1.1.0
#   Date: 2025-03-04
#   Original Author: Kenan Pelit
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

# Define blocklist URLs
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
	#"${HOME}/.config/transmission/blocklists"
	"${HOME}/.config/transmission-daemon/blocklists"
)

# Create directories if they don't exist
for DIR in "${DIRS[@]}"; do
	mkdir -p "${DIR}"
done

# Generate timestamp
TIMESTAMP=$(date +%Y%m%d-%H%M)

# Create a temporary directory
TEMP_DIR=$(mktemp -d)
MERGED_FILE="${TEMP_DIR}/merged_blocklist.txt"
touch "${MERGED_FILE}"

echo "Downloading and processing blocklists..."

# Process each URL individually
for URL in "${URLS[@]}"; do
	echo "Processing: ${URL}"
	TEMP_FILE="${TEMP_DIR}/$(basename "${URL}")"

	# Download the file
	if ! wget -q "${URL}" -O "${TEMP_FILE}"; then
		echo "Warning: Failed to download ${URL}"
		continue
	fi

	# Process the file based on its type
	PROCESSED_FILE="${TEMP_FILE}.processed"

	# Check if file is gzipped
	if file "${TEMP_FILE}" | grep -q "gzip"; then
		# Decompress gzipped file
		if ! gunzip -c "${TEMP_FILE}" >"${PROCESSED_FILE}"; then
			echo "Warning: Failed to decompress ${TEMP_FILE}"
			continue
		fi
	else
		# Just copy the file if it's not gzipped
		cp "${TEMP_FILE}" "${PROCESSED_FILE}"
	fi

	# Append to the merged file
	cat "${PROCESSED_FILE}" >>"${MERGED_FILE}"
done

# Sort and deduplicate the merged file
FINAL_FILE="${TEMP_DIR}/blocklist.txt"
if ! LC_ALL=C sort -u "${MERGED_FILE}" >"${FINAL_FILE}"; then
	echo "Error: Failed to sort and deduplicate blocklists"
	rm -rf "${TEMP_DIR}"
	exit 1
fi

# Check if we have any content
if [[ ! -s "${FINAL_FILE}" ]]; then
	echo "Error: No blocklist content was successfully downloaded"
	rm -rf "${TEMP_DIR}"
	exit 1
fi

# Copy to both directories
for DIR in "${DIRS[@]}"; do
	# Remove old blocklists
	rm -f "${DIR}"/extras* "${DIR}"/blocklist*

	# Copy as extras with timestamp
	cp "${FINAL_FILE}" "${DIR}/extras-${TIMESTAMP}.txt"

	# Copy as blocklist
	cp "${FINAL_FILE}" "${DIR}/blocklist"

	echo "Updated blocklists in: ${DIR}"
done

# Clean up
rm -rf "${TEMP_DIR}"
echo "Successfully updated all blocklists"

# Restart transmission-daemon to apply changes
if systemctl --user is-active transmission.service &>/dev/null; then
	echo "Restarting transmission user service..."
	systemctl --user restart transmission.service
elif systemctl is-active transmission-daemon.service &>/dev/null; then
	echo "Restarting transmission system service..."
	sudo systemctl restart transmission-daemon.service
fi
