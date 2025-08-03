#!/usr/bin/env bash

# Hyprland Commit Updater Script
set -euo pipefail

# Renkler
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

FLAKE_PATH="$HOME/.nixosc/flake.nix"

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# GitHub'dan son commit hash'ini al
get_latest_commit() {
	local response
	response=$(curl -s --max-time 30 "https://api.github.com/repos/hyprwm/Hyprland/commits/main")

	if [[ -z "$response" ]]; then
		log_error "GitHub API'ye erişim başarısız"
		exit 1
	fi

	local commit_hash
	commit_hash=$(echo "$response" | sed -n 's/.*"sha":[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)

	if [[ -z "$commit_hash" ]]; then
		log_error "Commit hash alınamadı"
		exit 1
	fi

	echo "${commit_hash:0:40}"
}

# Mevcut commit'i flake.nix'ten al
get_current_commit() {
	local current_hash

	# Aktif URL'i ara
	current_hash=$(command grep 'url = "github:hyprwm/hyprland/' "$FLAKE_PATH" | command grep -v '^[[:space:]]*#' | head -1 | sed 's/.*\/\([^"]*\)".*/\1/')

	# Bulunamazsa comment edilmiş en son olanı al
	if [[ -z "$current_hash" ]]; then
		current_hash=$(command grep '#.*url = "github:hyprwm/hyprland/' "$FLAKE_PATH" | tail -1 | sed 's/.*\/\([^"]*\)".*/\1/')
	fi

	echo "${current_hash:-unknown}"
}

# Flake.nix'i güncelle
update_flake() {
	local new_commit="$1"
	local today=$(date +%m%d)

	log_info "Flake.nix güncelleniyor..."

	# Backup dizinini oluştur ve backup al
	mkdir -p "$HOME/.nixosb"
	cp "$FLAKE_PATH" "$HOME/.nixosb/flake.nix.backup.$(date +%Y%m%d_%H%M%S)"
	log_info "Backup oluşturuldu: $HOME/.nixosb/"

	# Python ile güncelle
	python3 -c "
import re

with open('$FLAKE_PATH', 'r') as f:
    content = f.read()

lines = content.split('\n')
new_lines = []
in_hyprland = False
url_added = False

for line in lines:
    if 'hyprland = {' in line:
        in_hyprland = True
        new_lines.append(line)
    elif in_hyprland and 'url = \"github:hyprwm/hyprland/' in line:
        if not line.strip().startswith('#'):
            new_lines.append('      #' + line)
        else:
            new_lines.append(line)
        if not url_added:
            new_lines.append('      url = \"github:hyprwm/hyprland/$new_commit\"; # $today - Updated Commits')
            url_added = True
    elif in_hyprland and line.strip() == '};':
        if not url_added:
            new_lines.append('      url = \"github:hyprwm/hyprland/$new_commit\"; # $today - Updated Commits')
        new_lines.append(line)
        in_hyprland = False
    else:
        new_lines.append(line)

with open('$FLAKE_PATH', 'w') as f:
    f.write('\n'.join(new_lines))
"
}

# Ana fonksiyon
main() {
	log_info "Hyprland commit güncelleyici başlatılıyor..."

	if [[ ! -f "$FLAKE_PATH" ]]; then
		log_error "Flake.nix bulunamadı: $FLAKE_PATH"
		exit 1
	fi

	local current_commit
	current_commit=$(get_current_commit)
	log_info "Mevcut commit: $current_commit"

	local latest_commit
	latest_commit=$(get_latest_commit)
	log_info "Son commit: $latest_commit"

	if [[ "$current_commit" == "$latest_commit" ]]; then
		log_success "Zaten son commit kullanılıyor."
		exit 0
	fi

	update_flake "$latest_commit"

	if command grep -q "url = \"github:hyprwm/hyprland/$latest_commit\"" "$FLAKE_PATH"; then
		log_success "Flake.nix başarıyla güncellendi!"
		log_info "Eski: $current_commit"
		log_info "Yeni: $latest_commit"
		echo
		log_info "Rebuild için:"
		echo -e "${YELLOW}cd ~/.nixosc && sudo nixos-rebuild switch --flake .#$(hostname)${NC}"
	else
		log_error "Güncelleme başarısız!"
		exit 1
	fi
}

main "$@"
