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

# Directories to link (relative to SOURCE_ROOT -> TARGET_ROOT)
DIRS=(
  "Documents"
  "Downloads"
  "Music"
  "Pictures"
  "Videos"
  "Work"
  "Tmp"
)

# Explicit links: "source|target"
EXTRA_LINKS=(
  "/repo/archive/.mullvad|$HOME/.mullvad"
  "/repo/archive/.anote|$HOME/.anote"
  "/repo/archive/.backups|$HOME/.backups"
  "/repo/archive/.kenp|$HOME/.kenp"
  "/repo/archive/.keep|$HOME/.keep"
  "/repo/tor|$HOME/.tor"
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

iter_links() {
  local dir
  for dir in "${DIRS[@]}"; do
    printf '%s|%s|%s\n' "$dir" "$SOURCE_ROOT/$dir" "$TARGET_ROOT/$dir"
  done

  local entry source target name
  for entry in "${EXTRA_LINKS[@]}"; do
    source="${entry%%|*}"
    target="${entry#*|}"
    name="$(basename "$target")"
    printf '%s|%s|%s\n' "$name" "$source" "$target"
  done
}

# Show current status
show_status() {
  echo -e "\n${BLUE}=== Symlink Durumu ===${NC}"

  local linked=0 missing=0

  while IFS='|' read -r name source target; do
    if [[ -L "$target" ]]; then
      local link_target="$(readlink "$target" || echo "ERROR")"
      if [[ "$link_target" == "$source" ]]; then
        echo -e "${GREEN}✓${NC} $name"
        ((linked++)) || true
      else
        echo -e "${YELLOW}⚠${NC} $name -> $link_target (farklı hedef)"
      fi
    elif [[ -e "$target" ]]; then
      echo -e "${RED}✗${NC} $name (dosya var, link değil)"
      ((missing++)) || true
    else
      echo -e "${RED}✗${NC} $name (link yok)"
      ((missing++)) || true
    fi

    # Check source
    if [[ ! -d "$source" ]]; then
      echo -e "  ${YELLOW}⚠ Kaynak yok: $source${NC}"
    fi
  done < <(iter_links)

  local total=$((${#DIRS[@]} + ${#EXTRA_LINKS[@]}))
  echo -e "\n${BLUE}Toplam: ${total} | Bağlı: $linked | Eksik: $missing${NC}"
}

# Backup existing directory
backup_dir() {
  local name="$1"
  local target="$2"

  if [[ -d "$target" && ! -L "$target" ]]; then
    local backup="${target}_backup_$(date +%Y%m%d_%H%M%S)"

    if [[ "$DRY_RUN" == "true" ]]; then
      log "[TEST] Yedek: $name -> $(basename "$backup")" "$YELLOW"
    else
      mv "$target" "$backup"
      log "Yedeklendi: $(basename "$backup")" "$YELLOW"
    fi
  fi
}

# Create single symlink
create_link() {
  local name="$1"
  local source="$2"
  local target="$3"

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
        log "Atlandı: $name" "$YELLOW"
        return
      fi
    fi
  fi

  # Check existing link
  if [[ -L "$target" ]]; then
    if [[ "$(readlink "$target")" == "$source" ]]; then
      log "Zaten var: $name" "$GREEN"
      return
    else
      [[ "$FORCE" == "true" ]] && rm "$target" || return
    fi
  fi

  # Create link
  if [[ "$DRY_RUN" == "true" ]]; then
    log "[TEST] Link: $name" "$YELLOW"
  else
    ln -s "$source" "$target"
    log "Oluşturuldu: $name" "$GREEN"
  fi
}

# Create all links
create_links() {
  [[ "$DRY_RUN" == "true" ]] && log "=== TEST MODU ===" "$YELLOW"

  log "\n=== Link Oluşturma ===" "$BLUE"

  while IFS='|' read -r name source target; do
    backup_dir "$name" "$target"
    create_link "$name" "$source" "$target"
  done < <(iter_links)

  log "\nTamamlandı!" "$GREEN"
}

# Remove all links
remove_links() {
  [[ "$DRY_RUN" == "true" ]] && log "=== TEST MODU ===" "$YELLOW"

  log "\n=== Link Kaldırma ===" "$BLUE"

  while IFS='|' read -r name source target; do
    if [[ -L "$target" ]]; then
      if [[ "$DRY_RUN" == "true" ]]; then
        log "[TEST] Kaldır: $name" "$YELLOW"
      else
        rm "$target"
        log "Kaldırıldı: $name" "$GREEN"
      fi
    else
      log "Link değil: $name" "$YELLOW"
    fi
  done < <(iter_links)

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
