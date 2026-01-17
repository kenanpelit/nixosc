#!/usr/bin/env bash
set -euo pipefail

SCRIPT_NAME="${0##*/}"
PARITY_UUID="gnome-niri-parity@kenan"

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

ensure_shell_eval_enabled() {
  # org.gnome.Shell.Eval returns (false, '') unless development-tools is enabled.
  if command -v gsettings >/dev/null 2>&1; then
    if [[ "$(gsettings get org.gnome.shell development-tools 2>/dev/null || true)" != "true" ]]; then
      gsettings set org.gnome.shell development-tools true 2>/dev/null || true
    fi
  fi
  if command -v dconf >/dev/null 2>&1; then
    dconf write /org/gnome/shell/development-tools true 2>/dev/null || true
  fi
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
  local out
  out="$(gdbus call --session \
    --dest org.gnome.Shell \
    --object-path /org/gnome/Shell \
    --method org.gnome.Shell.Eval \
    "$js" 2>/dev/null || true)"
  if [[ -z "$out" || "$out" == *"(false,"* ]]; then
    ensure_shell_eval_enabled
    out="$(gdbus call --session \
      --dest org.gnome.Shell \
      --object-path /org/gnome/Shell \
      --method org.gnome.Shell.Eval \
      "$js" 2>/dev/null || true)"
  fi
  printf '%s' "$out"
}

PARITY_BUS="org.gnome.Shell"
PARITY_OBJ="/org/kenan/GnomeNiriParity"
PARITY_IFACE="org.kenan.GnomeNiriParity"
PARITY_AVAILABLE=""
PARITY_LAST_ERR=""

parity_extension_dir() {
  local data_home="${XDG_DATA_HOME:-$HOME/.local/share}"
  printf '%s' "$data_home/gnome-shell/extensions/$PARITY_UUID"
}

parity_try_enable_extension() {
  command -v gnome-extensions >/dev/null 2>&1 || return 1
  local dir
  dir="$(parity_extension_dir)"
  [[ -d "$dir" ]] || return 1
  gnome-extensions enable "$PARITY_UUID" >/dev/null 2>&1 || true
  return 0
}

parity_available() {
  if [[ "$PARITY_AVAILABLE" == "1" ]]; then
    return 0
  fi
  if [[ "$PARITY_AVAILABLE" == "0" ]]; then
    return 1
  fi

  local out=""
  out="$(gdbus call --session \
    --dest "$PARITY_BUS" \
    --object-path "$PARITY_OBJ" \
    --method "${PARITY_IFACE}.Ping" 2>&1 || true)"
  if [[ -n "$out" && "$out" != Error* && "$out" != *"Error:"* && "$out" == *"pong"* ]]; then
    PARITY_AVAILABLE="1"
    return 0
  fi

  PARITY_LAST_ERR="$out"
  parity_try_enable_extension || true

  out="$(gdbus call --session \
    --dest "$PARITY_BUS" \
    --object-path "$PARITY_OBJ" \
    --method "${PARITY_IFACE}.Ping" 2>&1 || true)"
  if [[ -n "$out" && "$out" != Error* && "$out" != *"Error:"* && "$out" == *"pong"* ]]; then
    PARITY_AVAILABLE="1"
    return 0
  fi

  PARITY_LAST_ERR="$out"
  PARITY_AVAILABLE="0"
  return 1
}

parity_call() {
  local method="$1"
  shift || true
  gdbus call --session \
    --dest "$PARITY_BUS" \
    --object-path "$PARITY_OBJ" \
    --method "${PARITY_IFACE}.${method}" \
    "$@" 2>&1 || true
}

pid_file_for_app() {
  local app="$1"

  case "$app" in
    Kenp) printf '%s' "/tmp/semsumo/brave-kenp.pid" ;;
    Ai) printf '%s' "/tmp/semsumo/brave-ai.pid" ;;
    CompecTA) printf '%s' "/tmp/semsumo/brave-compecta.pid" ;;
    brave-youtube.com__-Default) printf '%s' "/tmp/semsumo/brave-youtube.pid" ;;
    TmuxKenp|Tmux) printf '%s' "/tmp/semsumo/kkenp.pid" ;;
    WebCord) printf '%s' "/tmp/semsumo/webcord.pid" ;;
    spotify|Spotify) printf '%s' "/tmp/semsumo/spotify.pid" ;;
    ferdium|Ferdium) printf '%s' "/tmp/semsumo/ferdium.pid" ;;
    *) return 1 ;;
  esac
}

