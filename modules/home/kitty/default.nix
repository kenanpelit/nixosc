# modules/home/kitty/default.nix
# ==============================================================================
# Kitty Terminal Emulator Configuration - Tokyo Night Moon
# ==============================================================================
{ pkgs, host, lib, ... }:
let
  # Tokyo Night Moon Color Palette
  palette = {
    # Base colors - Moon theme
    bg = {
      primary = "#222436";    # Moon background
      secondary = "#2f334d";  # Moon surface
      tertiary = "#1e2030";   # Moon darker
    };
    fg = {
      primary = "#c8d3f5";    # Moon text
      muted = "#636da6";      # Moon muted
      subtle = "#444a73";     # Moon subtle
    };
    accent = {
      purple = "#c099ff";     # Moon purple
      cyan = "#86e1fc";       # Moon cyan
      yellow = "#ffc777";     # Moon yellow
      red = "#ff757f";        # Moon red
      green = "#c3e88d";      # Moon green
      blue = "#82aaff";       # Moon blue
      pink = "#fca7ea";       # Moon pink
      orange = "#ff966c";     # Moon orange
      teal = "#4fd6be";       # Moon teal
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
      
      cursor = palette.accent.cyan;
      cursor_text_color = palette.bg.primary;
      url_color = palette.accent.cyan;
      
      # Window borders
      active_border_color = palette.accent.purple;
      inactive_border_color = palette.fg.subtle;
      bell_border_color = palette.accent.yellow;
      
      # Tab bar - Moon theme
      active_tab_foreground = palette.bg.primary;
      active_tab_background = palette.accent.cyan;
      inactive_tab_foreground = palette.fg.primary;
      inactive_tab_background = palette.bg.secondary;
      tab_bar_background = palette.bg.primary;
      
      # Marks - Moon colors
      mark1_foreground = palette.bg.primary;
      mark1_background = palette.accent.purple;
      mark2_foreground = palette.bg.primary;
      mark2_background = palette.accent.pink;
      mark3_foreground = palette.bg.primary;
      mark3_background = palette.accent.cyan;
      
      # ANSI Colors (0-15) - Tokyo Night Moon
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
      color15 = "#ffffff";               # bright white
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

