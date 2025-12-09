#!/usr/bin/env bash
#═══════════════════════════════════════════════════════════════════════════════
#  ╦═╗╔═╗╔═╗╦  ╦  ╦  ╔═╗╦ ╦╔╗╔╔═╗╦ ╦╔═╗╦═╗
#  ╠╦╝║ ║╠╣ ║  ║  ║  ╠═╣║ ║║║║║  ╠═╣║╣ ╠╦╝
#  ╩╚═╚═╝╚  ╩  ╩═╝╩  ╩ ╩╚═╝╝╚╝╚═╝╩ ╩╚═╝╩╚═
#  Unified Rofi Launcher with Power Menu Integration
#  Version: 3.0.0
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
readonly CMD_PREFIXES=("start-")
readonly CUSTOM_BIN_DIRS=(
	"/etc/profiles/per-user/${USER:-kenan}/bin"
	"$HOME/.local/bin"
	"$HOME/bin"
)

# Hyprland config file
readonly HYPR_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/hypr/hyprland.conf"

#╭──────────────────────────────────────────────────────────────────────────────╮
#│                      POWER MENU CONFIGURATION                                │
#╰──────────────────────────────────────────────────────────────────────────────╯

# Graceful shutdown configuration
readonly GRACE_BROWSERS=("brave" "brave-browser" "firefox" "chromium" "google-chrome" "opera")
readonly GRACE_APPS=("code" "codium" "discord" "slack" "telegram-desktop")
readonly ALL_GRACE_APPS=("${GRACE_BROWSERS[@]}" "${GRACE_APPS[@]}")

# Timing configuration
: "${SOFT_TIMEOUT:=15}"
: "${HARD_DELAY:=0.5}"
: "${ACTION_DELAY:=0.3}"

# Feature flags
: "${FIX_BROWSERS:=true}"
: "${CLOSE_USER_SESSION:=true}"
: "${ENABLE_NOTIFICATIONS:=true}"

# Define available power actions
declare -A POWER_TEXT POWER_ICON POWER_CMD POWER_COLOR
readonly ALL_POWER_ACTIONS=(lockscreen logout suspend hibernate reboot shutdown)

# Power action definitions with Nerd Font icons
POWER_TEXT[reboot]="Restart"
POWER_ICON[reboot]="󰜉"
POWER_COLOR[reboot]="#e0af68"
POWER_CMD[reboot]="systemctl reboot -i"

POWER_TEXT[lockscreen]="Lock Screen"
POWER_ICON[lockscreen]="󰍁"
POWER_COLOR[lockscreen]="#7aa2f7"
POWER_CMD[lockscreen]="hyprlock || swaylock || loginctl lock-session"

POWER_TEXT[logout]="Sign Out"
POWER_ICON[logout]="󰗼"
POWER_COLOR[logout]="#bb9af7"
POWER_CMD[logout]="hyprctl dispatch exit || swaymsg exit || loginctl terminate-session \${XDG_SESSION_ID:-}"

POWER_TEXT[suspend]="Sleep"
POWER_ICON[suspend]="󰒲"
POWER_COLOR[suspend]="#7dcfff"
POWER_CMD[suspend]="systemctl suspend -i"

POWER_TEXT[hibernate]="Hibernate"
POWER_ICON[hibernate]="󰜗"
POWER_COLOR[hibernate]="#9ece6a"
POWER_CMD[hibernate]="systemctl hibernate -i"

POWER_TEXT[shutdown]="Shut Down"
POWER_ICON[shutdown]="󰐥"
POWER_COLOR[shutdown]="#f7768e"
POWER_CMD[shutdown]="systemctl poweroff -i"

POWER_ICON[cancel]="󰍃"
POWER_COLOR[cancel]="#565f89"

# Confirmation and cancel
readonly POWER_CONFIRM_ACTIONS=(reboot shutdown hibernate)

# Power menu theme configuration
: "${POWER_MENU_LINES:=6}"
: "${POWER_MENU_WIDTH_CH:=32}"
: "${POWER_MENU_FONT:=Maple Mono NF 12}"
: "${POWER_MENU_BORDER:=2}"
: "${POWER_MENU_PADDING:=12}"
: "${POWER_MENU_THEME:=modern}"

readonly THEME_CACHE_DIR="${CACHE_DIR}/power-menu-themes"
readonly POWER_THEME_FILE="${THEME_CACHE_DIR}/theme-${POWER_MENU_THEME}.rasi"
mkdir -p "$THEME_CACHE_DIR"

