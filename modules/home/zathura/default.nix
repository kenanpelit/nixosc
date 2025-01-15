{ config
, lib
, ...
}:

with lib;
let
  cfg = config.my.programs.zathura;
in
{
  options.my.programs.zathura.enable = mkEnableOption "zathura";

  config = mkIf cfg.enable {
    home-manager.users.moritz.programs.zathura = {
      enable = true;
      options = {
        recolor = true;
        adjust-open = "width";
        font = "Jetbrains Mono 9";
        selection-clipboard = "clipboard";
      };
    };
  };
}

