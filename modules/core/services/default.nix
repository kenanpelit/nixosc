# modules/core/services/default.nix
# ==============================================================================
# Base System Services Configuration
# ==============================================================================
# This configuration manages core system services including:
# - Virtual filesystem support
# - SSD optimization
# - D-Bus configuration
# - Input device services
# - Bluetooth support
# - System maintenance
#
# Author: Kenan Pelit
# ==============================================================================
{ pkgs, ... }:
{

  services = {
    # Filesystem Services
    gvfs.enable = true;       # Virtual filesystem support
    fstrim.enable = true;     # SSD optimization service
    
    # D-Bus Configuration
    dbus = {
      enable = true;
      packages = with pkgs; [ 
        gcr                   # GPG and encryption infrastructure
        gnome-keyring         # Keyring support
      ];
    };
    
    # Bluetooth Management
    blueman.enable = true;    # Bluetooth management interface
    
    # Input Device Services
    touchegg.enable = false;  # Touchscreen gesture service (disabled)
    
    # System Security & Maintenance
    hblock.enable = true;     # Ad blocking service
    fwupd.enable = true;      # Firmware update daemon
    
    # Thumbnail Generation
    tumbler.enable = true;    # Thumbnail service for file managers
    
    # Print Support (optional - enable if needed)
    printing.enable = false;  # CUPS printing system
    avahi = {                 # Network discovery
      enable = false;         # Enable if you use network printers
      nssmdns4 = false;
    };
  };
  
  systemd.maskedServices = [
    "thinkfan-sleep.service"
    "thinkfan-wakeup.service"
  ];
}

