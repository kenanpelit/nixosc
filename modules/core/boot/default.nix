# modules/core/boot/default.nix
# Boot loader and theme.

{ lib, inputs, system, isPhysicalHost ? false, isVirtualHost ? false, ... }:

let
  isPhysicalMachine = isPhysicalHost;
  isVirtualMachine  = isVirtualHost;

  # NixOS grub theme path from distro-grub-themes flake
  grubThemePath =
    "${inputs.distro-grub-themes.packages.${system}.nixos-grub-theme}";
in
{
  boot.loader = {
    grub = {
      enable  = true;
      device  = lib.mkForce (if isVirtualMachine then "/dev/vda" else "nodev");
      efiSupport = isPhysicalMachine;
      useOSProber = true;
      configurationLimit = 10;
      gfxmodeEfi  = "auto";
      gfxmodeBios = "auto";
      splashImage = null;
      theme = grubThemePath; # path to theme directory (expects theme.txt inside)
    };

    efi = lib.mkIf isPhysicalMachine {
      canTouchEfiVariables = true;
      efiSysMountPoint     = "/boot";
    };
  };
}
