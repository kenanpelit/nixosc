# modules/core/hardware/default.nix
# Graphics, firmware, trackpoint, misc hw.

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
