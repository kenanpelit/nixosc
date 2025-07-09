#!/usr/bin/env bash
#===============================================================================
#
#   Script: OSC SSH Master Utility
#   Version: 1.0.0
#   Date: 2024-05-05
#   Author: Kenan Pelit
#   Repository: https://github.com/kenanpelit/nixosc
#   Description: Comprehensive SSH management utility combining ASSH management,
#                session control, hosts backup, and secure connection setup
#
#   Features:
#   - Host management and shell completion with ASSH integration
#   - SSH control socket management (listing, cleaning, monitoring)
#   - Remote hosts file backup capabilities
#   - Passwordless SSH setup with Ed25519 keys
#   - XDG Base Directory compliance
#   - Comprehensive logging and error handling
#
#   License: MIT
#
#===============================================================================

# Colors for messages
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# ASCII Art Banner
BANNER="
╔═══════════════════════════════════════════╗
║           OSC SSH Master Utility          ║
║       All-in-One SSH Management Tool      ║
╚═══════════════════════════════════════════╝"

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

# SSH control directory
CONTROL_DIR="$HOME/.ssh/controlmasters"
LOG_FILE="$HOME/.ssh/ssh-master-utility.log"

# Hosts backup directory
HOSTS_DIR="$HOME/.anote/hosts"

# Message functions
success_msg() { echo -e "${GREEN}✔ $1${NC}"; }
error_msg() { echo -e "${RED}✘ $1${NC}" >&2; }
info_msg() { echo -e "${BLUE}ℹ $1${NC}"; }
warn_msg() { echo -e "${YELLOW}⚠ $1${NC}"; }

# Logging function
log() {
	echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >>"$LOG_FILE"
	if [ "$2" = "verbose" ]; then
		info_msg "$1"
	fi
}

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
	mkdir -p "$CACHE_DIR" "$BASH_COMPLETION_DIR" "$ZSH_COMPLETION_DIR" "$FISH_COMPLETION_DIR" "$CONTROL_DIR" "$HOSTS_DIR"
	chmod 700 "$CONTROL_DIR"
	log "Created required directories" "verbose"
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
			success_msg "assh is already at the latest version (v$INSTALLED_VERSION)."
			return
		else
			warn_msg "Installed version: v$INSTALLED_VERSION, Latest version: v$LATEST_ASSH_VERSION"
			read -rp "Do you want to update assh? (y) Yes, (n) No: " choice
			if [[ "$choice" != "y" ]]; then
				info_msg "assh update skipped."
				return
			fi
		fi
	else
		info_msg "assh is not installed. Starting installation..."
	fi

	info_msg "Downloading and installing assh..."
	(
		mkdir -p "$ASSH_BACKUP_DIR"
		if curl -Lo "$ASSH_BACKUP_DIR/assh.tar.gz" "$ASSH_URL"; then
			tar -xzvf "$ASSH_BACKUP_DIR/assh.tar.gz" -C "$ASSH_BACKUP_DIR" &
			spinner
			sudo mv "$ASSH_BACKUP_DIR/assh" "$ASSH_BIN"
			sudo chmod +x "$ASSH_BIN"
			rm -f "$ASSH_BACKUP_DIR/assh.tar.gz"
		else
			error_msg "Failed to download assh. Check your internet connection or GitHub access."
			return 1
		fi
	)

	if command -v assh &>/dev/null; then
		success_msg "assh successfully installed or updated and backed up under $ASSH_BACKUP_DIR."
		log "assh installed/updated to version $LATEST_ASSH_VERSION" "verbose"
	else
		error_msg "assh installation failed. File not found at /usr/local/bin/assh."
		log "assh installation failed" "verbose"
		return 1
	fi
}

