#!/usr/bin/env zsh
# vm-start.sh - Basit libvirt VM başlatıcı
# win10 VM’ini başlatır, Hyprland workspace 6’ya geçip virsh ile çalıştırır.

# VM name
vm_name="win10"
export LIBVIRT_DEFAULT_URI="qemu:///system"

# change workspace
hyprctl dispatch workspace 6

virsh start ${vm_name}
virt-viewer -f -w -a ${vm_name}
