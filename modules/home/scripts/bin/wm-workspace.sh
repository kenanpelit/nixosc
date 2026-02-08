#!/usr/bin/env bash
# wm-workspace.sh
# Workspace router across compositors (Hyprland, Niri).
# Used by Fusuma (and other callers) to route workspace/monitor actions to the
# correct backend (`hypr-workspace-monitor`, `niri-osc`).
#
# Niri dispatch modes:
# - legacy short flags (`-mn`, `-mp`, `-wl`, ...) -> `niri-osc flow legacy`
# - modern subcommands (`scratchpad-toggle`, ...) -> `niri-osc flow`

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

is_niri_flow_subcommand() {
  case "${1:-}" in
    legacy|focus|focus-or-spawn|move-to-current-workspace|move-to-current-workspace-or-spawn|toggle-follow-mode|toggle-mark|focus-marked|list-marked|scratchpad-toggle|scratchpad-show|scratchpad-show-all|help|-h|--help|-V|--version)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

# systemd --user services often run with a minimal PATH; prefer common Nix profile locations.
NIRI_OSC="$(
  resolve_bin niri-osc \
    "${WM_WORKSPACE_NIRI_OSC:-}" \
    "/etc/profiles/per-user/${USER}/bin/niri-osc" \
    "${HOME}/.nix-profile/bin/niri-osc" \
    "${HOME}/.local/state/nix/profiles/profile/bin/niri-osc"
)"

HYPR_WORKSPACE_MONITOR="$(
  resolve_bin hypr-workspace-monitor \
    "${WM_WORKSPACE_HYPR_WORKSPACE_MONITOR:-}" \
    "/etc/profiles/per-user/${USER}/bin/hypr-workspace-monitor" \
    "${HOME}/.nix-profile/bin/hypr-workspace-monitor" \
    "${HOME}/.local/state/nix/profiles/profile/bin/hypr-workspace-monitor"
)"

if [[ -n "${NIRI_SOCKET:-}" ]] || [[ "${XDG_CURRENT_DESKTOP:-}" == "niri" ]] || [[ "${XDG_SESSION_DESKTOP:-}" == "niri" ]]; then
  if [[ -n "${NIRI_OSC:-}" ]]; then
    if [[ $# -gt 0 ]]; then
      first_arg="$1"
      if [[ "${first_arg}" == "flow" ]]; then
        shift
        exec "${NIRI_OSC}" flow "$@"
      fi
      if [[ "${first_arg}" == -* ]]; then
        exec "${NIRI_OSC}" flow legacy "$@"
      fi
      if is_niri_flow_subcommand "${first_arg}"; then
        exec "${NIRI_OSC}" flow "$@"
      fi
      exec "${NIRI_OSC}" flow legacy "$@"
    fi

    exec "${NIRI_OSC}" flow --help
  else
    echo "niri-osc not found in PATH" >&2
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
