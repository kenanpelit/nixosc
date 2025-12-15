# modules/home/btop/default.nix
# ==============================================================================
# Home module for btop resource monitor with theme defaults.
# Installs btop and sets user config via Home Manager.
# Tweak colors/behaviour here instead of editing btop.conf manually.
# ==============================================================================

{ pkgs, lib, config, ... }:
let
  cfg = config.my.user.btop;
in
{
  options.my.user.btop = {
    enable = lib.mkEnableOption "btop system monitor";
  };

  config = lib.mkIf cfg.enable {
    # =============================================================================
    # Program Configuration
    # =============================================================================
    programs.btop = {
      enable = true;
      settings = {
        color_theme = lib.mkDefault "TTY";  # FIXED: Added lib.mkDefault to allow Catppuccin override
        theme_background = false;
        update_ms = 500;
        rounded_corners = false;
      };
    };
  };
}
