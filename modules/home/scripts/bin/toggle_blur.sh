#!/usr/bin/env bash
# toggle_blur.sh - Blur efekti aç/kapa
# Waybar/Hyprland blur ayarını değiştirip yeniden yükler, bildirim gönderir.

if hyprctl getoption decoration:blur:enabled | grep "int: 1" > /dev/null; then
    hyprctl keyword decoration:blur:enabled false > /dev/null
else
    hyprctl keyword decoration:blur:enabled true > /dev/null
fi
