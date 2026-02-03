# modules/nixos/fonts/default.nix
# ==============================================================================
# NixOS fonts bundle: font packages, rendering tweaks, and fallbacks.
# Configure typographic defaults once for every host here.
# Keep font policy centralized to avoid per-host drift.
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
      default = false; # Default to FALSE for 2K (Standard DPI needs subpixel)
      description = ''
        If true, fontconfig is tuned for HiDPI/Retina (4K+) panels:
          - grayscale antialiasing (no subpixel)
        If false (default for 2K/FHD), we use standard subpixel rendering:
          - rgb subpixel (sharper on standard screens)
          - slight hinting
          - lcddefault filter
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
            "Noto Color Emoji"
          ];

          sansSerif = [
            "Maple Mono NF"
            "Maple Mono"
            "Noto Sans"
            "Noto Sans CJK SC"
            "Liberation Sans"
            "DejaVu Sans"
            "Noto Color Emoji"
          ];
        };

        # 2K/Standard Monitor Optimization (Gold Standard)
        subpixel = {
          rgba = if cfg.fonts.hiDpiOptimized then "none" else "rgb";
          lcdfilter = if cfg.fonts.hiDpiOptimized then "none" else "lcddefault";
        };

        hinting = {
          enable   = true;
          autohint = false;
          style    = "slight"; # Slight is best for modern fonts on both 2K and 4K
        };

        antialias = true;
        useEmbeddedBitmaps = false;
        
        # Force emoji fallback into Inter/Fira/Maple
        localConf = ''
          <?xml version="1.0"?>
          <!DOCTYPE fontconfig SYSTEM "fonts.dtd">
          <fontconfig>
            <!-- Prefer Noto, explicitly reject Twitter Color Emoji -->
            <rejectfont>
              <pattern>
                <patelt name="family">
                  <string>Twitter Color Emoji</string>
                </patelt>
              </pattern>
            </rejectfont>

            <!-- Generic Emoji Alias -->
            <alias>
              <family>emoji</family>
              <prefer>
                <family>Noto Color Emoji</family>
                <family>Twitter Color Emoji</family>
              </prefer>
            </alias>

            <!-- Specific Font Fallbacks -->
            <alias>
              <family>Inter</family>
              <prefer><family>Noto Color Emoji</family></prefer>
            </alias>
            <alias>
              <family>Fira Code</family>
              <prefer><family>Noto Color Emoji</family></prefer>
            </alias>
            <alias>
              <family>Maple Mono NF</family>
              <prefer><family>Noto Color Emoji</family></prefer>
            </alias>
          </fontconfig>
        '';
      };
    };

    environment.variables = {
      # Version 40 is standard for Arch/CachyOS (sharper)
      FREETYPE_PROPERTIES = "truetype:interpreter-version=40";
    };
  };
}
