#!/usr/bin/env bash
# ==============================================================================
# niri-set - Niri session helper multiplexer
# ==============================================================================
# Single entrypoint for Niri helper tasks that used to live in separate scripts:
#   - tty
#   - env
#   - init
#   - lock
#   - go (arrange-windows)
#   - here
#   - cast
#   - flow
#   - doctor
#
# Usage:
#   niri-set <subcommand> [args...]
#
# This file is intentionally self-contained because `modules/home/scripts/bin.nix`
# packages each `*.sh` file as a standalone binary.
# ==============================================================================

set -euo pipefail

start_clipse_listener() {
  command -v clipse >/dev/null 2>&1 || return 0

  if command -v pgrep >/dev/null 2>&1; then
    if pgrep -af 'clipse.*-listen' >/dev/null 2>&1; then
      return 0
    fi
    # Newer clipse versions spawn wl-paste watchers and exit (no long-running
    # `clipse -listen` process). Detect them to avoid starting duplicates.
    if pgrep -af 'wl-paste.*--watch clipse' >/dev/null 2>&1; then
      return 0
    fi
  fi

  # `-listen` starts the monitor in the background and exits quickly.
  clipse -listen >/dev/null 2>&1 || true
}

usage() {
  cat <<'EOF'
Usage:
  niri-set <command> [args...]

Commands:
  tty                Start Niri from TTY/DM (was: niri_tty)
  clipse             Start clipse clipboard listener (background)
  env                Export env to systemd --user (was: niri-session-start)
  init               Bootstrap session (was: niri-init)
  lock               Lock session via DMS/logind (was: niri-lock)
  go                 Move windows to target workspaces (was: niri-arrange-windows)
  here               Bring window here (or launch); `all` gathers a set
  cast               Dynamic screencast helpers (window/monitor/clear/pick)
  flow               Workspace/monitor helper (was: niri-workspace-monitor)
  doctor             Print session diagnostics (try: --tree, --logs)
  float              Toggle between floating and tiling modes with preset size
  zen                Toggle Zen Mode (hide gaps, borders, bar)
  pin                Toggle Pin Mode (PIP-style floating window)

Examples:
  niri-set env
  niri-set lock
  niri-set zen
  niri-set pin
EOF
}

cmd="${1:-}"
shift || true

case "${cmd}" in
zen)
  # ----------------------------------------------------------------------------
  # Zen Mode: Toggle gaps, borders, and bar (State-file based)
  # ----------------------------------------------------------------------------
  (
    set -euo pipefail

    STATE_FILE="${XDG_RUNTIME_DIR:-/tmp}/niri-zen.state"
    ZEN_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/niri/dms/zen.kdl"

    ensure_zen_file() {
      mkdir -p "$(dirname "$ZEN_FILE")" 2>/dev/null || true
      if [[ -L "$ZEN_FILE" ]]; then
        rm -f "$ZEN_FILE" 2>/dev/null || true
      fi
      [[ -f "$ZEN_FILE" ]] || : >"$ZEN_FILE"
    }

    enable_zen_config() {
      cat >"$ZEN_FILE" <<'EOF'
layout {
  gaps 0;

  border {
    off;
  }

  focus-ring {
    off;
  }

  tab-indicator {
    off;
  }

  insert-hint {
    off;
  }
}
EOF
    }

    disable_zen_config() {
      : >"$ZEN_FILE"
    }

    reload_config() {
      # Newer niri versions live-reload included files; keep this as a fallback.
      niri msg action load-config-file >/dev/null 2>&1 || true
    }

    notify() {
      command -v notify-send >/dev/null 2>&1 || return 0
      notify-send -t 1000 "Zen Mode" "${1:-}" 2>/dev/null || true
    }

    if [[ -f "$STATE_FILE" ]]; then
      # === DISABLE ZEN (Restore) ===

      ensure_zen_file
      disable_zen_config
      reload_config

      # Restore DMS Bar
      dms ipc call bar toggle index 0 >/dev/null 2>&1 || true
      dms ipc call notifications toggle-dnd >/dev/null 2>&1 || true

      rm -f "$STATE_FILE"
      notify "Off"
      echo "Zen Mode: Off"
    else
      # === ENABLE ZEN ===

      ensure_zen_file
      enable_zen_config
      reload_config

      # Hide Bar
      dms ipc call bar toggle index 0 >/dev/null 2>&1 || true
      # Silence Notifications
      dms ipc call notifications toggle-dnd >/dev/null 2>&1 || true

      touch "$STATE_FILE"
      notify "On"
      echo "Zen Mode: On"
    fi
  )
  ;;

pin)
  # ----------------------------------------------------------------------------
  # Pin Mode: Toggle PIP-style floating window (Robust Read-Move-Verify)
  # ----------------------------------------------------------------------------
  (
    set -euo pipefail

    # Helper: Get focused window geometry (x y w h) with retry
    get_window_geo() {
      for _ in {1..10}; do
        local out
        out="$(niri msg -j focused-window 2>/dev/null)"
        if [[ -n "$out" ]]; then
          local x y w h
          x="$(echo "$out" | jq -r '.workspace_view_position.x? // empty')"
          y="$(echo "$out" | jq -r '.workspace_view_position.y? // empty')"
          w="$(echo "$out" | jq -r '.window_size.width? // empty')"
          h="$(echo "$out" | jq -r '.window_size.height? // empty')"

          if [[ -n "$x" && -n "$y" && -n "$w" && -n "$h" ]]; then
            echo "$x $y $w $h"
            return 0
          fi
        fi
        sleep 0.05
      done
      return 1
    }

    # Helper: Get focused output dimensions (w h)
    get_output_dim() {
      local out
      out="$(niri msg -j focused-output 2>/dev/null)"
      if [[ -n "$out" ]]; then
        # Try multiple fields for dimensions with safety checks (?)
        echo "$out" | jq -r '(.current_mode.width? // .mode.width? // .geometry.width? // 0) as $w | (.current_mode.height? // .mode.height? // .geometry.height? // 0) as $h | "\($w) \($h)"' 2>/dev/null
      else
        echo "0 0"
      fi
    }

    win_json="$(niri msg -j focused-window 2>/dev/null)"
    if [[ -z "$win_json" ]]; then exit 0; fi

    is_floating="$(echo "$win_json" | jq -r '.is_floating // false')"
    current_w="$(echo "$win_json" | jq -r '.window_size.width // 0')"

    if [[ "$is_floating" == "true" ]] && [[ "$current_w" -lt 500 ]]; then
      # Restore
      niri msg action move-window-to-tiling >/dev/null 2>&1 || true
      niri msg action reset-window-height >/dev/null 2>&1 || true
    else
      # Pin
      if [[ "$is_floating" == "false" ]]; then
        niri msg action move-window-to-floating >/dev/null 2>&1 || true
      fi

      # 1. Resize
      target_w=640
      target_h=360
      niri msg action set-window-width "$target_w" >/dev/null 2>&1 || true
      niri msg action set-window-height "$target_h" >/dev/null 2>&1 || true

      # 2. Loop to move to exact target
      read -r ow oh <<<"$(get_output_dim)"

      # Sanity Check: If output detection failed or returned garbage, use primary monitor defaults
      # Dell UP2716D: 2560x1440
      if [[ "$ow" -lt 100 || "$oh" -lt 100 ]]; then
        ow=2560
        oh=1440
      fi

      margin_x=32
      margin_y=96

      # Target: Top-Right
      tx=$((ow - target_w - margin_x))
      ty=$((margin_y))

      # Safety clamp: Ensure we don't target off-screen negative coordinates
      if [[ "$tx" -lt 0 ]]; then tx=0; fi
      if [[ "$ty" -lt 0 ]]; then ty=0; fi

      for _ in {1..2}; do
        # Read current pos
        read -r cx cy cw ch <<<"$(get_window_geo)"

        # Calculate delta
        dx=$((tx - cx))
        dy=$((ty - cy))

        if [[ "$dx" -eq 0 && "$dy" -eq 0 ]]; then
          break
        fi

        niri msg action move-floating-window -x "$dx" -y "$dy" >/dev/null 2>&1 || true
        sleep 0.1
      done
    fi
  )
  ;;

