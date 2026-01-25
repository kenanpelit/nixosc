#!/usr/bin/env bash
#===============================================================================
#
#   Script: OSC Symlink Manager
#   Version: 1.1.0
#   Date: 2025-07-20
#   Author: Kenan Pelit
#   Repository: https://github.com/kenanpelit/nixosc
#   Description: Manages symbolic links for configured directories between a
#                source repository and target location with backup functionality
#
#   Features:
#   - Creates symbolic links from source to target directories
#   - Automatic backup of existing directories
#   - Configurable directory list
#   - Dry-run mode for testing
#   - Color-coded status output
#   - Safety checks and confirmations
#
#   License: MIT
#
#===============================================================================

# set -euo pipefail

# Colors
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

# Configuration
SOURCE_ROOT="/repo/archive"
TARGET_ROOT="$HOME"

# Directories to link
DIRS=(
  "Documents"
  "Downloads"
  "Music"
  "Pictures"
  "Videos"
  "Work"
  "Tmp"
  "mullvad"
)

# Options
DRY_RUN=false
FORCE=false

# Simple logging
log() {
  local color="${2:-$NC}"
  echo -e "${color}$1${NC}"
}

error() {
  log "HATA: $1" "$RED"
  exit 1
}

# Help
show_help() {
  echo -e "${BLUE}Symlink Yönetici${NC}"
  echo
  echo "Kullanım: $(basename "$0") [KOMUT] [SEÇENEKLER]"
  echo
  echo "Komutlar:"
  echo "  create (varsayılan)    Symlink'leri oluştur"
  echo "  remove                 Symlink'leri kaldır"
  echo "  status                 Durumu göster"
  echo
  echo "Seçenekler:"
  echo "  -d, --dry-run         Test modu"
  echo "  -f, --force           Onay isteme"
  echo "  -h, --help            Yardım"
  echo
  echo "Örnekler:"
  echo "  $(basename "$0")                    # Symlink'leri oluştur"
  echo "  $(basename "$0") status             # Durumu göster"
  echo "  $(basename "$0") remove --dry-run   # Kaldırma testi"
  echo
}

# Check prerequisites
check_setup() {
  [[ -d "$SOURCE_ROOT" ]] || error "Kaynak dizin bulunamadı: $SOURCE_ROOT"
  [[ -w "$TARGET_ROOT" ]] || error "Hedef dizine yazma izni yok: $TARGET_ROOT"
}

# Show current status
show_status() {
  echo -e "\n${BLUE}=== Symlink Durumu ===${NC}"

  local linked=0 missing=0

  for dir in "${DIRS[@]}"; do
    local target="$TARGET_ROOT/$dir"
    local source="$SOURCE_ROOT/$dir"

    if [[ -L "$target" ]]; then
      local link_target="$(readlink "$target" || echo "ERROR")"
      if [[ "$link_target" == "$source" ]]; then
        echo -e "${GREEN}✓${NC} $dir"
        ((linked++)) || true
      else
        echo -e "${YELLOW}⚠${NC} $dir -> $link_target (farklı hedef)"
      fi
    elif [[ -e "$target" ]]; then
      echo -e "${RED}✗${NC} $dir (dosya var, link değil)"
      ((missing++)) || true
    else
      echo -e "${RED}✗${NC} $dir (link yok)"
      ((missing++)) || true
    fi

    # Check source
    if [[ ! -d "$source" ]]; then
      echo -e "  ${YELLOW}⚠ Kaynak yok: $source${NC}"
    fi
  done

  echo -e "\n${BLUE}Toplam: ${#DIRS[@]} | Bağlı: $linked | Eksik: $missing${NC}"
}

# Backup existing directory
backup_dir() {
  local dir="$1"
  local target="$TARGET_ROOT/$dir"

  if [[ -d "$target" && ! -L "$target" ]]; then
    local backup="${target}_backup_$(date +%Y%m%d_%H%M%S)"

    if [[ "$DRY_RUN" == "true" ]]; then
      log "[TEST] Yedek: $dir -> $(basename "$backup")" "$YELLOW"
    else
      mv "$target" "$backup"
      log "Yedeklendi: $(basename "$backup")" "$YELLOW"
    fi
  fi
}

# Create single symlink
create_link() {
  local dir="$1"
  local source="$SOURCE_ROOT/$dir"
  local target="$TARGET_ROOT/$dir"

  # Create source if missing
  if [[ ! -d "$source" ]]; then
    if [[ "$FORCE" == "true" ]] || [[ "$DRY_RUN" == "true" ]]; then
      if [[ "$DRY_RUN" == "true" ]]; then
        log "[TEST] Kaynak oluştur: $source" "$YELLOW"
      else
        mkdir -p "$source"
        log "Kaynak oluşturuldu: $source" "$BLUE"
      fi
    else
      read -p "Kaynak dizin oluşturulsun mu ($source)? (e/h): " -n 1 -r
      echo
      if [[ $REPLY =~ ^[Ee]$ ]]; then
        mkdir -p "$source"
      else
        log "Atlandı: $dir" "$YELLOW"
        return
      fi
    fi
  fi

  # Check existing link
  if [[ -L "$target" ]]; then
    if [[ "$(readlink "$target")" == "$source" ]]; then
      log "Zaten var: $dir" "$GREEN"
      return
    else
      [[ "$FORCE" == "true" ]] && rm "$target" || return
    fi
  fi

  # Create link
  if [[ "$DRY_RUN" == "true" ]]; then
    log "[TEST] Link: $dir" "$YELLOW"
  else
    ln -s "$source" "$target"
    log "Oluşturuldu: $dir" "$GREEN"
  fi
}

# Create all links
create_links() {
  [[ "$DRY_RUN" == "true" ]] && log "=== TEST MODU ===" "$YELLOW"

  log "\n=== Link Oluşturma ===" "$BLUE"

  for dir in "${DIRS[@]}"; do
    backup_dir "$dir"
    create_link "$dir"
  done

  log "\nTamamlandı!" "$GREEN"
}

# Remove all links
remove_links() {
  [[ "$DRY_RUN" == "true" ]] && log "=== TEST MODU ===" "$YELLOW"

  log "\n=== Link Kaldırma ===" "$BLUE"

  for dir in "${DIRS[@]}"; do
    local target="$TARGET_ROOT/$dir"

    if [[ -L "$target" ]]; then
      if [[ "$DRY_RUN" == "true" ]]; then
        log "[TEST] Kaldır: $dir" "$YELLOW"
      else
        rm "$target"
        log "Kaldırıldı: $dir" "$GREEN"
      fi
    else
      log "Link değil: $dir" "$YELLOW"
    fi
  done

  log "\nTamamlandı!" "$GREEN"
}

# Main
main() {
  local command="create"

  # Parse arguments directly in main
  while [[ $# -gt 0 ]]; do
    case $1 in
    create | remove | status)
      command="$1"
      shift
      ;;
    -d | --dry-run)
      DRY_RUN=true
      shift
      ;;
    -f | --force)
      FORCE=true
      shift
      ;;
    -h | --help)
      show_help
      exit 0
      ;;
    *)
      error "Bilinmeyen parametre: $1"
      ;;
    esac
  done

  check_setup

  case "$command" in
  "create") create_links ;;
  "remove") remove_links ;;
  "status") show_status ;;
  esac
}

main "$@"
