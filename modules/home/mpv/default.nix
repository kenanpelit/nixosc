# modules/home/mpv/default.nix
{ config, lib, pkgs, ... }:
with lib;
{
  options.modules.mpv = {
    enable = lib.mkEnableOption "mpv configuration";
  };
  
  config = lib.mkIf config.modules.mpv.enable {
    home.packages = with pkgs; [
      mpv
      gnutar
      gzip
      coreutils
    ];

    systemd.user.services.extract-mpv-config = {
      Unit = {
        Description = "Extract MPV configuration";
        Requires = [ "sops-nix.service" ];
        After = [ "sops-nix.service" ];
      };
      
      Service = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = let
          extractScript = pkgs.writeShellScript "extract-mpv-config" ''
            if [ ! -f "/home/${config.home.username}/.backup/mpv.tar.gz" ]; then
              echo "MPV tar dosyası henüz hazır değil..."
              exit 1
            fi
            
            echo "Temizleniyor..."
            rm -rf $HOME/.config/mpv
            
            echo "Dizin oluşturuluyor..."
            mkdir -p $HOME/.config/mpv
            
            echo "Tar dosyası açılıyor..."
            ${pkgs.gnutar}/bin/tar --no-same-owner -xzf /home/${config.home.username}/.backup/mpv.tar.gz -C $HOME/.config/
          '';
        in "${extractScript}";
      };
      
      Install = {
        WantedBy = [ "default.target" ];
      };
    };
  };
}
