# modules/core/spice/default.nix
# ==============================================================================
# SPICE Configuration
# ==============================================================================
# This configuration manages SPICE settings including:
# - USB redirection
# - Device agent
# - Security wrappers
# - Device rules
# - KVM/QEMU integration
#
# Author: Kenan Pelit
# ==============================================================================
{ pkgs, ... }:
{
  # SPICE USB Redirection
  virtualisation.spiceUSBRedirection.enable = true;  # USB device passthrough
  
  services = {
    # SPICE agent for guest integration
    spice-vdagentd.enable = true;
    
    # Device Rules
    udev.extraRules = ''
      # USB devices for libvirtd group
      SUBSYSTEM=="usb", ATTR{idVendor}=="*", ATTR{idProduct}=="*", GROUP="libvirtd"
      
      # VFIO devices for GPU passthrough
      SUBSYSTEM=="vfio", GROUP="libvirtd"
      
      # Additional SPICE-specific rules
      KERNEL=="kvm", GROUP="kvm", MODE="0664"
      SUBSYSTEM=="misc", KERNEL=="vhost-net", GROUP="kvm", MODE="0664"
    '';
  };
  
  # Security Configuration  
  security.wrappers.spice-client-glib-usb-acl-helper.source = 
    "${pkgs.spice-gtk}/bin/spice-client-glib-usb-acl-helper";
  
  # SPICE packages
  environment.systemPackages = with pkgs; [
    spice-gtk          # SPICE client libraries
    spice-protocol     # SPICE protocol headers
    virt-viewer        # Remote desktop viewer
  ];
}

