# modules/nixos/hardware/default.nix
# ==============================================================================
# NixOS hardware enablement: CPU/GPU quirks, firmware, microcode, sensors.
# Collects common hardware toggles so hosts stay consistent.
# Update this file for new devices instead of per-host patches.
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

    # Firmware/microcode defaults are handled in modules/nixos/kernel.
  };
}
