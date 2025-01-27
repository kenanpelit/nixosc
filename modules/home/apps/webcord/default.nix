# modules/home/apps/webcord/default.nix
{ pkgs, ... }:
let
  colors = import ./../../../themes/default.nix;
  discordTheme = import ./theme.nix {
    inherit (colors) kenp effects fonts;
  };
in {
  # =============================================================================
  # Package Installation
  # =============================================================================
  home.packages = with pkgs; [
    webcord-vencord
  ];
  # =============================================================================
  # Theme Configuration
  # =============================================================================
  xdg.configFile."Vencord/themes/kenp.theme.css".text = discordTheme.css;
}
