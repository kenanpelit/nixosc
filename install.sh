#!/usr/bin/env bash
# ==============================================================================
# NixOS Installation Script v4.0.3 (Snowfall Edition)
# Modular, Flake-aware, Git-integrated, and Beautiful
# Location: flake root (./install.sh)
# ==============================================================================

set -Eeuo pipefail
IFS=$'\n\t'

# ==============================================================================
# PART 1: CORE LIBRARY & VISUALS
# ==============================================================================

# Timer
readonly START_TIME=$(date +%s)

# Metadata
readonly VERSION="4.0.3"
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly WORK_DIR="${SCRIPT_DIR}"

# Configuration Paths
readonly CONFIG_DIR="$HOME/.config/nixos"
readonly LOG_FILE="$HOME/.nixosb/nixos-install.log"
readonly SYSTEM_ARCH="x86_64-linux"
readonly DEFAULT_HOST="hay"

# Merge Configuration - Files to preserve during merges
readonly EXCLUDE_FILES=(
  # Keep user Hyprland config pinned on target branch
  "modules/home/hyprland/config.nix"
  "systems/${SYSTEM_ARCH}/hay/hardware-configuration.nix"
  "systems/${SYSTEM_ARCH}/vhay/hardware-configuration.nix"
  "flake.lock"
)

# Defaults
readonly DEFAULT_USERNAME='kenan'

# UI Colors (TrueColor / Adaptive)
if [[ -t 1 ]]; then
  readonly C_RESET='\033[0m'
  readonly C_BOLD='\033[1m'
  readonly C_DIM='\033[2m'
  readonly C_RED='\033[38;5;196m'
  readonly C_GREEN='\033[38;5;77m'   # More vivid green
  readonly C_YELLOW='\033[38;5;220m' # Gold/Yellow
  readonly C_BLUE='\033[38;5;39m'    # NixOS Blue-ish
  readonly C_PURPLE='\033[38;5;141m' # Softer Purple
  readonly C_CYAN='\033[38;5;80m'    # Bright Cyan
  readonly C_WHITE='\033[38;5;255m'
  readonly C_GRAY='\033[38;5;240m'

  readonly S_SUCCESS="✓"
  readonly S_ERROR="✗"
  readonly S_WARN="⚠"
  readonly S_INFO="ℹ"
  readonly S_ARROW="❯" # More modern arrow
  readonly S_BULLET="•"
else
  readonly C_RESET='' C_BOLD='' C_DIM='' C_RED='' C_GREEN='' C_YELLOW='' C_BLUE='' C_PURPLE='' C_CYAN='' C_WHITE='' C_GRAY=''
  readonly S_SUCCESS="[OK]" S_ERROR="[ERR]" S_WARN="[WARN]" S_INFO="[INFO]" S_ARROW="->" S_BULLET="*"
fi

# Logging System
log::init() {
  local log_path="${1:-"$LOG_FILE"}"
  mkdir -p "$(dirname "$log_path")" 2>/dev/null || true

  # Prefer writing logs under $HOME (LOG_FILE). If it's not writable, keep going
  # without file logging rather than dirtying the repo/workdir.
  if ! (: >>"$log_path") 2>/dev/null; then
    log WARN "Cannot write log file: $log_path (continuing without file logging)"
    return 0
  fi

  exec 3>>"$log_path" 2>/dev/null || true
  find "$(dirname "$log_path")" -name "nixos-install*.log" -mtime +7 -delete 2>/dev/null || true
}

log() {
  local level="$1"
  shift
  local msg="$*"
  local timestamp="$(date '+%H:%M:%S')"

  case "$level" in
  INFO) printf "  ${C_BLUE}${S_INFO}${C_RESET}  %b\n" "$msg" ;;
  SUCCESS) printf "  ${C_GREEN}${S_SUCCESS}${C_RESET}  %b\n" "$msg" ;;
  WARN) printf "  ${C_YELLOW}${S_WARN}${C_RESET}  %b\n" "$msg" ;;
  ERROR) printf "  ${C_RED}${S_ERROR}${C_RESET}  %b\n" "$msg" >&2 ;;
  STEP) printf "\n${C_PURPLE}${S_ARROW} ${C_BOLD}%b${C_RESET}\n" "$msg" ;;
  DEBUG) [[ "${DEBUG:-false}" == "true" ]] && printf "  ${C_GRAY}${S_BULLET}${C_RESET}  %b\n" "$msg" ;;
  esac

  if [[ -e /proc/self/fd/3 ]]; then
    local clean_msg
    clean_msg="$(printf '%b' "$msg" | sed 's/\x1b\[[0-9;]*m//g')"
    echo "[$timestamp] [$level] $clean_msg" >&3
  fi
}