read_live_pid() {
  local pid_file="$1"
  local pid=""

  [[ -n "$pid_file" && -f "$pid_file" ]] || return 1
  pid="$(tr -d '[:space:]' <"$pid_file" 2>/dev/null || true)"
  [[ "$pid" =~ ^[0-9]+$ ]] || return 1
  kill -0 "$pid" 2>/dev/null || return 1
  printf '%s' "$pid"
}

gnome_move_here_pid() {
  local pid_raw="$1"
  if parity_available; then
    local out
    out="$(parity_call MoveHerePid "$pid_raw")"
    if [[ -z "$out" || "$out" == Error* || "$out" == *"Error:"* ]]; then
      PARITY_LAST_ERR="$out"
      echo "__GNOME_SET_BACKEND_FAILED__"
      return 0
    fi
    printf '%s' "$out"
    return 0
  fi

  local pid
  pid="$(js_escape "$pid_raw")"

  local js
  local out
  js="$(cat <<EOF
(function () {
  const wantPid = parseInt("${pid}", 10);
  if (!wantPid || isNaN(wantPid)) return "__GNOME_SET_BAD_PID__";

  const wins = global.get_window_actors().map(a => a.meta_window).filter(w => w);
  const activeWs = global.workspace_manager.get_active_workspace();

  function wpid(w) { try { return w.get_pid ? w.get_pid() : 0; } catch (e) { return 0; } }
  function samePid(w) { return wpid(w) === wantPid; }

  let win =
    wins.find(w => samePid(w) && w.get_workspace && w.get_workspace() === activeWs) ||
    wins.find(w => samePid(w));

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

  out="$(gnome_eval "$js" || true)"
  if [[ -z "$out" || "$out" == *"(false,"* ]]; then
    echo "__GNOME_SET_BACKEND_FAILED__"
    return 0
  fi
  printf '%s' "$out"
}

gnome_move_here() {
  local target_raw="$1"
  if parity_available; then
    local out
    out="$(parity_call MoveHere "$target_raw")"
    if [[ -z "$out" || "$out" == Error* || "$out" == *"Error:"* ]]; then
      PARITY_LAST_ERR="$out"
      echo "__GNOME_SET_BACKEND_FAILED__"
      return 0
    fi
    printf '%s' "$out"
    return 0
  fi

  local target
  target="$(js_escape "$target_raw")"

  local js
  local out
  js="$(cat <<EOF
(function () {
  const Shell = imports.gi.Shell;
  const GLib = imports.gi.GLib;

  const target = "${target}";
  const targetDesktop = target.endsWith(".desktop") ? target : (target + ".desktop");

  function norm(s) { return (s || "").toString(); }
  function eqi(a, b) { return norm(a).toLowerCase() === norm(b).toLowerCase(); }

  const tracker = Shell.WindowTracker.get_default();
  const wins = global.get_window_actors().map(a => a.meta_window).filter(w => w);
  const activeWs = global.workspace_manager.get_active_workspace();

  const cmdCache = {};

  function bytesToString(bytes) {
    if (!bytes) return "";

    try {
      if (typeof TextDecoder !== "undefined") {
        return (new TextDecoder("utf-8")).decode(bytes);
      }
    } catch (e) {}

    try {
      const ByteArray = imports.byteArray;
      if (ByteArray && typeof ByteArray.toString === "function") {
        return ByteArray.toString(bytes);
      }
    } catch (e) {}

    try {
      let s = "";
      for (let i = 0; i < bytes.length; i++) s += String.fromCharCode(bytes[i]);
      return s;
    } catch (e) {}

    return "";
  }

  function getPid(w) {
    try { return w.get_pid ? (w.get_pid() || 0) : 0; } catch (e) { return 0; }
  }

  function cmdlineForPid(pid) {
    if (!pid) return "";
    const key = pid.toString();
    if (cmdCache[key] !== undefined) return cmdCache[key];

    try {
      const path = "/proc/" + key + "/cmdline";
      const res = GLib.file_get_contents(path);
      const ok = res[0];
      const bytes = res[1];
      if (!ok || !bytes) {
        cmdCache[key] = "";
        return cmdCache[key];
      }
      cmdCache[key] = bytesToString(bytes).replace(/\\0/g, " ");
      return cmdCache[key];
    } catch (e) {
      cmdCache[key] = "";
      return cmdCache[key];
    }
  }

  function cmdlineMatchesTarget(w) {
    const pid = getPid(w);
    if (!pid) return false;
    const cmd = cmdlineForPid(pid).toLowerCase();
    if (!cmd) return false;

    const t = target.toLowerCase();
    const home = GLib.get_home_dir().toLowerCase();
    const isolated = home + "/.brave/isolated/" + t;

    if (t.length >= 4) {
      const tokens = cmd.split(/\\s+/).filter(s => s && s.length);
      for (const tok of tokens) {
        if (tok === t) return true;
        if (tok.endsWith("/" + t)) return true;
      }
    }

    return (
      cmd.includes("--class=" + t) ||
      cmd.includes("--class " + t) ||
      cmd.includes("--name=" + t) ||
      cmd.includes("--name " + t) ||
      cmd.includes("--user-data-dir=" + isolated) ||
      cmd.includes("--user-data-dir " + isolated)
    );
  }

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
      eqi(p.appId, targetDesktop) ||
      cmdlineMatchesTarget(w)
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

  out="$(gnome_eval "$js" || true)"
  if [[ -z "$out" || "$out" == *"(false,"* ]]; then
    echo "__GNOME_SET_BACKEND_FAILED__"
    return 0
  fi
  printf '%s' "$out"
}

keys_for_app() {
  local app="$1"

  case "$app" in
    Kenp)
      cat <<'EOF'
Kenp
brave-kenp
EOF
      ;;
    Ai)
      cat <<'EOF'
Ai
brave-ai
EOF
      ;;
    CompecTA)
      cat <<'EOF'
CompecTA
brave-compecta
EOF
      ;;
    TmuxKenp|Tmux)
      cat <<'EOF'
TmuxKenp
kitty
EOF
      ;;
    WebCord)
      cat <<'EOF'