here)
  # ----------------------------------------------------------------------------
  # Embedded: osc-here logic (Bring window here OR launch)
  # ----------------------------------------------------------------------------
  (
    set -euo pipefail

    # Notification setting: 0 (off), 1 (on)
    NOTIFY_ENABLED="${OSC_HERE_NOTIFY:-0}"

    # Default list for 'all' command
    DEFAULT_APPS=(
      "Kenp"
      "TmuxKenp"
      "Ai"
      "CompecTA"
      "WebCord"
      #"org.telegram.desktop"
      "brave-youtube.com__-Default"
      "spotify"
      "ferdium"
    )

    send_notify() {
      local msg="$1"
      local urgency="${2:-normal}"

      # Only show normal notifications if enabled
      if [[ "$urgency" == "normal" && "$NOTIFY_ENABLED" != "1" ]]; then
        return 0
      fi

      if command -v notify-send >/dev/null 2>&1; then
        notify-send -t 2000 -u "$urgency" -i "system-run" "Niri" "$msg"
      fi
    }

    # Helper function to process a single app
    process_app() {
      local APP_ID="$1"

      # --- 1. Try to pull existing window (Nirius) ---
      if command -v nirius >/dev/null 2>&1; then
        if nirius move-to-current-workspace --app-id "^${APP_ID}$" --focus >/dev/null 2>&1; then
          send_notify "<b>$APP_ID</b> moved to current workspace."
          return 0
        fi
      fi

      # --- 2. Check if it's already here but not focused ---
      if command -v niri >/dev/null 2>&1 && command -v jq >/dev/null 2>&1; then
        window_id=$(niri msg -j windows | jq -r --arg app "$APP_ID" '.[] | select(.app_id == $app) | .id' | head -n1)
        if [[ -n "$window_id" ]]; then
          niri msg action focus-window --id "$window_id"
          send_notify "<b>$APP_ID</b> focused."
          return 0
        fi
      fi

      # --- 3. Launching logic (Window not found) ---
      send_notify "Launching <b>$APP_ID</b>..."

      case "$APP_ID" in
      "Kenp") start-brave-kenp >/dev/null 2>&1 & ;;
      "TmuxKenp") start-kkenp >/dev/null 2>&1 & ;;
      "Ai") start-brave-ai >/dev/null 2>&1 & ;;
      "CompecTA") start-brave-compecta >/dev/null 2>&1 & ;;
      "WebCord") start-webcord >/dev/null 2>&1 & ;;
      #"org.telegram.desktop") Telegram >/dev/null 2>&1 & ;;
      "brave-youtube.com__-Default") start-brave-youtube >/dev/null 2>&1 & ;;
      "spotify") start-spotify >/dev/null 2>&1 & ;;
      "ferdium") start-ferdium >/dev/null 2>&1 & ;;
      "discord") start-discord >/dev/null 2>&1 & ;;
      "kitty") kitty >/dev/null 2>&1 & ;;
      *)
        if command -v "$APP_ID" >/dev/null 2>&1; then
          "$APP_ID" >/dev/null 2>&1 &
        else
          send_notify "Error: No start command found for <b>$APP_ID</b>" "critical"
        fi
        ;;
      esac
    }

    APP_ID="${1:-}"
    LIST="${2:-}"

    if [[ -z "$APP_ID" ]]; then
      echo "Error: App ID is required."
      exit 1
    fi

    if [[ "$APP_ID" == "all" ]]; then
      # Process list
      if [[ -n "$LIST" ]]; then
        IFS=',' read -ra APPS <<<"$LIST"
      else
        APPS=("${DEFAULT_APPS[@]}")
      fi

      for app in "${APPS[@]}"; do
        process_app "$app"
        # Small delay to let Niri process moves smoothly
        sleep 0.1
      done

      # Explicit workflow: always end focused on Kenp.
      process_app "Kenp"

      send_notify "All specified apps gathered here."
    else
      # Process single app
      process_app "$APP_ID"
    fi
  )
  ;;

clipse)
  start_clipse_listener
  ;;

