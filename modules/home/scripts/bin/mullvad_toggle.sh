#!/usr/bin/env bash

# Function to check Mullvad VPN status
check_vpn_status() {
  mullvad status | grep -q "Connected"
  return $?
}

# Function to connect to Mullvad VPN
connect_vpn() {
  mullvad connect >>/dev/null 2>&1 &
  disown
  notify-send -t 5000 "🔒 MULLVAD VPN" "Connection Status: ACTIVE" -i security-high
}

# Function to disconnect from Mullvad VPN
disconnect_vpn() {
  mullvad disconnect >>/dev/null 2>&1 &
  disown
  notify-send -t 5000 "🔓 MULLVAD VPN" "Connection Status: INACTIVE" -i security-medium
}

# Function to toggle VPN connection
toggle_vpn() {
  if check_vpn_status; then
    disconnect_vpn
  else
    connect_vpn
  fi
}

# Check if a parameter is provided
if [[ -z $1 ]]; then
  toggle_vpn # Default action is toggle when no parameter
  exit 0
fi

# Check parameter and execute the corresponding function
case "$1" in
toggle)
  toggle_vpn
  ;;
connect)
  if check_vpn_status; then
    echo "VPN is already connected."
    notify-send -t 5000 "ℹ️ MULLVAD VPN" "Already ACTIVE" -i security-high
  else
    connect_vpn
  fi
  ;;
disconnect)
  if check_vpn_status; then
    disconnect_vpn
  else
    echo "VPN is already disconnected."
    notify-send -t 5000 "ℹ️ MULLVAD VPN" "Already INACTIVE" -i security-medium
  fi
  ;;
*)
  echo "Usage: $0 [toggle|connect|disconnect]"
  echo "If no parameter is provided, toggle action will be performed."
  exit 1
  ;;
esac
