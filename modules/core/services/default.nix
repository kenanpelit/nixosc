# modules/core/sops/default.nix
# ==============================================================================
# SOPS Secrets Management Configuration
# ==============================================================================
#
# Module:      modules/core/sops
# Purpose:     System-level encrypted secrets management with SOPS and age
# Author:      Kenan Pelit
# Created:     2025-09-03
# Modified:    2025-11-15
#
# Architecture:
#   Age Encryption → SOPS Management → NixOS Integration → Service Injection
#
# Secret Lifecycle:
#   1. Generation    - age-keygen creates encryption key
#   2. Encryption    - sops encrypts secrets with age public key
#   3. Storage       - Encrypted YAML stored in git (safe to commit)
#   4. Activation    - Decrypted during nixos-rebuild to tmpfs
#   5. Consumption   - Services read decrypted secrets from /run/secrets/
#
# Security Model:
#   • Encryption at Rest - Secrets encrypted in git repository
#   • Decryption on Boot - Transparent decryption during activation
#   • Memory-only Store - Decrypted secrets live in tmpfs (RAM)
#   • Access Control - File permissions limit secret access
#   • No GPG Complexity - Age is simpler, faster, more secure
#
# Design Principles:
#   • Fail Gracefully - Allow builds without secrets (initial setup)
#   • Single Source - One encrypted file per secret category
#   • Least Privilege - Minimal permissions, per-service access
#   • Git-friendly - Encrypted files safe to version control
#
# Module Boundaries:
#   ✓ System-level secrets           (THIS MODULE)
#   ✓ Age key management             (THIS MODULE)
#   ✓ NetworkManager passwords       (THIS MODULE)
#   ✗ User-level secrets             (home-manager sops module)
#   ✗ Application config             (service modules)
#   ✗ SSH keys                       (accounts module)
#
# ==============================================================================

{ config, lib, pkgs, inputs, username, ... }:

let
  inherit (lib) mkIf;
  
  # ----------------------------------------------------------------------------
  # Path Configuration (Single Source of Truth)
  # ----------------------------------------------------------------------------
  
  homeDir = "/home/${username}";
  
  # SOPS configuration paths
  sopsDir        = "${homeDir}/.nixosc/secrets";
  sopsAgeKeyFile = "${homeDir}/.config/sops/age/keys.txt";
  
  # Secret files (one file per category for better organization)
  wirelessSecretsFile = "${sopsDir}/wireless-secrets.enc.yaml";
  
  # ----------------------------------------------------------------------------
  # Helper Functions
  # ----------------------------------------------------------------------------
  
  # Check if encrypted secrets file exists (prevents build failures)
  secretsFileExists = builtins.pathExists wirelessSecretsFile;
  
