#!/usr/bin/env bash
#═══════════════════════════════════════════════════════════════════════════════
#  ╦═╗╔═╗╔═╗╦  ╦  ╦  ╔═╗╦ ╦╔╗╔╔═╗╦ ╦╔═╗╦═╗
#  ╠╦╝║ ║╠╣ ║  ║  ║  ╠═╣║ ║║║║║  ╠═╣║╣ ╠╦╝
#  ╩╚═╚═╝╚  ╩  ╩═╝╩  ╩ ╩╚═╝╝╚╝╚═╝╩ ╩╚═╝╩╚═
#  Unified Rofi Launcher with Multiple Modes
#  Version: 2.1.0
#═══════════════════════════════════════════════════════════════════════════════
set -euo pipefail

#╭──────────────────────────────────────────────────────────────────────────────╮
#│                              CONFIGURATION                                   │
#╰──────────────────────────────────────────────────────────────────────────────╯

readonly SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/rofi"
readonly THEME_FILE="${CONFIG_DIR}/themes/launcher.rasi"
readonly CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/rofi"

# Create cache directory
mkdir -p "$CACHE_DIR"

# Frecency database
readonly FRECENCY_FILE="$CACHE_DIR/frecency.txt"

# Default mode
MODE="default"

# Command prefixes for custom mode
readonly CMD_PREFIXES=("start-" "gnome-")
readonly CUSTOM_BIN_DIRS=(
	"/etc/profiles/per-user/kenan/bin"
	"$HOME/.local/bin"
	"$HOME/bin"
)

# Hyprland config file
readonly HYPR_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/hypr/hyprland.conf"

#╭──────────────────────────────────────────────────────────────────────────────╮
#│                              HELPER FUNCTIONS                                │
#╰──────────────────────────────────────────────────────────────────────────────╯

has_command() {
	command -v "$1" &>/dev/null
}

notify() {
	local title="$1"
	local message="$2"
	local icon="${3:-dialog-information}"

	if has_command notify-send; then
		notify-send "$title" "$message" -i "$icon" 2>/dev/null || true
	fi
}

frecency_add() {
	local entry="$1"
	[[ -z "$entry" ]] && return 1

	touch "$FRECENCY_FILE"

	local count=$(grep "^${entry}:" "$FRECENCY_FILE" 2>/dev/null | cut -d: -f2 || echo 0)
	count=$((count + 1))

	grep -v "^${entry}:" "$FRECENCY_FILE" >"${FRECENCY_FILE}.tmp" 2>/dev/null || true
	echo "${entry}:${count}" >>"${FRECENCY_FILE}.tmp"
	sort -t: -k2 -nr "${FRECENCY_FILE}.tmp" >"$FRECENCY_FILE"
	rm -f "${FRECENCY_FILE}.tmp"
}

frecency_list() {
	[[ -f "$FRECENCY_FILE" ]] || return 0
	cut -d: -f1 "$FRECENCY_FILE"
}

add_to_frecency() {
	frecency_add "$1"
}

get_theme_param() {
	if [[ -f "$THEME_FILE" ]]; then
		echo "-theme $THEME_FILE"
	fi
}

#╭──────────────────────────────────────────────────────────────────────────────╮
#│                              MODE FUNCTIONS                                  │
#╰──────────────────────────────────────────────────────────────────────────────╯

mode_default() {
	rofi \
		-show combi \
		-combi-modi 'drun,run,window,filebrowser,ssh' \
		-modi "combi,drun,run,window,filebrowser,ssh" \
		-show-icons \
		-matching fuzzy \
		-sort \
		-sorting-method "fzf" \
		-drun-match-fields "name,generic,exec,categories,keywords" \
		-window-match-fields "title,app-id" \
		-drun-display-format "{name} [<span weight='light' size='small'><i>({generic})</i></span>]" \
		$(get_theme_param)
}

mode_apps() {
	rofi \
		-show drun \
		-modi drun \
		-show-icons \
		-matching fuzzy \
		-sort \
		-sorting-method "fzf" \
		-drun-match-fields "name,generic,exec,categories,keywords" \
		-drun-display-format "{name} [<span weight='light' size='small'><i>({generic})</i></span>]" \
		-display-drun "󰀻 Applications" \
		$(get_theme_param)
}

mode_run() {
	rofi \
		-show run \
		-modi run \
		-matching fuzzy \
		-sort \
		-display-run "󰆍 Execute" \
		$(get_theme_param)
}

mode_window() {
	rofi \
		-show window \
		-modi window \
		-show-icons \
		-matching fuzzy \
		-window-match-fields "title,app-id" \
		-display-window "󰖯 Windows" \
		$(get_theme_param)
}

