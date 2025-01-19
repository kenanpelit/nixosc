#!/usr/bin/env bash

#===============================================================================
#   Script: Advanced Dotfiles Manager with GNU Stow
#   Version: 2.4.0
#   Created: December 17, 2024
#   License: MIT
#===============================================================================
#
# DESCRIPTION:
# This script provides a comprehensive solution for managing dotfiles using GNU Stow.
# It supports both individual file management and group-based configuration management.
#
# KEY FEATURES:
# - Group-based configuration management via groups.conf
# - Support for both ~/.config and home directory files
# - Multiple file/directory management per group
# - Smart handling of file extensions and program names
# - Selective import of configurations
# - Dry-run capability for safe testing
# - Automatic symlinking using GNU Stow
#
# DIRECTORY STRUCTURE:
# ~/.dotfiles/                    # Main dotfiles directory
# ├── groups.conf                 # Group definitions file
# ├── zsh/                        # Example group directory
# │   ├── .zshrc                  # Home directory files
# │   ├── .zprofile
# │   └── .config/                # .config directory files
# │       └── zsh/
# │           └── aliases
# └── starship/                   # Example with multiple configs
#     └── .config/
#         ├── starship.toml       # Main config
#         └── starship/           # Theme directory
#             ├── theme1.toml
#             └── theme2.toml
#
# GROUPS.CONF FORMAT:
# Format: group_name:home_files:config_dir
# Example entries:
#   zsh:.zshrc,.zprofile,.zshenv:zsh
#   nvim::nvim
#   bash:.bashrc,.bash_profile:
#   starship:.config/starship.toml,.config/starship:starship
#
# Note: Multiple .config entries should be comma-separated in home_files field
#
#===============================================================================

# Color definitions
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Global variables
DOTFILES_DIR="$HOME/.dotfiles"
GROUPS_CONFIG="$DOTFILES_DIR/groups.conf"
IMPORTED_PATHS=()

# Check if stow is installed
check_stow() {
  if ! command -v stow &>/dev/null; then
    echo -e "${RED}GNU Stow not found!${NC}"
    echo -e "${YELLOW}For installation:${NC}"
    echo "Arch Linux: sudo pacman -S stow"
    echo "Ubuntu/Debian: sudo apt install stow"
    echo "Fedora: sudo dnf install stow"
    exit 1
  fi
}

