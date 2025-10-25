# modules/home/gnome/default.nix
# ==============================================================================
# GNOME autostart desktop entry for keyring fix
# ==============================================================================
{ config, lib, pkgs, ... }:

{
  xdg.configFile."autostart/gnome-keyring-fix.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=GNOME Keyring Fix
    Comment=Fix GNOME Keyring lag on startup
    Exec=gnome-kr-fix
    Terminal=false
    Hidden=false
    X-GNOME-Autostart-enabled=true
    X-GNOME-Autostart-Delay=3
    Categories=System;
    StartupNotify=false
  '';
}
