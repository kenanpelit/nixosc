# modules/home/sops/default.nix
# ==============================================================================
# SOPS Home Manager Configuration
# ==============================================================================
# This configuration manages user-level secrets including:
# - GitHub API tokens
# - Nix configuration secrets
# - Gist tokens
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
  '';
}

