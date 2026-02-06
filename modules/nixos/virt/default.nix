# modules/nixos/virt/default.nix
# ==============================================================================
# NixOS Virtualization & Containerization Stack
# ------------------------------------------------------------------------------
# Unifies Libvirt/QEMU (VMs) and Podman/Docker (Containers).
# Enabled primarily on physical hosts to provide hypervisor capabilities.
# ==============================================================================

{ lib, pkgs, config, ... }:

let
  isPhysicalHost = config.my.host.isPhysicalHost or false;
in
{
  virtualisation = lib.mkIf isPhysicalHost {
    # -- Containers (Podman) ---------------------------------------------------
    podman = {
      enable = true;
      dockerCompat = true;
      defaultNetwork.settings.dns_enabled = true;
    };

    # -- Virtual Machines (Libvirt/QEMU) ---------------------------------------
    libvirtd = {
      enable = true;
      qemu = {
        package = pkgs.qemu_kvm;
        swtpm.enable = true;
      };
      onBoot = "ignore";
      onShutdown = "shutdown";
    };

    spiceUSBRedirection.enable = true;
  };

  # Ensure libvirtd starts automatically on physical hosts
  systemd = lib.mkIf isPhysicalHost {
    services.libvirtd.wantedBy = lib.mkDefault [ "multi-user.target" ];
  };
}
