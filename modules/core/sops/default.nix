# modules/core/sops/default.nix
# ==============================================================================
# SOPS System Level Configuration
# ==============================================================================
{ config, lib, pkgs, inputs, ... }:

{
  # SOPS NixOS module'ünü içe aktarma
  imports = [
    inputs.sops-nix.nixosModules.sops
  ];

  # SOPS configuration for system level secrets
  sops = {
    # Age key for encryption/decryption
    age.keyFile = "/home/kenan/.config/sops/age/keys.txt";
    
    # System level secrets
    secrets = {
      # Ken_5 ağı parolası
      "wireless_ken_5_password" = {
        # Burada doğru yolu kullanın
        sopsFile = ../../../../secrets/wireless-secrets.enc.yaml;
        key = "ken_5_password";
        owner = "root";
        group = "networkmanager";
        mode = "0640";
      };
      # Ken_2_4 ağı parolası
      "wireless_ken_2_4_password" = {
        # Burada doğru yolu kullanın
        sopsFile = ../../../../secrets/wireless-secrets.enc.yaml;
        key = "ken_2_4_password";
        owner = "root";
        group = "networkmanager";
        mode = "0640";
      };
    };
  };
}

