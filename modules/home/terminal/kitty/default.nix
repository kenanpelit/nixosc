# modules/home/terminal/kitty/default.nix
# ==============================================================================
# Kitty Terminal Emülatör Konfigürasyonu
# ==============================================================================
{ pkgs, host, lib, ... }:  # lib parametresini ekleyin
let
  colors = import ./../../../themes/default.nix;
  kittyTheme = import ./theme.nix {
    inherit (colors) kenp effects fonts;
  };
in
{
  imports = [
    (import ./settings.nix {
      inherit kittyTheme colors;  # colors'ı ekleyin
      inherit lib;                # lib'i ekleyin
    })
  ];

  programs.kitty.enable = true;
}
