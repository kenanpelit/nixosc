# modules/home/rofi/default.nix
# ------------------------------------------------------------------------------
# Home Manager module for rofi.
# Exposes my.user options to install packages and write user config.
# Keeps per-user defaults centralized instead of scattered dotfiles.
# Adjust feature flags and templates in the module body below.
# ------------------------------------------------------------------------------

{ config, lib, pkgs, ... }:
let
  cfg = config.my.user.rofi;
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
  options.my.user.rofi = {
    enable = lib.mkEnableOption "Rofi application launcher";
  };

  config = lib.mkIf cfg.enable {
    # =============================================================================
    # Theme Configuration
    # =============================================================================
    xdg.configFile."rofi/theme.rasi".text = rofiTheme.theme;
  };
  
  imports = [
    ./config.nix   # Main configuration
  ];
}
