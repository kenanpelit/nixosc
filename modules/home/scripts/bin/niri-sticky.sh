#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# niri-sticky
# -----------------------------------------------------------------------------
# Purpose:
# - Native sticky/stage workflow helper for Niri (no external `nsticky`).
# - Maintains sticky windows across workspace switches via daemon mode.
# - Implements stage cycle semantics: normal -> sticky -> staged -> sticky.
#
# Interface:
# - `niri-sticky sticky ...` : sticky list/state operations
# - `niri-sticky stage ...`  : stage list/state operations
# - `niri-sticky <action>`   : top-level sticky aliases (list/toggle/add/...)
# - `niri-sticky`            : daemon mode (workspace watcher)
#
# State (XDG):
# - ${XDG_STATE_HOME:-$HOME/.local/state}/niri-sticky/state.json
# - ${XDG_STATE_HOME:-$HOME/.local/state}/niri-sticky/state.lock
#
# Tunables:
# - NIRI_STICKY_POLL_INTERVAL   daemon poll interval (default: 0.35s)
# - NIRI_STICKY_STAGE_WORKSPACE stage workspace name (default: stage)
# - NIRI_STICKY_NOTIFY          1/0 enable notifications (default: 1)
# - NIRI_STICKY_NOTIFY_TIMEOUT  notify timeout ms (default: 1400)
#
# Dependencies:
# - niri
# - jq
# - flock
# -----------------------------------------------------------------------------

set -euo pipefail

VERSION="1.1.0"
STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
STATE_DIR="${STATE_HOME}/niri-sticky"
STATE_FILE="${STATE_DIR}/state.json"
LOCK_FILE="${STATE_DIR}/state.lock"
POLL_INTERVAL="${NIRI_STICKY_POLL_INTERVAL:-0.35}"
STAGE_WORKSPACE="${NIRI_STICKY_STAGE_WORKSPACE:-stage}"
NOTIFY_ENABLED="${NIRI_STICKY_NOTIFY:-1}"
NOTIFY_TIMEOUT="${NIRI_STICKY_NOTIFY_TIMEOUT:-1400}"

err() {
  printf 'Error: %s\n' "$*" >&2
  exit 1
}

info() {
  printf 'niri-sticky: %s\n' "$*" >&2
}

need_bins() {
  command -v niri >/dev/null 2>&1 || err "niri not found in PATH"
  command -v jq >/dev/null 2>&1 || err "jq not found in PATH"
  command -v flock >/dev/null 2>&1 || err "flock not found in PATH"
}

notify() {
  local urgency="${1:-low}"
  local title="${2:-Sticky}"
  local body="${3:-}"

  [[ "$NOTIFY_ENABLED" == "1" ]] || return 0
  command -v notify-send >/dev/null 2>&1 || return 0

  notify-send \
    -a "niri-sticky" \
    -u "$urgency" \
    -t "$NOTIFY_TIMEOUT" \
    -h string:x-canonical-private-synchronous:niri-sticky \
    "$title" "$body" >/dev/null 2>&1 || true
}

usage() {
  cat <<'USAGE'
niri-sticky - sticky/stage workflow helper for Niri

Usage:
  niri-sticky [daemon]
  niri-sticky sticky <action> [args]
  niri-sticky stage  <action> [args]
  niri-sticky <sticky-action> [args]

Sticky actions:
  add <window_id>
  remove <window_id>
  list
  toggle-active
  toggle-appid <app_id>
  toggle-title <title-substring>

Stage actions:
  add <window_id>
  remove <window_id>
  list
  toggle-active
  toggle-appid <app_id>
  toggle-title <title-substring>
  add-all
  remove-all

Notes:
  - No args starts daemon mode.
  - Top-level `list/add/remove/toggle-*` commands are treated as sticky actions.
  - Stage workspace defaults to "stage" and can be changed by
    NIRI_STICKY_STAGE_WORKSPACE.
USAGE
}

with_lock() {
  mkdir -p "$STATE_DIR"
  touch "$LOCK_FILE"
  (
    flock -x 9 || exit 1
    "$@"
  ) 9>"$LOCK_FILE"
}

state_update_locked() {
  local jq_program="$1"
  shift

  local tmp
  tmp="$(mktemp)"
  if jq "$@" "$jq_program" "$STATE_FILE" >"$tmp"; then
    mv "$tmp" "$STATE_FILE"
  else
    rm -f "$tmp"
    err "failed to update state"
  fi
}

