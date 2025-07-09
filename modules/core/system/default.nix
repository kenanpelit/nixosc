# modules/core/system/default.nix
# ==============================================================================
# Base System Configuration
# ==============================================================================
# This configuration manages basic system settings including:
# - Timezone configuration
# - Locale settings
# - Keyboard layout
# - System version
#
# Author: Kenan Pelit
# ==============================================================================

{ ... }:
{
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

  # System Version
  system.stateVersion = "25.11";
}
