#!/usr/bin/env bash
# niri-arrange-windows.sh
# Moves running applications to their designated named workspaces in Niri.
# Useful for restoring window layout after a messy session or restart.

set -euo pipefail

usage() {
  cat <<'EOF'
Kullanım:
  niri-arrange-windows.sh [--dry-run] [--focus <window-id|workspace>]
  niri-arrange-windows.sh [--verbose]

Amaç:
  Niri'de açık pencereleri, semsumo (--daily) düzenindeki "ait oldukları"
  workspace'lere geri taşır.

Notlar:
  - Bu script Niri oturumu içinde çalıştırılmalı (NIRI_SOCKET gerekli).
  - Taşıma işlemi için Niri action'ları kullanılır:
      - focus-window <id>
      - move-window-to-workspace <workspace>
  - Varsayılan davranış: işlem bitince eski odaklanan pencereye geri döner.

Örnek:
  niri-arrange-windows.sh
  niri-arrange-windows.sh --dry-run
  niri-arrange-windows.sh --focus 2        # Window ID 2'ye geri odaklan
  niri-arrange-windows.sh --focus ws:2     # Workspace 2'ye geç
EOF
}

DRY_RUN=0
FOCUS_OVERRIDE=""
VERBOSE=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN=1; shift ;;
    --focus) FOCUS_OVERRIDE="${2:-}"; shift 2 ;;
    --verbose) VERBOSE=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Bilinmeyen arg: $1" >&2; usage; exit 2 ;;
  esac
done

if ! command -v niri >/dev/null 2>&1; then
  echo "niri bulunamadı (PATH)." >&2
  exit 1
fi
if ! command -v jq >/dev/null 2>&1; then
  echo "jq bulunamadı (PATH)." >&2
  exit 1
fi

NIRI=(niri msg)

rules_file="${XDG_CONFIG_HOME:-$HOME/.config}/niri/dms/workspace-rules.tsv"
declare -a RULE_PATTERNS=()
declare -a RULE_WORKSPACES=()

