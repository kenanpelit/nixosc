#!/usr/bin/env bash
#######################################
#
# Version: 1.0.0
# Date: 2024-12-08
# Author: Kenan Pelit
# Repository: github.com/kenanpelit/dotfiles
# Description: HyprFlow
#
# License: MIT
#
#######################################

# Monitör tanımlamaları
MONITOR_DELL="DP-5"    # ID 1
MONITOR_LAPTOP="eDP-1" # ID 0

# Workspace listesi
workspaces=(1 2 3 4 5 6 7 8 9)

for ws in "${workspaces[@]}"; do
  # Önce workspace'i oluştur
  hyprctl dispatch workspace "$ws"
  sleep 0.1 # Oluşturulması için kısa bekleme

  if [[ "$ws" -le 6 ]]; then
    # 1-6 arası Dell monitöre
    hyprctl dispatch moveworkspacetomonitor "$ws" "$MONITOR_DELL"
  else
    # 7-9 arası laptop ekranına
    hyprctl dispatch moveworkspacetomonitor "$ws" "$MONITOR_LAPTOP"
  fi
done

# En son workspace 1'e dön
hyprctl dispatch workspace 1
