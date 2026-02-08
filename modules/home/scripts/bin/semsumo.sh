#!/usr/bin/env bash
# semsumo.sh - Uygulama başlatıcı toplu script
# Sık kullanılan tarayıcı/profil ve yardımcı uygulamaları doğru env ile başlatır.

#===============================================================================
#
#   Script: Semsumo Unified - Enhanced Application Launcher & Generator
#   Version: 8.0.0
#   Date: 2025-10-05
#   Description: Unified system for launching applications with automatic
#                window manager detection (Hyprland/GNOME/Generic)
#
#   Features:
#   - Automatic window manager detection (Hyprland, GNOME, generic Wayland/X11)
#   - Application startup verification with timeout (Hyprland)
#   - Startup script generation for all profiles
#   - Multi-browser support (Brave, Chrome)
#   - VPN bypass/secure mode support
#   - Terminal session management
#   - Config-free operation (no external config files needed)
#
#===============================================================================

#-------------------------------------------------------------------------------
# Configuration and Constants
#-------------------------------------------------------------------------------

readonly SCRIPT_NAME=$(basename "$0")
readonly VERSION="8.0.0"
# Snowfall düzenine göre start scriptleri burada tutuluyor
readonly SCRIPTS_DIR="$HOME/.nixosc/modules/home/scripts/start"
readonly LOG_DIR="$HOME/.logs/semsumo"
readonly LOG_FILE="$LOG_DIR/semsumo.log"
readonly STATE_DIR="${XDG_RUNTIME_DIR:-/tmp}/semsumo"
readonly DEFAULT_FINAL_WORKSPACE="2"
readonly DEFAULT_WAIT_TIME=1
readonly DEFAULT_APP_TIMEOUT=4
readonly DEFAULT_CHECK_INTERVAL=1

# Colors
if [[ -t 1 ]]; then
  readonly RED='\033[0;31m'
  readonly GREEN='\033[0;32m'
  readonly YELLOW='\033[1;33m'
  readonly BLUE='\033[0;34m'
  readonly PURPLE='\033[0;35m'
  readonly CYAN='\033[0;36m'
  readonly BOLD='\033[1m'
  readonly NC='\033[0m'
else
  readonly RED='' GREEN='' YELLOW='' BLUE='' PURPLE='' CYAN='' BOLD='' NC=''
fi

# Operation modes
MODE_GENERATE=false
MODE_LAUNCH=false
MODE_LIST=false
MODE_CLEAN=false
RUN_TERMINALS=false
RUN_BROWSER=false
RUN_APPS=false
SINGLE_PROFILE=""
DEBUG_MODE=false
DRY_RUN=false
WAIT_TIME=$DEFAULT_WAIT_TIME
FINAL_WORKSPACE=$DEFAULT_FINAL_WORKSPACE
BROWSER_TYPE="brave"
LAUNCH_ALL=false
LAUNCH_TYPE=""
BROWSER_ONLY=false
LAUNCH_DAILY=false
LAUNCH_DAILY_ALL=false
APP_TIMEOUT=$DEFAULT_APP_TIMEOUT
CHECK_INTERVAL=$DEFAULT_CHECK_INTERVAL
NOTIFY_ENABLED=true
LOG_BACKEND_READY=""

# Window Manager Detection
WM_TYPE=""

# Daily/Essential profiles list - UPDATED
declare -A DAILY_PROFILES=(
  ["kkenp"]="TERMINALS"               # Workspace 2
  ["brave-kenp"]="BRAVE_BROWSERS"     # Workspace 1
  ["brave-ai"]="BRAVE_BROWSERS"       # Workspace 3
  ["brave-compecta"]="BRAVE_BROWSERS" # Workspace 4
  ["webcord"]="APPS"                  # Workspace 5
  ["brave-youtube"]="BRAVE_BROWSERS"  # Workspace 7
  ["spotify"]="APPS"                  # Workspace 8
  ["ferdium"]="APPS"                  # Workspace 9
)

# Terminal Applications - UPDATED
declare -A TERMINALS=(
  ["kkenp"]="kitty|--class TmuxKenp -T Tmux --override background_opacity=1.0 -e tm|2|secure|1|false"
  ["mkenp"]="kitty|--class TmuxKenp -T Tmux --override background_opacity=1.0 -e tm|2|secure|1|false"
  ["wkenp"]="wezterm|start --class TmuxKenp -e tm|2|bypass|1|false"
  ["wezterm"]="wezterm|start --class wezterm|2|secure|1|false"
  ["kitty-single"]="kitty|--class kitty -T kitty --single-instance|2|secure|1|false"
  ["wezterm-rmpc"]="wezterm|start --class rmpc -e rmpc|0|secure|1|false"
)

# Browser Applications - Brave - UPDATED
declare -A BRAVE_BROWSERS=(
  ["brave-kenp"]="profile_brave|Kenp --separate --restore-last-session|1|secure|2|false"
  ["brave-ai"]="profile_brave|Ai --separate --restore-last-session|3|secure|2|false"
  ["brave-compecta"]="profile_brave|CompecTA --separate --restore-last-session|4|secure|2|false"
  ["brave-whats"]="profile_brave|Whats --separate --restore-last-session|9|secure|1|false"
  ["brave-exclude"]="profile_brave|Exclude --separate --restore-last-session|6|bypass|1|false"
  ["brave-youtube"]="profile_brave|--youtube --separate --class brave-youtube.com__-Default|7|secure|1|false"
  ["brave-tiktok"]="profile_brave|--tiktok --separate --class tiktok --title tiktok|6|secure|1|true"
  ["brave-spotify"]="profile_brave|--spotify --separate --class spotify --title spotify|8|secure|1|true"
  ["brave-discord"]="profile_brave|--discord --separate --class discord --title discord|5|secure|1|true"
  ["brave-whatsapp"]="profile_brave|--whatsapp --separate --class whatsapp --title whatsapp|9|secure|1|true"
)

# Browser Applications - Chrome
declare -A CHROME_BROWSERS=(
  ["chrome-kenp"]="profile_chrome|Kenp --class Kenp|1|secure|1|false"
  ["chrome-ai"]="profile_chrome|AI --class AI|3|secure|1|false"
  ["chrome-compecta"]="profile_chrome|CompecTA --class CompecTA|4|secure|1|false"
  ["chrome-whats"]="profile_chrome|Whats --class Whats|9|secure|1|false"
)

# Browser Applications - Firefox
declare -A FIREFOX_BROWSERS=(
  ["firefox-kenp"]="firefox|-P kenp --class Kenp --name Kenp --new-window --new-instance|1|secure|1|false"
  ["firefox-compecta"]="firefox|-P compecta --class Compecta --name Compecta --new-window --new-instance|4|secure|1|false"
  ["firefox-proxy"]="firefox|-P proxy --class Proxy --name Proxy --new-window --new-instance|6|bypass|1|false"
)

# Applications - UPDATED
declare -A APPS=(
  ["discord"]="discord|-m --class=discord --title=discord|5|secure|1|true"
  ["webcord"]="webcord|--class=WebCord --title=Webcord|5|secure|1|false"
  ["spotify"]="spotify|--class Spotify -T Spotify|8|bypass|1|false"
  ["mpv"]="mpv|--player-operation-mode=pseudo-gui --input-ipc-server=/tmp/mpvsocket|6|bypass|1|true"
  ["ferdium"]="ferdium||9|secure|1|false"
)

#-------------------------------------------------------------------------------
# Window Manager Detection
#-------------------------------------------------------------------------------