# Power menu options
POWER_DRYRUN=false
POWER_SHOW_SYMBOLS=true
POWER_SHOW_TEXT=true
POWER_SHOW=("${ALL_POWER_ACTIONS[@]}")
POWER_SYMFONT=""
POWER_CHOOSE_ID=""

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
#│                        POWER MENU HELPER FUNCTIONS                           │
#╰──────────────────────────────────────────────────────────────────────────────╯

power_notify() {
	$ENABLE_NOTIFICATIONS || return 0

	local title="$1"
	local message="$2"
	local urgency="${3:-normal}"
	local icon="${4:-system-shutdown}"

	if has_command notify-send; then
		notify-send -t 3000 -u "$urgency" -i "$icon" "$title" "$message" 2>/dev/null || true
	fi
}

graceful_shutdown() {
	local app alive apps_found=()

	for app in "${ALL_GRACE_APPS[@]}"; do
		if pgrep -x "$app" >/dev/null 2>&1; then
			apps_found+=("$app")
		fi
	done

	[[ ${#apps_found[@]} -eq 0 ]] && return 0

	echo "Gracefully closing applications: ${apps_found[*]}"

	for app in "${apps_found[@]}"; do
		pkill -TERM -x "$app" 2>/dev/null || true
	done

	for ((i = 0; i < SOFT_TIMEOUT; i++)); do
		sleep 1
		alive=false

		for app in "${apps_found[@]}"; do
			if pgrep -x "$app" >/dev/null 2>&1; then
				alive=true
				break
			fi
		done

		$alive || break
	done

	for app in "${apps_found[@]}"; do
		if pgrep -x "$app" >/dev/null 2>&1; then
			pkill -KILL -x "$app" 2>/dev/null || true
			echo "Force killed: $app"
		fi
	done
}

fix_browser_flags() {
	$FIX_BROWSERS || return 0

	local browser_configs=(
		"$HOME/.config/BraveSoftware/Brave-Browser"
		"$HOME/.config/google-chrome"
		"$HOME/.config/chromium"
		"$HOME/.mozilla/firefox"
	)

	local config fixed=false

	for config in "${browser_configs[@]}"; do
		[[ -d "$config" ]] || continue

		local local_state="$config/Local State"
		local prefs="$config/Default/Preferences"

		if [[ -f "$local_state" ]]; then
			if has_command jq; then
				jq '.profile.exited_cleanly=true' "$local_state" >"${local_state}.tmp" 2>/dev/null &&
					mv "${local_state}.tmp" "$local_state" && fixed=true
			else
				sed -i 's/"exited_cleanly":[[:space:]]*false/"exited_cleanly": true/g' "$local_state" 2>/dev/null && fixed=true
			fi
		fi

		if [[ -f "$prefs" ]]; then
			if has_command jq; then
				jq '.profile.exit_type="Normal"' "$prefs" >"${prefs}.tmp" 2>/dev/null &&
					mv "${prefs}.tmp" "$prefs" && fixed=true
			else
				sed -i 's/"exit_type":[[:space:]]*"Crashed"/"exit_type":"Normal"/g' "$prefs" 2>/dev/null && fixed=true
			fi
		fi
	done

	$fixed && echo "Browser crash flags fixed"
}

pre_power_phase() {
	local action="$1"

	echo "Preparing system for ${POWER_TEXT[$action]}..."

	graceful_shutdown
	fix_browser_flags

	if $CLOSE_USER_SESSION; then
		systemctl --user exit 2>/dev/null || true
		sleep "$ACTION_DELAY"
	fi

	echo "System ready for ${POWER_TEXT[$action]}"
}

do_power_action() {
	local action="$1"

	if $POWER_DRYRUN; then
		echo "[DRY-RUN] Selected: ${POWER_TEXT[$action]}"
		echo "[DRY-RUN] Command: ${POWER_CMD[$action]}"
		return 0
	fi

	power_notify "Power Menu" "${POWER_TEXT[$action]}..." "normal" "system-${action}"

	case "$action" in
	reboot | shutdown | hibernate)
		pre_power_phase "$action"
		;;
	esac

	echo "Executing: ${POWER_CMD[$action]}"

	local expanded_cmd
	expanded_cmd=$(eval echo "${POWER_CMD[$action]}")

	if eval "$expanded_cmd" 2>/dev/null; then
		sleep "$HARD_DELAY"
		pkill rofi 2>/dev/null || true
	else
		echo "ERROR: Power action failed: $action" >&2
		power_notify "Power Menu Error" "Failed to ${POWER_TEXT[$action]}" "critical" "dialog-error"
		return 1
	fi
}

generate_power_theme() {
	local theme_file="${1:-$POWER_THEME_FILE}"

	mkdir -p "$(dirname "$theme_file")"

	case "${POWER_MENU_THEME}" in
	"glass")
		cat >"$theme_file" <<'EOF'
* {
	font: "Maple Mono NF 12";
	background: rgba(26, 27, 38, 0.85);
	background-alt: rgba(26, 27, 38, 0.95);
	foreground: #c0caf5;
	selected: rgba(122, 162, 247, 0.15);
	active: #7aa2f7;
	urgent: #f7768e;
}

window {
	transparency: "real";
	background-color: @background;
	text-color: @foreground;
	width: 420px;
	padding: 20px;
	border: 2px solid;
	border-color: rgba(122, 162, 247, 0.3);
	border-radius: 16px;
	location: center;
	anchor: center;
}

mainbox {
	background-color: transparent;
	children: [ inputbar, listview ];
	spacing: 15px;
}

inputbar {
	background-color: rgba(26, 27, 38, 0.6);
	text-color: @foreground;
	padding: 12px 16px;
	border-radius: 12px;
	children: [ prompt, entry ];
	spacing: 10px;
}

prompt {
	background-color: transparent;
	text-color: @active;
	font: "Maple Mono NF Bold 12";
}

entry {
	background-color: transparent;
	text-color: @foreground;
	placeholder: "Select action...";
	placeholder-color: rgba(192, 202, 245, 0.5);
}

listview {
	background-color: transparent;
	columns: 2;
	lines: 3;
	spacing: 12px;
	cycle: true;
	dynamic: true;
	layout: vertical;
	fixed-columns: true;
}

element {
	background-color: rgba(26, 27, 38, 0.6);
	text-color: @foreground;
	padding: 16px;
	border-radius: 12px;
	orientation: horizontal;
	spacing: 12px;
}

element-icon {
	background-color: transparent;
	size: 24px;
	text-color: inherit;
}

element-text {
	background-color: transparent;
	text-color: inherit;
	vertical-align: 0.5;
	horizontal-align: 0.0;
	expand: true;
}

element selected {
	background-color: @selected;
	text-color: @active;
	border: 2px solid;
	border-color: @active;
}

element.urgent {
	background-color: rgba(247, 118, 142, 0.1);
	text-color: @urgent;
	border-color: @urgent;
}
EOF
		;;
	"minimal")
		cat >"$theme_file" <<'EOF'
* {
	font: "Maple Mono NF 11";
	background: #ffffff;
	background-alt: #f5f5f5;
	foreground: #333333;
	selected: #e3f2fd;
	active: #2196f3;
	urgent: #f44336;
}

window {
	background-color: @background;
	text-color: @foreground;
	width: 360px;
	padding: 0;
	border: 1px solid #e0e0e0;
	border-radius: 8px;
}

mainbox {
	background-color: transparent;
	children: [ listview ];
	padding: 8px;
}

listview {
	background-color: transparent;
	columns: 1;
	lines: 6;
	spacing: 4px;
	cycle: true;
	dynamic: true;
}

element {
	background-color: transparent;
	text-color: @foreground;
	padding: 12px 16px;
	border-radius: 6px;
}

element-text {
	background-color: transparent;
	text-color: inherit;
	vertical-align: 0.5;
}

element selected {
	background-color: @selected;
	text-color: @active;
}

element.urgent {
	text-color: @urgent;
}
EOF
		;;
	"catppuccin")
		cat >"$theme_file" <<'EOF'
