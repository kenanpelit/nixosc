#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$HOME/.nixosc/modules/home/system/scripts/start"
OUTPUT_FILE="$HOME/.nixosc/modules/home/system/scripts/start.nix"

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
	echo "    builtins.readFile ./start/${filename}" >>"$OUTPUT_FILE"
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
