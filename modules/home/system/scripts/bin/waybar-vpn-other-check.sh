#!/usr/bin/env bash

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
