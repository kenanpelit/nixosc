#!/usr/bin/env bash
# Rofi Performance Control Interface for ThinkPad

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script paths - standart path'te oldukları için direk isimleriyle çağırıyoruz
PERF_SCRIPT="osc-perf-mode"
ASKPASS_SCRIPT="askpass" # Askpass scriptini ~/scripts/ altına koyacağız

# Check if performance script exists in PATH
check_script() {
	if ! command -v "$PERF_SCRIPT" &>/dev/null; then
		echo -e "${RED}Performance script not found in PATH: $PERF_SCRIPT${NC}"
		echo "Please ensure perf-control.sh is in one of these directories:"
		echo $PATH | tr ':' '\n'
		exit 1
	fi
}

# Get current status for display
get_display_status() {
	local status
	status=$($PERF_SCRIPT status 2>/dev/null | head -12)
	echo "$status"
}

# Show notification with status
show_notification() {
	local title="$1"
	local message="$2"

	# Get current status for notification
	local status=$(get_display_status)

	# Show notification with rofi
	rofi -e "$message\n\n=== Current Status ===\n$status" \
		-theme-str 'window { width: 65%; height: 50%; }' \
		-theme-str 'listview { lines: 15; }'
}

# Execute command with sudo
run_sudo() {
	local cmd="$1"
	local message="$2"

	export SUDO_ASKPASS="$ASKPASS_SCRIPT"
	if sudo -A bash -c "$cmd"; then
		show_notification "Success" "✅ $message"
	else
		show_notification "Error" "❌ Failed to execute: $message"
	fi
}

# Main rofi menu
show_main_menu() {
	echo -e "📊 System Status\n⚡ Performance Mode\n⚖️ Balanced Mode\n🔋 Power Save Mode\n🎛️ Custom Settings\n🔄 Reset to Default\n❓ Help\n❌ Exit"
}

# Detailed status view
show_status_detail() {
	local status
	status=$($PERF_SCRIPT status)

	# Show in rofi with scrollable view
	echo "$status" | rofi -dmenu -p "System Status" -l 20 \
		-theme-str 'window { width: 75%; height: 60%; }' \
		-theme-str 'entry { enabled: false; }' \
		-theme-str 'element-text { highlight: none; }'
}

# Show help information
show_help() {
	local help_text
	help_text=$($PERF_SCRIPT --help)

	echo "$help_text" | rofi -dmenu -p "Help" -l 15 \
		-theme-str 'window { width: 70%; height: 50%; }' \
		-theme-str 'entry { enabled: false; }'
}

# Custom settings menu
show_custom_menu() {
	echo -e "🚀 Set Governor: Performance\n🐢 Set Governor: Power Save\n⚡ Set Governor: schedutil\n🔥 Enable Turbo Boost\n❄️ Disable Turbo Boost\n📊 Set Power Limits\n🎚️ Set Frequency Limits\n🔧 Toggle auto-cpufreq\n↩️ Back to Main"
}

# Power limits input
set_power_limits() {
	local pl1 pl2

	pl1=$(rofi -dmenu -p "PL1 (Watts):" -theme-str 'entry { placeholder: "e.g., 40 for Meteor Lake"; }')
	pl2=$(rofi -dmenu -p "PL2 (Watts):" -theme-str 'entry { placeholder: "e.g., 55 for Meteor Lake"; }')

	if [[ $pl1 =~ ^[0-9]+$ ]] && [[ $pl2 =~ ^[0-9]+$ ]]; then
		run_sudo "$PERF_SCRIPT custom --pl1 $pl1 --pl2 $pl2" "Power limits set to ${pl1}W/${pl2}W"
	else
		show_notification "Error" "❌ Invalid power values. Please enter numbers only."
	fi
}

