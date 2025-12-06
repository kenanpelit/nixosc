#!/usr/bin/env bash
#
# VIR - Vim Remote Editor
# ----------------------
# A powerful utility to seamlessly edit remote files over SSH using Vim's SCP functionality.
#
# Features:
# - Auto-detects SSH users from config
# - Supports custom SSH ports
# - Allows different editors (nvim, neovim, etc.)
# - SSH key management
# - Pre-edit file existence and permission checking
# - Automatic backups in ~/.vir directory
# - Directory browsing support
# - Colorful, informative output
#
#   Version: 2.0.0
#   Date: 2025-03-17
#   Author: Kenan Pelit
#   Repository: https://github.com/kenanpelit/nixosc
#   License: MIT
#
# Usage: ./vir.sh [options] [user@]hostname path/to/file [nvim-options]

set -e # Stop script on error

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions
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
	echo "  $0 [options] [user@]hostname path/to/file [nvim-options]"
	echo
	echo "Options:"
	echo "  -h, --help              Show this help message"
	echo "  -p, --port PORT         Specify SSH port (default: 22)"
	echo "  -e, --editor EDITOR     Specify editor to use (default: nvim)"
	echo "  -i, --identity FILE     Specify identity file for SSH"
	echo "  -c, --check             Check if the file exists before opening"
	echo "  -w, --writeable         Check if the file is writeable before opening"
	echo "  -b, --backup            Create a backup before editing (stored in ~/.vir)"
	echo "  -d, --directory DIR     Browse directory contents"
	echo
	echo "Examples:"
	echo "  $0 admin@server.example.com /etc/nginx/nginx.conf"
	echo "  $0 -p 2222 server.example.com /etc/nginx/nginx.conf"
	echo "  $0 -e nvim -i ~/.ssh/custom_key server.example.com /var/log/messages"
	echo "  $0 -c -w -b server.example.com ~/scripts/backup.sh"
	echo "  $0 -d server.example.com /etc/nginx/"
}

# Default values
PORT=22
EDITOR="nvim"
IDENTITY_FILE=""
CHECK_FILE=false
CHECK_WRITABLE=false
CREATE_BACKUP=false
DIRECTORY_MODE=false

# Process command line arguments
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
	-w | --writeable)
		CHECK_WRITABLE=true
		shift
		;;
	-b | --backup)
		CREATE_BACKUP=true
		shift
		;;
	-d | --directory)
		DIRECTORY_MODE=true
		shift
		;;
	*)
		POSITIONAL+=("$1")
		shift
		;;
	esac
done
set -- "${POSITIONAL[@]}" # Restore positional arguments

