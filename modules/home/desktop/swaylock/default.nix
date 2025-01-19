# modules/home/swaylock/default.nix
# ==============================================================================
# SwayLock Screen Locker Configuration
# ==============================================================================
{ pkgs, lib, config, inputs, ... }:
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
      effect-pixelate = 5;

      # ---------------------------------------------------------------------------
      # Indicator Configuration
      # ---------------------------------------------------------------------------
      indicator = true;
      indicator-radius = 100;
      indicator-thickness = 10;
      indicator-caps-lock = true;

      # ---------------------------------------------------------------------------
      # Font Settings
      # ---------------------------------------------------------------------------
      font = "Hack";
      font-size = 20;

      # ---------------------------------------------------------------------------
      # Color Theme (Tokyo Night)
      # ---------------------------------------------------------------------------
      # Highlight Colors
      key-hl-color = "7aa2f7ff";          # Blue accent
      bs-hl-color = "f7768eff";           # Red

      # Ring Colors
      ring-color = "1a1b26aa";            # Dark background
      ring-clear-color = "e0af68ff";      # Orange
      ring-caps-lock-color = "bb9af7ff";  # Purple
      ring-ver-color = "9ece6aff";        # Green
      ring-wrong-color = "db4b4bff";      # Bright red

      # Interior Colors
      inside-color = "16161ecc";          # Darkest Tokyo Night
      inside-clear-color = "16161edd";
      inside-caps-lock-color = "16161edd";
      inside-ver-color = "16161edd";
      inside-wrong-color = "16161edd";

      # Text Colors
      text-color = "a9b1d6ff";            # Light gray
      text-clear-color = "e0af68ff";      # Orange
      text-caps-lock-color = "bb9af7ff";  # Purple
      text-ver-color = "9ece6aff";        # Green
      text-wrong-color = "f7768eff";      # Red

      # Transparent UI Elements
      separator-color = "00000000";
      line-color = "00000000";
      line-clear-color = "00000000";
      line-caps-lock-color = "00000000";
      line-ver-color = "00000000";
      line-wrong-color = "00000000";

      # Layout Settings
      layout-bg-color = "16161ecc";       # Darkest shade
      layout-text-color = "c0caf5ff";     # Light blue
    };
  };
}
