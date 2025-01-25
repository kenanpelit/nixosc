# modules/core/virtualization/default.nix
# ==============================================================================
# Virtualization Configuration
# ==============================================================================
# This configuration file manages all virtualization-related settings including:
# - Podman container engine
# - QEMU/KVM virtualization
# - Container registry settings
# - Hardware virtualization support
#
# Key components:
# - Podman configuration with Docker compatibility
# - LibvirtD and QEMU settings
# - Container registry management
# - USB and SPICE device handling
#
# Author: Kenan Pelit
# ==============================================================================

{ ... }:
{
  imports = [
    ./podman
    ./container
    ./vm
    ./spice
  ];
}
