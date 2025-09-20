#!/usr/bin/env bash
#═══════════════════════════════════════════════════════════════════════════════
#  ╔═╗╔═╗╦ ╦╔═╗╦═╗  ╔╦╗╔═╗╔╗╔╦ ╦
#  ╠═╝║ ║║║║║╣ ╠╦╝  ║║║║╣ ║║║║ ║
#  ╩  ╚═╝╚╩╝╚═╝╩╚═  ╩ ╩╚═╝╝╚╝╚═╝
#  Hyprland-Friendly Power Menu for Rofi
#  Version: 3.0.0
#  Author: Enhanced Edition
#═══════════════════════════════════════════════════════════════════════════════
set -euo pipefail

#╭──────────────────────────────────────────────────────────────────────────────╮
#│                              CONFIGURATION                                   │
#╰──────────────────────────────────────────────────────────────────────────────╯

# Grace period settings for application shutdown
readonly GRACE_APPS=("brave" "brave-browser" "brave-browser-stable" "firefox" "chromium")
readonly SOFT_TIMEOUT=10
readonly HARD_DELAY=0.5
readonly FIX_BRAVE=true
readonly CLOSE_USER_SESSION=true

# Define available actions
declare -A TEXT ICON CMD COLOR
readonly ALL_ACTIONS=(shutdown reboot suspend hibernate lockscreen logout)

# Action definitions with enhanced icons and colors
TEXT[lockscreen]="Lock Screen"
ICON[lockscreen]="󰍁"
COLOR[lockscreen]="#7aa2f7"
CMD[lockscreen]="hyprlock || swaylock || loginctl lock-session"

TEXT[logout]="Sign Out"
ICON[logout]="󰗼"
COLOR[logout]="#bb9af7"
CMD[logout]="hyprctl dispatch exit || swaymsg exit || loginctl terminate-session ${XDG_SESSION_ID}"

TEXT[suspend]="Sleep"
ICON[suspend]="󰒲"
COLOR[suspend]="#7dcfff"
CMD[suspend]="systemctl suspend -i"

TEXT[hibernate]="Hibernate"
ICON[hibernate]="󰜗"
COLOR[hibernate]="#9ece6a"
CMD[hibernate]="systemctl hibernate"

TEXT[reboot]="Restart"
ICON[reboot]="󰜉"
COLOR[reboot]="#e0af68"
CMD[reboot]="systemctl reboot -i"

TEXT[shutdown]="Shut Down"
ICON[shutdown]="󰐥"
COLOR[shutdown]="#f7768e"
CMD[shutdown]="systemctl poweroff -i"

# Confirmation dialog
ICON[cancel]="󰜺"
COLOR[cancel]="#565f89"
readonly CONFIRM_ACTIONS=(reboot shutdown hibernate)

#╭──────────────────────────────────────────────────────────────────────────────╮
#│                              THEME GENERATION                                │
#╰──────────────────────────────────────────────────────────────────────────────╯

# UI Configuration
: "${POWER_MENU_LINES:=6}"
: "${POWER_MENU_WIDTH_CH:=32}"
: "${POWER_MENU_FONT:=JetBrainsMono Nerd Font 12}"
: "${POWER_MENU_BORDER:=2}"
: "${POWER_MENU_PADDING:=12}"
: "${POWER_MENU_THEME:=modern}" # modern, minimal, glass

_generate_theme() {
	local theme_file
	theme_file="$(mktemp /tmp/power-menu-theme.XXXXXX.rasi)"

	case "${POWER_MENU_THEME}" in
	"glass")
		cat >"$theme_file" <<'EOF'
* {
	font: "JetBrainsMono Nerd Font 12";
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
	font: "JetBrainsMono Nerd Font Bold 12";
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
	font: "Inter 11";
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
	*) # modern (default)
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

#╭──────────────────────────────────────────────────────────────────────────────╮
#│                           AUTO-LAUNCH WITH ROFI                              │
#╰──────────────────────────────────────────────────────────────────────────────╯