detect_window_manager() {
  if command -v hyprctl &>/dev/null && hyprctl version &>/dev/null; then
    WM_TYPE="hyprland"
    log "INFO" "DETECT" "Detected Hyprland window manager"
  elif command -v niri &>/dev/null && [[ "$XDG_CURRENT_DESKTOP" == "niri" ]]; then
    WM_TYPE="niri"
    log "INFO" "DETECT" "Detected Niri window manager"
  elif [[ "$XDG_CURRENT_DESKTOP" == *"GNOME"* ]] || command -v gnome-shell &>/dev/null; then
    WM_TYPE="gnome"
    log "INFO" "DETECT" "Detected GNOME desktop environment"
  elif [[ -n "$WAYLAND_DISPLAY" ]]; then
    WM_TYPE="wayland"
    log "INFO" "DETECT" "Detected generic Wayland session"
  else
    WM_TYPE="x11"
    log "INFO" "DETECT" "Detected X11 session"
  fi
}

#-------------------------------------------------------------------------------
# Helper Functions
#-------------------------------------------------------------------------------

init_log_backend() {
  if [[ -n "$LOG_BACKEND_READY" ]]; then
    [[ "$LOG_BACKEND_READY" == "true" ]]
    return
  fi

  if mkdir -p "$LOG_DIR" 2>/dev/null && touch "$LOG_FILE" 2>/dev/null; then
    LOG_BACKEND_READY="true"
  else
    LOG_BACKEND_READY="false"
  fi
}

replace_literal_token() {
  local file="$1"
  local token="$2"
  local value="$3"
  local content

  content=$(<"$file") || return 1
  content="${content//"$token"/$value}"
  printf '%s' "$content" >"$file"
}

is_non_negative_int() {
  [[ "$1" =~ ^[0-9]+$ ]]
}

is_positive_int() {
  [[ "$1" =~ ^[1-9][0-9]*$ ]]
}

parse_args_to_array() {
  local raw_args="$1"
  local -n out_ref="$2"
  out_ref=()

  if [[ -n "$raw_args" ]]; then
    read -r -a out_ref <<<"$raw_args"
  fi
}

run_command_with_vpn() {
  local vpn_mode="$1"
  local command_name="$2"
  shift 2
  local -a command_args=("$@")

  case "$vpn_mode" in
  bypass)
    if command -v mullvad >/dev/null 2>&1 && mullvad status 2>/dev/null | grep -q "Connected"; then
      if command -v mullvad-exclude >/dev/null 2>&1; then
        log "INFO" "LAUNCH" "Starting with VPN bypass"
        mullvad-exclude "$command_name" "${command_args[@]}" &
      else
        log "WARN" "LAUNCH" "mullvad-exclude not found"
        "$command_name" "${command_args[@]}" &
      fi
    else
      "$command_name" "${command_args[@]}" &
    fi
    ;;
  secure | *)
    if command -v mullvad >/dev/null 2>&1 && mullvad status 2>/dev/null | grep -q "Connected"; then
      log "INFO" "LAUNCH" "Starting with VPN protection"
    else
      log "WARN" "LAUNCH" "VPN not connected!"
    fi
    "$command_name" "${command_args[@]}" &
    ;;
  esac
}

record_pid_state() {
  local profile="$1"
  local pid="$2"
  local command_name="$3"

  mkdir -p "$STATE_DIR"
  printf '%s\n' "$pid" >"$STATE_DIR/$profile.pid"
  printf '%s\n' "$command_name" >"$STATE_DIR/$profile.cmd"
}

pid_matches_expected_command() {
  local pid="$1"
  local expected_command="$2"
  local cmdline

  [[ -n "$expected_command" ]] || return 1
  [[ -r "/proc/$pid/cmdline" ]] || return 1

  cmdline=$(tr '\0' ' ' </proc/"$pid"/cmdline 2>/dev/null || true)
  [[ -n "$cmdline" ]] || return 1

  [[ "$cmdline" == *"$expected_command"* ]]
}

log() {
  local level="$1"
  local module="${2:-MAIN}"
  local message="$3"
  local notify="${4:-false}"
  local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
  local color=""

  case "$level" in
  "INFO") color=$BLUE ;;
  "SUCCESS") color=$GREEN ;;
  "WARN") color=$YELLOW ;;
  "ERROR") color=$RED ;;
  "DEBUG") color=$PURPLE ;;
  esac

  echo -e "${color}${BOLD}[$level]${NC} ${PURPLE}[$module]${NC} $message"

  init_log_backend || true
  if [[ "$LOG_BACKEND_READY" == "true" ]]; then
    if ! printf '[%s] [%s] [%s] %s\n' "$timestamp" "$level" "$module" "$message" >>"$LOG_FILE" 2>/dev/null; then
      LOG_BACKEND_READY="false"
    fi
  fi

  if [[ "$notify" == "true" && "$NOTIFY_ENABLED" == "true" && -n "${DBUS_SESSION_BUS_ADDRESS:-}" && -x "$(command -v notify-send)" ]]; then
    notify-send -a "$SCRIPT_NAME" "$module: $message" >/dev/null 2>&1 || true
  fi

  return 0
}

setup_external_monitor() {
  if [[ "$DRY_RUN" == "true" ]]; then
    return 0
  fi

  if [[ "$WM_TYPE" == "gnome" ]] && command -v xrandr >/dev/null 2>&1; then
    local external_monitor=$(xrandr --query | grep " connected" | grep -v "eDP" | head -1 | awk '{print $1}')
    if [[ -n "$external_monitor" ]]; then
      log "INFO" "DISPLAY" "Setting external monitor $external_monitor as primary..."
      xrandr --output "$external_monitor" --primary
      sleep 1
    fi
  fi
}

switch_workspace() {
  local workspace="$1"

  if [[ -z "$workspace" || "$workspace" == "0" || "$DRY_RUN" == "true" ]]; then
    return 0
  fi

  case "$WM_TYPE" in
  hyprland)
    if command -v hyprctl &>/dev/null; then
      local current=$(hyprctl activeworkspace -j | grep -o '"id": [0-9]*' | grep -o '[0-9]*' || echo "")
      if [[ "$current" != "$workspace" ]]; then
        log "INFO" "WORKSPACE" "Switching to workspace $workspace (Hyprland)"
        hyprctl dispatch workspace "$workspace"
        sleep 1
      fi
    fi
    ;;
  niri)
    if command -v niri-osc >/dev/null 2>&1; then
      log "INFO" "WORKSPACE" "Switching to workspace $workspace (Niri via niri-osc)"
      niri-osc set flow -wn "$workspace"
      sleep 1
    elif command -v niri >/dev/null 2>&1; then
      log "INFO" "WORKSPACE" "Switching to workspace $workspace (Niri)"
      niri msg action focus-workspace "$workspace"
      sleep 1
    fi
    ;;
  gnome)
    local target_workspace=$((workspace - 1))
    # Wayland'da wmctrl çalışmadığı için önce gdbus (org.gnome.Shell.Eval) deneriz.
    if command -v gdbus >/dev/null 2>&1; then
      log "INFO" "WORKSPACE" "Switching to workspace $workspace (GNOME via gdbus)"
      gdbus call --session \
        --dest org.gnome.Shell \
        --object-path /org/gnome/Shell \
        --method org.gnome.Shell.Eval \
        "global.workspace_manager.get_workspace_by_index($target_workspace).activate(global.get_current_time());" \
        >/dev/null 2>&1 || true
      sleep 1
    elif command -v wmctrl >/dev/null 2>&1; then
      log "INFO" "WORKSPACE" "Switching to workspace $workspace (GNOME via wmctrl)"
      wmctrl -s "$target_workspace"
      sleep 1
    else
      log "WARN" "WORKSPACE" "GNOME workspace switching needs gdbus (preferred) or wmctrl"
    fi
    ;;
  *)
    if command -v wmctrl >/dev/null 2>&1; then
      local target_workspace=$((workspace - 1))
      log "INFO" "WORKSPACE" "Switching to workspace $workspace (wmctrl)"
      wmctrl -s "$target_workspace"
      sleep 1
    fi
    ;;
  esac
}

