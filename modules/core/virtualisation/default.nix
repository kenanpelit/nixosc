# modules/core/virtualisation/default.nix
# ==============================================================================
# Virtualisation Configuration
# ==============================================================================
# This configuration manages virtualisation settings including:
# - Container runtime (Podman) and registries
# - VM engine settings (LibvirtD, QEMU)
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
  };
}

