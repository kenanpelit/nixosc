# modules/home/gnupg/gpgunlock.nix
{ config, lib, pkgs, ... }:
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
      ];
      
      ExecStartPre = "${pkgs.coreutils}/bin/sleep 2";
      ExecStart = toString (pkgs.writeShellScript "gpg-unlock" ''
        # GPG ayarlarını yapılandır
        ${pkgs.gnupg}/bin/gpg-connect-agent updatestartuptty /bye

        # Test mesajı oluştur ve şifrele
        echo "test" | ${pkgs.gnupg}/bin/gpg \
          --batch \
          --yes \
          --quiet \
          -se -r kenanpelit@gmail.com \
          > /tmp/test.gpg

        # Şifreyi çöz
        ${pkgs.gnupg}/bin/gpg \
          --batch \
          --yes \
          --quiet \
          -d /tmp/test.gpg

        # Temizle
        rm -f /tmp/test.gpg
      '');
      RemainAfterExit = true;
      TimeoutSec = "1min";
    };

    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };
}
