# modules/core/virtualization/default.nix
# ==============================================================================
# Virtualization Configuration
# ==============================================================================
{ config, pkgs, username, ... }:
{
  # =============================================================================
  # User Group Configuration
  # =============================================================================
  users.users.${username}.extraGroups = [ 
    "libvirtd"  # Virtual machine management
    "kvm"       # KVM access
  ];

  # =============================================================================
  # Virtualization Services
  # =============================================================================
  virtualisation = {
    libvirtd = {
      enable = true;
      qemu = {
        swtpm.enable = true;  # TPM emulation
        ovmf = {
          enable = true;
          packages = [ pkgs.OVMFFull.fd ];  # UEFI firmware
        };
      };
    };
    spiceUSBRedirection.enable = true;  # USB device passthrough
  };

  # =============================================================================
  # SPICE Configuration
  # =============================================================================
  # SPICE agent for guest integration
  services.spice-vdagentd.enable = true;

  # =============================================================================
  # Device Rules
  # =============================================================================
  # USB and SPICE udev rules
  services.udev.extraRules = ''
    SUBSYSTEM=="usb", ATTR{idVendor}=="*", ATTR{idProduct}=="*", GROUP="libvirtd"
    SUBSYSTEM=="vfio", GROUP="libvirtd"
  '';

  # =============================================================================
  # Security Configuration
  # =============================================================================
  security.wrappers.spice-client-glib-usb-acl-helper.source = 
    "${pkgs.spice-gtk}/bin/spice-client-glib-usb-acl-helper";
}
