# modules/home/gnupg/gpgunlock.nix
# ==============================================================================
# GPG Auto-Unlock Service
# ==============================================================================
{ config, lib, pkgs, username, ... }:
{
  systemd.user.services.gpg-unlock = {
    Unit = {
      Description = "Unlock GPG key on login";
      After = [ "graphical-session.target" "gpg-agent.service" ];
      PartOf = [ "graphical-session.target" ];
      Requires = [ "gpg-agent.service" ];
    };

    Service = {
      Type = "oneshot";
      Environment = [
        "DISPLAY=:0"
        "WAYLAND_DISPLAY=wayland-1"
        "XDG_RUNTIME_DIR=/run/user/1000"
        "GNUPGHOME=%h/.gnupg"
        "GPG_TTY=$(tty)"
      ];
      
      ExecStartPre = toString (pkgs.writeShellScript "gpg-unlock-pre" ''
        ${pkgs.coreutils}/bin/sleep 2
        ${pkgs.gnupg}/bin/gpgconf --kill gpg-agent
        ${pkgs.gnupg}/bin/gpg-connect-agent updatestartuptty /bye
      '');

      ExecStart = toString (pkgs.writeShellScript "gpg-unlock" ''
        # Daha basit bir test işlemi
        ${pkgs.gnupg}/bin/gpg -K --with-keygrip
        echo "test" | ${pkgs.gnupg}/bin/gpg --clearsign
      '');

      StandardOutput = "journal";
      StandardError = "journal";
      RemainAfterExit = true;
      TimeoutSec = "60s";
    };

    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };
}
