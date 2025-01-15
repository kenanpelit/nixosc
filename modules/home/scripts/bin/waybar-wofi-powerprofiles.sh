#!/usr/bin/env bash

# Check if WOFI_DIR is set
if [ -z "$WOFI_DIR" ]; then
  WOFI_DIR="$HOME/.config/wofi"
fi

# Variables
prompt="Power Profiles"
current_profile=$(powerprofilesctl get)

# Options
option_1="   Balanced"
option_2="   Performance"
option_3="   Power-Saver"

# Wofi command
wofi_cmd() {
  wofi \
    --dmenu \
    --style "$WOFI_DIR/styles/bluetooth.css" \
    --conf "$WOFI_DIR/configs/powerprofiles" \
    --cache-file=/dev/null \
    --width 300 \
    --height 220 \
    --prompt "Power Profiles"
}

# Pass variables to wofi dmenu
run_wofi() {
  echo -e "$option_1\n$option_2\n$option_3" | wofi_cmd
}

# Confirmation CMD
confirm_cmd() {
  echo -e "Yes\nNo" | wofi --dmenu \
    --prompt "Are you Sure?" \
    --width 200 \
    --height 120 \
    --cache-file /dev/null
}

# Ask for confirmation
confirm_exit() {
  confirm_cmd
}

# Confirm and execute
confirm_run() {
  selected="$(confirm_exit)"
  if [[ "$selected" == "Yes" ]]; then
    ${1} && ${2} && ${3}
  else
    exit
  fi
}

# Execute Command
run_cmd() {
  if [[ "$1" == '--opt1' ]]; then
    confirm_run 'powerprofilesctl set balanced'
    notify-send -t 5000 " Powerprofiles" "Set to: Balanced"
  elif [[ "$1" == '--opt2' ]]; then
    confirm_run 'powerprofilesctl set performance'
    notify-send -t 5000 " Powerprofiles" "Set to: Performance"
  elif [[ "$1" == '--opt3' ]]; then
    confirm_run 'powerprofilesctl set power-saver'
    notify-send -t 5000 " Powerprofiles" "Set to: Power-Saver"
  fi
}

# Actions
chosen="$(run_wofi)"
case ${chosen} in
"$option_1")
  run_cmd --opt1
  ;;
"$option_2")
  run_cmd --opt2
  ;;
"$option_3")
  run_cmd --opt3
  ;;
esac
