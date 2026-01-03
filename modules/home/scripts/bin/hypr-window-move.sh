#!/usr/bin/env bash
# hypr-window-move.sh
# Small Hyprland helper for moving the focused window:
# - to previous/next workspace (within per-monitor ranges)
# - to the other monitor (by moving to its active workspace)

set -euo pipefail

: "${XDG_RUNTIME_DIR:="/run/user/$(id -u)"}"

if [[ -z "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
  if first_sig="$(ls "$XDG_RUNTIME_DIR"/hypr 2>/dev/null | head -n1)"; then
    export HYPRLAND_INSTANCE_SIGNATURE="$first_sig"
  fi
fi

usage() {
  cat >&2 <<'EOF'
Usage:
  hypr-window-move workspace prev|next
  hypr-window-move monitor other
EOF
}

if ! command -v hyprctl >/dev/null 2>&1; then
  exit 0
fi

if ! command -v jq >/dev/null 2>&1; then
  exit 0
fi

cmd="${1:-}"
shift || true

case "$cmd" in
  workspace)
    direction="${1:-}"
    case "$direction" in
      prev|next) ;;
      *) usage; exit 1 ;;
    esac

    active="$(hyprctl activewindow -j 2>/dev/null || echo '{}')"
    addr="$(jq -r '.address // empty' <<<"$active")"
    ws_id="$(jq -r '.workspace.id // empty' <<<"$active")"

    [[ -z "${addr}" || -z "${ws_id}" ]] && exit 0
    [[ "${ws_id}" =~ ^-?[0-9]+$ ]] || exit 0

    ws_id="$((ws_id))"
    (( ws_id > 0 )) || exit 0

    start=""
    end=""
    wrap=false

    if (( ws_id >= 1 && ws_id <= 6 )); then
      start=1
      end=6
      wrap=true
    elif (( ws_id >= 7 && ws_id <= 9 )); then
      start=7
      end=9
      wrap=true
    fi

    target="$ws_id"
    if [[ "$direction" == "prev" ]]; then
      if $wrap; then
        if (( ws_id <= start )); then
          target="$end"
        else
          target="$((ws_id - 1))"
        fi
      else
        (( ws_id > 1 )) || exit 0
        target="$((ws_id - 1))"
      fi
    else
      if $wrap; then
        if (( ws_id >= end )); then
          target="$start"
        else
          target="$((ws_id + 1))"
        fi
      else
        target="$((ws_id + 1))"
      fi
    fi

    [[ "$target" == "$ws_id" ]] && exit 0
    hyprctl dispatch movetoworkspacesilent "$target,address:$addr" >/dev/null 2>&1 || true
    ;;

  monitor)
    action="${1:-}"
    case "$action" in
      other) ;;
      *) usage; exit 1 ;;
    esac

    active="$(hyprctl activewindow -j 2>/dev/null || echo '{}')"
    addr="$(jq -r '.address // empty' <<<"$active")"
    cur_mon="$(jq -r '.monitor // empty' <<<"$active")"

    [[ -z "${addr}" || -z "${cur_mon}" ]] && exit 0
    [[ "${cur_mon}" =~ ^-?[0-9]+$ ]] || exit 0

    monitors="$(hyprctl monitors -j 2>/dev/null || echo '[]')"
    target_ws="$(
      jq -r --argjson cur "$cur_mon" '
        [ .[]
          | select((.id // -1) != $cur)
          | .activeWorkspace.id // empty
        ][0] // empty
      ' <<<"$monitors"
    )"

    [[ -z "${target_ws}" || "${target_ws}" == "null" ]] && exit 0
    hyprctl dispatch movetoworkspacesilent "$target_ws,address:$addr" >/dev/null 2>&1 || true
    ;;

  *)
    usage
    exit 1
    ;;
esac

