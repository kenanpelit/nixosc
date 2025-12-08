# modules/nixos/noctalia/default.nix
# ==============================================================================
# Noctalia shell integration for Hyprland/Sway/Niri.
# Registers the upstream Home Manager module and enables it for the primary user
# when `my.user.noctalia.enable` is set.
# ==============================================================================
{ config, lib, pkgs, inputs, ... }:
let
  cfg = config.my.user.noctalia or { enable = false; };
  user = config.my.user.name or "kenan";
  noctaliaPkg = inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default;
in {
  options.my.user.noctalia.enable = lib.mkEnableOption "Noctalia (Quickshell-based) shell";

  config = lib.mkIf cfg.enable {
    # Expose upstream HM module to the user's Home Manager evaluation
    home-manager.sharedModules = [ inputs.noctalia.homeModules.default ];

    # Enable Noctalia for the primary user
    home-manager.users.${user}.programs.noctalia-shell = {
      enable = true;
      package = noctaliaPkg;
      systemd.enable = true;
      # Basic tweaks; keep the rest at upstream defaults
      settings = {
        appLauncher.enableClipboardHistory = true;
        appLauncher.enableClipPreview = true;
      };
    };

    # Force icon theme for Noctalia/Qt lookups
    home-manager.users.${user}.systemd.user.services.noctalia-shell.Service.Environment = [
      "QT_ICON_THEME=a-candy-beauty-icon-theme"
      "XDG_ICON_THEME=a-candy-beauty-icon-theme"
    ];
  };
}
