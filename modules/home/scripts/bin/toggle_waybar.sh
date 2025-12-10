#!/usr/bin/env bash
# toggle_waybar.sh - Waybar görünürlük toggler
# Waybar sürecini durdurup başlatır veya layer görünürlüğünü değiştirir.

SERVICE=".waybar-wrapped"

if pgrep -x "$SERVICE" > /dev/null; then
    pkill -9 waybar
else
    runbg waybar
fi