if [[ -z "${ROFI_RETV:-}" && -z "${ROFI_INSIDE:-}" ]]; then
	self="$(readlink -f "${BASH_SOURCE[0]}")"
	theme_file="$(_generate_theme)"

	# Clean up theme file on exit
	trap "rm -f '${theme_file}'" EXIT

	exec rofi -show power \
		-modi "power:${self}" \
		-theme "${theme_file}" \
		-show-icons \
		-icon-theme "Papirus" \
		-display-power " Power" \
		-kb-custom-1 "Alt+s" \
		-kb-custom-2 "Alt+r" \
		-kb-custom-3 "Alt+l"
fi

#╭──────────────────────────────────────────────────────────────────────────────╮
#│                            COMMAND LINE INTERFACE                            │
#╰──────────────────────────────────────────────────────────────────────────────╯

DRYRUN=false
SHOW_SYMBOLS=true
SHOW_TEXT=true
SHOW=("${ALL_ACTIONS[@]}")
SYMFONT=""
choose_id=""

usage() {
	cat <<'EOF'
╔═══════════════════════════════════════════════════════════════╗
║                     POWER MENU - ROFI MODULE                 ║
╚═══════════════════════════════════════════════════════════════╝

USAGE:
    power-menu [OPTIONS]

OPTIONS:
    --choices <a/b/c>      Show only specified actions
    --confirm <a/b>        Require confirmation for actions
    --dry-run              Test mode without executing actions
    --symbols              Show icons (default)
    --no-symbols           Hide icons
    --text                 Show text labels (default)
    --no-text              Hide text labels
    --symbols-font <name>  Set icon font
    --choose <id>          Auto-select action
    --theme <name>         Set theme (modern/minimal/glass)
    -h, --help             Show this help message

EXAMPLES:
    power-menu --choices shutdown/reboot/suspend
    power-menu --theme glass
    power-menu --dry-run --choose shutdown

EOF
}

# Parse command line arguments
parsed="$(getopt -o h --long help,dry-run,confirm:,choices:,choose:,symbols,no-symbols,text,no-text,symbols-font:,theme: -- "$@")" || {
	echo "❌ Argument parsing failed"
	exit 1
}

eval set -- "${parsed}"
unset parsed

while true; do
	case "${1}" in
	-h | --help)
		usage
		exit 0
		;;
	--dry-run)
		DRYRUN=true
		shift
		;;
	--confirm)
		IFS=/ read -r -a CONFIRM_ACTIONS <<<"${2}"
		shift 2
		;;
	--choices)
		IFS=/ read -r -a SHOW <<<"${2}"
		shift 2
		;;
	--choose)
		choose_id="${2}"
		shift 2
		;;
	--symbols)
		SHOW_SYMBOLS=true
		shift
		;;
	--no-symbols)
		SHOW_SYMBOLS=false
		shift
		;;
	--text)
		SHOW_TEXT=true
		shift
		;;
	--no-text)
		SHOW_TEXT=false
		shift
		;;
	--symbols-font)
		SYMFONT="${2}"
		shift 2
		;;
	--theme)
		POWER_MENU_THEME="${2}"
		shift 2
		;;
	--)
		shift
		break
		;;
	*)
		echo "❌ Internal argument error"
		exit 1
		;;
	esac
done

# Validate options
$SHOW_SYMBOLS || $SHOW_TEXT || {
	echo "❌ Cannot disable both symbols and text" >&2
	exit 1
}

#╭──────────────────────────────────────────────────────────────────────────────╮
#│                              HELPER FUNCTIONS                                │
#╰──────────────────────────────────────────────────────────────────────────────╯

# Send desktop notification
notify() {
	local title="$1"
	local message="$2"
	local urgency="${3:-normal}"
	local icon="${4:-system-shutdown}"

	if command -v notify-send >/dev/null 2>&1; then
		notify-send -t 3000 -u "$urgency" -i "$icon" "$title" "$message"
	fi
}

