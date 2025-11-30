# modules/core/fonts/default.nix
# Fonts and fontconfig.

{ lib, config, pkgs, ... }:

let cfg = config.my.display;
in {
  config = lib.mkIf cfg.fonts.enable {
    fonts = {
      packages = [
        pkgs.noto-fonts
        pkgs.noto-fonts-cjk-sans
        pkgs.noto-fonts-color-emoji
        pkgs.nerd-fonts.fira-code
      ];
      fontconfig = lib.mkIf cfg.fonts.hiDpiOptimized {
        hinting.style = "full";
        antialias = true;
        subpixel.rgba = "rgb";
      };
    };
  };
}
