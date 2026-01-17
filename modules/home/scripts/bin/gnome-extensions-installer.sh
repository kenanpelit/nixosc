#!/usr/bin/env bash
# gnome-extensions-installer.sh - GNOME uzantı kurucu/güncelleyici
# Yüklü listeye göre uzantıları indirir, günceller veya yeniden kurar;
# sürüm ve durum raporu üretir.

#===============================================================================
#
#   Script: GNOME Extensions Auto Installer + Updater
#   Version: 2.3.0
#   Description: Install, update, and (optionally) reinstall GNOME Shell extensions
#   Updated: Synced with 28 installed extensions
#
#===============================================================================

#set -x
#set -euo pipefail

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly PURPLE='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly BOLD='\033[1m'
readonly NC='\033[0m'

# Modes: install (default), update, reinstall, scan
MODE="install"

# Extension list (Updated: 28 extensions)
declare -a EXTENSIONS=(
  "audio-switch-shortcuts@dbatis.github.com"
  "auto-move-windows@gnome-shell-extensions.gcampax.github.com"
  "azwallpaper@azwallpaper.gitlab.com"
  "bluetooth-quick-connect@bjarosze.gmail.com"
  "clipboard-indicator@tudmotu.com"
  "copyous@boerdereinar.dev"
  "dash-to-panel@jderose9.github.com"
  "disable-workspace-animation@ethnarque"
  "extension-list@tu.berry"
  "gsconnect@andyholmes.github.io"
  "headphone-internal-switch@gustavomalta.github.com"
  "just-perfection-desktop@just-perfection"
  "launcher@hedgie.tech"
  "mediacontrols@cliffniff.github.com"
  "no-overview@fthx"
  "notification-configurator@exposedcat"
  "notification-icons@jiggak.io"
  "no-titlebar-when-maximized@alec.ninja"
  "space-bar@luchrioh"
  "tilingshell@ferrarodomenico.com"
  "tophat@fflewddur.github.io"
  "trayIconsReloaded@selfmade.pl"
  "vertical-workspaces@G-dH.github.com"
  "veil@dagimg-dot"
  "vpn-indicator@fthx"
  "weatheroclock@CleoMenezesJr.github.io"
  "zetadev@bootpaper"
)

log() {
  local level="$1"
  shift
  local message="$*"
  local color=""
  case "$level" in
  "INFO") color=$BLUE ;;
  "SUCCESS") color=$GREEN ;;
  "WARN") color=$YELLOW ;;
  "ERROR") color=$RED ;;
  *) color=$NC ;;
  esac
  echo -e "${color}${BOLD}[$level]${NC} $message"
}

usage() {
  cat <<EOF
${BOLD}Usage:${NC} $(basename "$0") [options]

Options:
  -i, --install      Install missing extensions only (default)
  -u, --update       Update installed extensions to latest compatible version
  -r, --reinstall    Force reinstall all listed extensions
  -s, --scan         Scan currently installed extensions and update script
  -l, --list         List currently installed extensions
  -h, --help         Show this help

Examples:
  $(basename "$0")                 # install missing
  $(basename "$0") --update        # update installed
  $(basename "$0") -r              # reinstall all
  $(basename "$0") --scan          # scan and add installed extensions to script
  $(basename "$0") --list          # show installed extensions
EOF
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
    -i | --install)
      MODE="install"
      shift
      ;;
    -u | --update)
      MODE="update"
      shift
      ;;
    -r | --reinstall)
      MODE="reinstall"
      shift
      ;;
    -s | --scan)
      MODE="scan"
      shift
      ;;
    -l | --list)
      MODE="list"
      shift
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    *)
      log "WARN" "Unknown arg: $1"
      usage
      exit 1
      ;;
    esac
  done
}

