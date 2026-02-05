#!/usr/bin/env bash
# Hyprland / Niri / Walker / Elephant / DankMaterialShell / Stasis Updater Script with Git Auto-Commit
set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

FLAKE_PATH="$HOME/.nixosc/flake.nix"
LOCK_PATH="$HOME/.nixosc/flake.lock"
NIXOS_PATH="$HOME/.nixosc"
MAX_HISTORY=5

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }

print_usage() {
  echo -e "${YELLOW}Usage:${NC} $(basename "$0") {all|hypr|hyprland|niri|walker|dank|stasis} [stable] [tag]"
  echo
  echo "  all             : Apply dank + niri + nixpkgs-unstable + walker (in that order)"
  echo "  hypr / hyprland : Update nixpkgs-unstable lock (Hyprland + plugins)"
  echo "  niri            : Update Niri input to latest commit on main"
  echo "  walker          : Update Walker and Elephant to their latest GitHub releases"
  echo "  dank            : Update DankMaterialShell to latest commit on main"
  echo "  stasis          : Update nixpkgs-unstable lock (Stasis via nixpkgs-unstable)"
  echo
  echo "Stable mode:"
  echo "  niri stable     : Pin Niri to latest GitHub release tag (e.g. v25.11)"
  echo "  <target> stable <tag> : Pin explicitly (skip network)"
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

  local changed_files=()
  if ! git diff --quiet "$FLAKE_PATH"; then
    changed_files+=("$FLAKE_PATH")
  fi
  if [[ -f "$LOCK_PATH" ]] && ! git diff --quiet "$LOCK_PATH"; then
    changed_files+=("$LOCK_PATH")
  fi

  if [[ ${#changed_files[@]} -eq 0 ]]; then
    log_info "No changes in flake.{nix,lock}, skipping git commit"
    return
  fi

  log_info "Creating git commit..."
  git add "${changed_files[@]}"

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
  local new_ref="$3"
  local ref_label="${4:-commit}"
  local today
  today=$(date +%m%d)

  log_info "Updating $input_name section in flake.nix..."
  backup_flake

  python3 <<PYEOF
import re

flake_path = '$FLAKE_PATH'
max_history = $MAX_HISTORY
new_ref = '$new_ref'
today = '$today'
input_name = '$input_name'
repo = '$repo'
ref_label = '$ref_label'

with open(flake_path, 'r') as f:
    content = f.read()

lines = content.split('\n')
new_lines = []
in_input = False
url_lines = []
active_key = None
indent = None
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
            stripped = line.strip()
            url_lines.append(stripped)

            # Capture indentation + attribute key from the first active line.
            if active_key is None and not stripped.startswith('#'):
                m = re.match(rf'\s*([A-Za-z0-9_.-]+)\s*=\s*"github:{re.escape(repo)}/[^"]+"\s*;.*$', line)
                if m:
                    active_key = m.group(1)
                    indent = re.match(r'^(\s*)', line).group(1)
            continue
        
        # End of input block
        if line.strip() == '};':
            if active_key is None:
                # Fallback: derive key from the first commented URL line.
                for u in url_lines:
                    candidate = re.sub(r'^\s*#\s*', '', u)
                    m = re.match(rf'([A-Za-z0-9_.-]+)\s*=\s*"github:{re.escape(repo)}/[^"]+"\s*;.*$', candidate)
                    if m:
                        active_key = m.group(1)
                        break

            if active_key is None:
                print(f"ERROR: Could not determine attribute key to update for repo '{repo}' in input '{input_name}'")
                exit(1)

            if indent is None:
                indent = "      "

            # Insert new URL
            new_lines.append(f'{indent}{active_key} = "github:{repo}/{new_ref}"; # {today} - Updated {ref_label}')
            
            # Add old URLs as comments (up to max_history)
            count = 0
            for url_line in url_lines:
                if count >= max_history:
                    break
                u = url_line.lstrip()
                if u.startswith('#'):
                    new_lines.append(indent + u)
                else:
                    new_lines.append(indent + '# ' + u)
                count += 1
            
            new_lines.append(line)
            in_input = False
            url_lines = []
            active_key = None
            indent = None
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

  update_commit_flake "$input_name" "$repo_lower" "$latest_commit" "commit"

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

update_lock_input() {
  local input_name="$1"
  local display_name="$2"

  log_info "$display_name lock updater starting..."

  if ! command -v nix >/dev/null 2>&1; then
    log_error "nix not found in PATH; cannot update flake.lock."
    exit 1
  fi

  cd "$NIXOS_PATH"

  log_info "Running: nix flake lock --update-input $input_name"
  nix flake lock --update-input "$input_name"

  log_success "flake.lock updated for $display_name ($input_name)"
  git_commit_changes "$input_name: update lock $(date +%m%d)"

  echo
  log_info "To rebuild:"
  echo -e "${YELLOW}cd ~/.nixosc && sudo nixos-rebuild switch --flake .#\\$(hostname)${NC}"
  echo
  log_info "To push:"
  echo -e "${YELLOW}cd ~/.nixosc && git push${NC}"
}

update_hyprland() {
  local mode="${1:-}"
  local explicit_tag="${2:-}"

  if [[ -n "$explicit_tag" ]]; then
    log_warning "Hyprland is tracked via nixpkgs-unstable; explicit tags are not supported (ignored)."
  fi

  case "$mode" in
  "" | commit)
    update_lock_input "nixpkgs-unstable" "Hyprland (via nixpkgs-unstable)"
    ;;
  stable | release)
    log_warning "Hyprland stable pinning was removed; updating nixpkgs-unstable lock instead."
    update_lock_input "nixpkgs-unstable" "Hyprland (via nixpkgs-unstable)"
    ;;
  *)
    log_error "Unknown mode for hyprland: $mode"
    print_usage
    exit 1
    ;;
  esac
}

update_niri() {
  local mode="${1:-}"
  local explicit_tag="${2:-}"

  case "$mode" in
  stable | release)
    update_release_input "niri" "YaLTeR/niri" "YaLTeR/niri" "Niri" "$explicit_tag"
    ;;
  "" | commit)
    update_commit_input "niri" "YaLTeR/niri" "YaLTeR/niri" "main" "Niri"
    ;;
  *)
    log_error "Unknown mode for niri: $mode"
    print_usage
    exit 1
    ;;
  esac
}

