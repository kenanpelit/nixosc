# modules/nixos/boot/default.nix
# ------------------------------------------------------------------------------
# NixOS module for boot (system-wide stack).
# Provides host defaults and service toggles declared in this file.
# Keeps machine-wide settings centralized under modules/nixos.
# Extend or override options here instead of ad-hoc host tweaks.
# ------------------------------------------------------------------------------

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