tty)
  # ----------------------------------------------------------------------------
  # Embedded: niri_tty.sh
  # ----------------------------------------------------------------------------
  (
    set -euo pipefail

    # =============================================================================
    # Niri Universal Launcher - TTY & GDM Compatible
    # =============================================================================
    # Based on hyprland_tty.sh
    # Optimized for Niri compositor + DankMaterialShell integration
    # =============================================================================

    # =============================================================================
    # Sabit Değişkenler
    # =============================================================================
    readonly SCRIPT_NAME="$(basename "$0")"
    readonly SCRIPT_VERSION="1.2.0-niri"
    LOG_DIR="$HOME/.logs"
    NIRI_LOG="$LOG_DIR/niri.log"
    DEBUG_LOG="$LOG_DIR/niri_debug.log"
    readonly MAX_LOG_SIZE=10485760 # 10MB
    readonly MAX_LOG_BACKUPS=3

    # Terminal renk kodları
    readonly C_GREEN='\033[0;32m'
    readonly C_BLUE='\033[0;34m'
    readonly C_YELLOW='\033[1;33m'
    readonly C_RED='\033[0;31m'
    readonly C_CYAN='\033[0;36m'
    readonly C_MAGENTA='\033[0;35m'
    readonly C_RESET='\033[0m'

    # Catppuccin flavor ve accent
    CATPPUCCIN_FLAVOR="${CATPPUCCIN_FLAVOR:-mocha}"
    CATPPUCCIN_ACCENT="${CATPPUCCIN_ACCENT:-mauve}"

    # Mode flags
    DEBUG_MODE=false
    DRY_RUN=false
    GDM_MODE=false
    FORCE_TTY_MODE=false

    # =============================================================================
    # GDM Detection
    # =============================================================================
    detect_gdm_session() {
      if [[ "$FORCE_TTY_MODE" == "true" ]]; then
        GDM_MODE=false
        return 0
      fi

      if [[ -n "${GDMSESSION:-}" ]] ||
        [[ "${XDG_SESSION_CLASS:-}" == "user" ]] ||
        [[ -n "${DBUS_SESSION_BUS_ADDRESS:-}" && -n "${XDG_SESSION_ID:-}" ]] ||
        [[ "$(loginctl show-session "$XDG_SESSION_ID" -p Type 2>/dev/null)" == *"wayland"* ]]; then
        GDM_MODE=true
      else
        GDM_MODE=false
      fi
    }

    # =============================================================================
    # Logging Fonksiyonları
    # =============================================================================
    debug_log() {
      local message="$1"
      local timestamp
      timestamp=$(date '+%Y-%m-%d %H:%M:%S')
      local full_msg="[${timestamp}] [DEBUG] ${message}"

      if [[ "$DEBUG_MODE" != "true" ]]; then
        echo "$full_msg" >>"$DEBUG_LOG" 2>/dev/null || true
        return
      fi

      echo -e "${C_CYAN}[DEBUG]${C_RESET} $message" >&2
      echo "$full_msg" >>"$DEBUG_LOG" 2>/dev/null || true
    }

    log() {
      local level="$1"
      local message="$2"
      local timestamp
      timestamp=$(date '+%Y-%m-%d %H:%M:%S')
      local log_entry="[${timestamp}] [${level}] ${message}"

      if [[ -d "$(dirname "$NIRI_LOG")" ]]; then
        echo "$log_entry" >>"$NIRI_LOG" 2>/dev/null || true
      fi
      debug_log "$message"
    }

    info() {
      local message="$1"
      echo -e "${C_GREEN}[INFO]${C_RESET} $message"
      log "INFO" "$message"
    }

    warn() {
      local message="$1"
      echo -e "${C_YELLOW}[WARN]${C_RESET} $message" >&2
      log "WARN" "$message"
    }

    error() {
      local message="$1"
      echo -e "${C_RED}[ERROR]${C_RESET} $message" >&2
      log "ERROR" "$message"
      exit 1
    }

    print_header() {
      local text="$1"
      echo
      echo -e "${C_BLUE}╔════════════════════════════════════════════════════════════╗${C_RESET}"
      echo -e "${C_BLUE}║  ${C_GREEN}${text}${C_RESET}"
      echo -e "${C_BLUE}╚════════════════════════════════════════════════════════════╝${C_RESET}"
      echo
    }

    # =============================================================================
    # Dizin ve Log Yönetimi
    # =============================================================================
    setup_directories() {
      if [[ "$GDM_MODE" == "true" ]]; then return 0; fi

      if ! mkdir -p "$LOG_DIR" 2>/dev/null; then
        LOG_DIR="/tmp/niri-logs-$USER"
        NIRI_LOG="$LOG_DIR/niri.log"
        DEBUG_LOG="$LOG_DIR/niri_debug.log"
        mkdir -p "$LOG_DIR"
      fi
      touch "$NIRI_LOG" "$DEBUG_LOG"
    }

    rotate_logs() {
      if [[ "$GDM_MODE" == "true" ]] || [[ ! -f "$NIRI_LOG" ]]; then return 0; fi

      local file_size
      file_size=$(stat -c%s "$NIRI_LOG" 2>/dev/null || echo 0)
      if [[ $file_size -gt $MAX_LOG_SIZE ]]; then
        mv "$NIRI_LOG" "${NIRI_LOG}.old.0"
        touch "$NIRI_LOG"
      fi
    }

    # =============================================================================
    # Sistem Kontrolleri
    # =============================================================================
    check_system() {
      if [[ -z "${XDG_RUNTIME_DIR:-}" ]]; then
        export XDG_RUNTIME_DIR="/run/user/$(id -u)"
      fi

      # Prefer starting via `niri-session` (systemd user session integration).
      # We prevent recursion in `.zprofile` using `NIRI_TTY_GUARD`.
      if command -v niri-session &>/dev/null; then
        NIRI_BINARY="niri-session"
      elif command -v niri &>/dev/null; then
        NIRI_BINARY="niri"
        warn "niri-session bulunamadı, fallback: niri --session (user services/targets çalışmayabilir)"
      else
        error "niri veya niri-session bulunamadı!"
      fi
    }

    # =============================================================================
    # Environment Setup
    # =============================================================================
    setup_environment() {
      print_header "ENVIRONMENT SETUP - NIRI"

      # Ensure systemd user services are not blocked in Nix environments.
      export SYSTEMD_OFFLINE=0
      debug_log "✓ SYSTEMD_OFFLINE=0 set"

      # NixOS: setuid sudo wrapper lives here; ensure it wins over /run/current-system/sw/bin/sudo.
      case ":${PATH:-}:" in
      *":/run/wrappers/bin:"*) ;;
      *) export PATH="/run/wrappers/bin:${PATH:-}" ;;
      esac

      # Minimal session identity. Detailed env (theme, cursor, toolkit hints) is set
      # in Niri config and exported to systemd via `niri-set env`.
      export XDG_SESSION_TYPE="wayland"
      export XDG_SESSION_DESKTOP="niri"
      export XDG_CURRENT_DESKTOP="niri"
      export DESKTOP_SESSION="niri"

      info "Environment setup tamamlandı"
    }

    # =============================================================================
    # Systemd Integration
    # =============================================================================
    setup_systemd_integration() {
      # NOTE:
      # systemctl/dbus çağrıları bazı TTY login senaryolarında bloklayıcı olabiliyor.
      # Bu yüzden hepsi best-effort + kısa timeout ile.
      local timeout_bin=""
      if command -v timeout >/dev/null 2>&1; then
        timeout_bin="timeout"
      fi

      # Import environment to systemd user session
      local vars="WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE XDG_SESSION_DESKTOP GTK_THEME XCURSOR_THEME BROWSER SYSTEMD_OFFLINE NIXOS_OZONE_WL"

      local rc=0
      if [[ -n "$timeout_bin" ]]; then
        $timeout_bin 2s systemctl --user import-environment $vars 2>/dev/null
        rc=$?
      else
        systemctl --user import-environment $vars 2>/dev/null
        rc=$?
      fi
      if [[ "$rc" -eq 0 ]]; then
        debug_log "Systemd environment import başarılı"
      else
        warn "Systemd import başarısız (systemd user session yok olabilir)"
      fi

      rc=0
      if [[ -n "$timeout_bin" ]]; then
        $timeout_bin 2s dbus-update-activation-environment --systemd --all 2>/dev/null
        rc=$?
      else
        dbus-update-activation-environment --systemd --all 2>/dev/null
        rc=$?
      fi
      if [[ "$rc" -eq 0 ]]; then
        debug_log "DBus activation environment güncellendi"
      else
        warn "DBus update başarısız"
      fi

      # Restart critical user services for correct environment
      if [[ "$GDM_MODE" == "true" ]]; then
        if [[ -n "$timeout_bin" ]]; then
          $timeout_bin 2s systemctl --user restart dms.service 2>/dev/null || true
        else
          systemctl --user restart dms.service 2>/dev/null || true
        fi
      fi
    }

    # =============================================================================
    # Cleanup old Niri processes (TTY mode)
    # =============================================================================
    cleanup_old_processes() {
      if [[ "$GDM_MODE" == "true" ]]; then
        return 0
      fi

      local niri_pids
      niri_pids=$(pgrep -f "niri-session|niri" 2>/dev/null || true)
      if [[ -n "$niri_pids" ]]; then
        echo "$niri_pids" | xargs -r kill -TERM 2>/dev/null || true
        sleep 2
        niri_pids=$(pgrep -f "niri-session|niri" 2>/dev/null || true)
        [[ -n "$niri_pids" ]] && echo "$niri_pids" | xargs -r kill -KILL 2>/dev/null || true
      fi
    }

    # =============================================================================
    # Start Niri
    # =============================================================================
    start_niri() {
      print_header "NIRI BAŞLATILIYOR"

      if [[ "$DRY_RUN" == "true" ]]; then
        info "[DRY-RUN] Niri başlatılmayacak"
        exit 0
      fi

      if [[ "$GDM_MODE" == "true" ]]; then
        # Greeter/DM path: log to journal.
        if [[ "$NIRI_BINARY" == "niri" ]]; then
          exec systemd-cat -t niri-gdm -- "$NIRI_BINARY" --session
        else
          exec systemd-cat -t niri-gdm -- "$NIRI_BINARY"
        fi
      else
        # TTY path: keep foreground process to hold the session on the VT.
        export NIRI_TTY_GUARD=1

        if [[ "$NIRI_BINARY" == "niri" ]]; then
          exec "$NIRI_BINARY" --session >>"$NIRI_LOG" 2>&1
        else
          exec "$NIRI_BINARY" >>"$NIRI_LOG" 2>&1
        fi

        local rc=$?
        error "Niri exited (code=$rc). Log: $NIRI_LOG"
        sleep 2
        exec "${SHELL:-bash}" -l
      fi
    }

    # =============================================================================
    # Main
    # =============================================================================
    main() {
      # Argument parsing (minimal)
      for arg in "$@"; do
        case "$arg" in
        --dry-run) DRY_RUN=true ;;
        --force-tty) FORCE_TTY_MODE=true ;;
        --debug) DEBUG_MODE=true ;;
        esac
      done

      detect_gdm_session
      info "niri_tty v${SCRIPT_VERSION} (GDM_MODE=$GDM_MODE)"

      setup_directories
      rotate_logs
      check_system
      setup_environment
      # Avoid early systemctl/dbus calls on TTY; Niri will export env after startup.
      if [[ "$GDM_MODE" == "true" ]]; then
        setup_systemd_integration
      fi
      cleanup_old_processes
      start_niri
    }

    main "${@:-}"
  )
  ;;

