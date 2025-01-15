{ pkgs, config, ... }:
let
  colors = import ./colors.nix { inherit config; };
in
{
  imports = [
    (import ./settings.nix { inherit (colors) custom; })
    (import ./style.nix { inherit (colors) custom; })
    ./waybar.nix
  ];
}
