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

# Set default values
ANOTE_CMD="${ANOTE_CMD:-anote}"
ANOTE_WINDOW_TITLE="Anote"
ANOTE_WINDOW_CLASS="anote"

# Set EDITOR environment variable to nvim if not already set
if [ -z "$EDITOR" ] && [ -z "$VISUAL" ]; then
	export EDITOR=nvim
fi

# Detect terminal preference
if command -v kitty &>/dev/null; then
	TERMINAL_CMD="kitty --class $ANOTE_WINDOW_CLASS -T $ANOTE_WINDOW_TITLE --single-instance"
elif command -v wezterm &>/dev/null; then
	TERMINAL_CMD="wezterm start --class $ANOTE_WINDOW_CLASS --window-title $ANOTE_WINDOW_TITLE"
else
	# Fallback to a generic terminal command
	command -v alacritty &>/dev/null && TERMINAL_CMD="alacritty --class $ANOTE_WINDOW_CLASS -t $ANOTE_WINDOW_TITLE"
	command -v gnome-terminal &>/dev/null && TERMINAL_CMD="gnome-terminal --class=$ANOTE_WINDOW_CLASS --title=$ANOTE_WINDOW_TITLE"
	command -v xterm &>/dev/null && TERMINAL_CMD="xterm -class $ANOTE_WINDOW_CLASS -title $ANOTE_WINDOW_TITLE"

	# If no terminal found, exit with error
	if [ -z "$TERMINAL_CMD" ]; then
		echo "Error: No supported terminal found (kitty, wezterm, alacritty, gnome-terminal, or xterm)" >&2
		exit 1
	fi
fi

# Set working directory
WORK_DIR="${ANOTE_DIR:-$HOME/.anote}"
mkdir -p "$WORK_DIR" 2>/dev/null

# Run anote with specified options
case "$1" in
-t | --single)
	$TERMINAL_CMD -e bash -c "$ANOTE_CMD -t"
	;;
-M | --multi)
	$TERMINAL_CMD -e bash -c "$ANOTE_CMD -M"
	;;
-s | --search)
	$TERMINAL_CMD -e bash -c "$ANOTE_CMD -s"
	;;
-A | --audit)
	$TERMINAL_CMD -e bash -c "$ANOTE_CMD -A"
	;;
-h | --help)
	echo "Usage: anotes [option]"
	echo "Options:"
	echo "  -t, --single   Run anote in single mode (snippet kopyalama)"
	echo "  -M, --multi    Run anote in multi mode (çok satırlı snippet)"
	echo "  -s, --search   Run anote in search mode (dosyalarda arama yap)"
	echo "  -A, --audit    Run anote in audit mode (karalama defteri)"
	echo "  -h, --help     Show this help message"
	echo "  (no option)    Run anote with default settings"
	;;
*)
	$TERMINAL_CMD -e bash -c "$ANOTE_CMD"
	;;
esac

# Exit with success status
exit 0
