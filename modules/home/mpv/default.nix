# modules/home/mpv/default.nix
# ==============================================================================
# MPV Media Player Configuration
# ==============================================================================
{ config, lib, pkgs, ... }:
with lib;
{
  # =============================================================================
  # Module Options
  # =============================================================================
  options.my.user.mpv = {
    enable = lib.mkEnableOption "mpv configuration";
  };
  
  # =============================================================================
  # Module Implementation
  # =============================================================================
  config = lib.mkIf config.my.user.mpv.enable {
    # ---------------------------------------------------------------------------
    # Configuration Extraction Service
    # ---------------------------------------------------------------------------
    systemd.user.services.extract-mpv-config = {
      Unit = {
        Description = "Extract MPV configuration";
        ConditionPathExists = "/home/${config.home.username}/.backup/mpv.tar.gz";
        Requires = [ "sops-nix.service" ];
        After = [ "sops-nix.service" ];
      };
      
      Service = {
        Type = "oneshot";
        RemainAfterExit = true;
        SuccessExitStatus = [ 0 1 2 ];
        ExecStart = let
          extractScript = pkgs.writeShellScript "extract-mpv-config" ''
            # Check for backup file
            if [ ! -f "/home/${config.home.username}/.backup/mpv.tar.gz" ]; then
              echo "MPV tar dosyası henüz hazır değil..."
              exit 0
            fi
            
            # Clean old config
            echo "Temizleniyor..."
            rm -rf $HOME/.config/mpv
            
            # Create directory
            echo "Dizin oluşturuluyor..."
            mkdir -p $HOME/.config/mpv
            
            # Extract configuration
            echo "Tar dosyası açılıyor..."
            ${pkgs.gnutar}/bin/tar --no-same-owner -xzf /home/${config.home.username}/.backup/mpv.tar.gz -C $HOME/.config/ || exit 0
          '';
        in "${extractScript}";
      };
      
      Install = {
        WantedBy = [ "default.target" ];
      };
    };
  };
}
