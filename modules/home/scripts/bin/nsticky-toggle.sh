#!/usr/bin/env bash
set -euo pipefail

# One keybind, smart behaviour:
# - If the active window is sticky -> stage it
# - If the active window is staged -> unstage it (back to sticky)
# - If the active window is neither -> make it sticky
#
# This avoids ending up in an inconsistent "sticky + staged" state.

die() {
  echo "nsticky-toggle: $*" >&2
  exit 1
}

command -v nsticky >/dev/null 2>&1 || die "nsticky not found in PATH"

out="$(nsticky stage toggle-active 2>&1 || true)"

if [[ "$out" == Error:* ]]; then
  # Normal window: stage toggle fails because it's not sticky yet.
  if [[ "$out" == *"not in sticky list"* ]]; then
    out2="$(nsticky sticky toggle-active 2>&1 || true)"
    [[ "$out2" == Error:* ]] && die "$out2"
    exit 0
  fi

  die "$out"
fi

# Success (staged or unstaged).
case "$out" in
  Added*|Staged*|Unstaged*) exit 0 ;;
esac

die "$out"
