# modules/core/fonts/default.nix
# ==============================================================================
# Font Stack & Rendering Defaults
# ==============================================================================
# Centralizes font packages, fontconfig defaults, Maple Mono NF as the primary
# system font (UI + mono), HiDPI tuning, and disables embedded bitmaps for
# cleaner rendering.
# ==============================================================================

{ lib, config, pkgs, ... }:

let
  inherit (lib) mkOption mkEnableOption mkIf types;
  cfg = config.my.display;
  mapleFonts = import ../../home/maple { inherit lib pkgs; };
in {
  options.my.display.fonts = {
    enable = mkEnableOption "system font stack (packages + fontconfig)";

    hiDpiOptimized = mkOption {
      type = types.bool;
      default = true;
      description = ''
        If true, fontconfig is tuned for HiDPI/modern LCD panels:
          - subpixel RGB
          - slight hinting
          - antialias enabled
      '';
    };
  };

  config = mkIf cfg.fonts.enable {
    fonts = {
      packages = with pkgs; [
        # Primary (UI + mono) from local Maple 7.8 set
        #mapleFonts."NF"
        #mapleFonts."NF-CN-unhinted"
        #mapleFonts.truetype

        # Extra symbols / light fallbacks
        nerd-fonts.symbols-only
        monaspace
        nerd-fonts.monaspace
        nerd-fonts.hack
        fira-code
        fira-code-symbols

        # Emoji & icons
        noto-fonts-color-emoji
        font-awesome
        material-design-icons

        # General UI / document fonts (minimal, kept for compatibility)
        liberation_ttf
        dejavu_fonts
        noto-fonts
        noto-fonts-cjk-sans
        noto-fonts-cjk-serif
        roboto
        ubuntu-classic
        open-sans
      ];

      enableDefaultPackages = true;
      fontDir.enable = true;

      fontconfig = {
        defaultFonts = {
          monospace = [
            # Primary everywhere
            "Maple Mono NF"
            "Maple Mono"
            "Maple Mono NF CN"

            # Minimal fallbacks
            "Monaspace Neon"
            "Hack Nerd Font"
            "Hack"
            "FiraCode Nerd Font"
            "Noto Color Emoji"
          ];

          emoji = [ "Noto Color Emoji" ];

          serif = [
            "Maple Mono NF"
            "Maple Mono"
            "Liberation Serif"
            "Noto Serif"
            "Noto Serif CJK SC"
            "DejaVu Serif"
          ];

          sansSerif = [
            "Maple Mono NF"
            "Maple Mono"
            "Noto Sans"
            "Noto Sans CJK SC"
            "Liberation Sans"
            "DejaVu Sans"
          ];
        };

        subpixel = mkIf cfg.fonts.hiDpiOptimized {
          rgba      = "rgb";
          lcdfilter = "default";
        };

        hinting = {
          enable   = true;
          autohint = false;
          style    = if cfg.fonts.hiDpiOptimized then "slight" else "medium";
        };

        antialias = true;
        useEmbeddedBitmaps = false;
        # Force emoji fallback into Inter/Fira
        localConf = ''
          <?xml version="1.0"?>
          <!DOCTYPE fontconfig SYSTEM "fonts.dtd">
          <fontconfig>
            <alias>
              <family>emoji</family>
              <prefer>
                <family>Noto Color Emoji</family>
                <family>Twitter Color Emoji</family>
              </prefer>
            </alias>
            <alias>
              <family>Inter</family>
              <prefer><family>Noto Color Emoji</family></prefer>
            </alias>
            <alias>
              <family>Fira Code</family>
              <prefer><family>Noto Color Emoji</family></prefer>
            </alias>
          </fontconfig>
        '';
      };
    };

    environment.variables = {
      FREETYPE_PROPERTIES = "truetype:interpreter-version=40";
    };
  };
}
