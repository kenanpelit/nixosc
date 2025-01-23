#!/usr/bin/env bash
#===============================================================================
#
#   Script: OSC Remote Tunnel Manager
#   Version: 1.0.0
#   Date: 2024-01-23
#   Author: Kenan Pelit
#   Repository: https://github.com/kenanpelit/nixosc
#   Description: Remote SSH tunnel manager with search capabilities for
#                filtering tunnel connections and status
#
#   Features:
#   - SSH connection with color preservation
#   - Quick tunnel status search
#   - Configurable connection parameters
#   - Direct tunnel command execution
#   - Pattern-based filtering
#
#   License: MIT
#
#===============================================================================

# SSH connection parameters
readonly REMOTE_USER="kenan"
readonly REMOTE_HOST="terminal"
readonly REMOTE_PORT="36499"
readonly BASE_COMMAND="~/tunnelman/tunnels.py -l"

# Ana fonksiyon
main() {
	local search_pattern="$1"
	local command="$BASE_COMMAND"

	# Eğer arama parametresi verildiyse komutu düzenle
	if [[ -n "$search_pattern" ]]; then
		command="$BASE_COMMAND | grep -i '$search_pattern'"
	fi

	# SSH bağlantısı yap ve komutu çalıştır
	ssh -p "${REMOTE_PORT}" -t "${REMOTE_USER}@${REMOTE_HOST}" "$command"
}

# Programı çalıştır
main "$@"
