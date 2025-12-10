#!/usr/bin/env bash
# toggle_float.sh - Pencere float toggle
# Hyprland’da aktif pencereyi float/tiling modları arasında geçiştirir.

hyprctl dispatch togglefloating
hyprctl dispatch resizeactive exact 950 600
hyprctl dispatch centerwindow
