# modules/home/desktop/walker/default.nix
{ config, lib, pkgs, ... }:

with lib;
let
  cfg = config.programs.walker;
in {
  options.programs.walker = {
    enable = mkEnableOption "walker application launcher";
    settings = mkOption {
      type = types.attrs;
      default = {};
      description = "Walker yapılandırması";
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.walker ];
    xdg.configFile."walker/config.toml".text = generators.toTOML {} cfg.settings;
  };
}
