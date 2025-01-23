#!/usr/bin/env bash
#===============================================================================
#
#   Script: NixOS Admin Script Generator
#   Version: 1.0.0
#   Date: 2024-01-23
#   Author: Kenan Pelit
#   Repository: https://github.com/kenanpelit/nixosc
#   Description: Automated Nix expression generator for admin scripts that
#                creates a modular home-manager configuration
#
#   Features:
#   - Automatically generates Nix expressions for shell scripts
#   - Handles special filename patterns (t1-9, tm)
#   - Ignores underscore-prefixed files
#   - Creates modular home-manager packages
#   - Maintains consistent naming conventions
#
#   License: MIT
#
#===============================================================================
set -euo pipefail

SCRIPT_DIR="$HOME/.nixosc/modules/home/system/scripts/admin"
OUTPUT_FILE="$HOME/.nixosc/modules/home/system/scripts/admin.nix"

# Header
cat >"$OUTPUT_FILE" <<'EOF'
{ pkgs, ... }:
let
EOF

# Process scripts
for script in "$SCRIPT_DIR"/*.sh "$SCRIPT_DIR"/t[1-9] "$SCRIPT_DIR"/tm; do
	[[ -f "$script" ]] || continue

	filename=$(basename "$script")
	[[ $filename == _* ]] && continue

	varname="${filename%.sh}"
	varname="${varname// /-}"
	varname="${varname//./-}"

	echo "  ${varname} = pkgs.writeShellScriptBin \"${varname}\" (" >>"$OUTPUT_FILE"
	echo "    builtins.readFile ./admin/${filename}" >>"$OUTPUT_FILE"
	echo "  );" >>"$OUTPUT_FILE"
done

# Footer
cat >>"$OUTPUT_FILE" <<'EOF'

in {
  home.packages = with pkgs; [
EOF

# Package list
for script in "$SCRIPT_DIR"/*.sh "$SCRIPT_DIR"/t[1-9] "$SCRIPT_DIR"/tm; do
	[[ -f "$script" ]] || continue

	filename=$(basename "$script")
	[[ $filename == _* ]] && continue

	varname="${filename%.sh}"
	varname="${varname// /-}"
	varname="${varname//./-}"

	echo "    ${varname}" >>"$OUTPUT_FILE"
done

echo "  ];" >>"$OUTPUT_FILE"
echo "}" >>"$OUTPUT_FILE"
