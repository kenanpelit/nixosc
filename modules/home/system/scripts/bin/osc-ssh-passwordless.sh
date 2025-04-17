#!/usr/bin/env bash

#==============================================================================
#  ssh-setup.sh
#==============================================================================
# Author: Kenan Pelit
# Last Updated: 2024-12-11
# Version: 1.0.0
#
# Description:
#   This script automates the setup of passwordless SSH authentication using
#   Ed25519 keys. It guides you through the process of generating SSH keys
#   and configuring them on a remote server.
#
# Features:
#   - Uses modern Ed25519 keys for better security
#   - Optional removal of existing host keys
#   - Secure permission settings
#   - Interactive prompts for better user experience
#
# Usage:
#   ./ssh-setup.sh
#
# Requirements:
#   - OpenSSH client (ssh, ssh-keygen, ssh-copy-id)
#   - Bash shell
#
# Note: Make sure you have SSH access to the remote server before running this script.
#==============================================================================

# Terminal Colors
Color_Off='\e[0m'
Red='\e[0;31m'
Green='\e[0;32m'
Yellow='\e[0;33m'

# ASCII Art Banner
banner="
╔═══════════════════════════════════════════╗
║         SSH Passwordless Setup            ║
║     Automated Ed25519 Key Generation      ║
╚═══════════════════════════════════════════╝"

# Display Banner
printf "%b\n" "$banner"
printf "\n"

# Get remote server details
printf "%b\n" "${Green}Enter your remote server address (e.g username@192.168.1.122):${Color_Off}"
read -rp "Remote Server: " REMOTE_SERVER
IP_ADDR=$(printf "%s" "$REMOTE_SERVER" | cut -d '@' -f2 | cut -d ':' -f1)
printf "\n"

# Optional key removal
read -rp "Do you want to remove existing SSH keys for this host? (y/N): " remove_keys
if [[ $remove_keys =~ ^[Yy]$ ]]; then
	printf "%b\n" "${Yellow}Removing existing keys for $IP_ADDR...${Color_Off}"
	ssh-keygen -R "$IP_ADDR"
	printf "\n"
fi

# Check and generate Ed25519 key if needed
if [ ! -f ~/.ssh/id_ed25519.pub ]; then
	printf "%b\n" "${Green}Generating Ed25519 public keys...${Color_Off}"
	printf "%b\n" "${Yellow}Note: For better security, consider adding a passphrase when prompted${Color_Off}"
	ssh-keygen -t ed25519 -a 100
	printf "\n"
else
	printf "%b\n" "${Yellow}Ed25519 key already exists. Using existing key.${Color_Off}"
fi

# Ensure .ssh directory exists on remote server
printf "%b\n" "${Yellow}Setting up .ssh directory on remote server...${Color_Off}"
ssh "$REMOTE_SERVER" "mkdir -p ~/.ssh && chmod 700 ~/.ssh"
printf "\n"

# Copy public key to remote server
printf "%b\n" "${Yellow}Copying your public key to remote server...${Color_Off}"
ssh-copy-id -i ~/.ssh/id_ed25519.pub "$REMOTE_SERVER"
printf "\n"

# Set secure permissions
printf "%b\n" "${Green}Setting secure permissions for SSH files...${Color_Off}"
chmod 600 ~/.ssh/id_ed25519
chmod 644 ~/.ssh/id_ed25519.pub

# Final instructions
printf "\n%b\n" "${Green}=== Setup Complete ===${Color_Off}"
printf "%b\n" "${Yellow}Quick Guide:${Color_Off}"
printf " • You can now connect using: ${Green}ssh $REMOTE_SERVER${Color_Off}\n"
printf " • If connection fails, restart the SSH service on remote server\n"
printf " • For security, consider adding your key to ssh-agent\n"
printf "\n"
printf "%b\n" "${Green}Happy secure computing!${Color_Off}"
