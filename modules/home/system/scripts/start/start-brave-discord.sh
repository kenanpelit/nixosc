#!/usr/bin/env bash
#===============================================================================
# Generated script for Brave-Discord
# VPN Mode: secure
# Do not edit manually - this file is automatically generated
#===============================================================================

# Error handling
set -euo pipefail

# Environment setup
export TMPDIR="/tmp/sem"

# Sabitler
WORKSPACE_BRAVE_DISCORD=5
FINAL_WORKSPACE=2
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

# Brave-Discord workspace'ine geç
switch_workspace "$WORKSPACE_BRAVE_DISCORD"

# Start session with Semsumo
echo "Brave-Discord başlatılıyor..."
semsumo start "Brave-Discord" "secure" &

# Uygulama açılması için bekle
echo "Uygulama açılması için $WAIT_TIME saniye bekleniyor..."
sleep $WAIT_TIME

# Tam ekran yap
make_fullscreen

# Tamamlandığında ana workspace'e geri dön
echo "İşlem tamamlandı, workspace $FINAL_WORKSPACE'e dönülüyor..."
switch_workspace "$FINAL_WORKSPACE"

# Exit successfully
exit 0
