#!/usr/bin/env bash
# WiFi Management Script using iwmenu and rofi
# Author: Kenan Pelit
# Date: 2024-01-14

# Check if iwmenu is installed
if ! command -v iwmenu >/dev/null 2>&1; then
	notify-send "Error" "iwmenu is not installed"
	exit 1
fi

# Check if rofi is installed
if ! command -v rofi >/dev/null 2>&1; then
	notify-send "Error" "rofi is not installed"
	exit 1
fi

# Execute iwmenu with rofi
exec iwmenu --menu custom --menu-command "rofi -dmenu -i -p 'Wi-Fi'"
