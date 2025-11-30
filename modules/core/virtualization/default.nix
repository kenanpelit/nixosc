# modules/core/virtualization/default.nix
# Libvirt/QEMU/Spice setup for physical host.

{ lib, pkgs, isPhysicalHost ? false, ... }:

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
