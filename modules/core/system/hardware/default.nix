# modules/core/system/hardware/default.nix
# ==============================================================================
# Hardware Configuration
# ==============================================================================
# This configuration manages hardware settings including:
# - Graphics drivers
# - Firmware management
# - CPU configuration
#
# Author: Kenan Pelit
# ==============================================================================

{ pkgs, ... }:
{
  hardware = {
    # Graphics Drivers and Hardware Acceleration
    graphics = {
      enable = true;
      extraPackages = with pkgs; [
        intel-media-driver
        vaapiVdpau
        libvdpau-va-gl
        mesa
        intel-compute-runtime
        intel-ocl
      ];
    };
    
    # Firmware Configuration
    enableRedistributableFirmware = true;
    enableAllFirmware = true;
    
    # CPU Configuration
    cpu.intel.updateMicrocode = true;
  };

  # System Packages
  environment.systemPackages = with pkgs; [
    linux-firmware
    wireless-regdb
    firmware-updater
    lm_sensors
  ];
}