# Format menu item with icon and text
format_item() {
	local icon="${1}"
	local text="${2}"
	local color="${3:-}"

	[[ -n "${icon}" ]] || icon=" "

	# Apply font to icon if specified
	local formatted_icon="<span font_size=\"large\">${icon}</span>"
	if [[ -n "${SYMFONT}" ]]; then
		formatted_icon="<span font=\"${SYMFONT}\" font_size=\"large\">${icon}</span>"
	fi

	# Apply color if specified
	if [[ -n "${color}" ]]; then
		formatted_icon="<span foreground=\"${color}\" font_size=\"large\">${icon}</span>"
	fi

	local formatted_text="<span font_size=\"medium\">${text}</span>"

	if $SHOW_SYMBOLS && $SHOW_TEXT; then
		printf "\u200e%s  \u2068%s\u2069" "$formatted_icon" "$formatted_text"
	elif $SHOW_SYMBOLS; then
		printf "%s" "$formatted_icon"
	else
		printf "%s" "$formatted_text"
	fi
}

# Check if selection contains label
contains_label() {
	[[ "$1" == *"$2"* ]]
}

# Gracefully close applications
graceful_shutdown() {
	echo "🔄 Gracefully closing applications..."
	local app alive

	# Send TERM signal to grace apps
	for app in "${GRACE_APPS[@]}"; do
		if pgrep -x "$app" >/dev/null; then
			$DRYRUN || pkill -TERM -x "$app" 2>/dev/null || true
			echo "  📤 Sent TERM signal to $app"
		fi
	done

	# Wait for apps to close gracefully
	for ((i = 0; i < SOFT_TIMEOUT; i++)); do
		sleep 1
		alive=false

		for app in "${GRACE_APPS[@]}"; do
			if pgrep -x "$app" >/dev/null; then
				alive=true
				break
			fi
		done

		$alive || break
		echo -n "  ⏳ Waiting for apps to close... ($((SOFT_TIMEOUT - i))s)"
		echo -ne "\r"
	done

	echo ""

	# Force kill if still running
	for app in "${GRACE_APPS[@]}"; do
		if pgrep -x "$app" >/dev/null; then
			$DRYRUN || pkill -KILL -x "$app" 2>/dev/null || true
			echo "  ⚠️  Force killed $app"
		fi
	done
}

# Fix Brave browser crash flags
fix_brave_flags() {
	$FIX_BRAVE || return 0

	local brave_base="${HOME}/.config/BraveSoftware/Brave-Browser"
	local local_state="${brave_base}/Local State"
	local prefs="${brave_base}/Default/Preferences"

	if $DRYRUN; then
		echo "🔧 [dry-run] Would fix Brave browser flags"
		return 0
	fi

	echo "🔧 Fixing Brave browser flags..."

	if command -v jq >/dev/null 2>&1; then
		# Use jq for proper JSON manipulation
		if [[ -f "$local_state" ]]; then
			jq '.profile.exited_cleanly=true' "$local_state" >"${local_state}.tmp" 2>/dev/null &&
				mv "${local_state}.tmp" "$local_state" &&
				echo "  ✅ Fixed Local State" || true
		fi

		if [[ -f "$prefs" ]]; then
			jq '.profile.exit_type="Normal"' "$prefs" >"${prefs}.tmp" 2>/dev/null &&
				mv "${prefs}.tmp" "$prefs" &&
				echo "  ✅ Fixed Preferences" || true
		fi
	else
		# Fallback to sed
		if [[ -f "$local_state" ]]; then
			sed -i 's/"exited_cleanly":[ ]*false/"exited_cleanly": true/g' "$local_state" &&
				echo "  ✅ Fixed Local State (sed)" || true
		fi

		if [[ -f "$prefs" ]]; then
			sed -i 's/"exit_type":[ ]*"Crashed"/"exit_type":"Normal"/g' "$prefs" &&
				echo "  ✅ Fixed Preferences (sed)" || true
		fi
	fi
}

# Pre-power phase cleanup
pre_power_phase() {
	echo "🚀 Preparing system for power action..."

	# Gracefully close applications
	graceful_shutdown

	# Fix browser flags
	fix_brave_flags

	# Close user session if configured
	if $CLOSE_USER_SESSION; then
		if ! $DRYRUN; then
			echo "  🔒 Closing user session..."
			systemctl --user exit 2>/dev/null || true
			sleep 0.3
		else
			echo "  🔒 [dry-run] Would close user session"
		fi
	fi

	echo "✅ System prepared for power action"
}

