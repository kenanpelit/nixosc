# modules/home/vivaldi/theme.nix
# ==============================================================================
# Vivaldi Catppuccin Theme Configuration
# ==============================================================================

{ config, pkgs, lib, ... }:

let
  # Pull from central Catppuccin config
  flavor = config.catppuccin.flavor or "mocha";
  accent = config.catppuccin.accent or "mauve";

  # Catppuccin Chrome Theme extension IDs
  catppuccinThemeIds = {
    mocha      = "bkkmolkhemgaeaeggcmfbghljjjoofoh";
    macchiato  = "cmpdlhmnmjhihmcfnigoememnffkimlk";
    frappe     = "olhelnoplefjdmncknfphenjclimckaf";
    latte      = "jhjnalhegpceacdhbplhnakmkdliaddd";
  };

  themeId = catppuccinThemeIds.${flavor};

  catppuccinColors = {
    mocha = {
      base = "#1e1e2e"; text = "#cdd6f4";
      blue = "#89b4fa"; mauve = "#cba6f7";
      red  = "#f38ba8"; green = "#a6e3a1";
      yellow = "#f9e2af"; peach = "#fab387";
    };
    macchiato = {
      base = "#24273a"; text = "#cad3f5";
      blue = "#8aadf4"; mauve = "#c6a0f6";
      red  = "#ed8796"; green = "#a6da95";
      yellow = "#eed49f"; peach = "#f5a97f";
    };
    frappe = {
      base = "#303446"; text = "#c6d0f5";
      blue = "#8caaee"; mauve = "#ca9ee6";
      red  = "#e78284"; green = "#a6d189";
      yellow = "#e5c890"; peach = "#ef9f76";
    };
    latte = {
      base = "#eff1f5"; text = "#4c4f69";
      blue = "#1e66f5"; mauve = "#8839ef";
      red  = "#d20f39"; green = "#40a02b";
      yellow = "#df8e1d"; peach = "#fe640b";
    };
  };

  colors = catppuccinColors.${flavor};

  customCSS = ''
    /* Catppuccin ${flavor} Custom Styles (Vivaldi) */
    :root {
      --catppuccin-base: ${colors.base};
      --catppuccin-text: ${colors.text};
      --catppuccin-accent: ${colors.${accent}};
    }

    @media (prefers-color-scheme: dark) {
      html, body {
        background-color: var(--catppuccin-base) !important;
        color: var(--catppuccin-text) !important;
      }
    }
  '';
in
{
  config = lib.mkIf (
    config.my.browser.vivaldi.enable
    && (config.my.browser.vivaldi.enableCatppuccinTheme or (config.catppuccin.enable or false))
    && config.my.browser.vivaldi.useChromiumWrapper
  ) {
    # Theme + helpers (through Chromium wrapper)
    programs.chromium.extensions = [
      { id = themeId; }                            # Catppuccin Theme
      { id = "eimadpbcbfnmbkopoojfekhnkhdbieeh"; } # Dark Reader
      { id = "clngdbkpkpeebahjckkjfobafhncgmne"; } # Stylus
    ];

    # Store custom CSS for Stylus
    home.file.".config/vivaldi/User Data/Stylus/catppuccin-${flavor}.css".text = customCSS;

    # Theming-related environment
    home.sessionVariables = {
      VIVALDI_ENABLE_DARK_MODE = "1";
      VIVALDI_DISABLE_FONT_SUBPIXEL_POSITIONING = "1";
    };
  };
}
