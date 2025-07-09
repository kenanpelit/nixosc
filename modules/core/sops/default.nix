# modules/core/sops/default.nix
# ==============================================================================
# SOPS System Level Configuration
# ==============================================================================
# This configuration manages system-level secrets including:
# - Age encryption key configuration
# - Wireless network passwords
# - System secret management
# - File permissions and ownership
# - User-level sops-nix service for home-manager compatibility
#
# Author: Kenan Pelit
# ==============================================================================
{ config, lib, pkgs, inputs, username, ... }:
{
  # SOPS NixOS module'ünü içe aktarma
  imports = [
    inputs.sops-nix.nixosModules.sops
  ];

  # =============================================================================
  # SOPS Configuration for System Level Secrets
  # =============================================================================
  sops = {
    # Default SOPS file - you can override per secret
    defaultSopsFile = "/home/${username}/.nixosc/secrets/wireless-secrets.enc.yaml";
    
    # Age key for encryption/decryption
    age.keyFile = "/home/${username}/.config/sops/age/keys.txt";
    
    # Validate SOPS files exist before trying to use them
    validateSopsFiles = false;  # Set to false to avoid build-time validation
    
    # Enable SOPS for nixos
    gnupg.sshKeyPaths = [];  # We're using age, not GPG
    
    # System level secrets - only include if files exist
    secrets = lib.mkIf (builtins.pathExists /home/${username}/.nixosc/secrets/wireless-secrets.enc.yaml) {
      # Ken_5 ağı parolası
      "wireless_ken_5_password" = {
        sopsFile = "/home/${username}/.nixosc/secrets/wireless-secrets.enc.yaml";
        key = "ken_5_password";
        owner = "root";
        group = "networkmanager";
        mode = "0640";
        # Restart NetworkManager when this secret changes
        restartUnits = [ "NetworkManager.service" ];
      };
      
      # Ken_2_4 ağı parolası
      "wireless_ken_2_4_password" = {
        sopsFile = "/home/${username}/.nixosc/secrets/wireless-secrets.enc.yaml";
        key = "ken_2_4_password";
        owner = "root";
        group = "networkmanager";
        mode = "0640";
        # Restart NetworkManager when this secret changes
        restartUnits = [ "NetworkManager.service" ];
      };
    };
  };

  # =============================================================================
  # Directory Structure and Permissions
  # =============================================================================
  # Ensure the secrets directory exists with proper permissions
  systemd.tmpfiles.rules = [
    "d /home/${username}/.nixosc 0755 ${username} users -"
    "d /home/${username}/.nixosc/secrets 0750 ${username} users -"
    "d /home/${username}/.config 0755 ${username} users -"
    "d /home/${username}/.config/sops 0750 ${username} users -"
    "d /home/${username}/.config/sops/age 0700 ${username} users -"
  ];

  # =============================================================================
  # System Packages
  # =============================================================================
  # Ensure age and sops are available system-wide
  environment.systemPackages = with pkgs; [
    age
    sops
  ];

  # =============================================================================
  # System Services Configuration
  # =============================================================================
  # Enable the system-level sops-nix service
  systemd.services.sops-nix = {
    description = "SOPS secrets activation";
    wantedBy = [ "multi-user.target" ];
    after = [ "local-fs.target" ];
    
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      User = "root";
      Group = "root";
    };
    
    script = ''
      # Ensure directories exist
      mkdir -p /home/${username}/.config/sops/age
      chown ${username}:users /home/${username}/.config/sops/age
      chmod 700 /home/${username}/.config/sops/age
      
      # Check if age key exists
      if [ ! -f "/home/${username}/.config/sops/age/keys.txt" ]; then
        echo "Warning: Age key not found at /home/${username}/.config/sops/age/keys.txt"
        echo "Please generate an age key first."
      else
        echo "Age key found - SOPS system service ready"
      fi
    '';
  };

  # =============================================================================
  # User Services Configuration
  # =============================================================================
  # Create user-level sops-nix service that other home-manager services can depend on
  systemd.user.services.sops-nix = {
    description = "SOPS secrets activation (user-level)";
    wantedBy = [ "default.target" ];
    after = [ "graphical-session.target" ];
    
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    
    script = ''
      # Simple user-level sops service
      echo "SOPS user-level service activated"
      
      # Ensure user directories exist
      mkdir -p /home/${username}/.config/sops/age
      
      # Check if age key exists
      if [ -f "/home/${username}/.config/sops/age/keys.txt" ]; then
        echo "Age key found - SOPS user service ready"
      else
        echo "Warning: Age key not found at /home/${username}/.config/sops/age/keys.txt"
      fi
      
      # Signal that SOPS is ready for other services
      touch /tmp/sops-user-ready
    '';
  };
}

