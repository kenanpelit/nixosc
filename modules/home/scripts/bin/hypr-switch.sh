#!/usr/bin/env bash
# hypr-switch - focused monitor/workspace switch helper for Hyprland

set -euo pipefail

DEFAULT_WORKSPACE="${HYPR_SWITCH_DEFAULT_WORKSPACE:-2}"
PRIMARY_MONITOR="${HYPR_SWITCH_PRIMARY_MONITOR:-eDP-1}"
SLEEP_DURATION="${HYPR_SWITCH_SLEEP_DURATION:-0.2}"
NOTIFY=1

notify() {
  [[ "${NOTIFY}" == "1" ]] || return 0
  local title="$1"
  local body="$2"
  if command -v dunstify >/dev/null 2>&1; then
    dunstify -t 2500 -u normal "${title}" "${body}" >/dev/null 2>&1 || true
  elif command -v notify-send >/dev/null 2>&1; then
    notify-send -t 2500 "${title}" "${body}" >/dev/null 2>&1 || true
  fi
}

usage() {
  cat <<'EOF'
Usage:
  hypr-switch [options] [workspace]

Options:
  -h, --help           Show help
  -l, --list           List monitors and active workspaces
  -m, --monitor NAME   Force target monitor
  -p, --primary        Force primary monitor
  -t, --timeout SEC    Delay between monitor focus and workspace switch
  -n, --no-notify      Disable notifications
EOF
}

list_state() {
  printf '%s\n' "Monitors:"
  hyprctl monitors -j | jq -r '.[] | "  \(.name)\t\(.width)x\(.height)@\(.refreshRate|floor)Hz\tfocused=\(.focused)\tws=\(.activeWorkspace.name)"'
}

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "hypr-switch: missing dependency: $1" >&2
    exit 127
  }
}

monitor_exists() {
  local mon="$1"
  hyprctl monitors -j | jq -e --arg mon "${mon}" '.[] | select(.name == $mon)' >/dev/null 2>&1
}

focused_monitor() {
  hyprctl monitors -j | jq -r '.[] | select(.focused==true) | .name' | head -n1
}

first_external_monitor() {
  hyprctl monitors -j | jq -r --arg primary "${PRIMARY_MONITOR}" '.[] | select(.name != $primary) | .name' | head -n1
}

target_monitor=""
force_primary=0
workspace="${DEFAULT_WORKSPACE}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
      usage
      exit 0
      ;;
    -l|--list)
      list_state
      exit 0
      ;;
    -m|--monitor)
      target_monitor="${2:-}"
      [[ -n "${target_monitor}" ]] || {
        echo "hypr-switch: --monitor requires a value" >&2
        exit 2
      }
      shift 2
      ;;
    -p|--primary)
      force_primary=1
      shift
      ;;
    -t|--timeout)
      SLEEP_DURATION="${2:-}"
      [[ -n "${SLEEP_DURATION}" ]] || {
        echo "hypr-switch: --timeout requires a value" >&2
        exit 2
      }
      shift 2
      ;;
    -n|--no-notify)
      NOTIFY=0
      shift
      ;;
    *)
      workspace="$1"
      shift
      ;;
  esac
done

need_cmd hyprctl
need_cmd jq
hyprctl version >/dev/null 2>&1 || {
  echo "hypr-switch: cannot connect to Hyprland IPC" >&2
  exit 1
}

if ! [[ "${workspace}" =~ ^[0-9]+$ ]]; then
  echo "hypr-switch: workspace must be numeric" >&2
  exit 2
fi

if [[ "${force_primary}" == "1" ]]; then
  target_monitor="${PRIMARY_MONITOR}"
elif [[ -z "${target_monitor}" ]]; then
  target_monitor="$(first_external_monitor)"
  if [[ -z "${target_monitor}" ]]; then
    target_monitor="${PRIMARY_MONITOR}"
  fi
fi

if ! monitor_exists "${target_monitor}"; then
  echo "hypr-switch: monitor not found: ${target_monitor}" >&2
  exit 1
fi

current_monitor="$(focused_monitor)"

hyprctl dispatch focusmonitor "${target_monitor}" >/dev/null 2>&1 || true
sleep "${SLEEP_DURATION}"
hyprctl dispatch workspace "${workspace}" >/dev/null 2>&1 || true

notify "Hyprland" "Monitor: ${current_monitor:-?} -> ${target_monitor}, workspace: ${workspace}"
