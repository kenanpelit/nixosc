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
        Requires = [ "sops-nix.service" ];
        After = [ "sops-nix.service" ];
      };
      
      Service = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = let
          extractScript = pkgs.writeShellScript "extract-mpv-config" ''
            # Check for backup file
            if [ ! -f "/home/${config.home.username}/.backup/mpv.tar.gz" ]; then
              echo "MPV tar dosyası henüz hazır değil..."
              exit 1
            fi
            
            # Clean old config
            echo "Temizleniyor..."
            rm -rf $HOME/.config/mpv
            
            # Create directory
            echo "Dizin oluşturuluyor..."
            mkdir -p $HOME/.config/mpv
            
            # Extract configuration
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