on_error() {
  local exit_code=$?
  local line_no="${1:-unknown}"
  log ERROR "Unexpected error (line ${line_no}, exit ${exit_code}): ${BASH_COMMAND}"
  exit "$exit_code"
}

trap 'on_error $LINENO' ERR

header() {
  if [[ -t 1 ]] && command -v clear >/dev/null 2>&1; then
    clear 2>/dev/null || true
  fi

  hr
  echo -e "${C_BLUE}${C_BOLD}"
  if [[ "$(term::cols)" -ge 60 ]]; then
    cat <<'EOF'
   _   _ _      ____   ____ 
  | \ | (_)_  _/ __ \ / ___|
  |  \| | \ \/ / | | |\___ \
  | |\  | |>  <| |_| |___) |
  |_| \_|_/_/\_\\____/|____/ 
EOF
  else
    echo "NixOS Install"
  fi
  echo -e "${C_RESET}"

  local meta=()
  meta+=("Snowfall Edition v${VERSION}")
  meta+=("${WORK_DIR}")

  if has_command git && git -C "${WORK_DIR}" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    local branch
    branch="$(git -C "${WORK_DIR}" branch --show-current 2>/dev/null || true)"
    [[ -n "$branch" ]] && meta+=("branch:${branch}")
  fi

  local meta_line
  meta_line="$(IFS=' | '; printf '%s' "${meta[*]}")"
  printf "${C_DIM}  %s${C_RESET}\n" "$meta_line"
  hr
  echo ""
}

term::cols() {
  local cols="${COLUMNS:-}"
  if [[ -z "$cols" ]] && command -v tput >/dev/null 2>&1; then
    cols="$(tput cols 2>/dev/null || true)"
  fi
  if [[ -z "$cols" ]] || ! [[ "$cols" =~ ^[0-9]+$ ]]; then
    cols="80"
  fi
  echo "$cols"
}

hr() {
  local cols
  cols="$(term::cols)"
  printf "${C_DIM}%*s${C_RESET}\n" "$cols" '' | tr ' ' '─'
}

confirm() {
  local msg="${1:-Are you sure?}"
  [[ "${CONFIG[AUTO_MODE]:-false}" == "true" ]] && return 0
  printf "${C_YELLOW}?${C_RESET} %s ${C_DIM}[y/N]${C_RESET} " "$msg"
  read -r -n 1 response || return 1
  echo
  [[ "${response,,}" == "y" ]]
}

has_command() { command -v "$1" &>/dev/null; }

check_deps() {
  local missing=()
  local cmds=(
    git
    nix
    jq
    sudo
    nixos-rebuild
    nixos-generate-config
    rsync
  )

  local cmd
  for cmd in "${cmds[@]}"; do
    if ! has_command "$cmd"; then
      missing+=("$cmd")
    fi
  done

  if [[ "${#missing[@]}" -gt 0 ]]; then
    log WARN "Missing commands: ${missing[*]}"
  fi
}

sudo::ensure() {
  if ! has_command sudo; then
    log ERROR "sudo not found in PATH."
    return 1
  fi

  if [[ "${CONFIG[AUTO_MODE]:-false}" == "true" ]]; then
    sudo -n true 2>/dev/null || {
      log ERROR "Auto mode requires passwordless sudo (sudo -n). Run without -a/--auto or cache sudo first (sudo -v)."
      return 1
    }
    return 0
  fi

  sudo -v
}

