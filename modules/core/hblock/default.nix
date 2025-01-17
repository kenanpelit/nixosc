# modules/core/hblock/default.nix
{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.services.hblock;
  updateScript = pkgs.writeShellScript "hblock-update" ''
    # Her kullanıcı için ~/.config/hblock/hosts dosyasını güncelle
    for USER_HOME in /home/*; do
      if [ -d "$USER_HOME" ]; then
        USER=$(basename "$USER_HOME")
        CONFIG_DIR="$USER_HOME/.config/hblock"
        HOSTS_FILE="$CONFIG_DIR/hosts"

        # Eğer config dizini yoksa oluştur
        mkdir -p "$CONFIG_DIR"

        # Temel girdileri ekle
        echo "# Base entries" > "$HOSTS_FILE"
        echo "localhost 127.0.0.1" >> "$HOSTS_FILE"
        echo "hay 127.0.0.2" >> "$HOSTS_FILE"

        # hBlock çıktısını ekle
        echo "# hBlock entries (Updated: $(date))" >> "$HOSTS_FILE"
        ${pkgs.hblock}/bin/hblock -O - | while read DOMAIN; do
          if [[ $DOMAIN =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+[[:space:]]+(.+)$ ]]; then
            echo "''${BASH_REMATCH[1]} ''${BASH_REMATCH[1]}" >> "$HOSTS_FILE"
          fi
        done

        # Dosya sahipliğini ayarla
        chown $USER:users "$HOSTS_FILE"
        chmod 644 "$HOSTS_FILE"
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
      export HOSTALIASES="$HOME/.config/hblock/hosts"
    '';
    environment.systemPackages = [ pkgs.hblock ];
  };
}

