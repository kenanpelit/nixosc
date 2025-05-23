# modules/core/system/hardware/default.nix
# ==============================================================================
# Hardware Configuration for ThinkPad E14 Gen 6
# ==============================================================================
# This configuration manages hardware settings including:
# - ThinkPad-specific ACPI and power management
# - Intel Arc Graphics drivers and hardware acceleration
# - NVMe storage optimizations for dual-drive setup
# - Intel Core Ultra 7 155H CPU configuration
# - LED control and function key management
# - TrackPoint and touchpad configuration
#
# Target Hardware:
# - ThinkPad E14 Gen 6 (21M7006LTX)
# - Intel Core Ultra 7 155H (16-core hybrid architecture)
# - Intel Arc Graphics (Meteor Lake-P)
# - 64GB DDR5 RAM
# - Dual NVMe setup: Transcend TS2TMTE400S + Timetec 35TT2280GEN4E-2TB
#
# Author: Kenan Pelit
# Modified: 2025-05-23 (E14 Gen 6 optimization)
# ==============================================================================
{ pkgs, ... }:
{
  hardware = {
    # ThinkPad-specific configurations
    trackpoint.enable = true;  # Enable the red TrackPoint nub for precise pointer control
    
    # Graphics Drivers and Hardware Acceleration
    # Optimized for Intel Arc Graphics (Meteor Lake-P) with full acceleration support
    graphics = {
      enable = true;
      extraPackages = with pkgs; [
        intel-media-driver      # Modern VA-API driver for Intel Arc Graphics
        vaapiVdpau             # Bridge between VA-API and VDPAU for video acceleration
        libvdpau-va-gl         # VDPAU driver using OpenGL/VA-API backend
        mesa                   # Open source graphics drivers with Arc support
        intel-compute-runtime  # OpenCL support for Intel Arc Graphics
        intel-ocl              # Intel OpenCL runtime for compute workloads
      ];
    };
    
    # Firmware Configuration
    # Essential for E14 Gen 6's modern hardware components
    enableRedistributableFirmware = true;  # Enable firmware that can be redistributed
    enableAllFirmware = true;              # Include all available firmware for WiFi, Bluetooth, etc.
    
    # CPU Configuration
    # Intel Core Ultra 7 155H specific settings
    cpu.intel.updateMicrocode = true;      # Enable CPU microcode updates for security and stability
  };
  
  # ThinkPad ACPI and power management
  services = {
    # ThinkPad-specific CPU throttling daemon
    # Critical for preventing thermal throttling on Intel Core Ultra 7 155H
    throttled.enable = true;
    
    # Advanced Power Management
    # TLP disabled to avoid conflict with power-profiles-daemon used by Hyprland/modern desktop
    tlp = {
      enable = false;  # Disabled for modern desktop environment compatibility
      settings = {
        # CPU Power Management for hybrid architecture (P-cores + E-cores)
        CPU_SCALING_GOVERNOR_ON_AC = "performance";  # Use performance governor when plugged in
        CPU_SCALING_GOVERNOR_ON_BAT = "powersave";   # Use powersave governor on battery
        
        # Battery Charge Thresholds
        # Note: E14 Gen 6 may not support charge thresholds via standard interface
        # These settings are preserved for reference but may not take effect
        START_CHARGE_THRESH_BAT0 = 70;  # Start charging at 70% (conservative for longevity)
        STOP_CHARGE_THRESH_BAT0 = 85;   # Stop charging at 85% (optimal for daily use)
        
        # NVMe Power Management
        # Optimized for dual NVMe setup (Transcend + Timetec drives)
        RUNTIME_PM_ON_AC = "auto";      # Allow runtime power management when plugged in
        RUNTIME_PM_ON_BAT = "auto";     # Enable aggressive power saving on battery
        
        # PCIe Active State Power Management
        # Controls power saving for PCIe devices (WiFi, NVMe, etc.)
        PCIE_ASPM_ON_AC = "default";           # Standard power management when plugged in
        PCIE_ASPM_ON_BAT = "powersupersave";   # Aggressive power saving on battery
      };
    };
  };
  
  # ThinkPad-specific kernel modules and options
  boot = {
    # Load ThinkPad ACPI module for hardware control
    kernelModules = [ "thinkpad_acpi" ];
    
    # Configure ThinkPad ACPI module options for E14 Gen 6
    extraModprobeConfig = ''
      # ThinkPad ACPI options for E14 Gen 6
      options thinkpad_acpi fan_control=1      # Enable manual fan speed control
      options thinkpad_acpi led_control=1      # Enable LED control (power button, etc.)
      options thinkpad_acpi brightness_mode=1  # Enable brightness control via ACPI
      options thinkpad_acpi volume_mode=1      # Enable volume control via function keys
    '';
    
    # Kernel parameters optimized for E14 Gen 6 hardware
    kernelParams = [
      "nvme.noacpi=1"     # Disable ACPI for NVMe to improve performance on dual-drive setup
      "intel_iommu=on"    # Enable Intel IOMMU for security and virtualization support
    ];
  };
  
  # System Packages
  # Essential tools for hardware monitoring and management on E14 Gen 6
  environment.systemPackages = with pkgs; [
    linux-firmware     # Additional firmware files for modern hardware
    wireless-regdb     # Wireless regulatory database for Intel WiFi
    firmware-updater   # Firmware update utilities for UEFI and device firmware
    lm_sensors         # Hardware sensors monitoring (temperature, fans, voltages)
    acpi               # ACPI utilities for battery and power information
    powertop           # Power consumption analysis tool for battery optimization
    s-tui              # Terminal UI for monitoring CPU performance and thermals
    thinkfan           # ThinkPad fan control utility (if manual control needed)
    nvme-cli           # NVMe management tools for dual-drive health monitoring
    intel-gpu-tools    # Intel GPU utilities for Arc Graphics monitoring
  ];
}
