{ inputs, lib, config, pkgs, ... }:
let
  cfg = config.my.user.noctalia;
in
{
  imports = [ inputs.noctalia.homeModules.default ];

  options.my.user.noctalia = {
    enable = lib.mkEnableOption "Noctalia Shell";
  };

  config = lib.mkIf cfg.enable {
    programs.noctalia-shell = {
      enable = true;
      # Systemd service management
      systemd.enable = true; 

      settings = {
        bar = {
          density = "compact";
          position = "top";
          showCapsule = true;
          widgets = {
            left = [
              {
                id = "ControlCenter";
                useDistroLogo = true;
              }
              {
                id = "Workspace";
                labelMode = "none";
                hideUnoccupied = false;
              }
            ];
            center = [
              {
                id = "Clock";
                formatHorizontal = "HH:mm";
                useMonospacedFont = true;
              }
            ];
            right = [
              {
                id = "Tray";
              }
              {
                id = "Volume";
              }
              {
                id = "Battery";
              }
              {
                id = "WiFi";
              }
              {
                id = "Bluetooth";
              }
            ];
          };
        };
        general = {
          radiusRatio = 0.5;
        };
      };
    };
  };
}
