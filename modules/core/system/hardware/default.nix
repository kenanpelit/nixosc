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
# Modified: 2025-05-12 (COSMIC compatibility)
# ==============================================================================
{ pkgs, ... }:
{
 hardware = {
   # ThinkPad-specific configurations
   trackpoint.enable = true;  # Enable the red TrackPoint nub for precise pointer control
   
   # Graphics Drivers and Hardware Acceleration
   # Configured for Intel integrated graphics with full acceleration support
   graphics = {
     enable = true;
     extraPackages = with pkgs; [
       intel-media-driver      # Modern VA-API driver for Intel GPUs
       vaapiVdpau             # Bridge between VA-API and VDPAU
       libvdpau-va-gl         # VDPAU driver using OpenGL/VA-API
       mesa                   # Open source graphics drivers
       intel-compute-runtime  # OpenCL support for Intel GPUs
       intel-ocl              # Intel OpenCL runtime
     ];
   };
   
   # Firmware Configuration
   # Ensures all necessary device firmware is available
   enableRedistributableFirmware = true;  # Enable firmware that can be redistributed
   enableAllFirmware = true;              # Include all available firmware
   
   # CPU Configuration
   # Intel-specific CPU settings
   cpu.intel.updateMicrocode = true;      # Enable CPU microcode updates for security
 };
 
 # ThinkPad ACPI and power management
 services = {
   # ThinkPad-specific CPU throttling daemon
   # Prevents CPU throttling issues on ThinkPad devices
   throttled.enable = true;
   
   # Advanced Power Management
   # TLP disabled to avoid conflict with power-profiles-daemon used by COSMIC
   tlp = {
     enable = false;  # Disabled for COSMIC compatibility
     settings = {
       # CPU Power Management (preserved for reference)
       CPU_SCALING_GOVERNOR_ON_AC = "performance";
       CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
       
       # Battery Charge Thresholds
       # Extends battery lifespan by limiting charge levels
       START_CHARGE_THRESH_BAT0 = 75;  # Start charging at 75%
       STOP_CHARGE_THRESH_BAT0 = 80;   # Stop charging at 80%
       
       # NVMe Power Management
       # Controls power states for NVMe drives
       RUNTIME_PM_ON_AC = "auto";
       RUNTIME_PM_ON_BAT = "auto";
       
       # PCIe Active State Power Management
       # Controls power saving for PCIe devices
       PCIE_ASPM_ON_AC = "default";
       PCIE_ASPM_ON_BAT = "powersupersave";
     };
   };
 };
 
 # ThinkPad-specific kernel modules and options
 boot = {
   # Load ThinkPad ACPI module for hardware control
   kernelModules = [ "thinkpad_acpi" ];
   
   # Configure ThinkPad ACPI module options
   extraModprobeConfig = ''
     # ThinkPad ACPI options
     options thinkpad_acpi fan_control=1   # Enable fan speed control
     options thinkpad_acpi led_control=1   # Enable LED control
     options thinkpad_acpi brightness_mode=1  # Enable brightness control
     options thinkpad_acpi volume_mode=1   # Enable volume control
   '';
   
   # Kernel parameters for better NVMe performance
   kernelParams = [
     "nvme.noacpi=1"  # Disable ACPI for NVMe to improve performance
   ];
 };
 
 # System Packages
 # Tools for hardware monitoring and management
 environment.systemPackages = with pkgs; [
   linux-firmware     # Additional firmware files
   wireless-regdb     # Wireless regulatory database
   firmware-updater   # Firmware update utilities
   lm_sensors         # Hardware sensors monitoring
   acpi               # ACPI utilities for battery/power info
   powertop           # Power consumption analysis tool
   s-tui              # Terminal UI for monitoring CPU
   thinkfan           # ThinkPad fan control utility
   nvme-cli           # NVMe management tools
 ];
}
