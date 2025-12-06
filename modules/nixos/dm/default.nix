# modules/core/dm/default.nix
# ==============================================================================
# Display Manager Configuration
# ==============================================================================
# Configures GDM (GNOME Display Manager) and session handling.
# - Enables GDM (Wayland mode)
# - Manages desktop environment enablement (GNOME, etc.)
# - Configures auto-login settings
# - Sets the default session based on enabled DEs
# - Applies keyboard layout settings to XServer
#
# ==============================================================================

{ lib, config, ... }:

let
  cfg = config.my.display;
in
{
  config = lib.mkIf cfg.enable {
    services.xserver.enable = true;
    services.displayManager.gdm = {
      enable = true;
      wayland = true;
    };
    services.desktopManager.gnome.enable = cfg.enableGnome;
    services.displayManager.autoLogin = {
      enable = cfg.autoLogin.enable;
      user   = cfg.autoLogin.user or null;
    };
    services.displayManager.defaultSession =
      if cfg.defaultSession != null then cfg.defaultSession
      else if cfg.enableHyprland then "hyprland-optimized"
      else if cfg.enableGnome then "gnome"
      else null;

    services.xserver.xkb.layout  = cfg.keyboard.layout;
    services.xserver.xkb.variant = cfg.keyboard.variant;
    services.xserver.xkb.options = lib.concatStringsSep "," cfg.keyboard.options;
  };
}
