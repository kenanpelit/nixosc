# modules/home/btop/default.nix
# ==============================================================================
# Btop System Monitor Configuration
# ==============================================================================
{ pkgs, lib, ... }:
{
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
}