# Host helpers
host::validate() {
  local hostname="$1"
  local flake_dir="${CONFIG[FLAKE_DIR]:-$WORK_DIR}"
  local system_dir="$flake_dir/systems/$SYSTEM_ARCH"

  if [[ -z "$hostname" ]]; then
    log ERROR "Hostname required."
    return 1
  fi

  if [[ ! -d "$system_dir/$hostname" ]]; then
    log ERROR "Unknown host '${hostname}'."
    if [[ -d "$system_dir" ]]; then
      log INFO "Available hosts in ${system_dir}:"
      find "$system_dir" -maxdepth 1 -mindepth 1 -type d -printf '  - %f\n'
    fi
    return 1
  fi
}

host::list() {
  local flake_dir="${CONFIG[FLAKE_DIR]:-$WORK_DIR}"
  local system_dir="$flake_dir/systems/$SYSTEM_ARCH"

  if [[ ! -d "$system_dir" ]]; then
    log ERROR "No systems directory found at ${system_dir}"
    return 1
  fi

  echo ""
  log STEP "Available Hosts ($SYSTEM_ARCH)"
  find "$system_dir" -maxdepth 1 -mindepth 1 -type d -printf '  - %f\n'
  echo ""
}

# ==============================================================================
# PART 2: CONFIGURATION MANAGEMENT
# ==============================================================================

declare -A CONFIG=(
  [USERNAME]="$DEFAULT_USERNAME"
  [HOSTNAME]=""
  [PROFILE]=""
  [FLAKE_DIR]="$WORK_DIR"
  [AUTO_MODE]=false
  [UPDATE_FLAKE]=false
)

config::load() {
  local file="${CONFIG_DIR}/config.json"
  if [[ -f "$file" ]] && has_command jq; then
    while IFS='=' read -r key value; do
      CONFIG[$key]="$value"
    done < <(jq -r 'to_entries[] | "\(.key)=\(.value)"' "$file" 2>/dev/null || true)
  fi
}

config::save() {
  if ! mkdir -p "$CONFIG_DIR" 2>/dev/null; then
    log WARN "Cannot create config directory: $CONFIG_DIR (skipping save)"
    return 0
  fi
  local file="${CONFIG_DIR}/config.json"
  if ! cat >"$file" <<EOF
{
  "USERNAME": "${CONFIG[USERNAME]}",
  "HOSTNAME": "${CONFIG[HOSTNAME]}",
  "PROFILE": "${CONFIG[PROFILE]}",
  "FLAKE_DIR": "${CONFIG[FLAKE_DIR]}"
}
EOF
  then
    log WARN "Cannot write config file: $file (skipping save)"
    return 0
  fi
}

config::get() { echo "${CONFIG[$1]:-}"; }
config::set() { CONFIG[$1]="$2"; }

# ==============================================================================
# Profile helpers (auto profile name like 251201 -> YYMMDD, next free day)
# ==============================================================================
profile::exists() {
  local name="$1"
  [[ -z "$name" ]] && return 1
  [[ -e "/nix/var/nix/profiles/system-profiles/${name}" ]]
}

profile::next_available() {
  local base_date="${1:-$(date +%Y-%m-%d)}"
  local offset=0
  while :; do
    local candidate
    candidate=$(date -d "${base_date} +${offset} day" +%y%m%d)
    profile::exists "$candidate" || {
      echo "$candidate"
      return 0
    }
    offset=$((offset + 1))
  done
}

# ==============================================================================
# PART 2.5: ASSET SYNC (Wallpapers)
# ==============================================================================
wallpapers::sync() {
  local src="${CONFIG[FLAKE_DIR]:-$WORK_DIR}/wallpapers"
  local dest="$HOME/Pictures/wallpapers"

  if [[ ! -d "$src" ]]; then
    log DEBUG "No wallpapers directory at $src; skipping sync."
    return 0
  fi

  if ! has_command rsync; then
    log WARN "rsync not found; skipping wallpaper sync."
    return 0
  fi

  log INFO "Syncing wallpapers to ${dest} (existing files kept)..."
  if ! mkdir -p "$dest" 2>/dev/null; then
    log WARN "Cannot create wallpaper directory: $dest (skipping)"
    return 0
  fi

  if ! rsync -a --ignore-existing --exclude '.gitkeep' "$src"/ "$dest"/; then
    log WARN "Wallpaper sync failed (skipping)."
    return 0
  fi
}

