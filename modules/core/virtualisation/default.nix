# modules/core/virtualisation/default.nix
# ==============================================================================
# Virtualisation Configuration
# ==============================================================================
# This configuration manages virtualisation settings including:
# - Container runtime (Podman) and registries
# - VM engine settings (LibvirtD, QEMU)
# - SPICE guest services and USB redirection
# - TPM and UEFI support
# - User permissions for virtualisation
# - Container maintenance and cleanup
#
# Author: Kenan Pelit
# ==============================================================================
{ pkgs, username, ... }:
{
  # User permissions for virtualisation
  users.users.${username}.extraGroups = [ 
    "libvirtd"  # Virtual machine management
    "kvm"       # KVM access
    "docker"    # Container access
  ];

  virtualisation = {
    # Container Configuration
    containers = {
      enable = true;
      registries = {
        search = [ "docker.io" "quay.io" ];
        insecure = [];
        block = [];
      };
    };

    # Container Runtime (Podman)
    podman = {
      enable = true;
      dockerCompat = true;
      
      defaultNetwork.settings = {
        dns_enabled = true;
      };
      
      autoPrune = {
        enable = true;
        flags = ["--all"];
        dates = "weekly";
      };
      
      extraPackages = with pkgs; [
        runc
        conmon
        skopeo
        slirp4netns
      ];
    };

    # VM Engine Configuration
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

  services = {
    # SPICE agent for guest integration
    spice-vdagentd.enable = true;
    
    # Device Rules for Virtualisation
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
  
  # Security Configuration for SPICE
  security.wrappers.spice-client-glib-usb-acl-helper.source = 
    "${pkgs.spice-gtk}/bin/spice-client-glib-usb-acl-helper";
  
  # Virtualisation packages
  environment.systemPackages = with pkgs; [
    spice-gtk          # SPICE client libraries
    spice-protocol     # SPICE protocol headers
    virt-viewer        # Remote desktop viewer
  ];
}
