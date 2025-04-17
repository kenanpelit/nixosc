#!/usr/bin/env bash
#===============================================================================
#
#   Script: OSC SSH Session Manager
#   Version: 1.0.0
#   Date: 2024-01-23
#   Author: Kenan Pelit
#   Repository: https://github.com/kenanpelit/nixosc
#   Description: SSH multiplexed sessions and control sockets management utility
#                for maintaining and monitoring SSH connections
#
#   Features:
#   - Lists active SSH control sessions with creation times
#   - Cleans old sessions based on age
#   - Kills all active sessions with graceful shutdown
#   - Monitors and fixes socket permissions for security
#   - Built-in logging functionality
#
#   License: MIT
#
#===============================================================================

CONTROL_DIR="$HOME/.ssh/controlmasters"
LOG_FILE="$HOME/.ssh/session-manager.log"

log() {
	echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >>"$LOG_FILE"
}

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
}

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
}

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
}

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

show_help() {
	echo "SSH Session Manager"
	echo "Usage: $0 [command] [options]"
	echo
	echo "Commands:"
	echo "  list                    List all active SSH control sessions"
	echo "  clean [minutes]         Clean sessions older than [minutes] (default: 60)"
	echo "  kill                    Kill all active SSH control sessions"
	echo "  check                   Check and fix socket permissions"
	echo "  help                    Show this help message"
}

case "$1" in
"list")
	list_sessions
	;;
"clean")
	max_age="${2:-60}" # Default to 60 minutes if not specified
	clean_old_sessions "$max_age"
	;;
"kill")
	kill_all_sessions
	;;
"check")
	check_socket_permissions
	;;
"help" | "")
	show_help
	;;
*)
	echo "Unknown command: $1"
	echo
	show_help
	exit 1
	;;
esac
