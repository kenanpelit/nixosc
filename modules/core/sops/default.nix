# modules/core/sops/default.nix
# ==============================================================================
# SOPS Secrets Management Configuration
# ==============================================================================
#
# Module:      modules/core/sops
# Purpose:     System-level encrypted secrets management with SOPS and age
# Author:      Kenan Pelit
# Created:     2025-09-03
# Modified:    2025-10-18
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
  
  # Runtime decrypted secrets location (tmpfs)
  secretsRunDir = "/run/secrets";
  
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
  # Provides: sops.secrets option, activation scripts, tmpfiles setup
  imports = [ inputs.sops-nix.nixosModules.sops ];

  # ============================================================================
  # SOPS Configuration (Layer 1: Encryption Backend)
  # ============================================================================
  
  sops = {
    # ==========================================================================
    # Default Secrets File
    # ==========================================================================
    # Primary encrypted YAML file containing multiple secrets
    # Format: YAML with encrypted values
    # Location: ~/.nixosc/secrets/wireless-secrets.enc.yaml
    # 
    # Structure:
    #   ken_5_password: ENC[AES256_GCM,data:...,tag:...,type:str]
    #   ken_2_4_password: ENC[AES256_GCM,data:...,tag:...,type:str]
    defaultSopsFile = wirelessSecretsFile;
    
    # ==========================================================================
    # Age Encryption Configuration
    # ==========================================================================
    # Age: Modern, simple encryption tool (replacement for GPG)
    # Key format: Bech32 encoding (age1...) - easier to handle than GPG
    # Security: X25519 (Curve25519) + ChaCha20-Poly1305
    
    age = {
      # ---- Private Key Location ----
      # Contains age private key for decrypting secrets
      # Format: Single-line secret key (AGE-SECRET-KEY-1...)
      # Permissions: 600 (user read/write only)
      # Backup: Store securely offline (USB, password manager)
      keyFile = sopsAgeKeyFile;
      
      # ---- Key Generation (one-time setup) ----
      # Generate key: age-keygen -o ~/.config/sops/age/keys.txt
      # Extract public key: grep 'public key:' ~/.config/sops/age/keys.txt
      # Use public key in .sops.yaml configuration
      
      # ---- SSH Key Fallback (disabled) ----
      # Age can use SSH keys, but we prefer dedicated age keys
      # Reason: Separation of concerns, better security model
      sshKeyPaths = [ ];
    };
    
    # ==========================================================================
    # Build-time Validation
    # ==========================================================================
    # Validation Strategy: Disabled for initial setup flexibility
    # Reason: Allows NixOS builds before secrets are created
    # Production: Consider enabling after initial setup (validateSopsFiles = true)
    validateSopsFiles = false;
    
    # When enabled, validation checks:
    # - Encrypted file exists
    # - File format is valid YAML
    # - All referenced secrets exist in file
    # - Age key can decrypt the file

    # ==========================================================================
    # GPG Configuration (disabled)
    # ==========================================================================
    # GPG support disabled - using age exclusively
    # Reason: Age is simpler, faster, and more secure than GPG
    # Note: No GPG keyring management, no web of trust complexity
    gnupg.sshKeyPaths = [ ];

    # ==========================================================================
    # Secret Definitions (Layer 2: Access Control)
    # ==========================================================================
    # Secrets are conditionally loaded only if encrypted file exists
    # This prevents build failures during initial setup
    # 
    # Secret Attributes:
    #   sopsFile: Path to encrypted YAML file
    #   key: Key name in YAML file
    #   owner/group: Unix ownership (who can read)
    #   mode: File permissions (octal)
    #   restartUnits: Services to restart on secret change
    #   path: Custom decrypted file location (default: /run/secrets/<name>)
    
    secrets = mkIf secretsFileExists {
      
      # ========================================================================
      # WiFi Network Passwords
      # ========================================================================
      # NetworkManager reads passwords from files specified in connection profiles
      # Profiles located in: /etc/NetworkManager/system-connections/
      
      # ---- Ken_5 WiFi Network (5GHz) ----
      "wireless_ken_5_password" = {
        # Source encrypted file
        sopsFile = wirelessSecretsFile;
        
        # Key in YAML file (plain text key, encrypted value)
        key = "ken_5_password";
        
        # ---- Access Control ----
        # Owner: root (NetworkManager runs as root)
        # Group: networkmanager (NetworkManager service group)
        # Mode: 0640 (owner read/write, group read, others none)
        owner = "root";
        group = "networkmanager";
        mode  = "0640";
        
        # ---- Service Integration ----
        # Restart NetworkManager when secret changes
        # Effect: Automatically reconnect with new password
        restartUnits = [ "NetworkManager.service" ];
        
        # Decrypted location: /run/secrets/wireless_ken_5_password
        # NetworkManager config references this path
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
      
      # ========================================================================
      # Additional Secret Examples (commented)
      # ========================================================================
      # Add more secrets following the same pattern
      
      # ---- SSH Private Key ----
      # "id_rsa" = {
      #   sopsFile = "${sopsDir}/ssh-keys.enc.yaml";
      #   key      = "id_rsa";
      #   owner    = username;
      #   group    = "users";
      #   mode     = "0600";  # User-only read/write
      #   path     = "${homeDir}/.ssh/id_rsa";  # Custom location
      # };
      
      # ---- API Token ----
      # "github_token" = {
      #   sopsFile = "${sopsDir}/api-tokens.enc.yaml";
      #   key      = "github_token";
      #   owner    = username;
      #   group    = "users";
      #   mode     = "0400";  # User-only read
      # };
      
      # ---- Database Password ----
      # "postgres_password" = {
      #   sopsFile = "${sopsDir}/database-secrets.enc.yaml";
      #   key      = "postgres_password";
      #   owner    = "postgres";
      #   group    = "postgres";
      #   mode     = "0400";
      #   restartUnits = [ "postgresql.service" ];
      # };
      
      # ---- TLS Certificate ----
      # "tls_cert" = {
      #   sopsFile = "${sopsDir}/tls-certs.enc.yaml";
      #   key      = "tls_cert";
      #   owner    = "nginx";
      #   group    = "nginx";
      #   mode     = "0440";
      #   restartUnits = [ "nginx.service" ];
      # };
    };
  };

  # ============================================================================
  # Directory Structure & Permissions (Layer 3: Filesystem Setup)
  # ============================================================================
  # Ensure required directories exist with proper permissions
  # Created by systemd-tmpfiles during early boot
  
  systemd.tmpfiles.rules = [
    # ---- NixOS Configuration Directory ----
    # Root of NixOS config and secrets storage
    # Permissions: 0755 (world-readable, user-writable)
    "d ${homeDir}/.nixosc 0755 ${username} users -"
    
    # ---- Secrets Storage Directory ----
    # Contains encrypted YAML files (safe to commit to git)
    # Permissions: 0750 (user+group readable, others none)
    "d ${sopsDir} 0750 ${username} users -"
    
    # ---- User Config Directory ----
    # Standard XDG config location
    # Permissions: 0755 (standard config directory permissions)
    "d ${homeDir}/.config 0755 ${username} users -"
    
    # ---- SOPS Config Directory ----
    # Contains SOPS-specific configuration
    # Permissions: 0750 (user+group readable, others none)
    "d ${homeDir}/.config/sops 0750 ${username} users -"
    
    # ---- Age Key Directory ----
    # Contains private encryption key (CRITICAL security)
    # Permissions: 0700 (user-only access, NO group or others)
    "d ${homeDir}/.config/sops/age 0700 ${username} users -"
    
    # Security Note: Age key directory MUST be 0700 (user-only)
    # Compromise of age key = compromise of all secrets
  ];

  # ============================================================================
  # System Packages (Layer 4: Management Tools)
  # ============================================================================
  # Essential tools for secret management and debugging
  
  environment.systemPackages = with pkgs; [
    # ---- Age Encryption Tool ----
    # Modern encryption tool (replacement for GPG)
    # Commands:
    #   age-keygen -o keys.txt    # Generate key pair
    #   age -e -r <pubkey> file   # Encrypt file
    #   age -d -i keys.txt file   # Decrypt file
    age
    
    # ---- SOPS CLI ----
    # Secret editing and management tool
    # Commands:
    #   sops secrets.yaml         # Edit encrypted file (opens in $EDITOR)
    #   sops -d secrets.yaml      # Decrypt and print
    #   sops updatekeys secrets   # Re-encrypt with new keys
    #   sops set 'key "value"' f  # Set specific key
    sops
    
    # ---- Debugging Tools (optional, uncomment if needed) ----
    # jq         # JSON processor (for inspecting decrypted JSON)
    # yq-go      # YAML processor (for inspecting decrypted YAML)
  ];

  # ============================================================================
  # System Service - SOPS Activation Helper (Layer 5: System Integration)
  # ============================================================================
  # Ensures proper setup and provides diagnostic output
  # Runs during system activation before secrets are decrypted
  
  systemd.services.sops-nix = {
    # ---- Service Metadata ----
    description = "SOPS secrets activation (system-level diagnostics)";
    wantedBy    = [ "multi-user.target" ];  # Start during normal boot
    after       = [ "local-fs.target" ];    # After filesystems mounted
    
    # ---- Service Configuration ----
    serviceConfig = {
      Type            = "oneshot";      # Run once and exit
      RemainAfterExit = true;           # Mark as active after completion
      User            = "root";         # Run as root (directory creation)
      Group           = "root";
      
      # Security Hardening
      PrivateTmp          = true;       # Isolated /tmp
      ProtectSystem       = "strict";   # Read-only system directories
      ProtectHome         = false;      # Need access to user home
      NoNewPrivileges     = true;       # Prevent privilege escalation
      ReadWritePaths      = [ homeDir ]; # Allow writing to user home
    };
    
    # ---- Service Script ----
    # 1. Ensure directory structure exists
    # 2. Set correct permissions
    # 3. Provide helpful diagnostic output
    script = ''
      set -euo pipefail
      
      # ---- Create Age Key Directory ----
      # Must exist before SOPS tries to decrypt
      mkdir -p ${homeDir}/.config/sops/age
      chown ${username}:users ${homeDir}/.config/sops/age
      chmod 700 ${homeDir}/.config/sops/age
      
      # ---- Age Key Validation ----
      # Check if age key exists and provide setup guidance
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
        
        # Validate key format (should start with AGE-SECRET-KEY-)
        if grep -q "^AGE-SECRET-KEY-" "${sopsAgeKeyFile}"; then
          echo "[SOPS] ✅ Age key format valid"
        else
          echo "[SOPS] ⚠️  Age key format invalid (should start with AGE-SECRET-KEY-)"
        fi
        
        # Check key permissions (should be 0600)
        KEY_PERMS=$(stat -c %a "${sopsAgeKeyFile}")
        if [ "$KEY_PERMS" = "600" ]; then
          echo "[SOPS] ✅ Age key permissions correct (600)"
        else
          echo "[SOPS] ⚠️  Age key permissions: $KEY_PERMS (should be 600)"
          echo "[SOPS] 🔧 Fix: chmod 600 ${sopsAgeKeyFile}"
        fi
      fi
      
      # ---- Secrets File Validation ----
      if [ -f "${wirelessSecretsFile}" ]; then
        echo "[SOPS] ✅ Wireless secrets file found"
        
        # Check if file is actually encrypted (contains ENC[)
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
  # Provides ready signal for user-level services that depend on secrets
  # Useful for home-manager services that need to wait for secrets
  
  systemd.user.services.sops-nix = {
    # ---- Service Metadata ----
    description = "SOPS secrets activation (user-level diagnostics)";
    wantedBy    = [ "default.target" ];        # Start with user session
    after       = [ "graphical-session.target" ]; # After GUI is ready
    
    # ---- Service Configuration ----
    serviceConfig = {
      Type            = "oneshot";
      RemainAfterExit = true;
      
      # Security Hardening
      PrivateTmp      = true;
      ProtectSystem   = "strict";
      NoNewPrivileges = true;
    };
    
    # ---- Service Script ----
    # 1. Verify user-level setup
    # 2. Create ready signal for dependent services
    # 3. Provide diagnostic output
    script = ''
      set -euo pipefail
      
      # ---- Ensure Age Directory Exists ----
      mkdir -p ${homeDir}/.config/sops/age
      
      # ---- User-level Key Check ----
      if [ -f "${sopsAgeKeyFile}" ]; then
        echo "[SOPS][user] ✅ Age key present - user-level SOPS ready"
        
        # Extract public key for reference
        PUB_KEY=$(grep 'public key:' "${sopsAgeKeyFile}" | cut -d: -f2 | tr -d ' ' || echo "unknown")
        echo "[SOPS][user] 🔑 Public key: $PUB_KEY"
      else
        echo "[SOPS][user] ⚠️  No age key at ${sopsAgeKeyFile}"
        echo "[SOPS][user] 🔧 Generate: age-keygen -o ${sopsAgeKeyFile}"
      fi
      
      # ---- Create Ready Signal ----
      # Other user services can depend on this file existing
      # Usage in home-manager:
      #   systemd.user.services.myservice = {
      #     after = [ "sops-nix.service" ];
      #     requires = [ "sops-nix.service" ];
      #   };
      touch /tmp/sops-user-ready
      echo "[SOPS][user] 📡 Ready signal created: /tmp/sops-user-ready"
    '';
  };
}

# ==============================================================================
# Best Practices & Usage Guidelines
# ==============================================================================
#
# 1. Initial Setup (one-time):
#    $ age-keygen -o ~/.config/sops/age/keys.txt
#    $ grep 'public key:' ~/.config/sops/age/keys.txt
#    # Add public key to .sops.yaml in repository root
#    $ mkdir -p ~/.nixosc/secrets
#    $ sops ~/.nixosc/secrets/wireless-secrets.enc.yaml
#    # Add your secrets in YAML format, save and exit
#
# 2. Creating Secret Files:
#    # Create .sops.yaml in repository root:
#    keys:
#      - &user_key age1ql3z7hjy54pw3hyww5ayyfg7zqgvc7w3j2elw8zmrj2kg5sfn9aqmcac8p
#    creation_rules:
#      - path_regex: secrets/.*\.enc\.yaml$
#        key_groups:
#          - age:
#            - *user_key
#    
#    # Create and edit secret:
#    $ sops ~/.nixosc/secrets/wireless-secrets.enc.yaml
#    # Add content:
#    ken_5_password: MySecretPassword123
#    ken_2_4_password: AnotherSecret456
#
# 3. Editing Secrets:
#    $ sops ~/.nixosc/secrets/wireless-secrets.enc.yaml
#    # Opens in $EDITOR (decrypted), re-encrypts on save
#
# 4. Viewing Secrets:
#    $ sops -d ~/.nixosc/secrets/wireless-secrets.enc.yaml
#    # Decrypt and print to stdout (use carefully!)
#
# 5. Using Secrets in NetworkManager:
#    # In /etc/NetworkManager/system-connections/Ken_5.nmconnection:
#    [wifi-security]
#    key-mgmt=wpa-psk
#    psk-file=/run/secrets/wireless_ken_5_password
#
# 6. Adding New Secrets:
#    # Edit this file, add new secret definition:
#    sops.secrets."my_new_secret" = {
#      sopsFile = wirelessSecretsFile;
#      key      = "my_secret_key";
#      owner    = "myuser";
#      group    = "mygroup";
#      mode     = "0400";
#    };
#    # Then edit encrypted file and add the key:
#    $ sops ~/.nixosc/secrets/wireless-secrets.enc.yaml
#    # Add: my_secret_key: secret_value
#
# 7. Rotating Keys:
#    $ age-keygen -o ~/.config/sops/age/keys.txt.new
#    # Update .sops.yaml with new public key
#    $ sops updatekeys ~/.nixosc/secrets/*.enc.yaml
#    $ mv ~/.config/sops/age/keys.txt.new ~/.config/sops/age/keys.txt
#
# 8. Backup Strategy:
#    - Encrypted files: Safe to commit to git
#    - Age private key: Backup offline (USB, password manager)
#    - Never commit: ~/.config/sops/age/keys.txt
#
# 9. Multi-machine Setup:
#    # Add multiple public keys to .sops.yaml:
#    keys:
#      - &laptop_key age1...
#      - &desktop_key age1...
#    creation_rules:
#      - path_regex: .*
#        key_groups:
#          - age:
#            - *laptop_key
#            - *desktop_key
#
# 10. Secret Categories:
#     - wifi-secrets.enc.yaml       # WiFi passwords
#     - api-tokens.enc.yaml         # API keys, tokens
#     - ssh-keys.enc.yaml           # SSH private keys
#     - database-secrets.enc.yaml   # DB passwords
#     - tls-certs.enc.yaml          # SSL/TLS certificates
#
# ==============================================================================
# Troubleshooting Guide
# ==============================================================================
#
# Secret decryption fails:
#   journalctl -u sops-nix.service          # Check service logs
#   ls -la ~/.config/sops/age/keys.txt      # Verify key exists (600 perms)
#   sops -d /path/to/secret.enc.yaml        # Test manual decryption
#   grep 'AGE-SECRET-KEY-' ~/.config/sops/age/keys.txt  # Validate key format
#
# Secrets not available to services:
#   ls -la /run/secrets/                    # Check decrypted secrets
#   systemctl status sops-nix.service       # Check activation service
#   journalctl -xe | grep sops              # Look for errors
#   stat /run/secrets/wireless_ken_5_password  # Check permissions
#
# NetworkManager can't read WiFi password:
#   sudo cat /run/secrets/wireless_ken_5_password  # Verify content
#   groups NetworkManager                   # Should include 'networkmanager'
#   sudo systemctl restart NetworkManager   # Reload with new secret
#   nmcli connection show Ken_5             # Check connection config
#
# Age key permissions wrong:
#   chmod 600 ~/.config/sops/age/keys.txt   # Fix permissions
#   chown $(whoami):users ~/.config/sops/age/keys.txt  # Fix ownership
#
# Editing secrets opens in wrong editor:
#   export EDITOR=vim                       # Set preferred editor
#   sops secrets.yaml                       # Should open in vim now
#
# Adding new machine can't decrypt:
#   # On new machine:
#   age-keygen -o ~/.config/sops/age/keys.txt
#   grep 'public key:' ~/.config/sops/age/keys.txt
#   # On old machine, add public key to .sops.yaml
#   sops updatekeys ~/.nixosc/secrets/*.enc.yaml  # Re-encrypt for all keys
#
# Secrets file corrupted:
#   git restore ~/.nixosc/secrets/wireless-secrets.enc.yaml  # Restore from git
#   sops -d secrets.yaml.backup > secrets.yaml  # Restore from backup
#
# Build fails with "secret not found":
#   # Either:
#   sops.validateSopsFiles = false;         # Disable validation (dev mode)
#   # Or:
#   sops secrets.yaml                       # Create the missing secret
#
# Want to use SSH keys instead of age:
#   # Not recommended, but possible:
#   sops.age.sshKeyPaths = [ "/home/user/.ssh/id_rsa" ];
#   # Update .sops.yaml to use SSH public key instead of age
#
# Debugging secret values:
#   # WARNING: Prints secrets to terminal!
#   sudo cat /run/secrets/wireless_ken_5_password
#   sops -d ~/.nixosc/secrets/wireless-secrets.enc.yaml | grep ken_5
#
# ==============================================================================
# Security Considerations
# ==============================================================================
#
# 1. Key Protection:
#    - Never commit age private key to git
#    - Use 0600 permissions (user-only read/write)
#    - Backup offline (encrypted USB, password manager)
#    - Consider TPM/hardware security module for production
#
# 2. Secret Rotation:
#    - Rotate secrets periodically (90 days recommended)
#    - Rotate age keys after suspected compromise
#    - Keep old encrypted files for rollback
#
# 3. Access Control:
#    - Use minimal permissions (owner/group/mode)
#    - One secret per service when possible
#    - Avoid 0644 or world-readable permissions
#    - Review restartUnits (unintended service restarts?)
#
# 4. Audit Trail:
#    - All secret changes tracked in git (encrypted)
#    - Use meaningful commit messages
#    - Regular audits of sops.secrets definitions
#    - Monitor /run/secrets/ access logs
#
# 5. Multi-user Systems:
#    - Each user should have own age key
#    - Use home-manager for user-specific secrets
#    - System secrets (root) separate from user secrets
#    - Review group memberships carefully
#
# 6. Production Hardening:
#    - Enable validateSopsFiles = true
#    - Use TPM/LUKS for age key encryption
#    - Implement secret rotation automation
#    - Monitor failed decryption attempts
#    - Consider sealed secrets for Kubernetes
#
# 7. Backup & Recovery:
#    - Encrypted files in git = safe backup
#    - Age private key MUST be backed up separately
#    - Test recovery procedure regularly
#    - Document key recovery process
#
# ==============================================================================

