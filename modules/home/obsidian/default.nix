# modules/home/obsidian/default.nix
# ==============================================================================
# Home module for Obsidian notes client.
# Installs the app and desktop entry; manage user settings centrally here.
# ==============================================================================

{ lib, config, ... }:
let
  cfg = config.my.user.obsidian;
in
{
  options.my.user.obsidian = {
    enable = lib.mkEnableOption "Obsidian configuration";
  };

  config = lib.mkIf cfg.enable {
  };
}