focus_tmuxkenp_best_effort() {
  if [[ "$DRY_RUN" == "true" ]]; then
    return 0
  fi

  case "$WM_TYPE" in
  hyprland)
    if command -v hyprctl >/dev/null 2>&1; then
      # Önce class ile dene, olmazsa title ile yakala.
      hyprctl dispatch focuswindow "class:^TmuxKenp$" >/dev/null 2>&1 || \
        hyprctl dispatch focuswindow "title:^Tmux$" >/dev/null 2>&1 || true
    fi
    ;;
  niri|gnome|*)
    # Niri'de workspace 2'ye geçmek genelde yeterli (aktif pencere otomatik odaklanır).
    true
    ;;
  esac
}

is_app_running() {
  local profile="$1"
  local search_pattern="${2:-}"
  local clients_json=""

  # For managed profiles, prefer window checks on Hyprland.
  if [[ "$WM_TYPE" == "hyprland" ]] && command -v hyprctl &>/dev/null && command -v jq &>/dev/null; then
    clients_json=$(hyprctl clients -j 2>/dev/null || true)

    if [[ -n "$clients_json" ]]; then
    case "$profile" in
    kkenp | mkenp)
      jq -e '.[] | select((.class // "") == "TmuxKenp")' <<<"$clients_json" >/dev/null 2>&1 && return 0
      return 1
      ;;
    wkenp)
      jq -e '.[] | select((.class // "") == "TmuxKenp" or (.class // "") == "wezterm")' <<<"$clients_json" >/dev/null 2>&1 && return 0
      return 1
      ;;
    kitty-single)
      jq -e '.[] | select((.class // "") == "kitty")' <<<"$clients_json" >/dev/null 2>&1 && return 0
      return 1
      ;;
    wezterm)
      jq -e '.[] | select((.class // "") == "wezterm" or (.class // "") == "org.wezfurlong.wezterm")' <<<"$clients_json" >/dev/null 2>&1 && return 0
      return 1
      ;;
    wezterm-rmpc)
      jq -e '.[] | select((.class // "") == "rmpc")' <<<"$clients_json" >/dev/null 2>&1 && return 0
      return 1
      ;;
    brave-kenp)
      jq -e '.[] | select((.class // "") == "Kenp" or (.initialTitle // "") == "Kenp Browser")' <<<"$clients_json" >/dev/null 2>&1 && return 0
      return 1
      ;;
    brave-ai)
      jq -e '.[] | select((.class // "") == "Ai" or (.initialTitle // "") == "Ai Browser")' <<<"$clients_json" >/dev/null 2>&1 && return 0
      return 1
      ;;
    brave-compecta)
      jq -e '.[] | select((.class // "") == "CompecTA" or (.initialTitle // "") == "CompecTA Browser")' <<<"$clients_json" >/dev/null 2>&1 && return 0
      return 1
      ;;
    brave-whats)
      jq -e '.[] | select((.class // "") == "Whats" or (.initialTitle // "") == "Whats Browser")' <<<"$clients_json" >/dev/null 2>&1 && return 0
      return 1
      ;;
    brave-exclude)
      jq -e '.[] | select((.class // "") == "Exclude" or (.initialTitle // "") == "Exclude Browser")' <<<"$clients_json" >/dev/null 2>&1 && return 0
      return 1
      ;;
    brave-youtube)
      jq -e '.[] | select((.class // "") | test("brave-youtube"; "i"))' <<<"$clients_json" >/dev/null 2>&1 && return 0
      return 1
      ;;
    brave-tiktok)
      jq -e '.[] | select((.class // "") | test("brave-tiktok"; "i"))' <<<"$clients_json" >/dev/null 2>&1 && return 0
      return 1
      ;;
    brave-spotify)
      jq -e '.[] | select((.class // "") | test("brave-spotify"; "i"))' <<<"$clients_json" >/dev/null 2>&1 && return 0
      return 1
      ;;
    brave-discord)
      jq -e '.[] | select((.class // "") | test("brave-discord"; "i"))' <<<"$clients_json" >/dev/null 2>&1 && return 0
      return 1
      ;;
    brave-whatsapp)
      jq -e '.[] | select((.class // "") | test("brave-whatsapp"; "i"))' <<<"$clients_json" >/dev/null 2>&1 && return 0
      return 1
      ;;
    firefox-kenp)
      jq -e '.[] | select((.class // "") | test("kenp"; "i"))' <<<"$clients_json" >/dev/null 2>&1 && return 0
      return 1
      ;;
    firefox-compecta)
      jq -e '.[] | select((.class // "") | test("compecta"; "i"))' <<<"$clients_json" >/dev/null 2>&1 && return 0
      return 1
      ;;
    firefox-proxy)
      jq -e '.[] | select((.class // "") | test("proxy"; "i"))' <<<"$clients_json" >/dev/null 2>&1 && return 0
      return 1
      ;;
    chrome-*)
      local profile_class="${profile#chrome-}"
      jq -e --arg profile_class "$profile_class" \
        '.[] | select((.class // "") | test("chrome|google-chrome"; "i")) | select((.title // "") | test($profile_class; "i"))' \
        <<<"$clients_json" >/dev/null 2>&1 && return 0
      return 1
      ;;
    esac
    fi
  fi

  # Fallback to process check
  if [[ -n "$search_pattern" ]]; then
    pgrep -f "$search_pattern" &>/dev/null
  else
    pgrep -f "$profile" &>/dev/null
  fi
}

check_window_on_workspace() {
  local workspace="$1"
  local class_pattern="$2"
  local timeout="${3:-$APP_TIMEOUT}"
  local interval="${4:-$CHECK_INTERVAL}"

  if [[ "$DRY_RUN" == "true" ]]; then
    return 0
  fi

  # Only Hyprland has window verification
  if [[ "$WM_TYPE" != "hyprland" ]]; then
    sleep "$WAIT_TIME"
    return 0
  fi

  if ! command -v hyprctl &>/dev/null || ! command -v jq &>/dev/null; then
    log "WARN" "VERIFY" "hyprctl or jq not available, skipping window verification"
    sleep "$WAIT_TIME"
    return 0
  fi

  local elapsed=0
  log "INFO" "VERIFY" "Waiting for window (class: $class_pattern) on workspace $workspace (timeout: ${timeout}s)"

  while [[ $elapsed -lt $timeout ]]; do
    if hyprctl clients -j 2>/dev/null | jq -e ".[] | select(.workspace.id == $workspace and (.class | test(\"$class_pattern\"; \"i\")))" >/dev/null 2>&1; then
      log "SUCCESS" "VERIFY" "Window found on workspace $workspace after ${elapsed}s"
      return 0
    fi

    sleep "$interval"
    ((elapsed += interval))

    if ((elapsed % 3 == 0)); then
      log "DEBUG" "VERIFY" "Still waiting... (${elapsed}/${timeout}s)"
    fi
  done

  log "WARN" "VERIFY" "Timeout waiting for window on workspace $workspace after ${timeout}s"
  return 1
}

get_class_pattern() {
  local profile="$1"
  local args="$2"

  if [[ "$args" =~ --class[=\ ]([^\ ]+) ]]; then
    echo "${BASH_REMATCH[1]}"
    return 0
  fi

  if [[ "$args" =~ (-T|--title)[=\ ]([^\ ]+) ]]; then
    echo "${BASH_REMATCH[2]}"
    return 0
  fi

  case "$profile" in
  brave-*)
    # If a profile name (first arg) is provided and not a flag, use it as class
    local first_arg="${args%% *}"
    if [[ -n "$first_arg" && "$first_arg" != -* ]]; then
      echo "$first_arg"
    else
      echo "brave|brave-browser"
    fi
    ;;
  chrome-*) echo "chrome|Google-chrome" ;;
  firefox-*)
    local profile_class="${profile#firefox-}"
    echo "${profile_class^}"
    ;;
  discord) echo "discord|Discord" ;;
  spotify) echo "spotify|Spotify" ;;
  ferdium) echo "ferdium|Ferdium" ;;
  kitty* | kkenp | mkenp) echo "kitty" ;;
  wezterm* | wkenp) echo "wezterm|org.wezfurlong.wezterm" ;;
  *) echo "$profile" ;;
  esac
}

