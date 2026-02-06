#!/usr/bin/env bash
# osc-niri-flow.sh - daemon-free Niri workflow helper
# Provides the subset needed by local scripts/keybinds using only `niri msg`.

set -euo pipefail

VERSION="1.0.0"
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/nirius"
MARKS_FILE="$STATE_DIR/marks.json"
SCRATCH_FILE="$STATE_DIR/scratchpad.json"
SCRATCH_WORKSPACE="${NIRIUS_SCRATCH_WORKSPACE:-99}"

MATCH_APP_ID=""
MATCH_TITLE=""
MATCH_PID=""
MATCH_WORKSPACE_ID=""
MATCH_WORKSPACE_NAME=""
MATCH_INCLUDE_CURRENT=0
MATCH_FOCUS=0
MATCH_NO_MOVE=0
REMAINING_ARGS=()

die() {
  printf 'osc-niri-flow: %s\n' "$*" >&2
  exit 1
}

usage() {
  cat <<'EOF'
Utility commands for the niri wayland compositor

Usage: osc-niri-flow <COMMAND>

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
}

niri_windows_json() {
  niri msg -j windows
}

niri_workspaces_json() {
  niri msg -j workspaces
}

current_workspace_id() {
  niri_workspaces_json | jq -r 'first(.[] | select(.is_active == true) | .id) // empty'
}

focused_window_id() {
  niri_windows_json | jq -r 'first(.[] | select(.is_focused == true) | .id) // empty'
}

workspace_id_from_name() {
  local workspace_name="$1"
  niri_workspaces_json | jq -r --arg name "$workspace_name" 'first(.[] | select((.name // "") == $name) | .id) // empty'
}

resolve_workspace_filter() {
  if [[ -n "$MATCH_WORKSPACE_NAME" && -z "$MATCH_WORKSPACE_ID" ]]; then
    MATCH_WORKSPACE_ID="$(workspace_id_from_name "$MATCH_WORKSPACE_NAME")"
    if [[ -z "$MATCH_WORKSPACE_ID" ]]; then
      MATCH_WORKSPACE_ID="-999999999"
    fi
  fi
}

