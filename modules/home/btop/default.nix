# modules/home/btop/default.nix
# ==============================================================================
# Home Manager module for btop.
# Exposes my.user options to install packages and write user config.
# Keeps per-user defaults centralized instead of scattered dotfiles.
# Adjust feature flags and templates in the module body below.
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