mode_files() {
	rofi \
		-show filebrowser \
		-modi filebrowser \
		-matching fuzzy \
		-display-filebrowser "󰉋 Files" \
		$(get_theme_param)
}

mode_ssh() {
	rofi \
		-show ssh \
		-modi ssh \
		-matching fuzzy \
		-display-ssh "󰢹 SSH" \
		$(get_theme_param)
}

mode_custom() {
	local cache_file="$CACHE_DIR/custom-commands.cache"
	local commands=""
	local debug="${DEBUG:-false}"

	if [[ "$debug" == "true" ]]; then
		echo "=== DEBUG: Custom Commands Mode ===" >&2
		echo "Cache file: $cache_file" >&2
		echo "Prefixes: ${CMD_PREFIXES[*]}" >&2
	fi

	# Check cache (5 minutes)
	if [[ -f "$cache_file" ]]; then
		local cache_age=$(($(date +%s) - $(stat -c%Y "$cache_file" 2>/dev/null || echo 0)))
		if [[ $cache_age -lt 300 ]]; then
			commands=$(cat "$cache_file")
			[[ "$debug" == "true" ]] && echo "Using cached commands" >&2
		fi
	fi

	# Scan if cache is empty or stale
	if [[ -z "$commands" ]]; then
		[[ "$debug" == "true" ]] && echo "Scanning for commands..." >&2

		# Scan custom bin directories
		for bin_dir in "${CUSTOM_BIN_DIRS[@]}"; do
			if [[ -d "$bin_dir" ]]; then
				[[ "$debug" == "true" ]] && echo "Scanning: $bin_dir" >&2

				for prefix in "${CMD_PREFIXES[@]}"; do
					for cmd in "$bin_dir/${prefix}"*; do
						if [[ -f "$cmd" && -x "$cmd" ]]; then
							local cmdname=$(basename "$cmd")
							if ! echo "$commands" | grep -qx "$cmdname"; then
								commands+="$cmdname"$'\n'
								[[ "$debug" == "true" ]] && echo "  Found: $cmdname" >&2
							fi
						fi
					done
				done
			fi
		done

		# Scan PATH
		IFS=':' read -ra PATHS <<<"$PATH"
		for dir in "${PATHS[@]}"; do
			if [[ -d "$dir" ]]; then
				for prefix in "${CMD_PREFIXES[@]}"; do
					for cmd in "$dir/${prefix}"*; do
						if [[ -f "$cmd" && -x "$cmd" ]]; then
							local cmdname=$(basename "$cmd")
							if ! echo "$commands" | grep -qx "$cmdname"; then
								commands+="$cmdname"$'\n'
								[[ "$debug" == "true" ]] && echo "  Found in PATH: $cmdname" >&2
							fi
						fi
					done
				done
			fi
		done

		# Clean and cache
		commands=$(echo "$commands" | sort -u | grep -v '^$')

		if [[ -n "$commands" ]]; then
			echo "$commands" >"$cache_file"
			[[ "$debug" == "true" ]] && echo "Cached $(echo "$commands" | wc -l) commands" >&2
		fi
	fi

	# Apply frecency sorting
	if [[ -n "$commands" ]]; then
		local frecency_items=$(frecency_list)
		if [[ -n "$frecency_items" ]]; then
			[[ "$debug" == "true" ]] && echo "Applying frecency sorting" >&2
			local remaining=$(comm -23 <(echo "$commands" | sort) <(echo "$frecency_items" | sort))
			commands=$(echo -e "$frecency_items\n$remaining" | grep -v '^$')
		fi
	fi

	# Check if found
	if [[ -z "$commands" ]]; then
		echo "No custom commands found matching: ${CMD_PREFIXES[*]}" >&2
		echo "Searched in:" >&2
		for dir in "${CUSTOM_BIN_DIRS[@]}"; do
			if [[ -d "$dir" ]]; then
				echo "  - $dir [EXISTS]" >&2
			else
				echo "  - $dir [NOT FOUND]" >&2
			fi
		done
		echo "  - All PATH directories" >&2
		notify "Rofi Launcher" "No custom commands found (${CMD_PREFIXES[*]})" "dialog-warning"
		return 1
	fi

	# Show in rofi
	echo "$commands" | rofi \
		-dmenu \
		-p "󰘳 Custom Commands" \
		-i \
		-matching fuzzy \
		-sort \
		-no-custom \
		$(get_theme_param)
}