parse_match_opts() {
  MATCH_APP_ID=""
  MATCH_TITLE=""
  MATCH_PID=""
  MATCH_WORKSPACE_ID=""
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
      --workspace-id|--workspace-index)
        [[ $# -ge 2 ]] || die "$1 requires a value"
        MATCH_WORKSPACE_ID="$2"
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
  resolve_workspace_filter
}

matched_window_ids() {
  local windows_json="$1"

  echo "$windows_json" | jq -r \
    --arg app "$MATCH_APP_ID" \
    --arg title "$MATCH_TITLE" \
    --arg pid "$MATCH_PID" \
    --arg workspace "$MATCH_WORKSPACE_ID" \
    '
      .[]
      | select(($app == "") or (((.app_id // "") | tostring) | test($app)))
      | select(($title == "") or (((.title // "") | tostring) | test($title)))
      | select(($pid == "") or (((.pid // -1) | tostring) == $pid))
      | select(($workspace == "") or (((.workspace_id // -1) | tostring) == $workspace))
      | (.id | tostring)
    '
}

focus_with_current_match() {
  local windows_json focused_id target_id index
  local -a ids

  windows_json="$(niri_windows_json)"
  mapfile -t ids < <(matched_window_ids "$windows_json")
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
  local windows_json current_workspace target_id window_workspace
  local -a ids

  windows_json="$(niri_windows_json)"
  current_workspace="$(current_workspace_id)"
  [[ -n "$current_workspace" ]] || return 1

  mapfile -t ids < <(matched_window_ids "$windows_json")
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

  niri msg action move-window-to-workspace --window-id "$target_id" --focus false "$current_workspace" >/dev/null
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

hide_window_to_scratch() {
  local window_id="$1"
  local origin_workspace="$2"
  if [[ "$MATCH_NO_MOVE" -eq 0 ]]; then
    niri msg action move-window-to-workspace --window-id "$window_id" --focus false "$SCRATCH_WORKSPACE" >/dev/null 2>&1 || true
  fi
  set_scratch_hidden "$window_id" true "$origin_workspace"
}

show_window_from_scratch() {
  local window_id="$1"
  local current_workspace
  current_workspace="$(current_workspace_id)"
  [[ -n "$current_workspace" ]] || return 1
  niri msg action move-window-to-workspace --window-id "$window_id" --focus false "$current_workspace" >/dev/null 2>&1 || true
  niri msg action focus-window --id "$window_id" >/dev/null 2>&1 || true
  set_scratch_hidden "$window_id" false "$current_workspace"
}

select_target_window_id() {
  local windows_json="$1"
  local focused_id
  local -a ids

  mapfile -t ids < <(matched_window_ids "$windows_json")
  if [[ "${#ids[@]}" -gt 0 ]]; then
    printf '%s\n' "${ids[0]}"
    return 0
  fi

  focused_id="$(focused_window_id)"
  if [[ -n "$focused_id" ]]; then
    printf '%s\n' "$focused_id"
    return 0
  fi

  return 1
}

cmd_scratchpad_toggle() {
  local windows_json target_id hidden_state origin_workspace
  parse_match_opts "$@"
  windows_json="$(niri_windows_json)"
  target_id="$(select_target_window_id "$windows_json" || true)"
  [[ -n "$target_id" ]] || return 1

  hidden_state="$(scratch_hidden_state "$target_id")"
  if [[ "$hidden_state" == "true" ]]; then
    show_window_from_scratch "$target_id"
    return 0
  fi

  if [[ -n "$MATCH_WORKSPACE_ID" ]]; then
    origin_workspace="$MATCH_WORKSPACE_ID"
  else
    origin_workspace="$(window_workspace_id "$windows_json" "$target_id")"
    [[ -n "$origin_workspace" ]] || origin_workspace="$(current_workspace_id)"
  fi

  hide_window_to_scratch "$target_id" "$origin_workspace"
}

cmd_scratchpad_show() {
  local focused_id focused_state windows_json current_workspace cursor selected_id tmp_file
  local -a hidden_ids matched_ids selected_ids

  parse_match_opts "$@"
  windows_json="$(niri_windows_json)"
  current_workspace="$(current_workspace_id)"
  [[ -n "$current_workspace" ]] || return 1

  focused_id="$(focused_window_id)"
  if [[ -n "$focused_id" ]]; then
    focused_state="$(scratch_hidden_state "$focused_id")"
    if [[ "$focused_state" == "false" ]]; then
      hide_window_to_scratch "$focused_id" "$current_workspace"
      return 0
    fi
  fi

  mapfile -t hidden_ids < <(jq -r '.entries // {} | to_entries[]? | select(.value.hidden == true) | .key' "$SCRATCH_FILE")
  [[ "${#hidden_ids[@]}" -gt 0 ]] || return 1

  if [[ -n "$MATCH_APP_ID$MATCH_TITLE$MATCH_PID$MATCH_WORKSPACE_ID$MATCH_WORKSPACE_NAME" ]]; then
    mapfile -t matched_ids < <(matched_window_ids "$windows_json")
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
  local windows_json current_workspace focused_once
  local -a hidden_ids matched_ids selected_ids

  parse_match_opts "$@"
  windows_json="$(niri_windows_json)"
  current_workspace="$(current_workspace_id)"
  [[ -n "$current_workspace" ]] || return 1

  mapfile -t hidden_ids < <(jq -r '.entries // {} | to_entries[]? | select(.value.hidden == true) | .key' "$SCRATCH_FILE")
  [[ "${#hidden_ids[@]}" -gt 0 ]] || return 1

  if [[ -n "$MATCH_APP_ID$MATCH_TITLE$MATCH_PID$MATCH_WORKSPACE_ID$MATCH_WORKSPACE_NAME" ]]; then
    mapfile -t matched_ids < <(matched_window_ids "$windows_json")
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
  for window_id in "${selected_ids[@]}"; do
    niri msg action move-window-to-workspace --window-id "$window_id" --focus false "$current_workspace" >/dev/null 2>&1 || true
    set_scratch_hidden "$window_id" false "$current_workspace"
    if [[ "$focused_once" -eq 0 ]]; then
      niri msg action focus-window --id "$window_id" >/dev/null 2>&1 || true
      focused_once=1
    fi
  done
}

cmd_toggle_follow_mode() {
  die "toggle-follow-mode is not implemented in osc-niri-flow"
}

main() {
  local command="${1:-}"
  case "$command" in
    ""|-h|--help|help)
      usage
      exit 0
      ;;
    -V|--version)
      printf 'osc-niri-flow %s\n' "$VERSION"
      exit 0
      ;;
  esac

  require_bins
  init_state
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
