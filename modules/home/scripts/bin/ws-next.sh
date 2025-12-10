#!/usr/bin/env bash
# ws-next.sh - Sonraki workspace’a geçiş (Hyprland)
# Çalışma alanını ileri alır; hyprctl dispatch ile çalışır.
set -euo pipefail

WMCTRL="${WMCTRL_ABS:-$(command -v wmctrl || echo /etc/profiles/per-user/kenan/bin/wmctrl)}"

current="$("$WMCTRL" -d | awk '/\*/{print $1}')"
total="$("$WMCTRL" -d | wc -l | tr -d '[:space:]')"

# ikisi de sayı mı?
if [[ "$current" =~ ^[0-9]+$ ]] && [[ "$total" =~ ^[0-9]+$ ]]; then
	if ((current < total - 1)); then
		"$WMCTRL" -s "$((current + 1))"
	fi
fi