# Update SSH host cache
update_cache() {
	info_msg "Updating host cache..."
	local temp_file="$CACHE_DIR/temp_hosts"

	if ! assh config list | grep -v '^#' | grep -v '^$' | awk '{print $1}' | sort >"$temp_file"; then
		error_msg "Failed to get host list from assh config"
		log "Host cache update failed" "verbose"
		return 1
	fi

	if [ ! -s "$temp_file" ]; then
		error_msg "No hosts found in assh config"
		rm -f "$temp_file"
		log "No hosts found in assh config" "verbose"
		return 1
	fi

	mv "$temp_file" "$CACHE_FILE"
	awk '{print substr($0,1,1) " " $0}' "$CACHE_FILE" | sort -u >"$INDEX_FILE"
	success_msg "Cache updated successfully. Found $(wc -l <"$CACHE_FILE") hosts."
	log "Host cache updated with $(wc -l <"$CACHE_FILE") hosts" "verbose"
	return 0
}

# Install bash completion
install_bash() {
	info_msg "Installing bash completion..."
	cat >"$BASH_COMPLETION_DIR/assh" <<'EOF'
#!/bin/bash

_assh_completion() {
    local cache_file="$HOME/.cache/assh/hosts"
    local index_file="$HOME/.cache/assh/hosts.idx"
    local prefix=${COMP_WORDS[COMP_CWORD]:0:1}
    
    if [[ -f "$index_file" ]]; then
        COMPREPLY=( $(grep "^$prefix" "$index_file" 2>/dev/null | cut -d' ' -f2 | grep "^${COMP_WORDS[COMP_CWORD]}") )
    else
        COMPREPLY=( $(compgen -W "$(cat $cache_file 2>/dev/null)" -- ${COMP_WORDS[COMP_CWORD]}) )
    fi
}

complete -F _assh_completion ssh
complete -F _assh_completion scp
EOF

	if ! grep -q "source ~/.bash_completion.d/assh" "$HOME/.bashrc"; then
		echo "source ~/.bash_completion.d/assh" >>"$HOME/.bashrc"
	fi
	log "Bash completion installed" "verbose"
}

# Install zsh completion
install_zsh() {
	info_msg "Installing zsh completion..."
	cat >"$ZSH_COMPLETION_DIR/_assh" <<\EOF
#compdef ssh scp

_assh() {
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

compdef _assh ssh
compdef _assh scp
EOF

	warn_msg "Important: For zsh completion to work, you need to add the completion directory to your fpath."
	info_msg "Please add this line to your .zshrc file:"
	echo "    fpath=($HOME/.config/zsh/completions \$fpath)"
	log "Zsh completion installed" "verbose"
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
	log "Fish completion installed" "verbose"
}

# Uninstall completions
uninstall_completions() {
	local shell="$1"
	info_msg "Uninstalling $shell completion..."
	case "$shell" in
	"bash")
		rm -f "$BASH_COMPLETION_DIR/assh"
		sed -i '/source ~\/.bash_completion.d\/assh/d' "$HOME/.bashrc"
		log "Bash completion uninstalled" "verbose"
		;;
	"zsh")
		rm -f "$ZSH_COMPLETION_DIR/_assh"
		sed -i '/fpath=($HOME\/.config\/zsh\/completions $fpath)/d' "$HOME/.zshrc"
		log "Zsh completion uninstalled" "verbose"
		;;
	"fish")
		rm -f "$FISH_COMPLETION_DIR/assh.fish"
		log "Fish completion uninstalled" "verbose"
		;;
	"all")
		uninstall_completions "bash"
		uninstall_completions "zsh"
		uninstall_completions "fish"
		rm -rf "$CACHE_DIR"
		log "All completions uninstalled" "verbose"
		;;
	esac
}

