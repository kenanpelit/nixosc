# modules/core/virtualization/default.nix
# ==============================================================================
# Virtualization Configuration
# ==============================================================================
# Configures Libvirt/QEMU virtualization stack for physical hosts.
# - Enables libvirtd service
# - Configures QEMU with swtpm support
# - Enables Spice USB redirection
#
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
