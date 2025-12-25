#!/usr/bin/env bash
# ==============================================================================
# NixOS Installation Script v4.0.1 (Snowfall Edition)
# Modular, Flake-aware, Git-integrated, and Beautiful
# Location: flake root (./install.sh)
# ==============================================================================

# Strict mode for safety (optional, but good practice)
# set -euo pipefail

# ==============================================================================
# PART 1: CORE LIBRARY & VISUALS
# ==============================================================================

# Timer
readonly START_TIME=$(date +%s)

# Metadata
readonly VERSION="4.0.1"
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
  local log_file="${1:-"$LOG_FILE"}"
  mkdir -p "$(dirname "$log_file")" 2>/dev/null || true

  # If log path is not writable (e.g., restricted environments), fall back to a
  # workspace-local log file.
  if ! ( : >>"$log_file" ) 2>/dev/null; then
    log_file="${WORK_DIR}/.nixosb/nixos-install.log"
    mkdir -p "$(dirname "$log_file")" 2>/dev/null || true
  fi

  exec 3>>"$log_file" 2>/dev/null || true
  find "$(dirname "$log_file")" -name "nixos-install*.log" -mtime +7 -delete 2>/dev/null || true
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
    local clean_msg="$(echo "$msg" | sed 's/\x1b\[[0-9;]*m//g')"
    echo "[$timestamp] [$level] $clean_msg" >&3
  fi
}

header() {
  clear
  echo -e "${C_BLUE}"
  cat <<'EOF'
   _   _ _      ____   ____ 
  | \ | (_)_  _/ __ \ / ___|
  |  \| | \ \/ / | | |\___ \
  | |\  | |>  <| |_| |___) |
  |_| \_|_/_/\_\\____/|____/ 
EOF
  echo -e "${C_RESET}"
  echo -e "${C_DIM}  Snowfall Edition v${VERSION} | ${WORK_DIR}${C_RESET}\n"
}

hr() {
  printf "${C_DIM}%*s${C_RESET}\n" "$(tput cols)" '' | tr ' ' '─'
}

confirm() {
  local msg="${1:-Are you sure?}"
  [[ "${CONFIG[AUTO_MODE]:-false}" == "true" ]] && return 0
  printf "${C_YELLOW}?${C_RESET} %s ${C_DIM}[y/N]${C_RESET} " "$msg"
  read -r -n 1 response
  echo
  [[ "${response,,}" == "y" ]]
}

has_command() { command -v "$1" &>/dev/null; }

check_deps() {
  for cmd in git nix jq; do
    if ! has_command "$cmd"; then
      log WARN "Missing dependency: $cmd"
    fi
  done
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
    done < <(jq -r 'to_entries[] | "\(.key)=\(.value)"' "$file")
  fi
}

config::save() {
  mkdir -p "$CONFIG_DIR"
  local file="${CONFIG_DIR}/config.json"
  cat >"$file" <<EOF
{
  "USERNAME": "${CONFIG[USERNAME]}",
  "HOSTNAME": "${CONFIG[HOSTNAME]}",
  "PROFILE": "${CONFIG[PROFILE]}",
  "FLAKE_DIR": "${CONFIG[FLAKE_DIR]}"
}
EOF
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

  log INFO "Syncing wallpapers to ${dest} (existing files kept)..."
  mkdir -p "$dest"
  rsync -a --ignore-existing --exclude '.gitkeep' "$src"/ "$dest"/
}

# ==============================================================================
# PART 3: FLAKE & GIT LOGIC
# ==============================================================================

