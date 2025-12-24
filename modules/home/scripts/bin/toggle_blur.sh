#!/usr/bin/env bash
# toggle_blur.sh - Blur efekti aç/kapa
# Hyprland blur ayarını değiştirir.

if hyprctl getoption decoration:blur:enabled | grep "int: 1" > /dev/null; then
    hyprctl keyword decoration:blur:enabled false > /dev/null
else
    hyprctl keyword decoration:blur:enabled true > /dev/null
fi
