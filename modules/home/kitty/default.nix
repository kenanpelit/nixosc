# modules/home/kitty/default.nix
# ==============================================================================
# Kitty Terminal Emulator Configuration
# ==============================================================================
{ pkgs, host, lib, ... }:

let
  # Tokyo Night Color Palette
  palette = {
    # Base colors
    bg = {
      primary = "#1a1b26";    # crust
      secondary = "#24283b";  # base  
      tertiary = "#1f2335";   # mantle
    };
    fg = {
      primary = "#c0caf5";    # text
      muted = "#565f89";      # surface2
      subtle = "#414868";     # surface1
    };
    accent = {
      purple = "#bb9af7";     # mauve
      cyan = "#7dcfff";       # sky
      yellow = "#e0af68";
      red = "#f7768e";
      green = "#9ece6a";
      blue = "#7aa2f7";
      pink = "#ff75a0";
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
      background = palette.bg.secondary;
      foreground = palette.fg.primary;
      selection_foreground = palette.bg.primary;
      selection_background = palette.accent.purple;
      
      cursor = palette.accent.purple;
      cursor_text_color = palette.bg.primary;
      url_color = palette.accent.cyan;
      
      # Window borders
      active_border_color = palette.accent.purple;
      inactive_border_color = palette.fg.subtle;
      bell_border_color = palette.accent.yellow;
      
      # Tab bar
      active_tab_foreground = palette.bg.primary;
      active_tab_background = palette.accent.purple;
      inactive_tab_foreground = palette.fg.primary;
      inactive_tab_background = palette.bg.primary;
      tab_bar_background = palette.bg.tertiary;
      
      # Marks
      mark1_foreground = palette.bg.primary;
      mark1_background = palette.accent.purple;
      mark2_foreground = palette.bg.primary;
      mark2_background = palette.accent.pink;
      mark3_foreground = palette.bg.primary;
      mark3_background = palette.accent.cyan;
      
      # ANSI Colors (0-15)
      color0 = palette.fg.subtle;      # black
      color1 = palette.accent.red;     # red
      color2 = palette.accent.green;   # green
      color3 = palette.accent.yellow;  # yellow
      color4 = palette.accent.blue;    # blue
      color5 = palette.accent.pink;    # magenta
      color6 = palette.accent.cyan;    # cyan
      color7 = palette.fg.primary;     # white
      color8 = palette.fg.muted;       # bright black
      color9 = palette.accent.red;     # bright red
      color10 = palette.accent.green;  # bright green
      color11 = palette.accent.yellow; # bright yellow
      color12 = palette.accent.blue;   # bright blue
      color13 = palette.accent.pink;   # bright magenta
      color14 = palette.accent.cyan;   # bright cyan
      color15 = "#ffffff";             # bright white
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
