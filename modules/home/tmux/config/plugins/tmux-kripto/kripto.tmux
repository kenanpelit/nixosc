#!/usr/bin/env bash

CWD="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$CWD/scripts/tmux.sh"

kripto_script="#($CWD/scripts/kripto.sh)"
kripto_tag="\#{kripto}"

interpolate() {
	local interpolated="$1"
	local interpolated="${interpolated/$kripto_tag/$kripto_script}"
	echo "$interpolated"
}

main() {
	set_tmux_option "status-right"
	set_tmux_option "status-left"
}
main
