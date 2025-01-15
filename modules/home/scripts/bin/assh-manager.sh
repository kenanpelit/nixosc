#!/usr/bin/env bash

#######################################
# ASSH Manager Script v1.0.2
# Author: Kenan Pelit
# License: MIT
#######################################

set -e

# Colors for messages
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# XDG Base Directory paths
XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"

# Directories and files
CACHE_DIR="$XDG_CACHE_HOME/assh"
BASH_COMPLETION_DIR="$HOME/.bash_completion.d"
ZSH_COMPLETION_DIR="$XDG_CONFIG_HOME/zsh/completions"
FISH_COMPLETION_DIR="$XDG_CONFIG_HOME/fish/completions"
CACHE_FILE="$CACHE_DIR/hosts"
INDEX_FILE="$CACHE_DIR/hosts.idx"
ARCH_CONFIG_DIR="$HOME/.config"

# Message functions
success_msg() { echo -e "${GREEN}✔ $1${NC}"; }
error_msg() { echo -e "${RED}✘ $1${NC}" >&2; }
info_msg() { echo -e "${BLUE}ℹ $1${NC}"; }
warn_msg() { echo -e "${YELLOW}⚠ $1${NC}"; }

# Spinner function for long operations
spinner() {
  local pid=$!
  local delay=0.1
  local spinstr='|/-\'
  while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
    local temp=${spinstr#?}
    printf " [%c]  " "$spinstr"
    local spinstr=$temp${spinstr%"$temp"}
    sleep $delay
    printf "\b\b\b\b\b\b"
  done
  printf "    \b\b\b\b"
}

# Create required directories
setup_dirs() {
  mkdir -p "$CACHE_DIR" "$BASH_COMPLETION_DIR" "$ZSH_COMPLETION_DIR" "$FISH_COMPLETION_DIR"
}

# Assh version check and installation
check_and_install_assh() {
  local ASSH_BIN="/usr/local/bin/assh"
  local ASSH_BACKUP_DIR="$ARCH_CONFIG_DIR/config/usr/local/bin"
  local LATEST_ASSH_VERSION="2.16.0"
  local ASSH_URL="https://github.com/moul/assh/releases/download/v${LATEST_ASSH_VERSION}/assh_${LATEST_ASSH_VERSION}_linux_amd64.tar.gz"

  if command -v assh &>/dev/null; then
    local INSTALLED_VERSION
    INSTALLED_VERSION=$(assh version | grep -oP '(\d+\.\d+\.\d+)' | head -n 1)
    if [[ "$INSTALLED_VERSION" == "$LATEST_ASSH_VERSION" ]]; then
      success_msg "assh zaten en güncel sürümde (v$INSTALLED_VERSION)."
      return
    else
      warn_msg "Yüklü sürüm: v$INSTALLED_VERSION, En son sürüm: v$LATEST_ASSH_VERSION"
      read -rp "assh'yi güncellemek istiyor musunuz? (e) Evet, (h) Hayır: " choice
      if [[ "$choice" != "e" ]]; then
        info_msg "assh güncellemesi atlandı."
        return
      fi
    fi
  else
    info_msg "assh yüklü değil. Kurulum başlatılıyor."
  fi

  info_msg "assh indiriliyor ve kuruluyor..."
  (
    mkdir -p "$ASSH_BACKUP_DIR"
    if curl -Lo "$ASSH_BACKUP_DIR/assh.tar.gz" "$ASSH_URL"; then
      tar -xzvf "$ASSH_BACKUP_DIR/assh.tar.gz" -C "$ASSH_BACKUP_DIR" &
      spinner
      sudo mv "$ASSH_BACKUP_DIR/assh" "$ASSH_BIN"
      sudo chmod +x "$ASSH_BIN"
      rm -f "$ASSH_BACKUP_DIR/assh.tar.gz"
    else
      error_msg "assh indirme başarısız oldu. İnternet bağlantınızı veya GitHub bağlantısını kontrol edin."
      return 1
    fi
  )

  if command -v assh &>/dev/null; then
    success_msg "assh başarıyla kuruldu veya güncellendi ve yedeği $ASSH_BACKUP_DIR altında saklandı."
  else
    error_msg "assh kurulumu başarısız oldu. Dosya /usr/local/bin/assh konumunda bulunamadı."
    return 1
  fi
}

# Update SSH host cache
update_cache() {
  info_msg "Updating host cache..."
  local temp_file="$CACHE_DIR/temp_hosts"

  if ! assh config list | grep -v '^#' | grep -v '^$' | awk '{print $1}' | sort >"$temp_file"; then
    error_msg "Failed to get host list from assh config"
    return 1
  fi

  if [ ! -s "$temp_file" ]; then
    error_msg "No hosts found in assh config"
    rm -f "$temp_file"
    return 1
  fi

  mv "$temp_file" "$CACHE_FILE"
  awk '{print substr($0,1,1) " " $0}' "$CACHE_FILE" | sort -u >"$INDEX_FILE"
  success_msg "Cache updated successfully. Found $(wc -l <"$CACHE_FILE") hosts."
  return 0
}

# Install bash completion
install_bash() {
  info_msg "Installing bash completion..."
  cat >"$BASH_COMPLETION_DIR/assh" <<'EOF'
#!/bin/bash

_assh_hosts_completion() {
    local cache_file="$HOME/.cache/assh/hosts"
    local index_file="$HOME/.cache/assh/hosts.idx"
    local prefix=${COMP_WORDS[COMP_CWORD]:0:1}
    
    if [[ -f "$index_file" ]]; then
        COMPREPLY=( $(grep "^$prefix" "$index_file" 2>/dev/null | cut -d' ' -f2 | grep "^${COMP_WORDS[COMP_CWORD]}") )
    else
        COMPREPLY=( $(compgen -W "$(cat $cache_file 2>/dev/null)" -- ${COMP_WORDS[COMP_CWORD]}) )
    fi
}

complete -F _assh_hosts_completion ssh
complete -F _assh_hosts_completion scp
EOF

  if ! grep -q "source ~/.bash_completion.d/assh" "$HOME/.bashrc"; then
    echo "source ~/.bash_completion.d/assh" >>"$HOME/.bashrc"
  fi
}

# Install zsh completion
install_zsh() {
  info_msg "Installing zsh completion..."
  cat >"$ZSH_COMPLETION_DIR/_assh" <<\EOF
#compdef ssh scp

_assh_hosts() {
    local cache_file="$HOME/.cache/assh/hosts"
    local index_file="$HOME/.cache/assh/hosts.idx"
    local prefix=${words[CURRENT]:0:1}
    
    if [[ -f "$index_file" ]]; then
        hosts=(${(f)"$(grep "^$prefix" "$index_file" 2>/dev/null | cut -d' ' -f2)"})
    else
        hosts=(${(f)"$(cat $cache_file 2>/dev/null)"})
    fi
    
    _describe 'hosts' hosts
}

compdef _assh_hosts ssh
compdef _assh_hosts scp
EOF

  if ! grep -q "fpath=($HOME/.config/zsh/completions \$fpath)" "$HOME/.zshrc"; then
    echo "fpath=($HOME/.config/zsh/completions \$fpath)" >>"$HOME/.zshrc"
  fi
}

# Install fish completion
install_fish() {
  info_msg "Installing fish completion..."
  cat >"$FISH_COMPLETION_DIR/assh.fish" <<'EOF'
function __assh_hosts_completion
    set -l cache_file "$HOME/.cache/assh/hosts"
    set -l index_file "$HOME/.cache/assh/hosts.idx"
    set -l prefix (commandline -ct)[1]
    
    if test -f "$index_file"
        grep "^$prefix" "$index_file" 2>/dev/null | cut -d' ' -f2
    else
        cat "$cache_file" 2>/dev/null
    end
end

complete -c ssh -a '(__assh_hosts_completion)'
complete -c scp -a '(__assh_hosts_completion)'
EOF
}

# Uninstall completions
uninstall() {
  local shell="$1"
  info_msg "Uninstalling $shell completion..."
  case "$shell" in
  "bash")
    rm -f "$BASH_COMPLETION_DIR/assh"
    sed -i '/source ~\/.bash_completion.d\/assh/d' "$HOME/.bashrc"
    ;;
  "zsh")
    rm -f "$ZSH_COMPLETION_DIR/_assh"
    sed -i '/fpath=($HOME\/.config\/zsh\/completions $fpath)/d' "$HOME/.zshrc"
    ;;
  "fish")
    rm -f "$FISH_COMPLETION_DIR/assh.fish"
    ;;
  "all")
    uninstall "bash"
    uninstall "zsh"
    uninstall "fish"
    rm -rf "$CACHE_DIR"
    ;;
  esac
}

