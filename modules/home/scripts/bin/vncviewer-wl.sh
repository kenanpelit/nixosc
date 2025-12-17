#!/usr/bin/env bash
# vncviewer-wl: Run TigerVNC viewer under Xwayland when DISPLAY is missing (Wayland session)

set -euo pipefail

target="${1:-localhost:5901}"

if [[ -n "${DISPLAY:-}" ]]; then
  exec vncviewer "$target"
fi

# Pick a display number that is likely free
disp=":1"

# Start Xwayland only if not already running for this display
if ! pgrep -af "Xwayland ${disp}" >/dev/null 2>&1; then
  Xwayland "${disp}" -terminate -nolisten tcp >/tmp/xwayland-vncviewer.log 2>&1 &
  sleep 0.5
fi

DISPLAY="${disp}" exec vncviewer "$target"
