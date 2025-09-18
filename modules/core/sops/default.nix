# modules/core/sops/default.nix
# ==============================================================================
# SOPS Secrets Management Module
# ==============================================================================
#
# Module: modules/core/sops
# Author: Kenan Pelit
# Date:   2025-09-03
#
# Purpose: System-level encrypted secrets management with SOPS and age
#
# Features:
#   - Encrypted secrets versioned in git
#   - Transparent decryption during NixOS activation
#   - Age encryption (no GPG complexity)
#   - NetworkManager wireless passwords as example
#
# Prerequisites (one-time setup):
#   $ mkdir -p ~/.config/sops/age
#   $ age-keygen -o ~/.config/sops/age/keys.txt
#   Use the public key in .sops.yaml configuration
#
# Design Notes:
#   - Default SOPS file: ~/.nixosc/secrets/wireless-secrets.enc.yaml
#   - Age key location: ~/.config/sops/age/keys.txt
#   - validateSopsFiles disabled for initial setup flexibility
#   - Secrets conditionally loaded if file exists (prevents build failures)
#
# ==============================================================================

{ config, lib, pkgs, inputs, username, ... }:

{
  # ============================================================================
  # SOPS-Nix Module Import
  # ============================================================================
  
  imports = [ inputs.sops-nix.nixosModules.sops ];

  # ============================================================================
  # SOPS Configuration
  # ============================================================================
  
  sops = {
    # Default secrets file (can store multiple secrets)
    defaultSopsFile = "/home/${username}/.nixosc/secrets/wireless-secrets.enc.yaml";
    
    # Age key for decryption
    age.keyFile = "/home/${username}/.config/sops/age/keys.txt";
    
    # Skip validation during build (allows initial setup without secrets)
    validateSopsFiles = false;
    
    # No GPG/SSH keys (using age exclusively)
    gnupg.sshKeyPaths = [ ];

    # --------------------------------------------------------------------------
    # Secret Definitions
    # --------------------------------------------------------------------------
    # Conditionally load secrets only if encrypted file exists
    
    secrets = lib.mkIf (builtins.pathExists /home/${username}/.nixosc/secrets/wireless-secrets.enc.yaml) {
      
      # Wireless password for Ken_5 SSID
      "wireless_ken_5_password" = {
        sopsFile = "/home/${username}/.nixosc/secrets/wireless-secrets.enc.yaml";
        key      = "ken_5_password";              # Key in YAML file
        owner    = "root";
        group    = "networkmanager";              # NM service group access
        mode     = "0640";                        # Read for group
        restartUnits = [ "NetworkManager.service" ]; # Reload on change
      };
      
      # Wireless password for Ken_2_4 SSID
      "wireless_ken_2_4_password" = {
        sopsFile = "/home/${username}/.nixosc/secrets/wireless-secrets.enc.yaml";
        key      = "ken_2_4_password";
        owner    = "root";
        group    = "networkmanager";
        mode     = "0640";
        restartUnits = [ "NetworkManager.service" ];
      };
      
      # Add more secrets here as needed (SSH keys, API tokens, etc.)
    };
  };

  # ============================================================================
  # Directory Structure & Permissions
  # ============================================================================
  # Ensure required directories exist with proper permissions
  
  systemd.tmpfiles.rules = [
    "d /home/${username}/.nixosc 0755 ${username} users -"
    "d /home/${username}/.nixosc/secrets 0750 ${username} users -"
    "d /home/${username}/.config 0755 ${username} users -"
    "d /home/${username}/.config/sops 0750 ${username} users -"
    "d /home/${username}/.config/sops/age 0700 ${username} users -"
  ];

  # ============================================================================
  # Required Tools
  # ============================================================================
  
  environment.systemPackages = with pkgs; [
    age      # Age encryption tool
    sops     # SOPS CLI for secret management
  ];

  # ============================================================================
  # System Service - SOPS Activation Helper
  # ============================================================================
  # Provides diagnostic warnings and ensures directories exist
  
  systemd.services.sops-nix = {
    description = "SOPS secrets activation (system helper)";
    wantedBy = [ "multi-user.target" ];
    after    = [ "local-fs.target" ];
    
    serviceConfig = {
      Type            = "oneshot";
      RemainAfterExit = true;
      User            = "root";
      Group           = "root";
    };
    
    script = ''
      # Ensure age directory exists with correct permissions
      mkdir -p /home/${username}/.config/sops/age
      chown ${username}:users /home/${username}/.config/sops/age
      chmod 700 /home/${username}/.config/sops/age
      
      # Check for age key and provide helpful guidance
      if [ ! -f "/home/${username}/.config/sops/age/keys.txt" ]; then
        echo "[SOPS] Age key not found at ~/.config/sops/age/keys.txt"
        echo "[SOPS] Generate one: age-keygen -o ~/.config/sops/age/keys.txt"
      else
        echo "[SOPS] Age key found - system-level SOPS ready"
      fi
    '';
  };

  # ============================================================================
  # User Service - Home-Manager Integration
  # ============================================================================
  # Provides ready signal for user-level services that depend on secrets
  
  systemd.user.services.sops-nix = {
    description = "SOPS secrets activation (user-level helper)";
    wantedBy = [ "default.target" ];
    after    = [ "graphical-session.target" ];
    
    serviceConfig = {
      Type            = "oneshot";
      RemainAfterExit = true;
    };
    
    script = ''
      mkdir -p /home/${username}/.config/sops/age
      
      if [ -f "/home/${username}/.config/sops/age/keys.txt" ]; then
        echo "[SOPS][user] Age key present - user-level SOPS ready"
      else
        echo "[SOPS][user] Warning: no age key at ~/.config/sops/age/keys.txt"
      fi
      
      # Signal file for HM services to depend on
      touch /tmp/sops-user-ready
    '';
  };
}

