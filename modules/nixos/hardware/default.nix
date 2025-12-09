# modules/nixos/hardware/default.nix
# ==============================================================================
# NixOS module for hardware (system-wide stack).
# Provides host defaults and service toggles declared in this file.
# Keeps machine-wide settings centralized under modules/nixos.
# Extend or override options here instead of ad-hoc host tweaks.
# ==============================================================================

{ pkgs, lib, config, ... }:

let
  isPhysicalMachine = config.my.host.isPhysicalHost;
  isVirtualMachine  = config.my.host.isVirtualHost;
in
{
  hardware = {
    trackpoint = lib.mkIf isPhysicalMachine {
      enable       = true;
      speed        = 200;
      sensitivity  = 200;
      emulateWheel = true;
    };

    graphics = {
      enable      = true;
      enable32Bit = true;
      extraPackages = with pkgs; [
        intel-media-driver
        mesa
        libva-vdpau-driver
        libvdpau-va-gl
      ];
      extraPackages32 = with pkgs.pkgsi686Linux; [
        intel-media-driver
      ];
    };

    enableRedistributableFirmware = true;
    enableAllFirmware             = true;
    cpu.intel.updateMicrocode     = true;
  };
}
