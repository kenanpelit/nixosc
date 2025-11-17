# modules/home/brave/theme.nix
# ==============================================================================
# Brave Browser Catppuccin Theme Configuration
# ==============================================================================
# This configuration manages Catppuccin theming for Brave browser including:
# - Dynamic theme extension based on central catppuccin config
# - Custom CSS injection for websites
# - Theme synchronization with system catppuccin settings
#
# Author: Kenan Pelit
# ==============================================================================
{ config, pkgs, lib, ... }:
let
  # Merkezi catppuccin konfigürasyonundan ayarları al
  flavor = config.catppuccin.flavor or "mocha";
  accent = config.catppuccin.accent or "mauve";

  # Catppuccin Chrome Theme extension IDs (flavor'a göre)
  catppuccinThemeIds = {
    mocha = "bkkmolkhemgaeaeggcmfbghljjjoofoh";        # Catppuccin Mocha
    macchiato = "cmpdlhmnmjhihmcfnigoememnffkimlk";    # Catppuccin Macchiato
    frappe = "olhelnoplefjdmncknfphenjclimckaf";        # Catppuccin Frappe
    latte = "jhjnalhegpceacdhbplhnakmkdliaddd";         # Catppuccin Latte
  };

  # Seçilen flavor için theme ID
  themeId = catppuccinThemeIds.${flavor};

  # Custom CSS for websites (Catppuccin colors)
  catppuccinColors = {
    mocha = {
      base = "#1e1e2e"; text = "#cdd6f4";
      blue = "#89b4fa"; mauve = "#cba6f7";
      red = "#f38ba8"; green = "#a6e3a1";
      yellow = "#f9e2af"; peach = "#fab387";
    };
    macchiato = {
      base = "#24273a"; text = "#cad3f5";
      blue = "#8aadf4"; mauve = "#c6a0f6";
      red = "#ed8796"; green = "#a6da95";
      yellow = "#eed49f"; peach = "#f5a97f";
    };
    frappe = {
      base = "#303446"; text = "#c6d0f5";
      blue = "#8caaee"; mauve = "#ca9ee6";
      red = "#e78284"; green = "#a6d189";
      yellow = "#e5c890"; peach = "#ef9f76";
    };
    latte = {
      base = "#eff1f5"; text = "#4c4f69";
      blue = "#1e66f5"; mauve = "#8839ef";
      red = "#d20f39"; green = "#40a02b";
      yellow = "#df8e1d"; peach = "#fe640b";
    };
  };

  colors = catppuccinColors.${flavor};

  # Custom CSS for injection
  customCSS = ''
    /* Catppuccin ${flavor} Custom Styles */
    :root {
      --catppuccin-base: ${colors.base};
      --catppuccin-text: ${colors.text};
      --catppuccin-accent: ${colors.${accent}};
    }

    /* Dark websites theme override */
    @media (prefers-color-scheme: dark) {
      html, body {
        background-color: var(--catppuccin-base) !important;
        color: var(--catppuccin-text) !important;
      }
    }
  '';
in
{
  config = lib.mkIf config.my.browser.brave.enable {
    # ==========================================================================
    # Catppuccin Theme Extension - Extend existing extensions
    # ==========================================================================
    programs.chromium.extensions = [
      # Catppuccin theme (dinamik olarak seçilen flavor)
      { id = themeId; }

      # Dark Reader (websites için)
      { id = "eimadpbcbfnmbkopoojfekhnkhdbieeh"; }

      # Stylus (custom CSS injection için)
      { id = "clngdbkpkpeebahjckkjfobafhncgmne"; }
    ];

    # ==========================================================================
    # Custom Stylus CSS
    # ==========================================================================
    home.file.".config/BraveSoftware/Brave-Browser/User Data/Stylus/catppuccin-${flavor}.css".text = customCSS;

    # ==========================================================================
    # Theme-specific Session Variables
    # ==========================================================================
    home.sessionVariables = {
      # Enable dark mode detection
      BRAVE_ENABLE_DARK_MODE = "1";
    };

  };
}
