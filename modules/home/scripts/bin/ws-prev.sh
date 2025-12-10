#!/usr/bin/env bash
# ws-prev.sh - Önceki workspace’a geçiş (Hyprland)
# Çalışma alanını geri alır; hyprctl dispatch ile çalışır.
set -euo pipefail

WMCTRL="${WMCTRL_ABS:-$(command -v wmctrl || echo /etc/profiles/per-user/kenan/bin/wmctrl)}"

current="$("$WMCTRL" -d | awk '/\*/{print $1}')"
# sayı mı?
if [[ "$current" =~ ^[0-9]+$ ]] && [[ "$current" -gt 0 ]]; then
	"$WMCTRL" -s "$((current - 1))"
fi
