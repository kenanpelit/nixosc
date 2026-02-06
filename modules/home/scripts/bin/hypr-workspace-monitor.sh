#!/usr/bin/env bash
# hypr-workspace-monitor - workspace/monitor/window helper for Hyprland
# Compatible target for `hypr-set workspace-monitor` callers.

set -euo pipefail

STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/hypr-workspace-monitor"
CURRENT_WS_FILE="${STATE_DIR}/current_workspace"
PREVIOUS_WS_FILE="${STATE_DIR}/previous_workspace"

ensure_state_dir() {
  mkdir -p "${STATE_DIR}"
}

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "hypr-workspace-monitor: missing dependency: $1" >&2
    exit 127
  }
}

usage() {
  cat <<'EOF'
Usage: hypr-workspace-monitor <option> [args...]

Common:
  -mn / -mp              focus next / previous monitor
  -ms / -msf             move current workspace to next monitor (without/with focus)
  -wu / -wd              workspace up/down (relative)
  -wl / -wr              workspace previous/next (relative)
  -wt                    toggle current/previous workspace
  -mw <ws>               move focused window to workspace

Window focus:
  -vn / -vp              cycle next / previous window
  -vl / -vr / -vu / -vd  focus left/right/up/down

Browser tabs (best effort):
  -tn / -tp              next / previous tab (wtype required)
EOF
}

current_ws_id() {
  hyprctl activeworkspace -j 2>/dev/null | jq -r '.id // empty'
}

current_ws_name() {
  hyprctl activeworkspace -j 2>/dev/null | jq -r '.name // empty'
}

record_workspace_transition() {
  local from="$1"
  local to="$2"
  ensure_state_dir
  [[ -n "${from}" ]] && printf '%s\n' "${from}" >"${PREVIOUS_WS_FILE}"
  [[ -n "${to}" ]] && printf '%s\n' "${to}" >"${CURRENT_WS_FILE}"
}

switch_workspace_relative() {
  local rel="$1"
  local before after
  before="$(current_ws_id)"
  hyprctl dispatch workspace "${rel}" >/dev/null 2>&1
  after="$(current_ws_id)"
  record_workspace_transition "${before}" "${after}"
}

switch_workspace_exact() {
  local target="$1"
  local before
  before="$(current_ws_id)"
  hyprctl dispatch workspace "${target}" >/dev/null 2>&1
  record_workspace_transition "${before}" "${target}"
}

toggle_prev_workspace() {
  local current previous
  ensure_state_dir
  current="$(current_ws_id)"
  if [[ -f "${PREVIOUS_WS_FILE}" ]]; then
    previous="$(cat "${PREVIOUS_WS_FILE}" 2>/dev/null || true)"
  else
    previous=""
  fi
  if [[ -z "${previous}" || "${previous}" == "${current}" ]]; then
    switch_workspace_relative "e-1"
    return
  fi
  switch_workspace_exact "${previous}"
}

move_focused_window_to_workspace() {
  local target_ws="$1"
  local addr
  addr="$(hyprctl activewindow -j 2>/dev/null | jq -r '.address // empty')"
  [[ -n "${addr}" ]] || return 0
  hyprctl dispatch movetoworkspace "${target_ws},address:${addr}" >/dev/null 2>&1 || true
  hyprctl dispatch focuswindow "address:${addr}" >/dev/null 2>&1 || true
}

focus_monitor() {
  local dir="$1"
  hyprctl dispatch focusmonitor "${dir}" >/dev/null 2>&1 || true
}

focus_next_prev_monitor() {
  local direction="$1"
  local current target
  current="$(hyprctl monitors -j | jq -r '.[] | select(.focused==true) | .name' | head -n1)"
  target="$(hyprctl monitors -j | jq -r --arg cur "${current}" --arg dir "${direction}" '
    [.[].name] as $m
    | ($m | length) as $len
    | if $len == 0 then ""
      else
        ($m | index($cur)) as $idx
        | if $idx == null then $m[0]
          else
            (if $dir == "next" then (($idx + 1) % $len) else (($idx - 1 + $len) % $len) end) as $n
            | $m[$n]
          end
      end
  ')"
  [[ -n "${target}" ]] || return 0
  focus_monitor "${target}"
}

send_tab() {
  local mode="$1"
  if ! command -v wtype >/dev/null 2>&1; then
    return 0
  fi
  if [[ "${mode}" == "prev" ]]; then
    wtype -P ctrl -P shift -p tab -r tab -R shift -R ctrl >/dev/null 2>&1 || true
  else
    wtype -P ctrl -p tab -r tab -R ctrl >/dev/null 2>&1 || true
  fi
}

option="${1:-}"
[[ -n "${option}" ]] || {
  usage
  exit 2
}

if [[ "${option}" == "-h" || "${option}" == "--help" ]]; then
  usage
  exit 0
fi

need_cmd hyprctl
need_cmd jq

hyprctl version >/dev/null 2>&1 || {
  echo "hypr-workspace-monitor: cannot connect to Hyprland IPC" >&2
  exit 1
}

shift || true

case "${option}" in
  -mn)
    focus_next_prev_monitor "next"
    ;;
  -mp)
    focus_next_prev_monitor "prev"
    ;;
  -ms)
    hyprctl dispatch movecurrentworkspacetomonitor +1 >/dev/null 2>&1 || true
    ;;
  -msf)
    hyprctl dispatch movecurrentworkspacetomonitor +1 >/dev/null 2>&1 || true
    hyprctl dispatch focusmonitor +1 >/dev/null 2>&1 || true
    ;;
  -wu|-wl)
    switch_workspace_relative "e-1"
    ;;
  -wd|-wr)
    switch_workspace_relative "e+1"
    ;;
  -wt)
    toggle_prev_workspace
    ;;
  -mw)
    target_ws="${1:-}"
    [[ -n "${target_ws}" ]] || {
      echo "hypr-workspace-monitor: -mw requires workspace argument" >&2
      exit 2
    }
    move_focused_window_to_workspace "${target_ws}"
    ;;
  -vn)
    hyprctl dispatch cyclenext >/dev/null 2>&1 || true
    ;;
  -vp)
    hyprctl dispatch cyclenext prev >/dev/null 2>&1 || true
    ;;
  -vl)
    hyprctl dispatch movefocus l >/dev/null 2>&1 || true
    ;;
  -vr)
    hyprctl dispatch movefocus r >/dev/null 2>&1 || true
    ;;
  -vu)
    hyprctl dispatch movefocus u >/dev/null 2>&1 || true
    ;;
  -vd)
    hyprctl dispatch movefocus d >/dev/null 2>&1 || true
    ;;
  -tn)
    send_tab "next"
    ;;
  -tp)
    send_tab "prev"
    ;;
  *)
    echo "hypr-workspace-monitor: unsupported option: ${option}" >&2
    usage
    exit 2
    ;;
esac