make_fullscreen() {
  if [[ "$DRY_RUN" == "true" ]]; then
    return 0
  fi

  case "$WM_TYPE" in
  hyprland)
    if command -v hyprctl &>/dev/null; then
      log "INFO" "FULLSCREEN" "Making window fullscreen (Hyprland)"
      sleep 1
      hyprctl dispatch fullscreen 1
      sleep 1
    fi
    ;;
  niri)
    if command -v niri >/dev/null 2>&1; then
      log "INFO" "FULLSCREEN" "Making window fullscreen (Niri)"
      sleep 1
      niri msg action fullscreen-window
      sleep 1
    fi
    ;;
  gnome)
    if command -v gdbus >/dev/null 2>&1; then
      log "INFO" "FULLSCREEN" "Making window fullscreen (GNOME)"
      sleep 1
      gdbus call --session --dest org.gnome.Shell --object-path /org/gnome/Shell --method org.gnome.Shell.Eval "global.display.get_focus_window().make_fullscreen()" >/dev/null 2>&1
      sleep 1
    elif command -v wmctrl >/dev/null 2>&1; then
      log "INFO" "FULLSCREEN" "Making window fullscreen (wmctrl)"
      sleep 1
      local window_id=$(wmctrl -l | tail -1 | awk '{print $1}')
      if [[ -n "$window_id" ]]; then
        wmctrl -i -r "$window_id" -b add,fullscreen
      fi
      sleep 1
    fi
    ;;
  *)
    log "WARN" "FULLSCREEN" "Fullscreen not supported for $WM_TYPE - press F11 manually"
    ;;
  esac
}

parse_config() {
  local config="$1"
  local field="$2"
  echo "$config" | cut -d'|' -f"$field"
}

get_browser_profiles() {
  case "$BROWSER_TYPE" in
  "brave") echo "BRAVE_BROWSERS" ;;
  "chrome") echo "CHROME_BROWSERS" ;;
  "firefox") echo "FIREFOX_BROWSERS" ;;
  *)
    log "ERROR" "BROWSER" "Invalid browser type: $BROWSER_TYPE"
    return 1
    ;;
  esac
}

#-------------------------------------------------------------------------------
# Script Generation Functions
#-------------------------------------------------------------------------------

generate_script() {
  local profile="$1"
  local config="$2"
  local script_path="$SCRIPTS_DIR/start-${profile}.sh"

  local cmd=$(parse_config "$config" 1)
  local args=$(parse_config "$config" 2)
  local workspace=$(parse_config "$config" 3)
  local vpn=$(parse_config "$config" 4)
  local wait=$(parse_config "$config" 5)
  local fullscreen=$(parse_config "$config" 6)

  [[ -z "$workspace" ]] && workspace="0"
  [[ -z "$vpn" ]] && vpn="secure"
  [[ -z "$wait" ]] && wait="1"
  [[ -z "$fullscreen" ]] && fullscreen="false"

  local class_pattern=$(get_class_pattern "$profile" "$args")

  mkdir -p "$SCRIPTS_DIR"

  cat >"$script_path" <<'SCRIPT_HEREDOC_START'
#!/usr/bin/env bash
# Profile: PROFILE_NAME
# Generated by Semsumo v8.0.0 (Unified Edition)
set -e

readonly APP_TIMEOUT=APP_TIMEOUT_VALUE
readonly CHECK_INTERVAL=CHECK_INTERVAL_VALUE
readonly WORKSPACE=WORKSPACE_VALUE
readonly VPN_MODE="VPN_VALUE"
readonly FULLSCREEN=FULLSCREEN_VALUE
readonly WAIT_TIME=WAIT_VALUE
readonly COMMAND="COMMAND_VALUE"
readonly ARGS_STR="ARGS_VALUE"
readonly STATE_DIR="STATE_DIR_VALUE"

# Detect window manager
if command -v hyprctl &>/dev/null && hyprctl version &>/dev/null; then
    WM_TYPE="hyprland"
elif command -v niri &>/dev/null && [[ "$XDG_CURRENT_DESKTOP" == "niri" ]]; then
    WM_TYPE="niri"
elif [[ "$XDG_CURRENT_DESKTOP" == *"GNOME"* ]] || command -v gnome-shell &>/dev/null; then
    WM_TYPE="gnome"
else
    WM_TYPE="generic"
fi

echo "Initializing PROFILE_NAME on $WM_TYPE..."

APP_ARGS=()
if [[ -n "$ARGS_STR" ]]; then
    read -r -a APP_ARGS <<<"$ARGS_STR"
fi

# External monitor setup (GNOME only)
if [[ "$WM_TYPE" == "gnome" ]] && command -v xrandr >/dev/null 2>&1; then
    EXTERNAL_MONITOR=$(xrandr --query | grep " connected" | grep -v "eDP" | head -1 | awk '{print $1}')
    if [[ -n "$EXTERNAL_MONITOR" ]]; then
        echo "Setting $EXTERNAL_MONITOR as primary..."
        xrandr --output "$EXTERNAL_MONITOR" --primary
        sleep 1
    fi
fi

# Switch to workspace
if [[ "$WORKSPACE" != "0" ]]; then
    case "$WM_TYPE" in
    hyprland)
        if command -v hyprctl >/dev/null 2>&1; then
            CURRENT=$(hyprctl activeworkspace -j | grep -o '"id": [0-9]*' | grep -o '[0-9]*' || echo "")
            if [[ "$CURRENT" != "$WORKSPACE" ]]; then
                echo "Switching to workspace $WORKSPACE..."
                hyprctl dispatch workspace "$WORKSPACE"
                sleep 1
            fi
        fi
        ;;
    niri)
        if command -v niri-osc >/dev/null 2>&1; then
            echo "Switching to workspace $WORKSPACE..."
            niri-osc set flow -wn "$WORKSPACE"
            sleep 1
        elif command -v niri >/dev/null 2>&1; then
            echo "Switching to workspace $WORKSPACE..."
            niri msg action focus-workspace "$WORKSPACE"
            sleep 1
        fi
        ;;
    gnome|*)
        if command -v wmctrl >/dev/null 2>&1; then
            TARGET=$((WORKSPACE - 1))
            echo "Switching to workspace $WORKSPACE..."
            wmctrl -s "$TARGET"
            sleep 1
        fi
        ;;
    esac
fi

echo "Starting application..."
echo "COMMAND: $COMMAND ${APP_ARGS[*]}"
echo "VPN MODE: $VPN_MODE"

# Start application with VPN mode
case "$VPN_MODE" in
    bypass)
        if command -v mullvad >/dev/null 2>&1 && mullvad status 2>/dev/null | grep -q "Connected"; then
            if command -v mullvad-exclude >/dev/null 2>&1; then
                echo "Starting with VPN bypass"
                mullvad-exclude "$COMMAND" "${APP_ARGS[@]}" &
            else
                echo "WARNING: mullvad-exclude not found"
                "$COMMAND" "${APP_ARGS[@]}" &
            fi
        else
            echo "VPN not connected"
            "$COMMAND" "${APP_ARGS[@]}" &
        fi
        ;;
    secure|*)
        if command -v mullvad >/dev/null 2>&1 && mullvad status 2>/dev/null | grep -q "Connected"; then
            echo "Starting with VPN protection"
        else
            echo "WARNING: VPN not connected!"
        fi
        "$COMMAND" "${APP_ARGS[@]}" &
        ;;
esac

APP_PID=$!
mkdir -p "$STATE_DIR"
echo "$APP_PID" > "$STATE_DIR/PROFILE_NAME.pid"
echo "$COMMAND" > "$STATE_DIR/PROFILE_NAME.cmd"
echo "Application started (PID: $APP_PID)"

