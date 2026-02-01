#!/usr/bin/env bash
set -euo pipefail

# Toggle power profiles: performance -> balanced -> power-saver

need() { command -v "$1" >/dev/null 2>&1; }

die() { echo "ERROR: $*" >&2; exit 1; }

need powerprofilesctl || die "powerprofilesctl not found"

current=$(powerprofilesctl get 2>/dev/null || true)
case "$current" in
  performance) next=balanced ;;
  balanced) next=power-saver ;;
  power-saver) next=performance ;;
  *) next=balanced ;;
 esac

powerprofilesctl set "$next"

if need notify-send; then
  case "$next" in
    performance) icon="speedometer"; title="Performance"; msg="Maximum performance" ;;
    balanced) icon="battery-good"; title="Balanced"; msg="Balanced power profile" ;;
    power-saver) icon="battery-low"; title="Power Saver"; msg="Reduced power usage" ;;
  esac
  notify-send -t 3500 -i "$icon" "Power Profile: $title" "$msg"
fi
