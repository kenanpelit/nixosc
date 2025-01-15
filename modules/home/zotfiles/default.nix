# modules/home/zotfiles/default.nix
{ config, lib, pkgs, ... }:
with lib;
{
  options.modules.zotfiles = {
    enable = lib.mkEnableOption "dotfiles configuration";
  };
  
  config = lib.mkIf config.modules.zotfiles.enable {
    systemd.user.services.extract-dotfiles = {
      Unit = {
        Description = "Extract dotfiles";
        Requires = [ "sops-nix.service" ];
        After = [ "sops-nix.service" ];
      };
      
      Service = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = let
          extractScript = pkgs.writeShellScript "extract-dotfiles" ''
            if [ ! -f "/home/${config.home.username}/.backup/dot.tar.gz" ]; then
              echo "Tar dosyası henüz hazır değil..."
              exit 1
            fi
            echo "Tar dosyası açılıyor..."
            ${pkgs.gnutar}/bin/tar --no-same-owner -xzf /home/${config.home.username}/.backup/dot.tar.gz -C $HOME
          '';
        in "${extractScript}";
      };
      
      Install = {
        WantedBy = [ "default.target" ];
      };
    };
  };
}
