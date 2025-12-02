#!/usr/bin/env bash

# =============================================================================
# Sway VM Launcher - Interactive VM Selection
# =============================================================================

echo "╔════════════════════════════════════════════════════════════╗"
echo "║  TTY${XDG_VTNR}: Sway VM Launcher                          ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Environment temizliği
unset XDG_CURRENT_DESKTOP XDG_SESSION_DESKTOP DESKTOP_SESSION

# Sway environment
export XDG_SESSION_TYPE=wayland
export XDG_SESSION_DESKTOP=sway
export XDG_CURRENT_DESKTOP=sway
export DESKTOP_SESSION=sway
export XDG_RUNTIME_DIR="/run/user/$(id -u)"

# Sway config dizini
SWAY_CONFIG_DIR="$HOME/.config/sway"

# Mevcut VM config dosyalarını kontrol et
declare -A vm_configs
vm_found=false

if [ -f "$SWAY_CONFIG_DIR/qemu_vmubuntu" ]; then
	vm_configs["1"]="Ubuntu"
	vm_configs["1_file"]="qemu_vmubuntu"
	vm_found=true
fi

if [ -f "$SWAY_CONFIG_DIR/qemu_vmarch" ]; then
	vm_configs["2"]="Arch Linux"
	vm_configs["2_file"]="qemu_vmarch"
	vm_found=true
fi

if [ -f "$SWAY_CONFIG_DIR/qemu_vmnixos" ]; then
	vm_configs["3"]="NixOS"
	vm_configs["3_file"]="qemu_vmnixos"
	vm_found=true
fi

# Hiç VM config bulunamadıysa
if [ "$vm_found" = false ]; then
	echo "ERROR: No VM configurations found in $SWAY_CONFIG_DIR"
	echo ""
	echo "Expected files:"
	echo "  • qemu_vmubuntu"
	echo "  • qemu_vmarch"
	echo "  • qemu_vmnixos"
	echo ""
	sleep 5
	exit 1
fi

# VM seçim menüsü
echo "Available Virtual Machines:"
echo ""

[ -n "${vm_configs[1]}" ] && echo "  [1] ${vm_configs[1]}"
[ -n "${vm_configs[2]}" ] && echo "  [2] ${vm_configs[2]}"
[ -n "${vm_configs[3]}" ] && echo "  [3] ${vm_configs[3]}"

echo ""
echo "  [q] Quit"
echo ""
echo -n "Select VM to launch: "

# Kullanıcı seçimi
read -r selection

case "$selection" in
1)
	if [ -n "${vm_configs[1]}" ]; then
		echo ""
		echo "Launching ${vm_configs[1]} VM in Sway..."
		sleep 1
		exec sway -c "$SWAY_CONFIG_DIR/${vm_configs[1_file]}"
	else
		echo "ERROR: Invalid selection"
		sleep 2
		exit 1
	fi
	;;
2)
	if [ -n "${vm_configs[2]}" ]; then
		echo ""
		echo "Launching ${vm_configs[2]} VM in Sway..."
		sleep 1
		exec sway -c "$SWAY_CONFIG_DIR/${vm_configs[2_file]}"
	else
		echo "ERROR: Invalid selection"
		sleep 2
		exit 1
	fi
	;;
3)
	if [ -n "${vm_configs[3]}" ]; then
		echo ""
		echo "Launching ${vm_configs[3]} VM in Sway..."
		sleep 1
		exec sway -c "$SWAY_CONFIG_DIR/${vm_configs[3_file]}"
	else
		echo "ERROR: Invalid selection"
		sleep 2
		exit 1
	fi
	;;
q | Q)
	echo ""
	echo "Cancelled. Exiting..."
	exit 0
	;;
*)
	echo ""
	echo "ERROR: Invalid selection"
	sleep 2
	exit 1
	;;
esac
