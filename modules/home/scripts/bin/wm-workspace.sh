#!/usr/bin/env bash
# wm-workspace.sh
# Workspace router across compositors (Hyprland, Niri).
# Used by Fusuma (and other callers) to route workspace/monitor actions to the
# correct backend (`hypr-workspace-monitor`, `niri-set flow`).

set -euo pipefail

resolve_bin() {
  local name="$1"
  shift || true

  local candidates=("$@")
  local c
  for c in "${candidates[@]}"; do
    [[ -n "${c:-}" && -x "${c}" ]] && { printf '%s\n' "${c}"; return 0; }
  done

  command -v "${name}" 2>/dev/null || true
}

# systemd --user services often run with a minimal PATH; prefer common Nix profile locations.
NIRI_SET="$(
  resolve_bin niri-set \
    "${WM_WORKSPACE_NIRI_SET:-}" \
    "/etc/profiles/per-user/${USER}/bin/niri-set" \
    "${HOME}/.nix-profile/bin/niri-set" \
    "${HOME}/.local/state/nix/profiles/profile/bin/niri-set"
)"

HYPR_WORKSPACE_MONITOR="$(
  resolve_bin hypr-workspace-monitor \
    "${WM_WORKSPACE_HYPR_WORKSPACE_MONITOR:-}" \
    "/etc/profiles/per-user/${USER}/bin/hypr-workspace-monitor" \
    "${HOME}/.nix-profile/bin/hypr-workspace-monitor" \
    "${HOME}/.local/state/nix/profiles/profile/bin/hypr-workspace-monitor"
)"

if [[ -n "${NIRI_SOCKET:-}" ]] || [[ "${XDG_CURRENT_DESKTOP:-}" == "niri" ]] || [[ "${XDG_SESSION_DESKTOP:-}" == "niri" ]]; then
  if [[ -n "${NIRI_SET:-}" ]]; then
    exec "${NIRI_SET}" flow "$@"
  else
    echo "niri-set not found in PATH" >&2
    exit 1
  fi
else
  if [[ -n "${HYPR_WORKSPACE_MONITOR:-}" ]]; then
    exec "${HYPR_WORKSPACE_MONITOR}" "$@"
  else
    echo "hypr-workspace-monitor not found in PATH" >&2
    exit 1
  fi
fi
