#!/usr/bin/env bash
# ==============================================================================
# Walker Launcher (minimal, elegant)
# ==============================================================================
# Launches Walker with predefined dimensions and nice terminal styling.
# No delays, no theme, pure efficiency.
# ==============================================================================

# ──────────────── 🎨 Colors (Catppuccin-inspired) ────────────────
BOLD="\e[1m"
RESET="\e[0m"
BLUE="\e[38;5;111m"
LAVENDER="\e[38;5;147m"
GREEN="\e[38;5;114m"
YELLOW="\e[38;5;180m"
GRAY="\e[38;5;245m"

# ──────────────── ⚙️  Parameters ────────────────
WIDTH=800
MINHEIGHT=300
MAXHEIGHT=700

# ──────────────── 🚀 Launch Info ────────────────
clear
echo -e "${LAVENDER}${BOLD}╔════════════════════════════════════════╗"
echo -e "║         🚀 Launching Walker...         ║"
echo -e "╚════════════════════════════════════════╝${RESET}"
echo -e "${BLUE}Width: ${YELLOW}${WIDTH}${RESET}  |  ${BLUE}Min Height: ${YELLOW}${MINHEIGHT}${RESET}  |  ${BLUE}Max Height: ${YELLOW}${MAXHEIGHT}${RESET}"

# ──────────────── 🧭 Run Walker ────────────────
walker --width=${WIDTH} --minheight=${MINHEIGHT} --maxheight=${MAXHEIGHT} &

# ──────────────── ✅ Done ────────────────
echo -e "${GREEN}Walker launched successfully!${RESET}"
