#!/usr/bin/env bash
# ==============================================================================
# NixOS Installation Script v3.2.2 (Refined Edition)
# Modular, Flake-aware, Git-integrated, and Beautiful
# Location: flake root (./install.sh)
# ==============================================================================

# NOTE:
#   - set -euo pipefail is intentionally left commented; this script runs a mix
#     of best-effort and hard-fail operations. If you enable it, review error
#     handling paths first.
#set -euo pipefail

# ==============================================================================
# PART 1: CORE LIBRARY & VISUALS
# ==============================================================================

# Timer
readonly START_TIME=$(date +%s)

# Metadata
readonly VERSION="3.2.2"
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Default flake root = script directory (no hard-coded /home path)
readonly WORK_DIR="${SCRIPT_DIR}"

# Configuration Paths
readonly CONFIG_DIR="$HOME/.config/nixos"
readonly CACHE_DIR="$HOME/.nixos-cache"
readonly LOG_FILE="$HOME/.nixosb/nixos-install.log"
readonly FLAKE_LOCK="flake.lock"

# Merge Configuration
readonly EXCLUDE_FILES=(
  "modules/home/hyprland/config.nix"
  "systems/x86_64-linux/hay/hardware-configuration.nix"
  "flake.json"
  "flake.lock"
)

# Defaults
readonly DEFAULT_USERNAME='kenan'
readonly DEFAULT_TZ="Europe/Istanbul"
readonly SYSTEM_ARCH="x86_64-linux"

# UI Colors (TrueColor / Adaptive)
if [[ -t 1 ]]; then
  readonly C_RESET='\033[0m'
  readonly C_BOLD='\033[1m'
  readonly C_DIM='\033[2m'

  # Modern Neon Palette
  readonly C_RED='\033[38;5;196m'
  readonly C_GREEN='\033[38;5;46m'
  readonly C_YELLOW='\033[38;5;226m'
  readonly C_BLUE='\033[38;5;33m'
  readonly C_PURPLE='\033[38;5;129m'
  readonly C_CYAN='\033[38;5;51m'
  readonly C_WHITE='\033[38;5;255m'
  readonly C_GRAY='\033[38;5;244m'

  # Symbols
  readonly S_SUCCESS="✔"
  readonly S_ERROR="✖"
  readonly S_WARN="⚠"
  readonly S_INFO="ℹ"
  readonly S_ARROW="➜"
  readonly S_BULLET="•"
else
  readonly C_RESET='' C_BOLD='' C_DIM='' C_RED='' C_GREEN='' C_YELLOW='' C_BLUE='' C_PURPLE='' C_CYAN='' C_WHITE='' C_GRAY=''
  readonly S_SUCCESS="[OK]" S_ERROR="[ERR]" S_WARN="[WARN]" S_INFO="[INFO]" S_ARROW="->" S_BULLET="*"
fi

# Logging System
log::init() {
  local log_file="${1:-"$LOG_FILE"}"
  mkdir -p "$(dirname "$log_file")"
  exec 3>>"$log_file"
  # Cleanup old logs
  find "$(dirname "$log_file")" -name "nixos-install*.log" -mtime +7 -delete 2>/dev/null || true
}

log() {
  local level="$1"
  shift
  local msg="$*"
  local timestamp=$(date '+%H:%M:%S')

  # Console Output
  case "$level" in
  INFO) printf "${C_BLUE}${S_INFO}  ${C_RESET}%b\n" "$msg" ;;
  SUCCESS) printf "${C_GREEN}${S_SUCCESS}  ${C_RESET}%b\n" "$msg" ;;
  WARN) printf "${C_YELLOW}${S_WARN}  ${C_RESET}%b\n" "$msg" ;;
  ERROR) printf "${C_RED}${S_ERROR}  ${C_RESET}%b\n" "$msg" >&2 ;;
  STEP) printf "\n${C_PURPLE}${S_ARROW}  ${C_BOLD}%b${C_RESET}\n" "$msg" ;;
  DEBUG) [[ "${DEBUG:-false}" == "true" ]] && printf "${C_GRAY}${S_BULLET}  %b${C_RESET}\n" "$msg" ;;
  esac

  # File Output
  if [[ -e /proc/self/fd/3 ]]; then
    # Strip color codes for log file
    local clean_msg=$(echo "$msg" | sed 's/\x1b\[[0-9;]*m//g')
    echo "[$timestamp] [$level] $clean_msg" >&3
  fi
}

