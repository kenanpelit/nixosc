#!/usr/bin/env bash
set -euo pipefail

# Power profile helper with optional auto-profile lock integration.
# Default behavior remains toggle:
# performance -> balanced -> power-saver -> performance

LOCK_FILE="${HOME}/.local/state/ppd-auto-profile/lock"
LOCK_DIR="${LOCK_FILE%/*}"

need() { command -v "$1" >/dev/null 2>&1; }

die() { echo "ERROR: $*" >&2; exit 1; }

need powerprofilesctl || die "powerprofilesctl not found (enable power-profiles-daemon)"

notify() {
  local icon="$1" title="$2" msg="$3"
  if need notify-send; then
    notify-send -t 3500 -i "$icon" "$title" "$msg" >/dev/null 2>&1 || true
  fi
}

profile_notify() {
  local profile="$1" icon title msg
  case "$profile" in
    performance) icon="speedometer"; title="Performance"; msg="Maximum performance" ;;
    balanced) icon="battery-good"; title="Balanced"; msg="Balanced power profile" ;;
    power-saver) icon="battery-low"; title="Power Saver"; msg="Reduced power usage" ;;
    *) icon="battery-good"; title="$profile"; msg="Power profile set" ;;
  esac
  notify "$icon" "Power Profile: $title" "$msg"
}

current_profile() {
  powerprofilesctl get 2>/dev/null || true
}

set_profile() {
  local profile="$1"
  powerprofilesctl set "$profile" >/dev/null 2>&1 || die "failed to set profile: $profile"
  profile_notify "$profile"
}

is_locked() {
  [ -f "$LOCK_FILE" ]
}

write_lock() {
  local profile="$1"
  mkdir -p "$LOCK_DIR"
  {
    echo "profile=$profile"
    echo "updated=$(date -Is)"
    echo "user=${USER:-unknown}"
  } >"$LOCK_FILE"
}

read_lock_profile() {
  awk -F= '/^profile=/{print $2; exit}' "$LOCK_FILE" 2>/dev/null || true
}

show_status() {
  local current lock_profile
  current="$(current_profile)"
  echo "current: ${current:-unknown}"
  if is_locked; then
    lock_profile="$(read_lock_profile)"
    if [ -n "$lock_profile" ]; then
      echo "auto-switch: locked ($lock_profile)"
    else
      echo "auto-switch: locked"
    fi
    echo "lock-file: $LOCK_FILE"
  else
    echo "auto-switch: unlocked"
  fi
}

usage() {
  cat <<EOF
Usage: power-profile [command] [args]

Commands:
  toggle              Toggle profile (default action)
  set <profile>       Set profile manually
  lock [profile]      Lock auto-switching; optional profile to set first
  unlock              Remove lock and re-enable auto-switching
  status              Show current profile and lock status
  help                Show this help
EOF
}

cmd="${1:-toggle}"
if [ "$#" -gt 0 ]; then
  shift
fi

case "$cmd" in
  toggle)
    current="$(current_profile)"
    case "$current" in
      performance) next=balanced ;;
      balanced) next=power-saver ;;
      power-saver) next=performance ;;
      *) next=balanced ;;
    esac
    set_profile "$next"
    # If already locked, keep lock metadata aligned with manual changes.
    if is_locked; then
      write_lock "$next"
      notify "emblem-locked" "Auto Power Profile: Locked" "Lock kept at $next"
    fi
    ;;

  set)
    profile="${1:-}"
    [ -n "$profile" ] || die "usage: power-profile set <profile>"
    set_profile "$profile"
    if is_locked; then
      write_lock "$profile"
      notify "emblem-locked" "Auto Power Profile: Locked" "Lock kept at $profile"
    fi
    ;;

  lock)
    profile="${1:-$(current_profile)}"
    [ -n "$profile" ] || profile="balanced"
    set_profile "$profile"
    write_lock "$profile"
    notify "emblem-locked" "Auto Power Profile: Locked" "Auto switching disabled ($profile)"
    ;;

  unlock)
    if is_locked; then
      rm -f "$LOCK_FILE"
      notify "emblem-default" "Auto Power Profile: Unlocked" "Auto switching enabled"
    else
      echo "already unlocked"
    fi
    ;;

  status)
    show_status
    ;;

  help|-h|--help)
    usage
    ;;

  *)
    die "unknown command: $cmd (run: power-profile help)"
    ;;
esac
