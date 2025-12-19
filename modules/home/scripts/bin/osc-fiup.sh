#!/usr/bin/env bash
# Hyprland / Niri / Walker / Elephant / DankMaterialShell Updater Script with Git Auto-Commit
set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

FLAKE_PATH="$HOME/.nixosc/flake.nix"
NIXOS_PATH="$HOME/.nixosc"
MAX_HISTORY=5

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }

print_usage() {
  echo -e "${YELLOW}Usage:${NC} $(basename "$0") {all|hypr|hyprland|niri|walker|dank}"
  echo
  echo "  all             : Apply dank + niri + hyprland + walker (in that order)"
  echo "  hypr / hyprland : Update Hyprland input to latest commit on main"
  echo "  niri            : Update Niri input to latest commit on main"
  echo "  walker          : Update Walker and Elephant to their latest GitHub releases"
  echo "  dank            : Update DankMaterialShell to latest commit on main"
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
# Generic commit-based updater
# ---------------------------------------------------------------------------

get_latest_commit() {
  local repo="$1"
  local branch="${2:-main}"
  local response=""

  # NOTE: We intentionally do `|| true` here; with `set -e`, a failing curl in a
  # command-substitution would otherwise exit the whole script before we can
  # print a helpful error.
  response="$(
    curl -fsSL --max-time 30 \
      -H "Accept: application/vnd.github+json" \
      "https://api.github.com/repos/$repo/commits/$branch" 2>/dev/null || true
  )"

  local commit_hash
  commit_hash=$(echo "$response" | sed -n 's/.*"sha":[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)
  if [[ -n "$commit_hash" ]]; then
    echo "${commit_hash:0:40}"
    return 0
  fi

  # Fallback: GitHub API can fail due to rate limits / captive portals / no net.
  # Use `git ls-remote` which often works even when the API is blocked.
  local remote_hash=""
  remote_hash="$(
    GIT_TERMINAL_PROMPT=0 git ls-remote "https://github.com/$repo.git" "refs/heads/$branch" 2>/dev/null |
      awk 'NR==1{print $1}' || true
  )"
  if [[ -n "$remote_hash" ]]; then
    echo "${remote_hash:0:40}"
    return 0
  fi

  log_error "Could not resolve latest commit for $repo ($branch). Network blocked or GitHub rate-limited?"
  exit 1
}

