# modules/home/gnupg/gpgunlock.nix
# ==============================================================================
# GPG Auto-Unlock Service
# ==============================================================================
{ config, lib, pkgs, username, ... }:  # username'i ekledik
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
        # Configure GPG settings
        ${pkgs.gnupg}/bin/gpg-connect-agent updatestartuptty /bye
        
        # Create and encrypt test message
        echo "test" | ${pkgs.gnupg}/bin/gpg \
          --batch \
          --yes \
          --quiet \
          -se -r ${username}pelit@gmail.com \
          > /tmp/test.gpg
          
        # Decrypt test message (bu adımda parola soracak)
        ${pkgs.gnupg}/bin/gpg \
          --batch \
          --no-default-keyring \
          -d /tmp/test.gpg
          
        # Cleanup
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
