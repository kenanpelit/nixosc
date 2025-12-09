# modules/home/xserver/default.nix
# ------------------------------------------------------------------------------
# Home Manager module for xserver.
# Exposes my.user options to install packages and write user config.
# Keeps per-user defaults centralized instead of scattered dotfiles.
# Adjust feature flags and templates in the module body below.
# ------------------------------------------------------------------------------

{ config, lib, pkgs, ... }:
let
  cfg = config.my.user.xserver;
in
{
  options.my.user.xserver = {
    enable = lib.mkEnableOption "X11/Xwayland session variables";
  };

  config = lib.mkIf cfg.enable {
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
  };
}