# List active SSH control sessions
list_sessions() {
	echo "Active SSH Control Sessions:"
	echo "----------------------------"

	if [ -d "$CONTROL_DIR" ]; then
		# Find all socket files
		while IFS= read -r socket; do
			if [ -S "$socket" ]; then
				creation_time=$(stat -c '%y' "$socket")
				socket_name=$(basename "$socket")
				echo "Session: $socket_name"
				echo "Created: $creation_time"
				echo "----------------------------"
			fi
		done < <(find "$CONTROL_DIR" -type s 2>/dev/null)
	else
		echo "No control directory found."
	fi
	log "Listed active SSH sessions" "verbose"
}

# Clean old sessions
clean_old_sessions() {
	local max_age="$1"
	local count=0

	if [ -d "$CONTROL_DIR" ]; then
		while IFS= read -r socket; do
			if [ -S "$socket" ]; then
				rm -f "$socket"
				count=$((count + 1))
				log "Removed old socket: $socket"
			fi
		done < <(find "$CONTROL_DIR" -type s -mmin "+$max_age" 2>/dev/null)

		echo "Cleaned $count old sessions."
	else
		echo "No control directory found."
	fi
	log "Cleaned $count old sessions (older than $max_age minutes)" "verbose"
}

# Kill all active sessions
kill_all_sessions() {
	local count=0

	if [ -d "$CONTROL_DIR" ]; then
		while IFS= read -r socket; do
			if [ -S "$socket" ]; then
				# Try to close the master connection gracefully
				ssh -O exit -S "$socket" dummy 2>/dev/null
				rm -f "$socket"
				count=$((count + 1))
				log "Killed session: $socket"
			fi
		done < <(find "$CONTROL_DIR" -type s 2>/dev/null)

		echo "Killed $count sessions."
	else
		echo "No control directory found."
	fi
	log "Killed $count active SSH sessions" "verbose"
}

# Check socket permissions
check_socket_permissions() {
	if [ -d "$CONTROL_DIR" ]; then
		echo "Checking socket directory permissions..."
		current_perm=$(stat -c "%a" "$CONTROL_DIR")

		if [ "$current_perm" != "700" ]; then
			echo "Warning: Control directory has unsafe permissions: $current_perm"
			echo "Fixing permissions..."
			chmod 700 "$CONTROL_DIR"
			log "Fixed control directory permissions from $current_perm to 700"
		fi

		# Check socket file permissions
		local unsafe=0
		while IFS= read -r socket; do
			if [ -S "$socket" ]; then
				socket_perm=$(stat -c "%a" "$socket")
				if [ "$socket_perm" != "600" ] && [ "$socket_perm" != "700" ]; then
					echo "Warning: Socket $socket has unsafe permissions: $socket_perm"
					chmod 600 "$socket"
					unsafe=$((unsafe + 1))
					log "Fixed socket permissions for $socket from $socket_perm to 600"
				fi
			fi
		done < <(find "$CONTROL_DIR" -type s 2>/dev/null)

		if [ $unsafe -gt 0 ]; then
			echo "Fixed permissions for $unsafe socket files."
		else
			echo "All socket permissions are secure."
		fi
	else
		echo "No control directory found."
	fi
}

