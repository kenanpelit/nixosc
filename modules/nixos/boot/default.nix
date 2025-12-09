# modules/nixos/boot/default.nix
# ==============================================================================
# NixOS boot policy: loader selection, kernel params, initrd bits for each host.
# Centralizes EFI/systemd-boot settings and filesystem mount tuning.
# Adjust early-boot toggles here instead of per-host ad-hoc edits.
# ==============================================================================

{ lib, inputs, system, config, ... }:

let
  isPhysicalMachine = config.my.host.isPhysicalHost;
  isVirtualMachine  = config.my.host.isVirtualHost;
in
{
  boot.loader = {
    grub = {
      enable  = true;
      device  = lib.mkForce (if isVirtualMachine then "/dev/vda" else "nodev");
      efiSupport = isPhysicalMachine;
      useOSProber = lib.mkDefault false;
      configurationLimit = 10;
      gfxmodeEfi  = "1920x1200";
      gfxmodeBios = if isVirtualMachine then "1920x1080" else "1920x1200";
      theme = inputs.distro-grub-themes.packages.${system}.nixos-grub-theme;
    };

    efi = lib.mkIf isPhysicalMachine {
      canTouchEfiVariables = true;
      efiSysMountPoint     = "/boot";
    };
  };
}
