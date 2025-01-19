# modules/home/zotfiles/default.nix
# ==============================================================================
# Dotfiles Management Configuration
# ==============================================================================
{ config, lib, pkgs, ... }:
with lib;
{
  # =============================================================================
  # Module Options
  # =============================================================================
  options.modules.zotfiles = {
    enable = lib.mkEnableOption "dotfiles configuration";
  };
  
  # =============================================================================
  # Module Implementation
  # =============================================================================
  config = lib.mkIf config.modules.zotfiles.enable {
    # ---------------------------------------------------------------------------
    # Extraction Service
    # ---------------------------------------------------------------------------
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
            # Check for backup file
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
