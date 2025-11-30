# modules/core/boot/default.nix
# Boot loader and theme.

{ lib, inputs, system, isPhysicalHost ? false, isVirtualHost ? false, ... }:

let
  isPhysicalMachine = isPhysicalHost;
  isVirtualMachine  = isVirtualHost;

  # NixOS grub theme path from distro-grub-themes flake
  grubThemePath =
    "${inputs.distro-grub-themes.packages.${system}.nixos-grub-theme}/share/grub/themes/nixos";
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
      theme = grubThemePath; # path to theme directory (expects theme.txt inside)
    };

    efi = lib.mkIf isPhysicalMachine {
      canTouchEfiVariables = true;
      efiSysMountPoint     = "/boot";
    };
  };
}
