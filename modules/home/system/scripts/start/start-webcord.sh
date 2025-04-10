#!/usr/bin/env bash
#===============================================================================
# Generated script for webcord
# VPN Mode: bypass
# Do not edit manually - this file is automatically generated
#===============================================================================

# Error handling
set -euo pipefail

# Environment setup
export TMPDIR="/tmp/sem"

# Sabitler
WORKSPACE_WEBCORD=5
FINAL_WORKSPACE=5
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

# webcord workspace'ine geç
switch_workspace "$WORKSPACE_WEBCORD"

# Start session with Semsumo
echo "webcord başlatılıyor..."
semsumo start "webcord" "bypass" &

# Uygulama açılması için bekle
echo "Uygulama açılması için $WAIT_TIME saniye bekleniyor..."
sleep $WAIT_TIME

# Tam ekran yap
make_fullscreen

# Exit successfully
exit 0