header() {
  clear
  echo -e "${C_CYAN}"
  cat <<'EOF'
    NixOS Config Manager
EOF
  echo -e "${C_RESET}"
  echo -e "${C_DIM}    v${VERSION} | ${WORK_DIR}${C_RESET}\n"
}

hr() {
  printf "${C_DIM}%*s${C_RESET}\n" "$(tput cols)" '' | tr ' ' '─'
}

# Helpers
confirm() {
  local msg="${1:-Are you sure?}"
  [[ "${CONFIG[AUTO_MODE]:-false}" == "true" ]] && return 0

  printf "${C_YELLOW}?${C_RESET} %s ${C_DIM}[y/N]${C_RESET} " "$msg"
  read -r -n 1 response
  echo
  [[ "${response,,}" == "y" ]]
}

has_command() { command -v "$1" &>/dev/null; }

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
      log INFO "Available hosts under ${system_dir}:"
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

  # Validate host against flake structure
  host::validate "$hostname" || return 1

  cd "${CONFIG[FLAKE_DIR]}" || return 1

  # 1. Git Check
  git::ensure_clean "${CONFIG[FLAKE_DIR]}"

  # 2. Construct Command
  local cmd="sudo nixos-rebuild switch --flake .#${hostname}"
  [[ -n "$profile" ]] && cmd+=" --profile-name ${profile}"

  cmd+=" --option accept-flake-config true"
  cmd+=" --option warn-dirty false"

  # 3. Build
  log STEP "Building System Configuration"
  log INFO "Host:    ${C_BOLD}${C_WHITE}$hostname${C_RESET}"
  [[ -n "$profile" ]] && log INFO "Profile: ${C_CYAN}$profile${C_RESET}"
  log INFO "Dir:     ${CONFIG[FLAKE_DIR]}"

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