# Backup remote hosts file
backup_hosts() {
	local SSH_CONNECTION="$1"

	if [ -z "$SSH_CONNECTION" ]; then
		error_msg "SSH connection name required."
		echo "Usage: $0 hosts-backup <ssh_connection_name>"
		return 1
	fi

	mkdir -p "$HOSTS_DIR"
	echo "Retrieving information from remote machine..."

	# Get hostname information
	HOSTNAME=$(ssh "$SSH_CONNECTION" 'hostname' 2>/dev/null)
	if [ $? -ne 0 ]; then
		error_msg "Error: Could not retrieve hostname information!"
		return 1
	fi

	echo "Hostname: $HOSTNAME"

	# Create a temporary file
	TEMP_FILE=$(mktemp)

	# Copy hosts file to temporary file
	scp "$SSH_CONNECTION:/etc/hosts" "$TEMP_FILE" 2>/dev/null
	if [ $? -ne 0 ]; then
		error_msg "Error: Could not copy hosts file!"
		rm -f "$TEMP_FILE"
		return 1
	fi

	# Create new hosts file
	TARGET_FILE="$HOSTS_DIR/${SSH_CONNECTION}_${HOSTNAME}_hosts"

	# Add connection information at the top of the file
	echo "# SSH Connection: $SSH_CONNECTION" >"$TARGET_FILE"
	echo "# Hostname: $HOSTNAME" >>"$TARGET_FILE"
	echo "# Backup date: $(date '+%Y-%m-%d %H:%M:%S')" >>"$TARGET_FILE"
	echo "" >>"$TARGET_FILE"
	cat "$TEMP_FILE" >>"$TARGET_FILE"

	# Remove temporary file
	rm -f "$TEMP_FILE"

	# Set permissions
	chmod 644 "$TARGET_FILE"

	# Operation summary
	echo -e "\nOperation Summary:"
	echo "-------------"
	echo "Hosts File: $TARGET_FILE"
	echo "SSH Connection: $SSH_CONNECTION"
	echo "Host Name: $HOSTNAME"

	log "Created hosts backup for $SSH_CONNECTION ($HOSTNAME) at $TARGET_FILE" "verbose"
	success_msg "Hosts file backup completed successfully."
}

# Setup passwordless SSH with Ed25519 keys
setup_ssh() {
	# Display Banner
	printf "%b\n" "$BANNER"
	printf "\n"

	# Get remote server details
	printf "%b\n" "${GREEN}Enter your remote server address (e.g username@192.168.1.122):${NC}"
	read -rp "Remote Server: " REMOTE_SERVER

	if [ -z "$REMOTE_SERVER" ]; then
		error_msg "Remote server address is required."
		return 1
	fi

	IP_ADDR=$(printf "%s" "$REMOTE_SERVER" | cut -d '@' -f2 | cut -d ':' -f1)
	printf "\n"

	# Optional key removal
	read -rp "Do you want to remove existing SSH keys for this host? (y/N): " remove_keys
	if [[ $remove_keys =~ ^[Yy]$ ]]; then
		printf "%b\n" "${YELLOW}Removing existing keys for $IP_ADDR...${NC}"
		ssh-keygen -R "$IP_ADDR"
		log "Removed existing SSH keys for $IP_ADDR" "verbose"
		printf "\n"
	fi

	# Check and generate Ed25519 key if needed
	if [ ! -f ~/.ssh/id_ed25519.pub ]; then
		printf "%b\n" "${GREEN}Generating Ed25519 public keys...${NC}"
		printf "%b\n" "${YELLOW}Note: For better security, consider adding a passphrase when prompted${NC}"
		ssh-keygen -t ed25519 -a 100
		log "Generated new Ed25519 key" "verbose"
		printf "\n"
	else
		printf "%b\n" "${YELLOW}Ed25519 key already exists. Using existing key.${NC}"
		log "Using existing Ed25519 key" "verbose"
	fi

	# Ensure .ssh directory exists on remote server
	printf "%b\n" "${YELLOW}Setting up .ssh directory on remote server...${NC}"
	ssh "$REMOTE_SERVER" "mkdir -p ~/.ssh && chmod 700 ~/.ssh"
	log "Set up .ssh directory on $REMOTE_SERVER" "verbose"
	printf "\n"

	# Copy public key to remote server
	printf "%b\n" "${YELLOW}Copying your public key to remote server...${NC}"
	ssh-copy-id -i ~/.ssh/id_ed25519.pub "$REMOTE_SERVER"
	log "Copied public key to $REMOTE_SERVER" "verbose"
	printf "\n"

	# Set secure permissions
	printf "%b\n" "${GREEN}Setting secure permissions for SSH files...${NC}"
	chmod 600 ~/.ssh/id_ed25519
	chmod 644 ~/.ssh/id_ed25519.pub
	log "Set secure permissions for SSH key files" "verbose"

	# Final instructions
	printf "\n%b\n" "${GREEN}=== Setup Complete ===${NC}"
	printf "%b\n" "${YELLOW}Quick Guide:${NC}"
	printf " • You can now connect using: ${GREEN}ssh $REMOTE_SERVER${NC}\n"
	printf " • If connection fails, restart the SSH service on remote server\n"
	printf " • For security, consider adding your key to ssh-agent\n"
	printf "\n"
	success_msg "SSH setup completed successfully."
}

