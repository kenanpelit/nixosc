#!/usr/bin/env bash
# ==============================================================================
# Ente Auth Launcher (Secrets-aware)
# ------------------------------------------------------------------------------
#  ✨ Launches Ente Auth with GNOME Keyring Secrets support on Hyprland / Wayland
#  🧩 Starts only the 'secrets' component to avoid SSH/GPG agent conflicts
#  💡 Auto-detects running D-Bus session and Secret Service availability
# ==============================================================================
# Author : Kenan Pelit
# Version: 1.0
# ==============================================================================

set -euo pipefail

# ------------------------------------------------------------------------------
# ✨ Colors (Catppuccin Mocha)
# ------------------------------------------------------------------------------
BOLD="\e[1m"
RESET="\e[0m"
LBLUE="\e[38;2;137;180;250m"
LRED="\e[38;2;243;139;168m"
LGREEN="\e[38;2;166;227;161m"
LYELLOW="\e[38;2;249;226;175m"
LMAUVE="\e[38;2;203;166;247m"

# ------------------------------------------------------------------------------
# 🧩 Header
# ------------------------------------------------------------------------------
printf "\n${LBLUE}${BOLD}==> Ente Auth Launcher${RESET}\n"
printf "${LMAUVE}Checking D-Bus and Secret Service environment...${RESET}\n"

# ------------------------------------------------------------------------------
# 🧠 Ensure D-Bus session is defined
# ------------------------------------------------------------------------------
if [[ -z "${DBUS_SESSION_BUS_ADDRESS:-}" ]]; then
	export DBUS_SESSION_BUS_ADDRESS="unix:path=${XDG_RUNTIME_DIR}/bus"
	printf "${LYELLOW}→ D-Bus session address was missing, defined automatically.${RESET}\n"
else
	printf "${LGREEN}✓ D-Bus session detected.${RESET}\n"
fi

# ------------------------------------------------------------------------------
# 🔐 Ensure Secret Service (org.freedesktop.secrets) is running
# ------------------------------------------------------------------------------
if ! busctl --user list 2>/dev/null | grep -q org.freedesktop.secrets; then
	printf "${LYELLOW}→ Starting GNOME Keyring (secrets-only)...${RESET}\n"
	if [[ -x "/run/current-system/sw/bin/gnome-keyring-daemon" ]]; then
		/run/current-system/sw/bin/gnome-keyring-daemon --foreground --components=secrets >/dev/null 2>&1 &
		sleep 0.3
		printf "${LGREEN}✓ Secret Service started successfully.${RESET}\n"
	else
		printf "${LRED}✗ gnome-keyring-daemon not found!${RESET}\n"
		exit 1
	fi
else
	printf "${LGREEN}✓ Secret Service is already running.${RESET}\n"
fi

# ------------------------------------------------------------------------------
# 🚀 Launch Ente Auth
# ------------------------------------------------------------------------------
printf "${LMAUVE}Launching Ente Auth...${RESET}\n"
exec ente_auth

# ------------------------------------------------------------------------------
# EOF
# ------------------------------------------------------------------------------