env)
  # ----------------------------------------------------------------------------
  # Embedded: niri-session-start.sh
  # ----------------------------------------------------------------------------
  (
    set -euo pipefail

    LOG_TAG="niri-env"
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

    ensure_session_identity() {
      export XDG_SESSION_TYPE="${XDG_SESSION_TYPE:-wayland}"
      export XDG_SESSION_DESKTOP="${XDG_SESSION_DESKTOP:-niri}"
      export XDG_CURRENT_DESKTOP="${XDG_CURRENT_DESKTOP:-niri}"
      export DESKTOP_SESSION="${DESKTOP_SESSION:-niri}"
    }

    set_env_in_systemd() {
      if ! command -v systemctl >/dev/null 2>&1; then
        return 0
      fi

      [[ -n "${WAYLAND_DISPLAY:-}" ]] || return 0

      local timeout_bin=""
      if command -v timeout >/dev/null 2>&1; then
        timeout_bin="timeout"
      fi

      local xdg_data_dirs="${XDG_DATA_DIRS:-}"
      if [[ -z "$xdg_data_dirs" ]]; then
        # Required for GLib (and xdg-desktop-portal) to find portal definitions
        # in NixOS' /run/current-system/sw.
        xdg_data_dirs="/run/current-system/sw/share"
        if [[ -d "/etc/profiles/per-user/${USER:-}/share" ]]; then
          xdg_data_dirs="${xdg_data_dirs}:/etc/profiles/per-user/${USER}/share"
        elif [[ -d "${HOME:-}/.nix-profile/share" ]]; then
          xdg_data_dirs="${xdg_data_dirs}:${HOME}/.nix-profile/share"
        fi
        xdg_data_dirs="${xdg_data_dirs}:/usr/local/share:/usr/share"
      fi

      local xdg_config_dirs="${XDG_CONFIG_DIRS:-/etc/xdg}"

      local args=(
        "WAYLAND_DISPLAY=${WAYLAND_DISPLAY}"
        "XDG_DATA_DIRS=${xdg_data_dirs}"
        "XDG_CONFIG_DIRS=${xdg_config_dirs}"
        "XDG_CURRENT_DESKTOP=${XDG_CURRENT_DESKTOP:-}"
        "XDG_SESSION_TYPE=${XDG_SESSION_TYPE:-}"
        "XDG_SESSION_DESKTOP=${XDG_SESSION_DESKTOP:-}"
        "DESKTOP_SESSION=${DESKTOP_SESSION:-}"
      )

      [[ -n "${DISPLAY:-}" ]] && args+=("DISPLAY=${DISPLAY}")
      [[ -n "${NIRI_SOCKET:-}" ]] && args+=("NIRI_SOCKET=${NIRI_SOCKET}")

      if [[ -n "$timeout_bin" ]]; then
        $timeout_bin 2s systemctl --user set-environment "${args[@]}" >/dev/null 2>&1 || true
      else
        systemctl --user set-environment "${args[@]}" >/dev/null 2>&1 || true
      fi
    }

    import_env_to_systemd() {
      if ! command -v systemctl >/dev/null 2>&1; then
        log "systemctl not found; skipping env import"
        return 0
      fi

      local vars=(
        WAYLAND_DISPLAY
        DISPLAY
        NIRI_SOCKET
        XDG_DATA_DIRS
        XDG_CONFIG_DIRS
        XDG_CURRENT_DESKTOP
        XDG_SESSION_TYPE
        XDG_SESSION_DESKTOP
        DESKTOP_SESSION
        BROWSER
        SSH_AUTH_SOCK
        GTK_THEME
        GTK_USE_PORTAL
        XDG_ICON_THEME
        QT_ICON_THEME
        XCURSOR_THEME
        XCURSOR_SIZE
        NIXOS_OZONE_WL
        MOZ_ENABLE_WAYLAND
        QT_QPA_PLATFORM
        QT_QPA_PLATFORMTHEME
        QT_QPA_PLATFORMTHEME_QT6
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

    start_niri_portals() {
      if ! command -v systemctl >/dev/null 2>&1; then
        return 0
      fi

      local timeout_bin=""
      if command -v timeout >/dev/null 2>&1; then
        timeout_bin="timeout"
      fi

      # Niri's primary screencasting path is via xdg-desktop-portal-gnome.
      # Start portal backends explicitly in case portals were activated before
      # WAYLAND_DISPLAY existed at login time.
      local services=(
        xdg-desktop-portal-gnome.service
        xdg-desktop-portal-gtk.service
      )

      local svc
      for svc in "${services[@]}"; do
        if [[ -n "$timeout_bin" ]]; then
          $timeout_bin 2s systemctl --user start "$svc" >/dev/null 2>&1 || true
        else
          systemctl --user start "$svc" >/dev/null 2>&1 || true
        fi
      done
    }

    restart_portals() {
      if ! command -v systemctl >/dev/null 2>&1; then
        return 0
      fi

      local timeout_bin=""
      if command -v timeout >/dev/null 2>&1; then
        timeout_bin="timeout"
      fi

      # xdg-desktop-portal is often started before the compositor exports
      # XDG_CURRENT_DESKTOP / WAYLAND_DISPLAY into systemd --user. Restarting
      # it here makes it pick the correct *-portals.conf (and exposes
      # ScreenCast/Screenshot).
      if [[ -n "$timeout_bin" ]]; then
        $timeout_bin 2s systemctl --user restart xdg-desktop-portal.service >/dev/null 2>&1 || true
      else
        systemctl --user restart xdg-desktop-portal.service >/dev/null 2>&1 || true
      fi
    }

    restart_dms_if_running() {
      if ! command -v systemctl >/dev/null 2>&1; then
        return 0
      fi

      systemctl --user try-restart dms.service >/dev/null 2>&1 || true
    }

    ensure_runtime_dir
    detect_wayland_display
    detect_niri_socket
    ensure_session_identity
    start_clipse_listener
    import_env_to_systemd
    set_env_in_systemd
    start_niri_portals
    restart_portals
    restart_dms_if_running
    start_target
  )
  ;;

init)
  # ----------------------------------------------------------------------------
  # Embedded: niri-init.sh
  # ----------------------------------------------------------------------------
  (
    set -euo pipefail

    LOG_TAG="niri-init"
    log() { printf '[%s] %s\n' "$LOG_TAG" "$*"; }
    warn() { printf '[%s] WARN: %s\n' "$LOG_TAG" "$*" >&2; }
    notify() {
      command -v notify-send >/dev/null 2>&1 || return 0
      local body="${1:-}"
      local timeout="${2:-2500}"
      notify-send -t "$timeout" "Niri Init" "$body" 2>/dev/null || true
    }

    run_if_present() {
      local cmd="$1"
      shift
      if command -v "$cmd" >/dev/null 2>&1; then
        if "$cmd" "$@"; then
          log "$cmd $*"
          notify "$cmd $*"
        else
          warn "$cmd failed (ignored): $*"
          notify "WARN: $cmd failed: $*"
        fi
      else
        warn "$cmd not found; skipping"
        notify "WARN: $cmd not found"
      fi
    }

    if ! command -v niri >/dev/null 2>&1; then
      warn "niri not found; exiting"
      exit 0
    fi

    if ! niri msg version >/dev/null 2>&1; then
      warn "cannot connect to niri (not in session / NIRI_SOCKET missing); exiting"
      exit 0
    fi

    preferred="${NIRI_INIT_PREFERRED_OUTPUT:-DP-3}"
    target=""
    if command -v jq >/dev/null 2>&1; then
      outputs_json="$(niri msg -j outputs 2>/dev/null || true)"
      if [[ -n "$outputs_json" ]]; then
        if [[ -n "$preferred" ]] && echo "$outputs_json" | jq -e --arg p "$preferred" '.[] | select(.name == $p)' >/dev/null 2>&1; then
          target="$preferred"
        else
          # Prefer an external output (anything that isn't eDP*), fallback to the first output.
          target="$(echo "$outputs_json" | jq -r '[.[] | .name] as $all | ($all | map(select(test("^eDP")|not)) | .[0]) // ($all | .[0]) // empty' 2>/dev/null || true)"
        fi
      fi
    else
      if niri msg outputs 2>/dev/null | grep -q "(${preferred})"; then
        target="$preferred"
      fi
    fi

    if [[ -n "$target" ]]; then
      niri msg action focus-monitor "$target" >/dev/null 2>&1 || true
      log "focused monitor: $target"
      notify "focused monitor: $target"
    fi

    run_if_present osc-soundctl init

    if [[ "${NIRI_INIT_SKIP_ARRANGE:-0}" != "1" ]]; then
      # We call the subcommand directly to avoid depending on extra binaries.
      if [[ "${NIRI_INIT_SKIP_FOCUS_WORKSPACE:-0}" != "1" ]]; then
        focus_ws="${NIRI_INIT_FOCUS_WORKSPACE:-2}"
        "$0" go --focus "ws:${focus_ws}"
        notify "go: ws:${focus_ws}"
      else
        "$0" go
        notify "go"
      fi
    elif [[ "${NIRI_INIT_SKIP_FOCUS_WORKSPACE:-0}" != "1" ]]; then
      # Best-effort fallback: this may refer to workspace index in niri.
      focus_ws="${NIRI_INIT_FOCUS_WORKSPACE:-2}"
      niri msg action focus-workspace "$focus_ws" >/dev/null 2>&1 || true
      notify "focus workspace: ${focus_ws}"
    fi

    log "niri-init completed."
    notify "niri-init completed."
  )
  ;;

lock)
  # ----------------------------------------------------------------------------
  # Embedded: niri-lock.sh
  # ----------------------------------------------------------------------------
  (
    set -euo pipefail

    is_dms_locked() {
      command -v dms >/dev/null 2>&1 || return 1
      local out
      out="$(dms ipc call lock isLocked 2>/dev/null | tr -d '\r' | tail -n 1 || true)"
      [[ "$out" == "true" ]]
    }

    if is_dms_locked; then
      exit 0
    fi

    mode="dms"
    if [[ "${1:-}" == "--logind" ]]; then
      mode="logind"
      shift || true
    fi

    case "$mode" in
    logind)
      if command -v loginctl >/dev/null 2>&1; then
        exec loginctl lock-session
      fi
      exec dms ipc call lock lock
      ;;
    *)
      exec dms ipc call lock lock
      ;;
    esac
  )
  ;;

