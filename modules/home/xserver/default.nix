# modules/home/xserver/default.nix
{ config, lib, pkgs, ... }:
{
  systemd.user.sessionVariables = {
    USERXSESSION = "$HOME/.cache/X11/xsession";
    USERXSESSIONRC = "$HOME/.cache/X11/xsessionrc";
    ALTUSERXSESSION = "$HOME/.cache/X11/Xsession";
    ERRFILE = "$HOME/.cache/X11/xsession-errors";
  };

  # X11 dizinini oluştur
  home.file.".cache/X11/.keep".text = "";

  # Display manager'ın kullandığı scriptleri override et
  home.file.".xprofile".text = ''
    export USERXSESSION="$HOME/.cache/X11/xsession"
    export USERXSESSIONRC="$HOME/.cache/X11/xsessionrc"
    export ALTUSERXSESSION="$HOME/.cache/X11/Xsession"
    export ERRFILE="$HOME/.cache/X11/xsession-errors"
  '';
}