# Window verification (Hyprland only)
if [[ "$WORKSPACE" != "0" && "$WM_TYPE" == "hyprland" ]] && command -v hyprctl >/dev/null 2>&1 && command -v jq >/dev/null 2>&1; then
    echo "Verifying window on workspace $WORKSPACE..."
    ELAPSED=0
    CLASS_PATTERN="CLASS_PATTERN_VALUE"
    
    while [[ $ELAPSED -lt $APP_TIMEOUT ]]; do
        if hyprctl clients -j 2>/dev/null | jq -e ".[] | select(.workspace.id == $WORKSPACE and (.class | test(\"$CLASS_PATTERN\"; \"i\")))" >/dev/null 2>&1; then
            echo "Window verified after ${ELAPSED}s"
            break
        fi
        sleep $CHECK_INTERVAL
        ((ELAPSED += CHECK_INTERVAL))
        if ((ELAPSED % 3 == 0)); then
            echo "Waiting... (${ELAPSED}/${APP_TIMEOUT}s)"
        fi
    done
    
    [[ $ELAPSED -ge $APP_TIMEOUT ]] && echo "WARNING: Timeout after ${APP_TIMEOUT}s"
else
    sleep $WAIT_TIME
fi

# Make fullscreen if needed
if [[ "$FULLSCREEN" == "true" ]]; then
    sleep $WAIT_TIME
    case "$WM_TYPE" in
    hyprland)
        command -v hyprctl >/dev/null 2>&1 && hyprctl dispatch fullscreen 1
        ;;
    niri)
        command -v niri >/dev/null 2>&1 && niri msg action fullscreen-window
        ;;
    gnome)
        if command -v gdbus >/dev/null 2>&1; then
            gdbus call --session --dest org.gnome.Shell --object-path /org/gnome/Shell --method org.gnome.Shell.Eval "global.display.get_focus_window().make_fullscreen()" >/dev/null 2>&1
        elif command -v wmctrl >/dev/null 2>&1; then
            WID=$(wmctrl -l | tail -1 | awk '{print $1}')
            [[ -n "$WID" ]] && wmctrl -i -r "$WID" -b add,fullscreen
        fi
        ;;
    esac
fi

echo "PROFILE_NAME initialization complete"
exit 0
SCRIPT_HEREDOC_START

  # Replace placeholders safely (literal token replacement).
  replace_literal_token "$script_path" "PROFILE_NAME" "$profile"
  replace_literal_token "$script_path" "APP_TIMEOUT_VALUE" "$APP_TIMEOUT"
  replace_literal_token "$script_path" "CHECK_INTERVAL_VALUE" "$CHECK_INTERVAL"
  replace_literal_token "$script_path" "WORKSPACE_VALUE" "$workspace"
  replace_literal_token "$script_path" "VPN_VALUE" "$vpn"
  replace_literal_token "$script_path" "FULLSCREEN_VALUE" "$fullscreen"
  replace_literal_token "$script_path" "WAIT_VALUE" "$wait"
  replace_literal_token "$script_path" "COMMAND_VALUE" "$cmd"
  replace_literal_token "$script_path" "ARGS_VALUE" "$args"
  replace_literal_token "$script_path" "CLASS_PATTERN_VALUE" "$class_pattern"
  replace_literal_token "$script_path" "STATE_DIR_VALUE" "$STATE_DIR"

  chmod +x "$script_path"
  log "SUCCESS" "GENERATE" "Generated: start-${profile}.sh"
}

generate_all_scripts() {
  log "INFO" "GENERATE" "Generating scripts for ALL profiles..."
  local count=0

  for profile in "${!TERMINALS[@]}"; do
    generate_script "$profile" "${TERMINALS[$profile]}"
    ((count++))
  done

  for profile in "${!BRAVE_BROWSERS[@]}"; do
    generate_script "$profile" "${BRAVE_BROWSERS[$profile]}"
    ((count++))
  done

  for profile in "${!FIREFOX_BROWSERS[@]}"; do
    generate_script "$profile" "${FIREFOX_BROWSERS[$profile]}"
    ((count++))
  done

  for profile in "${!CHROME_BROWSERS[@]}"; do
    generate_script "$profile" "${CHROME_BROWSERS[$profile]}"
    ((count++))
  done

  for profile in "${!APPS[@]}"; do
    generate_script "$profile" "${APPS[$profile]}"
    ((count++))
  done

  log "SUCCESS" "GENERATE" "Generated $count unified scripts in $SCRIPTS_DIR"
}

generate_daily_scripts() {
  log "INFO" "GENERATE" "Generating daily/essential profiles..."
  local count=0

  for profile in "${!DAILY_PROFILES[@]}"; do
    local profile_type="${DAILY_PROFILES[$profile]}"
    local config=""

    case "$profile_type" in
    "TERMINALS") config="${TERMINALS[$profile]}" ;;
    "BRAVE_BROWSERS") config="${BRAVE_BROWSERS[$profile]}" ;;
    "APPS") config="${APPS[$profile]}" ;;
    esac

    if [[ -n "$config" ]]; then
      generate_script "$profile" "$config"
      ((count++))
    fi
  done

  log "SUCCESS" "GENERATE" "Generated $count daily scripts"
}

clean_scripts() {
  log "INFO" "GENERATE" "Removing all generated scripts..."
  if [[ -d "$SCRIPTS_DIR" ]]; then
    rm -f "$SCRIPTS_DIR"/start-*.sh
    log "SUCCESS" "GENERATE" "All scripts removed"
  fi
}

#-------------------------------------------------------------------------------
# Launch Functions
#-------------------------------------------------------------------------------

# Window verification - ENHANCED
ensure_windows_on_correct_workspace() {
  if [[ "$DRY_RUN" == "true" ]]; then
    return 0
  fi

  if [[ "$WM_TYPE" != "hyprland" ]]; then
    return 0
  fi

  if ! command -v hyprctl &>/dev/null || ! command -v jq &>/dev/null; then
    log "WARN" "WINDOW" "hyprctl or jq not available, skipping window workspace verification"
    return 0
  fi

  log "INFO" "WINDOW" "Ensuring all windows are on correct workspaces..."

  # Define window to workspace mappings - UPDATED based on your layout
  declare -A WINDOW_WORKSPACE_MAP=(
    ["TmuxKenp"]="2"                    # Terminal
    ["Kenp"]="1"                        # Main browser (multiple windows possible)
    ["discord|Discord|WebCord"]="5"     # Discord/WebCord
    ["brave-youtube.com__-Default"]="7" # YouTube
    ["spotify|Spotify"]="8"             # Spotify
    ["ferdium|Ferdium"]="9"             # Ferdium
  )

  local moved_count=0

  for class_pattern in "${!WINDOW_WORKSPACE_MAP[@]}"; do
    local target_workspace="${WINDOW_WORKSPACE_MAP[$class_pattern]}"

    # Check if window exists and move if needed
    if hyprctl clients -j 2>/dev/null | jq -e ".[] | select(.class | test(\"^($class_pattern)$\"; \"i\"))" >/dev/null 2>&1; then
      # Only move if window is not already on target workspace
      local current_workspace=$(hyprctl clients -j 2>/dev/null | jq -r ".[] | select(.class | test(\"^($class_pattern)$\"; \"i\")) | .workspace.id" | head -1)

      if [[ "$current_workspace" != "$target_workspace" ]]; then
        log "INFO" "WINDOW" "Moving windows matching '$class_pattern' from workspace $current_workspace to $target_workspace"
        hyprctl dispatch movetoworkspacesilent "${target_workspace},class:^(${class_pattern})$" >/dev/null 2>&1
        ((moved_count++))
        sleep 0.5
      else
        log "DEBUG" "WINDOW" "Window '$class_pattern' already on correct workspace $target_workspace"
      fi
    fi
  done

  if [[ $moved_count -gt 0 ]]; then
    log "SUCCESS" "WINDOW" "Moved $moved_count window type(s) to correct workspaces"
  else
    log "INFO" "WINDOW" "All windows already on correct workspaces"
  fi
}