# ==============================================================================
# PART 3: FLAKE & GIT LOGIC
# ==============================================================================

git::ensure_clean() {
  local dir="$1"
  if ! git -C "$dir" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    log DEBUG "Not a git work tree: $dir"
    return 0
  fi

  local dirty
  dirty="$(git -C "$dir" status --porcelain 2>/dev/null || true)"
  if [[ -n "$dirty" ]]; then
    log WARN "Git tree is dirty (Nix may warn; builds may be less reproducible)."
    if confirm "Stage all changes (git add -A)?"; then
      git -C "$dir" add -A
      log SUCCESS "Changes staged."
    else
      log WARN "Proceeding with dirty tree."
    fi
  fi
}

flake::update() {
  local input="${1:-}"
  cd "${CONFIG[FLAKE_DIR]}" || return 1

  log STEP "Updating Flake Inputs"

  if [[ -n "$input" ]]; then
    log INFO "Updating input: ${C_CYAN}$input${C_RESET}"
    nix flake lock --update-input "$input"
  else
    log INFO "Updating all inputs..."
    nix flake update
  fi
  log SUCCESS "Flake updated."
}

flake::rebuild() {
  local verb="${1:-switch}"
  local hostname="${2:-$(config::get HOSTNAME)}"
  local profile="${3:-$(config::get PROFILE)}"

  case "$verb" in
    switch | build) ;;
    *)
      log ERROR "Unknown nixos-rebuild action: $verb (expected: switch|build)"
      return 2
      ;;
  esac

  host::validate "$hostname" || return 1
  cd "${CONFIG[FLAKE_DIR]}" || return 1
  git::ensure_clean "${CONFIG[FLAKE_DIR]}"
  sudo::ensure || return 1

  local cmd=(
    sudo nixos-rebuild "$verb"
    --flake ".#${hostname}"
    --option accept-flake-config true
    --option warn-dirty false
  )

  if [[ -n "$profile" ]]; then
    cmd+=(--profile-name "$profile")
  fi

  local cmd_display
  cmd_display="$(printf '%q ' "${cmd[@]}")"
  cmd_display="${cmd_display% }"

  if [[ "$verb" == "switch" ]]; then
    log STEP "Applying System Configuration"
  else
    log STEP "Building System Configuration"
  fi
  log INFO "Host:    ${C_BOLD}${C_WHITE}$hostname${C_RESET}"
  [[ -n "$profile" ]] && log INFO "Profile: ${C_CYAN}$profile${C_RESET}"
  log INFO "Dir:     ${CONFIG[FLAKE_DIR]}"
  log INFO "Command: ${C_DIM}${cmd_display}${C_RESET}"

  log INFO "Running nixos-rebuild ${verb}..."

  # Force a TTY so nixos-rebuild prints steady progress even when it would
  # otherwise buffer or hide output.
  if [[ -t 1 ]] && command -v script >/dev/null 2>&1; then
    local rc_file script_rc rc tty_cmd
    rc_file="$(mktemp -t nixos-rebuild-rc.XXXXXX)"
    printf -v tty_cmd '%s; __rc=$?; printf "%%s" "$__rc" > %q; exit "$__rc"' "$cmd_display" "$rc_file"

    script_rc=0
    script -qfc "$tty_cmd" /dev/null || script_rc=$?

    rc="$script_rc"
    if [[ -r "$rc_file" ]]; then
      rc="$(cat "$rc_file" 2>/dev/null || echo "$script_rc")"
    fi
    rm -f "$rc_file"

    if [[ "$rc" =~ ^[0-9]+$ ]] && (( rc == 0 )); then
      echo ""
      log SUCCESS "nixos-rebuild ${verb} completed successfully!"
      return 0
    fi

    echo ""
    log ERROR "nixos-rebuild ${verb} failed (exit code: ${rc:-$script_rc})"
    return "${rc:-$script_rc}"
  fi

  if "${cmd[@]}"; then
    echo ""
    log SUCCESS "nixos-rebuild ${verb} completed successfully!"
    return 0
  fi
  local rc=$?
  echo ""
  log ERROR "nixos-rebuild ${verb} failed (exit code: $rc)"
  return "$rc"
}

