#!/usr/bin/env bash
#===============================================================================
#  Hyprland-Friendly Power Menu for Rofi (standalone + script modi)
#  Version: 2.6.1
#===============================================================================
set -euo pipefail

#------------------------------- Ayarlar ---------------------------------------
GRACE_APPS=("brave" "brave-browser" "brave-browser-stable")
SOFT_TIMEOUT=10
HARD_DELAY=0.5
FIX_BRAVE=true
CLOSE_USER_SESSION=true

declare -A TEXT ICON CMD
ALL=(shutdown reboot suspend hibernate lockscreen logout)

TEXT[lockscreen]="Lock"
ICON[lockscreen]="\Uf033e"
CMD[lockscreen]="hyprlock || swaylock"
TEXT[logout]="Logout"
ICON[logout]="\Uf0343"
CMD[logout]="hyprctl dispatch exit || swaymsg exit || true"
TEXT[suspend]="Suspend"
ICON[suspend]="\Uf04b2"
CMD[suspend]="systemctl suspend -i"
TEXT[hibernate]="Hibernate"
ICON[hibernate]="\Uf02ca"
CMD[hibernate]="systemctl hibernate"
TEXT[reboot]="Reboot"
ICON[reboot]="\Uf0709"
CMD[reboot]="systemctl reboot -i"
TEXT[shutdown]="Shutdown"
ICON[shutdown]="\Uf0425"
CMD[shutdown]="systemctl poweroff -i"
ICON[cancel]="\Uf0156"
CONFIRM=(reboot shutdown hibernate)

#----------------------------- Kompakt tema üretimi ----------------------------
: "${POWER_MENU_LINES:=8}"
: "${POWER_MENU_WIDTH_CH:=28}"
: "${POWER_MENU_FONT:=}" # örn: "JetBrainsMono Nerd Font 11"
: "${POWER_MENU_BORDER:=2}"
: "${POWER_MENU_PADDING:=8}"

_write_theme_file() {
	local tf
	tf="$(mktemp /tmp/power-menu-theme.XXXXXX.rasi)"
	{
		# Font bloğu (boşsa yazma)
		if [[ -n "${POWER_MENU_FONT}" ]]; then
			printf '* { font: "%s"; }\n' "${POWER_MENU_FONT}"
		fi
		cat <<EOF
window {
  width: ${POWER_MENU_WIDTH_CH}ch;
  padding: ${POWER_MENU_PADDING}px;
  border: ${POWER_MENU_BORDER}px;
  border-radius: 6px;
  border-color: #b4befe;
}
mainbox { children: [ inputbar, listview ]; }
listview { columns: 1; lines: ${POWER_MENU_LINES}; spacing: 6px; fixed-height: false; }
element { padding: 6px 8px; }
element selected {
  background-color: rgba(180,190,254,0.12);
  border: 1px;
  border-color: rgba(180,190,254,0.5);
}
inputbar { spacing: 8px; padding: 6px 8px; }
EOF
	} >"$tf"
	echo "$tf"
}

#----------------------------- Otomatik rofi açılışı ---------------------------
if [[ -z "${ROFI_RETV:-}" && -z "${ROFI_INSIDE:-}" ]]; then
	self="$(readlink -f "${BASH_SOURCE[0]}")"
	theme_file="$(_write_theme_file)"
	exec rofi -show power -modi "power:${self}" \
		-theme "${theme_file}" \
		-lines "${POWER_MENU_LINES}" \
		-eh 1
fi

#----------------------------- CLI seçenekleri ---------------------------------
DRYRUN=false
SHOW_SYMBOLS=true
SHOW_TEXT=true
SHOW=("${ALL[@]}")
SYMFONT=""
choose_id=""
usage() {
	cat <<EOF
power-menu – rofi modu
Kullanım: power-menu [--choices a/b/c] [--confirm a/b] [--dry-run]
                    [--symbols|--no-symbols] [--text|--no-text]
                    [--symbols-font "Font Adı"] [--choose <id>]
EOF
}
parsed="$(getopt -o h --long help,dry-run,confirm:,choices:,choose:,symbols,no-symbols,text,no-text,symbols-font: -- "$@")" || {
	echo "Arg parse error"
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
		IFS=/ read -r -a CONFIRM <<<"${2}"
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
	--)
		shift
		break
		;;
	*)
		echo "Internal arg error"
		exit 1
		;;
	esac
done
$SHOW_SYMBOLS || $SHOW_TEXT || {
	echo "Hem --no-symbols hem --no-text olamaz." >&2
	exit 1
}