launch_application() {
  local profile="$1"
  local config="$2"
  local type="${3:-app}"

  local cmd=$(parse_config "$config" 1)
  local args=$(parse_config "$config" 2)
  local workspace=$(parse_config "$config" 3)
  local vpn=$(parse_config "$config" 4)
  local wait=$(parse_config "$config" 5)
  local fullscreen=$(parse_config "$config" 6)
  local -a cmd_args=()

  [[ -z "$workspace" ]] && workspace="0"
  [[ -z "$vpn" ]] && vpn="secure"
  [[ -z "$wait" ]] && wait="1"
  [[ -z "$fullscreen" ]] && fullscreen="false"

  if is_app_running "$profile"; then
    log "WARN" "LAUNCH" "$profile is already running"
    return 0
  fi

  setup_external_monitor
  switch_workspace "$workspace"
  log "INFO" "LAUNCH" "Starting $profile ($type, $WM_TYPE, workspace: $workspace)"
  parse_args_to_array "$args" cmd_args

  if [[ "$DRY_RUN" == "true" ]]; then
    log "DEBUG" "LAUNCH" "Dry run: would start $profile"
    return 0
  fi

  run_command_with_vpn "$vpn" "$cmd" "${cmd_args[@]}"

  local app_pid=$!
  record_pid_state "$profile" "$app_pid" "$cmd"

  if [[ "$workspace" != "0" ]]; then
    local class_pattern=$(get_class_pattern "$profile" "$args")
    check_window_on_workspace "$workspace" "$class_pattern" "$APP_TIMEOUT" "$CHECK_INTERVAL"
  else
    sleep "$wait"
  fi

  [[ "$fullscreen" == "true" ]] && make_fullscreen

  log "SUCCESS" "LAUNCH" "$profile started (PID: $app_pid)"
}

launch_application_background() {
  local profile="$1"
  local config="$2"
  local type="${3:-app}"

  local cmd=$(parse_config "$config" 1)
  local args=$(parse_config "$config" 2)
  local workspace=$(parse_config "$config" 3)
  local vpn=$(parse_config "$config" 4)
  local -a cmd_args=()

  [[ -z "$workspace" ]] && workspace="0"
  [[ -z "$vpn" ]] && vpn="secure"

  if is_app_running "$profile"; then
    log "WARN" "LAUNCH" "$profile is already running"
    return 0
  fi

  log "INFO" "LAUNCH" "Starting $profile ($type, $WM_TYPE, workspace: $workspace, mode: concurrent)"
  parse_args_to_array "$args" cmd_args

  if [[ "$DRY_RUN" == "true" ]]; then
    log "DEBUG" "LAUNCH" "Dry run: would start $profile"
    return 0
  fi

  run_command_with_vpn "$vpn" "$cmd" "${cmd_args[@]}"

  local app_pid=$!
  record_pid_state "$profile" "$app_pid" "$cmd"

  log "SUCCESS" "LAUNCH" "$profile started (PID: $app_pid)"
}

launch_profile() {
  local profile="$1"

  if [[ -v TERMINALS["$profile"] ]]; then
    launch_application "$profile" "${TERMINALS[$profile]}" "terminal"
  elif [[ -v BRAVE_BROWSERS["$profile"] && "$BROWSER_TYPE" == "brave" ]]; then
    launch_application "$profile" "${BRAVE_BROWSERS[$profile]}" "brave"
  elif [[ -v FIREFOX_BROWSERS["$profile"] && "$BROWSER_TYPE" == "firefox" ]]; then
    launch_application "$profile" "${FIREFOX_BROWSERS[$profile]}" "firefox"
  elif [[ -v CHROME_BROWSERS["$profile"] && "$BROWSER_TYPE" == "chrome" ]]; then
    launch_application "$profile" "${CHROME_BROWSERS[$profile]}" "chrome"
  elif [[ -v APPS["$profile"] ]]; then
    launch_application "$profile" "${APPS[$profile]}" "app"
  else
    log "ERROR" "LAUNCH" "Profile not found: $profile"
    return 1
  fi
}

# Launch order for daily profiles - OPTIMIZED
# This ensures applications start in the correct order to appear on their designated workspaces
launch_daily_profiles() {
  log "INFO" "LAUNCH" "Starting daily/essential profiles on $WM_TYPE..."

  # Launch in optimized order:
  # 1. Terminals first (workspace 2 - default on primary monitor)
  # 2. Main browser (workspace 1)
  # 3. AI browser (workspace 3)
  # 4. Work browser (workspace 4)
  # 5. WebCord (workspace 5)
  # 6. YouTube (workspace 7 - default on secondary monitor)
  # 7. Spotify (workspace 8)
  # 8. Ferdium/WhatsApp (workspace 9)

  local daily_order=(
    "kkenp"          # WS 2: Terminal
    "brave-kenp"     # WS 1: Main browser
    "brave-ai"       # WS 3: AI workspace
    "brave-compecta" # WS 4: Work
    "webcord"        # WS 5: WebCord
    "brave-youtube"  # WS 7: YouTube
    "spotify"        # WS 8: Spotify
    "ferdium"        # WS 9: WhatsApp/Ferdium
  )

  if [[ "$LAUNCH_DAILY_ALL" == "true" ]]; then
    log "INFO" "LAUNCH" "Launching daily profiles concurrently (--concurrent)"
    setup_external_monitor

    for profile in "${daily_order[@]}"; do
      if [[ -v DAILY_PROFILES["$profile"] ]]; then
        local profile_type="${DAILY_PROFILES[$profile]}"
        local config=""

        case "$profile_type" in
        "TERMINALS") config="${TERMINALS[$profile]}" ;;
        "BRAVE_BROWSERS") config="${BRAVE_BROWSERS[$profile]}" ;;
        "APPS") config="${APPS[$profile]}" ;;
        esac

        if [[ -n "$config" ]]; then
          case "$profile_type" in
          "TERMINALS") launch_application_background "$profile" "$config" "terminal" ;;
          "BRAVE_BROWSERS") launch_application_background "$profile" "$config" "brave" ;;
          "APPS") launch_application_background "$profile" "$config" "app" ;;
          esac
        fi
      fi
    done

    if [[ "$WM_TYPE" == "hyprland" ]]; then
      log "INFO" "WINDOW" "Verifying window positions..."
      sleep 2
      ensure_windows_on_correct_workspace
    fi

    log "INFO" "WORKSPACE" "Switching to default workspace 2"
    switch_workspace "2"
    focus_tmuxkenp_best_effort

    log "SUCCESS" "LAUNCH" "Daily profiles launched successfully"
    return 0
  fi

  for profile in "${daily_order[@]}"; do
    if [[ -v DAILY_PROFILES["$profile"] ]]; then
      local profile_type="${DAILY_PROFILES[$profile]}"
      local config=""

      case "$profile_type" in
      "TERMINALS")
        config="${TERMINALS[$profile]}"
        launch_application "$profile" "$config" "terminal"
        ;;
      "BRAVE_BROWSERS")
        config="${BRAVE_BROWSERS[$profile]}"
        launch_application "$profile" "$config" "brave"
        ;;
      "APPS")
        config="${APPS[$profile]}"
        launch_application "$profile" "$config" "app"
        ;;
      esac

      # Small delay between launches to ensure proper workspace assignment
      sleep 0.5
    fi
  done

  # Ensure all windows are on correct workspaces (Hyprland specific)
  if [[ "$WM_TYPE" == "hyprland" ]]; then
    log "INFO" "WINDOW" "Verifying window positions..."
    sleep 2
    ensure_windows_on_correct_workspace
  fi

  # Switch to default workspace (2 - Terminal on primary monitor)
  log "INFO" "WORKSPACE" "Switching to default workspace 2"
  switch_workspace "2"
  focus_tmuxkenp_best_effort

  log "SUCCESS" "LAUNCH" "Daily profiles launched successfully"
}

