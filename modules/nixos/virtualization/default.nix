# modules/nixos/virtualization/default.nix
# ------------------------------------------------------------------------------
# NixOS module for virtualization (system-wide stack).
# Provides host defaults and service toggles declared in this file.
# Keeps machine-wide settings centralized under modules/nixos.
# Extend or override options here instead of ad-hoc host tweaks.
# ------------------------------------------------------------------------------

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
