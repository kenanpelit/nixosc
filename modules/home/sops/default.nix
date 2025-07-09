# modules/home/sops/default.nix
# SOPS (Secrets OPerationS) Configuration for Home Manager
# Manages encrypted secrets and secure file deployments
# ==============================================================================
{ username, inputs, config, lib, ... }:
{
  # =============================================================================
  # Import SOPS Home Manager Module
  # Required for secrets management functionality
  # =============================================================================
  imports = [
    inputs.sops-nix.homeManagerModules.sops
  ];
  
  # =============================================================================
  # Core SOPS Configuration 
  # Defines default secret location and age key settings
  # =============================================================================
  sops = {
    # Default encrypted secrets file location - mutlak yol kullanın
    defaultSopsFile = /home/${username}/.nixosc/secrets/home-secrets.enc.yaml;
    
    # Age private key location for decryption
    age.keyFile = "/home/${username}/.config/sops/age/keys.txt";
    
    # Disable strict file validation
    validateSopsFiles = false;
    
    # ---------------------------------------------------------------------------
    # Secrets Configuration - Sadece var olan dosyalar için
    # ---------------------------------------------------------------------------
    secrets = lib.mkMerge [
      # Temel secrets - eğer dosya varsa
      (lib.mkIf (builtins.pathExists /home/${username}/.nixosc/secrets/home-secrets.enc.yaml) {
        # GitHub access token
        "github_token" = {
          path = "${config.home.homeDirectory}/.config/github/token";
        };
        
        # Nix configuration file
        "nix_conf" = {
          path = "${config.home.homeDirectory}/.config/nix/nix.conf";
          mode = "0600";
        };
        
        # GitHub Gist access token
        "gist_token" = {
          path = "${config.home.homeDirectory}/.gist";
          mode = "0600";
        };
      })
      
      # Binary assets - eğer dosyalar varsa
      (lib.mkIf (builtins.pathExists /home/${username}/.nixosc/assets/tmux.enc.tar.gz) {
        "tmux_backup_archive" = {
          path = "${config.home.homeDirectory}/.backup/tmux.tar.gz";
          mode = "0600";
          format = "binary";
          sopsFile = /home/${username}/.nixosc/assets/tmux.enc.tar.gz;
        };
      })
      
      (lib.mkIf (builtins.pathExists /home/${username}/.nixosc/assets/oh-my-tmux.enc.tar.gz) {
        "oh-my-tmux_backup_archive" = {
          path = "${config.home.homeDirectory}/.backup/oh-my-tmux.tar.gz";
          mode = "0600";
          format = "binary";
          sopsFile = /home/${username}/.nixosc/assets/oh-my-tmux.enc.tar.gz;
        };
      })
      
      (lib.mkIf (builtins.pathExists /home/${username}/.nixosc/assets/mpv.enc.tar.gz) {
        "mpv_backup_archive" = {
          path = "${config.home.homeDirectory}/.backup/mpv.tar.gz";
          mode = "0600";
          format = "binary";
          sopsFile = /home/${username}/.nixosc/assets/mpv.enc.tar.gz;
        };
      })
    ];
  };
}

