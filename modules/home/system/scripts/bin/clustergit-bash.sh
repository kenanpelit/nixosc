#!/usr/bin/env bash

# Colors
OKBLUE='\033[94m'
OKGREEN='\033[92m'
WARNING='\033[93m'
FAIL='\033[91m'
ENDC='\033[0m'

# Default values
DIRNAME="."
VERBOSE=false
HIDE_CLEAN=false
RECURSIVE=false
BRANCH="(master|main)"
EXCLUDE=()
ALIGN=40

# Function to print usage
usage() {
  echo "Usage: $0 [options]"
  echo "Options:"
  echo "  -d, --dir DIR          Directory to scan (default: current directory)"
  echo "  -v, --verbose          Show full git status"
  echo "  -H, --hide-clean       Hide clean repositories"
  echo "  -R, --recursive        Recursively search for git repos"
  echo "  -b, --branch PATTERN   Branch pattern to match (default: master|main)"
  echo "  -e, --exclude PATTERN  Exclude directories matching pattern"
  echo "  -a, --align NUM        Repository name alignment (default: 40)"
  echo "  -h, --help            Show this help message"
  exit 1
}

# Function to check if directory is git repo
is_git_repo() {
  [ -d "$1/.git" ]
}

# Function to print colored message
print_color() {
  local color=$1
  local message=$2
  echo -e "${color}${message}${ENDC}"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
  -d | --dir)
    DIRNAME="$2"
    shift 2
    ;;
  -v | --verbose)
    VERBOSE=true
    shift
    ;;
  -H | --hide-clean)
    HIDE_CLEAN=true
    shift
    ;;
  -R | --recursive)
    RECURSIVE=true
    shift
    ;;
  -b | --branch)
    BRANCH="$2"
    shift 2
    ;;
  -e | --exclude)
    EXCLUDE+=("$2")
    shift 2
    ;;
  -a | --align)
    ALIGN="$2"
    shift 2
    ;;
  -h | --help)
    usage
    ;;
  *)
    echo "Unknown option: $1"
    usage
    ;;
  esac
done

# Function to check if directory should be excluded
should_exclude() {
  local dir="$1"
  for pattern in "${EXCLUDE[@]}"; do
    if [[ "$dir" =~ $pattern ]]; then
      return 0
    fi
  done
  return 1
}

# Function to check git repository status
check_repo() {
  local repo_path="$1"
  local repo_name="$(basename "$repo_path")"
  local status_msg=""

  # Change to repository directory
  cd "$repo_path" || return

  # Get git status
  local git_status=$(git status 2>&1)

  # Get current branch
  local current_branch=$(git branch --show-current)

  # Check if on correct branch
  if [[ -n "$BRANCH" && ! "$current_branch" =~ $BRANCH ]]; then
    status_msg="${WARNING}On branch ${current_branch}"
  fi

  # Check if clean
  if echo "$git_status" | grep -q "nothing to commit.*clean"; then
    if [[ "$HIDE_CLEAN" == "false" ]]; then
      status_msg="${OKGREEN}Clean"
    else
      return
    fi
  elif echo "$git_status" | grep -q "nothing added to commit but untracked files present"; then
    status_msg="${WARNING}Untracked files"
  else
    status_msg="${FAIL}Changes"
  fi

  # Check for unpushed commits
  if echo "$git_status" | grep -q "Your branch is ahead of"; then
    status_msg="$status_msg, ${FAIL}Unpushed commits"
  fi

  # Print repository status
  printf "%-${ALIGN}s: %b\n" "$repo_name" "$status_msg${ENDC}"

  # Print verbose output if requested
  if [[ "$VERBOSE" == "true" ]]; then
    echo "---------------- $repo_path -----------------"
    echo "$git_status"
    echo "---------------- $repo_path -----------------"
  fi

  cd - >/dev/null
}

# Function to scan directories
scan_dirs() {
  local base_dir="$1"
  local dirty_count=0

  # Find all git repositories
  if [[ "$RECURSIVE" == "true" ]]; then
    find_cmd="find \"$base_dir\" -type d"
  else
    find_cmd="find \"$base_dir\" -maxdepth 1 -type d"
  fi

  while IFS= read -r dir; do
    # Skip if should be excluded
    if should_exclude "$dir"; then
      continue
    fi

    # Check if it's a git repository
    if is_git_repo "$dir"; then
      check_repo "$dir"
      ((dirty_count++))
    fi
  done < <(eval "$find_cmd")

  return $dirty_count
}

# Main execution
echo "Scanning subdirectories of $DIRNAME"

# Check if directory exists
if [ ! -d "$DIRNAME" ]; then
  print_color "$FAIL" "Error: Directory $DIRNAME does not exist"
  exit 1
fi

# Scan directories
scan_dirs "$DIRNAME"
dirty_count=$?

echo "Done"
