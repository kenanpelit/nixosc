#!/usr/bin/env bash
# ==============================================================================
# osc-ndrop.sh - Toggle a "drop-down" style window (Niri + Hyprland + GNOME)
# ==============================================================================
# Features (ndrop/tdrop-like):
# - If the program is not running: launch it and bring it to the foreground.
# - If it is running on another workspace: bring it to the current workspace
#   and focus it (default), or switch to its workspace and focus it (--focus).
# - If it is running on the current workspace: hide it (default), or just focus
#   it (--focus).
#
# Matching:
# - Default match key is the command name (first word).
# - Can extract app-id/class from the command line:
#   - foot: -a/--app-id
#   - others: --class
# - Override with: -c/--class <CLASS>
#
# Backend detection:
# - Auto-detects Niri (niri msg), Hyprland (hyprctl), or GNOME (gdbus + org.gnome.Shell).
#
# Environment:
# - OSC_NDROP_NIRI_HIDE_WORKSPACE  (default: oscndrop; workspace used to hide windows on Niri)
# - OSC_NDROP_HYPR_HIDE_SPECIAL    (default: oscndrop)
# - OSC_NDROP_ONLINE_HOST          (default: github.com)
# - OSC_NDROP_ONLINE_TIMEOUT       (default: 20 seconds)
# ==============================================================================

set -euo pipefail

# Debug: `OSC_NDROP_DEBUG=1 osc-ndrop ...`
if [[ "${OSC_NDROP_DEBUG:-0}" == "1" ]]; then
  set -x
fi

SCRIPT_NAME="${0##*/}"
VERSION="0.1.0"

print_help() {
  cat <<EOF
${SCRIPT_NAME} v${VERSION}

Usage:
  ${SCRIPT_NAME} [OPTIONS] <command...>

Options:
  -c, --class <CLASS>     Override class/app-id used for matching
  -F, --focus             Focus-only mode (never hide; switch to its workspace)
  -i, --insensitive       Case-insensitive partial matching
  -o, --online            Wait for internet connectivity before first launch
  -v, --verbose           Show notifications (if notify-send is available)
  -H, --help              Show help
  -V, --version           Show version

Backend options:
      --backend <auto|niri|hyprland|gnome>
      --niri-hide-workspace <index|name>   (default: \$OSC_NDROP_NIRI_HIDE_WORKSPACE or "oscndrop")
      --hypr-hide-special <name>           (default: \$OSC_NDROP_HYPR_HIDE_SPECIAL or "oscndrop")

Examples:
  # Dropdown terminal (kitty)
  ${SCRIPT_NAME} kitty --class dropdown-terminal

  # Two independent instances
  ${SCRIPT_NAME} kitty --class kitty_1
  ${SCRIPT_NAME} kitty --class kitty_2
EOF
}

print_version() {
  echo "${SCRIPT_NAME} v${VERSION}"
}

notify() {
  local title="$1"
  local body="$2"
  local urgency="${3:-normal}"
  if command -v notify-send >/dev/null 2>&1; then
    notify-send -u "$urgency" -t 1500 "$title" "$body" >/dev/null 2>&1 || true
  fi
}

die() {
  echo "Error: $*" >&2
  exit 1
}

regex_escape() {
  local s="$1"
  s="$(printf '%s' "$s" | sed -e 's/[][\\.^$*+?(){}|]/\\&/g')"
  printf '%s' "$s"
}

js_escape() {
  local s="$1"
  s="${s//\\/\\\\}"
  s="${s//\"/\\\"}"
  s="${s//$'\n'/\\n}"
  printf '%s' "$s"
}

wait_online() {
  local host="$1"
  local timeout_s="$2"
  local i=0

  while ((i < timeout_s * 10)); do
    if ping -qc 1 -W 1 "$host" >/dev/null 2>&1; then
      return 0
    fi
    sleep 0.1
    ((i++))
  done

  return 1
}

FOCUS=false
INSENSITIVE=false
ONLINE=false
VERBOSE=false

BACKEND="auto"
NIRI_HIDE_WORKSPACE="${OSC_NDROP_NIRI_HIDE_WORKSPACE:-oscndrop}"
HYPR_HIDE_SPECIAL="${OSC_NDROP_HYPR_HIDE_SPECIAL:-oscndrop}"
ONLINE_HOST="${OSC_NDROP_ONLINE_HOST:-github.com}"
ONLINE_TIMEOUT="${OSC_NDROP_ONLINE_TIMEOUT:-20}"

