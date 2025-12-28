#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF' >&2
Usage:
  dms-ipc [call] <target> <function> [args...]
  dms-ipc show
  dms-ipc prop ...

Notes:
  - Uses quickshell IPC with `--any-display` to avoid DISPLAY/WAYLAND_DISPLAY
    filtering issues in mixed Wayland + XWayland environments.
  - Reads the active DMS config path from $XDG_RUNTIME_DIR/danklinux.path.
EOF
}

runtime_dir="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
state_file="$runtime_dir/danklinux.path"

ensure_state_file() {
  [[ -f "$state_file" ]] && return 0

  if command -v systemctl >/dev/null 2>&1; then
    systemctl --user start dms.service >/dev/null 2>&1 || true
    for _ in $(seq 1 50); do
      [[ -f "$state_file" ]] && return 0
      sleep 0.1
    done
  fi

  return 1
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

if [[ $# -eq 0 ]]; then
  usage
  exit 2
fi

if ! ensure_state_file; then
  echo "dms-ipc: DMS config state not found at: $state_file" >&2
  echo "dms-ipc: is dms.service running?" >&2
  exit 1
fi

config_path="$(tr -d '\r' <"$state_file" | head -n 1 | tr -d '[:space:]' || true)"
if [[ -z "${config_path:-}" ]]; then
  echo "dms-ipc: empty config path in: $state_file" >&2
  exit 1
fi

subcmd="${1:-}"
case "$subcmd" in
  call|show|prop) ;;
  *)
    set -- call "$@"
    ;;
esac

exec qs ipc --any-display --newest -p "$config_path" "$@"

