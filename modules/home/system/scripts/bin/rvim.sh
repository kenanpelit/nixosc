#!/usr/bin/env bash

# Script to edit remote files using nvim over SSH
# Usage: ./remote_nvim_edit.sh user@host:/path/to/file

# Function to display usage
show_usage() {
  echo "Usage: $0 [options] user@host:/path/to/file"
  echo ""
  echo "Options:"
  echo "  -p PORT     Specify SSH port (default: 22)"
  echo "  -i KEY      Specify SSH private key"
  echo "  -h         Show this help message"
  exit 1
}

# Default values
SSH_PORT=22
SSH_KEY=""

# Parse command line options
while getopts "p:i:h" opt; do
  case $opt in
  p) SSH_PORT="$OPTARG" ;;
  i) SSH_KEY="-i $OPTARG" ;;
  h) show_usage ;;
  \?)
    echo "Invalid option: -$OPTARG" >&2
    show_usage
    ;;
  esac
done

# Shift the options so $1 is the remote file path
shift $((OPTIND - 1))

# Check if remote file path is provided
if [ -z "$1" ]; then
  echo "Error: Remote file path not specified"
  show_usage
fi

# Split the remote path into host and file path
REMOTE_PATH=$1
HOST=$(echo $REMOTE_PATH | cut -d: -f1)
FILE_PATH=$(echo $REMOTE_PATH | cut -d: -f2-)

if [ -z "$HOST" ] || [ -z "$FILE_PATH" ]; then
  echo "Error: Invalid remote path format"
  show_usage
fi

# Create temporary directory
TEMP_DIR=$(mktemp -d)
TEMP_FILE="$TEMP_DIR/$(basename "$FILE_PATH")"

# Function to cleanup temporary files
cleanup() {
  rm -rf "$TEMP_DIR"
}

# Set trap for cleanup on exit
trap cleanup EXIT

# Download the remote file
echo "Downloading remote file..."
scp -P $SSH_PORT $SSH_KEY "$REMOTE_PATH" "$TEMP_FILE" || {
  echo "Error: Failed to download remote file"
  exit 1
}

# Get initial modification time
INITIAL_MTIME=$(stat -c %Y "$TEMP_FILE" 2>/dev/null || stat -f %m "$TEMP_FILE")

# Edit the file with nvim
nvim "$TEMP_FILE"

# Get new modification time
NEW_MTIME=$(stat -c %Y "$TEMP_FILE" 2>/dev/null || stat -f %m "$TEMP_FILE")

# Upload the file only if it has been modified
if [ "$INITIAL_MTIME" != "$NEW_MTIME" ]; then
  echo "Uploading changes..."
  scp -P $SSH_PORT $SSH_KEY "$TEMP_FILE" "$REMOTE_PATH" || {
    echo "Error: Failed to upload changes"
    echo "Your changes are still saved in: $TEMP_FILE"
    trap - EXIT
    exit 1
  }
  echo "Changes uploaded successfully"
else
  echo "No changes made"
fi

exit 0
