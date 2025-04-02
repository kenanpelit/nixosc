#!/usr/bin/env bash

# anotes - a script to run anote in kitty or wezterm with various options
# Usage: anotes [option]
# Sets nvim as the default editor if no EDITOR is defined
# Options:
#   -t, --single   Run anote in single mode
#   -M, --multi    Run anote in multi mode
#   -s, --search   Run anote in search mode
#   -A, --audit    Run anote in audit mode
#   -h, --help     Show this help message
#   (no option)    Run anote with default settings

# Set EDITOR environment variable to nvim if not already set
if [ -z "$EDITOR" ] && [ -z "$VISUAL" ]; then
	export EDITOR=nvim
fi

# Detect terminal preference
# We'll check if wezterm is available, otherwise fall back to kitty
if command -v wezterm &>/dev/null; then
	TERMINAL_CMD="wezterm start --class anote"
else
	TERMINAL_CMD="kitty --class anote -T anote --single-instance"
fi

case "$1" in
-t | --single)
	$TERMINAL_CMD -e anote -t
	;;
-M | --multi)
	$TERMINAL_CMD -e anote -M
	;;
-s | --search)
	$TERMINAL_CMD -e anote -s
	;;
-A | --audit)
	$TERMINAL_CMD -e anote -A
	;;
-h | --help)
	echo "Usage: anotes [option]"
	echo "Options:"
	echo "  -t, --single   Run anote in single mode"
	echo "  -M, --multi    Run anote in multi mode"
	echo "  -s, --search   Run anote in search mode"
	echo "  -A, --audit    Run anote in audit mode"
	echo "  -h, --help     Show this help message"
	echo "  (no option)    Run anote with default settings"
	;;
*)
	$TERMINAL_CMD -e anote
	;;
esac
