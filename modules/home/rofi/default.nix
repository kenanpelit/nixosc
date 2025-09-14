# modules/home/rofi/default.nix
# ==============================================================================
# Rofi Configuration - Catppuccin Dynamic Theme
# ==============================================================================
{ config, lib, pkgs, ... }:
let
  # Catppuccin modülünden otomatik renk alımı
  inherit (config.catppuccin) sources;
  
  # Palette JSON'dan renkler
  colors = (lib.importJSON "${sources.palette}/palette.json").${config.catppuccin.flavor}.colors;
  
  # Rofi tema CSS'i
  rofiTheme = {
    theme = ''
      * {
        bg-col: ${colors.crust.hex};
        bg-col-light: ${colors.base.hex};
        border-col: ${colors.surface1.hex};
        selected-col: ${colors.surface0.hex};
        green: ${colors.mauve.hex};           // Ana vurgu rengi - otomatik catppuccin palette
        fg-col: ${colors.text.hex};
        fg-col2: ${colors.subtext1.hex};
        grey: ${colors.surface2.hex};
        highlight: ${colors.lavender.hex};    // Highlight için açık mor - otomatik palette
        
        /* Ekstra Catppuccin renkleri - otomatik palette */
        mauve: ${colors.mauve.hex};
        lavender: ${colors.lavender.hex};
        sapphire: ${colors.sapphire.hex};
        accent: ${colors.mauve.hex};
        accent-light: ${colors.lavender.hex};
        accent-dark: ${colors.mauve.hex};
      }
    '';
  };
in
{
  # =============================================================================
  # Module Imports
  # =============================================================================
  imports = [
    ./config.nix   # Main configuration
  ];
  
  # =============================================================================
  # Package Installation
  # =============================================================================
  home.packages = (with pkgs; [ rofi ]);
  
  # =============================================================================
  # Theme Configuration
  # =============================================================================
  xdg.configFile."rofi/theme.rasi".text = rofiTheme.theme;
}

