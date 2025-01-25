# modules/core/media/bluetooth/default.nix
# ==============================================================================
# Bluetooth Configuration
# ==============================================================================
# This configuration manages Bluetooth functionality including:
# - Bluetooth device support
# - Auto-start behavior
# - Bluetooth management interface
#
# Author: Kenan Pelit
# ==============================================================================

{ ... }:
{
  hardware.bluetooth = {
    enable = true;        # Enable Bluetooth support
    powerOnBoot = true;   # Auto-start on boot
  };
  
  services.blueman.enable = true;  # Bluetooth management interface
}
