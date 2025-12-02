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

## Simple Script To Pick Color Quickly.

pick_color() {
  local geometry
  geometry=$(slurp -b 1B1F2800 -p) || return 1

  # Check if geometry is not empty
  if [ -z "$geometry" ]; then
    notify-send "Error" "No area selected"
    return 1
  fi # Buradaki kapanış parantezini düzelttim

  local color
  color=$(grim -g "$geometry" -t ppm - |
    magick - -format '%[pixel:p{0,0}]' txt:- 2>/dev/null |
    tail -n1 | cut -d' ' -f4)

  # Check if color was successfully captured
  if [ -n "$color" ]; then
    # Copy to clipboard
    echo -n "$color" | wl-copy

    # Create temporary image for preview
    local image="/tmp/color_preview_${color//[#\/\\]/}.png"
    magick -size 48x48 xc:"$color" "$image" 2>/dev/null

    # Show notification
    if [ -f "$image" ]; then
      notify-send -h string:x-canonical-private-synchronous:sys-notify -u low -i "$image" "$color, copied to clipboard."
    else
      notify-send -h string:x-canonical-private-synchronous:sys-notify -u low "$color, copied to clipboard."
    fi

    # Clean up
    rm -f "$image"
  else
    notify-send "Error" "Failed to capture color"
    return 1
  fi
}

# Run the script
pick_color
