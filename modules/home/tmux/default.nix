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
  options.modules.tmux = {
    enable = lib.mkEnableOption "tmux configuration";
  };
 
  # =============================================================================
  # Module Implementation
  # =============================================================================
  config = lib.mkIf config.modules.tmux.enable {
    # ---------------------------------------------------------------------------
    # Required Packages
    # ---------------------------------------------------------------------------
    home.packages = with pkgs; [
      tmux      # Terminal multiplexer
    ];

    # ---------------------------------------------------------------------------
    # Configuration Extraction Service
    # ---------------------------------------------------------------------------
    systemd.user.services.extract-tmux-config = {
      Unit = {
        Description = "Extract tmux and oh-my-tmux configurations";
        Requires = [ "sops-nix.service" ];
        After = [ "sops-nix.service" ];
      };
     
      Service = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = let
          extractScript = pkgs.writeShellScript "extract-tmux-config" ''
            # Check for backup files
            if [ ! -f "/home/${config.home.username}/.backup/tmux.tar.gz" ] || [ ! -f "/home/${config.home.username}/.backup/oh-my-tmux.tar.gz" ]; then
              echo "Required tar files are not ready yet..."
              exit 1
            fi
           
            echo "Cleaning up old configurations..."
            rm -rf $HOME/.config/tmux $HOME/.config/oh-my-tmux
           
            echo "Creating directories..."
            mkdir -p $HOME/.config/tmux $HOME/.config/oh-my-tmux
           
            echo "Extracting tmux configuration..."
            ${pkgs.gnutar}/bin/tar --no-same-owner -xzf /home/${config.home.username}/.backup/tmux.tar.gz -C $HOME/.config/
            echo "Extracting oh-my-tmux configuration..."
            ${pkgs.gnutar}/bin/tar --no-same-owner -xzf /home/${config.home.username}/.backup/oh-my-tmux.tar.gz -C $HOME/.config/
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
    xdg.configFile = {
      "tmux".enable = false;
      "oh-my-tmux".enable = false;
    };
  };
}
