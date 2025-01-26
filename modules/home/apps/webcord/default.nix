# modules/home/apps/discord/default.nix
{ pkgs, ... }:
let
  colors = import ./../../../themes/colors.nix;
  theme = colors.mkTheme {
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
  xdg.configFile."Vencord/themes/kenp.theme.css".text = theme.discord.css;
}

