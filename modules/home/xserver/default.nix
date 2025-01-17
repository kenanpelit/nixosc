# modules/home/xserver/default.nix
{ config, lib, pkgs, ... }:
{
  home.sessionVariables = {
    USERXSESSION = "$HOME/.cache/X11/xsession";
    USERXSESSIONRC = "$HOME/.cache/X11/xsessionrc";
    ALTUSERXSESSION = "$HOME/.cache/X11/Xsession";
    ERRFILE = "$HOME/.cache/X11/xsession-errors";
  };

  # Dizini otomatik oluşturmak için
  home.file.".cache/X11/.keep".text = "";
}

