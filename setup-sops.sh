#!/usr/bin/env bash
set -euo pipefail

# Renk tanımlamaları
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

# Fonksiyonlar
log_info() {
  local message="${1:-}"
  echo -e "${BLUE}INFO:${NC} ${message}"
}

log_success() {
  local message="${1:-}"
  echo -e "${GREEN}SUCCESS:${NC} ${message}"
}

log_error() {
  local message="${1:-}"
  echo -e "${RED}ERROR:${NC} ${message}" >&2
}

# Gerekli dizinlerin oluşturulması
setup_directories() {
  log_info "Gerekli dizinler oluşturuluyor..."
  mkdir -p ~/.config/sops/age
  mkdir -p secrets
}

# Age key kontrolü ve oluşturulması
setup_age_key() {
  if [[ ! -f ~/.config/sops/age/keys.txt ]]; then
    log_info "Age key oluşturuluyor..."
    age-keygen -o ~/.config/sops/age/keys.txt
    log_success "Age key oluşturuldu: ~/.config/sops/age/keys.txt"
  else
    log_info "Age key zaten mevcut: ~/.config/sops/age/keys.txt"
  fi
}

# .sops.yaml dosyasının oluşturulması
create_sops_config() {
  log_info ".sops.yaml dosyası oluşturuluyor..."

  # Public key'i al
  PUBLIC_KEY=$(age-keygen -y ~/.config/sops/age/keys.txt)

  # .sops.yaml dosyasını oluştur
  cat >.sops.yaml <<EOF
creation_rules:
    - path_regex: '.*\.yaml$'
      age: >-
        ${PUBLIC_KEY}
EOF

  log_success ".sops.yaml dosyası oluşturuldu"
}

# SSH host key oluşturma ve şifreleme
create_ssh_keys() {
  local host="${1:-}"
  local WORK_DIR

  # Cleanup fonksiyonu
  cleanup() {
    [[ -n "${WORK_DIR:-}" ]] && [[ -d "${WORK_DIR}" ]] && rm -rf "${WORK_DIR}"
  }

  # Geçici dizin oluştur
  WORK_DIR=$(mktemp -d)
  trap cleanup EXIT

  log_info "SSH host key oluşturuluyor..."

  # SSH key oluştur
  ssh-keygen -o -a 100 -t ed25519 -f "${WORK_DIR}/ssh_host_ed25519_key" -N "" -C "root@${host}"

  log_info "secrets.yaml dosyası hazırlanıyor..."

  # Geçici YAML dosyası oluştur
  cat >"${WORK_DIR}/temp.yaml" <<EOF
${host}_ssh_host_ed25519_key: |
$(sed 's/^/    /' "${WORK_DIR}/ssh_host_ed25519_key")
EOF

  # SOPS ile şifrele
  SOPS_AGE_KEY_FILE=~/.config/sops/age/keys.txt sops -e "${WORK_DIR}/temp.yaml" >secrets/secrets.yaml

  # Public key'i kopyala
  cp "${WORK_DIR}/ssh_host_ed25519_key.pub" "secrets/${host}_ssh_host_ed25519_key.pub"

  log_success "SSH keyleri oluşturuldu ve şifrelendi"
}

# Ana fonksiyon
main() {
  # Gerekli bağımlılıkları kontrol et
  if ! command -v sops &>/dev/null || ! command -v age &>/dev/null; then
    log_error "sops ve age kurulu değil. Lütfen önce şu komutu çalıştırın:"
    echo "nix-shell -p sops age"
    exit 1
  fi

  # Host parametresini kontrol et
  if [[ "$#" -ne 1 ]]; then
    log_error "Kullanım: $0 <host_name>"
    exit 1
  fi

  local host="${1:-}"

  # Ana işlemleri gerçekleştir
  setup_directories
  setup_age_key
  create_sops_config
  create_ssh_keys "$host"

  # Sonuç bilgisi
  log_success "Tüm işlemler tamamlandı!"
  log_info "Oluşturulan dosyalar:"
  echo "  - ~/.config/sops/age/keys.txt"
  echo "  - .sops.yaml"
  echo "  - secrets/secrets.yaml"
  echo "  - secrets/${host}_ssh_host_ed25519_key.pub"
}

# Scripti çalıştır
main "$@"
