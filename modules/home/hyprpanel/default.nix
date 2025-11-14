{ inputs, config, lib, pkgs, ... }:

with lib;

let
  cfg = config.programs.hyprpanel;
in
{
  options.programs.hyprpanel = {
    enable = mkEnableOption "Hyprpanel - A modern panel for Hyprland";

    package = mkOption {
      type = types.package;
      default = inputs.hyprpanel.packages.${pkgs.stdenv.hostPlatform.system}.default;
      defaultText = literalExpression "inputs.hyprpanel.packages.\${pkgs.stdenv.hostPlatform.system}.default";
      description = "The Hyprpanel package to use.";
    };

    systemd = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Whether to enable systemd integration for Hyprpanel.";
      };

      target = mkOption {
        type = types.str;
        default = "hyprland-session.target";
        description = "The systemd target to bind Hyprpanel to.";
      };
    };

    settings = mkOption {
      type = types.nullOr (types.attrsOf types.anything);
      default = null;
      example = literalExpression ''
        {
          layout = {
            bar.layouts = {
              "0" = {
                left = [ "dashboard" "workspaces" ];
                middle = [ "media" ];
                right = [ "volume" "systray" "notifications" ];
              };
            };
          };
          bar.launcher.autoDetectIcon = true;
          bar.workspaces.show_icons = true;
          theme.bar.transparent = true;
        }
      '';
      description = ''
        Configuration for Hyprpanel. See <https://hyprpanel.com/configuration/settings.html>
        for available options.
      '';
    };

    overrideConfig = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to override the existing configuration file.
        If false, only creates the config if it doesn't exist.
      '';
    };

    extraConfig = mkOption {
      type = types.lines;
      default = "";
      example = ''
        // Additional custom configuration
      '';
      description = "Extra configuration to append to the settings.";
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];

    # Config dosyasını oluştur
    xdg.configFile."ags/config.js" = mkIf (cfg.settings != null) {
      text = ''
        ${builtins.toJSON cfg.settings}
        ${cfg.extraConfig}
      '';
      force = cfg.overrideConfig;
    };

    # Systemd servisi
    systemd.user.services.hyprpanel = mkIf cfg.systemd.enable {
      Unit = {
        Description = "Hyprpanel - Modern panel for Hyprland";
        PartOf = [ "graphical-session.target" ];
        After = [ "graphical-session.target" ];
        ConditionEnvironment = "WAYLAND_DISPLAY";
      };

      Service = {
        ExecStart = "${cfg.package}/bin/hyprpanel";
        Restart = "on-failure";
        RestartSec = 3;
        Environment = [
          "PATH=${lib.makeBinPath [ pkgs.bash pkgs.coreutils ]}"
        ];
      };

      Install = {
        WantedBy = [ cfg.systemd.target ];
      };
    };

    # Hyprland entegrasyonu
    wayland.windowManager.hyprland.settings = mkIf config.wayland.windowManager.hyprland.enable {
      exec-once = mkIf (!cfg.systemd.enable) [
        "${cfg.package}/bin/hyprpanel"
      ];
    };
  };
}

