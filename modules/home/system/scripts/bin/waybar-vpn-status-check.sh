#!/usr/bin/env bash

# Modern shield/lock tarzı VPN ikonları
ICON_CONNECTED="󰦝 "    # Shield with check mark
ICON_DISCONNECTED="󰦞 " # Shield with x mark

## Alternatif seçenekler:
#ICON_CONNECTED="󰌆"    # Lock with shield
#ICON_DISCONNECTED="󰌉" # Broken lock with shield

## Klasik lock tarzı
#ICON_CONNECTED="󰒃 "    # Locked padlock
#ICON_DISCONNECTED="󰒄 " # Unlocked padlock

## Globe tarzı
#ICON_CONNECTED="󰖟"    # Protected globe
#ICON_DISCONNECTED="󰖪" # Unprotected globe

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
