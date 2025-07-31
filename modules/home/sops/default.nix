# modules/home/sops/default.nix
# ==============================================================================
# SOPS Home Manager Configuration
# ==============================================================================
# This configuration manages user-level secrets including:
# - GitHub API tokens
# - Nix configuration secrets
# - Gist tokens
# - Tmux and Oh-My-Tmux configurations
# - Subliminal configuration
# - File permissions and ownership
#
# Author: Kenan Pelit
# ==============================================================================
{ config, lib, pkgs, inputs, username, ... }:
{
  # SOPS Home Manager
  imports = [ inputs.sops-nix.homeManagerModules.sops ];
  # =============================================================================
  # SOPS Configuration for User Level Secrets
  # =============================================================================
  sops = {
    # Varsayılan SOPS dosyası - her secret için özelleştirilebilir
    defaultSopsFile = "${config.home.homeDirectory}/.nixosc/secrets/home-secrets.enc.yaml";
    
    # Age key for encryption/decryption
    age.keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";
    
    # Validate SOPS files exist before trying to use them
    validateSopsFiles = false;  # Set to false to avoid build-time validation
    # ===========================================================================
    # User Secrets Configuration
    # ===========================================================================
    secrets = {
      # GitHub API token
      "github_token" = {
        path = "${config.home.homeDirectory}/.config/github/token";
        mode = "0600";  # Only accessible by user
      };
      
      # Nix configuration secrets
      "nix_conf" = {
        path = "${config.home.homeDirectory}/.config/nix/nix.conf";
        mode = "0600";  # Only accessible by user
      };
      
      # GitHub Gist token
      "gist_token" = {
        path = "${config.home.homeDirectory}/.gist";
        mode = "0600";  # Only accessible by user
      };
      
      # Subliminal configuration
      "subliminal_config" = {
        sopsFile = "${config.home.homeDirectory}/.nixosc/secrets/subliminal.enc.toml";
        path = "${config.home.homeDirectory}/.config/subliminal/subliminal.toml";
        mode = "0600";
        format = "binary";
      };
      
      # Tmux configuration archive
      "tmux_config" = {
        sopsFile = "${config.home.homeDirectory}/.nixosc/assets/tmux.enc.tar.gz";
        path = "${config.home.homeDirectory}/.backup/tmux.tar.gz";
        mode = "0600";
        format = "binary";
      };
      
      # MPV configuration archive
      "mpv_config" = {
        sopsFile = "${config.home.homeDirectory}/.nixosc/assets/mpv.enc.tar.gz";
        path = "${config.home.homeDirectory}/.backup/mpv.tar.gz";
        mode = "0600";
        format = "binary";
      };
    };
  };
  # =============================================================================
  # Directory Structure and Permissions
  # =============================================================================
  # Ensure required directories exist with proper permissions
  home.activation.createDirs = lib.hm.dag.entryBefore ["writeBoundary"] ''
    # SOPS age keys directory
    mkdir -p "${config.home.homeDirectory}/.config/sops/age"
    
    # GitHub configuration directory
    mkdir -p "${config.home.homeDirectory}/.config/github"
    
    # Nix configuration directory
    mkdir -p "${config.home.homeDirectory}/.config/nix"
    
    # Subliminal configuration directory
    mkdir -p "${config.home.homeDirectory}/.config/subliminal"
    
    # Backup directory for encrypted files
    mkdir -p "${config.home.homeDirectory}/.backup"
  '';
}