flake::switch() { flake::rebuild switch "$@"; }
flake::build() { flake::rebuild build "$@"; }

# ==============================================================================
# PART 4: INSTALLATION COMMANDS
# ==============================================================================

# Define show_summary FIRST because it is called by cmd_install
show_summary() {
  local end_time=$(date +%s)
  local duration=$((end_time - START_TIME))
  local minutes=$((duration / 60))
  local seconds=$((duration % 60))

  echo ""
  hr
  log SUCCESS "System successfully updated"
  hr
  echo ""
  log INFO "Host:     ${C_BOLD}${C_WHITE}${CONFIG[HOSTNAME]:-Unknown}${C_RESET}"
  log INFO "User:     ${C_CYAN}${CONFIG[USERNAME]}${C_RESET}"
  [[ -n "${CONFIG[PROFILE]}" ]] && log INFO "Profile:  ${C_PURPLE}${CONFIG[PROFILE]}${C_RESET}"
  log INFO "Time:     $(date '+%H:%M:%S')"
  log INFO "Duration: ${minutes} min ${seconds} sec"
  echo ""
  hr
}

cmd_install() {
  local hostname="${1:-$(config::get HOSTNAME)}"
  [[ -z "$hostname" ]] && {
    log ERROR "Hostname not specified."
    return 1
  }

  config::set HOSTNAME "$hostname"
  config::save

  header

  # Optional Update
  if [[ "${CONFIG[UPDATE_FLAKE]}" == "true" ]]; then
    flake::update
  fi

  # Sync wallpapers (non-destructive)
  wallpapers::sync

  # Build System
  if flake::switch "$hostname"; then
    show_summary
  else
    log ERROR "Installation aborted due to errors."
    exit 1
  fi
}

cmd_build() {
  local hostname="${1:-$(config::get HOSTNAME)}"
  [[ -z "$hostname" ]] && {
    log ERROR "Hostname not specified."
    return 1
  }

  config::set HOSTNAME "$hostname"
  config::save

  header

  # Optional Update
  if [[ "${CONFIG[UPDATE_FLAKE]}" == "true" ]]; then
    flake::update
  fi

  if flake::build "$hostname"; then
    log SUCCESS "Build completed successfully!"
  else
    log ERROR "Build aborted due to errors."
    exit 1
  fi
}

cmd_pre-install() {
  local hostname="${1:-$(config::get HOSTNAME)}"
  [[ -z "$hostname" ]] && {
    log ERROR "Hostname required (use --host or -H)."
    return 1
  }

  host::validate "$hostname" || return 1

  header
  log STEP "Bootstrap Initial Configuration"

  if [[ $EUID -eq 0 ]]; then
    log ERROR "Run as normal user, NOT root."
    return 1
  fi

  sudo::ensure || return 1

  # This command is meant to run on an already installed (minimal) NixOS system
  # to bootstrap prerequisites (flakes, base packages, etc.). It operates on the
  # current root filesystem, not on /mnt.
  local target_root="/"
  local nixos_dir="/etc/nixos"

  local template_path="${CONFIG[FLAKE_DIR]:-$WORK_DIR}/systems/${SYSTEM_ARCH}/${hostname}/templates/bootstrap.nix"
  if [[ ! -f "$template_path" ]]; then
    log ERROR "Template not found: $template_path"
    return 1
  fi

  if [[ -f "${nixos_dir}/configuration.nix" ]]; then
    local backup="${nixos_dir}/configuration.nix.bak-$(date +%s)"
    log WARN "Backing up existing config to: $(basename "$backup")"
    sudo cp "${nixos_dir}/configuration.nix" "$backup"
  fi

  log INFO "Installing configuration..."
  sudo install -m 0644 "$template_path" "${nixos_dir}/configuration.nix"

  if [[ ! -f "${nixos_dir}/hardware-configuration.nix" ]]; then
    log INFO "Generating hardware config..."
    sudo nixos-generate-config --root "$target_root"
  fi

  if confirm "Apply bootstrap now? (runs nixos-rebuild switch)"; then
    log STEP "Applying Bootstrap (nixos-rebuild switch)"
    sudo nixos-rebuild switch
  else
    log WARN "Bootstrap config installed, but not applied."
  fi

  log SUCCESS "Bootstrap ready!"
  echo -e "\n${C_YELLOW}Next:${C_RESET} sudo nixos-rebuild switch --flake \"${CONFIG[FLAKE_DIR]:-$WORK_DIR}#${hostname}\""
}