# Check if enough arguments are provided
if [ $# -lt 2 ]; then
	echo -e "${RED}Error:${NC} Not enough arguments provided."
	echo "A server and remote file path are required."
	echo
	show_usage
	exit 1
fi

SERVER="$1"
REMOTE_PATH="$2"
shift 2 # Remove the first two arguments

# Check if editor exists
if ! command -v "$EDITOR" &>/dev/null; then
	print_error "Editor '$EDITOR' not found. Please install it or use a different editor."
	exit 1
fi

# Set up backup directory
BACKUP_DIR="$HOME/.vir"
if [ "$CREATE_BACKUP" = true ]; then
	if [ ! -d "$BACKUP_DIR" ]; then
		print_info "Creating backup directory at $BACKUP_DIR"
		mkdir -p "$BACKUP_DIR"
	fi
fi

# Check if user is specified in SERVER
if [[ "$SERVER" != *"@"* ]]; then
	# No user specified, check if it's in ssh config
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

# SSH connection options
SSH_OPTS=()
if [ -n "$IDENTITY_FILE" ]; then
	SSH_OPTS+=(-i "$IDENTITY_FILE")
fi
if [ "$PORT" -ne 22 ]; then
	SSH_OPTS+=(-p "$PORT")
fi

# Test SSH connection
print_info "Testing SSH connection to $FULL_SERVER..."
if ! ssh "${SSH_OPTS[@]}" -o BatchMode=yes -o ConnectTimeout=5 "$FULL_SERVER" exit 2>/dev/null; then
	print_error "Failed to connect to $FULL_SERVER. Please check your SSH configuration."
	exit 1
fi
print_success "SSH connection successful."

# Handle directory mode
if [ "$DIRECTORY_MODE" = true ]; then
	print_info "Directory mode activated. Browsing $REMOTE_PATH"

	# Check if the path is a directory
	if ! ssh "${SSH_OPTS[@]}" "$FULL_SERVER" "[ -d $REMOTE_PATH ]"; then
		print_error "$REMOTE_PATH is not a directory on the remote server."
		exit 1
	fi

	# Create SCP URL with proper format
	if [[ "$REMOTE_PATH" == /* ]]; then
		# Absolute path
		DIR_PATH="$REMOTE_PATH"
	else
		# Relative path, prefix with home
		DIR_PATH="~/$REMOTE_PATH"
	fi

	# Create SCP URL for directory
	if [ "$PORT" -ne 22 ]; then
		SCP_URL="scp://${FULL_SERVER}:${PORT}/$DIR_PATH"
	else
		SCP_URL="scp://${FULL_SERVER}/$DIR_PATH"
	fi

	# Editor command line options
	EDITOR_OPTS=()
	if [ -n "$IDENTITY_FILE" ]; then
		EDITOR_OPTS+=(-c "let g:netrw_scp_cmd=\"scp -i $IDENTITY_FILE\"")
	fi

	print_info "Opening directory $SCP_URL with $EDITOR..."
	"$EDITOR" "${EDITOR_OPTS[@]}" "$SCP_URL" "$@"
	print_success "Done browsing $REMOTE_PATH on $FULL_SERVER."
	exit 0
fi

# Process the single file
if [[ "$REMOTE_PATH" == /* ]]; then
	# Absolute path
	REMOTE_FILE="$REMOTE_PATH"
else
	# Relative path, prefix with ~/ to make it relative to home
	print_info "Converting relative path to home-relative path"
	REMOTE_FILE="~/$REMOTE_PATH"
fi

# Create SCP URL with proper format
if [ "$PORT" -ne 22 ]; then
	# Port specified
	SCP_URL="scp://${FULL_SERVER}:${PORT}/$REMOTE_FILE"
else
	SCP_URL="scp://${FULL_SERVER}/$REMOTE_FILE"
fi

# Check if file exists
if [ "$CHECK_FILE" = true ]; then
	print_info "Checking if the file exists on the remote server..."
	if ! ssh "${SSH_OPTS[@]}" "$FULL_SERVER" "[ -f ${REMOTE_FILE/#\~/$HOME} ] || [ -f $REMOTE_FILE ]"; then
		print_warning "File does not exist on the remote server. It will be created when saved."
	else
		print_success "File exists on the remote server."
	fi
fi

# Check if file is writable
if [ "$CHECK_WRITABLE" = true ]; then
	print_info "Checking if the file is writable..."
	if ! ssh "${SSH_OPTS[@]}" "$FULL_SERVER" "[ -w ${REMOTE_FILE/#\~/$HOME} ] || [ -w $REMOTE_FILE ]"; then
		print_warning "File is not writable. You may not be able to save changes."
	else
		print_success "File is writable."
	fi
fi

# Create backup if requested
if [ "$CREATE_BACKUP" = true ]; then
	print_info "Creating backup of remote file..."

	# Create timestamp and server-specific directory
	TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
	SERVER_DIRNAME=$(echo "$FULL_SERVER" | tr '@:/' '_')
	BACKUP_SUBDIR="$BACKUP_DIR/$SERVER_DIRNAME"
	mkdir -p "$BACKUP_SUBDIR"

	# Get filename
	FILENAME=$(basename "$REMOTE_FILE")
	BACKUP_FILENAME="${FILENAME}_${TIMESTAMP}"

	# Download the file for backup if it exists
	if ssh "${SSH_OPTS[@]}" "$FULL_SERVER" "[ -f ${REMOTE_FILE/#\~/$HOME} ] || [ -f $REMOTE_FILE ]"; then
		scp "${SSH_OPTS[@]}" "${FULL_SERVER}:${REMOTE_FILE}" "$BACKUP_SUBDIR/$BACKUP_FILENAME"
		print_success "Backup created at $BACKUP_SUBDIR/$BACKUP_FILENAME"
	else
		print_warning "No backup created as file does not exist yet."
	fi
fi

# Editor command line options
EDITOR_OPTS=()
if [ -n "$IDENTITY_FILE" ]; then
	# Add Vim SCP identity file parameter
	EDITOR_OPTS+=(-c "let g:netrw_scp_cmd=\"scp -i $IDENTITY_FILE\"")
fi

print_info "Opening $SCP_URL with $EDITOR..."
"$EDITOR" "${EDITOR_OPTS[@]}" "$SCP_URL" "$@"

print_success "Done editing $REMOTE_FILE on $FULL_SERVER."
