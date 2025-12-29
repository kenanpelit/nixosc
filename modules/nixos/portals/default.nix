# modules/nixos/portals/default.nix
# ==============================================================================
# NixOS XDG portal selection (desktop/flatpak integration).
# Centralize portal backends to keep file pickers/screenshare consistent.
# Tweak portal providers here instead of per-session overrides.
# ==============================================================================

{ pkgs, lib, inputs, config, ... }:

let
  cfg = config.my.display;
  flatpakEnabled = config.services.flatpak.enable or false;
  hyprPortalPkg =
    inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland;
  cosmicPortalPkg = pkgs."xdg-desktop-portal-cosmic" or null;
  cosmicPortalEnabled = (cfg.enableCosmic or false) && cosmicPortalPkg != null;
in
{
  config = lib.mkIf (cfg.enable || flatpakEnabled) {
    # Required when Home Manager installs portals via user packages
    environment.pathsToLink = [
      "/share/applications"
      "/share/xdg-desktop-portal"
    ];

    xdg.portal = {
      enable = true;
      extraPortals =
        (lib.optional cfg.enableHyprland hyprPortalPkg)
        ++ (lib.optional cosmicPortalEnabled cosmicPortalPkg)
        ++ (lib.optional ((cfg.enableMangowc or false) || cfg.enableNiri) pkgs.xdg-desktop-portal-wlr)
        ++ [ 
          pkgs.xdg-desktop-portal-gtk 
          pkgs.xdg-desktop-portal-gnome
        ];
      # Pick portal backends per-session to avoid "wrong compositor portal"
      # when multiple WMs are installed on the same host.
      #
      # Keys here match `DesktopNames` / XDG_CURRENT_DESKTOP values from the
      # session .desktop files (see `modules/nixos/sessions`).
      config = lib.mkMerge [
        {
          common.default = [ "gtk" ];

          # Hyprland sessions (upstream often sets "Hyprland", but keep a
          # lowercase alias to be resilient across greeters/wrappers).
          Hyprland.default = [ "hyprland" "gtk" ];
          hyprland.default = [ "hyprland" "gtk" ];

          # Niri: rely on wlr portal for screencast/screenshot protocols, and gtk
          # for file picker.
          niri = {
            default = [ "wlr" "gtk" ];
            # The upstream `wlr.portal` doesn't list `UseIn=niri`, so we must
            # explicitly bind these interfaces or ScreenCast/Screenshot won't be
            # exposed at all (browser will only offer "tab share").
            "org.freedesktop.impl.portal.ScreenCast" = [ "wlr" ];
            "org.freedesktop.impl.portal.Screenshot" = [ "wlr" ];
          };

          # GNOME session.
          GNOME.default = [ "gnome" "gtk" ];
        }
        (lib.mkIf (cfg.enableMangowc or false) {
          # Mango's upstream module sets this to "gtk". Force wlr first so
          # screencast/screenshot portals work reliably under dwl-based sessions.
          mango.default = lib.mkForce "wlr;gtk";
          mango."org.freedesktop.impl.portal.ScreenCast" = [ "wlr" ];
          mango."org.freedesktop.impl.portal.Screenshot" = [ "wlr" ];
        })
        (lib.mkIf cosmicPortalEnabled {
          COSMIC.default = [ "cosmic" "gtk" ];
          cosmic.default = [ "cosmic" "gtk" ];
        })
      ];
    };
  };
}
