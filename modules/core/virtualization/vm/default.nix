# modules/core/virtualization/vm/default.nix
# ==============================================================================
# VM Engine Configuration
# ==============================================================================
# This configuration manages VM settings including:
# - LibvirtD configuration
# - QEMU settings
# - TPM and UEFI support
# - User permissions
#
# Author: Kenan Pelit
# ==============================================================================

{ pkgs, username, ... }:
{
  users.users.${username}.extraGroups = [ 
    "libvirtd"  # Virtual machine management
    "kvm"       # KVM access
  ];

  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      swtpm.enable = true;  # TPM emulation
      ovmf = {
        enable = true;
        packages = [ pkgs.OVMFFull.fd ];  # UEFI firmware
      };
    };
  };
}
