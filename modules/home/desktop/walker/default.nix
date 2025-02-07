# modules/home/desktop/walker/default.nix
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.programs.walker;
in {
  options.programs.walker = {
    enable = mkEnableOption "walker application launcher";

    package = mkOption {
      type = types.package;
      default = pkgs.walker;
      defaultText = literalExpression "pkgs.walker";
      description = "The walker package to use.";
    };

    settings = mkOption {
      type = types.attrs;
      default = {};
      description = "Configuration for walker.";
      example = literalExpression ''
        {
          theme = "nord";
          width = 800;
          height = 500;
        }
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];

    xdg.configFile."walker/config.toml".text = generators.toTOML {} cfg.settings;
  };
}

