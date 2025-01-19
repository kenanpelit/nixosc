#!/usr/bin/env bash

# This script defines a power menu mode for rofi
set -e
set -u

# All supported choices
all=(shutdown reboot suspend hibernate lockscreen)

# By default, show all choices
show=("${all[@]}")

declare -A texts
texts[lockscreen]="lock screen"
texts[switchuser]="switch user"
texts[logout]="log out"
texts[suspend]="suspend"
texts[hibernate]="hibernate"
texts[reboot]="reboot"
texts[shutdown]="shut down"

declare -A icons
icons[lockscreen]="\Uf033e"
icons[switchuser]="\Uf0019"
icons[logout]="\Uf0343"
icons[suspend]="\Uf04b2"
icons[hibernate]="\Uf02ca"
icons[reboot]="\Uf0709"
icons[shutdown]="\Uf0425"
icons[cancel]="\Uf0156"

declare -A actions
actions[lockscreen]="swaylock"
actions[logout]="sway exit"
actions[suspend]="systemctl suspend -i"
actions[hibernate]="systemctl hibernate"
actions[reboot]="systemctl reboot -i"
actions[shutdown]="systemctl poweroff -i"

# Actions that require confirmation
confirmations=(reboot shutdown hibernate)

# Default settings
dryrun=false
showsymbols=true
showtext=true

function check_valid {
	option="$1"
	shift 1
	for entry in "${@}"; do
		if [ -z "${actions[$entry]+x}" ]; then
			echo "Invalid choice in $1: $entry" >&2
			exit 1
		fi
	done
}

# Parse command-line options
parsed=$(getopt --options=h --longoptions=help,dry-run,confirm:,choices:,choose:,symbols,no-symbols,text,no-text,symbols-font: --name "$0" -- "$@")
if [ $? -ne 0 ]; then
	echo 'Terminating...' >&2
	exit 1
fi
eval set -- "$parsed"
unset parsed

while true; do
	case "$1" in
	"-h" | "--help")
		echo "rofi-power-menu - a power menu mode for Rofi"
		echo
		echo "Usage: rofi-power-menu [--choices CHOICES] [--confirm CHOICES]"
		# ... (help text remains the same)
		exit 0
		;;
	"--dry-run")
		dryrun=true
		shift 1
		;;
	"--confirm")
		IFS='/' read -ra confirmations <<<"$2"
		check_valid "$1" "${confirmations[@]}"
		shift 2
		;;
	"--choices")
		IFS='/' read -ra show <<<"$2"
		check_valid "$1" "${show[@]}"
		shift 2
		;;
	"--choose")
		check_valid "$1" "$2"
		selectionID="$2"
		shift 2
		;;
	"--symbols")
		showsymbols=true
		shift 1
		;;
	"--no-symbols")
		showsymbols=false
		shift 1
		;;
	"--text")
		showtext=true
		shift 1
		;;
	"--no-text")
		showtext=false
		shift 1
		;;
	"--symbols-font")
		symbols_font="$2"
		shift 2
		;;
	"--")
		shift
		break
		;;
	*)
		echo "Internal error" >&2
		exit 1
		;;
	esac
done

if [ "$showsymbols" = "false" -a "$showtext" = "false" ]; then
	echo "Invalid options: cannot have --no-symbols and --no-text enabled at the same time." >&2
	exit 1
fi

function write_message {
	if [ -z ${symbols_font+x} ]; then
		icon="<span font_size=\"medium\">$1</span>"
	else
		icon="<span font=\"${symbols_font}\" font_size=\"medium\">$1</span>"
	fi
	text="<span font_size=\"medium\">$2</span>"
	if [ "$showsymbols" = "true" ]; then
		if [ "$showtext" = "true" ]; then
			echo -n "\u200e$icon \u2068$text\u2069"
		else
			echo -n "\u200e$icon"
		fi
	else
		echo -n "$text"
	fi
}

function print_selection {
	echo -e "$1" | $(
		read -r -d '' entry
		echo "echo $entry"
	)
}

# Execute the selected action safely
function execute_action {
	local action=$1
	if [ $dryrun = true ]; then
		echo "Selected: $action" >&2
	else
		# Launch the action in background
		eval "${actions[$action]}" &
		# Small delay to ensure action starts
		sleep 0.5
		# Gracefully close rofi
		pkill rofi
	fi
}

declare -A messages
declare -A confirmationMessages
for entry in "${all[@]}"; do
	messages[$entry]=$(write_message "${icons[$entry]}" "${texts[$entry]^}")
done
for entry in "${all[@]}"; do
	confirmationMessages[$entry]=$(write_message "${icons[$entry]}" "Yes, ${texts[$entry]}")
done
confirmationMessages[cancel]=$(write_message "${icons[cancel]}" "No, cancel")

if [ $# -gt 0 ]; then
	selection="${@}"
elif [ -n "${selectionID+x}" ]; then
	selection="${messages[$selectionID]}"
fi

# Don't allow custom entries
echo -e "\0no-custom\x1ftrue"
# Use markup
echo -e "\0markup-rows\x1ftrue"

if [ -z "${selection+x}" ]; then
	echo -e "\0prompt\x1fPower menu"
	for entry in "${show[@]}"; do
		echo -e "${messages[$entry]}\0icon\x1f${icons[$entry]}"
	done
else
	for entry in "${show[@]}"; do
		if [ "$selection" = "$(print_selection "${messages[$entry]}")" ]; then
			for confirmation in "${confirmations[@]}"; do
				if [ "$entry" = "$confirmation" ]; then
					echo -e "\0prompt\x1fAre you sure"
					echo -e "${confirmationMessages[$entry]}\0icon\x1f${icons[$entry]}"
					echo -e "${confirmationMessages[cancel]}\0icon\x1f${icons[cancel]}"
					exit 0
				fi
			done
			selection=$(print_selection "${confirmationMessages[$entry]}")
		fi
		if [ "$selection" = "$(print_selection "${confirmationMessages[$entry]}")" ]; then
			execute_action "$entry"
			exit 0
		fi
		if [ "$selection" = "$(print_selection "${confirmationMessages[cancel]}")" ]; then
			exit 0
		fi
	done
	echo "Invalid selection: $selection" >&2
	exit 1
fi
