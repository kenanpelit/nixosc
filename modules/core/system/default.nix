# modules/core/system/default.nix
# ==============================================================================
# Base System Configuration
# ==============================================================================
{ self, pkgs, lib, inputs, ... }:
{
  imports = [ ];  # Home-manager import removed

  # =============================================================================
  # Localization Settings
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

  # =============================================================================
  # Keyboard Configuration
  # =============================================================================
  services.xserver.xkb = {
    layout = "tr";
    variant = "f";
    options = "ctrl:nocaps";  # Caps Lock as Ctrl
  };

  # Console Keymap
  console.keyMap = "trf";

  # =============================================================================
  # System Version
  # =============================================================================
  system.stateVersion = "24.11";  # Do not change this value
}
