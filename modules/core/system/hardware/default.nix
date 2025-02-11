# modules/core/system/hardware/default.nix
# ==============================================================================
# Hardware Configuration for ThinkPad X1 Carbon 6th
# ==============================================================================
# This configuration manages hardware settings including:
# - ThinkPad-specific ACPI and power management
# - Graphics drivers and Intel-specific optimizations
# - NVMe storage and SSD optimizations
# - CPU/Power configuration
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
   # ThinkPad-specific CPU throttling daemon
   throttled.enable = true;
   
   # Advanced Power Management
   tlp = {
     enable = true;
     settings = {
       # CPU Power Management
       CPU_SCALING_GOVERNOR_ON_AC = "performance";
       CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
       
       # Battery Charge Thresholds
       START_CHARGE_THRESH_BAT0 = 75;
       STOP_CHARGE_THRESH_BAT0 = 80;
       
       # NVMe Power Management
       RUNTIME_PM_ON_AC = "auto";
       RUNTIME_PM_ON_BAT = "auto";
       
       # PCIe Active State Power Management
       PCIE_ASPM_ON_AC = "default";
       PCIE_ASPM_ON_BAT = "powersupersave";
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
   
   # Kernel parameters for better NVMe performance
   kernelParams = [
     "nvme.noacpi=1"  # Disable ACPI for NVMe to improve performance
   ];
 };

 # System Packages
 environment.systemPackages = with pkgs; [
   linux-firmware
   wireless-regdb
   firmware-updater
   lm_sensors       # Hardware sensors
   acpi            # ACPI utilities
   powertop        # Power consumption analysis
   s-tui           # Terminal UI for monitoring CPU
   thinkfan        # ThinkPad fan control
   nvme-cli        # NVMe management tools
 ];
}
