# modules/nixos/sops/default.nix
# ==============================================================================
# SOPS Secrets Management Configuration
# ==============================================================================

{ config, lib, pkgs, inputs, ... }:

let
  inherit (lib) mkIf;
  username = config.my.user.name;
  homeDir  = "/home/${username}";
  
  # Paths
  sopsDir        = "${homeDir}/.nixosc/secrets";
  sopsAgeKeyDir  = "${homeDir}/.config/sops/age";
  sopsAgeKeyFile = "${sopsAgeKeyDir}/keys.txt";
  
  # Secret Files
  wirelessSecretsFile = "${sopsDir}/wireless-secrets.enc.yaml";
  hasWirelessSecrets = builtins.pathExists wirelessSecretsFile;
in
{
  imports = [ inputs.sops-nix.nixosModules.sops ];

  # ============================================================================
  # Core SOPS Configuration
  # ============================================================================
  sops = {
    validateSopsFiles = hasWirelessSecrets;

    age = {
      keyFile = sopsAgeKeyFile;
      sshKeyPaths = [ ]; # Disable SSH key derivation
    };

    gnupg.sshKeyPaths = [ ]; # Disable GPG

  } // lib.optionalAttrs hasWirelessSecrets {
    defaultSopsFile = wirelessSecretsFile;

    # --------------------------------------------------------------------------
    # Secrets Definition
    # --------------------------------------------------------------------------
    secrets = {
      "wireless_ken_5_password" = {
        key   = "ken_5_password";
        owner = "root";
        group = "networkmanager";
        mode  = "0640";
        restartUnits = [ "NetworkManager.service" ];
      };

      "wireless_ken_2_4_password" = {
        key   = "ken_2_4_password";
        owner = "root";
        group = "networkmanager";
        mode  = "0640";
        restartUnits = [ "NetworkManager.service" ];
      };
    };
  };

  # ============================================================================
  # System Tools
  # ============================================================================
  environment.systemPackages = with pkgs; [
    age
    sops
    ssh-to-age
  ];

  # ============================================================================
  # Initialization & Permissions
  # ============================================================================
  # Ensure SOPS directory structure exists with correct permissions
  systemd.tmpfiles.rules = [
    "d ${sopsAgeKeyDir} 0700 ${username} users -"
    "d ${sopsDir}       0750 ${username} users -"
  ];
}
