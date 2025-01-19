# modules/core/security/default.nix
# ==============================================================================
# Security Configuration
# ==============================================================================
# This configuration file manages all security-related settings including:
# - Core system security settings
# - GNOME Keyring integration
# - GnuPG configuration
# - Host blocking (hBlock)
#
# Key components:
# - PAM and sudo configuration
# - GNOME Keyring credential storage
# - GnuPG agent and SSH support
# - System-wide ad and malware domain blocking
#
# Author: Kenan Pelit
# ==============================================================================

{ config, lib, pkgs, ... }:
let
  cfg = config.services.hblock;
  updateScript = pkgs.writeShellScript "hblock-update" ''
    # Update ~/.config/hblock/hosts file for each user
    for USER_HOME in /home/*; do
      if [ -d "$USER_HOME" ]; then
        USER=$(basename "$USER_HOME")
        CONFIG_DIR="$USER_HOME/.config/hblock"
        HOSTS_FILE="$CONFIG_DIR/hosts"
        mkdir -p "$CONFIG_DIR"
        echo "# Base entries" > "$HOSTS_FILE"
        echo "localhost 127.0.0.1" >> "$HOSTS_FILE"
        echo "hay 127.0.0.2" >> "$HOSTS_FILE"
        echo "# hBlock entries (Updated: $(date))" >> "$HOSTS_FILE"
        ${pkgs.hblock}/bin/hblock -O - | while read DOMAIN; do
          if [[ $DOMAIN =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+[[:space:]]+(.+)$ ]]; then
            echo "''${BASH_REMATCH[1]} ''${BASH_REMATCH[1]}" >> "$HOSTS_FILE"
          fi
        done
        chown $USER:users "$HOSTS_FILE"
        chmod 644 "$HOSTS_FILE"
      fi
    done
  '';
in
{
  options.services.hblock = {
    enable = lib.mkEnableOption "hBlock service";
  };

  config = {
    # =============================================================================
    # Core Security Settings
    # =============================================================================
    security = {
      rtkit.enable = true;     # Realtime Kit for audio
      sudo.enable = true;      # Superuser permissions
      
      # PAM Service Configuration
      pam.services = {
        # Screen Locker Integration
        swaylock.enableGnomeKeyring = true;
        hyprlock.enableGnomeKeyring = true;
        login.enableGnomeKeyring = true;
      };
    };

    # =============================================================================
    # GNOME Keyring Configuration
    # =============================================================================
    services.gnome.gnome-keyring.enable = true;

    # =============================================================================
    # GnuPG Configuration
    # =============================================================================
    programs.gnupg = {
      agent = {
        enable = true;
        pinentryPackage = pkgs.pinentry-gnome3;
        enableSSHSupport = true;
      };
    };

    # =============================================================================
    # DBus Integration
    # =============================================================================
    services.dbus = {
      enable = true;
      packages = [ pkgs.gcr ];
    };

    # =============================================================================
    # hBlock Configuration
    # =============================================================================
    systemd = lib.mkIf cfg.enable {
      services.hblock = {
        description = "hBlock - Update user hosts files";
        after = [ "network-online.target" ];
        wants = [ "network-online.target" ];
        serviceConfig = {
          Type = "oneshot";
          ExecStart = updateScript;
          RemainAfterExit = true;
        };
      };

      timers.hblock = {
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = "daily";
          RandomizedDelaySec = 3600;
          Persistent = true;
        };
      };
    };

    environment = {
      sessionVariables = {
        GCR_PKCS11_MODULE = "${pkgs.gcr}/lib/pkcs11/gcr-pkcs11.so";
        GCR_PROVIDER_PRIORITY = "1";
      };

      etc."skel/.bashrc".text = lib.mkAfter ''
        export HOSTALIASES="$HOME/.config/hblock/hosts"
      '';

      systemPackages = with pkgs; [
        hblock
        gcr
      ];
    };
  };
}