get_current_commit() {
  local repo="$1"
  local url_line

  # Try active URL first
  url_line=$(
    command grep "url = \"github:$repo" "$FLAKE_PATH" 2>/dev/null |
      command grep -v '^[[:space:]]*#' |
      head -1
  )

  # Fallback to last commented URL
  if [[ -z "$url_line" ]]; then
    url_line=$(
      command grep "#.*url = \"github:$repo" "$FLAKE_PATH" 2>/dev/null |
        tail -1
    )
  fi

  if [[ -z "$url_line" ]]; then
    echo "unknown"
    return
  fi

  # Extract commit hash if present (40 hex chars after repo/)
  if [[ "$url_line" =~ github:$repo/([a-f0-9]{40}) ]]; then
    echo "${BASH_REMATCH[1]}"
  # Or any ref after repo/
  elif [[ "$url_line" =~ github:$repo/([^\"\;]+) ]]; then
    echo "${BASH_REMATCH[1]}"
  # No ref, just repo URL
  else
    echo "none"
  fi
}

update_commit_flake() {
  local input_name="$1"
  local repo="$2"
  local new_commit="$3"
  local today
  today=$(date +%m%d)

  log_info "Updating $input_name section in flake.nix..."
  backup_flake

  python3 <<PYEOF
import re

flake_path = '$FLAKE_PATH'
max_history = $MAX_HISTORY
new_commit = '$new_commit'
today = '$today'
input_name = '$input_name'
repo = '$repo'

with open(flake_path, 'r') as f:
    content = f.read()

lines = content.split('\n')
new_lines = []
in_input = False
url_lines = []
found_input = False

for i, line in enumerate(lines):
    # Match input block start
    if re.match(rf'\s*{re.escape(input_name)}\s*=\s*\{{', line):
        in_input = True
        found_input = True
        new_lines.append(line)
        continue
    
    if in_input:
        # Collect URL lines (both active and commented)
        if f'github:{repo}' in line:
            url_lines.append(line.strip())
            continue
        
        # End of input block
        if line.strip() == '};':
            # Insert new URL
            new_lines.append(f'      url = "github:{repo}/{new_commit}"; # {today} - Updated commit')
            
            # Add old URLs as comments (up to max_history)
            count = 0
            for url_line in url_lines:
                if count >= max_history:
                    break
                if url_line.startswith('#'):
                    new_lines.append('      ' + url_line)
                else:
                    new_lines.append('#      ' + url_line)
                count += 1
            
            new_lines.append(line)
            in_input = False
            url_lines = []
            continue
    
    new_lines.append(line)

if not found_input:
    print(f"ERROR: Input '{input_name}' not found in flake.nix")
    exit(1)

with open(flake_path, 'w') as f:
    f.write('\n'.join(new_lines))
PYEOF
}

update_commit_input() {
  local input_name="$1"
  local repo="$2"
  local repo_lower="$3"
  local branch="${4:-main}"
  local display_name="$5"

  log_info "$display_name commit updater starting..."

  local current_commit
  current_commit=$(get_current_commit "$repo_lower")
  log_info "Current $display_name commit: $current_commit"

  local latest_commit
  latest_commit=$(get_latest_commit "$repo" "$branch")
  log_info "Latest $display_name commit:  $latest_commit"

  if [[ "$current_commit" == "$latest_commit" ]]; then
    log_success "$display_name is already at the latest commit."
    return 0
  fi

  update_commit_flake "$input_name" "$repo_lower" "$latest_commit"

  if command grep -q "github:$repo_lower/$latest_commit" "$FLAKE_PATH"; then
    log_success "flake.nix updated successfully for $display_name!"
    log_info "Old commit: $current_commit"
    log_info "New commit: $latest_commit"

    git_commit_changes "$input_name: update to latest $(date +%m%d)"

    echo
    log_info "To rebuild:"
    echo -e "${YELLOW}cd ~/.nixosc && sudo nixos-rebuild switch --flake .#\$(hostname)${NC}"
    echo
    log_info "To push:"
    echo -e "${YELLOW}cd ~/.nixosc && git push${NC}"
  else
    log_error "$display_name update failed: new URL not found in flake.nix!"
    exit 1
  fi
}

update_hyprland() {
  update_commit_input "hyprland" "hyprwm/Hyprland" "hyprwm/hyprland" "main" "Hyprland"
}

update_niri() {
  update_commit_input "niri" "YaLTeR/niri" "YaLTeR/niri" "main" "Niri"
}

update_dank() {
  update_commit_input "dankMaterialShell" "AvengeMedia/DankMaterialShell" "AvengeMedia/DankMaterialShell" "master" "DankMaterialShell"
}

# ---------------------------------------------------------------------------
# Walker / Elephant
# ---------------------------------------------------------------------------

get_latest_release_tag() {
  local repo="$1"
  local response=""
  response="$(
    curl -fsSL --max-time 30 \
      -H "Accept: application/vnd.github+json" \
      "https://api.github.com/repos/$repo/releases/latest" 2>/dev/null || true
  )"
  if [[ -z "$response" ]]; then
    log_error "Failed to reach GitHub API for $repo (no network / rate limit?)"
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

get_current_repo_version() {
  local repo="$1"
  local current

  current=$(
    command grep "url = \"github:$repo/" "$FLAKE_PATH" 2>/dev/null |
      command grep -v '^[[:space:]]*#' |
      head -1 |
      sed 's#.*'"$repo"'/\([^"]*\)".*#\1#'
  )

  if [[ -z "$current" ]]; then
    current=$(
      command grep "#.*url = \"github:$repo/" "$FLAKE_PATH" 2>/dev/null |
        tail -1 |
        sed 's#.*'"$repo"'/\([^"]*\)".*#\1#'
    )
  fi

  echo "${current:-unknown}"
}

update_repo_url() {
  local repo="$1"
  local new_tag="$2"

  python3 - "$FLAKE_PATH" "$repo" "$new_tag" <<'PY'
import sys
import re
from pathlib import Path

flake_path, repo, tag = sys.argv[1:]
path = Path(flake_path)
content = path.read_text()

pattern = rf'(url = "github:{re.escape(repo)}/)[^"]*(";)'
new_content, count = re.subn(pattern, rf'\1{tag}\2', content)

if count == 0:
    sys.exit(1)

path.write_text(new_content)
PY
}

update_walker_and_elephant() {
  log_info "Walker / Elephant release updater starting..."

  backup_flake

  local walker_repo="abenz1267/walker"
  local elephant_repo="abenz1267/elephant"
  local updated_any=false

  local current_walker current_elephant
  local latest_walker latest_elephant

  current_walker=$(get_current_repo_version "$walker_repo")
  current_elephant=$(get_current_repo_version "$elephant_repo")

  log_info "Current Walker version:   $current_walker"
  log_info "Current Elephant version: $current_elephant"

  latest_walker=$(get_latest_release_tag "$walker_repo")
  latest_elephant=$(get_latest_release_tag "$elephant_repo")

  log_info "Latest Walker release:    $latest_walker"
  log_info "Latest Elephant release:  $latest_elephant"

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

  git_commit_changes "walker/elephant: bump to latest releases (walker: $latest_walker, elephant: $latest_elephant)"

  echo
  log_info "To rebuild:"
  echo -e "${YELLOW}cd ~/.nixosc && sudo nixos-rebuild switch --flake .#\$(hostname)${NC}"
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
  all)
    update_dank
    update_niri
    update_hyprland
    update_walker_and_elephant
    ;;
  hypr | hyprland)
    update_hyprland
    ;;
  niri)
    update_niri
    ;;
  walker)
    update_walker_and_elephant
    ;;
  dank | dankmaterialshell)
    update_dank
    ;;
  *)
    log_error "Unknown target: $target"
    print_usage
    exit 1
    ;;
  esac
}

main "$@"