* {
	font: "Maple Mono NF 12";
	bg0: #1e1e2e;
	bg1: #313244;
	fg0: #cdd6f4;
	fg1: #a6adc8;
	accent: #89b4fa;
	urgent: #f38ba8;
	selected: rgba(137, 180, 250, 0.18);
}

window {
	background-color: @bg0;
	text-color: @fg0;
	width: 420px;
	padding: 16px;
	border: 2px solid @accent;
	border-radius: 14px;
	location: center;
	anchor: center;
}

mainbox {
	background-color: transparent;
	children: [ inputbar, listview ];
	spacing: 12px;
}

inputbar {
	background-color: @bg1;
	text-color: @fg0;
	padding: 10px 14px;
	border-radius: 10px;
	children: [ prompt, entry ];
	spacing: 8px;
}

prompt {
	background-color: transparent;
	text-color: @accent;
	font: "Maple Mono NF Bold 12";
}

entry {
	background-color: transparent;
	text-color: @fg0;
	placeholder: "Type to filter...";
	placeholder-color: @fg1;
}

listview {
	background-color: transparent;
	columns: 1;
	lines: 6;
	spacing: 8px;
	cycle: true;
	dynamic: true;
	scrollbar: false;
}

element {
	background-color: @bg1;
	text-color: @fg0;
	padding: 12px;
	border-radius: 10px;
	orientation: horizontal;
	spacing: 12px;
}

