#!/usr/bin/env bash
#===============================================================================
#
#   Script: NixOS Script Generator
#   Version: 2.0.0
#   Date: 2025-04-08
#   Author: Kenan Pelit
#   Repository: https://github.com/kenanpelit/nixosc
#   Description: Unified Nix expression generator for scripts that
#                creates modular home-manager configurations
#
#   Features:
#   - Automatically generates Nix expressions for shell scripts
#   - Handles multiple script directories (bin, start)
#   - Handles special filename patterns (t1-9, tm)
#   - Ignores underscore-prefixed files
#   - Creates modular home-manager packages
#   - Maintains consistent naming conventions
#
#   License: MIT
#
#===============================================================================

set -euo pipefail

# Configuration: Define directories to process
declare -A DIRECTORIES=(
	["bin"]="$HOME/.nixosc/modules/home/scripts/bin"
	["start"]="$HOME/.nixosc/modules/home/scripts/start"
	["gnome"]="$HOME/.nixosc/modules/home/scripts/gnome"

)

# Function to process a single directory
process_directory() {
	local dir_name=$1
	local script_dir="${DIRECTORIES[$dir_name]}"
	local output_file="$HOME/.nixosc/modules/home/scripts/${dir_name}.nix"

	echo "Processing directory: $dir_name"

	# Header
	cat >"$output_file" <<EOF
{ pkgs, ... }:
let
EOF

	# Process scripts
	for script in "$script_dir"/*.sh "$script_dir"/t[1-9] "$script_dir"/tm; do
		[[ -f "$script" ]] || continue
		filename=$(basename "$script")
		[[ $filename == _* ]] && continue

		varname="${filename%.sh}"
		varname="${varname// /-}"
		varname="${varname//./-}"

		echo "  ${varname} = pkgs.writeShellScriptBin \"${varname}\" (" >>"$output_file"
		echo "    builtins.readFile ./${dir_name}/${filename}" >>"$output_file"
		echo "  );" >>"$output_file"
	done

	# Footer
	cat >>"$output_file" <<EOF
in {
  home.packages = with pkgs; [
EOF

	# Package list
	for script in "$script_dir"/*.sh "$script_dir"/t[1-9] "$script_dir"/tm; do
		[[ -f "$script" ]] || continue
		filename=$(basename "$script")
		[[ $filename == _* ]] && continue

		varname="${filename%.sh}"
		varname="${varname// /-}"
		varname="${varname//./-}"

		echo "    ${varname}" >>"$output_file"
	done

	echo "  ];" >>"$output_file"
	echo "}" >>"$output_file"

	echo "Generated: $output_file"
}

# Main function
main() {
	echo "==============================================================================="
	echo "  NixOS Script Generator - Unified"
	echo "  Version: 2.0.0"
	echo "  $(date '+%Y-%m-%d %H:%M:%S')"
	echo "==============================================================================="

	# Process all directories
	for dir_name in "${!DIRECTORIES[@]}"; do
		process_directory "$dir_name"
	done

	echo "All Nix expressions have been generated successfully."
}

# Execute main function
main
