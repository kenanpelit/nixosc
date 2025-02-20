#!/usr/bin/env bash
# ==============================================================================
# GRUB Theme Cleanup Script
# ==============================================================================
# This script cleans up GRUB theme-related directories to prevent installation
# conflicts when updating GRUB configuration.
#
# Author: Kenan Pelit
# ==============================================================================

# Exit on error
set -e

# Check if running as root
if [[ $EUID -ne 0 ]]; then
	echo "This script must be run as root"
	exit 1
fi

# Define directories to clean
DIRS=(
	"/boot/theme"
	"/boot/grub/themes"
	"/boot/grub/fonts"
)

# Function to safely remove directories
cleanup_dir() {
	local dir=$1
	if [[ -d "$dir" ]]; then
		echo "Removing $dir..."
		rm -rf "$dir"
		echo "✓ Removed $dir"
	else
		echo "! Directory $dir does not exist, skipping..."
	fi
}

# Main cleanup process
echo "Starting GRUB theme cleanup..."
echo "-----------------------------"

for dir in "${DIRS[@]}"; do
	cleanup_dir "$dir"
done

echo "-----------------------------"
echo "Cleanup completed successfully!"