CLASS_OVERRIDE=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    -c | --class)
      shift
      CLASS_OVERRIDE="${1:-}"
      [[ -n "$CLASS_OVERRIDE" ]] || die "--class requires a value"
      shift
      ;;
    -F | --focus)
      FOCUS=true
      shift
      ;;
    -i | --insensitive)
      INSENSITIVE=true
      shift
      ;;
    -o | --online)
      ONLINE=true
      shift
      ;;
    -v | --verbose)
      VERBOSE=true
      shift
      ;;
    --backend)
      shift
      BACKEND="${1:-}"
      [[ -n "$BACKEND" ]] || die "--backend requires a value"
      shift
      ;;
    --niri-hide-workspace)
      shift
      NIRI_HIDE_WORKSPACE="${1:-}"
      [[ -n "$NIRI_HIDE_WORKSPACE" ]] || die "--niri-hide-workspace requires a value"
      shift
      ;;
    --hypr-hide-special)
      shift
      HYPR_HIDE_SPECIAL="${1:-}"
      [[ -n "$HYPR_HIDE_SPECIAL" ]] || die "--hypr-hide-special requires a value"
      shift
      ;;
    -H | --help)
      print_help
      exit 0
      ;;
    -V | --version)
      print_version
      exit 0
      ;;
    --)
      shift
      break
      ;;
    -*)
      die "Unknown option: $1"
      ;;
    *)
      break
      ;;
  esac
done

[[ $# -gt 0 ]] || die "Missing command. Try '${SCRIPT_NAME} --help'"

COMMANDLINE=("$@")
COMMAND="${COMMANDLINE[0]}"

CLASS="$COMMAND"

# Common hardcoded mappings (mostly aligned with upstream ndrop)
case "$COMMAND" in
  epiphany) CLASS="org.gnome.Epiphany" ;;
  brave) CLASS="brave-browser" ;;
  godot4)
    CLASS="org.godotengine."
    INSENSITIVE=true
    ;;
  logseq) CLASS="Logseq" ;;
  telegram-desktop) CLASS="org.telegram.desktop" ;;
  tor-browser) CLASS="Tor Browser" ;;
esac

