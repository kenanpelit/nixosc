# modules/core/fonts/default.nix
# ==============================================================================
# Font Stack & Rendering Defaults
# ==============================================================================
# Centralizes font packages, fontconfig defaults, Inter as primary system font
# (Maple Mono retained as a fallback), HiDPI tuning, and disables embedded
# bitmaps for cleaner rendering.
# ==============================================================================

{ lib, config, pkgs, ... }:

let
  inherit (lib) mkOption mkEnableOption mkIf types;
  cfg = config.my.display;
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
        # Primary UI font
        inter

        # Primary monospace fallback set
        maple-mono.NF
        maple-mono.NF-CN-unhinted
        maple-mono.truetype

        # Alternates / fallbacks
        monaspace
        nerd-fonts.monaspace       # NF-patched Monaspace for icons
        nerd-fonts.symbols-only    # Extra NF symbols fallback
        nerd-fonts.hack
        cascadia-code
        fira-code
        fira-code-symbols
        jetbrains-mono
        source-code-pro

        # Emoji & icons
        noto-fonts-color-emoji
        font-awesome
        material-design-icons

        # General UI / document fonts
        liberation_ttf
        dejavu_fonts
        noto-fonts
        noto-fonts-cjk-sans
        noto-fonts-cjk-serif
        inter
        roboto
        ubuntu-classic
        open-sans
      ];

      enableDefaultPackages = true;
      fontDir.enable = true;

      fontconfig = {
        defaultFonts = {
          monospace = [
            # Primary system font (also for mono to force consistency)
            "Inter"
            "Inter Variable"

            # Maple as preferred mono fallback
            "Maple Mono NF"
            "Maple Mono"
            "Maple Mono NF CN"

            # Additional fallbacks
            "Monaspace Neon"
            "JetBrainsMono Nerd Font"
            "JetBrains Mono"
            "Hack Nerd Font"
            "Hack"
            "FiraCode Nerd Font"
            "Noto Color Emoji"
          ];

          emoji = [ "Noto Color Emoji" ];

          serif = [
            "Liberation Serif"
            "Noto Serif"
            "Noto Serif CJK SC"
            "DejaVu Serif"
          ];

          sansSerif = [
            "Liberation Sans"
            "Inter"
            "Noto Sans"
            "Noto Sans CJK SC"
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
      };
    };

    environment.variables = {
      FREETYPE_PROPERTIES = "truetype:interpreter-version=40";
    };
  };
}
