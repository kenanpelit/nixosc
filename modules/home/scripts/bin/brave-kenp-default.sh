#!/usr/bin/env bash
set -euo pipefail

# Default browser entry for Kenp profile.
# Use shared Brave instance so links open as tabs in the existing window.

if command -v profile_brave >/dev/null 2>&1; then
  exec profile_brave Kenp --no-separate "$@"
fi

if command -v brave-launcher >/dev/null 2>&1; then
  exec brave-launcher --profile-directory=Default "$@"
fi

if command -v brave >/dev/null 2>&1; then
  exec brave --profile-directory=Default "$@"
fi

if command -v brave-browser >/dev/null 2>&1; then
  exec brave-browser --profile-directory=Default "$@"
fi

echo "brave-kenp-default: brave not found" >&2
exit 127
