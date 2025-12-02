#!/usr/bin/env bash
# Hyprland / Walker / Elephant Updater Script with Git Auto-Commit
set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

FLAKE_PATH="$HOME/.nixosc/flake.nix"
NIXOS_PATH="$HOME/.nixosc"
MAX_HISTORY=5 # How many old Hyprland commits to keep as commented history

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }

print_usage() {
  echo -e "${YELLOW}Usage:${NC} $(basename "$0") {hypr|hyprland|walker}"
  echo
  echo "  hypr / hyprland : Update Hyprland input to latest commit on main"
  echo "  walker          : Update Walker and Elephant to their latest GitHub releases"
}

# ---------------------------------------------------------------------------
# Git helpers
# ---------------------------------------------------------------------------

check_git_repo() {
  if [[ ! -d "$NIXOS_PATH/.git" ]]; then
    log_warning "Git repository not found. Initializing new repo..."
    cd "$NIXOS_PATH"
    git init
    git add .
    git commit -m "Initial commit"
    log_success "Git repository initialized"
  fi
}

git_commit_changes() {
  local commit_msg="$1"

  cd "$NIXOS_PATH"

  # Only look at flake.nix for changes
  if git diff --quiet "$FLAKE_PATH"; then
    log_info "No changes in flake.nix, skipping git commit"
    return
  fi

  log_info "Creating git commit..."
  git add "$FLAKE_PATH"

  if git commit -m "$commit_msg"; then
    log_success "Git commit created: $commit_msg"
    log_info "Last commits:"
    git log --oneline -3 --color=always
  else
    log_error "Git commit failed!"
  fi
}

backup_flake() {
  mkdir -p "$HOME/.nixosb"
  local backup_file="$HOME/.nixosb/flake.nix.backup.$(date +%Y%m%d_%H%M%S)"
  cp "$FLAKE_PATH" "$backup_file"
  log_info "Backup created: $backup_file"
}

# ---------------------------------------------------------------------------
# Hyprland specific: commit getter and flake updater
# ---------------------------------------------------------------------------

