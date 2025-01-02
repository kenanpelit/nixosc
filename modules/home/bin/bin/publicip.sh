#!/usr/bin/env bash

# WanIP Checker
# Checks current IP address and country, showing both terminal output and desktop notification
# Dependencies: curl, notify-send, mullvad-vpn
# Author: Kenan
# Usage: ./wanip.sh

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

notify() {
  notify-send "$1" "$2"
}

get_country() {
  local ip=$1
  if country=$(curl -s "https://ipapi.co/$ip/country_name"); then
    echo "$country"
  fi
}

check_ip() {
  real_ip=$(curl -s https://ipinfo.io/ip)
  status_output=$(mullvad status)

  if echo "$status_output" | grep -q "Connected"; then
    vpn_ip=$(echo "$status_output" | grep -oP "IPv4: \K[0-9.]+")
    if [ "$real_ip" != "$vpn_ip" ]; then
      country=$(get_country "$real_ip")
      message="Regular IP: $real_ip"
      notify "IP Status" "$message\nCountry: $country"
      echo -e "${GREEN}Regular IP:${NC} $real_ip"
      echo -e "Country: ${GREEN}$country${NC}"
    else
      country=$(get_country "$vpn_ip")
      message="Mullvad IP: $vpn_ip"
      notify "IP Status" "$message\nCountry: $country"
      echo -e "${GREEN}Mullvad IP:${NC} $vpn_ip"
      echo -e "Country: ${GREEN}$country${NC}"
    fi
    return 0
  else
    country=$(get_country "$real_ip")
    message="Regular IP: $real_ip"
    notify "IP Status" "$message\nCountry: $country"
    echo -e "${GREEN}Regular IP:${NC} $real_ip"
    echo -e "Country: ${GREEN}$country${NC}"
    return 0
  fi
}

check_ip