cmd_pre-install() {
  local hostname="${1:-$(config::get HOSTNAME)}"
  [[ -z "$hostname" ]] && {
    log ERROR "Hostname required (use --host or -H)."
    return 1
  }

  # Validate host directory before touching /etc/nixos
  host::validate "$hostname" || return 1

  header
  log STEP "Bootstrap Initial Configuration"

  if [[ $EUID -eq 0 ]]; then
    log ERROR "Run as normal user, NOT root."
    return 1
  fi

  local template_path="${CONFIG[FLAKE_DIR]:-$WORK_DIR}/hosts/${hostname}/templates/initial-configuration.nix"
  if [[ ! -f "$template_path" ]]; then
    log ERROR "Template not found: $template_path"
    return 1
  fi

  if [[ -f /etc/nixos/configuration.nix ]]; then
    local backup="/etc/nixos/configuration.nix.bak-$(date +%s)"
    log WARN "Backing up existing config to: $(basename "$backup")"
    sudo cp /etc/nixos/configuration.nix "$backup"
  fi

  log INFO "Installing configuration..."
  sudo cp "$template_path" /etc/nixos/configuration.nix
  sudo chown root:root /etc/nixos/configuration.nix
  sudo chmod 644 /etc/nixos/configuration.nix

  if [[ ! -f /etc/nixos/hardware-configuration.nix ]]; then
    log INFO "Generating hardware config..."
    sudo nixos-generate-config --root /
  fi

  log SUCCESS "Bootstrap ready!"
  echo -e "\n${C_YELLOW}Next:${C_RESET} sudo nixos-install  ${C_DIM}(or 'nixos-rebuild switch' if live)${C_RESET}"
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

  # Default Source to Current if not provided
  if [[ -z "$source_branch" ]]; then
    source_branch="$current_branch"
  fi

  # Interactive Selection ONLY if Target is missing
  if [[ -z "$target_branch" ]]; then
    # Fetch latest branches
    git fetch -p >/dev/null 2>&1

    # List local and remote branches, removing duplicates and 'origin/HEAD'
    mapfile -t branches < <(git branch -a --format='%(refname:short)' | grep -v 'origin/HEAD' | sed 's/^origin\///' | sort -u)

    echo -e "\n${C_CYAN}Available Branches (Local & Remote):${C_RESET}"
    local i=0
    for branch in "${branches[@]}"; do
      echo "  $i) $branch"
      ((i++))
    done
    echo ""

    # Confirm/Change Source
    read -r -p "Select SOURCE branch [Default: $source_branch]: " src_sel
    src_sel="${src_sel:-$source_branch}"

    if [[ "$src_sel" =~ ^[0-9]+$ ]] && ((src_sel < ${#branches[@]})); then
      source_branch="${branches[$src_sel]}"
    else
      source_branch="$src_sel"
    fi

    # Select Target
    while [[ -z "$target_branch" ]]; do
      read -r -p "Select TARGET branch (name or number): " tgt_sel
      if [[ -z "$tgt_sel" ]]; then continue; fi

      if [[ "$tgt_sel" =~ ^[0-9]+$ ]] && ((tgt_sel < ${#branches[@]})); then
        target_branch="${branches[$tgt_sel]}"
      else
        target_branch="$tgt_sel"
      fi
    done
  fi

  # Validation (Allow remote branches via rev-parse)
  if [[ "$source_branch" == "$target_branch" ]]; then
    log ERROR "Source and Target cannot be the same ($source_branch)."
    return 1
  fi

  log INFO "Source: ${C_BOLD}${source_branch}${C_RESET}"
  log INFO "Target: ${C_BOLD}${target_branch}${C_RESET}"

  if ! git rev-parse --verify "$source_branch" >/dev/null 2>&1; then
    log ERROR "Source branch '$source_branch' not found."
    return 1
  fi

  # Check if target exists locally or remotely
  if ! git rev-parse --verify "$target_branch" >/dev/null 2>&1; then
    # Try origin/target if local doesn't exist
    if git rev-parse --verify "origin/$target_branch" >/dev/null 2>&1; then
      log WARN "Branch '$target_branch' found on remote, will be created locally."
    else
      log ERROR "Target branch '$target_branch' not found locally or on remote."
      return 1
    fi
  fi

  # Clean working directory check
  if [[ -n "$(git status --porcelain)" ]]; then
    log WARN "Working directory is dirty."
    if [[ "$auto_yes" != "true" ]] && ! confirm "Continue anyway?"; then
      log ERROR "Operation aborted."
      return 1
    fi
  fi

  # 3. Switch and Merge
  log INFO "Switching to target branch..."
  git checkout "$target_branch" || return 1

  log INFO "Merging source branch (no commit)..."
  if ! git merge --no-commit --no-ff "$source_branch"; then
    log ERROR "Merge encountered conflicts!"
    echo -e "${C_RED}Conflicting files:${C_RESET}"
    git diff --name-only --diff-filter=U | sed 's/^/  - /'
    echo ""
    log WARN "The script cannot continue automatically."
    log INFO "Please resolve conflicts manually, then commit and push."
    return 1
  fi

  # 4. Handle Excludes
  log INFO "Processing excluded files..."
  for file in "${EXCLUDE_FILES[@]}"; do
    if [[ -f "$file" ]]; then
      log DEBUG "Excluding: $file"
      git reset HEAD "$file" 2>/dev/null || true
      git checkout HEAD -- "$file" 2>/dev/null || true
    fi
  done

  # 5. Show Changes
  log STEP "Merge Summary"
  local staged_files=$(git diff --cached --name-only)

  if [[ -z "$staged_files" ]]; then
    log SUCCESS "Branches are already in sync (except excluded files)."

    if [[ "$current_branch" != "$target_branch" ]]; then
      git checkout "$current_branch"
    fi
    return 0
  fi

  echo -e "${C_GREEN}Files to merge:${C_RESET}"
  echo "$staged_files" | sed 's/^/  + /'

  # 6. Commit Confirmation
  if [[ "$auto_yes" == "true" ]] || confirm "Commit these changes?"; then
    local excluded_list=""
    for f in "${EXCLUDE_FILES[@]}"; do
      excluded_list+="- $f\n"
    done

    local commit_msg="Merge from $source_branch to $target_branch (excluding specific files)\n\nExcluded files:\n$excluded_list\nAuto-generated by install.sh"

    git commit -m "$commit_msg"
    log SUCCESS "Merge committed."

    # 7. Push Target
    if [[ "$auto_yes" == "true" ]] || confirm "Push $target_branch to remote?"; then
      git push && log SUCCESS "Pushed $target_branch."
    fi
  else
    log WARN "Merge aborted. Changes are staged."
    log INFO "Use 'git reset --hard HEAD' to undo."
    return 1
  fi

  # 8. Switch Back
  if [[ "$current_branch" != "$target_branch" ]]; then
    if [[ "$auto_yes" == "true" ]] || confirm "Switch back to $current_branch?"; then

      # Stash any excluded file changes to allow checkout
      if [[ -n "$(git status --porcelain)" ]]; then
        log INFO "Stashing excluded file changes for checkout..."
        git stash push -m "Auto-stash by install.sh merge" >/dev/null
      fi

      git checkout "$current_branch"

      # Restore stash if it was ours
      # Note: We might not want to pop if the user wants to keep those exclusions clean
      # But usually, we just want to go back.

      if [[ "$auto_yes" == "true" ]] || confirm "Push $current_branch as well?"; then
        git push && log SUCCESS "Pushed $current_branch."
      fi
    fi
  fi
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

  # Build System
  if flake::build "$hostname"; then
    show_summary
  else
    log ERROR "Installation aborted due to errors."
    exit 1
  fi
}

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
  
  # Manually aligned output with echo -e to prevent printf color code issues
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
  echo ""
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
  echo "  update           Update flake inputs"
  echo "  build            Build only"
  echo "  merge            Merge branches (interactively)"
  echo "  hosts            List available hosts (from ./hosts)"
  echo "  --pre-install    Bootstrap system"
  echo ""
  echo -e "${C_BOLD}Options:${C_RESET}"
  echo "  -H, --host NAME  Hostname (hay, vhay)"
  echo "  -p, --profile X  Profile name"
  echo "  -u, --update     Update inputs before install"
  echo "  -a, --auto       Non-interactive mode"
  echo "  -m, --merge      Run merge after install (or standalone)"
}

parse_args() {
  # Compatibility: Flags first -> implied 'install'
  # BUT verify it's not a standalone command flag like help or merge
  if [[ "${1:-}" =~ ^- ]] && [[ "$1" != "-h" ]] && [[ "$1" != "--help" ]] && [[ "$1" != "-m" ]] && [[ "$1" != "--merge" ]]; then
    set -- "install" "$@"
  fi

  local action=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
    install)
      action="install"
      # Handle implied hostname (install hay)
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
      ;;
    merge)
      shift
      local auto_yes="false"
      local src=""
      local tgt=""

      # Parse remaining args for merge
      while [[ $# -gt 0 ]]; do
        case "$1" in
        -y | --yes) auto_yes="true" ;;
        -*) ;; # Ignore other flags
        *)
          if [[ -z "$src" ]]; then
            src="$1"
          elif [[ -z "$tgt" ]]; then
            tgt="$1"
          fi
          ;;
        esac
        shift
      done

      # Smart defaulting: if only one arg provided, assume it's TARGET, and SOURCE is current
      if [[ -n "$src" ]] && [[ -z "$tgt" ]]; then
        tgt="$src"
        src="" # Will be auto-detected as current in cmd_merge
      fi

      cmd_merge "$auto_yes" "$src" "$tgt"
      exit 0
      ;;
    --pre-install) cmd_pre-install ;;

    # Flags
    -u | --update) config::set UPDATE_FLAKE true ;;
    -m | --merge)
      shift
      local auto_yes="false"
      local src=""
      local tgt=""

      while [[ $# -gt 0 ]]; do
        case "$1" in
        -y | --yes) auto_yes="true" ;;
        -*) break ;; # Stop at next flag (e.g. -H)
        *)
          if [[ -z "$src" ]]; then
            src="$1"
          elif [[ -z "$tgt" ]]; then
            tgt="$1"
          fi
          ;;
        esac
        shift
      done

      # Smart defaulting: if only one arg provided, assume it's TARGET, and SOURCE is current
      if [[ -n "$src" ]] && [[ -z "$tgt" ]]; then
        tgt="$src"
        src="" # Will be auto-detected as current in cmd_merge
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
      # Handle -a hostname
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
  6) host::list; read -r -p "Press Enter to continue..." _ ;;
  q) exit 0 ;;
  *) show_menu ;;
  esac
}

main() {
  log::init
  config::load
  if [[ $# -gt 0 ]]; then
    parse_args "$@"
  else
    show_menu
  fi
}

main "$@"
