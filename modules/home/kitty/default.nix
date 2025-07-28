# modules/home/kitty/default.nix
# ==============================================================================
# Kitty Terminal Emulator Configuration - Catppuccin Mocha
# ==============================================================================
{ pkgs, host, lib, ... }:
let
  # Catppuccin Mocha Color Palette
  palette = {
    # Base colors - Mocha theme
    bg = {
      primary = "#1e1e2e";    # Mocha base
      secondary = "#313244";  # Mocha surface0
      tertiary = "#181825";   # Mocha mantle
    };
    fg = {
      primary = "#cdd6f4";    # Mocha text
      muted = "#6c7086";      # Mocha overlay0
      subtle = "#45475a";     # Mocha surface1
    };
    accent = {
      purple = "#cba6f7";     # Mocha mauve
      cyan = "#89dceb";       # Mocha sky
      yellow = "#f9e2af";     # Mocha yellow
      red = "#f38ba8";        # Mocha pink
      green = "#a6e3a1";      # Mocha green
      blue = "#89b4fa";       # Mocha blue
      pink = "#f5c2e7";       # Mocha pink
      orange = "#fab387";     # Mocha peach
      teal = "#94e2d5";       # Mocha teal
    };
  };
  
  # Typography configuration
  typography = {
    family = "Hack Nerd Font";
    size = 13.3;
    features = [ "liga" "calt" ];
  };
  
  # Performance settings
  performance = {
    repaint_delay = 10;
    input_delay = 3;
    scrollback_lines = 10000;
  };
  
  # Theme configuration for settings.nix
  kittyTheme = {
    colors = {
      background = palette.bg.primary;
      foreground = palette.fg.primary;
      selection_foreground = palette.bg.primary;
      selection_background = palette.accent.purple;
      
      cursor = palette.accent.teal;
      cursor_text_color = palette.bg.primary;
      url_color = palette.accent.blue;
      
      # Window borders
      active_border_color = palette.accent.purple;
      inactive_border_color = palette.fg.subtle;
      bell_border_color = palette.accent.yellow;
      
      # Tab bar - Mocha theme
      active_tab_foreground = palette.bg.primary;
      active_tab_background = palette.accent.purple;
      inactive_tab_foreground = palette.fg.primary;
      inactive_tab_background = palette.bg.secondary;
      tab_bar_background = palette.bg.primary;
      
      # Marks - Mocha colors
      mark1_foreground = palette.bg.primary;
      mark1_background = palette.accent.purple;
      mark2_foreground = palette.bg.primary;
      mark2_background = palette.accent.pink;
      mark3_foreground = palette.bg.primary;
      mark3_background = palette.accent.teal;
      
      # ANSI Colors (0-15) - Catppuccin Mocha
      color0 = palette.fg.subtle;        # black
      color1 = palette.accent.red;       # red
      color2 = palette.accent.green;     # green
      color3 = palette.accent.yellow;    # yellow
      color4 = palette.accent.blue;      # blue
      color5 = palette.accent.purple;    # magenta
      color6 = palette.accent.cyan;      # cyan
      color7 = palette.fg.primary;       # white
      color8 = palette.fg.muted;         # bright black
      color9 = palette.accent.red;       # bright red
      color10 = palette.accent.green;    # bright green
      color11 = palette.accent.yellow;   # bright yellow
      color12 = palette.accent.blue;     # bright blue
      color13 = palette.accent.purple;   # bright magenta
      color14 = palette.accent.cyan;     # bright cyan
      color15 = "#f5e0dc";               # bright white (rosewater)
    };
  };
in {
  imports = [
    (import ./settings.nix {
      inherit kittyTheme palette typography performance lib;
    })
  ];
  
  programs.kitty.enable = true;
}