# Frequency input
set_frequency() {
	local max_freq min_freq

	max_freq=$(rofi -dmenu -p "Max Frequency:" -theme-str 'entry { placeholder: "e.g., 4.8GHz (leave empty for no limit)"; }')
	min_freq=$(rofi -dmenu -p "Min Frequency:" -theme-str 'entry { placeholder: "e.g., 800MHz (leave empty for no limit)"; }')

	local cmd="$PERF_SCRIPT custom"
	[ -n "$max_freq" ] && cmd+=" --max-freq \"$max_freq\""
	[ -n "$min_freq" ] && cmd+=" --min-freq \"$min_freq\""

	if [ -n "$max_freq" ] || [ -n "$min_freq" ]; then
		run_sudo "$cmd" "Frequency limits updated"
	else
		show_notification "Info" "No frequency limits were set"
	fi
}

# Toggle auto-cpufreq
toggle_auto_cpufreq() {
	if systemctl is-active --quiet auto-cpufreq; then
		run_sudo "systemctl stop auto-cpufreq" "auto-cpufreq stopped"
	else
		run_sudo "systemctl start auto-cpufreq" "auto-cpufreq started"
	fi
}

# Handle menu selection
handle_selection() {
	local choice="$1"

	case "$choice" in
	"📊 System Status")
		show_status_detail
		;;
	"⚡ Performance Mode")
		run_sudo "$PERF_SCRIPT performance" "Performance mode activated 🚀"
		;;
	"⚖️ Balanced Mode")
		run_sudo "$PERF_SCRIPT balanced" "Balanced mode activated ⚖️"
		;;
	"🔋 Power Save Mode")
		run_sudo "$PERF_SCRIPT powersave" "Power save mode activated 🔋"
		;;
	"🎛️ Custom Settings")
		show_custom_submenu
		;;
	"🔄 Reset to Default")
		run_sudo "$PERF_SCRIPT reset" "Reset to default settings 🔄"
		;;
	"❓ Help")
		show_help
		;;
	"❌ Exit")
		exit 0
		;;
	esac
}

# Custom settings submenu
show_custom_submenu() {
	while true; do
		local custom_choice
		custom_choice=$(show_custom_menu | rofi -dmenu -p "Custom Settings:" \
			-theme-str 'listview { lines: 10; }')

		case "$custom_choice" in
		"🚀 Set Governor: Performance")
			run_sudo "$PERF_SCRIPT custom --governor performance" "Governor set to performance 🚀"
			;;
		"🐢 Set Governor: Power Save")
			run_sudo "$PERF_SCRIPT custom --governor powersave" "Governor set to powersave 🐢"
			;;
		"⚡ Set Governor: schedutil")
			run_sudo "$PERF_SCRIPT custom --governor schedutil" "Governor set to schedutil ⚡"
			;;
		"🔥 Enable Turbo Boost")
			run_sudo "$PERF_SCRIPT custom --turbo enable" "Turbo boost enabled 🔥"
			;;
		"❄️ Disable Turbo Boost")
			run_sudo "$PERF_SCRIPT custom --turbo disable" "Turbo boost disabled ❄️"
			;;
		"📊 Set Power Limits")
			set_power_limits
			;;
		"🎚️ Set Frequency Limits")
			set_frequency
			;;
		"🔧 Toggle auto-cpufreq")
			toggle_auto_cpufreq
			;;
		"↩️ Back to Main")
			return
			;;
		*)
			# Exit if user pressed ESC or closed the menu
			return
			;;
		esac

		# Small delay to show notification
		sleep 0.5
	done
}

# Main function
main() {
	# Check if performance script exists
	check_script

	while true; do
		local choice
		choice=$(show_main_menu | rofi -dmenu -p "ThinkPad Performance:" \
			-theme-str '
                window {
                    width: 35%;
                    location: north;
                    anchor: north;
                    y-offset: 50;
                }
                listview {
                    lines: 9;
                    fixed-height: true;
                }
                element selected {
                    background-color: #2e3440;
                    text-color: #88c0d0;
                }
                element {
                    padding: 8px;
                }
            ')

		if [ -z "$choice" ]; then
			exit 0
		fi

		handle_selection "$choice"
	done
}

# Handle script interrupts
trap 'echo -e "${RED}Script interrupted.${NC}"; exit 1' INT TERM

# Run main function
main "$@"
