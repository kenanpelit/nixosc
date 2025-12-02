#!/usr/bin/env bash
#
# osc-rsync.sh - Optimized rsync commands for different transfer scenarios
#
# Usage: ./advanced-rsync.sh [-t type] [-s source] [-d destination] [-r remove] [-h help]
#
# Author: Kenan Pelit
# Date: March 16, 2025
# Version: 1.0
#
# This script provides optimized rsync commands for various transfer scenarios.
# It simplifies the process of using complex rsync parameters by providing
# pre-configured settings for different network conditions and use cases.

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Display script banner
function show_banner {
	echo -e "${BLUE}┌─────────────────────────────────────────┐${NC}"
	echo -e "${BLUE}│       OSC rsync Transfer Tool           │${NC}"
	echo -e "${BLUE}└─────────────────────────────────────────┘${NC}"
	echo
}

# Display usage information
function show_help {
	show_banner
	echo -e "Usage: $0 ${GREEN}[options]${NC}"
	echo
	echo -e "Options:"
	echo -e "  ${GREEN}-t TYPE${NC}        Transfer type (required unless -h is used)"
	echo -e "  ${GREEN}-s SOURCE${NC}      Source directory or file (required)"
	echo -e "  ${GREEN}-d DEST${NC}        Destination directory (required)"
	echo -e "  ${GREEN}-r${NC}             Remove files at destination that don't exist at source"
	echo -e "  ${GREEN}-h${NC}             Display this help message"
	echo
	echo -e "Transfer types:"
	echo -e "  ${GREEN}std${NC}        Standard transfer (general use)"
	echo -e "  ${GREEN}net${NC}        Network transfer (optimized for network transfers)"
	echo -e "  ${GREEN}loc${NC}        Local transfer (optimized for same system or LAN)"
	echo -e "  ${GREEN}web${NC}        Internet transfer (optimized for large files over internet)"
	echo
	echo -e "Examples:"
	echo -e "  $0 -t std -s /source/dir/ -d /target/dir/"
	echo -e "  $0 -t net -s /data/folder/ -d user@server:/backup/folder/"
	echo -e "  $0 -t web -s /large/files/ -d remote-server:/backup/dir/ -r"
	echo
	exit 0
}

# Function to validate required parameters
function validate_params {
	if [ -z "$TRANSFER_TYPE" ] || [ -z "$SOURCE" ] || [ -z "$DEST" ]; then
		echo -e "${RED}Error: Missing required parameters${NC}"
		echo -e "Try '$0 -h' for more information."
		exit 1
	fi
}

# Default values
TRANSFER_TYPE=""
SOURCE=""
DEST=""
DELETE_FLAG=""

# Parse command line options
while getopts ":t:s:d:rh" opt; do
	case $opt in
	t)
		TRANSFER_TYPE=$OPTARG
		;;
	s)
		SOURCE=$OPTARG
		;;
	d)
		DEST=$OPTARG
		;;
	r)
		DELETE_FLAG="--delete"
		;;
	h)
		show_help
		;;
	\?)
		echo -e "${RED}Invalid option: -$OPTARG${NC}" >&2
		echo -e "Try '$0 -h' for more information."
		exit 1
		;;
	:)
		echo -e "${RED}Option -$OPTARG requires an argument.${NC}" >&2
		echo -e "Try '$0 -h' for more information."
		exit 1
		;;
	esac
done

# Check if there are any arguments, show help if none
if [ $# -eq 0 ]; then
	show_help
fi

# Validate parameters if help is not requested
if [ "$1" != "-h" ]; then
	validate_params
fi

# Display starting message
show_banner
echo -e "${BLUE}Starting transfer: ${SOURCE} -> ${DEST}${NC}"
echo -e "${GREEN}Transfer type: ${TRANSFER_TYPE}${NC}"
echo

# Perform the transfer based on type
case $TRANSFER_TYPE in
std)
	echo -e "${YELLOW}Starting standard transfer...${NC}"
	rsync -avzPh --info=progress2 --stats $DELETE_FLAG "$SOURCE" "$DEST"
	;;
net)
	echo -e "${YELLOW}Starting network transfer...${NC}"
	rsync -axAXvzE --compress-level=9 --numeric-ids --info=progress2 --stats $DELETE_FLAG "$SOURCE" "$DEST"
	;;
loc)
	echo -e "${YELLOW}Starting local transfer...${NC}"
	rsync -avxHAXW --no-compress --numeric-ids --info=progress2 --stats $DELETE_FLAG "$SOURCE" "$DEST"
	;;
web)
	echo -e "${YELLOW}Starting internet transfer...${NC}"
	rsync -avzP --compress-level=9 --partial-dir=.rsync-partial --append-verify --timeout=120 --info=progress2 --stats $DELETE_FLAG "$SOURCE" "$DEST"
	;;
*)
	echo -e "${RED}Invalid transfer type: ${TRANSFER_TYPE}${NC}"
	echo -e "Valid types are: std, net, loc, web"
	echo -e "Try '$0 -h' for more information."
	exit 1
	;;
esac

# Check if transfer was successful
if [ $? -eq 0 ]; then
	echo -e "${GREEN}Transfer completed successfully!${NC}"
else
	echo -e "${RED}An error occurred during transfer!${NC}"
	exit 1
fi

exit 0
