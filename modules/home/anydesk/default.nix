{ config, pkgs, ... }:

let
  run-anydesk = pkgs.writeShellScriptBin "run-anydesk" ''
    # GTK teması ve diğer tema ayarları ile birlikte çalıştır
    export GTK_THEME="Catppuccin-Mocha-Blue-Standard"
    export QT_STYLE_OVERRIDE="kvantum"
    export GDK_BACKEND=x11
    anydesk "$@"
  '';
in
{
  home.packages = with pkgs; [
    anydesk
    run-anydesk
  ];

  xdg.desktopEntries.anydesk = {
    name = "RunAnyDesk";
    exec = "run-anydesk %u";
    icon = "anydesk";
    terminal = false;
    type = "Application";
    categories = [ "Network" "RemoteAccess" ];
    mimeType = [ "x-scheme-handler/anydesk" ];
  };
}