arrange-windows)
  echo "niri-set: 'arrange-windows' is deprecated; use 'go'." >&2
  exec "$0" go "$@"
  ;;

go)
  # ----------------------------------------------------------------------------
  # Embedded: niri-arrange-windows.sh
  # ----------------------------------------------------------------------------
  (
    set -euo pipefail

    notify() {
      command -v notify-send >/dev/null 2>&1 || return 0
      local body="${1:-}"
      local timeout="${2:-2500}"
      notify-send -t "$timeout" "Niri Arranger" "$body" 2>/dev/null || true
    }

    usage() {
      cat <<'EOF'
Kullanım:
  niri-set go [--dry-run] [--focus <window-id|workspace>]
  niri-set go [--verbose]

Amaç:
  Niri'de açık pencereleri, semsumo (--daily) düzenindeki "ait oldukları"
  workspace'lere geri taşır.

Notlar:
  - Bu komut Niri oturumu içinde çalıştırılmalı (NIRI_SOCKET gerekli).
  - Taşıma işlemi için Niri action'ları kullanılır:
      - focus-window <id>
      - move-window-to-workspace <workspace>
  - Varsayılan davranış: işlem bitince Kenp'i workspace 1'e alır ve Kenp'e odaklanır.
    `--focus` ile override edilebilir.

Örnek:
  niri-set go
  niri-set go --dry-run
  niri-set go --focus 2        # Window ID 2'ye geri odaklan
  niri-set go --focus ws:2     # Workspace 2'ye geç
EOF
    }

    DRY_RUN=0
    FOCUS_OVERRIDE=""
    VERBOSE=0

    while [[ $# -gt 0 ]]; do
      case "$1" in
      --dry-run)
        DRY_RUN=1
        shift
        ;;
      --focus)
        FOCUS_OVERRIDE="${2:-}"
        shift 2
        ;;
      --verbose)
        VERBOSE=1
        shift
        ;;
      -h | --help)
        usage
        exit 0
        ;;
      *)
        echo "Bilinmeyen arg: $1" >&2
        usage
        exit 2
        ;;
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
    declare -a RULE_TITLE_PATTERNS=()

    resolve_workspace_ref() {
      local want_name="${1:-}"
      [[ -n "$want_name" ]] || return 1

      local current_output=""
      local line idx name

      while IFS= read -r line; do
        if [[ "$line" =~ ^Output[[:space:]]+\"([^\"]+)\": ]]; then
          current_output="${BASH_REMATCH[1]}"
          continue
        fi

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
      local want_id="${1:-}"
      [[ -n "$want_id" ]] || return 1

      "${NIRI[@]}" windows 2>/dev/null | awk -v id="$want_id" '
          $1=="Window" && $2=="ID" {
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
      local win_json="${1:-}"
      [[ -n "$win_json" ]] || return 1

      local ws_name ws_id ws_out ws_idx
      ws_name="$(jq -r '.workspace.name // .workspace_name // empty' <<<"$win_json")"
      ws_id="$(jq -r '.workspace_id // .workspace.id // empty' <<<"$win_json")"
      ws_out="$(jq -r '.output // .output_name // .workspace.output // .workspace_output // empty' <<<"$win_json")"
      ws_idx="$(jq -r '.workspace.index // .workspace_idx // empty' <<<"$win_json")"

      printf 'name=%s id=%s out=%s idx=%s\n' "${ws_name:-?}" "${ws_id:-?}" "${ws_out:-?}" "${ws_idx:-?}"
    }

    load_rules() {
      local file="$1"
      [[ -f "$file" ]] || return 1

      while IFS=$'\t' read -r pattern ws title; do
        [[ -z "${pattern//[[:space:]]/}" ]] && continue
        [[ "${pattern:0:1}" == "#" ]] && continue
        [[ -z "${ws//[[:space:]]/}" ]] && continue
        RULE_PATTERNS+=("$pattern")
        RULE_WORKSPACES+=("$ws")
        RULE_TITLE_PATTERNS+=("${title:-}")
      done <"$file"
    }

    if load_rules "$rules_file"; then
      :
    else
      RULE_PATTERNS+=("^(TmuxKenp|Tmux)$")
      RULE_WORKSPACES+=("2")
      RULE_TITLE_PATTERNS+=("")
      RULE_PATTERNS+=("^(kitty|org\\.wezfurlong\\.wezterm)$")
      RULE_WORKSPACES+=("2")
      RULE_TITLE_PATTERNS+=("^Tmux$")
      RULE_PATTERNS+=("^Kenp$")
      RULE_WORKSPACES+=("1")
      RULE_TITLE_PATTERNS+=("")
      RULE_PATTERNS+=("^Ai$")
      RULE_WORKSPACES+=("3")
      RULE_TITLE_PATTERNS+=("")
      RULE_PATTERNS+=("^CompecTA$")
      RULE_WORKSPACES+=("4")
      RULE_TITLE_PATTERNS+=("")
      RULE_PATTERNS+=("^WebCord$")
      RULE_WORKSPACES+=("5")
      RULE_TITLE_PATTERNS+=("")
      RULE_PATTERNS+=("^discord$")
      RULE_WORKSPACES+=("5")
      RULE_TITLE_PATTERNS+=("")
      RULE_PATTERNS+=("^(spotify|Spotify|com\\.spotify\\.Client)$")
      RULE_WORKSPACES+=("8")
      RULE_TITLE_PATTERNS+=("")
      RULE_PATTERNS+=("^ferdium$")
      RULE_WORKSPACES+=("9")
      RULE_TITLE_PATTERNS+=("")
      RULE_PATTERNS+=("^org\\.keepassxc\\.KeePassXC$")
      RULE_WORKSPACES+=("7")
      RULE_TITLE_PATTERNS+=("")
      RULE_PATTERNS+=("^brave-youtube\\.com__-Default$")
      RULE_WORKSPACES+=("7")
      RULE_TITLE_PATTERNS+=("")
    fi

    focused_id="$("${NIRI[@]}" -j focused-window 2>/dev/null | jq -r '.id // empty' || true)"

    target_for_app_id() {
      local app_id="${1:-}"
      local title="${2:-}"
      [[ -z "$app_id" ]] && return 1

      local i
      for i in "${!RULE_PATTERNS[@]}"; do
        if [[ "$app_id" =~ ${RULE_PATTERNS[$i]} ]]; then
          title_pattern="${RULE_TITLE_PATTERNS[$i]:-}"
          if [[ -n "${title_pattern//[[:space:]]/}" ]] && [[ ! "$title" =~ $title_pattern ]]; then
            continue
          fi
          echo "${RULE_WORKSPACES[$i]}"
          return 0
        fi
      done
      return 1
    }

    echo "Scanning windows..."
    notify "Pencereler düzenleniyor…" 1200
    windows_json="$("${NIRI[@]}" -j windows)"

    moved=0
    planned=0
    failed=0

    while read -r win; do
      id="$(jq -r '.id' <<<"$win")"
      app_id="$(jq -r '.app_id // ""' <<<"$win")"
      title="$(jq -r '.title // ""' <<<"$win")"
      current_ws_name="$(jq -r '.workspace.name // .workspace_name // empty' <<<"$win")"

      if [[ "$app_id" == "hyprland-share-picker" ]]; then
        continue
      fi
      if [[ -z "$app_id" && "$title" =~ ^[Pp]icture[[:space:]-]*in[[:space:]-]*[Pp]icture$ ]]; then
        continue
      fi

      target_ws=""
      if target_ws="$(target_for_app_id "$app_id" "$title" 2>/dev/null)"; then
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

      if [[ -n "$current_ws_name" && "$current_ws_name" == "$target_ws" ]]; then
        [[ "$VERBOSE" -eq 1 ]] && echo " == $id: '$app_id' already on ws:$target_ws (by name)"
        continue
      fi

      echo " -> $id: '$app_id' -> ws:$target_ws (output:$target_out idx:$target_idx)"
      planned=$((planned + 1))
      if [[ "$DRY_RUN" -eq 1 ]]; then
        continue
      fi

      if ! "${NIRI[@]}" action move-window-to-monitor --id "$id" "$target_out" >/dev/null 2>&1; then
        echo " !! move-window-to-monitor failed for id=$id -> out:$target_out" >&2
        failed=$((failed + 1))
        continue
      fi

      "${NIRI[@]}" action focus-monitor "$target_out" >/dev/null 2>&1 || true

      if ! "${NIRI[@]}" action move-window-to-workspace --window-id "$id" --focus false "$target_idx" >/dev/null 2>&1; then
        echo " !! move-window-to-workspace failed for id=$id -> ws:$target_ws (out:$target_out idx:$target_idx)" >&2
        failed=$((failed + 1))
        continue
      fi
      moved=$((moved + 1))

      after="$(get_window_json_by_id "$id" || true)"
      if [[ -n "$after" ]]; then
        after_name="$(jq -r '.workspace.name // .workspace_name // empty' <<<"$after")"
        after_id="$(jq -r '.workspace_id // .workspace.id // empty' <<<"$after")"

        if [[ -n "$after_name" && "$after_name" == "$target_ws" ]]; then
          [[ "$VERBOSE" -eq 1 ]] && echo "    ok: $(get_window_loc "$after")"
        else
          if [[ -n "$after_id" && "$after_id" == "$target_idx" ]]; then
            [[ "$VERBOSE" -eq 1 ]] && echo "    ok (by idx, output unknown): $(get_window_loc "$after")"
          else
            echo " !! move did not land on ws:$target_ws for id=$id ($app_id), now: $(get_window_loc "$after")" >&2
            failed=$((failed + 1))
          fi
        fi
      else
        after_ws_id="$(get_window_workspace_id_text "$id" || true)"
        if [[ -n "$after_ws_id" && "$after_ws_id" == "$target_idx" ]]; then
          [[ "$VERBOSE" -eq 1 ]] && echo "    ok (text ws_id=$after_ws_id)"
        elif [[ -n "$after_ws_id" ]]; then
          echo " !! move did not land on ws:$target_ws for id=$id ($app_id), now: text ws_id=$after_ws_id" >&2
          failed=$((failed + 1))
        fi
      fi
    done < <(jq -c '.[]' <<<"$windows_json")

    if [[ -n "$FOCUS_OVERRIDE" ]]; then
      if [[ "$FOCUS_OVERRIDE" =~ ^ws:(.+)$ ]]; then
        focus_ws_name="${BASH_REMATCH[1]}"
        if read -r focus_out focus_idx < <(resolve_workspace_ref "$focus_ws_name"); then
          "${NIRI[@]}" action focus-monitor "$focus_out" >/dev/null 2>&1 || true
          "${NIRI[@]}" action focus-workspace "$focus_idx" >/dev/null 2>&1 || true
        else
          "${NIRI[@]}" action focus-workspace "$focus_ws_name" >/dev/null 2>&1 || true
        fi
      else
        "${NIRI[@]}" action focus-window "$FOCUS_OVERRIDE" >/dev/null 2>&1 || true
      fi
    elif [[ -n "$focused_id" ]]; then
      "${NIRI[@]}" action focus-window "$focused_id" >/dev/null 2>&1 || true
    fi

    focus_kenp() {
      local home_ws="1"
      home_ws="$(target_for_app_id "Kenp" "" 2>/dev/null || true)"
      [[ -n "${home_ws:-}" ]] || home_ws="1"

      local home_out="" home_idx=""
      if ! read -r home_out home_idx < <(resolve_workspace_ref "$home_ws"); then
        home_out=""
        home_idx=""
      fi

      if command -v jq >/dev/null 2>&1; then
        kenp_id="$("${NIRI[@]}" -j windows 2>/dev/null | jq -r 'first(.[] | select(.app_id=="Kenp") | .id) // empty' || true)"
      fi

      if [[ -z "${kenp_id:-}" && -n "${home_out:-}" && -n "${home_idx:-}" ]]; then
        # Try to spawn and wait briefly for window to appear.
        if command -v start-brave-kenp >/dev/null 2>&1; then
          start-brave-kenp >/dev/null 2>&1 & disown || true
          for _ in {1..50}; do
            kenp_id="$("${NIRI[@]}" -j windows 2>/dev/null | jq -r 'first(.[] | select(.app_id=="Kenp") | .id) // empty' || true)"
            [[ -n "${kenp_id:-}" ]] && break
            sleep 0.1
          done
        fi
      fi

      if [[ -z "${kenp_id:-}" ]]; then
        # Best-effort fallback: just try to focus/spawn without moving.
        if command -v nirius >/dev/null 2>&1; then
          nirius focus-or-spawn --app-id '^Kenp$' start-brave-kenp >/dev/null 2>&1 || true
        fi
        return 0
      fi

      # Ensure Kenp ends up on its home workspace (default: "1"), then focus it.
      if [[ -n "${home_out:-}" && -n "${home_idx:-}" ]]; then
        "${NIRI[@]}" action move-window-to-monitor --id "$kenp_id" "$home_out" >/dev/null 2>&1 || true
        "${NIRI[@]}" action focus-monitor "$home_out" >/dev/null 2>&1 || true
        "${NIRI[@]}" action move-window-to-workspace --window-id "$kenp_id" --focus false "$home_idx" >/dev/null 2>&1 || true
      fi
      "${NIRI[@]}" action focus-window "$kenp_id" >/dev/null 2>&1 || true
      return 0
    }

    # Default: end focused on Kenp (unless caller explicitly overrides focus).
    if [[ -z "$FOCUS_OVERRIDE" && "$DRY_RUN" -eq 0 ]]; then
      focus_kenp
    fi

    echo "Done."
    if [[ "$DRY_RUN" -eq 1 ]]; then
      notify "Dry-run: ${planned} pencere hedefe gidecek." 3000
    else
      if [[ "$planned" -eq 0 ]]; then
        notify "Değişiklik yok (zaten düzenli)." 2500
      else
        notify "Taşınan: ${moved}/${planned}  Hata: ${failed}" 3500
      fi
    fi
  )
  ;;

cast)
  # ----------------------------------------------------------------------------
  # Dynamic screencast helper (niri "Dynamic Cast Target").
  #
  # Requires: niri >= 25.05
  # ----------------------------------------------------------------------------
  (
    set -euo pipefail

    usage_cast() {
      cat <<'EOF'
Usage:
  niri-set cast window     # cast focused window
  niri-set cast monitor    # cast focused monitor
  niri-set cast clear      # clear dynamic cast target
  niri-set cast pick       # interactively pick a window and cast it
EOF
    }

    action="${1:-}"
    shift || true

    command -v niri >/dev/null 2>&1 || exit 0
    command -v jq >/dev/null 2>&1 || exit 0
    niri msg version >/dev/null 2>&1 || exit 0

    case "$action" in
    window)
      exec niri msg action set-dynamic-cast-window
      ;;
    monitor)
      exec niri msg action set-dynamic-cast-monitor
      ;;
    clear)
      exec niri msg action clear-dynamic-cast-target
      ;;
    pick)
      win_id="$(niri msg --json pick-window 2>/dev/null | jq -r '.id // empty' || true)"
      [[ -n "$win_id" ]] || exit 0
      exec niri msg action set-dynamic-cast-window --id "$win_id"
      ;;
    "" | -h | --help | help)
      usage_cast
      exit 0
      ;;
    *)
      echo "niri-set cast: unknown action: $action" >&2
      usage_cast >&2
      exit 2
      ;;
    esac
  )
  ;;

