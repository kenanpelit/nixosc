# modules/core/hblock/default.nix
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.hblock;
  updateScript = pkgs.writeShellScript "hblock-update" ''
    # Her kullanıcı için ~/.hosts dosyasını güncelle
    for USER_HOME in /home/*; do
      if [ -d "$USER_HOME" ]; then
        USER=$(basename "$USER_HOME")
        
        # Temel girdileri ekle
        echo "# Base entries" > "$USER_HOME/.hosts"
        echo "localhost 127.0.0.1" >> "$USER_HOME/.hosts"
        echo "hay 127.0.0.2" >> "$USER_HOME/.hosts"
        
        # hBlock çıktısını ekle
        echo "# hBlock entries (Updated: $(date))" >> "$USER_HOME/.hosts"
        ${pkgs.hblock}/bin/hblock -O - | while read DOMAIN; do
          if [[ $DOMAIN =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+[[:space:]]+(.+)$ ]]; then
            echo "''${BASH_REMATCH[1]} ''${BASH_REMATCH[1]}" >> "$USER_HOME/.hosts"
          fi
        done
        
        # Dosya sahipliğini ayarla
        chown $USER:users "$USER_HOME/.hosts"
        chmod 644 "$USER_HOME/.hosts"
      fi
    done
  '';
in {
  options.services.hblock = {
    enable = mkEnableOption "hBlock service";
  };

  config = mkIf cfg.enable {
    systemd.services.hblock = {
      description = "hBlock - Update user hosts files";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      
      serviceConfig = {
        Type = "oneshot";
        ExecStart = updateScript;
        RemainAfterExit = true;
      };
    };

    systemd.timers.hblock = {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "daily";
        RandomizedDelaySec = 3600;
        Persistent = true;
      };
    };

    # Kullanıcıların varsayılan .bashrc veya .zshrc'sine HOSTALIASES ekle
    environment.etc."skel/.bashrc".text = lib.mkAfter ''
      export HOSTALIASES="$HOME/.hosts"
    '';

    environment.systemPackages = [ pkgs.hblock ];
  };
}
