#!/usr/bin/env bash
# ==============================================================================
# Secret Management Script for NixOS
# Description: SOPS ve AGE tabanlı gizli bilgi yönetimi
# Author: kenanpelit
# ==============================================================================
set -euo pipefail

# NixOS config dizinini bul
find_nixos_config_dir() {
	local current_dir="$PWD"

	# Önce mevcut dizinde kontrol et
	if [[ -f "$current_dir/flake.nix" && -d "$current_dir/secrets" ]]; then
		echo "$current_dir"
		return 0
	fi

	# ~/.nixosc dizininde kontrol et
	if [[ -f "$HOME/.nixosc/flake.nix" && -d "$HOME/.nixosc/secrets" ]]; then
		echo "$HOME/.nixosc"
		return 0
	fi

	# Parent dizinlerde ara
	local dir="$current_dir"
	while [[ "$dir" != "/" ]]; do
		if [[ -f "$dir/flake.nix" && -d "$dir/secrets" ]]; then
			echo "$dir"
			return 0
		fi
		dir=$(dirname "$dir")
	done

	# Bulunamazsa varsayılan
	echo "$HOME/.nixosc"
}

# NixOS config dizinini ayarla
NIXOS_CONFIG_DIR=$(find_nixos_config_dir)

# Çalışma dizinini değiştir
cd "$NIXOS_CONFIG_DIR" || {
	echo "HATA: NixOS config dizini bulunamadı: $NIXOS_CONFIG_DIR"
	exit 1
}

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
Kullanım: $(basename "$0") [SEÇENEK] <komut> [args]

Secret yönetim aracı - SOPS ve AGE kullanarak gizli bilgileri şifreler

Komutlar:
   init              AGE ve SOPS yapılandırmasını oluştur
   create <type>     Yeni secret dosyaları oluştur
   edit <type>       Mevcut secret dosyasını düzenle
   view <type>       Secret dosyasını görüntüle (salt okunur)
   check             Mevcut yapılandırmayı kontrol et

Seçenekler:
   -h, --help        Bu mesajı göster
   -f, --force       Mevcut dosyaların üzerine yaz

Örnekler:
   $(basename "$0") init              # Temel yapılandırmayı oluştur
   $(basename "$0") create home       # Home secrets oluştur
   $(basename "$0") edit home         # Home secrets düzenle
   $(basename "$0") view wireless     # Wireless secrets görüntüle
   $(basename "$0") check             # Yapılandırmayı kontrol et

Not: Dosya isimlendirme kuralı: <type>-secrets.[enc.]yaml
    örn: home-secrets.yaml, system-secrets.enc.yaml

Mevcut secret dosyaları:
$(find "$NIXOS_CONFIG_DIR/secrets" -name "*.enc.yaml" 2>/dev/null | sed "s|$NIXOS_CONFIG_DIR/secrets/||; s/-secrets\.enc\.yaml//" | sort | sed 's/^/   - /' || echo "   Henüz secret dosyası yok")

NixOS Config Dizini: $NIXOS_CONFIG_DIR
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

# Secret dosya yolu belirleme
get_secret_path() {
	local type="$1"
	echo "secrets/${type}-secrets.enc.yaml"
}

# Secret dosyası varlık kontrolü
check_secret_exists() {
	local type="$1"
	local enc_file
	enc_file=$(get_secret_path "$type")

	if [[ ! -f "$enc_file" ]]; then
		log_error "Secret dosyası bulunamadı: $enc_file"
		log_info "Önce şu komutla oluşturun: $(basename "$0") create $type"
		return 1
	fi
	return 0
}

# Secret oluşturma
create_secrets() {
	local type="${1:-home}"
	local yaml_file="secrets/${type}-secrets.yaml"
	local enc_file
	enc_file=$(get_secret_path "$type")

	# Mevcut dosya kontrolü
	if [[ -f "$enc_file" ]]; then
		log_warn "$enc_file zaten mevcut"
		read -p "Üzerine yazmak istiyor musunuz? (y/N): " -n 1 -r
		echo
		if [[ ! $REPLY =~ ^[Yy]$ ]]; then
			log_info "İşlem iptal edildi"
			return 0
		fi
	fi

	# Template oluştur
	cat >"$yaml_file" <<EOF
# ${type^} Secrets Configuration
# Oluşturulma: $(date +%Y-%m-%d)
# 
# Bu dosya SOPS ile şifrelenir. Düzenlemek için:
# $(basename "$0") edit $type

secrets:
   # Örnek kullanım:
   # example_key: "example_value"
   # api_token: "your-api-token-here"
   # password: "your-secure-password"
   
   example_key: "example_value"
EOF

	# SOPS ile şifrele
	log_info "Secret dosyası şifreleniyor..."
	SOPS_AGE_KEY_FILE=~/.config/sops/age/keys.txt sops -e "$yaml_file" >"$enc_file"
	rm "$yaml_file"

	log_success "${type^} secrets oluşturuldu: $enc_file"
	log_info "Düzenlemek için: $(basename "$0") edit $type"
}

