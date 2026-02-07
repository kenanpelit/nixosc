#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# niri-flow
# -----------------------------------------------------------------------------
# Purpose:
# - Daemon-free workflow layer for Niri, implemented directly on `niri msg`.
# - Keeps daily keybind workflows fast and dependency-light.
#
# Interface:
# - Subcommands for focus/focus-or-spawn and workspace routing.
# - Mark and scratchpad primitives (`toggle`, `show`, `show-all`).
# - Follow-mode toggling for tracked windows.
#
# State (XDG):
# - ${XDG_STATE_HOME:-$HOME/.local/state}/niri-flow/marks.json
# - ${XDG_STATE_HOME:-$HOME/.local/state}/niri-flow/scratchpad.json
# - ${XDG_STATE_HOME:-$HOME/.local/state}/niri-flow/follow.json
#
# Tunables:
# - OSC_NIRI_FLOW_SCRATCH_WORKSPACE (default: 99)
#
# Dependencies:
# - niri
# - jq
#
# Notes:
# - This script is stateful but daemon-free.
# - Run `niri-flow --help` for the full command surface.
# -----------------------------------------------------------------------------

set -euo pipefail

VERSION="1.1.0"
STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
STATE_DIR="${STATE_HOME}/niri-flow"
MARKS_FILE="$STATE_DIR/marks.json"
SCRATCH_FILE="$STATE_DIR/scratchpad.json"
FOLLOW_FILE="$STATE_DIR/follow.json"
SCRATCH_WORKSPACE_FALLBACK="${OSC_NIRI_FLOW_SCRATCH_WORKSPACE:-99}"

MATCH_APP_ID=""
MATCH_TITLE=""
MATCH_PID=""
MATCH_WORKSPACE_ID=""
MATCH_WORKSPACE_INDEX=""
MATCH_WORKSPACE_NAME=""
MATCH_INCLUDE_CURRENT=0
MATCH_FOCUS=0
MATCH_NO_MOVE=0
REMAINING_ARGS=()

die() {
  printf 'niri-flow: %s\n' "$*" >&2
  exit 1
}

usage() {
  cat <<'EOF'
Utility commands for the niri wayland compositor

Usage: niri-flow <COMMAND>

Commands:
  focus
  focus-or-spawn
  move-to-current-workspace
  move-to-current-workspace-or-spawn
  toggle-follow-mode
  toggle-mark
  focus-marked
  list-marked
  scratchpad-toggle
  scratchpad-show
  scratchpad-show-all
  help

Options:
  -h, --help     Print help
  -V, --version  Print version
EOF
}

command_usage() {
  cat <<'EOF'
Match options:
  --app-id <regex>
  --title <regex>
  --pid <number>
  --workspace-id <id>
  --workspace-index <id>
  --workspace-name <name>
  --include-current-workspace
  --focus
  --no-move
EOF
}

require_bins() {
  command -v niri >/dev/null 2>&1 || die "niri not found in PATH"
  command -v jq >/dev/null 2>&1 || die "jq not found in PATH"
}

