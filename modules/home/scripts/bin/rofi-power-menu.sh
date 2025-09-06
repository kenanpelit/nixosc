#!/usr/bin/env bash
# ==============================================================================
# power-menu (Hyprland friendly) - Rofi mode
# Version: 2.2.0
# Author: you + ChatGPT
#
# Özellikler:
# - Reboot/Shutdown/Hibernate öncesi "nazik kapatma": Brave vb. süreçlere SIGTERM,
#   kısa bekleme, hâlâ yaşıyorsa (nadir) SIGKILL.
# - Brave “crash restore” balonunu tetikleyen bayrakları bir kez temizler.
# - Kapatmadan hemen önce `systemctl --user exit` ile user-session servislerini
#   düzgün kapatır (pipewire/portal vs.).
# - Onay mekanizması (reboot/shutdown/hibernate için).
# - Renkli/ikonlu çıktı (rofi markup), --no-symbols / --no-text destekli.
# - --dry-run ile ne yapacağını gösterir.
#
# Rofi entegrasyonu:
# rofi -show power -modi "power:~/bin/power-menu"
# ==============================================================================

#set -euo pipefail

# ----------------------------- Ayarlar ---------------------------------------
# Nazik kapatma listesi (process adları - pgrep -x ile eşleşir)
GRACE_APPS=("brave" "brave-browser" "brave-browser-stable")

# Bekleme süreleri
SOFT_TIMEOUT=10 # SIGTERM sonrası bekleme (saniye)
HARD_DELAY=0.5  # Rofi’nin kapanmasına fırsat (saniye)

# Brave “crash balonu” flag fix (bir defa çalıştırmak genelde yeterli)
FIX_BRAVE=true

# User session’ı düzgün kapat (tavsiye edilir)
CLOSE_USER_SESSION=true

# ----------------------------- UI Metin/İkon ---------------------------------
declare -A TEXT ICON CMD
ALL=(shutdown reboot suspend hibernate lockscreen logout)

TEXT[lockscreen]="Lock"
TEXT[logout]="Logout"
TEXT[suspend]="Suspend"
TEXT[hibernate]="Hibernate"
TEXT[reboot]="Reboot"
TEXT[shutdown]="Shutdown"

ICON[lockscreen]="\Uf033e"
ICON[logout]="\Uf0343"
ICON[suspend]="\Uf04b2"
ICON[hibernate]="\Uf02ca"
ICON[reboot]="\Uf0709"
ICON[shutdown]="\Uf0425"
ICON[cancel]="\Uf0156"

# Komutlar (Hyprland/Sway uyumlu)
CMD[lockscreen]="hyprlock || swaylock"
CMD[logout]="hyprctl dispatch exit || swaymsg exit || true"
CMD[suspend]="systemctl suspend -i"
CMD[hibernate]="systemctl hibernate"
CMD[reboot]="systemctl reboot -i"
CMD[shutdown]="systemctl poweroff -i"

CONFIRM=(reboot shutdown hibernate)

# ----------------------------- CLI seçenekleri --------------------------------
DRYRUN=false
SHOW_SYMBOLS=true
SHOW_TEXT=true
SHOW=("${ALL[@]}")
SYMFONT=""

usage() {
	cat <<EOF
power-menu – rofi modu
Kullanım: power-menu [--choices a/b/c] [--confirm a/b] [--dry-run]
                   [--symbols|--no-symbols] [--text|--no-text]
                   [--symbols-font 'Font Name']

Ör: rofi -show power -modi "power:$0"
EOF
}

parsed=$(getopt -o h --long help,dry-run,confirm:,choices:,choose:,symbols,no-symbols,text,no-text,symbols-font: -- "$@") || {
	echo "Arg parse error"
	exit 1
}
eval set -- "$parsed"
unset parsed

if ! declare -F printf >/dev/null; then
	echo "bash gerekli" >&2
	exit 1
fi

choose_id=""
while true; do
	case "$1" in
	-h | --help)
		usage
		exit 0
		;;
	--dry-run)
		DRYRUN=true
		shift
		;;
	--confirm)
		IFS=/ read -r -a CONFIRM <<<"$2"
		shift 2
		;;
	--choices)
		IFS=/ read -r -a SHOW <<<"$2"
		shift 2
		;;
	--choose)
		choose_id="$2"
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
		SYMFONT="$2"
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

if ! $SHOW_SYMBOLS && ! $SHOW_TEXT; then
	echo "Hem --no-symbols hem --no-text olamaz." >&2
	exit 1
fi

# --------------------------- Yardımcı Fonksiyonlar ----------------------------
wmsg() { # rofi markup satırı üret
	local ic="$1" tx="$2" icon="<span font_size=\"medium\">$ic</span>"
	[ -n "$SYMFONT" ] && icon="<span font=\"$SYMFONT\" font_size=\"medium\">$ic</span>"
	local text="<span font_size=\"medium\">$tx</span>"
	if $SHOW_SYMBOLS && $SHOW_TEXT; then
		printf "\u200e%s \u2068%s\u2069" "$icon" "$text"
	elif $SHOW_SYMBOLS; then
		printf "%s" "$icon"
	else
		printf "%s" "$text"
	fi
}

