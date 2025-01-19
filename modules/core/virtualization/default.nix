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

{ config, lib, pkgs, username, ... }:
{
 # =============================================================================
 # User Group Configuration
 # =============================================================================
 users.users.${username}.extraGroups = [ 
   "libvirtd"  # Virtual machine management
   "kvm"       # KVM access
 ];

 # =============================================================================
 # Container Engine Configuration
 # =============================================================================
 virtualisation = {
   # Podman Configuration
   podman = {
     enable = true;
     dockerCompat = true;        # Docker command compatibility
     
     # Network Configuration
     defaultNetwork.settings = {
       dns_enabled = true;
     };
     
     # Automatic Cleanup
     autoPrune = {
       enable = true;
       flags = ["--all"];        # Clean all unused images
       dates = "weekly";         # Weekly cleanup schedule
     };
     
     # Required Packages
     extraPackages = [
       pkgs.runc            # Container runtime
       pkgs.conmon          # Container monitoring
       pkgs.skopeo          # Container image tool
       pkgs.slirp4netns     # Rootless networking
     ];
   };

   # Container Registry Configuration
   containers = {
     enable = true;
     registries = {
       search = [ "docker.io" "quay.io" ];
       insecure = [];
       block = [];
     };
   };

   # =============================================================================
   # VM Engine Configuration
   # =============================================================================
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

   # SPICE USB Redirection
   spiceUSBRedirection.enable = true;  # USB device passthrough
 };

 # =============================================================================
 # SPICE Configuration
 # =============================================================================
 services = {
   # SPICE agent for guest integration
   spice-vdagentd.enable = true;
   
   # Device Rules
   udev.extraRules = ''
     SUBSYSTEM=="usb", ATTR{idVendor}=="*", ATTR{idProduct}=="*", GROUP="libvirtd"
     SUBSYSTEM=="vfio", GROUP="libvirtd"
   '';
 };

 # =============================================================================
 # Security Configuration
 # =============================================================================
 security.wrappers.spice-client-glib-usb-acl-helper.source = 
   "${pkgs.spice-gtk}/bin/spice-client-glib-usb-acl-helper";
}