# Extract class/app-id from the command line when possible (multiple instances).
if [[ "$COMMAND" == "foot" ]]; then
  for ((i = 1; i < ${#COMMANDLINE[@]}; i++)); do
    case "${COMMANDLINE[i]}" in
      -a | --app-id)
        if ((i + 1 < ${#COMMANDLINE[@]})); then
          CLASS="${COMMANDLINE[i + 1]}"
        fi
        ;;
    esac
  done
else
  for ((i = 1; i < ${#COMMANDLINE[@]}; i++)); do
    case "${COMMANDLINE[i]}" in
      --class)
        if ((i + 1 < ${#COMMANDLINE[@]})); then
          CLASS="${COMMANDLINE[i + 1]}"
        fi
        ;;
    esac
  done
fi

if [[ -n "$CLASS_OVERRIDE" ]]; then
  CLASS="$CLASS_OVERRIDE"
fi

detect_backend() {
  local requested="$1"

  case "$requested" in
    niri | hyprland | gnome)
      echo "$requested"
      return 0
      ;;
    auto) ;;
    *) die "Invalid backend: $requested (expected: auto|niri|hyprland|gnome)" ;;
  esac

  if command -v niri >/dev/null 2>&1 && niri msg -j workspaces >/dev/null 2>&1; then
    echo "niri"
    return 0
  fi

  if command -v hyprctl >/dev/null 2>&1 && hyprctl version >/dev/null 2>&1; then
    echo "hyprland"
    return 0
  fi

  if command -v gdbus >/dev/null 2>&1; then
    if gdbus call --session \
      --dest org.freedesktop.DBus \
      --object-path /org/freedesktop/DBus \
      --method org.freedesktop.DBus.NameHasOwner \
      org.gnome.Shell 2>/dev/null | grep -q "true"; then
      echo "gnome"
      return 0
    fi
  fi

  die "Could not detect backend (need niri, hyprctl, or GNOME Shell)"
}

launch_command() {
  if $ONLINE; then
    if ! wait_online "$ONLINE_HOST" "$ONLINE_TIMEOUT"; then
      $VERBOSE && notify "osc-ndrop" "Online check timed out, launching anyway." "low"
    fi
  fi

  $VERBOSE && notify "osc-ndrop" "Launching: ${COMMANDLINE[*]}" "low"

  "${COMMANDLINE[@]}" &
  disown || true
}

niri_toggle() {
  command -v jq >/dev/null 2>&1 || { launch_command; return 0; }
  local has_nirius=false
  if command -v nirius >/dev/null 2>&1; then
    has_nirius=true
  fi

  local windows workspaces current_ws_id current_ws_ref
  windows="$(niri msg -j windows 2>/dev/null || echo '[]')"
  workspaces="$(niri msg -j workspaces 2>/dev/null || echo '[]')"

  current_ws_id="$(
    echo "$workspaces" | jq -r 'first(.[] | select(.is_focused==true) | .id) // empty'
  )"

  current_ws_ref="$(
    echo "$workspaces" | jq -r 'first(.[] | select(.is_focused==true) | .idx) // empty'
  )"

  if [[ -z "$current_ws_id" || -z "$current_ws_ref" ]]; then
    launch_command
    return 0
  fi

  local insensitive_json=false
  $INSENSITIVE && insensitive_json=true

  local app_id_re
  if $INSENSITIVE; then
    app_id_re="(?i)$(regex_escape "$CLASS")"
  else
    app_id_re="^$(regex_escape "$CLASS")$"
  fi

  # Prefer a match on the current workspace.
  local window_id_here
  window_id_here="$(
    echo "$windows" \
      | jq -r --arg cls "$CLASS" --arg ws "$current_ws_id" --argjson insensitive "$insensitive_json" '
          first(
            .[]
            | select(if $insensitive
                then ((.app_id // "") | test($cls; "i"))
                else ((.app_id // "") == $cls)
              end)
            | select((.workspace_id|tostring) == ($ws|tostring))
            | .id
          ) // empty
        '
  )"

  if [[ -n "$window_id_here" ]]; then
    if $FOCUS; then
      niri msg action focus-window --id "$window_id_here" >/dev/null 2>&1 || true
      $VERBOSE && notify "Niri" "Focused: ${CLASS}" "low"
      return 0
    fi

    if $has_nirius; then
      # Hide using nirius scratchpad (stays on current workspace).
      niri msg action focus-window --id "$window_id_here" >/dev/null 2>&1 || true
      nirius scratchpad-toggle --app-id "$app_id_re" --workspace-id "$current_ws_id" >/dev/null 2>&1 || true
    else
      # Hide by moving to a dedicated workspace (does not follow focus).
      niri msg action move-window-to-workspace --window-id "$window_id_here" --focus false "$NIRI_HIDE_WORKSPACE" >/dev/null 2>&1 || true
    fi

    $VERBOSE && notify "Niri" "Hidden: ${CLASS}" "low"
  return 0
  fi

  # Otherwise, pick any match and bring/focus it.
  local window_id_any
  window_id_any="$(
    echo "$windows" \
      | jq -r --arg cls "$CLASS" --argjson insensitive "$insensitive_json" '
          first(
            .[]
            | select(if $insensitive
                then ((.app_id // "") | test($cls; "i"))
                else ((.app_id // "") == $cls)
              end)
            | .id
          ) // empty
        '
  )"

  if [[ -z "$window_id_any" ]]; then
    launch_command
    return 0
  fi

  if $FOCUS; then
    niri msg action focus-window --id "$window_id_any" >/dev/null 2>&1 || true
    $VERBOSE && notify "Niri" "Focused: ${CLASS}" "low"
    return 0
  fi

  if $has_nirius; then
    # Show from scratchpad first (if applicable).
    if nirius scratchpad-show --app-id "$app_id_re" >/dev/null 2>&1; then
      $VERBOSE && notify "Niri" "Shown: ${CLASS}" "low"
      return 0
    fi

    # Bring it from any unfocused workspace (including a hide workspace).
    if nirius move-to-current-workspace --app-id "$app_id_re" --focus >/dev/null 2>&1; then
      $VERBOSE && notify "Niri" "Moved here: ${CLASS}" "low"
      return 0
    fi
  fi

  niri msg action move-window-to-workspace --window-id "$window_id_any" --focus false "$current_ws_ref" >/dev/null 2>&1 || true
  niri msg action focus-window --id "$window_id_any" >/dev/null 2>&1 || true
  $VERBOSE && notify "Niri" "Moved here: ${CLASS}" "low"
}

hypr_special_visible() {
  local name="$1"
  command -v jq >/dev/null 2>&1 || return 1

  local want1="special:${name}"
  local want2="${name}"

  hyprctl monitors -j 2>/dev/null \
    | jq -e --arg w1 "$want1" --arg w2 "$want2" '
        any(.[]; (.specialWorkspace.name // "") == $w1 or (.specialWorkspace.name // "") == $w2)
      ' >/dev/null 2>&1
}

hypr_toggle() {
  command -v jq >/dev/null 2>&1 || { launch_command; return 0; }

  local clients current_ws_id active_addr
  clients="$(hyprctl clients -j 2>/dev/null || echo '[]')"

  current_ws_id="$(
    hyprctl activeworkspace -j 2>/dev/null | jq -r '.id // empty' || true
  )"
  if [[ -z "$current_ws_id" || "$current_ws_id" == "null" ]]; then
    current_ws_id="-1"
  fi

  active_addr="$(
    hyprctl activewindow -j 2>/dev/null | jq -r '.address // empty' || true
  )"

  local insensitive_json=false
  $INSENSITIVE && insensitive_json=true

  local special_target="special:${HYPR_HIDE_SPECIAL}"
  local special_visible=false
  if hypr_special_visible "$HYPR_HIDE_SPECIAL"; then
    special_visible=true
  fi

  hypr_find_matching_window() {
    local clients_json="$1"
    local only_workspace_name="${2:-}"

    if [[ -n "$only_workspace_name" ]]; then
      echo "$clients_json" | jq -r --arg cls "$CLASS" --arg ws "$only_workspace_name" --argjson insensitive "$insensitive_json" '
          first(
            .[]
            | select(if $insensitive
                then (((.class // "") | test($cls; "i")) or ((.initialClass // "") | test($cls; "i")))
                else (((.class // "") == $cls) or ((.initialClass // "") == $cls))
              end)
            | select((.workspace.name // "") == $ws)
            | [.address, (.workspace.name // ""), (.workspace.id // "")]
          ) // empty
          | @tsv
        '
      return 0
    fi

    echo "$clients_json" | jq -r --arg cls "$CLASS" --argjson insensitive "$insensitive_json" '
        first(
          .[]
          | select(if $insensitive
              then (((.class // "") | test($cls; "i")) or ((.initialClass // "") | test($cls; "i")))
              else (((.class // "") == $cls) or ((.initialClass // "") == $cls))
            end)
          | [.address, (.workspace.name // ""), (.workspace.id // "")]
        ) // empty
        | @tsv
      '
  }

  hypr_wait_for_window() {
    local tries="${1:-30}"
    local delay_s="${2:-0.1}"
    local i

    for ((i = 0; i < tries; i++)); do
      local snapshot
      snapshot="$(hyprctl clients -j 2>/dev/null || echo '[]')"

      local found
      found="$(hypr_find_matching_window "$snapshot")"
      if [[ -n "$found" ]]; then
        printf '%s\n' "$found"
        return 0
      fi

      sleep "$delay_s"
    done

    return 1
  }

  # If the window lives in a dedicated special workspace, toggle that like a scratchpad.
  local addr_special
  read -r addr_special _ < <(hypr_find_matching_window "$clients" "$special_target") || true

  if [[ -n "${addr_special:-}" ]]; then
    if ! $special_visible; then
      hyprctl dispatch togglespecialworkspace "$HYPR_HIDE_SPECIAL" >/dev/null 2>&1 || true
    fi

    if ! $FOCUS && $special_visible && [[ "${active_addr:-}" == "${addr_special}" ]]; then
      hyprctl dispatch togglespecialworkspace "$HYPR_HIDE_SPECIAL" >/dev/null 2>&1 || true
      $VERBOSE && notify "Hyprland" "Hidden: ${CLASS}" "low"
      return 0
    fi

    hyprctl dispatch focuswindow "address:${addr_special}" >/dev/null 2>&1 || true
    $VERBOSE && notify "Hyprland" "Focused: ${CLASS}" "low"
    return 0
  fi

  # Prefer a match on the current workspace.
  local addr_here
  addr_here="$(
    echo "$clients" \
      | jq -r --arg cls "$CLASS" --arg ws "$current_ws_id" --argjson insensitive "$insensitive_json" '
          first(
            .[]
            | select(if $insensitive
                then (((.class // "") | test($cls; "i")) or ((.initialClass // "") | test($cls; "i")))
                else (((.class // "") == $cls) or ((.initialClass // "") == $cls))
              end)
            | select((.workspace.id|tostring) == ($ws|tostring))
            | .address
          ) // empty
        '
  )"

  if [[ -n "${addr_here:-}" ]]; then
    if $FOCUS; then
      hyprctl dispatch focuswindow "address:${addr_here}" >/dev/null 2>&1 || true
      $VERBOSE && notify "Hyprland" "Focused: ${CLASS}" "low"
      return 0
    fi

    local was_visible=false
    if hypr_special_visible "$HYPR_HIDE_SPECIAL"; then
      was_visible=true
    fi

    hyprctl dispatch movetoworkspacesilent "special:${HYPR_HIDE_SPECIAL},address:${addr_here}" >/dev/null 2>&1 || true
    $VERBOSE && notify "Hyprland" "Hidden: ${CLASS}" "low"

    if $was_visible; then
      hyprctl dispatch togglespecialworkspace "$HYPR_HIDE_SPECIAL" >/dev/null 2>&1 || true
    fi

    if [[ -n "${active_addr:-}" && "${active_addr}" != "null" ]]; then
      hyprctl dispatch focuswindow "address:${active_addr}" >/dev/null 2>&1 || true
    fi
    return 0
  fi

  # Otherwise, pick any match.
  local addr_any ws_name_any ws_id_any
  read -r addr_any ws_name_any ws_id_any < <(hypr_find_matching_window "$clients") || true

  if [[ -z "${addr_any:-}" ]]; then
    launch_command

    # Best-effort: wait briefly and then focus/show the launched window.
    local launched
    if launched="$(hypr_wait_for_window 30 0.1)"; then
      local addr_new ws_name_new
      read -r addr_new ws_name_new _ <<<"$launched"

      if [[ -n "${addr_new:-}" ]]; then
        if [[ "${ws_name_new:-}" == "$special_target" ]]; then
          if ! hypr_special_visible "$HYPR_HIDE_SPECIAL"; then
            hyprctl dispatch togglespecialworkspace "$HYPR_HIDE_SPECIAL" >/dev/null 2>&1 || true
          fi
          hyprctl dispatch focuswindow "address:${addr_new}" >/dev/null 2>&1 || true
        elif [[ -n "${current_ws_id}" && "${current_ws_id}" != "-1" ]]; then
          hyprctl dispatch movetoworkspace "${current_ws_id},address:${addr_new}" >/dev/null 2>&1 || true
          hyprctl dispatch focuswindow "address:${addr_new}" >/dev/null 2>&1 || true
        else
          hyprctl dispatch focuswindow "address:${addr_new}" >/dev/null 2>&1 || true
        fi
      fi
    fi

    return 0
  fi

  if $FOCUS; then
    if [[ "${ws_name_any:-}" == special:* ]]; then
      if [[ "${ws_name_any}" == "$special_target" ]] && ! hypr_special_visible "$HYPR_HIDE_SPECIAL"; then
        hyprctl dispatch togglespecialworkspace "$HYPR_HIDE_SPECIAL" >/dev/null 2>&1 || true
      fi
      hyprctl dispatch focuswindow "address:${addr_any}" >/dev/null 2>&1 || true
      $VERBOSE && notify "Hyprland" "Focused (special): ${CLASS}" "low"
      return 0
    fi

    if [[ -n "${ws_id_any:-}" && "${ws_id_any}" != "null" ]]; then
      hyprctl dispatch workspace "${ws_id_any}" >/dev/null 2>&1 || true
    fi
    hyprctl dispatch focuswindow "address:${addr_any}" >/dev/null 2>&1 || true
    $VERBOSE && notify "Hyprland" "Focused: ${CLASS}" "low"
    return 0
  fi

  if [[ "$current_ws_id" != "-1" ]]; then
    hyprctl dispatch movetoworkspace "${current_ws_id},address:${addr_any}" >/dev/null 2>&1 || true
  fi
  hyprctl dispatch focuswindow "address:${addr_any}" >/dev/null 2>&1 || true
  $VERBOSE && notify "Hyprland" "Moved here: ${CLASS}" "low"
}

gnome_eval() {
  local js="$1"
  command -v gdbus >/dev/null 2>&1 || return 1
  gdbus call --session \
    --dest org.gnome.Shell \
    --object-path /org/gnome/Shell \
    --method org.gnome.Shell.Eval \
    "$js" 2>/dev/null
}

gnome_toggle() {
  command -v gdbus >/dev/null 2>&1 || { launch_command; return 0; }

  local target insensitive_js focus_js js out
  target="$(js_escape "$CLASS")"

  insensitive_js=false
  $INSENSITIVE && insensitive_js=true

  focus_js=false
  $FOCUS && focus_js=true

  js="$(cat <<EOF
(function () {
  const Shell = imports.gi.Shell;

  const target = "${target}";
  const insensitive = ${insensitive_js};
  const focusOnly = ${focus_js};

  function norm(s) { return (s || "").toString(); }
  function same(a, b) {
    a = norm(a);
    b = norm(b);
    if (insensitive) return a.toLowerCase().includes(b.toLowerCase());
    return a === b;
  }

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
    return same(p.cls, target) || same(p.inst, target) || same(p.appId, target);
  }

  const activeWs = global.workspace_manager.get_active_workspace();
  let win =
    wins.find(w => matches(w) && w.get_workspace && w.get_workspace() === activeWs) ||
    wins.find(w => matches(w));

  if (!win) return "__OSC_NDROP_NOT_FOUND__";

  const isMin = !!win.minimized;

  if (focusOnly) {
    try {
      const ws = win.get_workspace ? win.get_workspace() : null;
      if (ws && ws !== activeWs && ws.activate) ws.activate(global.get_current_time());
    } catch (e) {}
    try { if (isMin && win.unminimize) win.unminimize(); } catch (e) {}
    try { if (win.activate) win.activate(global.get_current_time()); } catch (e) {}
    return "__OSC_NDROP_FOCUSED__";
  }

  // Default: toggle minimize on current workspace; otherwise move here + focus.
  try {
    const ws = win.get_workspace ? win.get_workspace() : null;
    if (ws && ws !== activeWs && win.change_workspace) win.change_workspace(activeWs);
  } catch (e) {}

  try {
    if (isMin) {
      if (win.unminimize) win.unminimize();
      if (win.activate) win.activate(global.get_current_time());
      return "__OSC_NDROP_SHOWN__";
    }
    if (win.minimize) win.minimize();
    return "__OSC_NDROP_HIDDEN__";
  } catch (e) {
    return "__OSC_NDROP_ERROR__:" + e;
  }
})();
EOF
)"

  out="$(gnome_eval "$js" || true)"
  if [[ -z "$out" || "$out" == *"(false,"* ]]; then
    $VERBOSE && notify "GNOME" "Eval failed, launching: ${CLASS}" "low"
    launch_command
    return 0
  fi

  if [[ "$out" == *"__OSC_NDROP_NOT_FOUND__"* ]]; then
    launch_command
    return 0
  fi

  if [[ "$out" == *"__OSC_NDROP_ERROR__"* ]]; then
    $VERBOSE && notify "GNOME" "osc-ndrop error: ${CLASS}" "low"
    return 1
  fi

  if $VERBOSE; then
    if [[ "$out" == *"__OSC_NDROP_HIDDEN__"* ]]; then
      notify "GNOME" "Hidden: ${CLASS}" "low"
    elif [[ "$out" == *"__OSC_NDROP_SHOWN__"* ]]; then
      notify "GNOME" "Shown: ${CLASS}" "low"
    elif [[ "$out" == *"__OSC_NDROP_FOCUSED__"* ]]; then
      notify "GNOME" "Focused: ${CLASS}" "low"
    else
      notify "GNOME" "Toggled: ${CLASS}" "low"
    fi
  fi
}

backend="$(detect_backend "$BACKEND")"

case "$backend" in
  niri) niri_toggle ;;
  hyprland) hypr_toggle ;;
  gnome) gnome_toggle ;;
  *) die "Internal error: unknown backend '$backend'" ;;
esac