print_sel() { echo -e "$1" | (
	read -r -d '' e
	echo "echo $e"
); }

notify() { command -v notify-send >/dev/null && notify-send -t 2500 "Power" "$*"; }

graceful_shutdown() {
	# Uygulamaları nazikçe kapat (SIGTERM) ve bekle; hâlâ varsa SIGKILL
	local alive=false
	for a in "${GRACE_APPS[@]}"; do
		if pgrep -x "$a" >/dev/null; then
			echo "[power] $a -> SIGTERM"
			$DRYRUN || pkill -TERM -x "$a" || true
		fi
	done

	for ((i = 0; i < SOFT_TIMEOUT; i++)); do
		sleep 1
		alive=false
		for a in "${GRACE_APPS[@]}"; do
			if pgrep -x "$a" >/dev/null; then
				alive=true
				break
			fi
		done
		$alive || break
	done

	for a in "${GRACE_APPS[@]}"; do
		if pgrep -x "$a" >/div/null; then
			echo "[power] $a hala çalışıyor -> SIGKILL"
			$DRYRUN || pkill -KILL -x "$a" || true
		fi
	done
}

fix_brave_flags() {
	$FIX_BRAVE || return 0
	local base="$HOME/.config/BraveSoftware/Brave-Browser"
	local local_state="$base/Local State"
	local prefs="$base/Default/Preferences"

	if $DRYRUN; then
		echo "[dry-run] Brave flag fix"
		return 0
	fi

	if command -v jq >/dev/null 2>&1; then
		[ -f "$local_state" ] && jq '.profile.exited_cleanly=true' "$local_state" >"${local_state}.tmp" 2>/dev/null && mv "${local_state}.tmp" "$local_state" || true
		[ -f "$prefs" ] && jq '.profile.exit_type="Normal"' "$prefs" >"${prefs}.tmp" 2>/dev/null && mv "${prefs}.tmp" "$prefs" || true
	else
		[ -f "$local_state" ] && sed -i 's/"exited_cleanly":[ ]*false/"exited_cleanly": true/g' "$local_state" || true
		[ -f "$prefs" ] && sed -i 's/"exit_type":[ ]*"Crashed"/"exit_type":"Normal"/g' "$prefs" || true
	fi
}

pre_power_phase() {
	graceful_shutdown
	fix_brave_flags
	if $CLOSE_USER_SESSION; then
		echo "[power] systemctl --user exit"
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

	case "$act" in
	reboot | shutdown | hibernate)
		pre_power_phase
		;;
	suspend)
		# suspend’te user exit yapma (uykudan dönüşte ortamı korumak isteyebilirsin)
		;;
	esac

	# Rofi’yi nazikçe kapatıp komutu uygula
	eval "${CMD[$act]}" &
	sleep "$HARD_DELAY"
	pkill rofi || true
}

# ------------------------------ Rofi Protokolü -------------------------------
declare -A MSG CFM
for e in "${ALL[@]}"; do
	MSG[$e]=$(wmsg "${ICON[$e]}" "${TEXT[$e]^}")
done
for e in "${ALL[@]}"; do
	CFM[$e]=$(wmsg "${ICON[$e]}" "Yes, ${TEXT[$e]}")
done
CFM[cancel]=$(wmsg "${ICON[cancel]}" "No, cancel")

# En üst başlıklar
echo -e "\0no-custom\x1ftrue"
echo -e "\0markup-rows\x1ftrue"

selection=""
if [ $# -gt 0 ]; then
	selection="$*"
elif [ -n "${choose_id:-}" ]; then selection="${MSG[$choose_id]}"; fi

if [ -z "$selection" ]; then
	echo -e "\0prompt\x1fPower menu"
	for e in "${SHOW[@]}"; do
		echo -e "${MSG[$e]}\0icon\x1f${ICON[$e]}"
	done
	exit 0
fi

# Seçim/Onay akışı
for e in "${SHOW[@]}"; do
	if [ "$selection" = "$(print_sel "${MSG[$e]}")" ]; then
		for c in "${CONFIRM[@]}"; do
			if [ "$e" = "$c" ]; then
				echo -e "\0prompt\x1fAre you sure"
				echo -e "${CFM[$e]}\0icon\x1f${ICON[$e]}"
				echo -e "${CFM[cancel]}\0icon\x1f${ICON[cancel]}"
				exit 0
			fi
		done
		selection="$(print_sel "${CFM[$e]}")"
	fi

	if [ "$selection" = "$(print_sel "${CFM[$e]}")" ]; then
		notify "${TEXT[$e]}…"
		do_action "$e"
		exit 0
	fi
	if [ "$selection" = "$(print_sel "${CFM[cancel]}")" ]; then
		notify "Canceled"
		exit 0
	fi
done

echo "Invalid selection: $selection" >&2
exit 1