#--------------------------------- Yardımcılar ---------------------------------
notify() { command -v notify-send >/dev/null && notify-send -t 2500 "Power" "$*"; }
wmsg() {
	local ic="${1-}" tx="${2-}"
	[[ -n "${ic}" ]] || ic=" "
	local icon="<span font_size=\"medium\">${ic}</span>"
	[[ -n "${SYMFONT-}" && -n "${SYMFONT}" ]] && icon="<span font=\"${SYMFONT}\" font_size=\"medium\">${ic}</span>"
	local text="<span font_size=\"medium\">${tx}</span>"
	if $SHOW_SYMBOLS && $SHOW_TEXT; then
		printf "\u200e%s \u2068%s\u2069" "$icon" "$text"
	elif $SHOW_SYMBOLS; then
		printf "%s" "$icon"
	else printf "%s" "$text"; fi
}
contains_label() { [[ "$1" == *"$2"* ]]; }

graceful_shutdown() {
	local a alive
	for a in "${GRACE_APPS[@]}"; do
		if pgrep -x "$a" >/dev/null; then $DRYRUN || pkill -TERM -x "$a" || true; fi
	done
	for ((i = 0; i < SOFT_TIMEOUT; i++)); do
		sleep 1
		alive=false
		for a in "${GRACE_APPS[@]}"; do pgrep -x "$a" >/dev/null && {
			alive=true
			break
		}; done
		$alive || break
	done
	for a in "${GRACE_APPS[@]}"; do
		if pgrep -x "$a" >/dev/null; then $DRYRUN || pkill -KILL -x "$a" || true; fi
	done
}
fix_brave_flags() {
	$FIX_BRAVE || return 0
	local base="${HOME}/.config/BraveSoftware/Brave-Browser"
	local local_state="${base}/Local State"
	local prefs="${base}/Default/Preferences"
	$DRYRUN && {
		echo "[dry-run] Brave flag fix"
		return 0
	}
	if command -v jq >/dev/null 2>&1; then
		[[ -f "$local_state" ]] && jq '.profile.exited_cleanly=true' "$local_state" >"${local_state}.tmp" 2>/dev/null && mv "${local_state}.tmp" "$local_state" || true
		[[ -f "$prefs" ]] && jq '.profile.exit_type="Normal"' "$prefs" >"${prefs}.tmp" 2>/dev/null && mv "${prefs}.tmp" "$prefs" || true
	else
		[[ -f "$local_state" ]] && sed -i 's/"exited_cleanly":[ ]*false/"exited_cleanly": true/g' "$local_state" || true
		[[ -f "$prefs" ]] && sed -i 's/"exit_type":[ ]*"Crashed"/"exit_type":"Normal"/g' "$prefs" || true
	fi
}
pre_power_phase() {
	graceful_shutdown
	fix_brave_flags
	if $CLOSE_USER_SESSION; then
		$DRYRUN || systemctl --user exit || true
		sleep 0.3
	fi
}
do_action() {
	local act="$1"
	if $DRYRUN; then
		echo "Selected: $act"
		return 0
	fi
	case "$act" in reboot | shutdown | hibernate) pre_power_phase ;; suspend) : ;; esac
	eval "${CMD[$act]}" &
	sleep "$HARD_DELAY"
	pkill rofi || true
}

#------------------------------- Rofi protokolü --------------------------------
declare -A MSG CFM
for e in "${ALL[@]}"; do MSG[$e]="$(wmsg "${ICON[$e]}" "${TEXT[$e]^}")"; done
for e in "${ALL[@]}"; do CFM[$e]="$(wmsg "${ICON[$e]}" "Yes, ${TEXT[$e]}")"; done
CFM[cancel]="$(wmsg "${ICON[cancel]-}" "No, cancel")"

echo -e "\0no-custom\x1ftrue"
echo -e "\0markup-rows\x1ftrue"

selection="${*:-}"
if [[ -z "$selection" ]] && ! [ -t 0 ]; then selection="$(cat)"; fi
if [[ -n "$choose_id" && -z "$selection" ]]; then
	do_action "$choose_id"
	exit 0
fi

if [[ -z "$selection" ]]; then
	echo -e "\0prompt\x1fPower menu"
	for e in "${SHOW[@]}"; do echo -e "${MSG[$e]}\0icon\x1f${ICON[$e]}"; done
	exit 0
fi

if contains_label "$selection" "Yes,"; then
	for e in "${ALL[@]}"; do
		contains_label "$selection" "${TEXT[$e]}" && {
			notify "${TEXT[$e]}…"
			do_action "$e"
			exit 0
		}
	done
	echo "Invalid selection: $selection"
	exit 1
fi

for e in "${SHOW[@]}"; do
	if contains_label "$selection" "${TEXT[$e]}"; then
		for c in "${CONFIRM[@]}"; do
			if [[ "$e" == "$c" ]]; then
				echo -e "\0prompt\x1fAre you sure"
				echo -e "${CFM[$e]}\0icon\x1f${ICON[$e]}"
				echo -e "${CFM[cancel]}\0icon\x1f${ICON[cancel]}"
				exit 0
			fi
		done
		notify "${TEXT[$e]}…"
		do_action "$e"
		exit 0
	fi
done

echo "Invalid selection: $selection" >&2
exit 1
