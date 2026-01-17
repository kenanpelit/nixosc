#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
gnome-column-width - Cycle/set window width proportions on GNOME (Wayland-safe)

Usage:
  gnome-column-width            # cycle preset widths
  gnome-column-width cycle      # same as above
  gnome-column-width set 0.8    # set to a specific proportion (0.1..1.0)
EOF
}

action="${1:-cycle}"
set_ratio="${2:-}"

case "$action" in
  -h|--help|help)
    usage
    exit 0
    ;;
  cycle|set)
    ;;
  *)
    echo "gnome-column-width: unknown action: $action" >&2
    usage >&2
    exit 2
    ;;
esac

if [[ "$action" == "set" ]]; then
  [[ -n "$set_ratio" ]] || set_ratio="0.8"
  if ! awk -v r="$set_ratio" 'BEGIN { exit !(r > 0 && r <= 1.0) }' >/dev/null 2>&1; then
    echo "gnome-column-width: invalid ratio: $set_ratio (expected 0 < r <= 1.0)" >&2
    exit 2
  fi
fi

command -v gdbus >/dev/null 2>&1 || {
  echo "gnome-column-width: gdbus not found" >&2
  exit 1
}

js_action="$action"
js_ratio="null"
if [[ "$action" == "set" ]]; then
  js_ratio="$set_ratio"
fi

js="$(cat <<EOF
(function () {
  const Meta = imports.gi.Meta;
  const Main = imports.ui.main;

  const action = "${js_action}";
  const setRatio = ${js_ratio};
  const presets = [0.30, 0.45, 0.60, 0.75, 1.0];
  const preferred = 0.8;

  const win = global.display.get_focus_window();
  if (!win) return "no-window";

  const monitor = win.get_monitor();
  const wa = Main.layoutManager.getWorkAreaForMonitor(monitor);
  const rect = win.get_frame_rect();

  function clamp(v, lo, hi) { return Math.max(lo, Math.min(hi, v)); }

  let ratio = preferred;
  if (action === "set" && typeof setRatio === "number" && setRatio > 0 && setRatio <= 1.0) {
    ratio = setRatio;
  } else {
    const current = rect.width / wa.width;
    let closest = 0;
    let best = 1e9;
    for (let i = 0; i < presets.length; i++) {
      const d = Math.abs(current - presets[i]);
      if (d < best) { best = d; closest = i; }
    }
    ratio = presets[(closest + 1) % presets.length];
  }

  const newW = Math.round(wa.width * ratio);
  const newH = rect.height;
  const newX = wa.x + Math.round((wa.width - newW) / 2);
  const newY = clamp(rect.y, wa.y, wa.y + Math.max(0, wa.height - newH));

  try { win.unmaximize(Meta.MaximizeFlags.BOTH); } catch (e) {}

  try {
    win.move_resize_frame(true, newX, newY, newW, newH);
    if (win.activate) win.activate(global.get_current_time());
    return "ok:" + ratio.toString();
  } catch (e) {
    return "error:" + e.toString();
  }
})();
EOF
)"

out="$(gdbus call --session --dest org.gnome.Shell --object-path /org/gnome/Shell --method org.gnome.Shell.Eval "$js" 2>/dev/null || true)"

if [[ -z "$out" || "$out" == *"(false,"* ]]; then
  echo "gnome-column-width: GNOME Shell Eval failed" >&2
  exit 1
fi

if [[ "$out" == *"error:"* ]]; then
  echo "gnome-column-width: $out" >&2
  exit 1
fi

exit 0

