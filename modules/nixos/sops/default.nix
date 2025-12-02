# modules/core/sops/default.nix
# ==============================================================================
# SOPS Secrets Management Configuration (age backend)
# ==============================================================================
#
# Module:      modules/core/sops
# Purpose:     System-level encrypted secrets management with SOPS + age
# Author:      Kenan Pelit
# Created:     2025-09-03
# Modified:    2025-11-15
#
# Layers:
#   1) Encryption backend (age + sops)
#   2) Secret definitions (sops.secrets)
#   3) Filesystem layout (tmpfiles)
#   4) Tools (age, sops)
#   5) System bootstrap service (root-level diagnostics)
#   6) User bootstrap service (user-level diagnostics)
#
# Key points:
#   • Secrets live encrypted in git (YAML)
#   • Decryption happens on tmpfs at runtime
#   • Age only (no GPG)
#   • Build must NOT fail if secrets are missing (initial setup)
#
# ==============================================================================

{ config, lib, pkgs, inputs, ... }:

let
  username = config.my.user.name or "kenan";
  inherit (lib) mkIf;

  # ---------------------------------------------------------------------------
  # Paths (single source of truth)
  # ---------------------------------------------------------------------------
  homeDir        = "/home/${username}";
  sopsDir        = "${homeDir}/.nixosc/secrets";
  sopsAgeKeyDir  = "${homeDir}/.config/sops/age";
  sopsAgeKeyFile = "${sopsAgeKeyDir}/keys.txt";

  # One encrypted file per logical category
  wirelessSecretsFile = "${sopsDir}/wireless-secrets.enc.yaml";

  # Avoid build failures when secrets are not yet created
  secretsFileExists = builtins.pathExists wirelessSecretsFile;

