# modules/home/security/gnupg/gpgunlock.nix
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
        "DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus"
      ];
      
      ExecStartPre = toString (pkgs.writeShellScript "gpg-unlock-pre" ''
        ${pkgs.coreutils}/bin/sleep 2
        ${pkgs.gnupg}/bin/gpgconf --kill all
        ${pkgs.coreutils}/bin/sleep 1
        ${pkgs.gnupg}/bin/gpg-connect-agent updatestartuptty /bye
      '');
      
      ExecStart = toString (pkgs.writeShellScript "gpg-unlock" ''
        # Önce anahtarları listeleyelim
        ${pkgs.gnupg}/bin/gpg -K --with-keygrip

        # Batch modunda test imzalama
        ${pkgs.coreutils}/bin/echo "test" | ${pkgs.gnupg}/bin/gpg \
          --batch \
          --pinentry-mode loopback \
          --passphrase "" \
          --no-tty \
          --clearsign
      '');

      StandardOutput = "journal";
      StandardError = "journal";
      RemainAfterExit = true;
      TimeoutSec = "60s";
    };
    Install = {
      WantedBy = [ "default.target" "graphical-session.target" ];
    };
  };
}