in
{
  # ============================================================================
  # Module Imports
  # ============================================================================
  # Import sops-nix for NixOS integration
  imports = [ inputs.sops-nix.nixosModules.sops ];

  # ============================================================================
  # SOPS Configuration (Layer 1: Encryption Backend)
  # ============================================================================
  
  sops = {
    # Default encrypted file
    defaultSopsFile = wirelessSecretsFile;
    
    age = {
      keyFile     = sopsAgeKeyFile;
      sshKeyPaths = [ ];
    };
    
    # Build-time validation disabled to allow initial setup
    validateSopsFiles = false;

    # GPG disabled – using age only
    gnupg.sshKeyPaths = [ ];

    # ==========================================================================
    # Secret Definitions (Layer 2: Access Control)
    # ==========================================================================
    secrets = mkIf secretsFileExists {
      # ---- Ken_5 WiFi Network (5GHz) ----
      "wireless_ken_5_password" = {
        sopsFile = wirelessSecretsFile;
        key      = "ken_5_password";
        owner    = "root";
        group    = "networkmanager";
        mode     = "0640";
        restartUnits = [ "NetworkManager.service" ];
      };
      
      # ---- Ken_2_4 WiFi Network (2.4GHz) ----
      "wireless_ken_2_4_password" = {
        sopsFile = wirelessSecretsFile;
        key      = "ken_2_4_password";
        owner    = "root";
        group    = "networkmanager";
        mode     = "0640";
        restartUnits = [ "NetworkManager.service" ];
      };

      # Diğer secret örnekleri comment’te kalıyor
    };
  };

  # ============================================================================
  # Directory Structure & Permissions (Layer 3: Filesystem Setup)
  # ============================================================================
  
  systemd.tmpfiles.rules = [
    "d ${homeDir}/.nixosc           0755 ${username} users -"
    "d ${sopsDir}                  0750 ${username} users -"
    "d ${homeDir}/.config          0755 ${username} users -"
    "d ${homeDir}/.config/sops     0750 ${username} users -"
    "d ${homeDir}/.config/sops/age 0700 ${username} users -"
  ];

  # ============================================================================
  # System Packages (Layer 4: Management Tools)
  # ============================================================================
  
  environment.systemPackages = with pkgs; [
    age
    sops
    # jq
    # yq-go
  ];

  # ============================================================================
  # System Service - SOPS Activation Helper (Layer 5: System Integration)
  # ============================================================================
  # ÖNEMLİ: sops-nix kendi `sops-nix.service` unit’ini getiriyor.
  # Burada isim çakışmaması için `sops-bootstrap` kullanıyoruz.

  systemd.services.sops-bootstrap = {
    description = "SOPS secrets activation (system-level diagnostics)";
    wantedBy    = [ "multi-user.target" ];
    after       = [ "local-fs.target" ];
    
    serviceConfig = {
      Type            = "oneshot";
      RemainAfterExit = true;
      User            = "root";
      Group           = "root";
      PrivateTmp      = true;
      ProtectSystem   = "strict";
      ProtectHome     = false;
      NoNewPrivileges = true;
      ReadWritePaths  = [ homeDir ];
    };
    
    script = ''
      set -euo pipefail
      
      # Age key directory
      mkdir -p ${homeDir}/.config/sops/age
      chown ${username}:users ${homeDir}/.config/sops/age
      chmod 700 ${homeDir}/.config/sops/age
      
      # Age key validation
      if [ ! -f "${sopsAgeKeyFile}" ]; then
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "[SOPS] ⚠️  Age key not found!"
        echo "[SOPS] 📍 Expected location: ${sopsAgeKeyFile}"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        echo "🔧 Setup Instructions:"
        echo "   1. Generate age key:"
        echo "      age-keygen -o ${sopsAgeKeyFile}"
        echo ""
        echo "   2. Extract public key:"
        echo "      grep 'public key:' ${sopsAgeKeyFile}"
        echo ""
        echo "   3. Add public key to .sops.yaml:"
        echo "      keys:"
        echo "        - &user_key age1..."
        echo "      creation_rules:"
        echo "        - path_regex: .*"
        echo "          key_groups:"
        echo "            - age:"
        echo "              - *user_key"
        echo ""
        echo "   4. Create first secret file:"
        echo "      sops ${wirelessSecretsFile}"
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
      else
        echo "[SOPS] ✅ Age key found - system-level SOPS ready"
        
        if grep -q "^AGE-SECRET-KEY-" "${sopsAgeKeyFile}"; then
          echo "[SOPS] ✅ Age key format valid"
        else
          echo "[SOPS] ⚠️  Age key format invalid (should start with AGE-SECRET-KEY-)"
        fi
        
        KEY_PERMS=$(stat -c %a "${sopsAgeKeyFile}")
        if [ "$KEY_PERMS" = "600" ]; then
          echo "[SOPS] ✅ Age key permissions correct (600)"
        else
          echo "[SOPS] ⚠️  Age key permissions: $KEY_PERMS (should be 600)"
          echo "[SOPS] 🔧 Fix: chmod 600 ${sopsAgeKeyFile}"
        fi
      fi
      
      # Secrets file validation
      if [ -f "${wirelessSecretsFile}" ]; then
        echo "[SOPS] ✅ Wireless secrets file found"
        
        if grep -q "ENC\[" "${wirelessSecretsFile}"; then
          echo "[SOPS] ✅ Secrets file encrypted"
        else
          echo "[SOPS] ⚠️  Secrets file not encrypted (plain text?)"
        fi
      else
        echo "[SOPS] ℹ️  No secrets file yet (${wirelessSecretsFile})"
        echo "[SOPS]    This is normal for initial setup"
      fi
      
      echo "[SOPS] ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    '';
  };

  # ============================================================================
  # User Service - Home-Manager Integration (Layer 6: User-level Support)
  # ============================================================================
  # Yine çakışmaması için isim: sops-user-bootstrap

  systemd.user.services.sops-user-bootstrap = {
    description = "SOPS secrets activation (user-level diagnostics)";
    wantedBy    = [ "default.target" ];
    after       = [ "graphical-session.target" ];
    
    serviceConfig = {
      Type            = "oneshot";
      RemainAfterExit = true;
      PrivateTmp      = true;
      ProtectSystem   = "strict";
      NoNewPrivileges = true;
    };
    
    script = ''
      set -euo pipefail
      
      mkdir -p ${homeDir}/.config/sops/age
      
      if [ -f "${sopsAgeKeyFile}" ]; then
        echo "[SOPS][user] ✅ Age key present - user-level SOPS ready"
        PUB_KEY=$(grep 'public key:' "${sopsAgeKeyFile}" | cut -d: -f2 | tr -d ' ' || echo "unknown")
        echo "[SOPS][user] 🔑 Public key: $PUB_KEY"
      else
        echo "[SOPS][user] ⚠️  No age key at ${sopsAgeKeyFile}"
        echo "[SOPS][user] 🔧 Generate: age-keygen -o ${sopsAgeKeyFile}"
      fi
      
      touch /tmp/sops-user-ready
      echo "[SOPS][user] 📡 Ready signal created: /tmp/sops-user-ready"
    '';
  };
}