in
{
  # ============================================================================
  # Import sops-nix
  # ============================================================================
  imports = [ inputs.sops-nix.nixosModules.sops ];

  # ============================================================================
  # Core SOPS configuration
  # ============================================================================
  sops = {
    defaultSopsFile = wirelessSecretsFile;

    age = {
      keyFile     = sopsAgeKeyFile;
      sshKeyPaths = [ ];
    };

    # We do not want evaluation to fail if the file does not exist yet.
    validateSopsFiles = false;

    # GPG fully disabled; we use age only.
    gnupg.sshKeyPaths = [ ];

    # -------------------------------------------------------------------------
    # Secrets (wireless example)
    # -------------------------------------------------------------------------
    secrets = mkIf secretsFileExists {
      # Wi-Fi: Ken_5 (5 GHz)
      "wireless_ken_5_password" = {
        sopsFile = wirelessSecretsFile;
        key      = "ken_5_password";
        owner    = "root";
        group    = "networkmanager";
        mode     = "0640";
        restartUnits = [ "NetworkManager.service" ];
      };

      # Wi-Fi: Ken_2_4 (2.4 GHz)
      "wireless_ken_2_4_password" = {
        sopsFile = wirelessSecretsFile;
        key      = "ken_2_4_password";
        owner    = "root";
        group    = "networkmanager";
        mode     = "0640";
        restartUnits = [ "NetworkManager.service" ];
      };

      # Add more secrets here as needed (mail, VPN, API tokens, etc.)
    };
  };

  # ============================================================================
  # Directory layout & permissions (tmpfiles)
  # ============================================================================
  systemd.tmpfiles.rules = [
    # Repo-level secrets dir
    "d ${homeDir}/.nixosc           0755 ${username} users -"
    "d ${sopsDir}                  0750 ${username} users -"

    # SOPS age key location
    "d ${homeDir}/.config          0755 ${username} users -"
    "d ${homeDir}/.config/sops     0750 ${username} users -"
    "d ${sopsAgeKeyDir}            0700 ${username} users -"
  ];

  # ============================================================================
  # Tools
  # ============================================================================
  environment.systemPackages = with pkgs; [
    age
    sops
    # jq
    # yq-go
  ];

  # ============================================================================
  # System-level diagnostics service (root)
  # ============================================================================
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

      # Ensure age key directory exists (root fixes perms, user owns content)
      mkdir -p ${sopsAgeKeyDir}
      chown ${username}:users ${sopsAgeKeyDir}
      chmod 700 ${sopsAgeKeyDir}

      echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
      echo "[SOPS][system] Diagnostics started"

      # Age key presence
      if [ ! -f "${sopsAgeKeyFile}" ]; then
        echo "[SOPS][system] ⚠ Age key not found"
        echo "[SOPS][system]    Expected: ${sopsAgeKeyFile}"
        echo ""
        echo "Setup:"
        echo "  1) Generate key:"
        echo "       age-keygen -o ${sopsAgeKeyFile}"
        echo "  2) Extract public key:"
        echo "       grep 'public key:' ${sopsAgeKeyFile}"
        echo "  3) Configure .sops.yaml with that public key."
      else
        echo "[SOPS][system] ✅ Age key found: ${sopsAgeKeyFile}"

        if grep -q '^AGE-SECRET-KEY-' "${sopsAgeKeyFile}"; then
          echo "[SOPS][system] ✅ Age key format OK"
        else
          echo "[SOPS][system] ⚠ Age key format suspicious (should start with AGE-SECRET-KEY-)"
        fi

        KEY_PERMS=$(stat -c %a "${sopsAgeKeyFile}")
        if [ "$KEY_PERMS" = "600" ]; then
          echo "[SOPS][system] ✅ Permissions OK (600)"
        else
          echo "[SOPS][system] ⚠ Permissions are $KEY_PERMS (expected 600)"
          echo "[SOPS][system]    Fix: chmod 600 ${sopsAgeKeyFile}"
        fi
      fi

      # Secrets file presence
      if [ -f "${wirelessSecretsFile}" ]; then
        echo "[SOPS][system] ✅ Wireless secrets file present: ${wirelessSecretsFile}"
        if grep -q 'ENC\[' "${wirelessSecretsFile}"; then
          echo "[SOPS][system] ✅ Appears encrypted (ENC[..] markers found)"
        else
          echo "[SOPS][system] ⚠ File does not look encrypted (no ENC[..] markers)"
        fi
      else
        echo "[SOPS][system] ℹ No wireless secrets file yet:"
        echo "[SOPS][system]    ${wirelessSecretsFile}"
        echo "[SOPS][system]    This is normal on initial setup."
      fi

      echo "[SOPS][system] Done."
      echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    '';
  };

  # ============================================================================
  # User-level diagnostics service (unprivileged)
  # ============================================================================
  # NOTE: Previously this unit was broken by ProtectSystem=strict
  # because it tried to mkdir in $HOME (read-only). Here we relax it
  # to "full" and explicitly allow homeDir as writable.
  # ============================================================================
  systemd.user.services.sops-user-bootstrap = {
    description = "SOPS secrets activation (user-level diagnostics)";
    wantedBy    = [ "default.target" ];
    after       = [ "graphical-session.target" ];

    serviceConfig = {
      Type            = "oneshot";
      RemainAfterExit = true;
      PrivateTmp      = true;
      NoNewPrivileges = true;
      # ProtectSystem and other hardening defaults are defined globally
      # in modules/core/services; do NOT override them here.
      ReadWritePaths  = [ homeDir "/tmp" ];
    };

    script = ''
      set -euo pipefail

      mkdir -p ${sopsAgeKeyDir}

      echo "[SOPS][user] Bootstrap started"

      if [ -f "${sopsAgeKeyFile}" ]; then
        echo "[SOPS][user] ✅ Age key present at ${sopsAgeKeyFile}"
        PUB_KEY=$(grep 'public key:' "${sopsAgeKeyFile}" | cut -d: -f2- | tr -d ' ' || echo "unknown")
        echo "[SOPS][user] 🔑 Public key: $PUB_KEY"
      else
        echo "[SOPS][user] ⚠ No age key at ${sopsAgeKeyFile}"
        echo "[SOPS][user]   Generate with:"
        echo "[SOPS][user]     age-keygen -o ${sopsAgeKeyFile}"
      fi

      touch /tmp/sops-user-ready
      echo "[SOPS][user] 📡 Ready signal: /tmp/sops-user-ready"
    '';
  };
}

