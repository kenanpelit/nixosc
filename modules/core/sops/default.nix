# modules/core/sops/default.nix
# ==============================================================================
# SOPS System Level Configuration
# ==============================================================================
# This configuration manages system-level secrets including:
# - Age encryption key configuration
# - Wireless network passwords
# - System secret management
# - File permissions and ownership
#
# Author: Kenan Pelit
# ==============================================================================
{ config, lib, pkgs, inputs, username, ... }:
{
  # SOPS NixOS module'ünü içe aktarma
  imports = [
    inputs.sops-nix.nixosModules.sops
  ];

  # SOPS configuration for system level secrets
  sops = {
    # Default SOPS file - you can override per secret
    defaultSopsFile = "/home/${username}/.nixosc/secrets/wireless-secrets.enc.yaml";
    
    # Age key for encryption/decryption
    age.keyFile = "/home/${username}/.config/sops/age/keys.txt";
    
    # Validate SOPS files exist before trying to use them
    validateSopsFiles = false;  # Set to false to avoid build-time validation
    
    # System level secrets
    secrets = {
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

  # Ensure the secrets directory exists with proper permissions
  systemd.tmpfiles.rules = [
    "d /home/${username}/.nixosc/secrets 0750 ${username} users -"
    "d /home/${username}/.config/sops 0750 ${username} users -"
    "d /home/${username}/.config/sops/age 0700 ${username} users -"
  ];
}