element-icon {
	background-color: transparent;
	size: 20px;
	text-color: inherit;
}

element-text {
	background-color: transparent;
	text-color: inherit;
	vertical-align: 0.5;
	horizontal-align: 0.0;
}

element selected {
	background-color: @selected;
	text-color: @accent;
	border: 1px solid @accent;
}

element.urgent {
	background-color: rgba(243, 139, 168, 0.12);
	text-color: @urgent;
	border: 1px solid @urgent;
}
EOF
		;;
	*)
		cat >"$theme_file" <<EOF
* {
	font: "${POWER_MENU_FONT}";
	bg0: #1a1b26;
	bg1: #24283b;
	bg2: #414868;
	fg0: #c0caf5;
	fg1: #a9b1d6;
	accent: #7aa2f7;
	urgent: #f7768e;
	selected: rgba(122, 162, 247, 0.2);
}

window {
	background-color: @bg0;
	text-color: @fg0;
	width: ${POWER_MENU_WIDTH_CH}ch;
	padding: ${POWER_MENU_PADDING}px;
	border: ${POWER_MENU_BORDER}px solid;
	border-color: @accent;
	border-radius: 12px;
	location: center;
	anchor: center;
}

mainbox {
	background-color: transparent;
	children: [ inputbar, message, listview ];
	spacing: 12px;
}

inputbar {
	background-color: @bg1;
	text-color: @fg0;
	padding: 10px 14px;
	border-radius: 8px;
	children: [ prompt, entry ];
	spacing: 10px;
}

prompt {
	background-color: transparent;
	text-color: @accent;
	font: "${POWER_MENU_FONT} Bold";
}

entry {
	background-color: transparent;
	text-color: @fg0;
	placeholder: "Type to filter...";
	placeholder-color: @fg1;
}

message {
	background-color: @bg1;
	padding: 10px;
	border-radius: 8px;
}

listview {
	background-color: transparent;
	columns: 1;
	lines: ${POWER_MENU_LINES};
	spacing: 8px;
	cycle: true;
	dynamic: true;
	scrollbar: false;
}

element {
	background-color: @bg1;
	text-color: @fg0;
	padding: 12px 14px;
	border-radius: 8px;
	orientation: horizontal;
	spacing: 12px;
}

element-icon {
	background-color: transparent;
	size: 20px;
	text-color: inherit;
}

element-text {
	background-color: transparent;
	text-color: inherit;
	vertical-align: 0.5;
	horizontal-align: 0.0;
}

element selected {
	background-color: @selected;
	text-color: @accent;
	border: 1px solid;
	border-color: @accent;
}

element alternate {
	background-color: transparent;
}

element.urgent {
	background-color: rgba(247, 118, 142, 0.1);
	text-color: @urgent;
}
EOF
		;;
	esac

	echo "$theme_file"
}

# Format power menu item with icon and text
power_format_item() {
	local icon="${1}"
	local text="${2}"
	local color="${3:-}"

	[[ -n "${icon}" ]] || icon=" "

	local formatted_icon="<span font_size=\"large\">${icon}</span>"
	if [[ -n "${POWER_SYMFONT}" ]]; then
		formatted_icon="<span font=\"${POWER_SYMFONT}\" font_size=\"large\">${icon}</span>"
	fi

	if [[ -n "${color}" ]]; then
		formatted_icon="<span foreground=\"${color}\" font_size=\"large\">${icon}</span>"
	fi

	local formatted_text="<span font_size=\"medium\">${text}</span>"

	if $POWER_SHOW_SYMBOLS && $POWER_SHOW_TEXT; then
		printf "\u200e%s  \u2068%s\u2069" "$formatted_icon" "$formatted_text"
	elif $POWER_SHOW_SYMBOLS; then
		printf "%s" "$formatted_icon"
	else
		printf "%s" "$formatted_text"
	fi
}