check_dependencies() {
  log "INFO" "Checking dependencies..."

  if ! pgrep -f "gnome-shell" >/dev/null 2>&1; then
    log "ERROR" "GNOME Shell is not running!"
    log "INFO" "Current desktop: ${XDG_CURRENT_DESKTOP:-unknown}"
    exit 1
  fi
  log "SUCCESS" "GNOME Shell is running!"

  for bin in gnome-extensions curl unzip; do
    if ! command -v "$bin" &>/dev/null; then
      log "ERROR" "'$bin' not found!"
      case "$bin" in
      gnome-extensions) log "INFO" "Install: sudo apt install gnome-shell-extension-prefs  (Debian/Ubuntu)" ;;
      curl) log "INFO" "Install: sudo apt install curl" ;;
      unzip) log "INFO" "Install: sudo apt install unzip" ;;
      esac
      exit 1
    fi
  done

  # jq is optional; we fall back to grep/sed if missing
  if command -v jq >/dev/null 2>&1; then
    JQ_AVAILABLE=1
  else
    JQ_AVAILABLE=0
  fi

  log "SUCCESS" "All mandatory dependencies found!"
}

get_gnome_version() {
  gnome-shell --version | grep -oE '[0-9]+\.[0-9]+' | head -1
}

extensions_dir_for_uuid() {
  echo "$HOME/.local/share/gnome-shell/extensions/$1"
}

current_local_version() {
  # Echo local "version" from metadata.json or empty
  local uuid="$1"
  local dir
  dir="$(extensions_dir_for_uuid "$uuid")"
  local meta="$dir/metadata.json"
  [[ -f "$meta" ]] || {
    echo ""
    return
  }
  # Pull "version": value (number or string)
  if command -v jq >/dev/null 2>&1; then
    jq -r 'try (.version|tostring) catch ""' "$meta"
  else
    # naive extract number/string
    grep -oE '"version"\s*:\s*[^,]+' "$meta" | sed -E 's/.*:\s*"?([^",}]+)"?/\1/' || true
  fi
}

get_extension_name() {
  local uuid="$1"
  local dir
  dir="$(extensions_dir_for_uuid "$uuid")"
  local meta="$dir/metadata.json"
  [[ -f "$meta" ]] || {
    echo "$uuid"
    return
  }
  if command -v jq >/dev/null 2>&1; then
    jq -r 'try .name catch ""' "$meta" || echo "$uuid"
  else
    grep -oE '"name"\s*:\s*"[^"]+"' "$meta" | sed -E 's/.*:\s*"([^"]+)".*/\1/' | head -1 || echo "$uuid"
  fi
}