#-------------------------------------------------------------------------------
# Nix Expression Generator
#-------------------------------------------------------------------------------

generate_nix_expressions() {
  log "INFO" "NIX-GEN" "Generating Nix expressions for script directories..."

  declare -A NIX_DIRECTORIES=(
    ["bin"]="$HOME/.nixosc/modules/home/scripts/bin"
    ["start"]="$HOME/.nixosc/modules/home/scripts/start"
  )

  local total_generated=0

  for dir_name in "${!NIX_DIRECTORIES[@]}"; do
    local script_dir="${NIX_DIRECTORIES[$dir_name]}"
    local output_file="$HOME/.nixosc/modules/home/scripts/${dir_name}.nix"

    log "INFO" "NIX-GEN" "Processing directory: $dir_name"

    # Header
    cat >"$output_file" <<'EOF'
{ pkgs, ... }:
let
EOF

    local script_count=0

    # Process scripts
    for script in "$script_dir"/*.sh "$script_dir"/t[1-9] "$script_dir"/tm; do
      [[ -f "$script" ]] || continue

      local filename=$(basename "$script")
      [[ $filename == _* ]] && continue

      local varname="${filename%.sh}"
      varname="${varname// /-}"
      varname="${varname//./-}"

      cat >>"$output_file" <<EOF
  ${varname} = pkgs.writeShellScriptBin "${varname}" (
    builtins.readFile ./${dir_name}/${filename}
  );
EOF
      ((script_count++))
    done

    # Footer
    cat >>"$output_file" <<'EOF'
in {
  home.packages = with pkgs; [
EOF

    # Package list
    for script in "$script_dir"/*.sh "$script_dir"/t[1-9] "$script_dir"/tm; do
      [[ -f "$script" ]] || continue

      local filename=$(basename "$script")
      [[ $filename == _* ]] && continue

      local varname="${filename%.sh}"
      varname="${varname// /-}"
      varname="${varname//./-}"

      echo "    ${varname}" >>"$output_file"
    done

    cat >>"$output_file" <<'EOF'
  ];
}
EOF

    log "SUCCESS" "NIX-GEN" "Generated: ${dir_name}.nix ($script_count scripts)"
    ((total_generated++))
  done

  log "SUCCESS" "NIX-GEN" "All Nix expressions generated ($total_generated files)"
}

#-------------------------------------------------------------------------------
# List and Status Functions
#-------------------------------------------------------------------------------

list_profiles() {
  echo -e "${BOLD}${CYAN}Available Profiles (Browser: $BROWSER_TYPE, WM: $WM_TYPE):${NC}\n"

  echo -e "${BOLD}${GREEN}Terminals:${NC}"
  for profile in "${!TERMINALS[@]}"; do
    local config="${TERMINALS[$profile]}"
    local cmd=$(parse_config "$config" 1)
    local workspace=$(parse_config "$config" 3)
    local vpn=$(parse_config "$config" 4)
    printf "  %-20s %s (workspace: %s, vpn: %s)\n" "$profile" "$cmd" "$workspace" "$vpn"
  done

  echo -e "\n${BOLD}${GREEN}Browsers ($BROWSER_TYPE):${NC}"
  local browsers_var=$(get_browser_profiles)
  local -n browsers_ref=$browsers_var
  for profile in "${!browsers_ref[@]}"; do
    local config="${browsers_ref[$profile]}"
    local cmd=$(parse_config "$config" 1)
    local workspace=$(parse_config "$config" 3)
    local vpn=$(parse_config "$config" 4)
    printf "  %-20s %s (workspace: %s, vpn: %s)\n" "$profile" "$cmd" "$workspace" "$vpn"
  done

  echo -e "\n${BOLD}${GREEN}Applications:${NC}"
  for profile in "${!APPS[@]}"; do
    local config="${APPS[$profile]}"
    local cmd=$(parse_config "$config" 1)
    local workspace=$(parse_config "$config" 3)
    local vpn=$(parse_config "$config" 4)
    printf "  %-20s %s (workspace: %s, vpn: %s)\n" "$profile" "$cmd" "$workspace" "$vpn"
  done
}

check_status() {
  echo -e "${BOLD}${CYAN}Application Status (WM: $WM_TYPE):${NC}\n"

  local running_count=0
  local total_count=0

  echo -e "${BOLD}${GREEN}Terminals:${NC}"
  for profile in "${!TERMINALS[@]}"; do
    ((total_count++))
    if is_app_running "$profile"; then
      echo -e "  ${GREEN}✓${NC} $profile (running)"
      ((running_count++))
    else
      echo -e "  ${RED}✗${NC} $profile (stopped)"
    fi
  done

  echo -e "\n${BOLD}${GREEN}Browsers ($BROWSER_TYPE):${NC}"
  local browsers_var=$(get_browser_profiles)
  local -n browsers_ref=$browsers_var
  for profile in "${!browsers_ref[@]}"; do
    ((total_count++))
    if is_app_running "$profile"; then
      echo -e "  ${GREEN}✓${NC} $profile (running)"
      ((running_count++))
    else
      echo -e "  ${RED}✗${NC} $profile (stopped)"
    fi
  done

  echo -e "\n${BOLD}${GREEN}Applications:${NC}"
  for profile in "${!APPS[@]}"; do
    ((total_count++))
    if is_app_running "$profile"; then
      echo -e "  ${GREEN}✓${NC} $profile (running)"
      ((running_count++))
    else
      echo -e "  ${RED}✗${NC} $profile (stopped)"
    fi
  done

  echo -e "\n${BOLD}Summary:${NC} $running_count/$total_count applications running"
}

kill_all() {
  log "INFO" "KILL" "Stopping all managed applications..."
  local killed_count=0

  if [[ -d "$STATE_DIR" ]]; then
    for pid_file in "$STATE_DIR"/*.pid; do
      if [[ -f "$pid_file" ]]; then
        local pid=$(cat "$pid_file")
        local profile=$(basename "$pid_file" .pid)
        local cmd_file="$STATE_DIR/$profile.cmd"
        local expected_command=""
        [[ -f "$cmd_file" ]] && expected_command=$(cat "$cmd_file")

        if kill -0 "$pid" 2>/dev/null; then
          if [[ -z "$expected_command" ]] || pid_matches_expected_command "$pid" "$expected_command"; then
            log "INFO" "KILL" "Stopping $profile (PID: $pid)"
            kill "$pid" 2>/dev/null && ((killed_count++))
          else
            log "WARN" "KILL" "Skipping $profile (PID reused or command mismatch)"
          fi
        fi
        rm -f "$pid_file"
        rm -f "$cmd_file"
      fi
    done
  fi

  log "SUCCESS" "KILL" "Stopped $killed_count applications"
}

#-------------------------------------------------------------------------------
# Help Function
#-------------------------------------------------------------------------------

show_help() {
  echo -e "${BOLD}${GREEN}Semsumo v$VERSION - Unified Application Launcher${NC}"
  echo
  echo -e "${BOLD}Usage:${NC}"
  echo "    $0 [BROWSER] <command> [options]"
  echo
  echo -e "${BOLD}Browser Types:${NC}"
  echo "    brave                 Use Brave Browser profiles (default)"
  echo "    firefox               Use Firefox profiles"
  echo "    chrome                Use Chrome Browser profiles"
  echo
  echo -e "${BOLD}Commands:${NC}"
  echo "    generate [profile]    Generate startup script(s)"
  echo "    launch [profile]      Launch application(s) directly"
  echo "    list                  List all available profiles"
  echo "    clean                 Remove all generated scripts"
  echo "    status                Show running applications status"
  echo "    kill                  Stop all managed applications"
  echo "    help                  Show this help"
  echo
  echo -e "${BOLD}Generate Options:${NC}"
  echo "    --all                 Generate scripts for ALL profiles (all browsers)"
  echo "    --daily               Generate scripts for daily/essential profiles"
  echo
  echo -e "${BOLD}Launch Options:${NC}"
  echo "    --daily               Launch only daily/essential profiles"
  echo "    --concurrent          With --daily: launch daily profiles concurrently"
  echo "    -all                  Legacy alias for --concurrent"
  echo "    --workspace NUM       Final workspace (default: $DEFAULT_FINAL_WORKSPACE)"
  echo "    --timeout NUM         App verification timeout (default: $DEFAULT_APP_TIMEOUT)"
  echo
  echo -e "${BOLD}Global Options:${NC}"
  echo "    --dry-run             Test mode (don't actually run anything)"
  echo "    --debug               Enable debug output"
  echo "    --no-notify           Disable desktop notifications"
  echo
  echo -e "${BOLD}Features:${NC}"
  echo "    - Auto-detects window manager (Hyprland/GNOME/generic)"
  echo "    - Window verification on Hyprland (requires jq)"
  echo "    - VPN bypass/secure mode support (Mullvad)"
  echo "    - Multi-browser profile support"
  echo "    - Nix expression generator for home-manager integration"
  echo
  echo -e "${BOLD}Examples:${NC}"
  echo "    $0 generate --all                   # Generate ALL scripts"
  echo "    $0 generate --daily                 # Generate daily scripts only"
  echo "    $0 launch --daily                   # Launch daily profiles"
  echo "    $0 brave launch brave-kenp          # Launch specific profile"
  echo "    $0 list                             # List all profiles"
  echo "    $0 status                           # Check running apps"
  echo
  echo -e "${BOLD}Detected:${NC} Window Manager = $WM_TYPE"
  echo -e "${BOLD}Locations:${NC}"
  echo "    Scripts: $SCRIPTS_DIR"
  echo "    Logs:    $LOG_FILE"
}

#-------------------------------------------------------------------------------
# Argument Parsing
#-------------------------------------------------------------------------------

parse_args() {
  if [[ $# -gt 0 && ("$1" == "brave" || "$1" == "chrome" || "$1" == "firefox") ]]; then
    BROWSER_TYPE="$1"
    shift
  fi

  case "${1:-help}" in
  generate)
    MODE_GENERATE=true
    shift
    ;;
  launch)
    MODE_LAUNCH=true
    shift
    ;;
  list)
    MODE_LIST=true
    shift
    ;;
  clean)
    MODE_CLEAN=true
    shift
    ;;
  status)
    check_status
    exit 0
    ;;
  kill)
    kill_all
    exit 0
    ;;
  help | --help | -h)
    show_help
    exit 0
    ;;
  version | --version | -v)
    echo "Semsumo v$VERSION"
    exit 0
    ;;
  *)
    log "ERROR" "ARGS" "Unknown command: $1"
    show_help
    exit 1
    ;;
  esac

  while [[ $# -gt 0 ]]; do
    case "$1" in
    --all)
      if [[ "$MODE_GENERATE" == "true" ]]; then
        LAUNCH_ALL=true
      elif [[ "$MODE_LAUNCH" == "true" ]]; then
        RUN_TERMINALS=true
        RUN_BROWSER=true
        RUN_APPS=true
      fi
      shift
      ;;
	    --daily)
	      LAUNCH_DAILY=true
	      shift
	      ;;
	    --concurrent|-all)
	      LAUNCH_DAILY_ALL=true
	      shift
	      ;;
	    --workspace)
	      if [[ -z "${2:-}" ]]; then
	        log "ERROR" "ARGS" "--workspace requires a numeric value"
	        exit 1
	      fi
	      if ! is_non_negative_int "$2"; then
	        log "ERROR" "ARGS" "Invalid workspace value: $2 (expected 0 or positive integer)"
	        exit 1
	      fi
	      FINAL_WORKSPACE="$2"
	      shift 2
	      ;;
	    --timeout)
	      if [[ -z "${2:-}" ]]; then
	        log "ERROR" "ARGS" "--timeout requires a numeric value"
	        exit 1
	      fi
	      if ! is_positive_int "$2"; then
	        log "ERROR" "ARGS" "Invalid timeout value: $2 (expected positive integer)"
	        exit 1
	      fi
	      APP_TIMEOUT="$2"
	      shift 2
	      ;;
	    --dry-run)
	      DRY_RUN=true
	      shift
	      ;;
	    --debug)
	      DEBUG_MODE=true
	      shift
	      ;;
	    --no-notify)
	      NOTIFY_ENABLED=false
	      shift
	      ;;
    "") break ;;
    *)
      SINGLE_PROFILE="$1"
      shift
      ;;
    esac
  done
}

#-------------------------------------------------------------------------------
# Main Function
#-------------------------------------------------------------------------------

main() {
  local start_time=$(date +%s)

  detect_window_manager
  parse_args "$@"
  check_dependencies

  log "INFO" "START" "Semsumo v$VERSION started ($WM_TYPE, $BROWSER_TYPE)" "true"

  if [[ "$MODE_GENERATE" == "true" ]]; then
    if [[ "$LAUNCH_ALL" == "true" ]]; then
      generate_all_scripts
    elif [[ "$LAUNCH_DAILY" == "true" ]]; then
      generate_daily_scripts
    elif [[ -n "$SINGLE_PROFILE" ]]; then
      log "ERROR" "GENERATE" "Single profile generation not yet implemented in unified version"
      exit 1
    else
      log "ERROR" "GENERATE" "Profile name or option required"
      show_help
      exit 1
    fi

  elif [[ "$MODE_LAUNCH" == "true" ]]; then
    if [[ "$LAUNCH_DAILY" == "true" ]]; then
      launch_daily_profiles
    elif [[ -n "$SINGLE_PROFILE" ]]; then
      launch_profile "$SINGLE_PROFILE"
    else
      log "ERROR" "LAUNCH" "Please specify --daily or profile name"
      exit 1
    fi

    # Ensure all windows are on correct workspaces (Hyprland only)
    if [[ "$WM_TYPE" == "hyprland" ]]; then
      log "INFO" "WINDOW" "Verifying window positions..."
      sleep 2 # Give windows time to fully appear
      ensure_windows_on_correct_workspace
    fi

    if [[ -n "$FINAL_WORKSPACE" ]]; then
      log "INFO" "WORKSPACE" "Switching to final workspace $FINAL_WORKSPACE"
      switch_workspace "$FINAL_WORKSPACE"
    fi

  elif [[ "$MODE_LIST" == "true" ]]; then
    list_profiles

  elif [[ "$MODE_CLEAN" == "true" ]]; then
    clean_scripts

  else
    show_help
    exit 1
  fi

  local end_time=$(date +%s)
  local total_time=$((end_time - start_time))

  log "SUCCESS" "DONE" "Completed ($WM_TYPE, $BROWSER_TYPE) - Time: ${total_time}s" "true"
}

# Check dependencies
check_dependencies() {
  local missing_deps=()

  case "$BROWSER_TYPE" in
  brave) command -v profile_brave >/dev/null 2>&1 || missing_deps+=("profile_brave") ;;
  chrome) command -v profile_chrome >/dev/null 2>&1 || missing_deps+=("profile_chrome") ;;
  firefox) command -v firefox >/dev/null 2>&1 || missing_deps+=("firefox") ;;
  esac

  if [[ "$WM_TYPE" == "hyprland" ]] && ! command -v jq >/dev/null 2>&1; then
    log "WARN" "DEPS" "jq not found - window verification disabled"
  fi

  if [[ ${#missing_deps[@]} -gt 0 ]]; then
    log "WARN" "DEPS" "Missing: ${missing_deps[*]}"
  fi
}

trap 'log "ERROR" "TRAP" "Script interrupted"; exit 1' ERR INT TERM

main "$@"