# Check if selection contains label
power_contains_label() {
	[[ "$1" == *"$2"* ]]
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

	if [[ -f "$cache_file" ]]; then
		local cache_age=$(($(date +%s) - $(stat -c%Y "$cache_file" 2>/dev/null || echo 0)))
		if [[ $cache_age -lt 300 ]]; then
			commands=$(cat "$cache_file")
			[[ "$debug" == "true" ]] && echo "Using cached commands" >&2
		fi
	fi

	if [[ -z "$commands" ]]; then
		[[ "$debug" == "true" ]] && echo "Scanning for commands..." >&2

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

		commands=$(echo "$commands" | sort -u | grep -v '^$')

		if [[ -n "$commands" ]]; then
			echo "$commands" >"$cache_file"
			[[ "$debug" == "true" ]] && echo "Cached $(echo "$commands" | wc -l) commands" >&2
		fi
	fi

	if [[ -n "$commands" ]]; then
		local frecency_items=$(frecency_list)
		if [[ -n "$frecency_items" ]]; then
			[[ "$debug" == "true" ]] && echo "Applying frecency sorting" >&2
			local remaining=$(comm -23 <(echo "$commands" | sort) <(echo "$frecency_items" | sort))
			commands=$(echo -e "$frecency_items\n$remaining" | grep -v '^$')
		fi
	fi

	if [[ -z "$commands" ]]; then
		echo "No custom commands found matching: ${CMD_PREFIXES[*]}" >&2
		notify "Rofi Launcher" "No custom commands found (${CMD_PREFIXES[*]})" "dialog-warning"
		return 1
	fi

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
	# Check if being called as rofi mode (from rofi itself)
	if [[ -n "${ROFI_RETV:-}" || -n "${ROFI_INSIDE:-}" ]]; then
		power_menu_rofi_mode
		return $?
	fi

	# Generate theme if needed
	[[ ! -f "$POWER_THEME_FILE" ]] && generate_power_theme

	# Launch as rofi mode
	local self="$(readlink -f "${BASH_SOURCE[0]}")"
	exec rofi -show power \
		-modi "power:${self} --power-mode-internal" \
		-theme "${POWER_THEME_FILE}" \
		-show-icons \
		-icon-theme "Papirus" \
		-display-power "󰐥 Power" \
		-kb-custom-1 "Alt+s" \
		-kb-custom-2 "Alt+r" \
		-kb-custom-3 "Alt+l"
}

