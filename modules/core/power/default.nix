# modules/core/power/default.nix
# ==============================================================================
# Power Management Configuration
# ==============================================================================
# This configuration manages power-related settings including:
# - UPower configuration
# - Power management policies
# - Thermal control
# - System logging
# - Deep sleep configuration (FIXED s2idle issue)
#
# Author: Kenan Pelit
# Power Management Configuration - FIXED for Lid Suspend & Deep Sleep
# ==============================================================================
{ ... }:
{
  # Boot Configuration for Deep Sleep
  boot = {
    kernelParams = [
      "mem_sleep_default=deep"    # Force deep sleep instead of s2idle
      "acpi_osi=Linux"           # Better ACPI compatibility
      "pcie_aspm=force"          # Aggressive PCIe power management
    ];
    
    # Additional kernel modules for power management
    kernelModules = [ "acpi_call" ];
    extraModulePackages = with config.boot.kernelPackages; [ acpi_call ];
  };

  services = {
    # UPower Configuration
    upower = {
      enable = true;
      criticalPowerAction = "Hibernate";  # Hibernate when battery critically low
    };
    
    # Power Management (logind) - FIXED for lid suspend
    logind = {
      lidSwitch = "suspend";              # Suspend when laptop lid closed
      lidSwitchDocked = "suspend";        # Suspend when lid closed while docked  
      lidSwitchExternalPower = "suspend"; # Suspend when lid closed on AC power
      extraConfig = ''
        HandlePowerKey=ignore             # Ignore power button (prevent accidental shutdown)
        HandleSuspendKey=suspend          # Suspend when suspend key pressed
        HandleHibernateKey=hibernate      # Hibernate when hibernate key pressed
        HandleLidSwitch=suspend           # EXPLICIT: Suspend on lid close
        HandleLidSwitchDocked=suspend     # EXPLICIT: Suspend on lid close when docked
        HandleLidSwitchExternalPower=suspend # EXPLICIT: Suspend on lid close on AC
        IdleAction=ignore                 # FIXED: Don't compete with GNOME idle management
        # IdleActionSec removed - let GNOME handle idle
      '';
    };
    
    # TLP - Keep disabled to avoid conflicts
    tlp.enable = false;
    
    # FIXED: Disable power-profiles-daemon to avoid conflict with GNOME
    power-profiles-daemon.enable = false;  # This may conflict with GNOME power management
    
    # Thermal Management
    thermald.enable = true;
    
    # System Logging Configuration
    journald = {
      extraConfig = ''
        SystemMaxUse=5G
        SystemMaxFileSize=500M
        MaxRetentionSec=1month
      '';
    };
  };
  
  # Power Management Configuration
  powerManagement = {
    enable = true;
    powertop.enable = true;           # Enable powertop for power optimization
    cpuFreqGovernor = "powersave";    # Use powersave governor for better battery life
    
    # Wake-on-LAN and USB wake-up settings
    powerUpCommands = ''
      # Disable wake-up for power-hungry devices
      echo disabled > /proc/acpi/wakeup || echo "GLAN wake-up disable failed"
      
      # Keep essential wake sources
      echo enabled > /proc/acpi/wakeup || echo "LID wake-up enable failed"
      echo enabled > /proc/acpi/wakeup || echo "SLPB wake-up enable failed"
    '';
    
    powerDownCommands = ''
      # Additional power savings before suspend
      echo 1 > /sys/module/snd_hda_intel/parameters/power_save || true
      echo auto > /sys/bus/pci/devices/0000:00:1f.6/power/control || true  # Ethernet
    '';
  };
  
  # ADDITION: Ensure systemd-logind has priority over other power managers
  systemd.extraConfig = ''
    [Login]
    HandleLidSwitch=suspend
    HandleLidSwitchDocked=suspend
    HandleLidSwitchExternalPower=suspend
  '';
  
  # Runtime power management for PCI devices
  services.udev.extraRules = ''
    # Enable runtime PM for PCI devices (aggressive power saving)
    ACTION=="add", SUBSYSTEM=="pci", ATTR{power/control}="auto"
    
    # Disable wake-up for Ethernet controller (reduce suspend power drain)
    ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x8086", ATTR{device}=="0x15bb", ATTR{power/wakeup}="disabled"
    
    # USB devices power management
    ACTION=="add", SUBSYSTEM=="usb", TEST=="power/control", ATTR{power/control}="auto"
  '';
}

