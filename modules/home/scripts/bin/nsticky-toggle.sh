#!/usr/bin/env bash
set -euo pipefail

# One keybind, smart behaviour:
# - If the active window is sticky -> stage it
# - If the active window is staged -> unstage it (back to sticky)
# - If the active window is neither -> make it sticky
#
# This avoids ending up in an inconsistent "sticky + staged" state.

notify() {
  local urgency="${1:-low}"
  local title="${2:-nsticky}"
  local body="${3:-}"

  command -v notify-send >/dev/null 2>&1 || return 0
  notify-send \
    -a "nsticky" \
    -u "$urgency" \
    -t 1400 \
    -h string:x-canonical-private-synchronous:nsticky-toggle \
    "$title" "$body" 2>/dev/null || true
}

die() {
  local msg="$*"
  notify critical "nsticky" "$msg"
  echo "nsticky-toggle: $msg" >&2
  exit 1
}

command -v nsticky >/dev/null 2>&1 || die "nsticky not found in PATH"

out="$(nsticky stage toggle-active 2>&1 || true)"

if [[ "$out" == Error:* ]]; then
  # Normal window: stage toggle fails because it's not sticky yet.
  if [[ "$out" == *"not in sticky list"* ]]; then
    out2="$(nsticky sticky toggle-active 2>&1 || true)"
    [[ "$out2" == Error:* ]] && die "$out2"
    case "$out2" in
      Added*) notify low "Sticky" "Enabled" ;;
      Removed*) notify low "Sticky" "Disabled" ;;
      *) notify low "nsticky" "$out2" ;;
    esac
    exit 0
  fi

  die "$out"
fi

case "$out" in
  Added*) notify low "Sticky" "Enabled" ;;
  Staged*) notify low "Stage" "Moved to stage" ;;
  Unstaged*) notify low "Stage" "Restored" ;;
  *) die "$out" ;;
esac

exit 0
