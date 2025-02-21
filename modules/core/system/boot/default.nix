# modules/core/system/boot/default.nix
# ==============================================================================
# Boot Configuration Module
# ==============================================================================
#
# This module manages the system's boot configuration, including:
# - GRUB bootloader with EFI/Legacy support
# - Machine-specific configurations (physical vs. virtual)
# - Visual settings and theming
# - Kernel package selection
#
# Key Features:
# - Conditional EFI support based on machine type
# - OS detection for multi-boot setups
# - High-resolution GRUB interface
# - NixOS theme integration
#
# Usage:
# This module is typically imported in your system configuration.
# The hostname check determines whether it's running on physical
# or virtual hardware and adjusts settings accordingly.
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
   # Use the latest stable kernel packages
   kernelPackages = pkgs.linuxPackages_latest;
   
   loader = {
     grub = {
       enable = true;
       # Use EFI/nodev for physical machine, /dev/vda for VMs
       device = lib.mkForce (if isPhysicalMachine then "nodev" else "/dev/vda");
       # Enable EFI support only for physical machine
       efiSupport = isPhysicalMachine;
       # Enable detection of other operating systems
       useOSProber = true;
       # Limit the number of configurations to keep
       configurationLimit = 10;
       
       # Visual Configuration
       # Set high-resolution display modes
       gfxmodeEfi = "1920x1080";    # EFI mode resolution
       gfxmodeBios = "1920x1080";   # BIOS mode resolution
       # Apply NixOS GRUB theme
       theme = inputs.distro-grub-themes.packages.${system}.nixos-grub-theme;
       #theme = inputs.distro-grub-themes.packages.${system}.thinkpad-grub-theme;
     };
     
     # EFI-specific configuration for physical machine
     efi = if isPhysicalMachine then {
       canTouchEfiVariables = true;  # Allow modification of EFI variables
       efiSysMountPoint = "/boot";   # EFI system partition mount point
     } else {};
   };
 };
}
