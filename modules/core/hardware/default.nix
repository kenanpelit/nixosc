# modules/core/hardware/default.nix
# ==============================================================================
# Hardware Configuration
# ==============================================================================
# Configures hardware-specific settings for physical and virtual hosts.
# - Graphics drivers (Intel/Mesa)
# - Firmware (Redistributable/All)
# - CPU Microcode (Intel)
# - Input devices (Trackpoint)
#
# ==============================================================================

{ pkgs, lib, isPhysicalHost ? false, isVirtualHost ? false, ... }:

let
  isPhysicalMachine = isPhysicalHost;
  isVirtualMachine  = isVirtualHost;
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