# Execute power action
do_action() {
	local action="$1"

	if $DRYRUN; then
		echo "🎯 [DRY-RUN] Selected action: ${action}"
		echo "📝 Would execute: ${CMD[$action]}"
		return 0
	fi

	# Show notification
	notify "Power Menu" "Executing ${TEXT[$action]}..." "normal" "system-${action}"

	# Pre-power phase for critical actions
	case "$action" in
	reboot | shutdown | hibernate)
		pre_power_phase
		;;
	suspend)
		echo "💤 Preparing to suspend..."
		;;
	lockscreen)
		echo "🔒 Locking screen..."
		;;
	logout)
		echo "👋 Logging out..."
		;;
	esac

	# Execute the action
	echo "⚡ Executing: ${CMD[$action]}"
	eval "${CMD[$action]}" &

	# Brief delay before closing rofi
	sleep "$HARD_DELAY"

	# Close rofi
	pkill rofi 2>/dev/null || true
}

#╭──────────────────────────────────────────────────────────────────────────────╮
#│                              ROFI MODE PROTOCOL                              │
#╰──────────────────────────────────────────────────────────────────────────────╯

# Build menu items
declare -A MENU_ITEMS CONFIRM_YES CONFIRM_NO

for action in "${ALL_ACTIONS[@]}"; do
	MENU_ITEMS[$action]="$(format_item "${ICON[$action]}" "${TEXT[$action]}" "${COLOR[$action]}")"
	CONFIRM_YES[$action]="$(format_item "${ICON[$action]}" "Yes, ${TEXT[$action]}" "${COLOR[$action]}")"
done

CONFIRM_NO="$(format_item "${ICON[cancel]}" "No, cancel" "${COLOR[cancel]}")"

# Configure rofi mode
echo -e "\0no-custom\x1ftrue"
echo -e "\0markup-rows\x1ftrue"
echo -e "\0urgent\x1f2,4"

# Get selection from rofi
selection="${*:-}"
if [[ -z "$selection" ]] && ! [ -t 0 ]; then
	selection="$(cat)"
fi

# Handle auto-choose
if [[ -n "$choose_id" && -z "$selection" ]]; then
	do_action "$choose_id"
	exit 0
fi

# Display menu if no selection
if [[ -z "$selection" ]]; then
	echo -e "\0prompt\x1f Power"
	echo -e "\0message\x1fWhat would you like to do?"

	for action in "${SHOW[@]}"; do
		echo -e "${MENU_ITEMS[$action]}\0icon\x1f${ICON[$action]}"
	done
	exit 0
fi

# Handle confirmation
if contains_label "$selection" "Yes,"; then
	for action in "${ALL_ACTIONS[@]}"; do
		if contains_label "$selection" "${TEXT[$action]}"; then
			do_action "$action"
			exit 0
		fi
	done
	echo "❌ Invalid selection: $selection"
	exit 1
fi

# Handle cancel
if contains_label "$selection" "cancel"; then
	exit 0
fi

# Handle action selection
for action in "${SHOW[@]}"; do
	if contains_label "$selection" "${TEXT[$action]}"; then
		# Check if confirmation needed
		for confirm_action in "${CONFIRM_ACTIONS[@]}"; do
			if [[ "$action" == "$confirm_action" ]]; then
				echo -e "\0prompt\x1f Confirm"
				echo -e "\0message\x1fAre you sure you want to ${TEXT[$action]}?"
				echo -e "${CONFIRM_YES[$action]}\0icon\x1f${ICON[$action]}\0urgent\x1ftrue"
				echo -e "${CONFIRM_NO}\0icon\x1f${ICON[cancel]}"
				exit 0
			fi
		done

		# Execute action directly
		do_action "$action"
		exit 0
	fi
done

# Invalid selection
echo "❌ Invalid selection: $selection" >&2
exit 1
