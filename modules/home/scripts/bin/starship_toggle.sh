#!/usr/bin/env bash
# ==============================================================================
# starship-toggle.sh
# ------------------------------------------------------------------------------
# Toggle between Starship FAST and FULL modes dynamically.
# - FAST (default): ultra-light, for large git repos or remote FS.
# - FULL: rich prompt with git_state, battery, infra tools, etc.
# ------------------------------------------------------------------------------
# Usage:
#   ./starship-toggle.sh
#
# Optional: add an alias to your shell:
#   alias stoggle="~/.arch/repo/starship-toggle.sh"
# ==============================================================================

# --- Catppuccin Mocha Colors ---
RESET="\e[0m"
GREEN="\e[38;2;166;227;161m"
RED="\e[38;2;243;139;168m"
BLUE="\e[38;2;137;180;250m"
YELLOW="\e[38;2;249;226;175m"
LAVENDER="\e[38;2;180;190;254m"

# --- Detect current mode ---
if [[ "$STARSHIP_MODE" == "full" ]]; then
	current="FULL"
else
	current="FAST"
fi

# --- Toggle logic ---
if [[ "$current" == "FAST" ]]; then
	export STARSHIP_MODE=full
	new="FULL"
	message="${GREEN}✨ Switched to FULL mode${RESET}"
else
	unset STARSHIP_MODE
	new="FAST"
	message="${YELLOW}⚡ Reverted to FAST mode${RESET}"
fi

# --- Display result ---
echo -e "${BLUE}Starship mode toggle:${RESET} ${LAVENDER}${current}${RESET} → ${LAVENDER}${new}${RESET}"
echo -e "$message"
echo

# --- Restart shell to apply immediately (optional) ---
read -rp "🔄 Restart shell to apply now? [y/N]: " ans
if [[ "$ans" =~ ^[Yy]$ ]]; then
	exec zsh -l
else
	echo -e "${RED}Note:${RESET} changes apply on next shell start."
fi