cmd_merge() {
  local auto_yes="${1:-false}"
  local source_branch="${2:-}"
  local target_branch="${3:-}"

  header
  log STEP "Branch Merge Operation"

  if ! git rev-parse --git-dir >/dev/null 2>&1; then
    log ERROR "Not a git repository."
    return 1
  fi

  local current_branch=$(git branch --show-current)
  [[ -z "$current_branch" ]] && current_branch="HEAD"
  log INFO "Current Branch: ${C_BOLD}${C_YELLOW}${current_branch}${C_RESET}"

  if [[ -z "$source_branch" ]]; then
    source_branch="$current_branch"
  fi

  if [[ -z "$target_branch" ]]; then
    git fetch -p >/dev/null 2>&1 || true
    mapfile -t branches < <(git branch -a --format='%(refname:short)' | grep -v 'origin/HEAD' | sed 's/^origin\///' | sort -u)

    echo -e "\n${C_CYAN}Available Branches:${C_RESET}"
    local i=0
    for branch in "${branches[@]}"; do
      echo "  $i) $branch"
      ((i++))
    done
    echo ""

    read -r -p "Select TARGET branch (name or number): " tgt_sel || return 1
    if [[ "$tgt_sel" =~ ^[0-9]+$ ]] && ((tgt_sel < ${#branches[@]})); then
      target_branch="${branches[$tgt_sel]}"
    else
      target_branch="$tgt_sel"
    fi
  fi

  if [[ "$source_branch" == "$target_branch" ]]; then
    log ERROR "Source and Target cannot be the same."
    return 1
  fi

  log INFO "Source: ${C_BOLD}${source_branch}${C_RESET}"
  log INFO "Target: ${C_BOLD}${target_branch}${C_RESET}"

  if ! git rev-parse --verify "$target_branch" >/dev/null 2>&1; then
    if git rev-parse --verify "origin/$target_branch" >/dev/null 2>&1; then
      log WARN "Branch '$target_branch' found on remote, will be created locally."
    else
      log ERROR "Target branch '$target_branch' not found."
      return 1
    fi
  fi

  if [[ -n "$(git status --porcelain)" ]]; then
    log WARN "Working directory is dirty."
    if [[ "$auto_yes" != "true" ]] && ! confirm "Continue anyway?"; then
      return 1
    fi
  fi

  log INFO "Switching to target branch..."
  git checkout "$target_branch" || return 1

  log INFO "Merging source branch (no commit)..."
  # Prefer incoming (source) changes, we'll re-apply exclusions after
  if ! git merge --no-commit --no-ff -X theirs "$source_branch"; then
    log ERROR "Merge encountered conflicts! Please resolve manually."
    return 1
  fi

  log INFO "Processing excluded files..."
  for file in "${EXCLUDE_FILES[@]}"; do
    if [[ -f "$file" ]]; then
      log DEBUG "Excluding: $file"
      git reset HEAD "$file" 2>/dev/null || true
      git checkout HEAD -- "$file" 2>/dev/null || true
    fi
  done

  log STEP "Merge Summary"
  local staged_files=$(git diff --cached --name-only)

  if [[ -z "$staged_files" ]]; then
    log SUCCESS "Branches are in sync (except excluded files)."
    if [[ "$current_branch" != "$target_branch" ]]; then
      git checkout "$current_branch"
    fi
    return 0
  fi

  echo -e "${C_GREEN}Files to merge:${C_RESET}"
  echo "$staged_files" | sed 's/^/  + /'

  if [[ "$auto_yes" == "true" ]] || confirm "Commit these changes?"; then
    local excluded_list=""
    for f in "${EXCLUDE_FILES[@]}"; do
      excluded_list+="- $f\n"
    done
    local commit_msg="Merge from $source_branch to $target_branch\n\nExcluded files:\n$excluded_list\nAuto-generated by install.sh"
    git commit -m "$commit_msg"
    log SUCCESS "Merge committed."
    if [[ "$auto_yes" == "true" ]] || confirm "Push $target_branch to remote?"; then
      git push && log SUCCESS "Pushed $target_branch."
    fi
  else
    log WARN "Merge aborted. Changes are staged. Use 'git reset --hard HEAD' to undo."
    return 1
  fi

  if [[ "$current_branch" != "$target_branch" ]]; then
    if [[ "$auto_yes" == "true" ]] || confirm "Switch back to $current_branch?"; then
      git checkout "$current_branch"
    fi
  fi
}

# ==============================================================================
# PART 5: CLI & MENUS
# ==============================================================================

show_help() {
  header
  echo "Usage: $(basename "$0") [COMMAND] [OPTIONS]"
  echo ""
  echo -e "${C_BOLD}Commands:${C_RESET}"
  echo "  install [HOST]    Build & switch configuration"
  echo "  build [HOST]      Build only (no switch)"
  echo "  auto [HOST]       Non-interactive switch with next free YYMMDD profile"
  echo "  update [INPUT]    Update flake inputs (all or one input)"
  echo "  merge             Merge branches (interactively)"
  echo "  hosts             List available hosts"
  echo "  bootstrap [HOST]  Install /etc/nixos bootstrap config (alias: --pre-install)"
  echo ""
  echo -e "${C_BOLD}Options:${C_RESET}"
  echo "  -H, --host NAME  Hostname (hay, vhay)"
  echo "  -p, --profile X  Profile name (--profile-name)"
  echo "  -u, --update     Update inputs before install/build"
  echo "  -a, --auto       Non-interactive mode (auto-yes prompts)"
  echo "  -m, --merge      Alias for 'merge'"
}

parse_args() {
  # Convenience:
  # - If the user starts with flags, assume `install` (e.g. `./install.sh -u -H hay`).
  # - If the user starts with a hostname, also assume `install` (e.g. `./install.sh hay -p kenp`).
  if [[ $# -gt 0 ]] && [[ "${1:-}" =~ ^- ]] && [[ "$1" != "-h" ]] && [[ "$1" != "--help" ]] && [[ "$1" != "-m" ]] && [[ "$1" != "--merge" ]] && [[ "$1" != "--pre-install" ]]; then
    set -- "install" "$@"
  elif [[ $# -gt 0 ]] && [[ "${1:-}" != -* ]]; then
    case "${1:-}" in
    auto | install | hosts | update | build | merge | bootstrap | pre-install) ;;
    *) set -- "install" "$@" ;;
    esac
  fi

  local action=""
  local auto_host=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
    auto)
      action="auto"
      if [[ -n "${2:-}" && ! "${2}" =~ ^- ]]; then
        auto_host="$2"
        shift
      fi
      ;;
    install)
      action="install"
      if [[ -n "${2:-}" && ! "$2" =~ ^- ]] && [[ "$2" != "update" && "$2" != "merge" ]]; then
        config::set HOSTNAME "$2"
        shift
      fi
      ;;
    hosts)
      shift
      host::list
      exit 0
      ;;
    update)
      shift
      flake::update "${1:-}"
      exit 0
      ;;
    build)
      action="build"
      if [[ -n "${2:-}" && ! "$2" =~ ^- ]]; then
        config::set HOSTNAME "$2"
        shift
      fi
      ;;
    merge)
      shift
      local auto_yes="false" src="" tgt=""
      while [[ $# -gt 0 ]]; do
        case "$1" in
        -y | --yes) auto_yes="true" ;;
        -*) ;;
        *) if [[ -z "$src" ]]; then src="$1"; elif [[ -z "$tgt" ]]; then tgt="$1"; fi ;;
        esac
        shift
      done
      if [[ -n "$src" ]] && [[ -z "$tgt" ]]; then
        tgt="$src"
        src=""
      fi
      cmd_merge "$auto_yes" "$src" "$tgt"
      exit 0
      ;;
    bootstrap | pre-install | --pre-install)
      action="bootstrap"
      if [[ -n "${2:-}" && ! "$2" =~ ^- ]]; then
        config::set HOSTNAME "$2"
        shift
      fi
      ;;
    -u | --update) config::set UPDATE_FLAKE true ;;
    -au | -ua)
      config::set AUTO_MODE true
      config::set UPDATE_FLAKE true
      if [[ -n "${2:-}" && ! "${2}" =~ ^- ]]; then
        config::set HOSTNAME "$2"
        shift
      fi
      ;;
    -m | --merge)
      shift
      local auto_yes="false" src="" tgt=""
      while [[ $# -gt 0 ]]; do
        case "$1" in
        -y | --yes) auto_yes="true" ;;
        -*) break ;; # Stop at next flag (e.g. -H) if we want to support install -m
        *) if [[ -z "$src" ]]; then src="$1"; elif [[ -z "$tgt" ]]; then tgt="$1"; fi ;;
        esac
        shift
      done
      # If we are in "install" mode (hostname set), this should just set a flag.
      # But since -m was excluded from auto-install injection, we assume standalone merge.
      if [[ -n "$src" ]] && [[ -z "$tgt" ]]; then
        tgt="$src"
        src=""
      fi
      cmd_merge "$auto_yes" "$src" "$tgt"
      exit 0
      ;;
    -H | --host)
      shift
      config::set HOSTNAME "$1"
      ;;
    -p | --profile)
      shift
      config::set PROFILE "$1"
      ;;
    -a | --auto)
      config::set AUTO_MODE true
      if [[ -n "${2:-}" && ! "$2" =~ ^- ]]; then
        config::set HOSTNAME "$2"
        shift
      fi
      ;;
    -h | --help)
      show_help
      exit 0
      ;;
    *)
      log ERROR "Unknown option: $1"
      exit 1
      ;;
    esac
    shift
  done

  if [[ "$action" == "bootstrap" ]]; then
    cmd_pre-install
    return
  fi

  if [[ "$action" == "auto" ]]; then
    local host="${auto_host:-$(config::get HOSTNAME)}"
    [[ -z "$host" ]] && host="$DEFAULT_HOST"
    # Match inst.sh behaviour: auto implies non-interactive and date-based profiles.
    config::set AUTO_MODE true
    config::set HOSTNAME "$host"
    config::set PROFILE "$(profile::next_available)"
    cmd_install "$host"
    return
  fi

  if [[ "$action" == "install" ]]; then
    cmd_install
    return
  fi

  if [[ "$action" == "build" ]]; then
    cmd_build
    return
  fi
}