WebCord
webcord
EOF
      ;;
    brave-youtube.com__-Default)
      cat <<'EOF'
brave-youtube.com__-Default
brave-youtube
EOF
      ;;
    spotify|Spotify)
      cat <<'EOF'
spotify
Spotify
EOF
      ;;
    org.telegram.desktop|org.telegram.desktop.desktop|TelegramDesktop|telegram-desktop|Telegram)
      cat <<'EOF'
org.telegram.desktop
org.telegram.desktop.desktop
telegram-desktop
Telegram
EOF
      ;;
    ferdium|Ferdium)
      cat <<'EOF'
ferdium
Ferdium
EOF
      ;;
    *)
      printf '%s\n' "$app"
      ;;
  esac
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
  local backend_failed=0

  # 1) Prefer PID match (Wayland-safe) to avoid spawning a new window
  if pid_file="$(pid_file_for_app "$app" 2>/dev/null || true)"; then
    if pid="$(read_live_pid "$pid_file" 2>/dev/null || true)"; then
      out="$(gnome_move_here_pid "$pid" || true)"
      if [[ "$out" == *"__GNOME_SET_BACKEND_FAILED__"* ]]; then
        backend_failed=1
      elif [[ "$out" == *"__GNOME_SET_OK__"* ]]; then
        return 0
      fi
    fi
  fi

  # 2) Try known key aliases (wm_class / appId / etc.)
  while IFS= read -r key; do
    [[ -n "$key" ]] || continue
    out="$(gnome_move_here "$key" || true)"
    if [[ "$out" == *"__GNOME_SET_BACKEND_FAILED__"* ]]; then
      backend_failed=1
      continue
    fi
    if [[ "$out" == *"__GNOME_SET_OK__"* ]]; then
      return 0
    fi
  done < <(keys_for_app "$app")

  # Not running: launch then pull it here (best-effort).
  launch_for_app "$app" || return 1

  for _ in {1..40}; do
    if pid_file="$(pid_file_for_app "$app" 2>/dev/null || true)"; then
      if pid="$(read_live_pid "$pid_file" 2>/dev/null || true)"; then
        out="$(gnome_move_here_pid "$pid" || true)"
        if [[ "$out" == *"__GNOME_SET_BACKEND_FAILED__"* ]]; then
          backend_failed=1
        elif [[ "$out" == *"__GNOME_SET_OK__"* ]]; then
          return 0
        fi
      fi
    fi

    while IFS= read -r key; do
      [[ -n "$key" ]] || continue
      out="$(gnome_move_here "$key" || true)"
      if [[ "$out" == *"__GNOME_SET_BACKEND_FAILED__"* ]]; then
        backend_failed=1
        continue
      fi
      if [[ "$out" == *"__GNOME_SET_OK__"* ]]; then
        return 0
      fi
    done < <(keys_for_app "$app")
    sleep 0.1
  done

  if [[ "$backend_failed" == "1" ]]; then
    hint="Enable extension: gnome-extensions enable ${PARITY_UUID} (then logout/login if needed)"
    [[ -n "$PARITY_LAST_ERR" ]] && hint="${hint}; last error: ${PARITY_LAST_ERR}"
    die "GNOME backend not available for '$app'. ${hint}"
  fi

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
    if parity_available; then
      parity_call Go >/dev/null 2>&1 || true
      exit 0
    fi

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
