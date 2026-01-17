#!/usr/bin/env bash
set -euo pipefail

SCRIPT_NAME="${0##*/}"

usage() {
  cat <<'EOF'
gnome-set - GNOME helpers (Niri-like)

Usage:
  gnome-set here <APP_ID|all>
  gnome-set go

Examples:
  gnome-set here Kenp
  gnome-set here TmuxKenp
  gnome-set here all
  gnome-set go
EOF
}

die() {
  echo "${SCRIPT_NAME}: $*" >&2
  exit 1
}

need() {
  command -v "$1" >/dev/null 2>&1 || die "missing dependency: $1"
}

js_escape() {
  local s="$1"
  s="${s//\\/\\\\}"
  s="${s//\"/\\\"}"
  s="${s//$'\n'/\\n}"
  printf '%s' "$s"
}

gnome_shell_running() {
  command -v gdbus >/dev/null 2>&1 || return 1
  gdbus call --session \
    --dest org.freedesktop.DBus \
    --object-path /org/freedesktop/DBus \
    --method org.freedesktop.DBus.NameHasOwner \
    org.gnome.Shell 2>/dev/null | grep -q "true"
}

gnome_eval() {
  local js="$1"
  gdbus call --session \
    --dest org.gnome.Shell \
    --object-path /org/gnome/Shell \
    --method org.gnome.Shell.Eval \
    "$js" 2>/dev/null
}

gnome_move_here() {
  local target_raw="$1"
  local target
  target="$(js_escape "$target_raw")"

  local js
  js="$(cat <<EOF
(function () {
  const Shell = imports.gi.Shell;

  const target = "${target}";
  const targetDesktop = target.endsWith(".desktop") ? target : (target + ".desktop");

  function norm(s) { return (s || "").toString(); }
  function eqi(a, b) { return norm(a).toLowerCase() === norm(b).toLowerCase(); }

  const tracker = Shell.WindowTracker.get_default();
  const wins = global.get_window_actors().map(a => a.meta_window).filter(w => w);
  const activeWs = global.workspace_manager.get_active_workspace();

  function props(w) {
    let cls = "";
    let inst = "";
    let appId = "";
    try { cls = w.get_wm_class ? (w.get_wm_class() || "") : ""; } catch (e) {}
    try { inst = w.get_wm_class_instance ? (w.get_wm_class_instance() || "") : ""; } catch (e) {}
    try {
      const app = tracker.get_window_app(w);
      appId = app ? (app.get_id() || "") : "";
    } catch (e) {}
    return { cls, inst, appId };
  }

  function matches(w) {
    const p = props(w);
    return (
      eqi(p.cls, target) ||
      eqi(p.inst, target) ||
      eqi(p.appId, target) ||
      eqi(p.appId, targetDesktop)
    );
  }

  let win =
    wins.find(w => matches(w) && w.get_workspace && w.get_workspace() === activeWs) ||
    wins.find(w => matches(w));

  if (!win) return "__GNOME_SET_NOT_FOUND__";

  try {
    const ws = win.get_workspace ? win.get_workspace() : null;
    if (ws && ws !== activeWs && win.change_workspace) win.change_workspace(activeWs);
  } catch (e) {}

  try { if (win.minimized && win.unminimize) win.unminimize(); } catch (e) {}
  try { if (win.activate) win.activate(global.get_current_time()); } catch (e) {}

  return "__GNOME_SET_OK__";
})();
EOF
)"

  gnome_eval "$js" || true
}

launch_for_app() {
  local app="$1"

  case "$app" in
    Kenp) start-brave-kenp >/dev/null 2>&1 & ;;
    TmuxKenp|Tmux) start-kkenp >/dev/null 2>&1 & ;;
    Ai) start-brave-ai >/dev/null 2>&1 & ;;
    CompecTA) start-brave-compecta >/dev/null 2>&1 & ;;
    WebCord) start-webcord >/dev/null 2>&1 & ;;
    brave-youtube.com__-Default) start-brave-youtube >/dev/null 2>&1 & ;;
    spotify|Spotify) start-spotify >/dev/null 2>&1 & ;;
    ferdium|Ferdium) start-ferdium >/dev/null 2>&1 & ;;
    org.telegram.desktop|TelegramDesktop)
      if command -v telegram-desktop >/dev/null 2>&1; then
        telegram-desktop >/dev/null 2>&1 &
      elif command -v Telegram >/dev/null 2>&1; then
        Telegram >/dev/null 2>&1 &
      else
        return 1
      fi
      ;;
    all) return 0 ;;
    *)
      if command -v "$app" >/dev/null 2>&1; then
        "$app" >/dev/null 2>&1 &
      else
        return 1
      fi
      ;;
  esac

  return 0
}

