# modules/home/swaylock/default.nix
# ==============================================================================
# SwayLock Screen Locker Configuration
# ==============================================================================
{ pkgs, lib, config, inputs, ... }:
let
  # Tokyo Night tema renkleri
  colors = {
    crust = "#1a1b26";
    text = "#c0caf5";
    blue = "#7aa2f7";
    red = "#f7768e";
    yellow = "#e0af68";
    mauve = "#bb9af7";
    green = "#9ece6a";
  };

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
      # Color Theme
      # ---------------------------------------------------------------------------
      # Highlight Colors
      key-hl-color = "${colors.blue}ff";          # Blue accent
      bs-hl-color = "${colors.red}ff";            # Red
      
      # Ring Colors
      ring-color = "${colors.crust}aa";            # Dark background
      ring-clear-color = "${colors.yellow}ff";     # Orange
      ring-caps-lock-color = "${colors.mauve}ff";  # Purple
      ring-ver-color = "${colors.green}ff";        # Green
      ring-wrong-color = "${colors.red}ff";        # Bright red
      
      # Interior Colors
      inside-color = "${colors.crust}cc";          # Darkest
      inside-clear-color = "${colors.crust}dd";
      inside-caps-lock-color = "${colors.crust}dd";
      inside-ver-color = "${colors.crust}dd";
      inside-wrong-color = "${colors.crust}dd";
      
      # Text Colors
      text-color = "${colors.text}ff";              # Light gray
      text-clear-color = "${colors.yellow}ff";      # Orange
      text-caps-lock-color = "${colors.mauve}ff";   # Purple
      text-ver-color = "${colors.green}ff";         # Green
      text-wrong-color = "${colors.red}ff";         # Red
      
      # Transparent UI Elements
      separator-color = "00000000";
      line-color = "00000000";
      line-clear-color = "00000000";
      line-caps-lock-color = "00000000";
      line-ver-color = "00000000";
      line-wrong-color = "00000000";
      
      # Layout Settings
      layout-bg-color = "${colors.crust}cc";        # Darkest shade
      layout-text-color = "${colors.text}ff";       # Light blue
    };
    
    # ---------------------------------------------------------------------------
    # Extra Settings (Varsa eklemek için yer bırakıldı)
    # ---------------------------------------------------------------------------
    # Özel eklemeler buraya yapılabilir.
  };
}

