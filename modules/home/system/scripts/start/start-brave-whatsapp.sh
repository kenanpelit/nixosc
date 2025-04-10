#!/usr/bin/env bash
#===============================================================================
# Generated script for Brave-Whatsapp
# VPN Mode: secure
# Do not edit manually - this file is automatically generated
#===============================================================================

# Error handling
set -euo pipefail

# Environment setup
export TMPDIR="/tmp/sem"

# Sabitler
WORKSPACE_BRAVE_WHATSAPP=9
FINAL_WORKSPACE=9
WAIT_TIME=2

# Workspace'e geçiş fonksiyonu
switch_workspace() {
	local workspace="$1"
	if command -v hyprctl &>/dev/null; then
		echo "Workspace $workspace'e geçiliyor..."
		hyprctl dispatch workspace "$workspace"
		sleep 1
	fi
}

# Tam ekran yapma fonksiyonu
make_fullscreen() {
	if command -v hyprctl &>/dev/null; then
		echo "Aktif pencere tam ekran yapılıyor..."
		sleep 1
		hyprctl dispatch fullscreen 1
		sleep 1
	fi
}

# Brave-Whatsapp workspace'ine geç
switch_workspace "$WORKSPACE_BRAVE_WHATSAPP"

# Start session with Semsumo
echo "Brave-Whatsapp başlatılıyor..."
semsumo start "Brave-Whatsapp" "secure" &

# Uygulama açılması için bekle
echo "Uygulama açılması için $WAIT_TIME saniye bekleniyor..."
sleep $WAIT_TIME

# Tam ekran yap
make_fullscreen

# Exit successfully
exit 0