float)
  # ----------------------------------------------------------------------------
  # Embedded: niri-toggle-window-mode
  # ----------------------------------------------------------------------------
  (
    set -euo pipefail

    ensure_niri_socket() {
      if [[ -n "${NIRI_SOCKET:-}" ]] && [[ -S "${NIRI_SOCKET}" ]]; then return 0; fi
      [[ -n "${XDG_RUNTIME_DIR:-}" ]] || export XDG_RUNTIME_DIR="/run/user/$(id -u)"
      local d="${WAYLAND_DISPLAY:-}"
      if [[ -z "$d" ]]; then
        for s in "$XDG_RUNTIME_DIR"/wayland-*; do [[ -S "$s" ]] && d="$(basename "$s")" && break; done
      fi
      if [[ -n "$d" ]]; then
        for s in "$XDG_RUNTIME_DIR"/niri."$d".*.sock; do [[ -S "$s" ]] && export NIRI_SOCKET="$s" && return 0; done
      fi
      for s in "$XDG_RUNTIME_DIR"/niri.*.sock; do [[ -S "$s" ]] && export NIRI_SOCKET="$s" && return 0; done
      return 1
    }

    ensure_niri_socket || {
      echo "Niri socket not found" >&2
      exit 1
    }

    win="$(niri msg -j focused-window 2>/dev/null || true)"
    if [[ -z "$win" ]]; then exit 0; fi

    is_floating="$(echo "$win" | jq -r '.is_floating // false')"

    if [[ "$is_floating" == "true" ]]; then
      # Switch to tiling
      niri msg action toggle-window-floating >/dev/null 2>&1 || true
    else
      # Switch to floating and resize
      niri msg action toggle-window-floating >/dev/null 2>&1 || true
      # Small delay might be needed or just fire commands; usually niri handles queue well
      niri msg action set-window-width 900 >/dev/null 2>&1 || true
      niri msg action set-window-height 650 >/dev/null 2>&1 || true
      niri msg action center-window >/dev/null 2>&1 || true
    fi
  )
  ;;

