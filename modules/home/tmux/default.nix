# modules/home/tmux/default.nix
# ==============================================================================
# Tmux Terminal Multiplexer Configuration
# ==============================================================================
{ config, lib, pkgs, ... }:
with lib;
{
  # =============================================================================
  # Module Options
  # =============================================================================
  options.my.user.tmux = {
    enable = lib.mkEnableOption "tmux configuration";
  };
 
  # =============================================================================
  # Module Implementation
  # =============================================================================
  config = lib.mkIf config.my.user.tmux.enable {
    # ---------------------------------------------------------------------------
    # Configuration Extraction Service
    # ---------------------------------------------------------------------------
    systemd.user.services.extract-tmux-config = {
      Unit = {
        Description = "Extract tmux configuration";
        ConditionPathExists = "/home/${config.home.username}/.backup/tmux.tar.gz";
        Requires = [ "sops-nix.service" ];
        After = [ "sops-nix.service" ];
      };
     
      Service = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = let
          extractScript = pkgs.writeShellScript "extract-tmux-config" ''
            # Check for backup file
            if [ ! -f "/home/${config.home.username}/.backup/tmux.tar.gz" ]; then
              echo "Required tar file is not ready yet..."
              exit 0
            fi
           
            echo "Cleaning up old configuration..."
            rm -rf $HOME/.config/tmux
           
            echo "Creating directory..."
            mkdir -p $HOME/.config/tmux
           
            echo "Extracting tmux configuration..."
            ${pkgs.gnutar}/bin/tar --no-same-owner -xzf /home/${config.home.username}/.backup/tmux.tar.gz -C $HOME/.config/
          '';
        in "${extractScript}";
      };
     
      Install = {
        WantedBy = [ "default.target" ];
      };
    };
    
    # ---------------------------------------------------------------------------
    # Disable home-manager tmux management
    # ---------------------------------------------------------------------------
    programs.tmux.enable = false;
    xdg.configFile."tmux".enable = false;
  };
}
