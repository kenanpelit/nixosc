# modules/home/anydesk/default.nix
# ==============================================================================
# Home module for AnyDesk remote desktop client.
# Installs the client and keeps user-level settings in one place.
# Adjust launch/desktop integration here instead of manual installs.
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