git::ensure_clean() {
  local dir="$1"
  cd "$dir" || return 1

  if [[ -n "$(git status --porcelain)" ]]; then
    log WARN "Git directory is dirty. Unstaged files are ignored by Flakes."
    if confirm "Stage all changes (git add .)?"; then
      git add .
      log SUCCESS "Changes staged."
    else
      log WARN "Proceeding with unstaged changes (Risky!)"
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

flake::build() {
  local hostname="${1:-$(config::get HOSTNAME)}"
  local profile="${2:-$(config::get PROFILE)}"

  host::validate "$hostname" || return 1
  cd "${CONFIG[FLAKE_DIR]}" || return 1
  git::ensure_clean "${CONFIG[FLAKE_DIR]}"

  # In auto mode we must not block on a sudo password prompt.
  if [[ "${CONFIG[AUTO_MODE]:-false}" == "true" ]]; then
    if ! sudo -n true 2>/dev/null; then
      log ERROR "Auto mode requires passwordless sudo (sudo -n). Run without -a/--auto or cache sudo first (sudo -v)."
      return 1
    fi
  fi

  # Construct Command
  local cmd="sudo nixos-rebuild switch --flake .#${hostname}"
  [[ -n "$profile" ]] && cmd+=" --profile-name ${profile}"

  cmd+=" --option accept-flake-config true"
  cmd+=" --option warn-dirty false"
  [[ "${DEBUG:-false}" == "true" ]] && cmd+=" --show-trace --verbose"

  log STEP "Building System Configuration"
  log INFO "Host:    ${C_BOLD}${C_WHITE}$hostname${C_RESET}"
  [[ -n "$profile" ]] && log INFO "Profile: ${C_CYAN}$profile${C_RESET}"
  log INFO "Dir:     ${CONFIG[FLAKE_DIR]}"
  log DEBUG "Command: ${cmd}"

  echo -e "${C_DIM}Running build command...${C_RESET}"
  if eval "$cmd"; then
    echo ""
    log SUCCESS "Build completed successfully!"
    return 0
  else
    echo ""
    log ERROR "Build failed!"
    return 1
  fi
}

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
  echo -e "${C_BOLD}${C_GREEN}${S_SUCCESS}  SYSTEM SUCCESSFULLY UPDATED${C_RESET}"
  hr
  echo ""
  echo -e "   ${C_DIM}Hostname   ${C_RESET}${C_BOLD}${CONFIG[HOSTNAME]:-Unknown}${C_RESET}"
  echo -e "   ${C_DIM}User       ${C_RESET}${C_CYAN}${CONFIG[USERNAME]}${C_RESET}"
  if [[ -n "${CONFIG[PROFILE]}" ]]; then
    echo -e "   ${C_DIM}Profile    ${C_RESET}${C_PURPLE}${CONFIG[PROFILE]}${C_RESET}"
  fi
  echo ""
  echo -e "   ${C_DIM}Time       ${C_RESET}$(date '+%H:%M:%S')"
  echo -e "   ${C_DIM}Duration   ${C_RESET}${minutes} min ${seconds} sec"
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
  if flake::build "$hostname"; then
    show_summary
  else
    log ERROR "Installation aborted due to errors."
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

  # This command is meant to run on an already installed (minimal) NixOS system
  # to bootstrap prerequisites (flakes, base packages, etc.). It operates on the
  # current root filesystem, not on /mnt.
  local target_root="/"
  local nixos_dir="/etc/nixos"

  local template_path="${CONFIG[FLAKE_DIR]:-$WORK_DIR}/systems/${SYSTEM_ARCH}/${hostname}/templates/initial-configuration.nix"
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
  sudo cp "$template_path" "${nixos_dir}/configuration.nix"
  sudo chown root:root "${nixos_dir}/configuration.nix"
  sudo chmod 644 "${nixos_dir}/configuration.nix"

  if [[ ! -f "${nixos_dir}/hardware-configuration.nix" ]]; then
    log INFO "Generating hardware config..."
    sudo nixos-generate-config --root /
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
    git fetch -p >/dev/null 2>&1
    mapfile -t branches < <(git branch -a --format='%(refname:short)' | grep -v 'origin/HEAD' | sed 's/^origin\///' | sort -u)

    echo -e "\n${C_CYAN}Available Branches:${C_RESET}"
    local i=0
    for branch in "${branches[@]}"; do
      echo "  $i) $branch"
      ((i++))
    done
    echo ""

    read -r -p "Select TARGET branch (name or number): " tgt_sel
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
  echo "  install          Build & Switch configuration"
  echo "  auto             Auto mode: update + install with next free YYMMDD profile"
  echo "  update           Update flake inputs"
  echo "  build            Build only"
  echo "  merge            Merge branches (interactively)"
  echo "  hosts            List available hosts"
  echo "  --pre-install    Bootstrap system"
  echo ""
  echo -e "${C_BOLD}Options:${C_RESET}"
  echo "  -H, --host NAME  Hostname (hay, vhay)"
  echo "  -p, --profile X  Profile name"
  echo "  -u, --update     Update inputs before install"
  echo "  -a, --auto       Non-interactive mode"
  echo "  -m, --merge      Run merge after install"
}

parse_args() {
  if [[ "${1:-}" =~ ^- ]] && [[ "$1" != "-h" ]] && [[ "$1" != "--help" ]] && [[ "$1" != "-m" ]] && [[ "$1" != "--merge" ]] && [[ "$1" != "--pre-install" ]]; then
    set -- "install" "$@"
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
      shift
      flake::build "$@"
      exit 0
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
    pre-install|--pre-install)
      action="pre-install"
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

  if [[ "$action" == "pre-install" ]]; then
    cmd_pre-install
    return
  fi

  if [[ "$action" == "auto" ]]; then
    local host="${auto_host:-$(config::get HOSTNAME)}"
    [[ -z "$host" ]] && host="$DEFAULT_HOST"
    config::set AUTO_MODE true
    # config::set UPDATE_FLAKE true (Disabled: prevents auto-upgrade on every build)
    config::set HOSTNAME "$host"
    config::set PROFILE "$(profile::next_available)"
    cmd_install "$host"
    return
  fi

  if [[ "$action" == "install" ]]; then
    cmd_install
  fi
}

show_menu() {
  header
  echo "Current Host: ${C_BOLD}${CONFIG[HOSTNAME]:-Unknown}${C_RESET}"
  echo "Flake Dir:    ${C_DIM}${CONFIG[FLAKE_DIR]:-$WORK_DIR}${C_RESET}"
  echo ""
  echo "1) Install / Switch Config"
  echo "2) Update Flake Inputs"
  echo "3) Pre-Install Bootstrap"
  echo "4) Merge Branches"
  echo "5) Edit Config (Neovim)"
  echo "6) List Hosts"
  echo "q) Exit"
  echo ""
  printf "${C_YELLOW}Select:${C_RESET} "
  read -r choice

  case "$choice" in
  1)
    [[ -z "${CONFIG[HOSTNAME]}" ]] && read -r -p "Hostname (hay/vhay): " h && config::set HOSTNAME "$h"
    cmd_install
    ;;
  2) flake::update ;;
  3)
    read -r -p "Hostname (hay/vhay): " h
    config::set HOSTNAME "$h"
    cmd_pre-install
    ;;
  4) cmd_merge "false" ;;
  5) cd "$WORK_DIR" && nvim . ;;
  6)
    host::list
    read -r -p "Press Enter to continue..." _
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
