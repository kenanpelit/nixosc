# modules/home/terminal/kitty/default.nix
# ==============================================================================
# Kitty Terminal Emülatör Konfigürasyonu
# ==============================================================================
{ pkgs, host, lib, ... }:
let
  # Tokyo Night tema renkleri
  colors = {
    base = "#24283b";
    crust = "#1a1b26";
    mantle = "#1f2335";
    text = "#c0caf5";
    surface1 = "#414868";
    surface2 = "#565f89";
    mauve = "#bb9af7";
    sky = "#7dcfff";
    yellow = "#e0af68";
    red = "#f7768e";
    green = "#9ece6a";
    blue = "#7aa2f7";
    pink = "#ff75a0";
  };

  # Font ayarları
  fonts = {
    terminal = {
      family = "Hack Nerd Font";
    };
  };

  # Kitty tema konfigürasyonu
  kittyTheme = {
    colors = {
      background = colors.base;
      foreground = colors.text;
      selection_foreground = colors.crust;
      selection_background = colors.mauve;
      
      cursor = colors.mauve;
      cursor_text_color = colors.crust;
      
      url_color = colors.sky;
      
      # Window borders
      active_border_color = colors.mauve;
      inactive_border_color = colors.surface1;
      bell_border_color = colors.yellow;
      
      # Tab bar
      active_tab_foreground = colors.crust;
      active_tab_background = colors.mauve;
      inactive_tab_foreground = colors.text;
      inactive_tab_background = colors.crust;
      tab_bar_background = colors.mantle;
      
      # Marks
      mark1_foreground = colors.crust;
      mark1_background = colors.mauve;
      mark2_foreground = colors.crust;
      mark2_background = colors.pink;
      mark3_foreground = colors.crust;
      mark3_background = colors.sky;
      
      # Standard colors
      color0 = colors.surface1;   # Black
      color8 = colors.surface2;   # Bright Black
      color1 = colors.red;        # Red
      color9 = colors.red;        # Bright Red
      color2 = colors.green;      # Green
      color10 = colors.green;     # Bright Green
      color3 = colors.yellow;     # Yellow
      color11 = colors.yellow;    # Bright Yellow
      color4 = colors.blue;       # Blue 
      color12 = colors.blue;      # Bright Blue
      color5 = colors.pink;       # Magenta
      color13 = colors.pink;      # Bright Magenta
      color6 = colors.sky;        # Cyan
      color14 = colors.sky;       # Bright Cyan
      color7 = colors.text;       # White
      color15 = "#ffffff";        # Bright White
    };
  };
in
{
  imports = [
    (import ./settings.nix {
      inherit kittyTheme colors fonts lib;
    })
  ];
  
  programs.kitty.enable = true;
}