# Rofi mode protocol handler for power menu
power_menu_rofi_mode() {
	# Build menu items
	declare -A MENU_ITEMS CONFIRM_YES
	for action in "${ALL_POWER_ACTIONS[@]}"; do
		MENU_ITEMS[$action]="$(power_format_item "${POWER_ICON[$action]}" "${POWER_TEXT[$action]}" "${POWER_COLOR[$action]}")"
		CONFIRM_YES[$action]="$(power_format_item "${POWER_ICON[$action]}" "Yes, ${POWER_TEXT[$action]}" "${POWER_COLOR[$action]}")"
	done
	CONFIRM_NO="$(power_format_item "${POWER_ICON[cancel]}" "No, cancel" "${POWER_COLOR[cancel]}")"

	# Configure rofi mode
	echo -e "\0no-custom\x1ftrue"
	echo -e "\0markup-rows\x1ftrue"
	echo -e "\0urgent\x1f2,4"

	# Get selection
	local selection="${*:-}"
	[[ -z "$selection" ]] && ! [ -t 0 ] && selection="$(cat)"

	# Handle auto-choose
	if [[ -n "$POWER_CHOOSE_ID" && -z "$selection" ]]; then
		do_power_action "$POWER_CHOOSE_ID"
		exit $?
	fi

	# Display initial menu
	if [[ -z "$selection" ]]; then
		echo -e "\0prompt\x1f󰐥 Power"
		echo -e "\0message\x1fWhat would you like to do?"

		for action in "${POWER_SHOW[@]}"; do
			echo -e "${MENU_ITEMS[$action]}\0icon\x1f${POWER_ICON[$action]}"
		done
		exit 0
	fi

	# Handle confirmation response
	if power_contains_label "$selection" "Yes,"; then
		for action in "${ALL_POWER_ACTIONS[@]}"; do
			if power_contains_label "$selection" "${POWER_TEXT[$action]}"; then
				do_power_action "$action"
				exit $?
			fi
		done
		exit 1
	fi

	# Handle cancel
	power_contains_label "$selection" "cancel" && exit 0

	# Handle action selection
	for action in "${POWER_SHOW[@]}"; do
		if power_contains_label "$selection" "${POWER_TEXT[$action]}"; then
			# Check if confirmation needed
			for confirm_action in "${POWER_CONFIRM_ACTIONS[@]}"; do
				if [[ "$action" == "$confirm_action" ]]; then
					echo -e "\0prompt\x1f󰀪 Confirm"
					echo -e "\0message\x1fAre you sure you want to ${POWER_TEXT[$action]}?"
					echo -e "${CONFIRM_YES[$action]}\0icon\x1f${POWER_ICON[$action]}\0urgent\x1ftrue"
					echo -e "${CONFIRM_NO}\0icon\x1f${POWER_ICON[cancel]}"
					exit 0
				fi
			done

			# Execute directly
			do_power_action "$action"
			exit $?
		fi
	done

	# Invalid selection
	echo "ERROR: Invalid selection: $selection" >&2
	exit 1
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
    $SCRIPT_NAME [MODE] [OPTIONS]

MODES:
    default, -d, --default       Full launcher (apps, run, windows, files, ssh)
    apps, -a, --apps            Applications only
    run, -r, --run              Run commands
    window, -w, --window        Window switcher
    files, -f, --files          File browser
    ssh, -s, --ssh              SSH connections
    custom, -c, --custom        Custom commands (start-*)
    keys, -k, --keys            Hyprland keybindings
    power, -p, --power          Power menu (full featured)
    help, -h, --help            Show this help

POWER MENU OPTIONS:
    --power-choices <a/b/c>     Show only specified power actions
    --power-confirm <a/b>       Require confirmation for actions
    --power-dry-run             Test mode without executing
    --power-symbols             Show icons (default)
    --power-no-symbols          Hide icons
    --power-text                Show text labels (default)
    --power-no-text             Hide text labels
    --power-symbols-font <name> Set icon font
    --power-choose <id>         Auto-select power action
    --power-theme <name>        Set theme (modern/minimal/glass)
    --power-regen-theme         Regenerate theme cache

EXAMPLES:
    $SCRIPT_NAME                         # Default mode
    $SCRIPT_NAME apps                    # Applications only
    $SCRIPT_NAME custom                  # Custom commands
    $SCRIPT_NAME power                   # Full power menu
    $SCRIPT_NAME power --power-dry-run   # Test power menu
    $SCRIPT_NAME power --power-choices shutdown/reboot/suspend
    $SCRIPT_NAME power --power-theme glass --power-regen-theme
    $SCRIPT_NAME -k                      # Show keybindings

ENVIRONMENT:
    DEBUG=true                 Enable debug output for custom mode
    XDG_CONFIG_HOME            Rofi config directory
    XDG_CACHE_HOME             Cache directory

POWER MENU ENVIRONMENT:
    SOFT_TIMEOUT=15            Graceful shutdown timeout (seconds)
    HARD_DELAY=0.5             Force kill delay (seconds)
    ACTION_DELAY=0.3           Delay before executing action
    FIX_BROWSERS=true          Fix browser crash flags
    CLOSE_USER_SESSION=true    Close systemd user session
    ENABLE_NOTIFICATIONS=true  Show desktop notifications
    POWER_MENU_THEME=modern    Theme (modern/minimal/glass)
    POWER_MENU_FONT=...        Custom font for power menu

CUSTOM COMMANDS:
    Search locations:
    - /etc/profiles/per-user/kenan/bin
    - \$HOME/.local/bin
    - \$HOME/bin
    - All directories in \$PATH


HOME                           Rofi config directory
    XDG_CACHE_HOME             Cache directory

POWER MENU ENVIRONMENT:
    SOFT_TIMEOUT=15            Graceful shutdown timeout (seconds)
    FIX_BROWSERS=true          Fix browser crash flags
    CLOSE_USER_SESSION=true    Close systemd user session
    ENABLE_NOTIFICATIONS=true  Show desktop notifications

CUSTOM COMMANDS:
    Search locations:
    - /etc/profiles/per-user/${USER:-kenan}/bin
    - \$HOME/.local/bin
    - \$HOME/bin
    - All directories in \$PATH

EOF
}