# Show help
show_help() {
  echo "ASSH Manager - SSH/SCP Completion Tool"
  echo "Usage: $(basename "$0") COMMAND [SHELL]"
  echo
  echo "Commands:"
  echo "  -h, --help              Show this help message"
  echo "  -u, --update            Update host cache"
  echo "  -i, --install SHELL     Install completion for specified shell"
  echo "      --uninstall SHELL   Uninstall completion for specified shell"
  echo "      --check-assh        Check and install/update assh"
  echo
  echo "Supported shells: bash, zsh, fish, all"
}

# Main function
main() {
  local cmd="$1"
  local shell="$2"

  case "$cmd" in
  -h | --help)
    show_help
    ;;
  --check-assh)
    check_and_install_assh
    ;;
  -u | --update)
    setup_dirs
    update_cache
    ;;
  -i | --install)
    if [ -z "$shell" ]; then
      error_msg "Shell type required"
      show_help
      return 1
    fi
    check_and_install_assh || return 1
    setup_dirs
    update_cache || return 1
    case "$shell" in
    "bash") install_bash ;;
    "zsh") install_zsh ;;
    "fish") install_fish ;;
    "all")
      install_bash
      install_zsh
      install_fish
      ;;
    *)
      error_msg "Invalid shell type '$shell'"
      show_help
      return 1
      ;;
    esac
    success_msg "Installation completed for $shell"
    info_msg "Please restart your shell or source the appropriate rc file"
    ;;
  --uninstall)
    if [ -z "$shell" ]; then
      error_msg "Shell type required"
      show_help
      return 1
    fi
    uninstall "$shell"
    success_msg "Uninstallation completed for $shell"
    ;;
  *)
    if [ -n "$cmd" ]; then
      error_msg "Unknown command '$cmd'"
    fi
    show_help
    return 1
    ;;
  esac
}

# Run main function with all arguments
main "$@"

