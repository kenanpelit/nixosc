#!/usr/bin/env bash
# tarchiver.sh - A simple tar archive manager for compressing and extracting files
# Usage:
#   tarchiver.sh compress <directory/file>  - Creates a .tar.gz archive
#   tarchiver.sh extract <archive.tar.gz>   - Extracts an archive

command=$1
target=$2

# Display help if no arguments
if [ $# -lt 1 ]; then
	echo "Usage:"
	echo "  $(basename $0) compress <directory/file> - Create a .tar.gz archive"
	echo "  $(basename $0) extract <archive.tar.gz>  - Extract an archive"
	exit 1
fi

case "$command" in
compress | c)
	if [ -z "$target" ]; then
		echo "Error: No target specified for compression"
		echo "Usage: $(basename $0) compress <directory/file>"
		exit 1
	fi

	if [ ! -e "$target" ]; then
		echo "Error: '$target' does not exist"
		exit 1
	fi

	echo "Creating archive: $target.tar.gz"
	tar -cvzf "$target.tar.gz" "$target"
	echo "Archive created: $target.tar.gz"
	;;

extract | e | x)
	if [ -z "$target" ]; then
		echo "Error: No archive specified for extraction"
		echo "Usage: $(basename $0) extract <archive.tar.gz>"
		exit 1
	fi

	if [ ! -f "$target" ]; then
		echo "Error: Archive '$target' does not exist or is not a file"
		exit 1
	fi

	echo "Extracting archive: $target"
	tar -xvzf "$target"
	echo "Extraction complete"
	;;

*)
	echo "Unknown command: $command"
	echo "Usage:"
	echo "  $(basename $0) compress <directory/file> - Create a .tar.gz archive"
	echo "  $(basename $0) extract <archive.tar.gz>  - Extract an archive"
	exit 1
	;;
esac

exit 0