# Parse command line arguments
parsed_args=()
power_mode_internal=false

while [[ $# -gt 0 ]]; do
	case "${1}" in
	# Power menu internal mode flag (for rofi mode protocol)
	--power-mode-internal)
		power_mode_internal=true
		MODE="power"
		shift
		;;
	# Power menu specific options
	--power-dry-run)
		POWER_DRYRUN=true
		shift
		;;
	--power-confirm)
		IFS=/ read -r -a POWER_CONFIRM_ACTIONS <<<"${2}"
		shift 2
		;;
	--power-choices)
		IFS=/ read -r -a POWER_SHOW <<<"${2}"
		shift 2
		;;
	--power-choose)
		POWER_CHOOSE_ID="${2}"
		shift 2
		;;
	--power-symbols)
		POWER_SHOW_SYMBOLS=true
		shift
		;;
	--power-no-symbols)
		POWER_SHOW_SYMBOLS=false
		shift
		;;
	--power-text)
		POWER_SHOW_TEXT=true
		shift
		;;
	--power-no-text)
		POWER_SHOW_TEXT=false
		shift
		;;
	--power-symbols-font)
		POWER_SYMFONT="${2}"
		shift 2
		;;
	--power-theme)
		POWER_MENU_THEME="${2}"
		shift 2
		;;
	--power-regen-theme)
		rm -f "${THEME_CACHE_DIR}/"*.rasi 2>/dev/null || true
		shift
		;;
	# Standard modes
	default | -d | --default)
		MODE="default"
		shift
		;;
	apps | -a | --apps)
		MODE="apps"
		shift
		;;
	run | -r | --run)
		MODE="run"
		shift
		;;
	window | -w | --window)
		MODE="window"
		shift
		;;
	files | -f | --files)
		MODE="files"
		shift
		;;
	ssh | -s | --ssh)
		MODE="ssh"
		shift
		;;
	custom | -c | --custom)
		MODE="custom"
		shift
		;;
	keys | -k | --keys)
		MODE="keys"
		shift
		;;
	power | -p | --power)
		MODE="power"
		shift
		;;
	help | -h | --help)
		usage
		exit 0
		;;
	*)
		if [[ -z "$MODE" ]]; then
			echo "ERROR: Unknown mode: $1" >&2
			echo "Run '$SCRIPT_NAME --help' for usage information" >&2
			exit 1
		else
			parsed_args+=("$1")
			shift
		fi
		;;
	esac
done

# Validate power menu options
if [[ "$MODE" == "power" ]]; then
	$POWER_SHOW_SYMBOLS || $POWER_SHOW_TEXT || {
		echo "ERROR: Cannot disable both symbols and text in power menu" >&2
		exit 1
	}
fi

#╭──────────────────────────────────────────────────────────────────────────────╮
#│                              MAIN EXECUTION                                  │
#╰──────────────────────────────────────────────────────────────────────────────╯

# If power mode internal (rofi mode protocol), run it directly
if $power_mode_internal; then
	power_menu_rofi_mode "${parsed_args[@]}"
	exit $?
fi

if ! has_command rofi; then
	echo "ERROR: rofi is not installed" >&2
	notify "Rofi Launcher" "rofi is not installed" "dialog-error"
	exit 1
fi

# Special handling for power mode
if [[ "$MODE" == "power" ]]; then
	mode_power
	exit $?
fi

# Execute the selected mode
SELECTED=$(mode_${MODE})
exit_code=$?

if [[ $exit_code -ne 0 ]]; then
	exit $exit_code
fi

# Handle command execution for non-power modes
if [[ -n "$SELECTED" ]]; then
	if [[ "$MODE" == "custom" ]]; then
		add_to_frecency "$SELECTED"
	fi

	if has_command "$SELECTED"; then
		"$SELECTED" >/dev/null 2>&1 &
		exec_result=$?
	else
		eval "$SELECTED" >/dev/null 2>&1 &
		exec_result=$?
	fi

	if [[ $exec_result -ne 0 ]]; then
		notify "Rofi Launcher" "Failed to execute: $SELECTED" "dialog-error"
		exit 1
	fi
fi

exit 0
