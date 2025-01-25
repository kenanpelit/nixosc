#!/usr/bin/env bash

# ==============================================================================
# Secret Management Script for NixOS
# Description: SOPS ve AGE tabanlı gizli bilgi yönetimi
# Author: kenanpelit
# ==============================================================================

set -euo pipefail

# Renk tanımlamaları
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m'

# Log fonksiyonları
log_info() { echo -e "${BLUE}INFO:${NC} ${1:-}"; }
log_success() { echo -e "${GREEN}SUCCESS:${NC} ${1:-}"; }
log_error() { echo -e "${RED}ERROR:${NC} ${1:-}" >&2; }
log_warn() { echo -e "${YELLOW}WARN:${NC} ${1:-}"; }

# Yardım mesajı
show_help() {
	cat <<EOF
Kullanım: $(basename "$0") [SEÇENEK] <komut>

Secret yönetim aracı - SOPS ve AGE kullanarak gizli bilgileri şifreler

Komutlar:
   init        AGE ve SOPS yapılandırmasını oluştur
   create      Yeni secret dosyaları oluştur
   check       Mevcut yapılandırmayı kontrol et

Seçenekler:
   -h, --help  Bu mesajı göster
   -f, --force Mevcut dosyaların üzerine yaz

Örnekler:
   $(basename "$0") init              # Temel yapılandırmayı oluştur
   $(basename "$0") create home       # Home secrets oluştur
   $(basename "$0") check             # Yapılandırmayı kontrol et

Not: Dosya isimlendirme kuralı: <type>-secrets.[enc.]yaml
    örn: home-secrets.yaml, system-secrets.enc.yaml
EOF
}

# Dizin yapısı
setup_directories() {
	log_info "Gerekli dizinler oluşturuluyor..."
	mkdir -p ~/.config/sops/age
	mkdir -p secrets
}

# AGE key yönetimi
setup_age_key() {
	if [[ ! -f ~/.config/sops/age/keys.txt ]]; then
		log_info "AGE key oluşturuluyor..."
		age-keygen -o ~/.config/sops/age/keys.txt
		log_success "AGE key oluşturuldu: ~/.config/sops/age/keys.txt"
	else
		log_info "AGE key mevcut: ~/.config/sops/age/keys.txt"
	fi
}

# SOPS yapılandırması
create_sops_config() {
	log_info ".sops.yaml dosyası oluşturuluyor..."
	PUBLIC_KEY=$(age-keygen -y ~/.config/sops/age/keys.txt)

	cat >.sops.yaml <<EOF
---
creation_rules:
 - path_regex: ^(secrets|assets)/.*$
   encrypted_regex: '^(.*)$'
   key_groups:
     - age:
         - "${PUBLIC_KEY}"

 - path_regex: ^config/.*\.secret\.yaml$
   key_groups:
     - age:
         - "${PUBLIC_KEY}"

 - path_regex: .*\.(secret|encrypted|enc)\..*$
   key_groups:
     - age:
         - "${PUBLIC_KEY}"
EOF
	log_success ".sops.yaml oluşturuldu"
}

# Secret oluşturma
create_secrets() {
	local type="${1:-home}"
	local yaml_file="secrets/${type}-secrets.yaml"
	local enc_file="secrets/${type}-secrets.enc.yaml"

	# Mevcut dosya kontrolü
	if [[ -f "$enc_file" ]]; then
		log_warn "$enc_file zaten mevcut"
		return 0
	fi

	# Template oluştur
	cat >"$yaml_file" <<EOF
# ${type^} Secrets Configuration
# Oluşturulma: $(date +%Y-%m-%d)

secrets:
   example_key: "example_value"
EOF

	# SOPS ile şifrele
	SOPS_AGE_KEY_FILE=~/.config/sops/age/keys.txt sops -e "$yaml_file" >"$enc_file"
	rm "$yaml_file"

	log_success "${type^} secrets oluşturuldu: $enc_file"
}

# Ana fonksiyon
main() {
	# Bağımlılık kontrolü
	if ! command -v sops &>/dev/null || ! command -v age &>/dev/null; then
		log_error "sops ve age kurulu değil. Kurulum için:"
		echo "nix-shell -p sops age"
		exit 1
	fi

	# Parametre kontrolü
	[[ "$#" -eq 0 ]] && {
		show_help
		exit 1
	}

	# Komut işleme
	case "${1:-}" in
	-h | --help) show_help ;;
	init)
		setup_directories
		setup_age_key
		create_sops_config
		;;
	create)
		[[ -z "${2:-}" ]] && {
			log_error "Secret tipi belirtilmedi"
			exit 1
		}
		create_secrets "$2"
		;;
	check)
		[[ -f ~/.config/sops/age/keys.txt ]] && log_success "AGE key OK" || log_error "AGE key yok"
		[[ -f .sops.yaml ]] && log_success "SOPS config OK" || log_error "SOPS config yok"
		;;
	*)
		log_error "Geçersiz komut: ${1:-}"
		show_help
		exit 1
		;;
	esac

	log_success "İşlem tamamlandı!"
}

main "$@"