init_state_locked() {
  mkdir -p "$STATE_DIR"
  if ! jq -e . "$STATE_FILE" >/dev/null 2>&1; then
    printf '{"sticky":[],"staged":[],"daemon":{"last_workspace_id":""}}\n' >"$STATE_FILE"
  fi

  local tmp
  tmp="$(mktemp)"
  if jq '
      if type != "object" then {} else . end
      | .sticky = ((.sticky // []) | if type == "array" then map(tostring) else [] end | unique)
      | .staged = ((.staged // []) | if type == "array" then map(tostring) else [] end | unique)
      | .sticky = (.sticky - .staged)
      | .daemon = (
          if (.daemon | type) == "object" then .daemon else {} end
          | .last_workspace_id = ((.last_workspace_id // "") | tostring)
        )
    ' "$STATE_FILE" >"$tmp" 2>/dev/null; then
    mv "$tmp" "$STATE_FILE"
  else
    rm -f "$tmp"
    printf '{"sticky":[],"staged":[],"daemon":{"last_workspace_id":""}}\n' >"$STATE_FILE"
  fi
}

init_state() {
  with_lock init_state_locked
}

state_contains_locked() {
  local key="$1"
  local id="$2"
  jq -e --arg key "$key" --arg id "$id" \
    '.[$key] // [] | map(tostring) | index($id) != null' \
    "$STATE_FILE" >/dev/null 2>&1
}

state_add_locked() {
  local key="$1"
  local id="$2"
  state_update_locked '
    .[$key] = ((.[$key] // []) | map(tostring) + [$id] | unique)
  ' --arg key "$key" --arg id "$id"
}

state_remove_locked() {
  local key="$1"
  local id="$2"
  state_update_locked '
    .[$key] = ((.[$key] // []) | map(tostring) | map(select(. != $id)))
  ' --arg key "$key" --arg id "$id"
}

state_list_locked() {
  local key="$1"
  jq -r --arg key "$key" '.[$key] // [] | .[]' "$STATE_FILE"
}

state_list_json_locked() {
  local key="$1"
  jq -c --arg key "$key" '.[$key] // [] | map(tonumber? // .)' "$STATE_FILE"
}

state_set_last_workspace_locked() {
  local ws_id="$1"
  state_update_locked '.daemon.last_workspace_id = $ws' --arg ws "$ws_id"
}

state_get_last_workspace_locked() {
  jq -r '.daemon.last_workspace_id // ""' "$STATE_FILE"
}

require_window_id() {
  local window_id="$1"
  [[ "$window_id" =~ ^[0-9]+$ ]] || err "window_id must be numeric: $window_id"
}

niri_windows_json() {
  niri msg -j windows 2>/dev/null
}

niri_workspaces_json() {
  niri msg -j workspaces 2>/dev/null
}

focused_window_id() {
  niri msg -j focused-window 2>/dev/null | jq -r '.id // empty'
}

active_workspace_id() {
  local workspaces_json ws
  workspaces_json="$(niri_workspaces_json || true)"
  ws="$(jq -r '
      first(.[]? | select(.is_focused == true) | .id)
      // first(.[]? | select(.is_active == true) | .id)
      // empty
    ' <<<"${workspaces_json:-[]}" 2>/dev/null || true)"
  printf '%s\n' "$ws"
}

active_workspace_index() {
  local windows_json workspaces_json
  windows_json="$(niri_windows_json || true)"
  workspaces_json="$(niri_workspaces_json || true)"

  jq -n \
    --argjson wins "${windows_json:-[]}" \
    --argjson wss "${workspaces_json:-[]}" \
    -r '
      def ws_by_id: reduce $wss[] as $ws ({}; .[($ws.id|tostring)] = $ws);
      (first($wins[]? | select(.is_focused == true and .workspace_id != null) | .workspace_id) // null) as $wid
      | if $wid != null then
          ((ws_by_id[($wid|tostring)] // {}).idx // empty)
        else
          (first($wss[]? | select(.is_focused == true) | .idx)
           // first($wss[]? | select(.is_active == true) | .idx)
           // empty)
        end
    '
}

window_exists_in_json() {
  local window_id="$1"
  local windows_json="$2"
  jq -e --arg id "$window_id" 'any(.[]?; (.id | tostring) == $id)' <<<"$windows_json" >/dev/null 2>&1
}

find_window_by_appid() {
  local appid="$1"
  local windows_json
  windows_json="$(niri_windows_json || true)"
  jq -r --arg appid "$appid" '
    first(.[]? | select((.app_id // "") == $appid) | .id) // empty
  ' <<<"${windows_json:-[]}" 2>/dev/null || true
}

find_window_by_title() {
  local title="$1"
  local windows_json
  windows_json="$(niri_windows_json || true)"
  jq -r --arg title "$title" '
    first(.[]? | select((.title // "") | contains($title)) | .id) // empty
  ' <<<"${windows_json:-[]}" 2>/dev/null || true
}

move_window_to_workspace() {
  local window_id="$1"
  local workspace_ref="$2"
  niri msg action move-window-to-workspace --window-id "$window_id" --focus false "$workspace_ref" >/dev/null 2>&1
}

prune_state_locked_with_windows() {
  local windows_json="$1"
  local live_ids
  live_ids="$(jq '[.[]? | .id | tostring]' <<<"$windows_json")"

  state_update_locked '
    .sticky = ((.sticky // []) | map(tostring) | unique | map(select(($live | index(.)) != null)))
    | .staged = ((.staged // []) | map(tostring) | unique | map(select(($live | index(.)) != null)))
    | .sticky = (.sticky - .staged)
  ' --argjson live "$live_ids"
}

ensure_window_exists_locked() {
  local window_id="$1"
  local windows_json
  windows_json="$(niri_windows_json || true)"
  [[ -n "$windows_json" ]] || err "failed to query niri windows"
  window_exists_in_json "$window_id" "$windows_json" || err "Window not found in Niri"
}

sticky_add_locked() {
  local window_id="$1"
  local ws_idx

  ensure_window_exists_locked "$window_id"

  if state_contains_locked "staged" "$window_id"; then
    ws_idx="$(active_workspace_index || true)"
    [[ -n "$ws_idx" ]] || err "active workspace not found"
    move_window_to_workspace "$window_id" "$ws_idx" || err "failed to move window"
    state_remove_locked "staged" "$window_id"
  fi

  if state_contains_locked "sticky" "$window_id"; then
    printf 'Already in sticky list\n'
    return 0
  fi

  state_add_locked "sticky" "$window_id"
  printf 'Added\n'
}

sticky_remove_locked() {
  local window_id="$1"

  ensure_window_exists_locked "$window_id"

  if state_contains_locked "sticky" "$window_id"; then
    state_remove_locked "sticky" "$window_id"
    printf 'Removed\n'
  else
    printf 'Not in sticky list\n'
  fi
}

sticky_toggle_active_locked() {
  local window_id="$1"

  ensure_window_exists_locked "$window_id"

  if state_contains_locked "sticky" "$window_id"; then
    state_remove_locked "sticky" "$window_id"
    printf 'Removed active window from sticky\n'
  else
    state_add_locked "sticky" "$window_id"
    printf 'Added active window to sticky\n'
  fi
}

sticky_toggle_target_locked() {
  local window_id="$1"
  local ws_idx

  ensure_window_exists_locked "$window_id"

  if state_contains_locked "staged" "$window_id"; then
    ws_idx="$(active_workspace_index || true)"
    [[ -n "$ws_idx" ]] || err "active workspace not found"
    move_window_to_workspace "$window_id" "$ws_idx" || err "failed to move window"
    state_remove_locked "staged" "$window_id"
    state_add_locked "sticky" "$window_id"
    printf 'Added window to sticky\n'
    return 0
  fi

  if state_contains_locked "sticky" "$window_id"; then
    state_remove_locked "sticky" "$window_id"
    printf 'Removed window from sticky\n'
  else
    state_add_locked "sticky" "$window_id"
    printf 'Added window to sticky\n'
  fi
}

stage_add_locked() {
  local window_id="$1"

  ensure_window_exists_locked "$window_id"

  if state_contains_locked "staged" "$window_id"; then
    err "Window is already in staged list"
  fi

  if ! state_contains_locked "sticky" "$window_id"; then
    err "Window is not in sticky list, cannot stage"
  fi

  move_window_to_workspace "$window_id" "$STAGE_WORKSPACE" || err "failed to move window to stage"
  state_remove_locked "sticky" "$window_id"
  state_add_locked "staged" "$window_id"
  printf 'Staged window\n'
}

stage_remove_locked() {
  local window_id="$1"
  local ws_idx

  ensure_window_exists_locked "$window_id"

  if state_contains_locked "sticky" "$window_id"; then
    err "Window is already in sticky list"
  fi

  if ! state_contains_locked "staged" "$window_id"; then
    err "Window is not in staged list, cannot unstage"
  fi

  ws_idx="$(active_workspace_index || true)"
  [[ -n "$ws_idx" ]] || err "active workspace not found"

  move_window_to_workspace "$window_id" "$ws_idx" || err "failed to move window from stage"
  state_remove_locked "staged" "$window_id"
  state_add_locked "sticky" "$window_id"
  printf 'Unstaged window\n'
}

stage_toggle_known_locked() {
  local window_id="$1"
  local not_sticky_error="$2"
  local ws_idx

  ensure_window_exists_locked "$window_id"

  if state_contains_locked "staged" "$window_id"; then
    ws_idx="$(active_workspace_index || true)"
    [[ -n "$ws_idx" ]] || err "active workspace not found"
    move_window_to_workspace "$window_id" "$ws_idx" || err "failed to unstage window"
    state_remove_locked "staged" "$window_id"
    state_add_locked "sticky" "$window_id"
    return 0
  fi

  if state_contains_locked "sticky" "$window_id"; then
    move_window_to_workspace "$window_id" "$STAGE_WORKSPACE" || err "failed to stage window"
    state_remove_locked "sticky" "$window_id"
    state_add_locked "staged" "$window_id"
    return 0
  fi

  err "$not_sticky_error"
}

stage_toggle_active_locked() {
  local window_id="$1"
  local ws_idx

  ensure_window_exists_locked "$window_id"

  if state_contains_locked "staged" "$window_id"; then
    ws_idx="$(active_workspace_index || true)"
    [[ -n "$ws_idx" ]] || err "active workspace not found"
    move_window_to_workspace "$window_id" "$ws_idx" || err "failed to unstage active window"
    state_remove_locked "staged" "$window_id"
    state_add_locked "sticky" "$window_id"
    printf 'Unstaged active window\n'
    return 0
  fi

  if state_contains_locked "sticky" "$window_id"; then
    move_window_to_workspace "$window_id" "$STAGE_WORKSPACE" || err "failed to stage active window"
    state_remove_locked "sticky" "$window_id"
    state_add_locked "staged" "$window_id"
    printf 'Staged active window\n'
    return 0
  fi

  state_add_locked "sticky" "$window_id"
  printf 'Added active window to sticky\n'
}

stage_add_all_locked() {
  local -a ids
  local count=0

  mapfile -t ids < <(state_list_locked "sticky")
  for window_id in "${ids[@]}"; do
    if move_window_to_workspace "$window_id" "$STAGE_WORKSPACE"; then
      state_remove_locked "sticky" "$window_id"
      state_add_locked "staged" "$window_id"
      ((count += 1))
    fi
  done

  printf 'Staged %d windows\n' "$count"
}

stage_remove_all_locked() {
  local -a ids
  local count=0
  local ws_idx

  ws_idx="$(active_workspace_index || true)"
  [[ -n "$ws_idx" ]] || err "active workspace not found"

  mapfile -t ids < <(state_list_locked "staged")
  for window_id in "${ids[@]}"; do
    if move_window_to_workspace "$window_id" "$ws_idx"; then
      state_remove_locked "staged" "$window_id"
      state_add_locked "sticky" "$window_id"
      ((count += 1))
    fi
  done

  printf 'Unstaged %d windows\n' "$count"
}

daemon_tick_locked() {
  local windows_json ws_id ws_idx last_ws

  windows_json="$(niri_windows_json || true)"
  [[ -n "$windows_json" ]] || return 0

  prune_state_locked_with_windows "$windows_json"

  ws_id="$(active_workspace_id || true)"
  ws_idx="$(active_workspace_index || true)"
  [[ -n "$ws_id" && -n "$ws_idx" ]] || return 0

  last_ws="$(state_get_last_workspace_locked)"
  if [[ "$ws_id" != "$last_ws" ]]; then
    local -a ids
    mapfile -t ids < <(state_list_locked "sticky")
    for window_id in "${ids[@]}"; do
      move_window_to_workspace "$window_id" "$ws_idx" || true
    done
    state_set_last_workspace_locked "$ws_id"
  fi
}

run_daemon() {
  info "starting daemon (poll=${POLL_INTERVAL}s, stage=${STAGE_WORKSPACE})"
  while true; do
    with_lock daemon_tick_locked || true
    sleep "$POLL_INTERVAL"
  done
}

cmd_sticky() {
  local action="${1:-}"
  shift || true

  case "$action" in
    add|a)
      [[ $# -eq 1 ]] || err "sticky add requires <window_id>"
      require_window_id "$1"
      with_lock sticky_add_locked "$1"
      ;;
    remove|r)
      [[ $# -eq 1 ]] || err "sticky remove requires <window_id>"
      require_window_id "$1"
      with_lock sticky_remove_locked "$1"
      ;;
    list|l)
      with_lock state_list_json_locked "sticky"
      ;;
    toggle-active|t)
      local window_id out
      window_id="$(focused_window_id)"
      [[ -n "$window_id" ]] || err "Active window not found"

      out="$(with_lock sticky_toggle_active_locked "$window_id")"
      case "$out" in
        Added*) notify low "Sticky" "Enabled" ;;
        Removed*) notify low "Sticky" "Disabled" ;;
      esac
      printf '%s\n' "$out"
      ;;
    toggle-appid|ta)
      [[ $# -eq 1 ]] || err "sticky toggle-appid requires <app_id>"
      local appid="$1" window_id out
      window_id="$(find_window_by_appid "$appid" || true)"
      [[ -n "$window_id" ]] || err "No window found with appid $appid"

      out="$(with_lock sticky_toggle_target_locked "$window_id")"
      case "$out" in
        Added*) notify low "Sticky" "Enabled" ;;
        Removed*) notify low "Sticky" "Disabled" ;;
      esac
      printf '%s\n' "$out"
      ;;
    toggle-title|tt)
      [[ $# -ge 1 ]] || err "sticky toggle-title requires <title-substring>"
      local title="$*" window_id out
      window_id="$(find_window_by_title "$title" || true)"
      [[ -n "$window_id" ]] || err "No window found with title containing '$title'"

      out="$(with_lock sticky_toggle_target_locked "$window_id")"
      case "$out" in
        Added*) notify low "Sticky" "Enabled" ;;
        Removed*) notify low "Sticky" "Disabled" ;;
      esac
      printf '%s\n' "$out"
      ;;
    *)
      err "unknown sticky action: ${action:-<empty>}"
      ;;
  esac
}

cmd_stage() {
  local action="${1:-}"
  shift || true

  case "$action" in
    list|l)
      with_lock state_list_json_locked "staged"
      ;;
    add|a)
      [[ $# -eq 1 ]] || err "stage add requires <window_id>"
      require_window_id "$1"
      with_lock stage_add_locked "$1"
      ;;
    remove|r)
      [[ $# -eq 1 ]] || err "stage remove requires <window_id>"
      require_window_id "$1"
      with_lock stage_remove_locked "$1"
      ;;
    toggle-active|t)
      local window_id out
      window_id="$(focused_window_id)"
      [[ -n "$window_id" ]] || err "Active window not found"

      out="$(with_lock stage_toggle_active_locked "$window_id")"
      case "$out" in
        Added*) notify low "Sticky" "Enabled" ;;
        Staged*) notify low "Stage" "Moved to stage" ;;
        Unstaged*) notify low "Stage" "Restored" ;;
      esac
      printf '%s\n' "$out"
      ;;
    toggle-appid|ta)
      [[ $# -eq 1 ]] || err "stage toggle-appid requires <app_id>"
      local appid="$1" window_id
      window_id="$(find_window_by_appid "$appid" || true)"
      [[ -n "$window_id" ]] || err "No window found with appid $appid"

      with_lock stage_toggle_known_locked "$window_id" "Window with appid $appid is not in sticky list"
      printf 'Toggled stage status by app ID\n'
      ;;
    toggle-title|tt)
      [[ $# -ge 1 ]] || err "stage toggle-title requires <title-substring>"
      local title="$*" window_id
      window_id="$(find_window_by_title "$title" || true)"
      [[ -n "$window_id" ]] || err "No window found with title containing '$title'"

      with_lock stage_toggle_known_locked "$window_id" "Window with title containing '$title' is not in sticky list"
      printf 'Toggled stage status by title\n'
      ;;
    add-all|aa)
      with_lock stage_add_all_locked
      ;;
    remove-all|ra)
      with_lock stage_remove_all_locked
      ;;
    *)
      err "unknown stage action: ${action:-<empty>}"
      ;;
  esac
}

main() {
  need_bins
  init_state

  local cmd="${1:-daemon}"
  shift || true

  case "$cmd" in
    daemon)
      run_daemon
      ;;
    sticky)
      cmd_sticky "$@"
      ;;
    stage)
      cmd_stage "$@"
      ;;
    list|l|add|a|remove|r|toggle-active|t|toggle-appid|ta|toggle-title|tt)
      cmd_sticky "$cmd" "$@"
      ;;
    help|-h|--help)
      usage
      ;;
    version|-V|--version)
      printf 'niri-sticky %s\n' "$VERSION"
      ;;
    *)
      err "unknown command: $cmd"
      ;;
  esac
}

main "$@"
