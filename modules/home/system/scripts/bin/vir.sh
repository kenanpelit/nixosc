#!/usr/bin/env bash
#
# VIR - Vim Remote Editor
# ----------------------
# A powerful utility to seamlessly edit remote files over SSH using Vim's SCP functionality.
#
# Features:
# - Auto-detects SSH users from config
# - Supports custom SSH ports
# - Allows different editors (vim, neovim, etc.)
# - SSH key management
# - Pre-edit file existence checking
# - Colorful, informative output
#
#   Version: 1.0.0
#   Date: 2024-03-01
#   Author: Kenan Pelit
#   Repository: https://github.com/kenanpelit/nixosc
#   License: MIT
#
# Usage: ./vir.sh [user@]hostname path/to/file [vim-options]

set -e # Hata durumunda betiği durdur

# Renk tanımlamaları
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Fonksiyonlar
function print_info() {
	echo -e "${BLUE}[INFO]${NC} $1"
}

function print_success() {
	echo -e "${GREEN}[SUCCESS]${NC} $1"
}

function print_warning() {
	echo -e "${YELLOW}[WARNING]${NC} $1"
}

function print_error() {
	echo -e "${RED}[ERROR]${NC} $1" >&2
}

function show_usage() {
	echo "VIR - Vim Remote Editor"
	echo "----------------------"
	echo "Seamlessly edit remote files over SSH using Vim's SCP functionality."
	echo
	echo "Usage:"
	echo "  $0 [options] [user@]hostname path/to/file [vim-options]"
	echo
	echo "Options:"
	echo "  -h, --help              Show this help message"
	echo "  -p, --port PORT         Specify SSH port (default: 22)"
	echo "  -e, --editor EDITOR     Specify editor to use (default: vim)"
	echo "  -i, --identity FILE     Specify identity file for SSH"
	echo "  -c, --check             Check if the file exists before opening"
	echo
	echo "Examples:"
	echo "  $0 admin@server.example.com /etc/nginx/nginx.conf"
	echo "  $0 -p 2222 server.example.com /etc/nginx/nginx.conf"
	echo "  $0 -e nvim -i ~/.ssh/custom_key server.example.com /var/log/messages"
	echo "  $0 -c server.example.com ~/scripts/backup.sh"
}

# Varsayılan değerler
PORT=22
EDITOR="vim"
IDENTITY_FILE=""
CHECK_FILE=false

# Komut satırı argümanlarını işle
POSITIONAL=()
while [[ $# -gt 0 ]]; do
	key="$1"

	case $key in
	-h | --help)
		show_usage
		exit 0
		;;
	-p | --port)
		PORT="$2"
		shift 2
		;;
	-e | --editor)
		EDITOR="$2"
		shift 2
		;;
	-i | --identity)
		IDENTITY_FILE="$2"
		shift 2
		;;
	-c | --check)
		CHECK_FILE=true
		shift
		;;
	*)
		POSITIONAL+=("$1")
		shift
		;;
	esac
done
set -- "${POSITIONAL[@]}" # Pozisyonel argümanları geri yükle

# Yeterli argüman sağlanıp sağlanmadığını kontrol et
if [ $# -lt 2 ]; then
	echo -e "${RED}Error:${NC} Not enough arguments provided."
	echo "A server and remote file path are required."
	echo
	show_usage
	exit 1
fi

SERVER="$1"
REMOTE_FILE="$2"
shift 2 # İlk iki argümanı kaldır

# Editörün var olup olmadığını kontrol et
if ! command -v "$EDITOR" &>/dev/null; then
	print_error "Editor '$EDITOR' not found. Please install it or use a different editor."
	exit 1
fi

# SERVER içinde kullanıcı belirtilip belirtilmediğini kontrol et
if [[ "$SERVER" != *"@"* ]]; then
	# Kullanıcı belirtilmemiş, ssh yapılandırmasında olup olmadığını kontrol et
	SSH_USER=$(ssh -G "$SERVER" 2>/dev/null | grep "^user " | cut -d' ' -f2)
	if [ -n "$SSH_USER" ]; then
		print_info "Using SSH config user: $SSH_USER"
		FULL_SERVER="${SSH_USER}@${SERVER}"
	else
		print_warning "No user specified and no user found in ssh config."
		print_info "Using current user: $(whoami)"
		FULL_SERVER="$(whoami)@${SERVER}"
	fi
else
	FULL_SERVER="$SERVER"
fi

# Dosya yolunun mutlak olup olmadığını kontrol et
if [[ "$REMOTE_FILE" != /* ]]; then
	# Göreceli yol, ev dizinine göre göreceli olması için ~/ ile başlat
	print_info "Converting relative path to home-relative path"
	REMOTE_FILE="~/$REMOTE_FILE"
fi

# SCP URL'sini oluştur
if [ "$PORT" -ne 22 ]; then
	# Port belirtilmişse, özel port ile SCP URL'si oluştur
	SCP_URL="scp://${FULL_SERVER}:${PORT}/${REMOTE_FILE}"
else
	SCP_URL="scp://${FULL_SERVER}/${REMOTE_FILE}"
fi

# SSH bağlantısını test et
print_info "Testing SSH connection to $FULL_SERVER..."
SSH_OPTS=()
if [ -n "$IDENTITY_FILE" ]; then
	SSH_OPTS+=(-i "$IDENTITY_FILE")
fi
if [ "$PORT" -ne 22 ]; then
	SSH_OPTS+=(-p "$PORT")
fi

if ! ssh "${SSH_OPTS[@]}" -o BatchMode=yes -o ConnectTimeout=5 "$FULL_SERVER" exit 2>/dev/null; then
	print_error "Failed to connect to $FULL_SERVER. Please check your SSH configuration."
	exit 1
fi
print_success "SSH connection successful."

# Dosyanın varlığını kontrol et
if [ "$CHECK_FILE" = true ]; then
	print_info "Checking if the file exists on the remote server..."
	if ! ssh "${SSH_OPTS[@]}" "$FULL_SERVER" "[ -f ${REMOTE_FILE/#\~/$HOME} ] || [ -f $REMOTE_FILE ]"; then
		print_warning "File does not exist on the remote server. It will be created when saved."
	else
		print_success "File exists on the remote server."
	fi
fi

# Editör komut satırı parametrelerini oluştur
EDITOR_OPTS=()
if [ -n "$IDENTITY_FILE" ]; then
	# Vim SCP özel kimlik dosyası parametresini ekle
	EDITOR_OPTS+=(-c "let g:netrw_scp_cmd=\"scp -i $IDENTITY_FILE\"")
fi

print_info "Opening $SCP_URL with $EDITOR..."

# Vim, SCP URL ve ek argümanlarla yürüt
"$EDITOR" "${EDITOR_OPTS[@]}" "$SCP_URL" "$@"

print_success "Done editing $REMOTE_FILE on $FULL_SERVER."