here_one() {
  local app="$1"
  local out
  out="$(gnome_move_here "$app" || true)"

  if [[ "$out" == *"__GNOME_SET_OK__"* ]]; then
    return 0
  fi

  # Not running: launch then pull it here (best-effort).
  launch_for_app "$app" || return 1

  for _ in {1..40}; do
    out="$(gnome_move_here "$app" || true)"
    if [[ "$out" == *"__GNOME_SET_OK__"* ]]; then
      return 0
    fi
    sleep 0.1
  done

  return 0
}

cmd="${1:-}"
shift || true

case "$cmd" in
  -h|--help|help|"")
    usage
    exit 0
    ;;
esac

need gdbus
gnome_shell_running || die "GNOME Shell not detected (need org.gnome.Shell on session bus)"

case "$cmd" in
  here)
    app="${1:-}"
    [[ -n "$app" ]] || die "here: missing APP_ID"

    if [[ "$app" == "all" ]]; then
      # Keep aligned with Niri defaults.
      apps=(
        "Kenp"
        "TmuxKenp"
        "Ai"
        "CompecTA"
        "WebCord"
        "brave-youtube.com__-Default"
        "spotify"
        "ferdium"
      )
      for a in "${apps[@]}"; do
        here_one "$a" || true
        sleep 0.05
      done
      here_one "Kenp" || true
      exit 0
    fi

    here_one "$app"
    ;;

  go)
    # Move windows back to their "home" workspaces (Niri rules parity).
    declare -a rules=(
      "Kenp:1"
      "TmuxKenp:2"
      "Ai:3"
      "CompecTA:4"
      "WebCord:5"
      "discord:5"
      "audacious:5"
      "org.telegram.desktop:6"
      "vlc:6"
      "remote-viewer:6"
      "transmission:7"
      "org.keepassxc.KeePassXC:7"
      "brave-youtube.com__-Default:7"
      "spotify:8"
      "ferdium:9"
      "com.rtosta.zapzap:9"
      "whatsie:9"
    )

    for rule in "${rules[@]}"; do
      key="${rule%%:*}"
      ws="${rule##*:}"
      key_js="$(js_escape "$key")"
      ws_idx="$((ws - 1))"

      js="$(cat <<EOF
(function () {
  const Shell = imports.gi.Shell;
  const target = "${key_js}";
  const targetDesktop = target.endsWith(".desktop") ? target : (target + ".desktop");
  const ws = global.workspace_manager.get_workspace_by_index(${ws_idx});

  function norm(s) { return (s || "").toString(); }
  function eqi(a, b) { return norm(a).toLowerCase() === norm(b).toLowerCase(); }

  const tracker = Shell.WindowTracker.get_default();
  const wins = global.get_window_actors().map(a => a.meta_window).filter(w => w);

  function props(w) {
    let cls = "";
    let inst = "";
    let appId = "";
    try { cls = w.get_wm_class ? (w.get_wm_class() || "") : ""; } catch (e) {}
    try { inst = w.get_wm_class_instance ? (w.get_wm_class_instance() || "") : ""; } catch (e) {}
    try {
      const app = tracker.get_window_app(w);
      appId = app ? (app.get_id() || "") : "";
    } catch (e) {}
    return { cls, inst, appId };
  }

  function matches(w) {
    const p = props(w);
    return (
      eqi(p.cls, target) ||
      eqi(p.inst, target) ||
      eqi(p.appId, target) ||
      eqi(p.appId, targetDesktop)
    );
  }

  let moved = 0;
  for (const w of wins) {
    if (!matches(w)) continue;
    try {
      if (w.change_workspace) w.change_workspace(ws);
      moved++;
    } catch (e) {}
  }
  return "moved:" + moved.toString();
})();
EOF
)"

      gnome_eval "$js" >/dev/null 2>&1 || true
      sleep 0.05
    done

    # End on Kenp (workspace 1) like niri-set go.
    gnome_eval "global.workspace_manager.get_workspace_by_index(0).activate(global.get_current_time());" >/dev/null 2>&1 || true
    gnome_move_here "Kenp" >/dev/null 2>&1 || true
    ;;

  *)
    die "unknown command: $cmd"
    ;;
esac
