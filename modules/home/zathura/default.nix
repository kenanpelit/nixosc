# modules/home/zathura/default.nix
# ==============================================================================
# Zathura PDF Reader Configuration
# ==============================================================================
{ config, lib, ... }:
with lib;
let
  cfg = config.my.programs.zathura;
in
{
  # =============================================================================
  # Module Options
  # =============================================================================
  options.my.programs.zathura.enable = mkEnableOption "zathura";

  # =============================================================================
  # Module Implementation
  # =============================================================================
  config = mkIf cfg.enable {
    home-manager.users.moritz.programs.zathura = {
      enable = true;

      # ---------------------------------------------------------------------------
      # Core Settings
      # ---------------------------------------------------------------------------
      options = {
        recolor = true;
        adjust-open = "width";
        font = "Jetbrains Mono 9";
        selection-clipboard = "clipboard";
      };
    };
  };
}