mode_power() {
	local power_script="$SCRIPT_DIR/rofi-power-menu"

	if [[ ! -x "$power_script" ]]; then
		power_script=$(command -v rofi-power-menu 2>/dev/null || echo "")
	fi

	if [[ -x "$power_script" ]]; then
		exec "$power_script"
	else
		notify "Rofi Launcher" "rofi-power-menu script not found" "dialog-error"
		return 1
	fi
}

mode_keys() {
	if [[ ! -f "$HYPR_CONFIG" ]]; then
		notify "Rofi Launcher" "Hyprland config not found: $HYPR_CONFIG" "dialog-error"
		return 1
	fi

	local keybinds=$(grep -oP '(?<=bind=).*' "$HYPR_CONFIG" |
		sed 's/,\([^,]*\)$/ = \1/' |
		sed 's/, exec//g' |
		sed 's/^,//g')

	if [[ -z "$keybinds" ]]; then
		notify "Rofi Launcher" "No keybindings found in config" "dialog-warning"
		return 1
	fi

	echo "$keybinds" | rofi \
		-dmenu \
		-p "⌨ Hyprland Keybindings" \
		-i \
		-matching fuzzy \
		-theme-str 'window {width: 60%;} listview {columns: 1;}' \
		$(get_theme_param)
}

#╭──────────────────────────────────────────────────────────────────────────────╮
#│                            COMMAND LINE INTERFACE                            │
#╰──────────────────────────────────────────────────────────────────────────────╯

usage() {
	cat <<EOF
╔═══════════════════════════════════════════════════════════════╗
║                  ROFI LAUNCHER - UNIFIED INTERFACE           ║
╚═══════════════════════════════════════════════════════════════╝

USAGE:
    $SCRIPT_NAME [MODE]

MODES:
    default, -d, --default       Full launcher (apps, run, windows, files, ssh)
    apps, -a, --apps            Applications only
    run, -r, --run              Run commands
    window, -w, --window        Window switcher
    files, -f, --files          File browser
    ssh, -s, --ssh              SSH connections
    custom, -c, --custom        Custom commands (start-*, gnome-*)
    keys, -k, --keys            Hyprland keybindings
    power, -p, --power          Power menu
    help, -h, --help            Show this help

EXAMPLES:
    $SCRIPT_NAME                # Default mode
    $SCRIPT_NAME apps           # Applications only
    $SCRIPT_NAME custom         # Custom commands
    $SCRIPT_NAME keys           # Show keybindings
    $SCRIPT_NAME -p             # Power menu

ENVIRONMENT:
    DEBUG=true                 Enable debug output for custom mode
    XDG_CONFIG_HOME            Rofi config directory
    XDG_CACHE_HOME             Cache directory

CUSTOM COMMANDS:
    The custom mode searches for executables with these prefixes:
    - start-*
    - gnome-*
    
    Search locations:
    - /etc/profiles/per-user/kenan/bin
    - \$HOME/.local/bin
    - \$HOME/bin
    - All directories in \$PATH

EOF
}

case "${1:-default}" in
default | -d | --default)
	MODE="default"
	;;
apps | -a | --apps)
	MODE="apps"
	;;
run | -r | --run)
	MODE="run"
	;;
window | -w | --window)
	MODE="window"
	;;
files | -f | --files)
	MODE="files"
	;;
ssh | -s | --ssh)
	MODE="ssh"
	;;
custom | -c | --custom)
	MODE="custom"
	;;
keys | -k | --keys)
	MODE="keys"
	;;
power | -p | --power)
	MODE="power"
	;;
help | -h | --help)
	usage
	exit 0
	;;
*)
	echo "ERROR: Unknown mode: $1" >&2
	echo "Run '$SCRIPT_NAME --help' for usage information" >&2
	exit 1
	;;
esac

#╭──────────────────────────────────────────────────────────────────────────────╮
#│                              MAIN EXECUTION                                  │
#╰──────────────────────────────────────────────────────────────────────────────╯

if ! has_command rofi; then
	echo "ERROR: rofi is not installed" >&2
	notify "Rofi Launcher" "rofi is not installed" "dialog-error"
	exit 1
fi

SELECTED=$(mode_${MODE})
exit_code=$?

if [[ $exit_code -ne 0 ]]; then
	exit $exit_code
fi

if [[ -n "$SELECTED" ]]; then
	if [[ "$MODE" == "custom" ]]; then
		add_to_frecency "$SELECTED"
	fi

	eval "$SELECTED" >/dev/null 2>&1 &
	exec_result=$?

	if [[ $exec_result -ne 0 ]]; then
		notify "Rofi Launcher" "Failed to execute: $SELECTED" "dialog-error"
		exit 1
	fi
fi

exit 0
