{ pkgs, ... }:
let
  colors = import ./../../../themes/colors.nix;
  theme = colors.mkTheme {
    inherit (colors) mocha effects fonts;
  };
in
{
  home.packages = with pkgs; [
    webcord-vencord
  ];

  xdg.configFile."Vencord/themes/mocha.theme.css".text = theme.discord.css;
}