flow)
  # ----------------------------------------------------------------------------
  # Embedded: niri-workspace-monitor.sh
  # ----------------------------------------------------------------------------
  (
    set -euo pipefail

    : "${XDG_RUNTIME_DIR:="/run/user/$(id -u)"}"
    PATH="/run/current-system/sw/bin:/etc/profiles/per-user/${USER}/bin:${PATH}"

    readonly SCRIPT_NAME="NiriFlow"

    cache_root="${XDG_CACHE_HOME:-$HOME/.cache}"
    cache_dir_candidate="$cache_root/niri/toggle"
    if ! mkdir -p "$cache_dir_candidate" 2>/dev/null || [[ ! -w "$cache_dir_candidate" ]]; then
      cache_root="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
      cache_dir_candidate="$cache_root/niri-flow"
      mkdir -p "$cache_dir_candidate" 2>/dev/null || true
    fi

    readonly CACHE_DIR="$cache_dir_candidate"
    readonly PREVIOUS_WS_FILE="$CACHE_DIR/previous_workspace"
    readonly MONITOR_STATE_FILE="$CACHE_DIR/monitor_state"

    init_environment() {
      mkdir -p "$CACHE_DIR" 2>/dev/null || true
      if [ ! -f "$PREVIOUS_WS_FILE" ]; then echo "1" >"$PREVIOUS_WS_FILE" 2>/dev/null || true; fi
      if [ ! -f "$MONITOR_STATE_FILE" ]; then echo "right" >"$MONITOR_STATE_FILE" 2>/dev/null || true; fi
    }

    log() { echo "[$SCRIPT_NAME] $1" >&2; }

    detect_wayland_display() {
      if [[ -n "${WAYLAND_DISPLAY:-}" ]]; then
        return 0
      fi

      local sock
      for sock in "${XDG_RUNTIME_DIR}"/wayland-*; do
        [[ -S "$sock" ]] || continue
        export WAYLAND_DISPLAY
        WAYLAND_DISPLAY="$(basename "$sock")"
        return 0
      done
    }

    ensure_niri_socket() {
      if [[ -n "${NIRI_SOCKET:-}" ]] && [[ -S "${NIRI_SOCKET}" ]]; then
        return 0
      fi

      detect_wayland_display || true

      shopt -s nullglob
      local candidates=()
      if [[ -n "${WAYLAND_DISPLAY:-}" ]]; then
        candidates+=("${XDG_RUNTIME_DIR}/niri.${WAYLAND_DISPLAY}."*.sock)
      fi
      candidates+=("${XDG_RUNTIME_DIR}/niri."*.sock)

      local sock
      for sock in "${candidates[@]}"; do
        [[ -S "$sock" ]] || continue
        export NIRI_SOCKET="$sock"
        shopt -u nullglob
        return 0
      done
      shopt -u nullglob
      return 1
    }

    niri_action() {
      ensure_niri_socket >/dev/null 2>&1 || true
      niri msg action "$@"
    }

    get_current_workspace() {
      ensure_niri_socket >/dev/null 2>&1 || true
      local output
      output=$(niri msg workspaces 2>/dev/null || true)

      if [[ -z "$output" ]] || [[ "${output:0:1}" != "[" ]]; then
        echo "1"
        return
      fi

      local id
      id=$(echo "$output" | jq -r '.[] | select(.is_active) | .id' 2>/dev/null)
      if [[ -n "$id" ]] && [[ "$id" != "null" ]]; then
        echo "$id"
      else
        echo "1"
      fi
    }

    get_previous_workspace() {
      if [ -f "$PREVIOUS_WS_FILE" ]; then
        cat "$PREVIOUS_WS_FILE"
      else
        echo "1"
      fi
    }

    save_current_as_previous() {
      local current
      current=$(get_current_workspace)
      echo "$current" >"$PREVIOUS_WS_FILE"
    }

    switch_to_workspace() {
      local index=$1
      save_current_as_previous
      niri_action focus-workspace "$index"
    }

    toggle_workspace() {
      local target
      target=$(get_previous_workspace)
      local current
      current=$(get_current_workspace)

      if [ "$target" != "$current" ]; then
        switch_to_workspace "$target"
      else
        log "Already on previous workspace ($target)"
      fi
    }

    navigate_relative() {
      local direction=$1
      save_current_as_previous

      case $direction in
      "next" | "down" | "right") niri_action focus-workspace-down ;;
      "prev" | "up" | "left") niri_action focus-workspace-up ;;
      esac
    }

    move_window_to_workspace() {
      local index=$1
      niri_action move-column-to-workspace "$index"
    }

    focus_monitor() {
      local direction=$1
      case $direction in
      "left") niri_action focus-monitor-left ;;
      "right") niri_action focus-monitor-right ;;
      "up") niri_action focus-monitor-up ;;
      "down") niri_action focus-monitor-down ;;
      "next") niri_action focus-monitor-next ;;
      "prev") niri_action focus-monitor-previous ;;
      esac
    }

    toggle_monitor_focus() {
      local state
      state="$(cat "$MONITOR_STATE_FILE" 2>/dev/null || echo "right")"

      if [[ "$state" == "right" ]]; then
        focus_monitor "right"
        echo "left" >"$MONITOR_STATE_FILE"
      else
        focus_monitor "left"
        echo "right" >"$MONITOR_STATE_FILE"
      fi
    }

    navigate_browser_tab() {
      local direction=$1

      if command -v wtype >/dev/null 2>&1; then
        if [[ "$direction" == "next" ]]; then
          wtype -M ctrl -k tab 2>/dev/null || true
        else
          wtype -M ctrl -M shift -k tab 2>/dev/null || true
        fi
        return 0
      fi

      log "Browser tab navigation requires wtype"
      return 1
    }

    main() {
      init_environment

      while [[ $# -gt 0 ]]; do
        case $1 in
        -wl)
          navigate_relative "prev"
          shift
          ;;
        -wr)
          navigate_relative "next"
          shift
          ;;
        -wt)
          toggle_workspace
          shift
          ;;
        -wn)
          [[ -n "${2:-}" ]] || {
            log "Error: Workspace number required for -wn"
            exit 1
          }
          switch_to_workspace "$2"
          shift 2
          ;;
        -mw)
          [[ -n "${2:-}" ]] || {
            log "Error: Workspace number required for -mw"
            exit 1
          }
          move_window_to_workspace "$2"
          shift 2
          ;;
        -ml)
          focus_monitor "left"
          shift
          ;;
        -mr)
          focus_monitor "right"
          shift
          ;;
        -mu)
          focus_monitor "up"
          shift
          ;;
        -md)
          focus_monitor "down"
          shift
          ;;
        -mn)
          focus_monitor "next"
          shift
          ;;
        -mp)
          focus_monitor "prev"
          shift
          ;;
        -ms)
          focus_monitor "right"
          shift
          ;;
        -msf)
          focus_monitor "right"
          shift
          ;;
        -mt)
          toggle_monitor_focus
          shift
          ;;
        -tn)
          navigate_browser_tab "next"
          shift
          ;;
        -tp)
          navigate_browser_tab "prev"
          shift
          ;;
        -h | --help)
          echo "Usage: niri-set flow [options]"
          echo "  -wl/-wr  Focus prev/up or next/down workspace"
          echo "  -wt      Toggle last workspace"
          echo "  -wn N    Focus workspace N"
          echo "  -mw N    Move window to workspace N"
          echo "  -ml/mr   Focus monitor left/right"
          echo "  -mn/-mp  Focus next/previous monitor"
          echo "  -mt      Toggle monitor focus (left/right)"
          echo "  -tn/-tp  Next/previous browser tab (wtype)"
          exit 0
          ;;
        *)
          log "Unknown option: $1"
          exit 1
          ;;
        esac
      done
    }

    main "$@"
  )
  ;;

