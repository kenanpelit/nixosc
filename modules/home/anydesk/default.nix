# modules/home/anydesk/default.nix
# ==============================================================================
# Home Manager module for anydesk.
# Exposes my.user options to install packages and write user config.
# Keeps per-user defaults centralized instead of scattered dotfiles.
# Adjust feature flags and templates in the module body below.
# ==============================================================================

{ config, pkgs, lib, ... }:
let
  cfg = config.my.user.anydesk;
  # =============================================================================
  # Custom Script Configuration
  # =============================================================================
  run-anydesk = pkgs.writeShellScriptBin "run-anydesk" ''
    # GTK teması ve diğer tema ayarları ile birlikte çalıştır
    export GTK_THEME="Catppuccin-Mocha-Blue-Standard"
    export QT_STYLE_OVERRIDE="kvantum"
    export GDK_BACKEND=x11
    anydesk "$@"
  '';
in
{
  options.my.user.anydesk = {
    enable = lib.mkEnableOption "AnyDesk remote desktop";
  };

  config = lib.mkIf cfg.enable {
    # =============================================================================
    # Package Installation
    # =============================================================================
    home.packages = [
      run-anydesk
    ];

    # =============================================================================
    # Desktop Entry Configuration
    # =============================================================================
    xdg.desktopEntries.anydesk = {
      name = "RunAnyDesk";
      exec = "run-anydesk %u";
      icon = "anydesk";
      terminal = false;
      type = "Application";
      categories = [ "Network" "RemoteAccess" ];
      mimeType = [ "x-scheme-handler/anydesk" ];
    };
  };
}
