# modules/home/swaylock/default.nix
# ==============================================================================
# SwayLock Screen Locker Configuration
# Uses centralized Catppuccin-nix module for theming
# ==============================================================================
{ pkgs, lib, config, inputs, ... }:
let
  # Font ayarları
  fonts = {
    notifications = {
      family = "Hack Nerd Font";
    };
    sizes = {
      xl = 15;
    };
  };
in
{
  programs.swaylock = {
    enable = true;
    package = pkgs.swaylock-effects;
    
    # =============================================================================
    # Lock Screen Settings
    # =============================================================================
    settings = {
      # ---------------------------------------------------------------------------
      # Core Settings
      # ---------------------------------------------------------------------------
      clock = true;
      timestr = "%H:%M";
      datestr = "%d.%m.%Y";
      screenshots = true;
      ignore-empty-password = true;
      show-failed-attempts = true;
      
      # ---------------------------------------------------------------------------
      # Visual Effects
      # ---------------------------------------------------------------------------
      effect-blur = "8x5";
      effect-vignette = "0.4:0.4";
      effect-pixelate = "5";
      
      # ---------------------------------------------------------------------------
      # Indicator Configuration
      # ---------------------------------------------------------------------------
      indicator = true;
      indicator-radius = "100";
      indicator-thickness = "10";
      indicator-caps-lock = true;
      
      # ---------------------------------------------------------------------------
      # Font Settings
      # ---------------------------------------------------------------------------
      font = fonts.notifications.family;
      font-size = toString fonts.sizes.xl;
      
      # ---------------------------------------------------------------------------
      # Color Theme - Handled by centralized catppuccin module
      # Colors are automatically applied via catppuccin.swaylock.enable = true
      # ---------------------------------------------------------------------------
      # No manual color definitions needed!
      # Catppuccin-nix module handles all colors automatically based on:
      # - config.catppuccin.flavor (mocha/macchiato/frappe/latte)
      # - config.catppuccin.accent (mauve/blue/red/etc.)
    };
  };
}
