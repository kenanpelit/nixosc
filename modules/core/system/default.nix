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

{ ... }:
{
  imports = [
    ./boot
    ./hardware
    ./power
    ./base
  ];
}
