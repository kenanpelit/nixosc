# modules/core/spice/default.nix
# ==============================================================================
# SPICE Configuration
# ==============================================================================
# This configuration manages SPICE settings including:
# - USB redirection
# - Device agent
# - Security wrappers
# - Device rules
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
      SUBSYSTEM=="usb", ATTR{idVendor}=="*", ATTR{idProduct}=="*", GROUP="libvirtd"
      SUBSYSTEM=="vfio", GROUP="libvirtd"
    '';
  };

  # Security Configuration
  security.wrappers.spice-client-glib-usb-acl-helper.source = 
    "${pkgs.spice-gtk}/bin/spice-client-glib-usb-acl-helper";
}
