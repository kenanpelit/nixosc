# modules/core/system/hardware/default.nix
# ==============================================================================
# Hardware Configuration for ThinkPad X1 Carbon 6th
# ==============================================================================
# This configuration manages hardware settings including:
# - ThinkPad-specific ACPI and power management
# - Graphics drivers and Intel-specific optimizations
# - Firmware management
# - CPU configuration
# - LED control and function key management
#
# Author: Kenan Pelit
# ==============================================================================
{ pkgs, ... }:
{
  hardware = {
    # ThinkPad-specific configurations
    trackpoint.enable = true;  # Enable TrackPoint
    
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

  # ThinkPad ACPI and power management
  services = {
    throttled.enable = true;  # ThinkPad-specific CPU throttling daemon
    power-profiles-daemon.enable = true;
    tlp = {
      enable = true;
      settings = {
        CPU_SCALING_GOVERNOR_ON_AC = "performance";
        CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
        DEVICES_TO_DISABLE_ON_STARTUP = "bluetooth";
        START_CHARGE_THRESH_BAT0 = 75;
        STOP_CHARGE_THRESH_BAT0 = 80;
      };
    };
  };

  # ThinkPad-specific kernel modules and options
  boot = {
    kernelModules = [ "thinkpad_acpi" ];
    extraModprobeConfig = ''
      # ThinkPad ACPI options
      options thinkpad_acpi fan_control=1
      options thinkpad_acpi led_control=1
      options thinkpad_acpi brightness_mode=1
      options thinkpad_acpi volume_mode=1
    '';
  };

  # System Packages
  environment.systemPackages = with pkgs; [
    linux-firmware
    wireless-regdb
    firmware-updater
    lm_sensors
    acpi
    powertop     # Power consumption and management tool
    s-tui        # Terminal UI for monitoring CPU
    thinkfan     # ThinkPad fan control
  ];
}