# Query GNOME Extensions API for a UUID + shell version.
query_remote_info() {
  local uuid="$1"
  local shell_ver="$2"
  local api="https://extensions.gnome.org/extension-info/?uuid=${uuid}&shell_version=${shell_ver}"
  local json
  if ! json="$(
    curl -fsSL --http1.1 \
      --retry 3 --retry-delay 1 \
      --connect-timeout 5 --max-time 15 \
      -H 'Accept: application/json' \
      -H 'User-Agent: gext-installer/2.3 (+local)' \
      "$api"
  )"; then
    return 1
  fi
  local remote_version version_tag download_url
  if command -v jq >/dev/null 2>&1; then
    remote_version="$(jq -r 'try (.version|tostring) catch ""' <<<"$json")"
    version_tag="$(jq -r 'try (.version_tag|tostring) catch ""' <<<"$json")"
    download_url="$(jq -r 'try .download_url catch ""' <<<"$json")"
  else
    remote_version="$(printf "%s" "$json" | grep -oE '"version"\s*:\s*[^,]+' | sed -E 's/.*:\s*"?([^",}]+)"?/\1/' | head -1)"
    version_tag="$(printf "%s" "$json" | grep -oE '"version_tag"\s*:\s*[^,]+' | sed -E 's/.*:\s*"?([^",}]+)"?/\1/' | head -1)"
    download_url="$(printf "%s" "$json" | grep -oE '"download_url"\s*:\s*"[^"]+"' | sed -E 's/.*:\s*"([^"]+)".*/\1/' | head -1)"
  fi
  [[ "$download_url" =~ ^/ ]] && download_url="https://extensions.gnome.org${download_url}"
  printf '%s\n%s\n%s\n' "$remote_version" "$version_tag" "$download_url"
}

install_from_zip() {
  local zip_path="$1"
  # --force will update if already installed
  if gnome-extensions install --force "$zip_path" >/dev/null 2>&1; then
    return 0
  else
    return 1
  fi
}

enable_extension() {
  local uuid="$1"
  if gnome-extensions enable "$uuid" >/dev/null 2>&1; then
    log "SUCCESS" "Enabled: $uuid"
  else
    log "WARN" "Could not enable automatically: $uuid (try relog or Alt+F2 → r on X11)"
  fi
}

download_and_install() {
  local uuid="$1"
  local shell_ver="$2"
  local mode_label="$3"

  local -a info
  if ! mapfile -t info < <(query_remote_info "$uuid" "$shell_ver"); then
    log "WARN" "No API info for: $uuid (shell $shell_ver). Install manually from https://extensions.gnome.org"
    return 1
  fi
  local remote_version="${info[0]}"
  local version_tag="${info[1]}"
  local download_url="${info[2]}"

  if [[ -z "$download_url" ]]; then
    log "WARN" "Download URL missing for: $uuid (shell $shell_ver)"
    return 1
  fi

  local tmpdir
  tmpdir="$(mktemp -d)"
  local zip_path="$tmpdir/extension.zip"

  log "INFO" "$mode_label → fetching $uuid (remote v$remote_version, tag $version_tag)"
  if ! curl -fsSL --http1.1 \
    --retry 3 --retry-delay 1 \
    --connect-timeout 5 --max-time 15 \
    -H 'Accept: application/zip' \
    -H 'User-Agent: gext-installer/2.3 (+local)' \
    -o "$zip_path" "$download_url"; then
    log "ERROR" "Download failed for: $uuid"
    rm -rf "$tmpdir"
    return 1
  fi

  if gnome-extensions install --force "$zip_path" >/dev/null 2>&1; then
    log "SUCCESS" "$mode_label complete: $uuid → v$remote_version"
    enable_extension "$uuid"
    rm -rf "$tmpdir"
    return 0
  else
    log "ERROR" "$mode_label failed for: $uuid"
    rm -rf "$tmpdir"
    return 1
  fi
}

install_extension_if_missing() {
  local uuid="$1"
  local shell_ver="$2"
  if gnome-extensions list | grep -qx "$uuid"; then
    log "WARN" "Already installed: $uuid"
    return 0
  fi
  download_and_install "$uuid" "$shell_ver" "Install"
}

reinstall_extension() {
  local uuid="$1"
  local shell_ver="$2"
  download_and_install "$uuid" "$shell_ver" "Reinstall"
}

update_extension_if_available() {
  local uuid="$1"
  local shell_ver="$2"

  if ! gnome-extensions list | grep -qx "$uuid"; then
    log "WARN" "Not installed (skipping update): $uuid"
    return 0
  fi

  local local_ver
  local_ver="$(current_local_version "$uuid")"
  [[ -z "$local_ver" ]] && local_ver="unknown"

  local -a info
  if ! mapfile -t info < <(query_remote_info "$uuid" "$shell_ver"); then
    log "WARN" "Could not query remote for: $uuid (shell $shell_ver)"
    return 1
  fi
  local remote_version="${info[0]}"
  local version_tag="${info[1]}"
  local download_url="${info[2]}"

  if [[ -z "$remote_version" ]]; then
    log "WARN" "No remote version for: $uuid (shell $shell_ver)"
    return 1
  fi

  if [[ "$local_ver" == "$remote_version" ]]; then
    log "INFO" "Up-to-date: $uuid (v$local_ver)"
    return 0
  else
    log "INFO" "Update available: $uuid local v$local_ver → remote v$remote_version"
    download_and_install "$uuid" "$shell_ver" "Update"
  fi
}

scan_and_update_script() {
  log "INFO" "Scanning currently installed extensions..."

  # Get the script path
  local script_path="$0"
  local script_realpath
  script_realpath="$(realpath "$script_path")"

  # Create backup
  local backup_path="${script_realpath}.backup-$(date +%Y%m%d-%H%M%S)"
  cp "$script_realpath" "$backup_path"
  log "SUCCESS" "Backup created: $backup_path"

  # Get all installed extensions
  local -a installed_extensions
  mapfile -t installed_extensions < <(gnome-extensions list | sort)

  if [[ ${#installed_extensions[@]} -eq 0 ]]; then
    log "WARN" "No extensions found!"
    return 1
  fi

  log "INFO" "Found ${#installed_extensions[@]} installed extensions"
  echo

  # Display installed extensions with names
  log "INFO" "Currently installed extensions:"
  for uuid in "${installed_extensions[@]}"; do
    local name
    name="$(get_extension_name "$uuid")"
    local ver
    ver="$(current_local_version "$uuid")"

    if is_extension_enabled "$uuid"; then
      echo -e "  ${GREEN}✓${NC} $name"
      echo -e "    ${CYAN}$uuid${NC} (v${ver:-?})"
    else
      echo -e "  ${YELLOW}○${NC} $name"
      echo -e "    ${CYAN}$uuid${NC} (v${ver:-?})"
    fi
  done

  echo
  read -rp "Do you want to update the script with these extensions? (y/N): " -n 1 REPLY
  echo

  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    log "INFO" "Scan cancelled. Backup preserved at: $backup_path"
    return 0
  fi

  # Create new extension array content
  local new_extensions="declare -a EXTENSIONS=(\n"
  for uuid in "${installed_extensions[@]}"; do
    new_extensions+="\t\"$uuid\"\n"
  done
  new_extensions+=")"

  # Create temporary file with updated content
  local tmpfile
  tmpfile="$(mktemp)"

  # Replace the EXTENSIONS array in the script
  awk -v new_ext="$new_extensions" '
		/^declare -a EXTENSIONS=\(/ {
			print new_ext
			# Skip lines until closing parenthesis
			while (getline > 0 && !/^\)/) { }
			next
		}
		{ print }
	' "$script_realpath" >"$tmpfile"

  # Replace the script with updated version
  mv "$tmpfile" "$script_realpath"
  chmod +x "$script_realpath"

  log "SUCCESS" "Script updated with ${#installed_extensions[@]} extensions!"
  log "INFO" "Backup saved at: $backup_path"
  log "INFO" "You can now use this script on other systems to install these extensions"
}

is_extension_enabled() {
  local uuid="$1"
  gnome-extensions list --enabled 2>/dev/null | grep -qx "$uuid"
}

list_installed_extensions() {
  log "INFO" "Currently installed extensions:"
  echo

  local -a installed
  mapfile -t installed < <(gnome-extensions list | sort)

  if [[ ${#installed[@]} -eq 0 ]]; then
    log "WARN" "No extensions installed!"
    return 0
  fi

  local count=1
  for uuid in "${installed[@]}"; do
    local name
    name="$(get_extension_name "$uuid")"
    local ver
    ver="$(current_local_version "$uuid")"

    echo -e "${BOLD}[$count]${NC} $name"
    echo -e "    UUID: ${CYAN}$uuid${NC}"
    echo -e "    Version: ${YELLOW}${ver:-unknown}${NC}"
    if is_extension_enabled "$uuid"; then
      echo -e "    Status: ${GREEN}Enabled${NC}"
    else
      echo -e "    Status: ${RED}Disabled${NC}"
    fi
    echo
    ((count++))
  done

  log "INFO" "Total: ${#installed[@]} extensions"
}

install_all_extensions() {
  log "INFO" "Installing ${#EXTENSIONS[@]} GNOME Shell extensions..."
  local count=1 success=0 failed=0
  local shell_ver
  shell_ver="$(get_gnome_version)"

  for uuid in "${EXTENSIONS[@]}"; do
    log "INFO" "[$count/${#EXTENSIONS[@]}] $uuid"
    if install_extension_if_missing "$uuid" "$shell_ver"; then
      ((success++))
    else
      ((failed++))
    fi
    ((count++))
    sleep 0.5
  done
  echo
  log "INFO" "Install summary → success: $success, failed: $failed"
  [[ $failed -eq 0 ]]
}

reinstall_all_extensions() {
  log "INFO" "Reinstalling ${#EXTENSIONS[@]} GNOME Shell extensions..."
  local count=1 success=0 failed=0
  local shell_ver
  shell_ver="$(get_gnome_version)"

  for uuid in "${EXTENSIONS[@]}"; do
    log "INFO" "[$count/${#EXTENSIONS[@]}] $uuid"
    if reinstall_extension "$uuid" "$shell_ver"; then
      ((success++))
    else
      ((failed++))
    fi
    ((count++))
    sleep 0.5
  done
  echo
  log "INFO" "Reinstall summary → success: $success, failed: $failed"
  [[ $failed -eq 0 ]]
}

update_all_extensions() {
  log "INFO" "Updating ${#EXTENSIONS[@]} GNOME Shell extensions..."
  local count=1 success=0 failed=0
  local shell_ver
  shell_ver="$(get_gnome_version)"

  for uuid in "${EXTENSIONS[@]}"; do
    log "INFO" "[$count/${#EXTENSIONS[@]}] $uuid"
    if update_extension_if_available "$uuid" "$shell_ver"; then
      ((success++))
    else
      ((failed++))
    fi
    ((count++))
    sleep 0.5
  done
  echo
  log "INFO" "Update summary → success: $success, failed: $failed"
  [[ $failed -eq 0 ]]
}

restart_gnome_shell() {
  log "INFO" "Restarting GNOME Shell to apply changes..."
  if [[ "${XDG_SESSION_TYPE:-}" == "wayland" ]]; then
    log "WARN" "Wayland oturumunda GNOME Shell doğrudan yeniden başlatılamaz. Çıkış yapıp tekrar giriş yapın."
    log "INFO" "X11 için: Alt+F2 → 'r' → Enter"
  else
    if command -v gnome-shell &>/dev/null; then
      nohup gnome-shell --replace &>/dev/null &
      disown
      log "SUCCESS" "GNOME Shell restarted!"
    fi
  fi
}

show_installed_extensions() {
  log "INFO" "Currently installed extensions:"
  gnome-extensions list | while read -r extension; do
    # Version
    local ver
    ver="$(current_local_version "$extension")"
    if is_extension_enabled "$extension"; then
      echo -e "  ${GREEN}✓${NC} $extension (v${ver:-?})"
    else
      echo -e "  ${RED}✗${NC} $extension (v${ver:-?})"
    fi
  done
}

main() {
  parse_args "$@"

  echo -e "${BOLD}${CYAN}GNOME Extensions Installer/Updater${NC}"
  echo -e "${BOLD}Mode:${NC} $MODE"
  echo

  # For scan and list modes, we don't need full dependency check
  if [[ "$MODE" == "list" ]]; then
    if ! command -v gnome-extensions &>/dev/null; then
      log "ERROR" "gnome-extensions command not found!"
      exit 1
    fi
    list_installed_extensions
    exit 0
  fi

  if [[ "$MODE" == "scan" ]]; then
    if ! command -v gnome-extensions &>/dev/null; then
      log "ERROR" "gnome-extensions command not found!"
      exit 1
    fi
    scan_and_update_script
    exit 0
  fi

  check_dependencies
  echo

  local shell_ver
  shell_ver="$(get_gnome_version)"
  log "INFO" "GNOME Shell version: $shell_ver"
  log "INFO" "Session type: ${XDG_SESSION_TYPE:-unknown}"
  echo

  case "$MODE" in
  install) install_all_extensions ;;
  update) update_all_extensions ;;
  reinstall) reinstall_all_extensions ;;
  esac

  echo
  show_installed_extensions

  echo
  log "INFO" "Manual options:"
  log "INFO" "• GNOME Extensions: https://extensions.gnome.org/"
  log "INFO" "• Extension Manager (Flatpak): flatpak install flathub com.mattjakeman.ExtensionManager"

  echo
  log "WARN" "Some extensions may require GNOME Shell restart to work properly."

  # Offer restart on X11
  if [[ "${XDG_SESSION_TYPE:-}" != "wayland" ]]; then
    echo
    read -rp "Do you want to restart GNOME Shell now? (y/N): " -n 1 REPLY
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
      restart_gnome_shell
    fi
  fi

  echo
  log "SUCCESS" "Done! Enjoy your GNOME extensions! 🎉"
}

main "$@"
