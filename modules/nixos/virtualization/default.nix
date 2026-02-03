# modules/nixos/virtualization/default.nix
# ==============================================================================
# NixOS virtualization stack: libvirt/qemu, docker/podman host settings.
# Enable hypervisor support and defaults here for all machines.
# Keep VM/container host config centralized instead of per-host tweaks.
# ==============================================================================

{ lib, pkgs, config, ... }:

let
  isPhysicalHost = config.my.host.isPhysicalHost;
in
{
  virtualisation = lib.mkIf isPhysicalHost {
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

  systemd = lib.mkIf isPhysicalHost {
    services.libvirtd.wantedBy = lib.mkForce [ "multi-user.target" ];
  };
}