init_state() {
  mkdir -p "$STATE_DIR"
  [[ -f "$MARKS_FILE" ]] || printf '{"marks":{}}\n' >"$MARKS_FILE"
  [[ -f "$SCRATCH_FILE" ]] || printf '{"entries":{},"cursor":0}\n' >"$SCRATCH_FILE"
  [[ -f "$FOLLOW_FILE" ]] || printf '{"windows":[],"last_workspace_id":""}\n' >"$FOLLOW_FILE"

  # Keep state files backward-compatible even if an older version wrote
  # different JSON shapes.
  normalize_state_file "$MARKS_FILE" '{"marks":{}}' '
    if type != "object" then {marks:{}} else . end
    | .marks = (
        if (.marks | type) == "object" then .marks
        elif (.marks | type) == "array" then
          (.marks | map(tostring) | reduce .[] as $id ({}; .[$id] = true))
        else {}
        end
      )
    | .marks = (.marks | with_entries(.value = ((.value // []) | if type == "array" then map(tostring) else [] end)))
  '

  normalize_state_file "$SCRATCH_FILE" '{"entries":{},"cursor":0}' '
    def normalize_entries:
      if type == "object" then .
      elif type == "array" then
        (
          map(
            if (type == "object" and has("key") and has("value")) then
              { key: (.key | tostring), value: .value }
            elif (type == "array" and length == 2) then
              { key: (.[0] | tostring), value: .[1] }
            else
              empty
            end
          )
          | from_entries
        )
      else
        {}
      end;

    if type != "object" then {entries:{}, cursor:0} else . end
    | .entries = ((.entries // {}) | normalize_entries)
    | .entries = (
        .entries
        | with_entries(
            .value = (
              if (.value | type) == "object" then
                {
                  origin_ws: ((.value.origin_ws // "") | tostring),
                  hidden: ((.value.hidden // false) | if type == "boolean" then . else false end)
                }
              else
                { origin_ws: "", hidden: false }
              end
            )
          )
      )
    | .cursor = ((.cursor // 0) | tonumber? // 0)
  '

  normalize_state_file "$FOLLOW_FILE" '{"windows":[],"last_workspace_id":""}' '
    if type != "object" then {windows:[], last_workspace_id:""} else . end
    | .windows = ((.windows // []) | if type == "array" then map(tostring) else [] end | unique)
    | .last_workspace_id = ((.last_workspace_id // "") | tostring)
  '
}

normalize_state_file() {
  local file="$1"
  local fallback_json="$2"
  local jq_program="$3"
  local tmp_file

  if ! jq -e . "$file" >/dev/null 2>&1; then
    printf '%s\n' "$fallback_json" >"$file"
  fi

  tmp_file="$(mktemp)"
  if jq "$jq_program" "$file" >"$tmp_file" 2>/dev/null; then
    mv "$tmp_file" "$file"
  else
    rm -f "$tmp_file"
    printf '%s\n' "$fallback_json" >"$file"
  fi
}

niri_windows_json() {
  niri msg -j windows
}

niri_workspaces_json() {
  niri msg -j workspaces
}

current_workspace_id() {
  local windows_json workspaces_json ws_id

  windows_json="$(niri_windows_json 2>/dev/null || true)"
  ws_id="$(echo "$windows_json" | jq -r 'first(.[] | select(.is_focused == true and .workspace_id != null) | .workspace_id) // empty' 2>/dev/null || true)"
  if [[ -n "$ws_id" ]]; then
    printf '%s\n' "$ws_id"
    return 0
  fi

  workspaces_json="$(niri_workspaces_json 2>/dev/null || true)"
  ws_id="$(echo "$workspaces_json" | jq -r 'first(.[] | select(.is_focused == true) | .id) // empty' 2>/dev/null || true)"
  if [[ -n "$ws_id" ]]; then
    printf '%s\n' "$ws_id"
    return 0
  fi

  ws_id="$(echo "$workspaces_json" | jq -r 'first(.[] | select(.is_active == true) | .id) // empty' 2>/dev/null || true)"
  printf '%s\n' "$ws_id"
}

current_workspace_index() {
  local windows_json workspaces_json ws_idx

  windows_json="$(niri_windows_json 2>/dev/null || true)"
  workspaces_json="$(niri_workspaces_json 2>/dev/null || true)"

  ws_idx="$(
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
      ' 2>/dev/null || true
  )"
  printf '%s\n' "$ws_idx"
}

focused_window_id() {
  niri_windows_json | jq -r 'first(.[] | select(.is_focused == true) | .id) // empty'
}

has_match_filter() {
  [[ -n "$MATCH_APP_ID$MATCH_TITLE$MATCH_PID$MATCH_WORKSPACE_ID$MATCH_WORKSPACE_INDEX$MATCH_WORKSPACE_NAME" ]]
}

parse_match_opts() {
  MATCH_APP_ID=""
  MATCH_TITLE=""
  MATCH_PID=""
  MATCH_WORKSPACE_ID=""
  MATCH_WORKSPACE_INDEX=""
  MATCH_WORKSPACE_NAME=""
  MATCH_INCLUDE_CURRENT=0
  MATCH_FOCUS=0
  MATCH_NO_MOVE=0
  REMAINING_ARGS=()

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --app-id)
        [[ $# -ge 2 ]] || die "--app-id requires a value"
        MATCH_APP_ID="$2"
        shift 2
        ;;
      --title)
        [[ $# -ge 2 ]] || die "--title requires a value"
        MATCH_TITLE="$2"
        shift 2
        ;;
      --pid)
        [[ $# -ge 2 ]] || die "--pid requires a value"
        MATCH_PID="$2"
        shift 2
        ;;
      --workspace-id)
        [[ $# -ge 2 ]] || die "--workspace-id requires a value"
        MATCH_WORKSPACE_ID="$2"
        shift 2
        ;;
      --workspace-index)
        [[ $# -ge 2 ]] || die "--workspace-index requires a value"
        MATCH_WORKSPACE_INDEX="$2"
        shift 2
        ;;
      --workspace-name)
        [[ $# -ge 2 ]] || die "--workspace-name requires a value"
        MATCH_WORKSPACE_NAME="$2"
        shift 2
        ;;
      --include-current-workspace)
        MATCH_INCLUDE_CURRENT=1
        shift
        ;;
      --focus)
        MATCH_FOCUS=1
        shift
        ;;
      --no-move)
        MATCH_NO_MOVE=1
        shift
        ;;
      --)
        shift
        break
        ;;
      -*)
        die "unknown option: $1"
        ;;
      *)
        break
        ;;
    esac
  done

  REMAINING_ARGS=("$@")
}

matched_window_ids() {
  local windows_json="$1"
  local workspaces_json="$2"

  echo "$windows_json" | jq -r \
    --arg app "$MATCH_APP_ID" \
    --arg title "$MATCH_TITLE" \
    --arg pid "$MATCH_PID" \
    --arg workspace "$MATCH_WORKSPACE_ID" \
    --arg workspace_idx "$MATCH_WORKSPACE_INDEX" \
    --arg workspace_name "$MATCH_WORKSPACE_NAME" \
    --argjson workspaces "$workspaces_json" \
    '
      def ws_by_id: reduce $workspaces[] as $ws ({}; .[($ws.id | tostring)] = $ws);
      .[]
      | . as $w
      | (ws_by_id[(($w.workspace_id // -1) | tostring)] // null) as $ws
      | select(($app == "") or ((($w.app_id // "") | tostring) | test($app)))
      | select(($title == "") or ((($w.title // "") | tostring) | test($title)))
      | select(($pid == "") or ((($w.pid // -1) | tostring) == $pid))
      | select(($workspace == "") or ((($w.workspace_id // -1) | tostring) == $workspace))
      | select(($workspace_idx == "") or (($ws != null) and (($ws.idx | tostring) == $workspace_idx)))
      | select(($workspace_name == "") or (($ws != null) and (((($ws.name // "") | tostring) | test($workspace_name)))))
      | ($w.id | tostring)
    '
}

focus_with_current_match() {
  local windows_json workspaces_json focused_id target_id index
  local -a ids

  windows_json="$(niri_windows_json)"
  workspaces_json="$(niri_workspaces_json)"
  mapfile -t ids < <(matched_window_ids "$windows_json" "$workspaces_json")
  [[ "${#ids[@]}" -gt 0 ]] || return 1

  if [[ "${#ids[@]}" -eq 1 ]]; then
    target_id="${ids[0]}"
  else
    focused_id="$(focused_window_id)"
    target_id="${ids[0]}"
    for index in "${!ids[@]}"; do
      if [[ "${ids[$index]}" == "$focused_id" ]]; then
        target_id="${ids[$(( (index + 1) % ${#ids[@]} ))]}"
        break
      fi
    done
  fi

  niri msg action focus-window --id "$target_id" >/dev/null
}

window_workspace_id() {
  local windows_json="$1"
  local window_id="$2"
  echo "$windows_json" | jq -r --arg id "$window_id" 'first(.[] | select((.id | tostring) == $id) | .workspace_id) // empty'
}

cmd_focus() {
  parse_match_opts "$@"
  focus_with_current_match
}

cmd_focus_or_spawn() {
  parse_match_opts "$@"

  [[ "${#REMAINING_ARGS[@]}" -gt 0 ]] || die "focus-or-spawn requires a command to spawn"

  if focus_with_current_match; then
    return 0
  fi

  "${REMAINING_ARGS[@]}" >/dev/null 2>&1 &
  disown || true
  return 0
}

move_one_to_current_workspace() {
  local windows_json workspaces_json current_workspace current_workspace_idx target_id window_workspace
  local -a ids

  windows_json="$(niri_windows_json)"
  workspaces_json="$(niri_workspaces_json)"
  current_workspace="$(current_workspace_id)"
  current_workspace_idx="$(current_workspace_index)"
  [[ -n "$current_workspace" ]] || return 1
  [[ -n "$current_workspace_idx" ]] || return 1

  mapfile -t ids < <(matched_window_ids "$windows_json" "$workspaces_json")
  [[ "${#ids[@]}" -gt 0 ]] || return 1

  target_id=""
  for window_id in "${ids[@]}"; do
    window_workspace="$(window_workspace_id "$windows_json" "$window_id")"
    if [[ "$MATCH_INCLUDE_CURRENT" -eq 0 && "$window_workspace" == "$current_workspace" ]]; then
      continue
    fi
    target_id="$window_id"
    break
  done
  [[ -n "$target_id" ]] || return 1

  niri msg action move-window-to-workspace --window-id "$target_id" --focus false "$current_workspace_idx" >/dev/null
  if [[ "$MATCH_FOCUS" -eq 1 ]]; then
    niri msg action focus-window --id "$target_id" >/dev/null 2>&1 || true
  fi
  return 0
}

cmd_move_to_current_workspace() {
  parse_match_opts "$@"
  move_one_to_current_workspace
}

cmd_move_to_current_workspace_or_spawn() {
  parse_match_opts "$@"
  [[ "${#REMAINING_ARGS[@]}" -gt 0 ]] || die "move-to-current-workspace-or-spawn requires a command to spawn"

  if move_one_to_current_workspace; then
    return 0
  fi

  "${REMAINING_ARGS[@]}" >/dev/null 2>&1 &
  disown || true
  return 0
}

update_marks_file() {
  local jq_program="$1"
  local tmp_file
  tmp_file="$(mktemp)"
  jq "$jq_program" "$MARKS_FILE" >"$tmp_file"
  mv "$tmp_file" "$MARKS_FILE"
}

cmd_toggle_mark() {
  local mark focused_id tmp_file
  mark="${1:-__default__}"
  focused_id="$(focused_window_id)"
  [[ -n "$focused_id" ]] || return 1

  tmp_file="$(mktemp)"
  jq --arg mark "$mark" --arg id "$focused_id" '
    .marks = (.marks // {}) |
    if ((.marks[$mark] // []) | index($id)) != null then
      .marks[$mark] = ((.marks[$mark] // []) | map(select(. != $id)))
    else
      .marks[$mark] = ((.marks[$mark] // []) + [$id] | unique)
    end
  ' "$MARKS_FILE" >"$tmp_file"
  mv "$tmp_file" "$MARKS_FILE"
}

cleanup_mark() {
  local mark="$1"
  local windows_json live_ids_json tmp_file
  windows_json="$(niri_windows_json)"
  live_ids_json="$(echo "$windows_json" | jq '[.[].id | tostring]')"
  tmp_file="$(mktemp)"
  jq --arg mark "$mark" --argjson live "$live_ids_json" '
    .marks = (.marks // {}) |
    .marks[$mark] = ((.marks[$mark] // []) | map(tostring) | map(select(($live | index(.)) != null)))
  ' "$MARKS_FILE" >"$tmp_file"
  mv "$tmp_file" "$MARKS_FILE"
}

cmd_focus_marked() {
  local mark target_id tmp_file
  mark="${1:-__default__}"
  cleanup_mark "$mark"
  target_id="$(jq -r --arg mark "$mark" '(.marks[$mark] // [])[0] // empty' "$MARKS_FILE")"
  [[ -n "$target_id" ]] || return 1

  niri msg action focus-window --id "$target_id" >/dev/null 2>&1 || true

  tmp_file="$(mktemp)"
  jq --arg mark "$mark" '
    .marks = (.marks // {}) |
    .marks[$mark] = (
      if ((.marks[$mark] // []) | length) > 1 then
        ((.marks[$mark])[1:] + [(.marks[$mark])[0]])
      else
        (.marks[$mark] // [])
      end
    )
  ' "$MARKS_FILE" >"$tmp_file"
  mv "$tmp_file" "$MARKS_FILE"
}

cmd_list_marked() {
  local mark all_marks
  mark="__default__"
  all_marks=0

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --all)
        all_marks=1
        shift
        ;;
      *)
        mark="$1"
        shift
        ;;
    esac
  done

  if [[ "$all_marks" -eq 1 ]]; then
    jq -r '.marks // {} | to_entries[]? | .key as $k | (.value[]? | "\($k)\t\(.)")' "$MARKS_FILE"
  else
    cleanup_mark "$mark"
    jq -r --arg mark "$mark" '.marks[$mark] // [] | .[]' "$MARKS_FILE"
  fi
}

scratch_tmp_update() {
  local jq_args=("$@")
  local tmp_file
  tmp_file="$(mktemp)"
  jq "${jq_args[@]}" "$SCRATCH_FILE" >"$tmp_file"
  mv "$tmp_file" "$SCRATCH_FILE"
}

scratch_entry_exists() {
  local window_id="$1"
  jq -e --arg id "$window_id" '.entries[$id] != null' "$SCRATCH_FILE" >/dev/null 2>&1
}

remove_scratch_entry() {
  local window_id="$1"
  scratch_tmp_update --arg id "$window_id" '
    .entries = (.entries // {}) |
    del(.entries[$id])
  '
}

refresh_scratch_entries() {
  local windows_json="$1"
  local live_ids_json
  live_ids_json="$(echo "$windows_json" | jq '[.[].id | tostring]')"
  scratch_tmp_update --argjson live "$live_ids_json" '
    .entries = (.entries // {}) |
    .entries = (
      .entries
      | with_entries(select(. as $entry | ($live | index($entry.key)) != null))
    )
  '
}

scratch_hidden_state() {
  local window_id="$1"
  jq -r --arg id "$window_id" '.entries[$id].hidden // "none"' "$SCRATCH_FILE"
}

set_scratch_hidden() {
  local window_id="$1"
  local hidden_flag="$2"
  local origin_workspace="$3"
  scratch_tmp_update --arg id "$window_id" --arg ws "$origin_workspace" --argjson hidden "$hidden_flag" '
    .entries = (.entries // {}) |
    .entries[$id] = ((.entries[$id] // {}) + {origin_ws: $ws, hidden: $hidden})
  '
}

focused_output_name() {
  niri_workspaces_json | jq -r '
    first(.[] | select(.is_focused == true) | .output // empty)
    // first(.[] | select(.is_active == true) | .output // empty)
    // empty
  '
}

scratch_workspace_index() {
  local output ws_id
  output="$(focused_output_name)"
  if [[ -n "$output" ]]; then
    ws_id="$(niri_workspaces_json | jq -r --arg out "$output" '([.[] | select((.output // "") == $out)] | max_by(.idx) | .idx // empty)')"
    if [[ -n "$ws_id" ]]; then
      printf '%s\n' "$ws_id"
      return 0
    fi
  fi
  printf '%s\n' "$SCRATCH_WORKSPACE_FALLBACK"
}

window_is_floating() {
  local window_id="$1"
  local windows_json="$2"
  echo "$windows_json" | jq -e --arg id "$window_id" 'first(.[] | select((.id | tostring) == $id) | .is_floating) == true' >/dev/null 2>&1
}

ensure_window_floating() {
  local window_id="$1"
  local windows_json="$2"
  if ! window_is_floating "$window_id" "$windows_json"; then
    niri msg action toggle-window-floating --id "$window_id" >/dev/null 2>&1 || true
  fi
}

scratchpad_move_all() {
  local windows_json="$1"
  local target_ws
  local -a scratch_ids

  target_ws="$(scratch_workspace_index)"
  [[ -n "$target_ws" ]] || return 1

  mapfile -t scratch_ids < <(jq -r '.entries // {} | keys[]?' "$SCRATCH_FILE")
  [[ "${#scratch_ids[@]}" -gt 0 ]] || return 0

  for window_id in "${scratch_ids[@]}"; do
    ensure_window_floating "$window_id" "$windows_json"
    niri msg action move-window-to-workspace --window-id "$window_id" --focus false "$target_ws" >/dev/null 2>&1 || true
    set_scratch_hidden "$window_id" true "$target_ws"
  done
}

hide_window_to_scratch() {
  local window_id="$1"
  local origin_workspace="$2"
  local scratch_workspace
  local windows_json
  if [[ "$MATCH_NO_MOVE" -eq 0 ]]; then
    windows_json="$(niri_windows_json)"
    ensure_window_floating "$window_id" "$windows_json"
    scratch_workspace="$(scratch_workspace_index)"
    niri msg action move-window-to-workspace --window-id "$window_id" --focus false "$scratch_workspace" >/dev/null 2>&1 || true
  fi
  set_scratch_hidden "$window_id" true "$origin_workspace"
}

show_window_from_scratch() {
  local window_id="$1"
  local current_workspace current_workspace_idx
  current_workspace="$(current_workspace_id)"
  current_workspace_idx="$(current_workspace_index)"
  [[ -n "$current_workspace" ]] || return 1
  [[ -n "$current_workspace_idx" ]] || return 1
  niri msg action move-window-to-workspace --window-id "$window_id" --focus false "$current_workspace_idx" >/dev/null 2>&1 || true
  niri msg action focus-window --id "$window_id" >/dev/null 2>&1 || true
  set_scratch_hidden "$window_id" false "$current_workspace"
}

select_target_window_id() {
  local windows_json="$1"
  local workspaces_json="$2"
  local focused_id
  local -a ids

  focused_id="$(focused_window_id)"

  # For plain scratchpad-toggle (no filters), act on the currently focused
  # window to match user expectation.
  if ! has_match_filter && [[ -n "$focused_id" ]]; then
    printf '%s\n' "$focused_id"
    return 0
  fi

  mapfile -t ids < <(matched_window_ids "$windows_json" "$workspaces_json")
  if [[ "${#ids[@]}" -gt 0 ]]; then
    printf '%s\n' "${ids[0]}"
    return 0
  fi

  if [[ -n "$focused_id" ]]; then
    printf '%s\n' "$focused_id"
    return 0
  fi

  return 1
}

cmd_scratchpad_toggle() {
  local windows_json workspaces_json target_id origin_workspace
  parse_match_opts "$@"
  windows_json="$(niri_windows_json)"
  workspaces_json="$(niri_workspaces_json)"
  refresh_scratch_entries "$windows_json"
  target_id="$(select_target_window_id "$windows_json" "$workspaces_json" || true)"
  [[ -n "$target_id" ]] || return 1

  if scratch_entry_exists "$target_id"; then
    remove_scratch_entry "$target_id"
    return 0
  fi

  if [[ -n "$MATCH_WORKSPACE_ID" ]]; then
    origin_workspace="$MATCH_WORKSPACE_ID"
  else
    origin_workspace="$(window_workspace_id "$windows_json" "$target_id")"
    [[ -n "$origin_workspace" ]] || origin_workspace="$(current_workspace_id)"
  fi

  hide_window_to_scratch "$target_id" "$origin_workspace"
  if [[ "$MATCH_NO_MOVE" -eq 0 ]]; then
    scratchpad_move_all "$windows_json"
  fi
}

cmd_scratchpad_show() {
  local focused_id windows_json workspaces_json cursor selected_id tmp_file
  local -a hidden_ids matched_ids selected_ids

  parse_match_opts "$@"
  windows_json="$(niri_windows_json)"
  workspaces_json="$(niri_workspaces_json)"
  refresh_scratch_entries "$windows_json"

  focused_id="$(focused_window_id)"
  if [[ -n "$focused_id" ]] && scratch_entry_exists "$focused_id"; then
    scratchpad_move_all "$windows_json"
    return 0
  fi

  mapfile -t hidden_ids < <(jq -r '.entries // {} | to_entries[]? | select(.value.hidden == true) | .key' "$SCRATCH_FILE")
  [[ "${#hidden_ids[@]}" -gt 0 ]] || return 1

  if [[ -n "$MATCH_APP_ID$MATCH_TITLE$MATCH_PID$MATCH_WORKSPACE_ID$MATCH_WORKSPACE_INDEX$MATCH_WORKSPACE_NAME" ]]; then
    mapfile -t matched_ids < <(matched_window_ids "$windows_json" "$workspaces_json")
    selected_ids=()
    for candidate_id in "${hidden_ids[@]}"; do
      for match_id in "${matched_ids[@]}"; do
        if [[ "$candidate_id" == "$match_id" ]]; then
          selected_ids+=("$candidate_id")
          break
        fi
      done
    done
  else
    selected_ids=("${hidden_ids[@]}")
  fi

  [[ "${#selected_ids[@]}" -gt 0 ]] || return 1

  cursor="$(jq -r '.cursor // 0' "$SCRATCH_FILE")"
  selected_id="${selected_ids[$((cursor % ${#selected_ids[@]}))]}"
  show_window_from_scratch "$selected_id"

  tmp_file="$(mktemp)"
  jq --argjson cursor "$((cursor + 1))" '.cursor = $cursor' "$SCRATCH_FILE" >"$tmp_file"
  mv "$tmp_file" "$SCRATCH_FILE"
}

cmd_scratchpad_show_all() {
  local windows_json workspaces_json focused_id focused_once
  local -a hidden_ids matched_ids selected_ids

  parse_match_opts "$@"
  windows_json="$(niri_windows_json)"
  workspaces_json="$(niri_workspaces_json)"
  refresh_scratch_entries "$windows_json"

  focused_id="$(focused_window_id)"
  if [[ -n "$focused_id" ]] && scratch_entry_exists "$focused_id"; then
    scratchpad_move_all "$windows_json"
    return 0
  fi

  mapfile -t hidden_ids < <(jq -r '.entries // {} | to_entries[]? | select(.value.hidden == true) | .key' "$SCRATCH_FILE")
  [[ "${#hidden_ids[@]}" -gt 0 ]] || return 1

  if [[ -n "$MATCH_APP_ID$MATCH_TITLE$MATCH_PID$MATCH_WORKSPACE_ID$MATCH_WORKSPACE_INDEX$MATCH_WORKSPACE_NAME" ]]; then
    mapfile -t matched_ids < <(matched_window_ids "$windows_json" "$workspaces_json")
    selected_ids=()
    for candidate_id in "${hidden_ids[@]}"; do
      for match_id in "${matched_ids[@]}"; do
        if [[ "$candidate_id" == "$match_id" ]]; then
          selected_ids+=("$candidate_id")
          break
        fi
      done
    done
  else
    selected_ids=("${hidden_ids[@]}")
  fi

  [[ "${#selected_ids[@]}" -gt 0 ]] || return 1

  focused_once=0
  local current_workspace current_workspace_idx
  current_workspace="$(current_workspace_id)"
  current_workspace_idx="$(current_workspace_index)"
  [[ -n "$current_workspace" ]] || return 1
  [[ -n "$current_workspace_idx" ]] || return 1
  for window_id in "${selected_ids[@]}"; do
    niri msg action move-window-to-workspace --window-id "$window_id" --focus false "$current_workspace_idx" >/dev/null 2>&1 || true
    set_scratch_hidden "$window_id" false "$current_workspace"
    if [[ "$focused_once" -eq 0 ]]; then
      niri msg action focus-window --id "$window_id" >/dev/null 2>&1 || true
      focused_once=1
    fi
  done
}

sync_follow_mode() {
  local current_workspace current_workspace_idx last_workspace
  local -a follow_ids

  current_workspace="$(current_workspace_id)"
  current_workspace_idx="$(current_workspace_index)"
  [[ -n "$current_workspace" ]] || return 0
  [[ -n "$current_workspace_idx" ]] || return 0

  last_workspace="$(jq -r '.last_workspace_id // ""' "$FOLLOW_FILE")"
  if [[ "$last_workspace" == "$current_workspace" ]]; then
    return 0
  fi

  mapfile -t follow_ids < <(jq -r '.windows // [] | .[]' "$FOLLOW_FILE")
  for window_id in "${follow_ids[@]}"; do
    niri msg action move-window-to-workspace --window-id "$window_id" --focus false "$current_workspace_idx" >/dev/null 2>&1 || true
  done

  local tmp_file
  tmp_file="$(mktemp)"
  jq --arg ws "$current_workspace" '.last_workspace_id = $ws' "$FOLLOW_FILE" >"$tmp_file"
  mv "$tmp_file" "$FOLLOW_FILE"
}

cmd_toggle_follow_mode() {
  local focused_id tmp_file
  focused_id="$(focused_window_id)"
  [[ -n "$focused_id" ]] || return 1

  tmp_file="$(mktemp)"
  jq --arg id "$focused_id" '
    .windows = (.windows // []) |
    if (.windows | index($id)) != null then
      .windows = (.windows | map(select(. != $id)))
    else
      .windows = (.windows + [$id] | unique)
    end
  ' "$FOLLOW_FILE" >"$tmp_file"
  mv "$tmp_file" "$FOLLOW_FILE"
}

main() {
  local command="${1:-}"
  case "$command" in
    ""|-h|--help|help)
      usage
      exit 0
      ;;
    -V|--version)
      printf 'niri-flow %s\n' "$VERSION"
      exit 0
      ;;
  esac

  require_bins
  init_state
  sync_follow_mode
  shift

  case "$command" in
    focus) cmd_focus "$@" ;;
    focus-or-spawn) cmd_focus_or_spawn "$@" ;;
    move-to-current-workspace) cmd_move_to_current_workspace "$@" ;;
    move-to-current-workspace-or-spawn) cmd_move_to_current_workspace_or_spawn "$@" ;;
    toggle-mark) cmd_toggle_mark "$@" ;;
    focus-marked) cmd_focus_marked "$@" ;;
    list-marked) cmd_list_marked "$@" ;;
    toggle-follow-mode) cmd_toggle_follow_mode "$@" ;;
    scratchpad-toggle) cmd_scratchpad_toggle "$@" ;;
    scratchpad-show) cmd_scratchpad_show "$@" ;;
    scratchpad-show-all) cmd_scratchpad_show_all "$@" ;;
    *)
      usage
      command_usage >&2
      die "unknown command: $command"
      ;;
  esac
}

main "$@"