doctor)
  # ----------------------------------------------------------------------------
  # Quick diagnostics for "why doesn't X start/work" issues.
  # ----------------------------------------------------------------------------
  (
    set -euo pipefail

    maybe() { command -v "$1" >/dev/null 2>&1; }
    kv() { printf '%-28s %s\n' "$1" "${2:-}"; }

    show_tree=false
    show_logs=false
    while [[ $# -gt 0 ]]; do
      case "${1:-}" in
      --tree)
        show_tree=true
        shift
        ;;
      --logs)
        show_logs=true
        shift
        ;;
      -h | --help)
        echo "Usage: niri-set doctor [--tree] [--logs]"
        exit 0
        ;;
      *)
        echo "niri-set doctor: unknown arg: ${1}" >&2
        exit 2
        ;;
      esac
    done

    timeout_bin=""
    if maybe timeout; then
      timeout_bin="timeout"
    fi

    systemctl_user_quick() {
      maybe systemctl || return 0
      if [[ -n "$timeout_bin" ]]; then
        $timeout_bin 2s systemctl --user "$@" 2>/dev/null || true
      else
        systemctl --user "$@" 2>/dev/null || true
      fi
    }

    systemctl_user_slow() {
      maybe systemctl || return 0
      if [[ -n "$timeout_bin" ]]; then
        $timeout_bin 8s systemctl --user "$@" 2>/dev/null || true
      else
        systemctl --user "$@" 2>/dev/null || true
      fi
    }

    journalctl_user() {
      maybe journalctl || return 0
      if [[ -n "$timeout_bin" ]]; then
        $timeout_bin 8s journalctl --user "$@" 2>/dev/null || true
      else
        journalctl --user "$@" 2>/dev/null || true
      fi
    }

    sysenv_get() {
      local dump="${1:-}"
      local var="${2:-}"
      local line
      while IFS= read -r line; do
        [[ -n "$line" ]] || continue
        [[ "$line" == "${var}="* ]] || continue
        printf '%s' "${line#*=}"
        return 0
      done <<<"$dump"
      return 0
    }

    print_unit_status() {
      local unit="${1:-}"
      [[ -n "$unit" ]] || return 0
      local state
      state="$(systemctl_user_quick is-active "$unit")"
      state="${state:-unknown}"
      printf '%-10s %s\n' "$state" "$unit"
    }

    declare -A printed_units=()
    print_units_status() {
      local unit
      for unit in "$@"; do
        [[ -n "$unit" ]] || continue
        if [[ -n "${printed_units[$unit]:-}" ]]; then
          continue
        fi
        printed_units["$unit"]=1
        print_unit_status "$unit"
      done
    }

    print_units_status_section() {
      declare -A section_units=()
      local unit
      for unit in "$@"; do
        [[ -n "$unit" ]] || continue
        if [[ -n "${section_units[$unit]:-}" ]]; then
          continue
        fi
        section_units["$unit"]=1
        print_unit_status "$unit"
      done
      if [[ "${#section_units[@]}" -eq 0 ]]; then
        echo "(none)"
      fi
    }

    echo "niri-set doctor"
    echo
    kv "XDG_SESSION_TYPE" "${XDG_SESSION_TYPE:-}"
    kv "XDG_CURRENT_DESKTOP" "${XDG_CURRENT_DESKTOP:-}"
    kv "XDG_SESSION_DESKTOP" "${XDG_SESSION_DESKTOP:-}"
    kv "DESKTOP_SESSION" "${DESKTOP_SESSION:-}"
    kv "WAYLAND_DISPLAY" "${WAYLAND_DISPLAY:-}"
    kv "NIRI_SOCKET" "${NIRI_SOCKET:-}"
    kv "DISPLAY" "${DISPLAY:-}"
    echo

    for cmd in niri jq systemctl dbus-update-activation-environment xwayland-satellite; do
      if maybe "$cmd"; then
        kv "bin:$cmd" "$(command -v "$cmd")"
      else
        kv "bin:$cmd" "(missing)"
      fi
    done
    echo

    if maybe niri; then
      if niri msg version >/dev/null 2>&1; then
        kv "niri msg version" "ok"
      else
        kv "niri msg version" "failed (session/env?)"
      fi
    fi

    if maybe systemctl; then
      bus_state="$(systemctl_user_quick is-system-running)"
      bus_state="${bus_state:-unavailable}"
      echo
      kv "systemd --user bus" "$bus_state"

      if [[ "$bus_state" != "unavailable" ]]; then
        sysenv_dump="$(systemctl_user_quick show-environment)"
        if [[ -n "${sysenv_dump:-}" ]]; then
          echo
          echo "systemd --user env (selected)"
          kv "userenv:WAYLAND_DISPLAY" "$(sysenv_get "$sysenv_dump" "WAYLAND_DISPLAY")"
          kv "userenv:NIRI_SOCKET" "$(sysenv_get "$sysenv_dump" "NIRI_SOCKET")"
          kv "userenv:XDG_CURRENT_DESKTOP" "$(sysenv_get "$sysenv_dump" "XDG_CURRENT_DESKTOP")"
          kv "userenv:XDG_SESSION_TYPE" "$(sysenv_get "$sysenv_dump" "XDG_SESSION_TYPE")"
          kv "userenv:XDG_SESSION_DESKTOP" "$(sysenv_get "$sysenv_dump" "XDG_SESSION_DESKTOP")"
          kv "userenv:DESKTOP_SESSION" "$(sysenv_get "$sysenv_dump" "DESKTOP_SESSION")"
          kv "userenv:DISPLAY" "$(sysenv_get "$sysenv_dump" "DISPLAY")"
        fi

        echo
        echo "Units (key)"
        print_units_status \
          niri-session.target \
          graphical-session.target \
          xdg-desktop-autostart.target \
          niri-ready.service \
          niri-bootstrap.service \
          niri-polkit-agent.service \
          dms.service \
          dms-plugin-sync.service \
          dms-resume-restart.service \
          kdeconnectd.service \
          kdeconnect-indicator.service \
          fusuma.service \
          cliphist-watch-text.service \
          cliphist-watch-image.service \
          stasis.service \
          xdg-desktop-portal.service \
          xdg-desktop-portal-gnome.service \
          xdg-desktop-portal-gtk.service

        wants_raw="$(systemctl_user_quick show -p Wants --value niri-session.target)"
        requires_raw="$(systemctl_user_quick show -p Requires --value niri-session.target)"
        if [[ -n "${wants_raw}${requires_raw}" ]]; then
          echo
          echo "Units (niri-session.target wants/requires)"
          # shellcheck disable=SC2206
          wants_units=(${wants_raw:-})
          # shellcheck disable=SC2206
          requires_units=(${requires_raw:-})
          print_units_status_section "${wants_units[@]}" "${requires_units[@]}"
        fi

        if [[ "$show_tree" == "true" ]]; then
          echo
          echo "Dependency tree (niri-session.target)"
          systemctl_user_slow list-dependencies --plain --no-pager niri-session.target
        fi

        if [[ "$show_logs" == "true" ]]; then
          echo
          echo "Logs (this boot): niri-bootstrap.service"
          journalctl_user -u niri-bootstrap.service -b --no-pager -n 120
        fi
      fi
    fi

    if maybe pgrep; then
      clipse_proc="$(pgrep -af 'clipse.*-listen' 2>/dev/null | head -n 1 || true)"
      if [[ -z "${clipse_proc:-}" ]]; then
        clipse_proc="$(pgrep -af 'wl-paste.*--watch clipse' 2>/dev/null | head -n 1 || true)"
      fi
      kv "is-running:clipse" "${clipse_proc:-inactive}"
    fi
  )
  ;;

"" | -h | --help | help)
  usage
  ;;
*)
  echo "Unknown command: ${cmd}" >&2
  usage >&2
  exit 2
  ;;
esac
