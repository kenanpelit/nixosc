# modules/home/xserver/default.nix
# ==============================================================================
# X11 / Xwayland Session Environment (User-level)
# ==============================================================================
# Purpose:
#   - Provide user-session environment tweaks for X11 / Xwayland clients.
#   - Mainly used to set XDG variables and compatibility flags from home-manager.
# Notes:
#   - System-level X server and Xwayland config live in core/display.
#   - This module focuses on per-user session variables.
# ==============================================================================
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
