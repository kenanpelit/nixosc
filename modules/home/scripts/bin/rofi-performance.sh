#!/usr/bin/env bash
# Rofi Power Profile Menu (PPD / powerprofilesctl)

set -euo pipefail

# Script paths (installed via HM scripts module)
PERF_SCRIPT="osc-perf-mode"
ASKPASS_SCRIPT="askpass"

have() { command -v "$1" >/dev/null 2>&1; }

remove_colors() { sed -E 's/\x1B\[[0-9;]*[mK]//g'; }

check_deps() {
	have rofi || {
		echo "rofi not found" >&2
		exit 1
	}
	have powerprofilesctl || {
		rofi -e "powerprofilesctl not found.\n\nEnable power-profiles-daemon / install power-profiles-daemon."
		exit 1
	}
}

get_display_status() {
	if have "$PERF_SCRIPT"; then
		"$PERF_SCRIPT" status 2>/dev/null | remove_colors | head -20
	else
		powerprofilesctl get 2>/dev/null || true
	fi
}

show_notification() {
	local message="$1"
	local status
	status="$(get_display_status)"
	rofi -e "$message\n\n=== Current Status ===\n$status" \
		-theme-str 'window { width: 65%; height: 50%; }' \
		-theme-str 'listview { lines: 15; }'
}

run_sudo() {
	local cmd="$1"
	local message="$2"

	export SUDO_ASKPASS="$ASKPASS_SCRIPT"
	if sudo -A bash -c "$cmd"; then
		show_notification "✅ $message"
	else
		show_notification "❌ Failed: $message"
	fi
}

set_profile() {
	local profile="$1"
	if powerprofilesctl set "$profile" 2>/dev/null; then
		show_notification "Profile set: $profile"
		return 0
	fi

	# Fallback: some setups may require root/polkit tweaks.
	run_sudo "powerprofilesctl set \"$profile\"" "Profile set: $profile"
}

show_main_menu() {
	echo -e "📊 Status\n⚡ Performance\n⚖️ Balanced\n🔋 Power Saver\n🔄 Restart PPD\n❓ Help\n❌ Exit"
}

show_status_detail() {
	local status
	status="$(get_display_status)"
	echo "$status" | rofi -dmenu -p "Power Status" -l 20 \
		-theme-str 'window { width: 75%; height: 60%; }' \
		-theme-str 'entry { enabled: false; }'
}

show_help() {
	local help_text
	if have "$PERF_SCRIPT"; then
		help_text="$("$PERF_SCRIPT" --help 2>/dev/null | remove_colors)"
	else
		help_text="Uses powerprofilesctl to switch between power-saver / balanced / performance."
	fi

	echo "$help_text" | rofi -dmenu -p "Help" -l 15 \
		-theme-str 'window { width: 70%; height: 50%; }' \
		-theme-str 'entry { enabled: false; }'
}

main() {
	check_deps

	while true; do
		choice="$(show_main_menu | rofi -dmenu -p "Power Profiles:" \
			-theme-str '
        window { width: 35%; location: north; anchor: north; y-offset: 50; }
        listview { lines: 7; fixed-height: true; }
        element { padding: 8px; }
      ')"

		[[ -n "${choice:-}" ]] || exit 0

		case "$choice" in
		"📊 Status") show_status_detail ;;
		"⚡ Performance") set_profile performance ;;
		"⚖️ Balanced") set_profile balanced ;;
		"🔋 Power Saver") set_profile power-saver ;;
		"🔄 Restart PPD")
			run_sudo "systemctl restart power-profiles-daemon.service" "power-profiles-daemon restarted"
			;;
		"❓ Help") show_help ;;
		"❌ Exit") exit 0 ;;
		esac

		sleep 0.3
	done
}

trap 'exit 1' INT TERM
main "$@"