# Secret düzenleme
edit_secret() {
	local type="$1"
	local enc_file
	enc_file=$(get_secret_path "$type")

	# Dosya varlık kontrolü
	if ! check_secret_exists "$type"; then
		return 1
	fi

	log_info "$type secrets düzenleniyor..."

	# Editor belirleme (öncelik sırası: EDITOR, VISUAL, vim, nano)
	local editor="${EDITOR:-${VISUAL:-}}"
	if [[ -z "$editor" ]]; then
		if command -v vim >/dev/null 2>&1; then
			editor="vim"
		elif command -v nano >/dev/null 2>&1; then
			editor="nano"
		else
			log_error "Uygun editör bulunamadı. EDITOR environment değişkenini ayarlayın."
			return 1
		fi
	fi

	# SOPS ile edit
	SOPS_AGE_KEY_FILE=~/.config/sops/age/keys.txt EDITOR="$editor" sops "$enc_file"

	log_success "$type secrets güncellendi"
}

# Secret görüntüleme
view_secret() {
	local type="$1"
	local enc_file
	enc_file=$(get_secret_path "$type")

	# Dosya varlık kontrolü
	if ! check_secret_exists "$type"; then
		return 1
	fi

	log_info "$type secrets görüntüleniyor..."
	echo "----------------------------------------"

	# SOPS ile decrypt ve görüntüle
	SOPS_AGE_KEY_FILE=~/.config/sops/age/keys.txt sops -d "$enc_file"

	echo "----------------------------------------"
	log_info "Düzenlemek için: $(basename "$0") edit $type"
}

# Mevcut secret dosyalarını listele
list_secrets() {
	log_info "Mevcut secret dosyaları:"

	if ! ls "$NIXOS_CONFIG_DIR/secrets"/*.enc.yaml >/dev/null 2>&1; then
		echo "   Henüz secret dosyası yok"
		return 0
	fi

	for file in "$NIXOS_CONFIG_DIR/secrets"/*.enc.yaml; do
		local basename_file
		basename_file=$(basename "$file" .enc.yaml)
		local type="${basename_file%-secrets}"
		local size
		size=$(stat -f%z "$file" 2>/dev/null || stat -c%s "$file" 2>/dev/null || echo "?")
		local date
		date=$(stat -f%Sm -t"%Y-%m-%d %H:%M" "$file" 2>/dev/null || stat -c%y "$file" 2>/dev/null | cut -d' ' -f1,2 | cut -d: -f1,2 || echo "?")

		printf "   %-15s %8s bytes  %s\n" "$type" "$size" "$date"
	done

	echo
	log_info "NixOS Config Dizini: $NIXOS_CONFIG_DIR"
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
	-h | --help)
		show_help
		;;
	init)
		setup_directories
		setup_age_key
		create_sops_config
		;;
	create)
		[[ -z "${2:-}" ]] && {
			log_error "Secret tipi belirtilmedi"
			echo "Kullanım: $(basename "$0") create <type>"
			exit 1
		}
		create_secrets "$2"
		;;
	edit)
		[[ -z "${2:-}" ]] && {
			log_error "Secret tipi belirtilmedi"
			echo "Kullanım: $(basename "$0") edit <type>"
			list_secrets
			exit 1
		}
		edit_secret "$2"
		;;
	view)
		[[ -z "${2:-}" ]] && {
			log_error "Secret tipi belirtilmedi"
			echo "Kullanım: $(basename "$0") view <type>"
			list_secrets
			exit 1
		}
		view_secret "$2"
		;;
	check)
		[[ -f ~/.config/sops/age/keys.txt ]] && log_success "AGE key OK" || log_error "AGE key yok"
		[[ -f .sops.yaml ]] && log_success "SOPS config OK" || log_error "SOPS config yok"
		list_secrets
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