resolve_workspace_ref() {
  # Given a workspace *name* (often numeric like "8"), resolve it to:
  #   <output-name> <workspace-index-on-that-output>
  #
  # Why: niri CLI "workspace reference" is (index OR name). Numeric names are
  # ambiguous and get parsed as index, so we must convert name->index ourselves.
  local want_name="${1:-}"
  [[ -n "$want_name" ]] || return 1

  local current_output=""
  local line idx name

  while IFS= read -r line; do
    if [[ "$line" =~ ^Output[[:space:]]+\"([^\"]+)\": ]]; then
      current_output="${BASH_REMATCH[1]}"
      continue
    fi

    # Examples:
    #   1 "1"
    # * 2 "2"
    if [[ "$line" =~ ^[[:space:]]*\*?[[:space:]]*([0-9]+)[[:space:]]+\"([^\"]*)\" ]]; then
      idx="${BASH_REMATCH[1]}"
      name="${BASH_REMATCH[2]}"
      if [[ -n "$current_output" && "$name" == "$want_name" ]]; then
        printf '%s\t%s\n' "$current_output" "$idx"
        return 0
      fi
    fi
  done < <("${NIRI[@]}" workspaces 2>/dev/null)

  return 1
}

get_window_json_by_id() {
  local id="${1:-}"
  [[ -n "$id" ]] || return 1
  "${NIRI[@]}" -j windows 2>/dev/null | jq -c ".[] | select(.id == ${id})" 2>/dev/null
}

get_window_workspace_id_text() {
  # Fallback for older niri JSON schemas: parse `niri msg windows` text output.
  # Returns the "Workspace ID" number for a window id.
  local want_id="${1:-}"
  [[ -n "$want_id" ]] || return 1

  "${NIRI[@]}" windows 2>/dev/null | awk -v id="$want_id" '
    $1=="Window" && $2=="ID" {
      # "Window ID 8:"
      sub(":", "", $3)
      in_block = ($3 == id)
    }
    in_block && $1=="Workspace" && $2=="ID:" {
      print $3
      exit
    }
  '
}

get_window_loc() {
  # Print a compact, human-readable location string for a window JSON object.
  # Output example: name=8 id=123 out=eDP-1 idx=2
  local win_json="${1:-}"
  [[ -n "$win_json" ]] || return 1

  local ws_name ws_id ws_out ws_idx
  # NOTE: Different niri versions expose slightly different JSON shapes.
  # We keep this best-effort and prefer `workspace_id` which exists widely.
  ws_name="$(jq -r '.workspace.name // .workspace_name // empty' <<<"$win_json")"
  ws_id="$(jq -r '.workspace_id // .workspace.id // empty' <<<"$win_json")"
  ws_out="$(jq -r '.output // .output_name // .workspace.output // .workspace_output // empty' <<<"$win_json")"
  ws_idx="$(jq -r '.workspace.index // .workspace_idx // empty' <<<"$win_json")"

  printf 'name=%s id=%s out=%s idx=%s\n' "${ws_name:-?}" "${ws_id:-?}" "${ws_out:-?}" "${ws_idx:-?}"
}

load_rules() {
  local file="$1"
  [[ -f "$file" ]] || return 1

  while IFS=$'\t' read -r pattern ws; do
    [[ -z "${pattern//[[:space:]]/}" ]] && continue
    [[ "${pattern:0:1}" == "#" ]] && continue
    [[ -z "${ws//[[:space:]]/}" ]] && continue
    RULE_PATTERNS+=("$pattern")
    RULE_WORKSPACES+=("$ws")
  done <"$file"
}

if load_rules "$rules_file"; then
  :
else
  # Built-in fallback (kept minimal). Prefer the generated TSV from `modules/home/niri`.
  RULE_PATTERNS+=("^(TmuxKenp|Tmux)$")
  RULE_WORKSPACES+=("2")
  RULE_PATTERNS+=("^Kenp$")
  RULE_WORKSPACES+=("1")
  RULE_PATTERNS+=("^Ai$")
  RULE_WORKSPACES+=("3")
  RULE_PATTERNS+=("^CompecTA$")
  RULE_WORKSPACES+=("4")
  RULE_PATTERNS+=("^WebCord$")
  RULE_WORKSPACES+=("5")
  RULE_PATTERNS+=("^discord$")
  RULE_WORKSPACES+=("5")
  RULE_PATTERNS+=("^(spotify|Spotify|com\\.spotify\\.Client)$")
  RULE_WORKSPACES+=("8")
  RULE_PATTERNS+=("^ferdium$")
  RULE_WORKSPACES+=("9")
  RULE_PATTERNS+=("^org\\.keepassxc\\.KeePassXC$")
  RULE_WORKSPACES+=("7")
  RULE_PATTERNS+=("^brave-youtube\\.com__-Default$")
  RULE_WORKSPACES+=("7")
fi

focused_id="$("${NIRI[@]}" -j focused-window 2>/dev/null | jq -r '.id // empty' || true)"

target_for_app_id() {
  local app_id="${1:-}"
  [[ -z "$app_id" ]] && return 1

  local i
  for i in "${!RULE_PATTERNS[@]}"; do
    if [[ "$app_id" =~ ${RULE_PATTERNS[$i]} ]]; then
      echo "${RULE_WORKSPACES[$i]}"
      return 0
    fi
  done
  return 1
}

echo "Scanning windows..."
windows_json="$("${NIRI[@]}" -j windows)"

echo "$windows_json" | jq -c '.[]' | while read -r win; do
  id="$(jq -r '.id' <<<"$win")"
  app_id="$(jq -r '.app_id // ""' <<<"$win")"
  title="$(jq -r '.title // ""' <<<"$win")"
  current_ws_name="$(jq -r '.workspace.name // .workspace_name // empty' <<<"$win")"

  # Skip some noisy / transient surfaces.
  if [[ "$app_id" == "hyprland-share-picker" ]]; then
    continue
  fi
  if [[ -z "$app_id" && "$title" =~ ^[Pp]icture[[:space:]-]*in[[:space:]-]*[Pp]icture$ ]]; then
    continue
  fi

  target_ws=""
  if target_ws="$(target_for_app_id "$app_id" 2>/dev/null)"; then
    :
  else
    continue
  fi

  target_out=""
  target_idx=""
  if ! read -r target_out target_idx < <(resolve_workspace_ref "$target_ws"); then
    echo " !! cannot resolve workspace name '$target_ws' to output/index (niri msg workspaces)" >&2
    continue
  fi

  # Skip if already there.
  # Prefer matching by *name* when available.
  #
  # IMPORTANT: Some niri builds only expose `workspace_id` in JSON and it is an
  # index scoped to the window's *current output*. Since we cannot reliably
  # infer the output from JSON on those builds, we avoid using `workspace_id`
  # as a "already correct" signal (it would create false positives).
  if [[ -n "$current_ws_name" && "$current_ws_name" == "$target_ws" ]]; then
    [[ "$VERBOSE" -eq 1 ]] && echo " == $id: '$app_id' already on ws:$target_ws (by name)"
    continue
  fi

  echo " -> $id: '$app_id' -> ws:$target_ws (output:$target_out idx:$target_idx)"
  if [[ "$DRY_RUN" -eq 1 ]]; then
    continue
  fi

  # Move in two steps to avoid numeric-workspace ambiguity across monitors:
  # 1) Move the window to the correct output (does not require focusing).
  # 2) Move the window to the workspace index on that output.
  #
  # NOTE: `move-window-to-monitor` supports `--id` (unlike many other actions).
  if ! "${NIRI[@]}" action move-window-to-monitor --id "$id" "$target_out" >/dev/null 2>&1; then
    echo " !! move-window-to-monitor failed for id=$id -> out:$target_out" >&2
    continue
  fi

  # Workspace reference is ambiguous without focusing the target output first.
  # (Some niri versions interpret workspace indices relative to the focused output.)
  "${NIRI[@]}" action focus-monitor "$target_out" >/dev/null 2>&1 || true

  if ! "${NIRI[@]}" action move-window-to-workspace --window-id "$id" --focus false "$target_idx" >/dev/null 2>&1; then
    echo " !! move-window-to-workspace failed for id=$id -> ws:$target_ws (out:$target_out idx:$target_idx)" >&2
    continue
  fi

  # Verify (best-effort)
  after="$(get_window_json_by_id "$id" || true)"
  if [[ -n "$after" ]]; then
    after_name="$(jq -r '.workspace.name // .workspace_name // empty' <<<"$after")"
    after_id="$(jq -r '.workspace_id // .workspace.id // empty' <<<"$after")"

    if [[ -n "$after_name" && "$after_name" == "$target_ws" ]]; then
      [[ "$VERBOSE" -eq 1 ]] && echo "    ok: $(get_window_loc "$after")"
    else
      # Older JSON schemas won't include workspace name/output. We can only
      # show the raw workspace_id here, which is not sufficient to validate
      # cross-output placement.
      if [[ -n "$after_id" && "$after_id" == "$target_idx" ]]; then
        [[ "$VERBOSE" -eq 1 ]] && echo "    ok (by idx, output unknown): $(get_window_loc "$after")"
      else
        echo " !! move did not land on ws:$target_ws for id=$id ($app_id), now: $(get_window_loc "$after")" >&2
      fi
    fi
  else
    # Text fallback verification (works even when JSON schema is minimal).
    after_ws_id="$(get_window_workspace_id_text "$id" || true)"
    if [[ -n "$after_ws_id" && "$after_ws_id" == "$target_idx" ]]; then
      [[ "$VERBOSE" -eq 1 ]] && echo "    ok (text ws_id=$after_ws_id)"
    elif [[ -n "$after_ws_id" ]]; then
      echo " !! move did not land on ws:$target_ws for id=$id ($app_id), now: text ws_id=$after_ws_id" >&2
    fi
  fi
done

# Restore focus (best-effort)
if [[ -n "$FOCUS_OVERRIDE" ]]; then
  if [[ "$FOCUS_OVERRIDE" =~ ^ws:(.+)$ ]]; then
    "${NIRI[@]}" action focus-workspace "${BASH_REMATCH[1]}" >/dev/null 2>&1 || true
  else
    "${NIRI[@]}" action focus-window "$FOCUS_OVERRIDE" >/dev/null 2>&1 || true
  fi
elif [[ -n "$focused_id" ]]; then
  "${NIRI[@]}" action focus-window "$focused_id" >/dev/null 2>&1 || true
fi

echo "Done."
if command -v notify-send >/dev/null 2>&1; then
  notify-send "Niri Arranger" "Pencereler workspace'lere taşındı"
fi