show_menu() {
  header
  echo "Current Host: ${C_BOLD}${CONFIG[HOSTNAME]:-Unknown}${C_RESET}"
  echo "Flake Dir:    ${C_DIM}${CONFIG[FLAKE_DIR]:-$WORK_DIR}${C_RESET}"
  echo ""
  echo "1) Install / Switch Config"
  echo "2) Update Flake Inputs"
  echo "3) Bootstrap System (pre-install)"
  echo "4) Merge Branches"
  echo "5) Edit Config (Neovim)"
  echo "6) List Hosts"
  echo "q) Exit"
  echo ""
  printf "${C_YELLOW}Select:${C_RESET} "
  read -r choice || exit 0

  case "$choice" in
  1)
    [[ -z "${CONFIG[HOSTNAME]}" ]] && read -r -p "Hostname (hay/vhay): " h && config::set HOSTNAME "$h"
    cmd_install
    ;;
  2) flake::update ;;
  3)
    read -r -p "Hostname (hay/vhay): " h || return 0
    config::set HOSTNAME "$h"
    cmd_pre-install
    ;;
  4) cmd_merge "false" ;;
  5)
    if has_command nvim; then
      (cd "$WORK_DIR" && nvim .) || true
    else
      log ERROR "nvim not found."
    fi
    ;;
  6)
    host::list
    read -r -p "Press Enter to continue..." _ || true
    ;;
  q) exit 0 ;;
  *) show_menu ;;
  esac
}

main() {
  log::init
  config::load
  check_deps
  if [[ $# -gt 0 ]]; then
    parse_args "$@"
  else
    show_menu
  fi
}

main "$@"