# Get latest Hyprland commit hash from GitHub
get_latest_hypr_commit() {
  local response
  response=$(curl -s --max-time 30 "https://api.github.com/repos/hyprwm/Hyprland/commits/main")
  if [[ -z "$response" ]]; then
    log_error "Failed to reach GitHub API for Hyprland"
    exit 1
  fi

  local commit_hash
  commit_hash=$(echo "$response" | sed -n 's/.*"sha":[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)
  if [[ -z "$commit_hash" ]]; then
    log_error "Could not extract Hyprland commit hash"
    exit 1
  fi
  echo "${commit_hash:0:40}"
}

# Get current Hyprland commit from flake.nix
get_current_hypr_commit() {
  local current_hash
  # Try active URL first
  current_hash=$(
    command grep 'url = "github:hyprwm/hyprland/' "$FLAKE_PATH" |
      command grep -v '^[[:space:]]*#' |
      head -1 |
      sed 's/.*\/\([^"]*\)".*/\1/'
  )

  # Fallback to last commented URL if no active one
  if [[ -z "$current_hash" ]]; then
    current_hash=$(
      command grep '#.*url = "github:hyprwm/hyprland/' "$FLAKE_PATH" |
        tail -1 |
        sed 's/.*\/\([^"]*\)".*/\1/'
    )
  fi
  echo "${current_hash:-unknown}"
}

# Update Hyprland input in flake.nix and keep MAX_HISTORY commented URLs
update_hypr_flake() {
  local new_commit="$1"
  local today
  today=$(date +%m%d)

  log_info "Updating Hyprland section in flake.nix..."
  backup_flake

  python3 -c "
import re

flake_path = '$FLAKE_PATH'
max_history = $MAX_HISTORY
new_commit = '$new_commit'
today = '$today'

with open(flake_path, 'r') as f:
    content = f.read()

lines = content.split('\n')
new_lines = []
in_hyprland = False
url_lines = []

for line in lines:
    if 'hyprland = {' in line:
        in_hyprland = True
        new_lines.append(line)
    elif in_hyprland and 'url = \"github:hyprwm/hyprland/' in line:
        # Collect existing URL lines
        url_lines.append(line.strip())
    elif in_hyprland and line.strip() == '};':
        # Insert new URL at the top
        new_lines.append(f'      url = \"github:hyprwm/hyprland/{new_commit}\"; # {today} - Updated commit')

        # Add old URLs as comments (up to max_history)
        count = 0
        for url_line in url_lines:
            if count >= max_history:
                break

            if url_line.startswith('#'):
                cleaned = re.sub(r'^#+\\s*', '#      ', url_line)
                new_lines.append(cleaned)
            else:
                new_lines.append('#      ' + url_line)
            count += 1

        new_lines.append(line)
        in_hyprland = False
        url_lines = []
    elif not (in_hyprland and 'url = \"github:hyprwm/hyprland/' in line):
        new_lines.append(line)

with open(flake_path, 'w') as f:
    f.write('\n'.join(new_lines))
"
}

update_hyprland() {
  log_info "Hyprland commit updater starting..."

  local current_commit
  current_commit=$(get_current_hypr_commit)
  log_info "Current Hyprland commit: $current_commit"

  local latest_commit
  latest_commit=$(get_latest_hypr_commit)
  log_info "Latest Hyprland commit:  $latest_commit"

  if [[ "$current_commit" == "$latest_commit" ]]; then
    log_success "Hyprland is already at the latest commit."
    exit 0
  fi

  update_hypr_flake "$latest_commit"

  if command grep -q "url = \"github:hyprwm/hyprland/$latest_commit\"" "$FLAKE_PATH"; then
    log_success "flake.nix updated successfully for Hyprland!"
    log_info "Old commit: $current_commit"
    log_info "New commit: $latest_commit"

    local commit_date
    commit_date=$(date +%m%d)
    git_commit_changes "hyprland: update to latest $commit_date"

    echo
    log_info "To rebuild:"
    echo -e "${YELLOW}cd ~/.nixosc && sudo nixos-rebuild switch --flake .#$(hostname)${NC}"
    echo
    log_info "To push:"
    echo -e "${YELLOW}cd ~/.nixosc && git push${NC}"
  else
    log_error "Hyprland update failed: new URL not found in flake.nix!"
    exit 1
  fi
}

# ---------------------------------------------------------------------------
# Walker / Elephant: release getter and flake updater
# ---------------------------------------------------------------------------

# Get latest GitHub release tag (e.g. v2.11.1)
get_latest_release_tag() {
  local repo="$1" # e.g. abenz1267/walker
  local response
  response=$(curl -s --max-time 30 "https://api.github.com/repos/$repo/releases/latest")
  if [[ -z "$response" ]]; then
    log_error "Failed to reach GitHub API for $repo"
    exit 1
  fi

  local tag
  tag=$(echo "$response" | sed -n 's/.*"tag_name":[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)
  if [[ -z "$tag" ]]; then
    log_error "Could not extract latest release tag for $repo"
    exit 1
  fi
  echo "$tag"
}

# Get current version (tag) for a given github:owner/repo input
get_current_repo_version() {
  local repo="$1" # e.g. abenz1267/walker
  local current

  # Active (non-commented) line
  current=$(
    command grep "url = \"github:$repo/" "$FLAKE_PATH" 2>/dev/null |
      command grep -v '^[[:space:]]*#' |
      head -1 |
      sed 's#.*'"$repo"'/\([^"]*\)".*#\1#'
  )

  # Fallback: last commented line
  if [[ -z "$current" ]]; then
    current=$(
      command grep "#.*url = \"github:$repo/" "$FLAKE_PATH" 2>/dev/null |
        tail -1 |
        sed 's#.*'"$repo"'/\([^"]*\)".*#\1#'
    )
  fi

  echo "${current:-unknown}"
}

# Update url = "github:<repo>/<tag>"; for all occurrences (active + commented)
update_repo_url() {
  local repo="$1"    # e.g. abenz1267/walker
  local new_tag="$2" # e.g. v2.11.1

  python3 - "$FLAKE_PATH" "$repo" "$new_tag" <<'PY'
import sys
import re
from pathlib import Path

flake_path, repo, tag = sys.argv[1:]
path = Path(flake_path)
content = path.read_text()

pattern = rf'(url = "github:{re.escape(repo)}/)[^"]*(";)'  # match any current tag
new_content, count = re.subn(pattern, rf'\1{tag}\2', content)

if count == 0:
    # Nothing updated -> signal error to caller
    sys.exit(1)

path.write_text(new_content)
PY
}

update_walker_and_elephant() {
  log_info "Walker / Elephant release updater starting..."

  backup_flake

  local walker_repo="abenz1267/walker"
  local elephant_repo="abenz1267/elephant"

  local current_walker current_elephant
  local latest_walker latest_elephant
  local updated_any=false

  current_walker=$(get_current_repo_version "$walker_repo")
  current_elephant=$(get_current_repo_version "$elephant_repo")

  log_info "Current Walker version:   $current_walker"
  log_info "Current Elephant version: $current_elephant"

  latest_walker=$(get_latest_release_tag "$walker_repo")
  latest_elephant=$(get_latest_release_tag "$elephant_repo")

  log_info "Latest Walker release:    $latest_walker"
  log_info "Latest Elephant release:  $latest_elephant"

  # Walker update
  if [[ "$current_walker" == "$latest_walker" ]]; then
    log_success "Walker is already at latest release."
  else
    log_info "Updating Walker to $latest_walker..."
    if update_repo_url "$walker_repo" "$latest_walker"; then
      log_success "Walker updated in flake.nix."
      updated_any=true
    else
      log_error "Failed to update Walker url in flake.nix (pattern not found)."
    fi
  fi

  # Elephant update
  if [[ "$current_elephant" == "$latest_elephant" ]]; then
    log_success "Elephant is already at latest release."
  else
    log_info "Updating Elephant to $latest_elephant..."
    if update_repo_url "$elephant_repo" "$latest_elephant"; then
      log_success "Elephant updated in flake.nix."
      updated_any=true
    else
      log_error "Failed to update Elephant url in flake.nix (pattern not found)."
    fi
  fi

  if [[ "$updated_any" != true ]]; then
    log_info "No Walker/Elephant changes detected; nothing to commit."
    return
  fi

  # Quick sanity check
  if ! command grep -q "url = \"github:$walker_repo/$latest_walker\"" "$FLAKE_PATH"; then
    log_warning "Walker new version not clearly visible in flake.nix; double-check manually."
  fi
  if ! command grep -q "url = \"github:$elephant_repo/$latest_elephant\"" "$FLAKE_PATH"; then
    log_warning "Elephant new version not clearly visible in flake.nix; double-check manually."
  fi

  local commit_msg
  commit_msg="walker/elephant: bump to latest releases (walker: $latest_walker, elephant: $latest_elephant)"
  git_commit_changes "$commit_msg"

  echo
  log_info "If these inputs are used in your NixOS/Home-Manager config, you probably want to rebuild:"
  echo -e "${YELLOW}cd ~/.nixosc && sudo nixos-rebuild switch --flake .#$(hostname)${NC}"
  echo
  log_info "To push:"
  echo -e "${YELLOW}cd ~/.nixosc && git push${NC}"
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

main() {
  if [[ ! -f "$FLAKE_PATH" ]]; then
    log_error "flake.nix not found at: $FLAKE_PATH"
    exit 1
  fi

  if [[ $# -lt 1 ]]; then
    print_usage
    exit 1
  fi

  local target="$1"
  check_git_repo

  case "$target" in
  hypr | hyprland)
    update_hyprland
    ;;
  walker)
    # As requested: 'walker' updates BOTH walker and elephant
    update_walker_and_elephant
    ;;
  *)
    log_error "Unknown target: $target"
    print_usage
    exit 1
    ;;
  esac
}

main "$@"
