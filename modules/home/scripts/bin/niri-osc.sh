#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# niri-osc
# -----------------------------------------------------------------------------
# Unified single-file Niri helper.
# Scopes:
# - set
# - flow
# - sticky
# - keybinds
# - drop
#
# Design:
# - Keep one entrypoint (`niri-osc`) while isolating large scope implementations.
# - Use lazy loading: scope payload is only materialized/executed when requested.
# - Cache extracted scope script under XDG cache for faster subsequent startups.
# -----------------------------------------------------------------------------

set -euo pipefail

NIRI_OSC_VERSION="2.0.0"
NIRI_OSC_SELF="${BASH_SOURCE[0]}"

niri_osc_usage() {
  cat <<'EOF'
Usage:
  niri-osc <scope> [args...]
  niri-osc help [scope]
  niri-osc doctor
  niri-osc version

Scopes:
  set        Session/bootstrap/routing helpers
  flow       Workflow helpers (scratchpad, marks, follow)
  sticky     Sticky/stage helpers
  keybinds   Parse Niri keybinds
  drop       Drop-down style app toggle (Niri)

Examples:
  niri-osc set init
  niri-osc flow scratchpad-toggle
  niri-osc sticky stage toggle-active
  niri-osc keybinds --help
  niri-osc drop kitty --class dropdown-terminal
EOF
}

niri_osc_is_scope() {
  case "$1" in
  set | flow | sticky | keybinds | drop)
    return 0
    ;;
  *)
    return 1
    ;;
  esac
}

niri_osc_scope_alias() {
  case "$1" in
  keys)
    printf 'keybinds\n'
    ;;
  *)
    printf '%s\n' "$1"
    ;;
  esac
}

niri_osc_cache_dir() {
  printf '%s\n' "${XDG_CACHE_HOME:-$HOME/.cache}/niri-osc"
}

niri_osc_source_stamp() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$NIRI_OSC_SELF" | awk '{print $1}'
  else
    cksum "$NIRI_OSC_SELF" 2>/dev/null | awk '{print $1 ":" $2}'
  fi
}

niri_osc_cache_is_fresh() {
  local cache_file="$1"
  local stamp="$2"

  [[ -s "$cache_file" ]] || return 1
  head -n 3 "$cache_file" | grep -Fq "# niri-osc-source:${stamp}" || return 1
}

niri_osc_write_scope_cache() {
  local scope="$1"
  local cache_file="$2"
  local stamp="$3"
  local tmp_file

  tmp_file="${cache_file}.tmp.$$"
  {
    printf '#!/usr/bin/env bash\n'
    printf '# niri-osc-scope:%s\n' "$scope"
    printf '# niri-osc-source:%s\n' "$stamp"
    niri_osc_payload_for_scope "$scope"
  } >"$tmp_file"

  chmod 700 "$tmp_file"
  mv "$tmp_file" "$cache_file"
}

niri_osc_run_scope() {
  local scope="$1"
  shift || true

  local cache_dir cache_file stamp
  cache_dir="$(niri_osc_cache_dir)"
  stamp="$(niri_osc_source_stamp || true)"
  cache_file="${cache_dir}/${scope}.sh"

  if mkdir -p "$cache_dir" 2>/dev/null; then
    if ! niri_osc_cache_is_fresh "$cache_file" "$stamp"; then
      niri_osc_write_scope_cache "$scope" "$cache_file" "$stamp"
    fi
    exec bash "$cache_file" "$@"
  fi

  local tmp_file
  tmp_file="$(mktemp "${TMPDIR:-/tmp}/niri-osc.${scope}.XXXXXX.sh")"
  niri_osc_payload_for_scope "$scope" >"$tmp_file"
  chmod 700 "$tmp_file"
  local rc=0
  if ! bash "$tmp_file" "$@"; then
    rc=$?
  fi
  rm -f "$tmp_file"
  return "$rc"
}

niri_osc_doctor() {
  local cache_dir stamp
  cache_dir="$(niri_osc_cache_dir)"
  stamp="$(niri_osc_source_stamp || echo unknown)"

  printf 'niri-osc version : %s\n' "$NIRI_OSC_VERSION"
  printf 'script path       : %s\n' "$NIRI_OSC_SELF"
  printf 'source stamp      : %s\n' "$stamp"
  printf 'cache dir         : %s\n' "$cache_dir"
  printf 'available scopes  : set flow sticky keybinds drop\n'

  if [[ -d "$cache_dir" ]]; then
    printf '\ncache entries:\n'
    for scope in set flow sticky keybinds drop; do
      local f
      f="${cache_dir}/${scope}.sh"
      if [[ -f "$f" ]]; then
        printf '  %s: %s\n' "$scope" "$f"
      else
        printf '  %s: (not cached)\n' "$scope"
      fi
    done
  fi
}

