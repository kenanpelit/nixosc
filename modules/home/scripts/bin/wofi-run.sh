#!/usr/bin/env bash
#===============================================================================
#   Script: Advanced Wofi Runner
#   Version: 1.1.0
#   Description: Enhanced run dialog with history and suggestions
#===============================================================================

VERSION="1.1.0"
HISTORY_FILE="$HOME/.cache/wofi-runner-history"
MAX_HISTORY=100
WOFI_CONFIG="$HOME/.config/wofi/configs/run"
WOFI_STYLE="$HOME/.config/wofi/styles/run.css"

export PATH="$HOME/.bin:$PATH"

clean_history() {
  [[ -f "$HISTORY_FILE" ]] && {
    awk '!seen[$0]++ && NF' "$HISTORY_FILE" | tail -n "$MAX_HISTORY" >"$HISTORY_FILE.tmp"
    mv "$HISTORY_FILE.tmp" "$HISTORY_FILE"
  }
}

get_commands() {
  (
    [[ -f "$HISTORY_FILE" ]] && cat "$HISTORY_FILE"
    (ls ~/.bin 2>/dev/null) | sort
    compgen -c | sort -u
  ) | awk '!seen[$0]++' | sort | head -n "$MAX_HISTORY"
}

clean_history

selected=$(get_commands | wofi \
  --show run \
  --prompt "Run:" \
  --conf "$WOFI_CONFIG" \
  --style "$WOFI_STYLE" \
  --sort-order alphabetical \
  --insensitive)

[[ -n "$selected" ]] && {
  echo "$selected" >>"$HISTORY_FILE"
  setsid -f $selected >/dev/null 2>&1
}
