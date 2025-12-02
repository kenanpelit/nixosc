# modules/core/boot/default.nix
# ==============================================================================
# Bootloader Configuration
# ==============================================================================
# Configures the GRUB bootloader and EFI settings.
# - GRUB enablement and theme
# - EFI support for physical machines
# - OS prober enablement
#
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
      useOSProber = true;
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