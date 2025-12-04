# modules/home/anydesk/default.nix
# ==============================================================================
# AnyDesk Remote Desktop Configuration
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
