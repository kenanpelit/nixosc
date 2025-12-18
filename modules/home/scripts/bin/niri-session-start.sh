#!/usr/bin/env bash
# ==============================================================================
# niri-session-start - Export Wayland session env to systemd --user and start
# niri-session.target.
#
# Why:
# - Services started by systemd --user (e.g. clipse) won't automatically get
#   compositor-provided env vars like WAYLAND_DISPLAY unless we import them.
# - Running this from niri's `spawn-at-startup` ensures the variables exist.
# ==============================================================================

set -euo pipefail

LOG_TAG="niri-session-start"
log() { printf '[%s] %s\n' "$LOG_TAG" "$*" >&2; }

ensure_runtime_dir() {
  if [[ -n "${XDG_RUNTIME_DIR:-}" ]]; then
    return 0
  fi

  local uid
  uid="$(id -u 2>/dev/null || true)"
  if [[ -n "$uid" ]]; then
    export XDG_RUNTIME_DIR="/run/user/$uid"
  fi
}

detect_wayland_display() {
  if [[ -n "${WAYLAND_DISPLAY:-}" ]]; then
    return 0
  fi

  [[ -n "${XDG_RUNTIME_DIR:-}" ]] || return 0

  local sock
  for sock in "${XDG_RUNTIME_DIR}"/wayland-*; do
    [[ -S "$sock" ]] || continue
    export WAYLAND_DISPLAY
    WAYLAND_DISPLAY="$(basename "$sock")"
    return 0
  done
}

detect_niri_socket() {
  if [[ -n "${NIRI_SOCKET:-}" ]]; then
    return 0
  fi

  [[ -n "${XDG_RUNTIME_DIR:-}" ]] || return 0
  [[ -n "${WAYLAND_DISPLAY:-}" ]] || return 0

  shopt -s nullglob
  local sock
  for sock in "${XDG_RUNTIME_DIR}/niri.${WAYLAND_DISPLAY}."*.sock; do
    [[ -S "$sock" ]] || continue
    export NIRI_SOCKET="$sock"
    break
  done
  shopt -u nullglob
}

import_env_to_systemd() {
  if ! command -v systemctl >/dev/null 2>&1; then
    log "systemctl not found; skipping env import"
    return 0
  fi

  local vars=(
    WAYLAND_DISPLAY
    NIRI_SOCKET
    XDG_CURRENT_DESKTOP
    XDG_SESSION_TYPE
    XDG_SESSION_DESKTOP
    DESKTOP_SESSION
    SSH_AUTH_SOCK
    NIXOS_OZONE_WL
    MOZ_ENABLE_WAYLAND
    QT_QPA_PLATFORM
    QT_WAYLAND_DISABLE_WINDOWDECORATION
    ELECTRON_OZONE_PLATFORM_HINT
  )

  systemctl --user import-environment "${vars[@]}" 2>/dev/null || true

  if command -v dbus-update-activation-environment >/dev/null 2>&1; then
    dbus-update-activation-environment --systemd "${vars[@]}" 2>/dev/null || true
  fi
}

start_target() {
  if ! command -v systemctl >/dev/null 2>&1; then
    log "systemctl not found; cannot start niri-session.target"
    return 0
  fi

  systemctl --user start niri-session.target 2>/dev/null || true
}

ensure_runtime_dir
detect_wayland_display
detect_niri_socket
import_env_to_systemd
start_target
