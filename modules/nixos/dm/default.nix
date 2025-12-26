# modules/nixos/dm/default.nix
# ==============================================================================
# NixOS display-manager/greeter wiring (e.g., greetd/lightdm settings).
# Centralize login UI toggles and session registration here.
# Keep DM choices consistent across hosts from this module.
# ==============================================================================

{ lib, config, options, ... }:

let
  cfg = config.my.display;
  dmsGreeterEnabled = config.my.greeter.dms.enable or false;
  hasCosmicDesktopManager =
    lib.hasAttrByPath [ "services" "desktopManager" "cosmic" "enable" ] options;
  hasCosmicGreeter =
    lib.hasAttrByPath [ "services" "displayManager" "cosmic-greeter" "enable" ] options;
in
{
  config = lib.mkIf cfg.enable (lib.mkMerge [
    {
      services.xserver.enable = true;

      services.displayManager.gdm = lib.mkIf (!dmsGreeterEnabled) {
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
        else if cfg.enableMangowc then "mango-optimized"
        else if cfg.enableGnome then "gnome"
        else if cfg.enableCosmic then "cosmic-optimized"
        else null;

      services.xserver.xkb.layout  = cfg.keyboard.layout;
      services.xserver.xkb.variant = cfg.keyboard.variant;
      services.xserver.xkb.options = lib.concatStringsSep "," cfg.keyboard.options;
    }

    (lib.mkIf (cfg.enableCosmic && hasCosmicDesktopManager) {
      services.desktopManager.cosmic.enable = true;
    })

    (lib.mkIf hasCosmicGreeter {
      # dms-greeter kullanıyoruz; COSMIC greeter'ı açmayalım.
      services.displayManager."cosmic-greeter".enable = lib.mkForce false;
    })
  ]);
}
