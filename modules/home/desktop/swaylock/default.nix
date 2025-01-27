# modules/home/desktop/swaylock/default.nix
# ==============================================================================
# SwayLock Screen Locker Configuration
# ==============================================================================
{ pkgs, lib, config, inputs, ... }:
let
  colors = import ./../../../themes/default.nix;
  inherit (colors) kenp;
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
      font = colors.fonts.notifications.family;
      font-size = toString colors.fonts.sizes.xl;
      
      # ---------------------------------------------------------------------------
      # Color Theme
      # ---------------------------------------------------------------------------
      # Highlight Colors
      key-hl-color = "${kenp.blue}ff";          # Blue accent
      bs-hl-color = "${kenp.red}ff";            # Red
      
      # Ring Colors
      ring-color = "${kenp.crust}aa";            # Dark background
      ring-clear-color = "${kenp.yellow}ff";     # Orange
      ring-caps-lock-color = "${kenp.mauve}ff";  # Purple
      ring-ver-color = "${kenp.green}ff";        # Green
      ring-wrong-color = "${kenp.red}ff";        # Bright red
      
      # Interior Colors
      inside-color = "${kenp.crust}cc";          # Darkest
      inside-clear-color = "${kenp.crust}dd";
      inside-caps-lock-color = "${kenp.crust}dd";
      inside-ver-color = "${kenp.crust}dd";
      inside-wrong-color = "${kenp.crust}dd";
      
      # Text Colors
      text-color = "${kenp.text}ff";              # Light gray
      text-clear-color = "${kenp.yellow}ff";      # Orange
      text-caps-lock-color = "${kenp.mauve}ff";   # Purple
      text-ver-color = "${kenp.green}ff";         # Green
      text-wrong-color = "${kenp.red}ff";         # Red
      
      # Transparent UI Elements
      separator-color = "00000000";
      line-color = "00000000";
      line-clear-color = "00000000";
      line-caps-lock-color = "00000000";
      line-ver-color = "00000000";
      line-wrong-color = "00000000";
      
      # Layout Settings
      layout-bg-color = "${kenp.crust}cc";        # Darkest shade
      layout-text-color = "${kenp.text}ff";       # Light blue
    };
    
    # ---------------------------------------------------------------------------
    # Extra Settings (Varsa eklemek için yer bırakıldı)
    # ---------------------------------------------------------------------------
    # Özel eklemeler buraya yapılabilir.
  };
}