update_dank() {
  update_commit_input "dankMaterialShell" "AvengeMedia/DankMaterialShell" "AvengeMedia/DankMaterialShell" "master" "DankMaterialShell"
}

update_stasis() {
  local mode="${1:-}"
  local explicit_tag="${2:-}"

  if [[ -n "$explicit_tag" ]]; then
    log_warning "Stasis is tracked via nixpkgs-unstable; explicit tags are not supported (ignored)."
  fi

  case "$mode" in
  "" | commit | stable | release)
    update_lock_input "nixpkgs-unstable" "Stasis (via nixpkgs-unstable)"
    ;;
  *)
    log_error "Unknown mode for stasis: $mode"
    print_usage
    exit 1
    ;;
  esac
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
  local tag
  tag=$(echo "$response" | sed -n 's/.*"tag_name":[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)
  if [[ -n "$tag" ]]; then
    echo "$tag"
    return 0
  fi

  log_warning "GitHub API release lookup failed for $repo; falling back to git ls-remote tags..."

  local tags latest
  tags="$(
    GIT_TERMINAL_PROMPT=0 git ls-remote --tags "https://github.com/$repo.git" 2>/dev/null |
      awk '{print $2}' |
      sed 's#^refs/tags/##' |
      sed 's#\\^{}##' |
      sort -u || true
  )"

  latest="$(
    printf '%s\n' "$tags" |
      command grep -E '^(v)?[0-9]+(\\.[0-9]+)*$' |
      sort -V |
      tail -n 1 || true
  )"

  if [[ -z "$latest" ]]; then
    log_error "Could not resolve a stable tag for $repo (no network / no matching tags?)"
    exit 1
  fi
  echo "$latest"
}

update_release_input() {
  local input_name="$1"
  local repo_api="$2"
  local repo_flake="$3"
  local display_name="$4"
  local explicit_tag="${5:-}"

  log_info "$display_name release updater starting..."

  local current_ref
  current_ref=$(get_current_commit "$repo_flake")
  log_info "Current $display_name ref: $current_ref"

  local tag
  tag="${explicit_tag:-$(get_latest_release_tag "$repo_api")}"
  log_info "Latest $display_name release: $tag"

  if [[ "$current_ref" == "$tag" ]]; then
    log_success "$display_name is already at release $tag."
    return 0
  fi

  update_commit_flake "$input_name" "$repo_flake" "$tag" "release"

  if command grep -q "github:$repo_flake/$tag" "$FLAKE_PATH"; then
    log_success "flake.nix updated successfully for $display_name!"
    log_info "Old ref: $current_ref"
    log_info "New ref: $tag"

    git_commit_changes "$input_name: pin to release $tag"

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
  local mode="${2:-}"
  local tag="${3:-}"
  check_git_repo

  case "$target" in
  all)
    update_dank
    update_niri "$mode"
    update_hyprland "$mode"
    update_walker_and_elephant
    ;;
  hypr | hyprland)
    update_hyprland "$mode" "$tag"
    ;;
  niri)
    update_niri "$mode" "$tag"
    ;;
  walker)
    update_walker_and_elephant
    ;;
  dank | dankmaterialshell)
    update_dank
    ;;
  stasis)
    update_stasis "$mode" "$tag"
    ;;
  *)
    log_error "Unknown target: $target"
    print_usage
    exit 1
    ;;
  esac
}

main "$@"