# Load group configurations from groups.conf
load_groups() {
  if [[ ! -f "$GROUPS_CONFIG" ]]; then
    return
  fi

  SPECIAL_GROUPS=()
  while IFS= read -r line; do
    # Skip comments and empty lines
    [[ "$line" =~ ^#.*$ || -z "$line" ]] && continue
    SPECIAL_GROUPS+=("$line")
  done <"$GROUPS_CONFIG"
}

# Group management functions
manage_groups() {
  local cmd=$1
  local group_name=$2
  local home_files=$3
  local config_dir=$4

  case "$cmd" in
  "add")
    if grep -q "^$group_name:" "$GROUPS_CONFIG" 2>/dev/null; then
      echo -e "${YELLOW}Updating existing group: $group_name${NC}"
      sed -i "/^$group_name:/d" "$GROUPS_CONFIG"
    fi
    echo "$group_name:$home_files:$config_dir" >>"$GROUPS_CONFIG"
    sort -u "$GROUPS_CONFIG" -o "$GROUPS_CONFIG"
    echo -e "${GREEN}Group definition for $group_name added successfully${NC}"
    ;;
  "rm")
    if [[ -f "$GROUPS_CONFIG" ]]; then
      if grep -q "^$group_name:" "$GROUPS_CONFIG"; then
        sed -i "/^$group_name:/d" "$GROUPS_CONFIG"
        echo -e "${GREEN}Group definition for $group_name removed successfully${NC}"
      else
        echo -e "${RED}Error: Group $group_name not found in groups.conf${NC}"
      fi
    fi
    ;;
  "ls")
    echo -e "${BLUE}Configured Groups:${NC}"
    if [[ -f "$GROUPS_CONFIG" ]]; then
      while IFS=: read -r name files config_dir; do
        [[ "$name" =~ ^#.*$ || -z "$name" ]] && continue
        echo -e "${YELLOW}Group: $name${NC}"
        [[ -n "$files" ]] && echo "  Home files: $files"
        [[ -n "$config_dir" ]] && echo "  Config dir: $config_dir"
        echo
      done <"$GROUPS_CONFIG"
    else
      echo "No groups configured"
    fi
    ;;
  esac
}

# Add configuration files to dotfiles
add_config() {
  check_stow
  local source=$1
  local program_name=""
  local is_config=false
  local target_path=""

  # Determine full path and program name
  if [[ "$source" == .config/* ]]; then
    is_config=true
    target_path="$HOME/$source"
    # Get program name from config path without extension
    program_name=$(echo "$source" | cut -d'/' -f2 | sed 's/\.[^.]*$//')
  else
    if [[ "$source" != .* ]]; then
      source=".$source"
    fi
    target_path="$HOME/$source"
    # Get program name without leading dot and extension
    program_name=$(echo "${source#.}" | sed 's/\.[^.]*$//')
  fi

  # Check for special groups
  for group_def in "${SPECIAL_GROUPS[@]}"; do
    IFS=':' read -r group_name group_files config_dir <<<"$group_def"

    if [[ "$is_config" == true && -n "$config_dir" && "$program_name" == "$config_dir" ]] ||
      [[ "$is_config" == false && "$group_files" == *"$source"* ]]; then
      program_name="$group_name"
      break
    fi
  done

  # Check if already imported
  if [[ " ${IMPORTED_PATHS[@]} " =~ " $source " ]]; then
    echo -e "${YELLOW}Already imported: $source${NC}"
    return 1
  fi

  # Check if target exists
  if [[ ! -e "$target_path" ]]; then
    echo -e "${RED}Error: $target_path not found${NC}"
    return 1
  fi

  # Create target directory and move files
  if [[ "$is_config" == true ]]; then
    mkdir -p "$DOTFILES_DIR/$program_name/.config"
    if [[ "$target_path" == *".config/"* ]]; then
      # Get the relative path after .config/
      local rel_path=${target_path#*/.config/}
      mv "$target_path" "$DOTFILES_DIR/$program_name/.config/$rel_path"
    else
      mv "$target_path" "$DOTFILES_DIR/$program_name/.config/"
    fi
  else
    mkdir -p "$DOTFILES_DIR/$program_name"
    mv "$target_path" "$DOTFILES_DIR/$program_name/"
  fi

  # Link with stow
  cd "$DOTFILES_DIR" && stow "$program_name"
  IMPORTED_PATHS+=("$source")
  echo -e "${GREEN}Successfully added $source to $program_name group${NC}"
  return 0
}

# Remove configuration files and symlinks
remove_config() {
  check_stow
  local program=$1

  if [[ ! -d "$DOTFILES_DIR/$program" ]]; then
    echo -e "${RED}Error: $program not found in dotfiles${NC}"
    return 1
  fi

  # Check if it's in a special group
  for group_def in "${SPECIAL_GROUPS[@]}"; do
    IFS=':' read -r group_name group_files config_dir <<<"$group_def"

    if [[ "$program" == "$group_name" ]]; then
      # First unstow
      cd "$DOTFILES_DIR" && stow -D "$program"

      # Move home files back
      if [[ -n "$group_files" ]]; then
        IFS=',' read -ra files <<<"$group_files"
        for file in "${files[@]}"; do
          if [[ -e "$DOTFILES_DIR/$program/$file" ]]; then
            mkdir -p "$(dirname "$HOME/$file")"
            mv "$DOTFILES_DIR/$program/$file" "$HOME/$file"
            echo -e "${GREEN}Restored: $file${NC}"
          fi
        done
      fi

      # Move config directory back
      if [[ -n "$config_dir" && -d "$DOTFILES_DIR/$program/.config/$config_dir" ]]; then
        mkdir -p "$HOME/.config"
        mv "$DOTFILES_DIR/$program/.config/$config_dir" "$HOME/.config/"
        echo -e "${GREEN}Restored: .config/$config_dir${NC}"
      fi

      rm -rf "$DOTFILES_DIR/$program"
      echo -e "${GREEN}Successfully removed all files for $program${NC}"
      return 0
    fi
  done

  # Handle non-grouped configs
  cd "$DOTFILES_DIR" && stow -D "$program"
  if [[ -d "$DOTFILES_DIR/$program/.config" ]]; then
    mkdir -p "$HOME/.config"
    mv "$DOTFILES_DIR/$program/.config/$program" "$HOME/.config/"
    echo -e "${GREEN}Restored: .config/$program${NC}"
  else
    mv "$DOTFILES_DIR/$program/.$program" "$HOME/"
    echo -e "${GREEN}Restored: .$program${NC}"
  fi

  rm -rf "$DOTFILES_DIR/$program"
  echo -e "${GREEN}Successfully removed all files for $program${NC}"
}

# Sync all dotfiles
sync_dotfiles() {
  check_stow
  echo -e "${BLUE}Synchronizing dotfiles...${NC}"
  cd "$DOTFILES_DIR"

  for dir in */; do
    program=${dir%/}
    stow -R "$program"
    echo -e "${GREEN}Synchronized $program${NC}"
  done
}

# Import configurations from groups.conf
import_configs() {
  local mode=$1 # 'dry-run' or 'apply'
  shift
  local selected_groups=("$@")
  local total=0
  local success=0
  local groups_found=false

  echo -e "${BLUE}Starting config import...${NC}"

  # Check if selected groups exist
  if [[ ${#selected_groups[@]} -gt 0 ]]; then
    local invalid_groups=()
    for selected in "${selected_groups[@]}"; do
      if ! grep -q "^${selected}:" "$GROUPS_CONFIG"; then
        invalid_groups+=("$selected")
      fi
    done

    if [[ ${#invalid_groups[@]} -gt 0 ]]; then
      echo -e "${RED}Error: Following groups not found in groups.conf:${NC}"
      for invalid in "${invalid_groups[@]}"; do
        echo "  - $invalid"
      done
      echo -e "${YELLOW}Use 'group ls' to see available groups${NC}"
      return 1
    fi
  fi

  while IFS=: read -r group_name home_files config_dir; do
    # Skip comments and empty lines
    [[ "$group_name" =~ ^#.*$ || -z "$group_name" ]] && continue

    # If groups are selected, process only those
    if [[ ${#selected_groups[@]} -gt 0 ]]; then
      local group_found=false
      for selected in "${selected_groups[@]}"; do
        if [[ "$group_name" == "$selected" ]]; then
          group_found=true
          break
        fi
      done
      [[ "$group_found" == false ]] && continue
    fi

    groups_found=true
    echo -e "\n${YELLOW}Processing group: $group_name${NC}"

    # Process all files (both home and config)
    if [[ -n "$home_files" ]]; then
      IFS=',' read -ra files <<<"$home_files"
      for file in "${files[@]}"; do
        if [[ -e "$HOME/$file" ]]; then
          total=$((total + 1))
          if [[ "$mode" == "dry-run" ]]; then
            echo "  Would import: $file"
          else
            if add_config "$file"; then
              success=$((success + 1))
              echo -e "  ${GREEN}Imported: $file${NC}"
            else
              echo -e "  ${RED}Failed to import: $file${NC}"
            fi
          fi
        else
          echo -e "  ${YELLOW}Not found: $file${NC}"
        fi
      done
    fi
  done <"$GROUPS_CONFIG"

  if [[ "$groups_found" == false ]]; then
    echo -e "${YELLOW}No matching groups found to process${NC}"
    return 1
  fi

  echo -e "\n${BLUE}Import summary:${NC}"
  if [[ "$mode" == "dry-run" ]]; then
    echo "Would import $total configurations"
  else
    echo "Successfully imported $success of $total configurations"
  fi
}

# List existing dotfiles
list_dotfiles() {
  [[ ! -d "$DOTFILES_DIR" || -z "$(ls -A "$DOTFILES_DIR")" ]] && {
    echo -e "${YELLOW}No dotfiles added yet.${NC}"
    return
  }

  echo -e "${BLUE}Current dotfiles:${NC}"
  cd "$DOTFILES_DIR"

  echo -e "${YELLOW}Files in .config:${NC}"
  found_configs=false
  for dir in */; do
    [[ -d "$DOTFILES_DIR/${dir%/}/.config" ]] && {
      echo "  - ${dir%/} (.config)"
      found_configs=true
    }
  done
  [[ "$found_configs" = false ]] && echo "  No .config files added yet"

  echo -e "\n${YELLOW}Files in home:${NC}"
  found_home_files=false
  for dir in */; do
    [[ ! -d "$DOTFILES_DIR/${dir%/}/.config" ]] && {
      echo "  - .${dir%/}"
      found_home_files=true
    }
  done
  [[ "$found_home_files" = false ]] && echo "  No home dotfiles added yet"

  # Show group configurations
  if [[ -f "$GROUPS_CONFIG" ]]; then
    echo -e "\n${YELLOW}Configured Groups:${NC}"
    while IFS=: read -r name files config_dir; do
      [[ "$name" =~ ^#.*$ || -z "$name" ]] && continue
      echo -e "  - $name"
    done <"$GROUPS_CONFIG"
  fi
}

# Show usage information
usage() {
  echo "Dotfiles Management with GNU Stow"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo
  echo "Usage: $(basename $0) <command> [options]"
  echo
  echo "Commands:"
  echo "  add <path>                     Add file/directory from home or .config"
  echo "  rm <name>                      Remove config files and symlinks"
  echo "  sync                           Synchronize all dotfiles"
  echo "  ls                             List existing dotfiles"
  echo "  import                         Import all configs from groups.conf"
  echo "  import <group1> <group2>       Import specific groups"
  echo "  import --dry-run [group]       Show what would be imported"
  echo
  echo "Group Management:"
  echo "  group add <name> <files> [dir] Add group to groups.conf"
  echo "  group rm <name>                Remove group from groups.conf only"
  echo "  group ls                       List all group configurations"
  echo
  echo "Examples:"
  echo "  $(basename $0) group add zsh '.zshrc,.zprofile' zsh       # Add group definition"
  echo "  $(basename $0) group add nvim '' nvim                     # Add config-only group"
  echo "  $(basename $0) group add starship '.config/starship.toml,.config/starship' starship"
  echo "  $(basename $0) add .zshrc                                 # Add single file"
  echo "  $(basename $0) rm zsh                                     # Remove files and symlinks"
  echo "  $(basename $0) group rm zsh                               # Remove only group definition"
  echo "  $(basename $0) import --dry-run zsh                       # Preview zsh import"
  echo "  $(basename $0) import nvim zsh                            # Import selected groups"
}

# Main function - command processing
main() {
  [[ ! -d "$DOTFILES_DIR" ]] && mkdir -p "$DOTFILES_DIR"
  load_groups

  case "$1" in
  "add")
    [[ -z "$2" ]] && {
      echo -e "${RED}Error: Path required${NC}"
      usage
      exit 1
    }
    add_config "$2"
    ;;
  "rm")
    [[ -z "$2" ]] && {
      echo -e "${RED}Error: Name required${NC}"
      usage
      exit 1
    }
    remove_config "$2"
    ;;
  "sync")
    sync_dotfiles
    ;;
  "ls")
    list_dotfiles
    ;;
  "import")
    shift
    local mode="apply"
    local groups=()

    # Process parameters
    while [[ $# -gt 0 ]]; do
      case "$1" in
      "--dry-run")
        mode="dry-run"
        ;;
      *)
        groups+=("$1")
        ;;
      esac
      shift
    done

    # Eğer hiç grup seçilmemişse ve dry-run varsa
    if [[ ${#groups[@]} -eq 0 && "$mode" == "dry-run" ]]; then
      import_configs "dry-run"
    # Eğer gruplar seçilmişse
    elif [[ ${#groups[@]} -gt 0 ]]; then
      import_configs "$mode" "${groups[@]}"
    # Hiç parametre yoksa tümünü import et
    else
      import_configs "apply"
    fi
    ;;
  "group")
    shift
    case "$1" in
    "add")
      [[ -z "$2" || -z "$3" ]] && {
        echo -e "${RED}Error: group add requires name and files${NC}"
        usage
        exit 1
      }
      manage_groups "add" "$2" "$3" "$4"
      ;;
    "rm")
      [[ -z "$2" ]] && {
        echo -e "${RED}Error: group rm requires name${NC}"
        usage
        exit 1
      }
      manage_groups "rm" "$2"
      ;;
    "ls")
      manage_groups "ls"
      ;;
    *)
      usage
      exit 1
      ;;
    esac
    ;;
  *)
    usage
    exit 1
    ;;
  esac
}

main "$@"
