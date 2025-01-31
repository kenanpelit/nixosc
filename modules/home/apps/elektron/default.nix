# modules/home/electron/default.nix
{ config, lib, pkgs, ... }:

with lib;
let
  cfg = config.modules.home.electron;
in {
  options.modules.home.electron = {
    enable = mkEnableOption "electron module";
    
    package = mkOption {
      type = types.package;
      default = pkgs.electron;  # En son kararlı sürüm (33.3.1)
      description = "Electron paketi";
    };
    
    apps = mkOption {
      type = types.attrsOf (types.submodule {
        options = {
          enable = mkEnableOption "electron app";
          package = mkOption {
            type = types.package;
            description = "Electron uygulaması paketi";
          };
          useWayland = mkOption {
            type = types.bool;
            default = true;
            description = "Wayland desteğini etkinleştir";
          };
        };
      });
      default = {};
      description = "Electron tabanlı uygulamalar";
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ] 
      ++ (mapAttrsToList (name: app: app.package) 
          (filterAttrs (name: app: app.enable) cfg.apps));
    
    # Electron uygulamaları için Wayland desteği
    xdg.configFile = mkMerge (mapAttrsToList (name: app:
      mkIf (app.enable && app.useWayland) {
        "${name}/electron-flags.conf".text = ''
          --enable-features=UseOzonePlatform,WaylandWindowDecorations
          --ozone-platform=wayland
        '';
      }
    ) cfg.apps);
  };
}
