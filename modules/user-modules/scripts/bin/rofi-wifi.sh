#!/usr/bin/env bash
# WiFi Management Script using iwd and rofi
# Author: Kenan Pelit
# Configuration
DEVICE=${1:-wlan0}
POSITION=${2:-0}
Y_OFF=${3:-0}
X_OFF=${4:-0}
FONT="DejaVu Sans Mono 12"
# Notify function
notify() {
	if command -v notify-send >/dev/null 2>&1; then
		notify-send -t 5000 "WiFi Manager" "$1"
	fi
	echo "$1"
}
# Scan networks
notify "Scanning networks..."
iwctl station $DEVICE scan
sleep 2
# Get current SSID
CURR_SSID=$(iwctl station $DEVICE show | sed -n 's/^\s*Connected\snetwork\s*\(\S*\)\s*$/\1/p')
# Get network list and remove headers/formatting
IW_NETWORKS=$(iwctl station $DEVICE get-networks | sed '/^--/d')
IW_NETWORKS=$(echo "$IW_NETWORKS" | sed '1,4d')
IW_NETWORKS=$(echo "$IW_NETWORKS" | sed -r "s/\x1B\[([0-9]{1,3}(;[0-9]{1,2})?)?[mGK]//g")
# Format network list with current network at top
PREFIX="Networks\n"
NETWORK_LIST=""
while IFS= read -r line; do
	[ -z "$line" ] && continue
	line=${line:4}
	SSID_NAME=$(echo "$line" | sed 's/\(\s*psk.*\)//')
	SSID_NAME=$(echo "$SSID_NAME" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
	[ -z "$SSID_NAME" ] && continue
	# Format line with fixed width
	if [ "$SSID_NAME" = "$CURR_SSID" ]; then
		printf -v network_part "%-45s" "$SSID_NAME ⚡"
	else
		printf -v network_part "%-45s" "$SSID_NAME"
	fi
	line="$network_part\n"
	if [ "$SSID_NAME" = "$CURR_SSID" ]; then
		PREFIX+=$line
	else
		NETWORK_LIST+=$line
	fi
done <<<"$IW_NETWORKS"
IW_NETWORKS=$PREFIX$NETWORK_LIST
# Build menu based on connection state
CON_STATE=$(iwctl station $DEVICE show)
if [[ "$CON_STATE" =~ " connected" ]]; then
	MENU="disconnect from ${CURR_SSID}\nmanually connect to a network\n$IW_NETWORKS"
else
	MENU="manually connect to a network\n$IW_NETWORKS"
fi
# Calculate rofi window dimensions
R_WIDTH=$(($(echo "$IW_NETWORKS" | head -n 1 | awk '{print length($0); }') + 5))
LINE_COUNT=$(echo "$IW_NETWORKS" | wc -l)
if [[ "$CON_STATE" =~ " connected" ]] || [ "$LINE_COUNT" -gt 8 ]; then
	LINE_COUNT=12
fi
# Show rofi menu
CHENTRY=$(echo -e "$MENU" | uniq -u | rofi -dmenu \
	-p "WiFi SSID" \
	-lines "$LINE_COUNT" \
	-location "$POSITION" \
	-yoffset "$Y_OFF" \
	-xoffset "$X_OFF" \
	-font "$FONT" \
	-width -"$R_WIDTH")
[ -z "$CHENTRY" ] && exit 0
# Process selection
CHSSID=$(echo "$CHENTRY" | sed 's/\s\{2,\}/\|/g' | awk -F "|" '{print $1}' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
# Handle selection
if [ "$CHENTRY" = "manually connect to a network" ]; then
	MSSID=$(echo "Enter your network's SSID." | rofi -dmenu \
		-p "SSID: " \
		-font "$FONT" \
		-lines 1)
	[ -z "$MSSID" ] && exit 0
	WIFI_PASS=$(echo "Enter the network password." | rofi -dmenu \
		-password \
		-p "Password: " \
		-lines 1 \
		-location "$POSITION" \
		-yoffset "$Y_OFF" \
		-xoffset "$X_OFF" \
		-font "$FONT" \
		-width -"$R_WIDTH")
	[ -z "$WIFI_PASS" ] && exit 0
	iwctl station $DEVICE disconnect
	iwctl --passphrase "$WIFI_PASS" station $DEVICE connect "$MSSID"
elif [[ "$CHENTRY" =~ "disconnect from " ]]; then
	iwctl station $DEVICE disconnect
elif [ "$CHSSID" != "" ]; then
	WIFI_PASS=$(echo "Enter the network password." | rofi -dmenu \
		-password \
		-p "Password: " \
		-lines 1 \
		-location "$POSITION" \
		-yoffset "$Y_OFF" \
		-xoffset "$X_OFF" \
		-font "$FONT" \
		-width -"$R_WIDTH")
	[ -z "$WIFI_PASS" ] && exit 0
	iwctl station $DEVICE disconnect
	iwctl --passphrase "$WIFI_PASS" station $DEVICE connect "$CHSSID"
fi
