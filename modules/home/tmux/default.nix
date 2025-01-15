# modules/home/tmux/default.nix
{ config, lib, pkgs, ... }:

with lib;
{
  options.modules.tmux = {
    enable = lib.mkEnableOption "tmux configuration";
  };
  
  config = lib.mkIf config.modules.tmux.enable {
    home.packages = with pkgs; [
      tmux
      gnutar
      gzip
      coreutils
      yq-go
    ];

    systemd.user.services.extract-tmux-config = {
      Unit = {
        Description = "Extract tmux configuration";
        Requires = [ "sops-nix.service" ];
        After = [ "sops-nix.service" ];
      };
      
      Service = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = let
          extractScript = pkgs.writeShellScript "extract-tmux-config" ''
            if [ ! -f "/home/${config.home.username}/.backup/tmux.tar.gz" ]; then
              echo "Tar dosyası henüz hazır değil..."
              exit 1
            fi
            
            echo "Temizleniyor..."
            rm -rf $HOME/.config/tmux $HOME/.config/oh-my-tmux
            
            echo "Dizinler oluşturuluyor..."
            mkdir -p $HOME/.config/tmux $HOME/.config/oh-my-tmux
            
            echo "Tar dosyası açılıyor..."
            ${pkgs.gnutar}/bin/tar --no-same-owner -xzf /home/${config.home.username}/.backup/tmux.tar.gz -C $HOME/.config/
          '';
        in "${extractScript}";
      };
      
      Install = {
        WantedBy = [ "default.target" ];
      };
    };
  };
}