# Show help message
show_help() {
	echo "OSC SSH Master Utility"
	echo "Usage: $(basename "$0") COMMAND [OPTIONS]"
	echo
	echo "Top-level commands:"
	echo "  update                  Update SSH host cache (shortcut for 'assh update')"
	echo "  hosts-backup CONNECTION Backup /etc/hosts file from remote server"
	echo "  setup                   Setup passwordless SSH with Ed25519 keys"
	echo "  help                    Show this help message"
	echo
	echo "ASSH commands:"
	echo "  assh check              Check and install/update assh"
	echo "  assh update             Update host cache"
	echo "  assh install SHELL      Install completion for specified shell (bash, zsh, fish, all)"
	echo "  assh uninstall SHELL    Uninstall completion for specified shell"
	echo
	echo "Session commands:"
	echo "  session list            List all active SSH control sessions"
	echo "  session clean [minutes] Clean sessions older than [minutes] (default: 60)"
	echo "  session kill            Kill all active SSH control sessions"
	echo "  session check           Check and fix socket permissions"
}

# Main function
main() {
	# Create necessary directories
	setup_dirs

	local cmd="$1"
	shift || true

	case "$cmd" in
	# Top-level commands for common operations
	"update")
		# Add a direct shortcut for the most common command
		update_cache
		;;
	"hosts-backup")
		connection="$1"
		backup_hosts "$connection"
		;;
	"setup")
		setup_ssh
		;;
	"help" | "")
		show_help
		;;

	# Sub-command groups
	"assh")
		subcmd="$1"
		shift || true
		case "$subcmd" in
		"check")
			check_and_install_assh
			;;
		"update")
			update_cache
			;;
		"install")
			shell="$1"
			if [ -z "$shell" ]; then
				error_msg "Shell type required"
				echo "Usage: $0 assh install [bash|zsh|fish|all]"
				return 1
			fi
			check_and_install_assh || return 1
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
				echo "Supported shells: bash, zsh, fish, all"
				return 1
				;;
			esac
			success_msg "Installation completed for $shell"
			info_msg "Please restart your shell or source the appropriate rc file"
			;;
		"uninstall")
			shell="$1"
			if [ -z "$shell" ]; then
				error_msg "Shell type required"
				echo "Usage: $0 assh uninstall [bash|zsh|fish|all]"
				return 1
			fi
			uninstall_completions "$shell"
			success_msg "Uninstallation completed for $shell"
			;;
		*)
			error_msg "Unknown assh subcommand: $subcmd"
			echo "Valid subcommands: check, update, install, uninstall"
			return 1
			;;
		esac
		;;
	"session")
		subcmd="$1"
		shift || true
		case "$subcmd" in
		"list")
			list_sessions
			;;
		"clean")
			max_age="${1:-60}" # Default to 60 minutes if not specified
			clean_old_sessions "$max_age"
			;;
		"kill")
			kill_all_sessions
			;;
		"check")
			check_socket_permissions
			;;
		*)
			error_msg "Unknown session subcommand: $subcmd"
			echo "Valid subcommands: list, clean, kill, check"
			return 1
			;;
		esac
		;;
	*)
		error_msg "Unknown command: $cmd"
		show_help
		return 1
		;;
	esac
}

# Display the banner at startup
echo -e "$BANNER"
# Run main function with all arguments
main "$@"
