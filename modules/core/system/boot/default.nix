# modules/core/system/boot/default.nix
# ==============================================================================
# Bootloader Configuration
# ==============================================================================
# This configuration manages boot settings including:
# - GRUB bootloader setup
# - EFI support
# - Kernel configuration
#
# Author: Kenan Pelit
# ==============================================================================
{ pkgs, config, lib, inputs, system, ... }:
let
  hostname = config.networking.hostName;
  isPhysicalMachine = hostname == "hay";
in
{
  boot = {
    kernelPackages = pkgs.linuxPackages_latest;
    
    loader = {
      grub = {
        enable = true;
        device = lib.mkForce (if isPhysicalMachine then "nodev" else "/dev/vda");
        efiSupport = isPhysicalMachine;
        useOSProber = true;
        configurationLimit = 10;
        
        # Visual Configuration
        theme = inputs.distro-grub-themes.packages.${system}.nixos-grub-theme;
        splashImage = "${inputs.distro-grub-themes.packages.${system}.nixos-grub-theme}/splash_image.jpg";
        gfxmodeEfi = "1920x1080";
        gfxmodeBios = "1920x1080";
      };
      
      efi = if isPhysicalMachine then {
        canTouchEfiVariables = true;
        efiSysMountPoint = "/boot";
      } else {};
    };
  };

  # Clean up old theme directories before GRUB installation
  system.activationScripts.cleanGrubTheme = ''
    echo "Cleaning up old GRUB theme directories..."
    rm -rf /boot/theme
    rm -rf /boot/grub/themes
  '';
}