niri_osc_payload_set() {
  cat <<'__NIRI_OSC_SET_PAYLOAD_20260208__'
# -----------------------------------------------------------------------------
# niri-osc set
# -----------------------------------------------------------------------------
# Purpose:
# - Main Niri session helper multiplexer used by keybinds, startup, and ops.
# - Consolidates session/bootstrap/window-routing helpers behind one command.
#
# Interface:
# - `niri-osc set <subcommand> [args...]`
# - Major groups: session (`tty`, `env`, `init`, `lock`), routing (`go`, `here`,
#   `flow`, `cast`), diagnostics (`doctor`), and layout toggles (`float`, `zen`,
#   `pin`).
#
# Design notes:
# - Intentionally self-contained because each `*.sh` is packaged as an
#   independent binary by `modules/home/scripts/bin.nix`.
# - Prefers graceful fallback behavior for optional desktop integrations (DMS,
#   notifications, portals, etc.).
#
# See:
# - `niri-osc set help`
# -----------------------------------------------------------------------------

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
  niri-osc set <command> [args...]

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
  niri-osc set env
  niri-osc set lock
  niri-osc set zen
  niri-osc set pin
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

    dms_ipc_call() {
      command -v dms >/dev/null 2>&1 || return 1
      # Silent fallback if dms-server is not reachable
      dms ipc call "$@" 2>/dev/null | tr -d '\r' || return 1
    }

    get_bar_state() {
      local out norm
      out="$(dms_ipc_call bar status index 0 2>/dev/null | tail -n 1 || echo "unknown")"
      norm="$(printf '%s' "$out" | tr '[:upper:]' '[:lower:]' | xargs || echo "unknown")"
      case "$norm" in
      visible | shown | show | on | true | 1) echo "visible" ;;
      hidden | hide | off | false | 0) echo "hidden" ;;
      *) echo "unknown" ;;
      esac
    }

    get_dnd_state() {
      local out norm
      out="$(dms_ipc_call notifications getDoNotDisturb | tail -n 1 || true)"
      norm="$(printf '%s' "$out" | tr '[:upper:]' '[:lower:]' | xargs || true)"
      case "$norm" in
      true | on | yes | 1) echo "true" ;;
      false | off | no | 0) echo "false" ;;
      *) echo "unknown" ;;
      esac
    }

    set_bar_state() {
      local desired="${1:-}" current
      current="$(get_bar_state)"
      [[ "$current" == "$desired" ]] && return 0

      case "$desired" in
      visible)
        dms_ipc_call bar reveal index 0 >/dev/null 2>&1 || true
        ;;
      hidden)
        dms_ipc_call bar hide index 0 >/dev/null 2>&1 || true
        ;;
      *)
        ;;
      esac
    }

    set_dnd_state() {
      local desired="${1:-}" current
      current="$(get_dnd_state)"
      [[ "$current" == "$desired" ]] && return 0

      case "$desired" in
      true | false)
        # DMS notifications IPC exposes toggle + getter (no explicit set).
        if [[ "$current" != "unknown" ]]; then
          dms_ipc_call notifications toggleDoNotDisturb >/dev/null 2>&1 || true
        fi
        ;;
      *)
        ;;
      esac
    }

    write_state_file() {
      local bar_state="${1:-unknown}" dnd_state="${2:-unknown}" tmp
      tmp="$(mktemp "${STATE_FILE}.XXXXXX")"
      {
        printf 'version=2\n'
        printf 'bar=%s\n' "$bar_state"
        printf 'dnd=%s\n' "$dnd_state"
      } >"$tmp"
      mv "$tmp" "$STATE_FILE"
    }

    load_state_file() {
      STATE_VERSION=""
      STATE_BAR=""
      STATE_DND=""
      [[ -f "$STATE_FILE" ]] || return 0

      while IFS='=' read -r key value; do
        case "$key" in
        version) STATE_VERSION="$value" ;;
        bar) STATE_BAR="$value" ;;
        dnd) STATE_DND="$value" ;;
        *)
          ;;
        esac
      done <"$STATE_FILE"
    }

    if [[ -f "$STATE_FILE" ]]; then
      # === DISABLE ZEN (Restore) ===

      ensure_zen_file
      disable_zen_config
      reload_config

      load_state_file

      if [[ "$STATE_VERSION" == "2" ]]; then
        [[ "$STATE_BAR" == "visible" || "$STATE_BAR" == "hidden" ]] && set_bar_state "$STATE_BAR"
        [[ "$STATE_DND" == "true" || "$STATE_DND" == "false" ]] && set_dnd_state "$STATE_DND"
      else
        # Legacy fallback for older empty marker files.
        dms_ipc_call bar toggle index 0 >/dev/null 2>&1 || true
        dms_ipc_call notifications toggle-dnd >/dev/null 2>&1 || dms_ipc_call notifications toggleDoNotDisturb >/dev/null 2>&1 || true
      fi

      rm -f "$STATE_FILE"
      notify "Off"
      echo "Zen Mode: Off"
    else
      # === ENABLE ZEN ===

      ensure_zen_file
      enable_zen_config
      reload_config

      bar_before="$(get_bar_state)"
      dnd_before="$(get_dnd_state)"
      write_state_file "$bar_before" "$dnd_before"

      # Hide bar + enable DND only if needed.
      set_bar_state "hidden"
      set_dnd_state "true"

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
      local current_ws_id=""
      local window_id=""
      local windows_json=""
      local workspaces_json=""

      # --- 1. Try to pull existing window (niri-osc flow) ---
      if command -v niri-osc >/dev/null 2>&1; then
        if niri-osc flow move-to-current-workspace --app-id "^${APP_ID}$" --focus >/dev/null 2>&1; then
          send_notify "<b>$APP_ID</b> moved to current workspace."
          return 0
        fi
      fi

      # --- 2. Check if it's already here but not focused ---
      if command -v niri >/dev/null 2>&1 && command -v jq >/dev/null 2>&1; then
        windows_json="$(niri msg -j windows 2>/dev/null || true)"
        workspaces_json="$(niri msg -j workspaces 2>/dev/null || true)"
        current_ws_id="$(
          jq -n \
            --argjson wins "${windows_json:-[]}" \
            --argjson wss "${workspaces_json:-[]}" \
            -r '
              first($wins[]? | select(.is_focused == true and .workspace_id != null) | .workspace_id)
              // first($wss[]? | select(.is_focused == true) | .id)
              // first($wss[]? | select(.is_active == true) | .id)
              // empty
            ' 2>/dev/null || true
        )"
        if [[ -n "$current_ws_id" ]]; then
          window_id="$(
            echo "$windows_json" \
              | jq -r --arg app "$APP_ID" --arg ws "$current_ws_id" \
                'first(.[] | select(.app_id == $app and ((.workspace_id|tostring) == $ws)) | .id) // empty' \
                  2>/dev/null || true
          )"
        fi
        if [[ -n "$window_id" ]]; then
          niri msg action focus-window --id "$window_id" >/dev/null 2>&1 || true
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
        [[ "$app" == "Kenp" ]] && continue
        process_app "$app" &
      done
      wait

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
    # Derived from legacy tty launcher logic, adapted for Niri.
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
      # in Niri config and exported to systemd via `niri-osc set env`.
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

    ensure_runtime_dir
    detect_wayland_display
    detect_niri_socket
    ensure_session_identity
    start_clipse_listener
    import_env_to_systemd
    set_env_in_systemd
    start_niri_portals
    restart_portals
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

    write_monitor_auto_profile() {
      [[ -n "${outputs_json:-}" ]] || return 0
      command -v jq >/dev/null 2>&1 || return 0

      local config_home dms_dir profile_file
      local internal_output external_output
      local detect_json
      local ext_w ext_h int_w int_x int_y

      config_home="${XDG_CONFIG_HOME:-$HOME/.config}"
      dms_dir="${config_home}/niri/dms"
      profile_file="${dms_dir}/monitor-auto.kdl"

      mkdir -p "$dms_dir"

      if [[ -L "$profile_file" ]]; then
        rm -f "$profile_file"
      fi

      # Prefer outputs that currently expose a valid mode. This avoids picking
      # stale/disconnected names (e.g. old DP-* connector ids after re-dock).
      detect_json="$(echo "$outputs_json" | jq -c '[.[] | select(((.current_mode.width // .mode.width // 0) > 0) and ((.current_mode.height // .mode.height // 0) > 0))]' 2>/dev/null || true)"
      if [[ -z "${detect_json:-}" ]] || [[ "${detect_json:-[]}" == "[]" ]]; then
        detect_json="$outputs_json"
      fi

      internal_output="$(echo "$detect_json" | jq -r '[.[] | .name | select(test("^eDP"))][0] // empty' 2>/dev/null || true)"
      external_output="$(echo "$detect_json" | jq -r '[.[] | .name | select(test("^eDP")|not)][0] // empty' 2>/dev/null || true)"

      if [[ -z "$internal_output" ]]; then
        internal_output="$(echo "$outputs_json" | jq -r '.[0].name // empty' 2>/dev/null || true)"
      fi

      [[ -n "$internal_output" ]] || return 0

      # Check for VRR capability on internal display (Meteor Lake optimization)
      internal_vrr="false"
      if [[ -n "$internal_output" ]]; then
        internal_vrr="$(echo "$detect_json" | jq -r --arg n "$internal_output" '.[] | select(.name == $n) | if .modes then (.modes[] | select(.is_current) | .vrr_capable) else false end // false' 2>/dev/null || echo "false")"
      fi

      ext_w=0
      ext_h=0
      int_w=0
      if [[ -n "$external_output" ]] && [[ "$external_output" != "$internal_output" ]]; then
        ext_w="$(echo "$detect_json" | jq -r --arg o "$external_output" '.[] | select(.name == $o) | (.current_mode.width // .mode.width // 0)' 2>/dev/null | head -n 1 || true)"
        ext_h="$(echo "$detect_json" | jq -r --arg o "$external_output" '.[] | select(.name == $o) | (.current_mode.height // .mode.height // 0)' 2>/dev/null | head -n 1 || true)"
        int_w="$(echo "$detect_json" | jq -r --arg o "$internal_output" '.[] | select(.name == $o) | (.current_mode.width // .mode.width // 0)' 2>/dev/null | head -n 1 || true)"
      fi

      [[ "$ext_w" =~ ^[0-9]+$ ]] || ext_w=0
      [[ "$ext_h" =~ ^[0-9]+$ ]] || ext_h=0
      [[ "$int_w" =~ ^[0-9]+$ ]] || int_w=0

      int_x=0
      int_y=0
      if [[ "$ext_w" -gt 0 ]] && [[ "$ext_h" -gt 0 ]]; then
        if [[ "$int_w" -gt 0 ]] && [[ "$ext_w" -gt "$int_w" ]]; then
          int_x=$(((ext_w - int_w) / 2))
        fi
        int_y="$ext_h"
      fi

      {
        echo "// Auto-generated by niri-osc set init."
        echo "// Output-only runtime profile. Workspace mapping is static in monitors.nix."
        if [[ -n "$external_output" ]] && [[ "$external_output" != "$internal_output" ]]; then
          echo "output \"$external_output\" { position x=0 y=0; scale 1.0; }"
          if [[ "$internal_vrr" == "true" ]]; then
            echo "output \"$internal_output\" { position x=${int_x} y=${int_y}; scale 1.0; variable-refresh-rate on-demand=true; }"
          else
            echo "output \"$internal_output\" { position x=${int_x} y=${int_y}; scale 1.0; }"
          fi
        else
          if [[ "$internal_vrr" == "true" ]]; then
            echo "output \"$internal_output\" { position x=0 y=0; scale 1.0; variable-refresh-rate on-demand=true; }"
          else
            echo "output \"$internal_output\" { position x=0 y=0; scale 1.0; }"
          fi
        fi
      } >"$profile_file"

      niri msg action load-config-file >/dev/null 2>&1 || true
      log "monitor output profile updated (internal=${internal_output}, external=${external_output:-none})"
    }

    normalize_workspace_range() {
      command -v jq >/dev/null 2>&1 || return 0

      local windows_json workspaces_json
      windows_json="$(niri msg -j windows 2>/dev/null || true)"
      workspaces_json="$(niri msg -j workspaces 2>/dev/null || true)"
      [[ -n "$windows_json" && -n "$workspaces_json" ]] || return 0

      local moved=0
      while IFS=$'\t' read -r window_id ws_output ws_idx ws_name; do
        [[ -n "$window_id" ]] || continue

        # Keep dedicated stage workspace behavior for sticky workflow.
        if [[ "$ws_name" == "stage" ]]; then
          continue
        fi

        local target_idx=1
        if [[ "$ws_output" =~ ^eDP ]]; then
          target_idx=7
        fi

        if niri msg action move-window-to-workspace --window-id "$window_id" --focus false "$target_idx" >/dev/null 2>&1; then
          moved=$((moved + 1))
        fi
      done < <(
        jq -n \
          --argjson wins "${windows_json:-[]}" \
          --argjson wss "${workspaces_json:-[]}" \
          -r '
            def ws_by_id:
              reduce $wss[] as $ws ({}; .[($ws.id | tostring)] = $ws);

            $wins[]?
            | (.workspace_id | tostring) as $wid
            | (ws_by_id[$wid] // {}) as $ws
            | ($ws.idx // -1) as $idx
            | ($ws.output // "") as $out
            | ($ws.name // "") as $name
            | select(($idx | tonumber? // -1) < 1 or ($idx | tonumber? // -1) > 9)
            | "\(.id)\t\($out)\t\($idx)\t\($name)"
          ' 2>/dev/null || true
      )

      local focused_idx
      focused_idx="$(
        jq -r '
          first(.[] | select(.is_focused == true) | .idx)
          // first(.[] | select(.is_active == true) | .idx)
          // empty
        ' <<<"${workspaces_json:-[]}" 2>/dev/null || true
      )"

      if [[ "$focused_idx" =~ ^[0-9]+$ ]] && { ((focused_idx < 1)) || ((focused_idx > 9)); }; then
        niri msg action focus-workspace "1" >/dev/null 2>&1 || true
      fi

      if ((moved > 0)); then
        log "workspace bounds normalized: moved ${moved} window(s) back to 1..9"
        notify "workspace bounds normalized: ${moved} window(s) -> 1..9"
      fi
    }

    compact_out_of_range_empty_workspaces() {
      command -v jq >/dev/null 2>&1 || return 0

      local windows_json workspaces_json
      windows_json="$(niri msg -j windows 2>/dev/null || true)"
      workspaces_json="$(niri msg -j workspaces 2>/dev/null || true)"
      [[ -n "$windows_json" && -n "$workspaces_json" ]] || return 0

      local collapsed=0
      while IFS=$'\t' read -r ws_output ws_idx ws_name win_count; do
        [[ -n "$ws_output" ]] || continue
        [[ "$ws_idx" =~ ^[0-9]+$ ]] || continue
        [[ "$win_count" =~ ^[0-9]+$ ]] || win_count=0

        ((ws_idx > 9)) || continue
        [[ -z "$ws_name" ]] || continue
        ((win_count == 0)) || continue

        niri msg action focus-monitor "$ws_output" >/dev/null 2>&1 || continue
        niri msg action focus-workspace "$ws_idx" >/dev/null 2>&1 || continue
        niri msg action focus-workspace "1" >/dev/null 2>&1 || true
        collapsed=$((collapsed + 1))
      done < <(
        jq -n \
          --argjson wins "${windows_json:-[]}" \
          --argjson wss "${workspaces_json:-[]}" \
          -r '
            def win_count($wid):
              [$wins[]? | select((.workspace_id | tostring) == ($wid | tostring))] | length;

            $wss[]?
            | (.idx | tonumber? // -1) as $idx
            | select($idx > 9)
            | [(.output // ""), ($idx | tostring), (.name // ""), (win_count(.id) | tostring)]
            | @tsv
          ' 2>/dev/null | sort -k1,1 -k2,2nr
      )

      if ((collapsed > 0)); then
        log "workspace bounds compacted: removed ${collapsed} empty out-of-range workspace slot(s)"
        notify "workspace bounds compacted: ${collapsed} empty slot(s)"
      fi
    }

    preferred="${NIRI_INIT_PREFERRED_OUTPUT:-DP-3}"
    target=""
    outputs_json=""
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

    write_monitor_auto_profile
    normalize_workspace_range
    compact_out_of_range_empty_workspaces

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
  echo "niri-osc set: 'arrange-windows' is deprecated; use 'go'." >&2
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
  niri-osc set go [--dry-run] [--focus <window-id|workspace>]
  niri-osc set go [--verbose]

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
  niri-osc set go
  niri-osc set go --dry-run
  niri-osc set go --focus 2        # Window ID 2'ye geri odaklan
  niri-osc set go --focus ws:2     # Workspace 2'ye geç
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

      # Never move temporary screen-share picker windows.
      if [[ "$app_id" =~ share-picker$ ]]; then
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
        if command -v niri-osc >/dev/null 2>&1; then
          niri-osc flow focus-or-spawn --app-id '^Kenp$' start-brave-kenp >/dev/null 2>&1 || true
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
  niri-osc set cast window     # cast focused window
  niri-osc set cast monitor    # cast focused monitor
  niri-osc set cast clear      # clear dynamic cast target
  niri-osc set cast pick       # interactively pick a window and cast it
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
      echo "niri-osc set cast: unknown action: $action" >&2
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
      if [[ -n "${NIRI_SOCKET:-}" ]] && [[ -S "${NIRI_SOCKET}" ]]; then
        if niri msg version >/dev/null 2>&1; then return 0; fi
      fi
      [[ -n "${XDG_RUNTIME_DIR:-}" ]] || export XDG_RUNTIME_DIR="/run/user/$(id -u)"
      local d="${WAYLAND_DISPLAY:-}"
      if [[ -z "$d" ]]; then
        for s in "$XDG_RUNTIME_DIR"/wayland-*; do [[ -S "$s" ]] && d="$(basename "$s")" && break; done
      fi
      if [[ -n "$d" ]]; then
        for s in "$XDG_RUNTIME_DIR"/niri."$d".*.sock; do
          if [[ -S "$s" ]]; then
             export NIRI_SOCKET="$s"
             if niri msg version >/dev/null 2>&1; then return 0; fi
          fi
        done
      fi
      for s in "$XDG_RUNTIME_DIR"/niri.*.sock; do 
        if [[ -S "$s" ]]; then
           export NIRI_SOCKET="$s"
           if niri msg version >/dev/null 2>&1; then return 0; fi
        fi
      done
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
    readonly WS_MIN=1
    readonly WS_MAX=9

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

    is_int() {
      [[ "${1:-}" =~ ^[0-9]+$ ]]
    }

    normalize_workspace_index() {
      local index="${1:-$WS_MIN}"
      if ! is_int "$index"; then
        printf '%s\n' "$WS_MIN"
        return 0
      fi

      if ((index < WS_MIN)); then
        index="$WS_MIN"
      elif ((index > WS_MAX)); then
        index="$WS_MAX"
      fi

      printf '%s\n' "$index"
    }

    next_workspace_index() {
      local current
      current="$(normalize_workspace_index "${1:-$WS_MIN}")"
      if ((current >= WS_MAX)); then
        printf '%s\n' "$WS_MIN"
      else
        printf '%s\n' "$((current + 1))"
      fi
    }

    prev_workspace_index() {
      local current
      current="$(normalize_workspace_index "${1:-$WS_MIN}")"
      if ((current <= WS_MIN)); then
        printf '%s\n' "$WS_MAX"
      else
        printf '%s\n' "$((current - 1))"
      fi
    }

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
        if niri msg version >/dev/null 2>&1; then return 0; fi
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
        if niri msg version >/dev/null 2>&1; then
          shopt -u nullglob
          return 0
        fi
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
      local windows_json workspaces_json
      windows_json="$(niri msg -j windows 2>/dev/null || true)"
      workspaces_json="$(niri msg -j workspaces 2>/dev/null || true)"

      if [[ -z "$workspaces_json" ]] || [[ "${workspaces_json:0:1}" != "[" ]]; then
        echo "1"
        return
      fi

      local id
      id="$(
        jq -n \
          --argjson wins "${windows_json:-[]}" \
          --argjson wss "${workspaces_json:-[]}" \
          -r '
            def ws_by_id:
              reduce $wss[] as $ws ({}; .[($ws.id | tostring)] = $ws);

            (first($wins[]? | select(.is_focused == true and .workspace_id != null) | (.workspace_id | tostring)) // "") as $wid
            | if ($wid != "" and (ws_by_id[$wid] != null)) then
                (ws_by_id[$wid].idx // empty)
              else
                (first($wss[]? | select(.is_focused == true) | .idx)
                 // first($wss[]? | select(.is_active == true) | .idx)
                 // empty)
              end
          ' 2>/dev/null || true
      )"
      if [[ -n "$id" ]] && [[ "$id" != "null" ]] && is_int "$id"; then
        normalize_workspace_index "$id"
        return 0
      fi

      printf '%s\n' "$WS_MIN"
    }

    get_previous_workspace() {
      if [ -f "$PREVIOUS_WS_FILE" ]; then
        normalize_workspace_index "$(cat "$PREVIOUS_WS_FILE" 2>/dev/null || echo "$WS_MIN")"
      else
        echo "$WS_MIN"
      fi
    }

    save_current_as_previous() {
      local current
      current=$(get_current_workspace)
      echo "$current" >"$PREVIOUS_WS_FILE"
    }

    switch_to_workspace() {
      local index="${1:-$WS_MIN}"
      if is_int "$index"; then
        index="$(normalize_workspace_index "$index")"
      fi
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
      local current target
      current="$(get_current_workspace)"

      case $direction in
      "next" | "down" | "right")
        target="$(next_workspace_index "$current")"
        switch_to_workspace "$target"
        ;;
      "prev" | "up" | "left")
        target="$(prev_workspace_index "$current")"
        switch_to_workspace "$target"
        ;;
      esac
    }

    move_window_to_workspace() {
      local index="${1:-$WS_MIN}"
      if is_int "$index"; then
        index="$(normalize_workspace_index "$index")"
      fi
      niri_action move-column-to-workspace "$index"
    }

    move_window_relative_workspace() {
      local direction="$1"
      local current target
      current="$(get_current_workspace)"
      case "$direction" in
      next | down | right)
        target="$(next_workspace_index "$current")"
        ;;
      prev | up | left)
        target="$(prev_workspace_index "$current")"
        ;;
      *)
        return 1
        ;;
      esac

      move_window_to_workspace "$target"
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
        -mwn)
          move_window_relative_workspace "next"
          shift
          ;;
        -mwp)
          move_window_relative_workspace "prev"
          shift
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
          echo "Usage: niri-osc set flow [options]"
          echo "  -wl/-wr  Focus prev/next workspace (bounded 1..9, wraps)"
          echo "  -wt      Toggle last workspace"
          echo "  -wn N    Focus workspace N (clamped to 1..9)"
          echo "  -mw N    Move window to workspace N (clamped to 1..9)"
          echo "  -mwp     Move window to previous workspace (1..9, wraps)"
          echo "  -mwn     Move window to next workspace (1..9, wraps)"
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
        echo "Usage: niri-osc set doctor [--tree] [--logs]"
        exit 0
        ;;
      *)
        echo "niri-osc set doctor: unknown arg: ${1}" >&2
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

    config_home="${XDG_CONFIG_HOME:-$HOME/.config}"
    niri_config_file="${config_home}/niri/config.kdl"
    niri_dms_dir="${config_home}/niri/dms"

    include_is_declared() {
      local include_path="${1:-}"
      [[ -n "$include_path" ]] || return 1
      [[ -f "$niri_config_file" ]] || return 1
      grep -Fq "include \"${include_path}\"" "$niri_config_file"
    }

    check_runtime_include_file() {
      local label="${1:-}"
      local include_path="${2:-}"
      local abs_path="${3:-}"
      local target

      if ! include_is_declared "$include_path"; then
        kv "$label" "not-declared"
        return 0
      fi

      if [[ ! -e "$abs_path" ]]; then
        kv "$label" "missing"
        return 0
      fi

      if [[ -L "$abs_path" ]]; then
        target="$(readlink -f "$abs_path" 2>/dev/null || true)"
        if [[ "$target" == /nix/store/* ]]; then
          kv "$label" "symlink->/nix/store (readonly)"
        else
          kv "$label" "symlink->${target:-unknown}"
        fi
        return 0
      fi

      if [[ ! -f "$abs_path" ]]; then
        kv "$label" "not-regular"
        return 0
      fi

      if [[ ! -w "$abs_path" ]]; then
        kv "$label" "not-writable"
        return 0
      fi

      kv "$label" "ok"
    }

    echo "niri-osc set doctor"
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

    echo
    echo "Runtime includes (strict)"
    kv "config.kdl" "$([[ -f "$niri_config_file" ]] && echo "$niri_config_file" || echo "missing")"
    check_runtime_include_file "include:dms/outputs.kdl" "dms/outputs.kdl" "${niri_dms_dir}/outputs.kdl"
    check_runtime_include_file "include:dms/monitor-auto.kdl" "dms/monitor-auto.kdl" "${niri_dms_dir}/monitor-auto.kdl"
    check_runtime_include_file "include:dms/zen.kdl" "dms/zen.kdl" "${niri_dms_dir}/zen.kdl"
    check_runtime_include_file "include:dms/cursor.kdl" "dms/cursor.kdl" "${niri_dms_dir}/cursor.kdl"
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
__NIRI_OSC_SET_PAYLOAD_20260208__
}

niri_osc_payload_flow() {
  cat <<'__NIRI_OSC_FLOW_PAYLOAD_20260208__'
# -----------------------------------------------------------------------------
# niri-osc flow
# -----------------------------------------------------------------------------
# Purpose:
# - Daemon-free workflow layer for Niri, implemented directly on `niri msg`.
# - Keeps daily keybind workflows fast and dependency-light.
#
# Interface:
# - Subcommands for focus/focus-or-spawn and workspace routing.
# - Mark and scratchpad primitives (`toggle`, `show`, `show-all`).
# - Follow-mode toggling for tracked windows.
#
# State (XDG):
# - ${XDG_STATE_HOME:-$HOME/.local/state}/niri-flow/marks.json
# - ${XDG_STATE_HOME:-$HOME/.local/state}/niri-flow/scratchpad.json
# - ${XDG_STATE_HOME:-$HOME/.local/state}/niri-flow/follow.json
#
# Tunables:
# - OSC_NIRI_FLOW_SCRATCH_WORKSPACE (default: oscndrop, "auto" for legacy dynamic behavior)
#
# Dependencies:
# - niri
# - jq
#
# Notes:
# - This script is stateful but daemon-free.
# - Run `niri-osc flow --help` for the full command surface.
# -----------------------------------------------------------------------------

set -euo pipefail

VERSION="1.1.0"
STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
STATE_DIR="${STATE_HOME}/niri-flow"
MARKS_FILE="$STATE_DIR/marks.json"
SCRATCH_FILE="$STATE_DIR/scratchpad.json"
FOLLOW_FILE="$STATE_DIR/follow.json"
LOCK_FILE="$STATE_DIR/state.lock"
# Keep scratch hidden windows on a stable workspace reference by default.
# Set OSC_NIRI_FLOW_SCRATCH_WORKSPACE=auto to keep the legacy behavior
# (using the current monitor's last workspace index).
SCRATCH_WORKSPACE_REF="${OSC_NIRI_FLOW_SCRATCH_WORKSPACE:-oscndrop}"
SCRATCH_WORKSPACE_FALLBACK="9"

MATCH_APP_ID=""
MATCH_TITLE=""
MATCH_PID=""
MATCH_WORKSPACE_ID=""
MATCH_WORKSPACE_INDEX=""
MATCH_WORKSPACE_NAME=""
MATCH_INCLUDE_CURRENT=0
MATCH_FOCUS=0
MATCH_NO_MOVE=0
REMAINING_ARGS=()

die() {
  printf 'niri-osc flow: %s\n' "$*" >&2
  exit 1
}

# Atomic update with flock
update_json_locked() {
  local file="$1"
  local jq_program="$2"
  shift 2
  
  touch "$LOCK_FILE"
  (
    flock -x 9
    [[ -f "$file" ]] || echo "{}" > "$file"
    local tmp
    tmp="$(mktemp)"
    if jq "$jq_program" "$file" "$@" > "$tmp"; then
      mv "$tmp" "$file"
    else
      rm -f "$tmp"
      return 1
    fi
  ) 9>"$LOCK_FILE"
}

usage() {
  cat <<'EOF'
Utility commands for the niri wayland compositor

Usage: niri-osc flow <COMMAND>

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
  touch "$LOCK_FILE"
  (
    flock -x 9
    [[ -f "$MARKS_FILE" ]] || printf '{"marks":{}}\n' >"$MARKS_FILE"
    [[ -f "$SCRATCH_FILE" ]] || printf '{"entries":{},"cursor":0}\n' >"$SCRATCH_FILE"
    [[ -f "$FOLLOW_FILE" ]] || printf '{"windows":[],"last_workspace_id":""}\n' >"$FOLLOW_FILE"

    # Normalize state files inside the lock
    local f
    for f in "$MARKS_FILE" "$SCRATCH_FILE" "$FOLLOW_FILE"; do
       if ! jq -e . "$f" >/dev/null 2>&1; then
          case $(basename "$f") in
            marks.json) printf '{"marks":{}}\n' >"$f" ;;
            scratchpad.json) printf '{"entries":{},"cursor":0}\n' >"$f" ;;
            follow.json) printf '{"windows":[],"last_workspace_id":""}\n' >"$f" ;;
          esac
       fi
    done
  ) 9>"$LOCK_FILE"
}

normalize_state_file() {
  local file="$1"
  local fallback_json="$2"
  local jq_program="$3"
  local tmp_file

  if ! jq -e . "$file" >/dev/null 2>&1; then
    printf '%s\n' "$fallback_json" >"$file"
  fi

  tmp_file="$(mktemp)"
  if jq "$jq_program" "$file" >"$tmp_file" 2>/dev/null; then
    mv "$tmp_file" "$file"
  else
    rm -f "$tmp_file"
    printf '%s\n' "$fallback_json" >"$file"
  fi
}

niri_windows_json() {
  niri msg -j windows
}

niri_workspaces_json() {
  niri msg -j workspaces
}

current_workspace_id() {
  local windows_json workspaces_json ws_id

  windows_json="$(niri_windows_json 2>/dev/null || true)"
  ws_id="$(echo "$windows_json" | jq -r 'first(.[] | select(.is_focused == true and .workspace_id != null) | .workspace_id) // empty' 2>/dev/null || true)"
  if [[ -n "$ws_id" ]]; then
    printf '%s\n' "$ws_id"
    return 0
  fi

  workspaces_json="$(niri_workspaces_json 2>/dev/null || true)"
  ws_id="$(echo "$workspaces_json" | jq -r 'first(.[] | select(.is_focused == true) | .id) // empty' 2>/dev/null || true)"
  if [[ -n "$ws_id" ]]; then
    printf '%s\n' "$ws_id"
    return 0
  fi

  ws_id="$(echo "$workspaces_json" | jq -r 'first(.[] | select(.is_active == true) | .id) // empty' 2>/dev/null || true)"
  printf '%s\n' "$ws_id"
}

current_workspace_index() {
  local windows_json workspaces_json ws_idx

  windows_json="$(niri_windows_json 2>/dev/null || true)"
  workspaces_json="$(niri_workspaces_json 2>/dev/null || true)"

  ws_idx="$(
    jq -n \
      --argjson wins "${windows_json:-[]}" \
      --argjson wss "${workspaces_json:-[]}" \
      -r '
        def ws_by_id: reduce $wss[] as $ws ({}; .[($ws.id|tostring)] = $ws);
        (first($wins[]? | select(.is_focused == true and .workspace_id != null) | .workspace_id) // null) as $wid
        | if $wid != null then
            ((ws_by_id[($wid|tostring)] // {}).idx // empty)
          else
            (first($wss[]? | select(.is_focused == true) | .idx)
             // first($wss[]? | select(.is_active == true) | .idx)
             // empty)
          end
      ' 2>/dev/null || true
  )"
  printf '%s\n' "$ws_idx"
}

focused_window_id() {
  niri_windows_json | jq -r 'first(.[] | select(.is_focused == true) | .id) // empty'
}

has_match_filter() {
  [[ -n "$MATCH_APP_ID$MATCH_TITLE$MATCH_PID$MATCH_WORKSPACE_ID$MATCH_WORKSPACE_INDEX$MATCH_WORKSPACE_NAME" ]]
}

parse_match_opts() {
  MATCH_APP_ID=""
  MATCH_TITLE=""
  MATCH_PID=""
  MATCH_WORKSPACE_ID=""
  MATCH_WORKSPACE_INDEX=""
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
      --workspace-id)
        [[ $# -ge 2 ]] || die "--workspace-id requires a value"
        MATCH_WORKSPACE_ID="$2"
        shift 2
        ;;
      --workspace-index)
        [[ $# -ge 2 ]] || die "--workspace-index requires a value"
        MATCH_WORKSPACE_INDEX="$2"
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
}

matched_window_ids() {
  local windows_json="$1"
  local workspaces_json="$2"

  echo "$windows_json" | jq -r \
    --arg app "$MATCH_APP_ID" \
    --arg title "$MATCH_TITLE" \
    --arg pid "$MATCH_PID" \
    --arg workspace "$MATCH_WORKSPACE_ID" \
    --arg workspace_idx "$MATCH_WORKSPACE_INDEX" \
    --arg workspace_name "$MATCH_WORKSPACE_NAME" \
    --argjson workspaces "$workspaces_json" \
    '
      def ws_by_id: reduce $workspaces[] as $ws ({}; .[($ws.id | tostring)] = $ws);
      .[]
      | . as $w
      | (ws_by_id[(($w.workspace_id // -1) | tostring)] // null) as $ws
      | select(($app == "") or ((($w.app_id // "") | tostring) | test($app)))
      | select(($title == "") or ((($w.title // "") | tostring) | test($title)))
      | select(($pid == "") or ((($w.pid // -1) | tostring) == $pid))
      | select(($workspace == "") or ((($w.workspace_id // -1) | tostring) == $workspace))
      | select(($workspace_idx == "") or (($ws != null) and (($ws.idx | tostring) == $workspace_idx)))
      | select(($workspace_name == "") or (($ws != null) and (((($ws.name // "") | tostring) | test($workspace_name)))))
      | ($w.id | tostring)
    '
}

focus_with_current_match() {
  local windows_json workspaces_json focused_id target_id index
  local -a ids

  windows_json="$(niri_windows_json)"
  workspaces_json="$(niri_workspaces_json)"
  mapfile -t ids < <(matched_window_ids "$windows_json" "$workspaces_json")
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
  local windows_json workspaces_json current_workspace current_workspace_idx target_id window_workspace
  local -a ids

  windows_json="$(niri_windows_json)"
  workspaces_json="$(niri_workspaces_json)"
  current_workspace="$(current_workspace_id)"
  current_workspace_idx="$(current_workspace_index)"
  [[ -n "$current_workspace" ]] || return 1
  [[ -n "$current_workspace_idx" ]] || return 1

  mapfile -t ids < <(matched_window_ids "$windows_json" "$workspaces_json")
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

  niri msg action move-window-to-workspace --window-id "$target_id" --focus false "$current_workspace_idx" >/dev/null
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
  local mark focused_id
  mark="${1:-__default__}"
  focused_id="$(focused_window_id)"
  [[ -n "$focused_id" ]] || return 1

  update_json_locked "$MARKS_FILE" '
    .marks = (.marks // {}) |
    if ((.marks[$mark] // []) | index($id)) != null then
      .marks[$mark] = ((.marks[$mark] // []) | map(select(. != $id)))
    else
      .marks[$mark] = ((.marks[$mark] // []) + [$id] | unique)
    end
  ' --arg mark "$mark" --arg id "$focused_id"
}

cleanup_mark() {
  local mark="$1"
  local windows_json live_ids_json
  windows_json="$(niri_windows_json)"
  live_ids_json="$(echo "$windows_json" | jq '[.[].id | tostring]')"
  
  update_json_locked "$MARKS_FILE" '
    .marks = (.marks // {}) |
    .marks[$mark] = ((.marks[$mark] // []) | map(tostring) | map(select(($live | index(.)) != null)))
  ' --arg mark "$mark" --argjson live "$live_ids_json"
}

cmd_focus_marked() {
  local mark target_id
  mark="${1:-__default__}"
  cleanup_mark "$mark"
  target_id="$(jq -r --arg mark "$mark" '(.marks[$mark] // [])[0] // empty' "$MARKS_FILE")"
  [[ -n "$target_id" ]] || return 1

  niri msg action focus-window --id "$target_id" >/dev/null 2>&1 || true

  update_json_locked "$MARKS_FILE" '
    .marks = (.marks // {}) |
    .marks[$mark] = (
      if ((.marks[$mark] // []) | length) > 1 then
        ((.marks[$mark])[1:] + [(.marks[$mark])[0]])
      else
        (.marks[$mark] // [])
      end
    )
  ' --arg mark "$mark"
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
  
  touch "$LOCK_FILE"
  (
    flock -x 9
    local tmp_file
    tmp_file="$(mktemp)"
    if jq "${jq_args[@]}" "$SCRATCH_FILE" >"$tmp_file"; then
      mv "$tmp_file" "$SCRATCH_FILE"
    else
      rm -f "$tmp_file"
    fi
  ) 9>"$LOCK_FILE"
}

scratch_entry_exists() {
  local window_id="$1"
  jq -e --arg id "$window_id" '.entries[$id] != null' "$SCRATCH_FILE" >/dev/null 2>&1
}

remove_scratch_entry() {
  local window_id="$1"
  scratch_tmp_update --arg id "$window_id" '
    .entries = (.entries // {}) |
    del(.entries[$id])
  '
}

refresh_scratch_entries() {
  local windows_json="$1"
  local live_ids_json
  live_ids_json="$(echo "$windows_json" | jq '[.[].id | tostring]')"
  scratch_tmp_update --argjson live "$live_ids_json" '
    .entries = (.entries // {}) |
    .entries = (
      .entries
      | with_entries(select(. as $entry | ($live | index($entry.key)) != null))
    )
  '
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

focused_output_name() {
  niri_workspaces_json | jq -r '
    first(.[] | select(.is_focused == true) | .output // empty)
    // first(.[] | select(.is_active == true) | .output // empty)
    // empty
  '
}

scratch_workspace_ref() {
  local configured="${SCRATCH_WORKSPACE_REF:-oscndrop}"
  if [[ "$configured" != "auto" ]]; then
    printf '%s\n' "$configured"
    return 0
  fi

  local output ws_id
  output="$(focused_output_name)"
  if [[ -n "$output" ]]; then
    ws_id="$(niri_workspaces_json | jq -r --arg out "$output" '([.[] | select((.output // "") == $out)] | max_by(.idx) | .idx // empty)')"
    if [[ -n "$ws_id" ]]; then
      printf '%s\n' "$ws_id"
      return 0
    fi
  fi

  printf '%s\n' "$SCRATCH_WORKSPACE_FALLBACK"
}

window_is_floating() {
  local window_id="$1"
  local windows_json="$2"
  echo "$windows_json" | jq -e --arg id "$window_id" 'first(.[] | select((.id | tostring) == $id) | .is_floating) == true' >/dev/null 2>&1
}

ensure_window_floating() {
  local window_id="$1"
  local windows_json="$2"
  if ! window_is_floating "$window_id" "$windows_json"; then
    niri msg action toggle-window-floating --id "$window_id" >/dev/null 2>&1 || true
  fi
}

scratchpad_move_all() {
  local windows_json="$1"
  local target_ws
  local -a scratch_ids

  target_ws="$(scratch_workspace_ref)"
  [[ -n "$target_ws" ]] || return 1

  mapfile -t scratch_ids < <(jq -r '.entries // {} | keys[]?' "$SCRATCH_FILE")
  [[ "${#scratch_ids[@]}" -gt 0 ]] || return 0

  for window_id in "${scratch_ids[@]}"; do
    ensure_window_floating "$window_id" "$windows_json"
    niri msg action move-window-to-workspace --window-id "$window_id" --focus false "$target_ws" >/dev/null 2>&1 || true
    set_scratch_hidden "$window_id" true "$target_ws"
  done
}

hide_window_to_scratch() {
  local window_id="$1"
  local origin_workspace="$2"
  local scratch_workspace
  local windows_json
  if [[ "$MATCH_NO_MOVE" -eq 0 ]]; then
    windows_json="$(niri_windows_json)"
    ensure_window_floating "$window_id" "$windows_json"
    scratch_workspace="$(scratch_workspace_ref)"
    niri msg action move-window-to-workspace --window-id "$window_id" --focus false "$scratch_workspace" >/dev/null 2>&1 || true
  fi
  set_scratch_hidden "$window_id" true "$origin_workspace"
}

show_window_from_scratch() {
  local window_id="$1"
  local current_workspace current_workspace_idx
  current_workspace="$(current_workspace_id)"
  current_workspace_idx="$(current_workspace_index)"
  [[ -n "$current_workspace" ]] || return 1
  [[ -n "$current_workspace_idx" ]] || return 1
  niri msg action move-window-to-workspace --window-id "$window_id" --focus false "$current_workspace_idx" >/dev/null 2>&1 || true
  niri msg action focus-window --id "$window_id" >/dev/null 2>&1 || true
  set_scratch_hidden "$window_id" false "$current_workspace"
}

select_target_window_id() {
  local windows_json="$1"
  local workspaces_json="$2"
  local focused_id
  local -a ids

  focused_id="$(focused_window_id)"

  # For plain scratchpad-toggle (no filters), act on the currently focused
  # window to match user expectation.
  if ! has_match_filter && [[ -n "$focused_id" ]]; then
    printf '%s\n' "$focused_id"
    return 0
  fi

  mapfile -t ids < <(matched_window_ids "$windows_json" "$workspaces_json")
  if [[ "${#ids[@]}" -gt 0 ]]; then
    printf '%s\n' "${ids[0]}"
    return 0
  fi

  if [[ -n "$focused_id" ]]; then
    printf '%s\n' "$focused_id"
    return 0
  fi

  return 1
}

cmd_scratchpad_toggle() {
  local windows_json workspaces_json target_id origin_workspace
  parse_match_opts "$@"
  windows_json="$(niri_windows_json)"
  workspaces_json="$(niri_workspaces_json)"
  refresh_scratch_entries "$windows_json"
  target_id="$(select_target_window_id "$windows_json" "$workspaces_json" || true)"
  [[ -n "$target_id" ]] || return 1

  if scratch_entry_exists "$target_id"; then
    remove_scratch_entry "$target_id"
    return 0
  fi

  if [[ -n "$MATCH_WORKSPACE_ID" ]]; then
    origin_workspace="$MATCH_WORKSPACE_ID"
  else
    origin_workspace="$(window_workspace_id "$windows_json" "$target_id")"
    [[ -n "$origin_workspace" ]] || origin_workspace="$(current_workspace_id)"
  fi

  hide_window_to_scratch "$target_id" "$origin_workspace"
  if [[ "$MATCH_NO_MOVE" -eq 0 ]]; then
    scratchpad_move_all "$windows_json"
  fi
}

cmd_scratchpad_show() {
  local focused_id windows_json workspaces_json cursor selected_id tmp_file
  local -a hidden_ids matched_ids selected_ids

  parse_match_opts "$@"
  windows_json="$(niri_windows_json)"
  workspaces_json="$(niri_workspaces_json)"
  refresh_scratch_entries "$windows_json"

  focused_id="$(focused_window_id)"
  if [[ -n "$focused_id" ]] && scratch_entry_exists "$focused_id"; then
    scratchpad_move_all "$windows_json"
    return 0
  fi

  mapfile -t hidden_ids < <(jq -r '.entries // {} | to_entries[]? | select(.value.hidden == true) | .key' "$SCRATCH_FILE")
  [[ "${#hidden_ids[@]}" -gt 0 ]] || return 1

  if [[ -n "$MATCH_APP_ID$MATCH_TITLE$MATCH_PID$MATCH_WORKSPACE_ID$MATCH_WORKSPACE_INDEX$MATCH_WORKSPACE_NAME" ]]; then
    mapfile -t matched_ids < <(matched_window_ids "$windows_json" "$workspaces_json")
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
  local windows_json workspaces_json focused_id focused_once
  local -a hidden_ids matched_ids selected_ids

  parse_match_opts "$@"
  windows_json="$(niri_windows_json)"
  workspaces_json="$(niri_workspaces_json)"
  refresh_scratch_entries "$windows_json"

  focused_id="$(focused_window_id)"
  if [[ -n "$focused_id" ]] && scratch_entry_exists "$focused_id"; then
    scratchpad_move_all "$windows_json"
    return 0
  fi

  mapfile -t hidden_ids < <(jq -r '.entries // {} | to_entries[]? | select(.value.hidden == true) | .key' "$SCRATCH_FILE")
  [[ "${#hidden_ids[@]}" -gt 0 ]] || return 1

  if [[ -n "$MATCH_APP_ID$MATCH_TITLE$MATCH_PID$MATCH_WORKSPACE_ID$MATCH_WORKSPACE_INDEX$MATCH_WORKSPACE_NAME" ]]; then
    mapfile -t matched_ids < <(matched_window_ids "$windows_json" "$workspaces_json")
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
  local current_workspace current_workspace_idx
  current_workspace="$(current_workspace_id)"
  current_workspace_idx="$(current_workspace_index)"
  [[ -n "$current_workspace" ]] || return 1
  [[ -n "$current_workspace_idx" ]] || return 1
  for window_id in "${selected_ids[@]}"; do
    niri msg action move-window-to-workspace --window-id "$window_id" --focus false "$current_workspace_idx" >/dev/null 2>&1 || true
    set_scratch_hidden "$window_id" false "$current_workspace"
    if [[ "$focused_once" -eq 0 ]]; then
      niri msg action focus-window --id "$window_id" >/dev/null 2>&1 || true
      focused_once=1
    fi
  done
}

sync_follow_mode() {
  local current_workspace current_workspace_idx last_workspace
  local -a follow_ids

  current_workspace="$(current_workspace_id)"
  current_workspace_idx="$(current_workspace_index)"
  [[ -n "$current_workspace" ]] || return 0
  [[ -n "$current_workspace_idx" ]] || return 0

  last_workspace="$(jq -r '.last_workspace_id // ""' "$FOLLOW_FILE")"
  if [[ "$last_workspace" == "$current_workspace" ]]; then
    return 0
  fi

  mapfile -t follow_ids < <(jq -r '.windows // [] | .[]' "$FOLLOW_FILE")
  for window_id in "${follow_ids[@]}"; do
    niri msg action move-window-to-workspace --window-id "$window_id" --focus false "$current_workspace_idx" >/dev/null 2>&1 || true
  done

  update_json_locked "$FOLLOW_FILE" --arg ws "$current_workspace" '.last_workspace_id = $ws'
}

cmd_toggle_follow_mode() {
  local focused_id
  focused_id="$(focused_window_id)"
  [[ -n "$focused_id" ]] || return 1

  update_json_locked "$FOLLOW_FILE" '
    .windows = (.windows // []) |
    if (.windows | index($id)) != null then
      .windows = (.windows | map(select(. != $id)))
    else
      .windows = (.windows + [$id] | unique)
    end
  ' --arg id "$focused_id"
}


main() {
  local command="${1:-}"
  case "$command" in
    ""|-h|--help|help)
      usage
      exit 0
      ;;
    -V|--version)
      printf 'niri-osc flow %s\n' "$VERSION"
      exit 0
      ;;
  esac

  require_bins
  init_state
  sync_follow_mode
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
__NIRI_OSC_FLOW_PAYLOAD_20260208__
}

niri_osc_payload_sticky() {
  cat <<'__NIRI_OSC_STICKY_PAYLOAD_20260208__'
# -----------------------------------------------------------------------------
# niri-osc sticky
# -----------------------------------------------------------------------------
# Purpose:
# - Native sticky/stage workflow helper for Niri (no external `nsticky`).
# - Maintains sticky windows across workspace switches via daemon mode.
# - Implements stage cycle semantics: normal -> sticky -> staged -> sticky.
#
# Interface:
# - `niri-osc sticky sticky ...` : sticky list/state operations
# - `niri-osc sticky stage ...`  : stage list/state operations
# - `niri-osc sticky <action>`   : top-level sticky aliases (list/toggle/add/...)
# - `niri-osc sticky`        : daemon mode (workspace watcher)
#
# State (XDG):
# - ${XDG_STATE_HOME:-$HOME/.local/state}/niri-sticky/state.json
# - ${XDG_STATE_HOME:-$HOME/.local/state}/niri-sticky/state.lock
#
# Tunables:
# - NIRI_STICKY_POLL_INTERVAL   daemon poll interval (default: 0.35s)
# - NIRI_STICKY_STAGE_WORKSPACE stage workspace name (default: stage)
# - NIRI_STICKY_NOTIFY          1/0 enable notifications (default: 1)
# - NIRI_STICKY_NOTIFY_TIMEOUT  notify timeout ms (default: 1400)
#
# Dependencies:
# - niri
# - jq
# - flock
# -----------------------------------------------------------------------------

set -euo pipefail

VERSION="1.1.0"
STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
STATE_DIR="${STATE_HOME}/niri-sticky"
STATE_FILE="${STATE_DIR}/state.json"
LOCK_FILE="${STATE_DIR}/state.lock"
POLL_INTERVAL="${NIRI_STICKY_POLL_INTERVAL:-0.35}"
STAGE_WORKSPACE="${NIRI_STICKY_STAGE_WORKSPACE:-stage}"
NOTIFY_ENABLED="${NIRI_STICKY_NOTIFY:-1}"
NOTIFY_TIMEOUT="${NIRI_STICKY_NOTIFY_TIMEOUT:-1400}"

err() {
  printf 'Error: %s\n' "$*" >&2
  exit 1
}

info() {
  printf 'niri-osc sticky: %s\n' "$*" >&2
}

need_bins() {
  command -v niri >/dev/null 2>&1 || err "niri not found in PATH"
  command -v jq >/dev/null 2>&1 || err "jq not found in PATH"
  command -v flock >/dev/null 2>&1 || err "flock not found in PATH"
}

notify() {
  local urgency="${1:-low}"
  local title="${2:-Sticky}"
  local body="${3:-}"

  [[ "$NOTIFY_ENABLED" == "1" ]] || return 0
  command -v notify-send >/dev/null 2>&1 || return 0

  notify-send \
    -a "niri-osc sticky" \
    -u "$urgency" \
    -t "$NOTIFY_TIMEOUT" \
    -h "string:x-canonical-private-synchronous:niri-osc-sticky" \
    "$title" "$body" >/dev/null 2>&1 || true
}

usage() {
  cat <<'USAGE'
niri-osc sticky - sticky/stage workflow helper for Niri

Usage:
  niri-osc sticky [daemon]
  niri-osc sticky sticky <action> [args]
  niri-osc sticky stage  <action> [args]
  niri-osc sticky <sticky-action> [args]

Sticky actions:
  add <window_id>
  remove <window_id>
  list
  toggle-active
  toggle-appid <app_id>
  toggle-title <title-substring>

Stage actions:
  add <window_id>
  remove <window_id>
  list
  toggle-active
  toggle-appid <app_id>
  toggle-title <title-substring>
  add-all
  remove-all

Notes:
  - No args starts daemon mode.
  - Top-level `list/add/remove/toggle-*` commands are treated as sticky actions.
  - Stage workspace defaults to "stage" and can be changed by
    NIRI_STICKY_STAGE_WORKSPACE.
USAGE
}

with_lock() {
  mkdir -p "$STATE_DIR"
  touch "$LOCK_FILE"
  (
    flock -x 9 || exit 1
    "$@"
  ) 9>"$LOCK_FILE"
}

state_update_locked() {
  local jq_program="$1"
  shift

  local tmp
  tmp="$(mktemp)"
  if jq "$@" "$jq_program" "$STATE_FILE" >"$tmp"; then
    mv "$tmp" "$STATE_FILE"
  else
    rm -f "$tmp"
    err "failed to update state"
  fi
}

init_state_locked() {
  mkdir -p "$STATE_DIR"
  if ! jq -e . "$STATE_FILE" >/dev/null 2>&1; then
    printf '{"sticky":[],"staged":[],"daemon":{"last_workspace_id":""}}\n' >"$STATE_FILE"
  fi

  local tmp
  tmp="$(mktemp)"
  if jq '
      if type != "object" then {} else . end
      | .sticky = ((.sticky // []) | if type == "array" then map(tostring) else [] end | unique)
      | .staged = ((.staged // []) | if type == "array" then map(tostring) else [] end | unique)
      | .sticky = (.sticky - .staged)
      | .daemon = (
          if (.daemon | type) == "object" then .daemon else {} end
          | .last_workspace_id = ((.last_workspace_id // "") | tostring)
        )
    ' "$STATE_FILE" >"$tmp" 2>/dev/null; then
    mv "$tmp" "$STATE_FILE"
  else
    rm -f "$tmp"
    printf '{"sticky":[],"staged":[],"daemon":{"last_workspace_id":""}}\n' >"$STATE_FILE"
  fi
}

init_state() {
  with_lock init_state_locked
}

state_contains_locked() {
  local key="$1"
  local id="$2"
  jq -e --arg key "$key" --arg id "$id" \
    '.[$key] // [] | map(tostring) | index($id) != null' \
    "$STATE_FILE" >/dev/null 2>&1
}

state_add_locked() {
  local key="$1"
  local id="$2"
  state_update_locked '
    .[$key] = ((.[$key] // []) | map(tostring) + [$id] | unique)
  ' --arg key "$key" --arg id "$id"
}

state_remove_locked() {
  local key="$1"
  local id="$2"
  state_update_locked '
    .[$key] = ((.[$key] // []) | map(tostring) | map(select(. != $id)))
  ' --arg key "$key" --arg id "$id"
}

state_list_locked() {
  local key="$1"
  jq -r --arg key "$key" '.[$key] // [] | .[]' "$STATE_FILE"
}

state_list_json_locked() {
  local key="$1"
  jq -c --arg key "$key" '.[$key] // [] | map(tonumber? // .)' "$STATE_FILE"
}

state_set_last_workspace_locked() {
  local ws_id="$1"
  state_update_locked '.daemon.last_workspace_id = $ws' --arg ws "$ws_id"
}

state_get_last_workspace_locked() {
  jq -r '.daemon.last_workspace_id // ""' "$STATE_FILE"
}

require_window_id() {
  local window_id="$1"
  [[ "$window_id" =~ ^[0-9]+$ ]] || err "window_id must be numeric: $window_id"
}

niri_windows_json() {
  niri msg -j windows 2>/dev/null
}

niri_workspaces_json() {
  niri msg -j workspaces 2>/dev/null
}

focused_window_id() {
  niri msg -j focused-window 2>/dev/null | jq -r '.id // empty'
}

active_workspace_id() {
  local workspaces_json ws
  workspaces_json="$(niri_workspaces_json || true)"
  ws="$(jq -r '
      first(.[]? | select(.is_focused == true) | .id)
      // first(.[]? | select(.is_active == true) | .id)
      // empty
    ' <<<"${workspaces_json:-[]}" 2>/dev/null || true)"
  printf '%s\n' "$ws"
}

active_workspace_index() {
  local windows_json workspaces_json
  windows_json="$(niri_windows_json || true)"
  workspaces_json="$(niri_workspaces_json || true)"

  jq -n \
    --argjson wins "${windows_json:-[]}" \
    --argjson wss "${workspaces_json:-[]}" \
    -r '
      def ws_by_id: reduce $wss[] as $ws ({}; .[($ws.id|tostring)] = $ws);
      (first($wins[]? | select(.is_focused == true and .workspace_id != null) | .workspace_id) // null) as $wid
      | if $wid != null then
          ((ws_by_id[($wid|tostring)] // {}).idx // empty)
        else
          (first($wss[]? | select(.is_focused == true) | .idx)
           // first($wss[]? | select(.is_active == true) | .idx)
           // empty)
        end
    '
}

window_exists_in_json() {
  local window_id="$1"
  local windows_json="$2"
  jq -e --arg id "$window_id" 'any(.[]?; (.id | tostring) == $id)' <<<"$windows_json" >/dev/null 2>&1
}

find_window_by_appid() {
  local appid="$1"
  local windows_json
  windows_json="$(niri_windows_json || true)"
  jq -r --arg appid "$appid" '
    first(.[]? | select((.app_id // "") == $appid) | .id) // empty
  ' <<<"${windows_json:-[]}" 2>/dev/null || true
}

find_window_by_title() {
  local title="$1"
  local windows_json
  windows_json="$(niri_windows_json || true)"
  jq -r --arg title "$title" '
    first(.[]? | select((.title // "") | contains($title)) | .id) // empty
  ' <<<"${windows_json:-[]}" 2>/dev/null || true
}

move_window_to_workspace() {
  local window_id="$1"
  local workspace_ref="$2"
  niri msg action move-window-to-workspace --window-id "$window_id" --focus false "$workspace_ref" >/dev/null 2>&1
}

prune_state_locked_with_windows() {
  local windows_json="$1"
  local live_ids
  live_ids="$(jq '[.[]? | .id | tostring]' <<<"$windows_json")"

  state_update_locked '
    .sticky = ((.sticky // []) | map(tostring) | unique | map(select(($live | index(.)) != null)))
    | .staged = ((.staged // []) | map(tostring) | unique | map(select(($live | index(.)) != null)))
    | .sticky = (.sticky - .staged)
  ' --argjson live "$live_ids"
}

ensure_window_exists_locked() {
  local window_id="$1"
  local windows_json
  windows_json="$(niri_windows_json || true)"
  [[ -n "$windows_json" ]] || err "failed to query niri windows"
  window_exists_in_json "$window_id" "$windows_json" || err "Window not found in Niri"
}

sticky_add_locked() {
  local window_id="$1"
  local ws_idx

  ensure_window_exists_locked "$window_id"

  if state_contains_locked "staged" "$window_id"; then
    ws_idx="$(active_workspace_index || true)"
    [[ -n "$ws_idx" ]] || err "active workspace not found"
    move_window_to_workspace "$window_id" "$ws_idx" || err "failed to move window"
    state_remove_locked "staged" "$window_id"
  fi

  if state_contains_locked "sticky" "$window_id"; then
    printf 'Already in sticky list\n'
    return 0
  fi

  state_add_locked "sticky" "$window_id"
  printf 'Added\n'
}

sticky_remove_locked() {
  local window_id="$1"

  ensure_window_exists_locked "$window_id"

  if state_contains_locked "sticky" "$window_id"; then
    state_remove_locked "sticky" "$window_id"
    printf 'Removed\n'
  else
    printf 'Not in sticky list\n'
  fi
}

sticky_toggle_active_locked() {
  local window_id="$1"

  ensure_window_exists_locked "$window_id"

  if state_contains_locked "sticky" "$window_id"; then
    state_remove_locked "sticky" "$window_id"
    printf 'Removed active window from sticky\n'
  else
    state_add_locked "sticky" "$window_id"
    printf 'Added active window to sticky\n'
  fi
}

sticky_toggle_target_locked() {
  local window_id="$1"
  local ws_idx

  ensure_window_exists_locked "$window_id"

  if state_contains_locked "staged" "$window_id"; then
    ws_idx="$(active_workspace_index || true)"
    [[ -n "$ws_idx" ]] || err "active workspace not found"
    move_window_to_workspace "$window_id" "$ws_idx" || err "failed to move window"
    state_remove_locked "staged" "$window_id"
    state_add_locked "sticky" "$window_id"
    printf 'Added window to sticky\n'
    return 0
  fi

  if state_contains_locked "sticky" "$window_id"; then
    state_remove_locked "sticky" "$window_id"
    printf 'Removed window from sticky\n'
  else
    state_add_locked "sticky" "$window_id"
    printf 'Added window to sticky\n'
  fi
}

stage_add_locked() {
  local window_id="$1"

  ensure_window_exists_locked "$window_id"

  if state_contains_locked "staged" "$window_id"; then
    err "Window is already in staged list"
  fi

  if ! state_contains_locked "sticky" "$window_id"; then
    err "Window is not in sticky list, cannot stage"
  fi

  move_window_to_workspace "$window_id" "$STAGE_WORKSPACE" || err "failed to move window to stage"
  state_remove_locked "sticky" "$window_id"
  state_add_locked "staged" "$window_id"
  printf 'Staged window\n'
}

stage_remove_locked() {
  local window_id="$1"
  local ws_idx

  ensure_window_exists_locked "$window_id"

  if state_contains_locked "sticky" "$window_id"; then
    err "Window is already in sticky list"
  fi

  if ! state_contains_locked "staged" "$window_id"; then
    err "Window is not in staged list, cannot unstage"
  fi

  ws_idx="$(active_workspace_index || true)"
  [[ -n "$ws_idx" ]] || err "active workspace not found"

  move_window_to_workspace "$window_id" "$ws_idx" || err "failed to move window from stage"
  state_remove_locked "staged" "$window_id"
  state_add_locked "sticky" "$window_id"
  printf 'Unstaged window\n'
}

stage_toggle_known_locked() {
  local window_id="$1"
  local not_sticky_error="$2"
  local ws_idx

  ensure_window_exists_locked "$window_id"

  if state_contains_locked "staged" "$window_id"; then
    ws_idx="$(active_workspace_index || true)"
    [[ -n "$ws_idx" ]] || err "active workspace not found"
    move_window_to_workspace "$window_id" "$ws_idx" || err "failed to unstage window"
    state_remove_locked "staged" "$window_id"
    state_add_locked "sticky" "$window_id"
    return 0
  fi

  if state_contains_locked "sticky" "$window_id"; then
    move_window_to_workspace "$window_id" "$STAGE_WORKSPACE" || err "failed to stage window"
    state_remove_locked "sticky" "$window_id"
    state_add_locked "staged" "$window_id"
    return 0
  fi

  err "$not_sticky_error"
}

stage_toggle_active_locked() {
  local window_id="$1"
  local ws_idx

  ensure_window_exists_locked "$window_id"

  if state_contains_locked "staged" "$window_id"; then
    ws_idx="$(active_workspace_index || true)"
    [[ -n "$ws_idx" ]] || err "active workspace not found"
    move_window_to_workspace "$window_id" "$ws_idx" || err "failed to unstage active window"
    state_remove_locked "staged" "$window_id"
    state_add_locked "sticky" "$window_id"
    printf 'Unstaged active window\n'
    return 0
  fi

  if state_contains_locked "sticky" "$window_id"; then
    move_window_to_workspace "$window_id" "$STAGE_WORKSPACE" || err "failed to stage active window"
    state_remove_locked "sticky" "$window_id"
    state_add_locked "staged" "$window_id"
    printf 'Staged active window\n'
    return 0
  fi

  state_add_locked "sticky" "$window_id"
  printf 'Added active window to sticky\n'
}

stage_add_all_locked() {
  local -a ids
  local count=0

  mapfile -t ids < <(state_list_locked "sticky")
  for window_id in "${ids[@]}"; do
    if move_window_to_workspace "$window_id" "$STAGE_WORKSPACE"; then
      state_remove_locked "sticky" "$window_id"
      state_add_locked "staged" "$window_id"
      ((count += 1))
    fi
  done

  printf 'Staged %d windows\n' "$count"
}

stage_remove_all_locked() {
  local -a ids
  local count=0
  local ws_idx

  ws_idx="$(active_workspace_index || true)"
  [[ -n "$ws_idx" ]] || err "active workspace not found"

  mapfile -t ids < <(state_list_locked "staged")
  for window_id in "${ids[@]}"; do
    if move_window_to_workspace "$window_id" "$ws_idx"; then
      state_remove_locked "staged" "$window_id"
      state_add_locked "sticky" "$window_id"
      ((count += 1))
    fi
  done

  printf 'Unstaged %d windows\n' "$count"
}

daemon_tick_locked() {
  local windows_json ws_id ws_idx last_ws

  windows_json="$(niri_windows_json || true)"
  [[ -n "$windows_json" ]] || return 0

  prune_state_locked_with_windows "$windows_json"

  ws_id="$(active_workspace_id || true)"
  ws_idx="$(active_workspace_index || true)"
  [[ -n "$ws_id" && -n "$ws_idx" ]] || return 0

  last_ws="$(state_get_last_workspace_locked)"
  if [[ "$ws_id" != "$last_ws" ]]; then
    local -a ids
    mapfile -t ids < <(state_list_locked "sticky")
    for window_id in "${ids[@]}"; do
      move_window_to_workspace "$window_id" "$ws_idx" || true
    done
    state_set_last_workspace_locked "$ws_id"
  fi
}

run_daemon() {
  info "starting daemon (poll=${POLL_INTERVAL}s, stage=${STAGE_WORKSPACE})"
  while true; do
    with_lock daemon_tick_locked || true
    sleep "$POLL_INTERVAL"
  done
}

cmd_sticky() {
  local action="${1:-}"
  shift || true

  case "$action" in
    add|a)
      [[ $# -eq 1 ]] || err "sticky add requires <window_id>"
      require_window_id "$1"
      with_lock sticky_add_locked "$1"
      ;;
    remove|r)
      [[ $# -eq 1 ]] || err "sticky remove requires <window_id>"
      require_window_id "$1"
      with_lock sticky_remove_locked "$1"
      ;;
    list|l)
      with_lock state_list_json_locked "sticky"
      ;;
    toggle-active|t)
      local window_id out
      window_id="$(focused_window_id)"
      [[ -n "$window_id" ]] || err "Active window not found"

      out="$(with_lock sticky_toggle_active_locked "$window_id")"
      case "$out" in
        Added*) notify low "Sticky" "Active window added" ;;
        Removed*) notify low "Sticky" "Active window removed" ;;
      esac
      printf '%s\n' "$out"
      ;;
    toggle-appid|ta)
      [[ $# -eq 1 ]] || err "sticky toggle-appid requires <app_id>"
      local appid="$1" window_id out
      window_id="$(find_window_by_appid "$appid" || true)"
      [[ -n "$window_id" ]] || err "No window found with appid $appid"

      out="$(with_lock sticky_toggle_target_locked "$window_id")"
      case "$out" in
        Added*) notify low "Sticky" "Window added" ;;
        Removed*) notify low "Sticky" "Window removed" ;;
      esac
      printf '%s\n' "$out"
      ;;
    toggle-title|tt)
      [[ $# -ge 1 ]] || err "sticky toggle-title requires <title-substring>"
      local title="$*" window_id out
      window_id="$(find_window_by_title "$title" || true)"
      [[ -n "$window_id" ]] || err "No window found with title containing '$title'"

      out="$(with_lock sticky_toggle_target_locked "$window_id")"
      case "$out" in
        Added*) notify low "Sticky" "Window added" ;;
        Removed*) notify low "Sticky" "Window removed" ;;
      esac
      printf '%s\n' "$out"
      ;;
    *)
      err "unknown sticky action: ${action:-<empty>}"
      ;;
  esac
}

cmd_stage() {
  local action="${1:-}"
  shift || true

  case "$action" in
    list|l)
      with_lock state_list_json_locked "staged"
      ;;
    add|a)
      [[ $# -eq 1 ]] || err "stage add requires <window_id>"
      require_window_id "$1"
      with_lock stage_add_locked "$1"
      ;;
    remove|r)
      [[ $# -eq 1 ]] || err "stage remove requires <window_id>"
      require_window_id "$1"
      with_lock stage_remove_locked "$1"
      ;;
    toggle-active|t)
      local window_id out
      window_id="$(focused_window_id)"
      [[ -n "$window_id" ]] || err "Active window not found"

      out="$(with_lock stage_toggle_active_locked "$window_id")"
      case "$out" in
        Added*) notify low "Sticky" "Active window added" ;;
        Staged*) notify low "Stage" "Active window moved to stage" ;;
        Unstaged*) notify low "Stage" "Active window restored to sticky" ;;
      esac
      printf '%s\n' "$out"
      ;;
    toggle-appid|ta)
      [[ $# -eq 1 ]] || err "stage toggle-appid requires <app_id>"
      local appid="$1" window_id
      window_id="$(find_window_by_appid "$appid" || true)"
      [[ -n "$window_id" ]] || err "No window found with appid $appid"

      with_lock stage_toggle_known_locked "$window_id" "Window with appid $appid is not in sticky list"
      printf 'Toggled stage status by app ID\n'
      ;;
    toggle-title|tt)
      [[ $# -ge 1 ]] || err "stage toggle-title requires <title-substring>"
      local title="$*" window_id
      window_id="$(find_window_by_title "$title" || true)"
      [[ -n "$window_id" ]] || err "No window found with title containing '$title'"

      with_lock stage_toggle_known_locked "$window_id" "Window with title containing '$title' is not in sticky list"
      printf 'Toggled stage status by title\n'
      ;;
    add-all|aa)
      with_lock stage_add_all_locked
      ;;
    remove-all|ra)
      with_lock stage_remove_all_locked
      ;;
    *)
      err "unknown stage action: ${action:-<empty>}"
      ;;
  esac
}

main() {
  local cmd="${1:-daemon}"
  case "$cmd" in
    help|-h|--help)
      usage
      return 0
      ;;
    version|-V|--version)
      printf 'niri-osc sticky %s\n' "$VERSION"
      return 0
      ;;
  esac

  need_bins
  init_state
  shift || true

  case "$cmd" in
    daemon)
      run_daemon
      ;;
    sticky)
      cmd_sticky "$@"
      ;;
    stage)
      cmd_stage "$@"
      ;;
    list|l|add|a|remove|r|toggle-active|t|toggle-appid|ta|toggle-title|tt)
      cmd_sticky "$cmd" "$@"
      ;;
    *)
      err "unknown command: $cmd"
      ;;
  esac
}

main "$@"
__NIRI_OSC_STICKY_PAYLOAD_20260208__
}

niri_osc_payload_keybinds() {
  cat <<'__NIRI_OSC_KEYBINDS_PAYLOAD_20260208__'
# -----------------------------------------------------------------------------
# niri-osc keybinds
# -----------------------------------------------------------------------------
# Purpose:
# - Parse Niri `binds { ... }` blocks into launcher-friendly plain text lines.
# - Produce keybind/title/command entries consumable by rofi/fuzzel/dmenu.
#
# Input/Output model:
# - Input: KDL config (default: ~/.config/niri/config.kdl)
# - Output: one formatted line per bind to stdout
# - Optional cleanup: remove spawn prefixes and/or command quotes
#
# Typical usage:
# - niri-osc keybinds | rofi -dmenu -i -p "Niri Keybinds"
# - niri-osc keybinds | fuzzel -d
#
# Dependencies:
# - awk
# - notify-send (optional; used for parse/file errors)
#
# Notes:
# - Parser is intentionally pragmatic (line-oriented) for speed and portability.
# - Run `niri-osc keybinds --help` for formatting and filtering options.
# -----------------------------------------------------------------------------

set -euo pipefail

# -----------------------------
# Defaults
DEFAULT_KDL="${HOME}/.config/niri/config.kdl"
DEFAULT_SEP_KB=$'\t| '
DEFAULT_SEP_TITLE=$' |\t'
DEFAULT_LINE_END=$'\n'

KEYBIND_KDL_PATH="$DEFAULT_KDL"
INCLUDE_OVERLAY_TITLES=1 # Python: default include (exclude_titles flag toggles)
REMOVE_CMD_QUOTATIONS=1  # Python: default remove (include_command_quotes toggles)
REMOVE_SPAWN_PREFIX=1    # Python: default remove (include_spawn_prefix toggles)
PAD_KEYBIND=8
PAD_TITLE=32
SEP_KEYBIND="$DEFAULT_SEP_KB"
SEP_TITLE="$DEFAULT_SEP_TITLE"
OUTPUT_LINE_END="$DEFAULT_LINE_END"

# -----------------------------
# Helpers
notify_error() {
  local title="$1"
  local msg="$2"
  if command -v notify-send >/dev/null 2>&1; then
    notify-send "$title" "$msg"
  else
    printf 'ERROR: %s\n%s\n' "$title" "$msg" >&2
  fi
}

usage() {
  cat <<EOF
Usage: niri-osc keybinds [options]

Parse niri keybinds into launcher-friendly output.

Options:
  -i,  --keybind_kdl PATH        Path to keybinds.kdl (default: $DEFAULT_KDL)
  -t,  --exclude_titles          Do not include 'hotkey-overlay-title' in output
  -s,  --include_spawn_prefix    Keep 'spawn'/'spawn-sh' prefix in commands
  -c,  --include_command_quotes  Keep apostrophes & quotation marks in commands
  -pk, --pad_keybind N           Padding added to keybinds (default: 8)
  -pt, --pad_title N             Padding added to titles (default: 32)
  -ak, --sep_keybind STR         Separator after keybind text (default: \$'\\t| ')
  -at, --sep_title STR           Separator after title text (default: \$' |\\t')
  -e,  --output_line_end STR     Line ending string for output (default: \$'\\n')
  -h,  --help                    Show this help

Example:
  niri-osc keybinds | fuzzel -d
EOF
}

# -----------------------------
# Arg parsing (supports short + long, including -pk/-pt/-ak/-at)
while [[ $# -gt 0 ]]; do
  case "$1" in
  -i | --keybind_kdl)
    [[ $# -ge 2 ]] || {
      usage >&2
      exit 2
    }
    KEYBIND_KDL_PATH="$2"
    shift 2
    ;;
  -t | --exclude_titles)
    INCLUDE_OVERLAY_TITLES=0
    shift
    ;;
  -s | --include_spawn_prefix)
    REMOVE_SPAWN_PREFIX=0
    shift
    ;;
  -c | --include_command_quotes)
    REMOVE_CMD_QUOTATIONS=0
    shift
    ;;
  -pk | --pad_keybind)
    [[ $# -ge 2 ]] || {
      usage >&2
      exit 2
    }
    PAD_KEYBIND="$2"
    shift 2
    ;;
  -pt | --pad_title)
    [[ $# -ge 2 ]] || {
      usage >&2
      exit 2
    }
    PAD_TITLE="$2"
    shift 2
    ;;
  -ak | --sep_keybind)
    [[ $# -ge 2 ]] || {
      usage >&2
      exit 2
    }
    SEP_KEYBIND="$2"
    shift 2
    ;;
  -at | --sep_title)
    [[ $# -ge 2 ]] || {
      usage >&2
      exit 2
    }
    SEP_TITLE="$2"
    shift 2
    ;;
  -e | --output_line_end)
    [[ $# -ge 2 ]] || {
      usage >&2
      exit 2
    }
    OUTPUT_LINE_END="$2"
    shift 2
    ;;
  -h | --help)
    usage
    exit 0
    ;;
  *)
    printf 'Unknown option: %s\n\n' "$1" >&2
    usage >&2
    exit 2
    ;;
  esac
done

# Expand ~ manually (bash does it for unquoted, but we want to be safe)
if [[ "$KEYBIND_KDL_PATH" == "~/"* ]]; then
  KEYBIND_KDL_PATH="${HOME}/${KEYBIND_KDL_PATH#~/}"
fi

# -----------------------------
# Read & validate file
if [[ ! -f "$KEYBIND_KDL_PATH" ]]; then
  notify_error "Error parsing keybinds!" "Not found: $KEYBIND_KDL_PATH"
  exit 1
fi

# -----------------------------
# Parse using awk
# We:
# - enter binds section when we see: ^\s*binds(\s*\{)?
# - start processing after that line
# - stop at a line that is exactly: }
#
# Notes:
# - We keep the parsing behavior close to your Python version (simple split on '{' and ';').
# - If a line contains multiple '{', it is skipped (same as Python).
#
awk \
  -v include_titles="$INCLUDE_OVERLAY_TITLES" \
  -v remove_quotes="$REMOVE_CMD_QUOTATIONS" \
  -v remove_spawn="$REMOVE_SPAWN_PREFIX" \
  -v pad_k="$PAD_KEYBIND" \
  -v pad_t="$PAD_TITLE" \
  -v sep_k="$SEP_KEYBIND" \
  -v sep_t="$SEP_TITLE" \
  -v out_end="$OUTPUT_LINE_END" \
  '
  function ltrim(s) { sub(/^[ \t\r\n]+/, "", s); return s }
  function rtrim(s) { sub(/[ \t\r\n]+$/, "", s); return s }
  function trim(s)  { return rtrim(ltrim(s)) }

  BEGIN {
    in_binds = 0
    found_binds = 0
    out_count = 0
  }

  {
    raw = $0

    # Detect binds section start (line may contain extra spaces before "{")
    if (!in_binds) {
      if (raw ~ /^[ \t]*binds([ \t]*\{)?[ \t]*$/ || raw ~ /^[ \t]*binds[ \t]*\{[ \t]*$/) {
        in_binds = 1
        found_binds = 1
        next
      }
    } else {
      line = trim(raw)

      # End of binds section
      if (line == "}") {
        in_binds = 0
        next
      }

      # Skip comments and short/junk lines
      if (line ~ /^\/\//) next
      if (length(line) < 3) next

      # Split on "{"
      # If more than 1 "{", skip (unexpected)
      n = split(line, parts, "{")
      if (n != 2) next

      config = parts[1]
      cmdpart = parts[2]

      # Extract keybind: first token in config
      # Similar to python: config.split(" ", 1)[0]
      keybind = config
      sub(/[ \t].*$/, "", keybind)

      # Extract first command up to ";"
      m = split(cmdpart, cmds, ";")
      command = trim(cmds[1])

      # Remove spawn/spawn-sh prefix if requested
      if (remove_spawn == 1) {
        if (command ~ /^spawn-sh[ \t]+/) sub(/^spawn-sh[ \t]+/, "", command)
        else if (command ~ /^spawn[ \t]+/) sub(/^spawn[ \t]+/, "", command)
      }

      # Remove quotes if requested
      if (remove_quotes == 1) {
        gsub(/"/, "", command)
        gsub(/\x27/, "", command)   # single quote
      }

      # Parse hotkey overlay title if requested
      title = ""
      if (include_titles == 1) {
        target = "hotkey-overlay-title="
        pos = index(config, target)
        if (pos > 0) {
          rest = substr(config, pos + length(target))
          rest = trim(rest)
          if (rest !~ /^null/) {
            marker = substr(rest, 1, 1)   # quote char
            # Split by marker: <marker> TITLE <marker> ...
            k = split(rest, tt, marker)
            if (k >= 3) title = tt[2]
          }
        }
      }

      # Padding
      keybind_padded = sprintf("%-*s", pad_k, keybind)

      if (length(title) > 0) {
        title_padded = sprintf("%-*s", pad_t, title)
        out[++out_count] = keybind_padded sep_k title_padded sep_t command
      } else {
        out[++out_count] = keybind_padded sep_k command
      }
    }
  }

  END {
    if (found_binds == 0) {
      # Mirror python behavior: notify + error
      # We cannot call notify-send reliably from awk portably, so print to stderr.
      # Caller bash already validated file, but not binds presence.
      print "Error parsing keybinds! Could not find binds {...} section" > "/dev/stderr"
      exit 3
    }

    for (i=1; i<=out_count; i++) {
      # Print with custom line terminator between lines
      printf "%s", out[i]
      if (i < out_count) printf "%s", out_end
    }
    if (out_count > 0) printf "%s", out_end
  }
  ' "$KEYBIND_KDL_PATH" || {
  # If awk returned our binds-not-found exit code or other error, also send notify.
  rc=$?
  if [[ $rc -eq 3 ]]; then
    notify_error "Error parsing keybinds!" "Could not find binds {...} section"
  fi
  exit "$rc"
}
__NIRI_OSC_KEYBINDS_PAYLOAD_20260208__
}

niri_osc_payload_drop() {
  cat <<'__NIRI_OSC_DROP_PAYLOAD_20260208__'
# ==============================================================================
# niri-osc drop - Toggle a drop-down style window in Niri
# ==============================================================================
# Features:
# - If the program is not running: launch it and bring it to foreground.
# - If it runs on another workspace: bring it to current workspace and focus.
# - If it runs on current workspace: hide it (default) or only focus (--focus).
#
# Matching:
# - Default key is command name (first arg).
# - Optional class/app-id extraction from command args (`--class`, foot `-a/--app-id`).
# - Override with `-c/--class`.
#
# Environment:
# - OSC_NDROP_NIRI_HIDE_WORKSPACE  (default: oscndrop)
# - OSC_NDROP_ONLINE_HOST          (default: github.com)
# - OSC_NDROP_ONLINE_TIMEOUT       (default: 20 seconds)
# ==============================================================================

set -euo pipefail

if [[ "${OSC_NDROP_DEBUG:-0}" == "1" ]]; then
  set -x
fi

SCRIPT_NAME="niri-osc drop"
VERSION="0.2.0"

print_help() {
  cat <<EOF
${SCRIPT_NAME} v${VERSION}

Usage:
  ${SCRIPT_NAME} [OPTIONS] <command...>

Options:
  -c, --class <CLASS>     Override class/app-id used for matching
  -F, --focus             Focus-only mode (never hide)
  -i, --insensitive       Case-insensitive partial matching
  -o, --online            Wait for internet connectivity before first launch
  -v, --verbose           Show notifications (if notify-send is available)
  --niri-hide-workspace <index|name>
                          Workspace used to hide windows (default: \$OSC_NDROP_NIRI_HIDE_WORKSPACE or "oscndrop")
  -H, --help              Show help
  -V, --version           Show version

Examples:
  ${SCRIPT_NAME} kitty --class dropdown-terminal
  ${SCRIPT_NAME} kitty --class kitty_1
EOF
}

print_version() {
  echo "${SCRIPT_NAME} v${VERSION}"
}

notify() {
  local title="$1"
  local body="$2"
  local urgency="${3:-normal}"
  if command -v notify-send >/dev/null 2>&1; then
    notify-send -u "$urgency" -t 1500 "$title" "$body" >/dev/null 2>&1 || true
  fi
}

die() {
  echo "Error: $*" >&2
  exit 1
}

regex_escape() {
  local s="$1"
  s="$(printf '%s' "$s" | sed -e 's/[][\\.^$*+?(){}|]/\\&/g')"
  printf '%s' "$s"
}

wait_online() {
  local host="$1"
  local timeout_s="$2"
  local i=0

  while ((i < timeout_s * 10)); do
    if ping -qc 1 -W 1 "$host" >/dev/null 2>&1; then
      return 0
    fi
    sleep 0.1
    ((i++))
  done

  return 1
}

FOCUS=false
INSENSITIVE=false
ONLINE=false
VERBOSE=false

NIRI_HIDE_WORKSPACE="${OSC_NDROP_NIRI_HIDE_WORKSPACE:-oscndrop}"
ONLINE_HOST="${OSC_NDROP_ONLINE_HOST:-github.com}"
ONLINE_TIMEOUT="${OSC_NDROP_ONLINE_TIMEOUT:-20}"
CLASS_OVERRIDE=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    -c|--class)
      shift
      CLASS_OVERRIDE="${1:-}"
      [[ -n "$CLASS_OVERRIDE" ]] || die "--class requires a value"
      shift
      ;;
    -F|--focus)
      FOCUS=true
      shift
      ;;
    -i|--insensitive)
      INSENSITIVE=true
      shift
      ;;
    -o|--online)
      ONLINE=true
      shift
      ;;
    -v|--verbose)
      VERBOSE=true
      shift
      ;;
    --niri-hide-workspace)
      shift
      NIRI_HIDE_WORKSPACE="${1:-}"
      [[ -n "$NIRI_HIDE_WORKSPACE" ]] || die "--niri-hide-workspace requires a value"
      shift
      ;;
    -H|--help)
      print_help
      exit 0
      ;;
    -V|--version)
      print_version
      exit 0
      ;;
    --)
      shift
      break
      ;;
    -*)
      die "Unknown option: $1"
      ;;
    *)
      break
      ;;
  esac
done

[[ $# -gt 0 ]] || die "Missing command. Try '${SCRIPT_NAME} --help'"

COMMANDLINE=("$@")
COMMAND="${COMMANDLINE[0]}"
CLASS="$COMMAND"

case "$COMMAND" in
  epiphany) CLASS="org.gnome.Epiphany" ;;
  brave) CLASS="brave-browser" ;;
  godot4)
    CLASS="org.godotengine."
    INSENSITIVE=true
    ;;
  logseq) CLASS="Logseq" ;;
  telegram-desktop) CLASS="org.telegram.desktop" ;;
  tor-browser) CLASS="Tor Browser" ;;
esac

if [[ "$COMMAND" == "foot" ]]; then
  for ((i = 1; i < ${#COMMANDLINE[@]}; i++)); do
    case "${COMMANDLINE[i]}" in
      -a|--app-id)
        if ((i + 1 < ${#COMMANDLINE[@]})); then
          CLASS="${COMMANDLINE[i + 1]}"
        fi
        ;;
    esac
  done
else
  for ((i = 1; i < ${#COMMANDLINE[@]}; i++)); do
    case "${COMMANDLINE[i]}" in
      --class)
        if ((i + 1 < ${#COMMANDLINE[@]})); then
          CLASS="${COMMANDLINE[i + 1]}"
        fi
        ;;
    esac
  done
fi

if [[ -n "$CLASS_OVERRIDE" ]]; then
  CLASS="$CLASS_OVERRIDE"
fi

launch_command() {
  if $ONLINE; then
    if ! wait_online "$ONLINE_HOST" "$ONLINE_TIMEOUT"; then
      $VERBOSE && notify "niri-osc drop" "Online check timed out, launching anyway." "low"
    fi
  fi

  $VERBOSE && notify "niri-osc drop" "Launching: ${COMMANDLINE[*]}" "low"
  "${COMMANDLINE[@]}" &
  disown || true
}

niri_toggle() {
  command -v niri >/dev/null 2>&1 || die "niri not found in PATH"
  command -v jq >/dev/null 2>&1 || { launch_command; return 0; }

  if ! niri msg -j version >/dev/null 2>&1; then
    die "niri IPC erişilemiyor (NIRI_SOCKET yok/erişim yok)"
  fi

  local windows workspaces current_ws_id current_ws_ref
  windows="$(niri msg -j windows 2>/dev/null || echo '[]')"
  workspaces="$(niri msg -j workspaces 2>/dev/null || echo '[]')"

  current_ws_id="$(echo "$workspaces" | jq -r 'first(.[] | select(.is_focused==true) | .id) // empty')"
  current_ws_ref="$(echo "$workspaces" | jq -r 'first(.[] | select(.is_focused==true) | .idx) // empty')"

  if [[ -z "$current_ws_id" || -z "$current_ws_ref" ]]; then
    launch_command
    return 0
  fi

  local insensitive_json=false
  $INSENSITIVE && insensitive_json=true

  local app_id_re
  if $INSENSITIVE; then
    app_id_re="(?i)$(regex_escape "$CLASS")"
  else
    app_id_re="^$(regex_escape "$CLASS")$"
  fi

  local window_id_here
  window_id_here="$({
    echo "$windows" | jq -r --arg cls "$CLASS" --arg ws "$current_ws_id" --argjson insensitive "$insensitive_json" '
      first(
        .[]
        | select(if $insensitive then ((.app_id // "") | test($cls; "i")) else ((.app_id // "") == $cls) end)
        | select((.workspace_id|tostring) == ($ws|tostring))
        | .id
      ) // empty
    '
  })"

  if [[ -n "$window_id_here" ]]; then
    if $FOCUS; then
      niri msg action focus-window --id "$window_id_here" >/dev/null 2>&1 || true
      $VERBOSE && notify "Niri" "Focused: ${CLASS}" "low"
      return 0
    fi

    niri msg action focus-window --id "$window_id_here" >/dev/null 2>&1 || true
    if command -v niri-osc >/dev/null 2>&1; then
      niri-osc flow scratchpad-toggle --app-id "$app_id_re" --workspace-id "$current_ws_id" >/dev/null 2>&1 || true
    else
      niri msg action move-window-to-workspace --window-id "$window_id_here" --focus false "$NIRI_HIDE_WORKSPACE" >/dev/null 2>&1 || true
    fi

    $VERBOSE && notify "Niri" "Hidden: ${CLASS}" "low"
    return 0
  fi

  local window_id_any
  window_id_any="$({
    echo "$windows" | jq -r --arg cls "$CLASS" --argjson insensitive "$insensitive_json" '
      first(
        .[]
        | select(if $insensitive then ((.app_id // "") | test($cls; "i")) else ((.app_id // "") == $cls) end)
        | .id
      ) // empty
    '
  })"

  if [[ -z "$window_id_any" ]]; then
    launch_command
    return 0
  fi

  if $FOCUS; then
    niri msg action focus-window --id "$window_id_any" >/dev/null 2>&1 || true
    $VERBOSE && notify "Niri" "Focused: ${CLASS}" "low"
    return 0
  fi

  if command -v niri-osc >/dev/null 2>&1; then
    if niri-osc flow scratchpad-show --app-id "$app_id_re" >/dev/null 2>&1; then
      $VERBOSE && notify "Niri" "Shown: ${CLASS}" "low"
      return 0
    fi

    if niri-osc flow move-to-current-workspace --app-id "$app_id_re" --focus >/dev/null 2>&1; then
      $VERBOSE && notify "Niri" "Moved here: ${CLASS}" "low"
      return 0
    fi
  fi

  niri msg action move-window-to-workspace --window-id "$window_id_any" --focus false "$current_ws_ref" >/dev/null 2>&1 || true
  niri msg action focus-window --id "$window_id_any" >/dev/null 2>&1 || true
  $VERBOSE && notify "Niri" "Moved here: ${CLASS}" "low"
}

niri_toggle
__NIRI_OSC_DROP_PAYLOAD_20260208__
}
niri_osc_payload_for_scope() {
  local scope="$1"
  case "$scope" in
  set)
    niri_osc_payload_set
    ;;
  flow)
    niri_osc_payload_flow
    ;;
  sticky)
    niri_osc_payload_sticky
    ;;
  keybinds)
    niri_osc_payload_keybinds
    ;;
  drop)
    niri_osc_payload_drop
    ;;
  *)
    printf 'niri-osc: unknown scope: %s\n' "$scope" >&2
    return 1
    ;;
  esac
}

main() {
  # Global cleanup for temporary files on exit
  _niri_osc_cleanup() {
    local rc=$?
    # Only cleanup if we have temp files (if any were created by mktemp)
    # Most sub-scopes handle their own, but this is a safety net.
    return $rc
  }
  trap _niri_osc_cleanup EXIT

  local raw_scope="${1:-help}"
  local scope
  scope="$(niri_osc_scope_alias "$raw_scope")"

  case "$scope" in
  help | -h | --help)
    shift || true
    if [[ $# -gt 0 ]]; then
      local help_scope
      help_scope="$(niri_osc_scope_alias "$1")"
      if niri_osc_is_scope "$help_scope"; then
        shift || true
        niri_osc_run_scope "$help_scope" --help "$@"
        return 0
      fi
    fi
    niri_osc_usage
    ;;

  doctor)
    shift || true
    niri_osc_doctor "$@"
    ;;

  version | -V | --version)
    printf 'niri-osc %s\n' "$NIRI_OSC_VERSION"
    ;;

  set | flow | sticky | keybinds | drop)
    shift || true
    niri_osc_run_scope "$scope" "$@"
    ;;

  *)
    printf 'niri-osc: unknown scope: %s\n' "$raw_scope" >&2
    niri_osc_usage >&2
    exit 1
    ;;
  esac
}

main "$@"
