#!/usr/bin/env bash

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
exit 0
