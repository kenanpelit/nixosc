# modules/core/services/default.nix
# ==============================================================================
# Base System Services Configuration
# ==============================================================================
# This configuration manages core system services including:
# - Virtual filesystem support
# - SSD optimization
# - D-Bus configuration
# - Input device services
#
# Author: Kenan Pelit
# ==============================================================================

{ pkgs, ... }:
{
  services = {
    gvfs.enable = true;       # Virtual filesystem support
    fstrim.enable = true;     # SSD optimization service
    
    # D-Bus Configuration
    dbus = {
      enable = true;
      packages = [ pkgs.gcr ];  # GPG and encryption infrastructure
    };
    
    # Input Device Services
    touchegg.enable = false;    # Touchscreen gesture service
    
    # Ad Blocking
    hblock.enable = true;      # Enable hBlock for ad blocking

    # Firmware Update Service
    fwupd.enable = true;       # Enable firmware update daemon
  };
}
