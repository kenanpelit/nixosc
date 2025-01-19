# modules/core/system/default.nix
# ==============================================================================
# Core System Configuration
# ==============================================================================
# This configuration file manages core system settings including:
# - Bootloader configuration
# - Hardware management and drivers
# - Power management and thermal control
# - System logging (journald)
# - Base system settings (locale, keyboard, etc.)
#
# Key components:
# - GRUB bootloader with EFI support
# - Intel hardware optimization
# - Power management for laptops
# - System logging configuration
# - Localization and keyboard settings
#
# Author: Kenan Pelit
# ==============================================================================

{ pkgs, config, lib, inputs, system, ... }:
let
 hostname = config.networking.hostName;
 isPhysicalMachine = hostname == "hay";
in
{
 # =============================================================================
 # Bootloader Configuration
 # =============================================================================
 boot = {
   kernelPackages = pkgs.linuxPackages_latest;
   
   loader = {
     grub = {
       enable = true;
       device = lib.mkForce (if isPhysicalMachine then "nodev" else "/dev/vda");
       efiSupport = isPhysicalMachine;
       useOSProber = true;
       configurationLimit = 10;
       
       # Visual Configuration
       theme = inputs.distro-grub-themes.packages.${system}.nixos-grub-theme;
       splashImage = "${inputs.distro-grub-themes.packages.${system}.nixos-grub-theme}/splash_image.jpg";
       gfxmodeEfi = "1920x1080";
       gfxmodeBios = "1920x1080";
     };
     
     efi = if isPhysicalMachine then {
       canTouchEfiVariables = true;
       efiSysMountPoint = "/boot";
     } else {};
   };
 };

 # =============================================================================
 # Hardware Configuration
 # =============================================================================
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

 # =============================================================================
 # Power Management
 # =============================================================================
 services = {
   # UPower Configuration
   upower = {
     enable = true;
     criticalPowerAction = "Hibernate";
   };

   # Logind Power Management
   logind = {
     lidSwitch = "suspend";
     lidSwitchDocked = "ignore";
     lidSwitchExternalPower = "suspend";
     extraConfig = ''
       HandlePowerKey=suspend
       HandleSuspendKey=suspend
       HandleHibernateKey=hibernate
       IdleAction=suspend
       IdleActionSec=30min
     '';
   };

   # TLP Power Management
   tlp = {
     enable = true;
     settings = {
       CPU_SCALING_GOVERNOR_ON_AC = "performance";
       CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
       CPU_ENERGY_PERF_POLICY_ON_AC = "performance";
       CPU_ENERGY_PERF_POLICY_ON_BAT = "power";
       CPU_MIN_PERF_ON_AC = 0;
       CPU_MAX_PERF_ON_AC = 100;
       CPU_MIN_PERF_ON_BAT = 0;
       CPU_MAX_PERF_ON_BAT = 80;
     };
   };

   # Thermal Management
   thermald.enable = true;

   # System Logging
   journald = {
     extraConfig = ''
       SystemMaxUse=5G
       SystemMaxFileSize=500M
       MaxRetentionSec=1month
     '';
   };
 };

 # =============================================================================
 # Base System Settings
 # =============================================================================
 # Time Zone
 time.timeZone = "Europe/Istanbul";

 # Locale Configuration
 i18n = {
   defaultLocale = "en_US.UTF-8";
   extraLocaleSettings = {
     LC_ADDRESS = "tr_TR.UTF-8";
     LC_IDENTIFICATION = "tr_TR.UTF-8";
     LC_MEASUREMENT = "tr_TR.UTF-8";
     LC_MONETARY = "tr_TR.UTF-8";
     LC_NAME = "tr_TR.UTF-8";
     LC_NUMERIC = "tr_TR.UTF-8";
     LC_PAPER = "tr_TR.UTF-8";
     LC_TELEPHONE = "tr_TR.UTF-8";
     LC_TIME = "tr_TR.UTF-8";
   };
 };

 # Keyboard Configuration
 services.xserver.xkb = {
   layout = "tr";
   variant = "f";
   options = "ctrl:nocaps";
 };
 console.keyMap = "trf";

 # System Packages
 environment.systemPackages = with pkgs; [
   linux-firmware
   wireless-regdb
   firmware-updater
   lm_sensors
 ];

 # System Version
 system.stateVersion = "24.11";
}

