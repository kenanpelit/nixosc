# modules/core/security/default.nix
# ==============================================================================
# Security & Hardening Configuration Module
# ==============================================================================
#
# Module: modules/core/security
# Author: Kenan Pelit
# Date:   2025-10-09
#
# Purpose: Centralized security configuration
#
# Scope:
#   - Firewall rules and port management (single authority)
#   - PAM/Polkit authentication
#   - AppArmor mandatory access control
#   - Audit logging (auditd + simplified rules)
#   - SSH client configuration
#   - hBlock domain blocking (per-user HOSTALIASES)
#
# Design Principles:
#   1. Single Authority: Firewall ports defined ONLY here
#   2. Use NixOS Firewall: Don't fight the framework, use it
#   3. Minimal Custom Rules: Only what NixOS doesn't provide
#   4. No Duplicate Rules: One source of truth
#
# ==============================================================================

{ lib, pkgs, config, ... }:

let
  inherit (lib) mkEnableOption mkIf mkAfter;

  # --------------------------------------------------------------------------
  # Configurable Port Settings
  # --------------------------------------------------------------------------
  transmissionWebPort  = 9091;   # Transmission Web UI
  transmissionPeerPort = 51413;  # Transmission peer port (TCP/UDP)

  # --------------------------------------------------------------------------
  # hBlock Update Script
  # --------------------------------------------------------------------------
  hblockUpdateScript = pkgs.writeShellScript "hblock-update" ''
    #!${pkgs.bash}/bin/bash
    set -euo pipefail

    for USER_HOME in /home/*; do
      if [ -d "$USER_HOME" ]; then
        USER="$(basename "$USER_HOME")"
        CONFIG_DIR="$USER_HOME/.config/hblock"
        HOSTS_FILE="$CONFIG_DIR/hosts"
        mkdir -p "$CONFIG_DIR"

        {
          echo "# Base entries"
          echo "localhost 127.0.0.1"
          echo "hay 127.0.0.2"
          echo "# hBlock entries (Updated: $(date))"

          ${pkgs.hblock}/bin/hblock -O - | while read -r LINE; do
            if [[ $LINE =~ ^([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)[[:space:]]+(.+)$ ]]; then
              dom="''${BASH_REMATCH[2]}"
              echo "''${dom} ''${dom}"
            fi
          done
        } > "$HOSTS_FILE"

        chown "$USER:users" "$HOSTS_FILE"
        chmod 0644 "$HOSTS_FILE"
      fi
    done
  '';
in
{
  # ============================================================================
  # Module Options
  # ============================================================================
  options.services.hblock.enable =
    mkEnableOption "hBlock per-user HOSTALIASES with daily auto-update";

  # ============================================================================
  # Security Configuration
  # ============================================================================
  config = {
    # --------------------------------------------------------------------------
    # Firewall (NixOS Native)
    # --------------------------------------------------------------------------
    # NOTE: networking/default.nix already has firewall.enable = true
    # We only define ports here (single authority)
    
    networking.firewall = {
      # Basic hardening
      allowPing = false;
      rejectPackets = true;
      logReversePathDrops = true;
      checkReversePath = "loose";

      # Tunnel interfaces (defined in networking/default.nix already)
      # trustedInterfaces = [ "wg+" "tun+" ];

      # Open Ports (all declared here)
      allowedTCPPorts = [
        transmissionWebPort    # Transmission Web UI
        1401                   # Custom service
      ];

      allowedUDPPorts = [
        1194 1195 1196        # OpenVPN
        1401                  # Custom service
        51820                 # WireGuard
      ];

      # Transmission peer port
      allowedTCPPortRanges = [
        { from = transmissionPeerPort; to = transmissionPeerPort; }
      ];
      allowedUDPPortRanges = [
        { from = transmissionPeerPort; to = transmissionPeerPort; }
      ];

      # --------------------------------------------------------------------------
      # Additional Hardening Rules (what NixOS doesn't do by default)
      # --------------------------------------------------------------------------
      extraCommands = ''
        # DoS mitigation: SYN flood protection
        iptables -A INPUT -p tcp --syn -m limit --limit 1/s --limit-burst 3 -j ACCEPT
        iptables -A INPUT -p tcp --syn -m connlimit --connlimit-above 15 -j REJECT --reject-with tcp-reset

        # Drop invalid packets
        iptables -A INPUT -m conntrack --ctstate INVALID -j DROP

        # Drop port scan patterns
        iptables -A INPUT -p tcp --tcp-flags ALL NONE -j DROP
        iptables -A INPUT -p tcp --tcp-flags ALL ALL -j DROP
        iptables -A INPUT -p tcp --tcp-flags ALL FIN,URG,PSH -j DROP
        iptables -A INPUT -p tcp --tcp-flags ALL SYN,RST,ACK,FIN,URG -j DROP
        iptables -A INPUT -p tcp --tcp-flags SYN,FIN SYN,FIN -j DROP
        iptables -A INPUT -p tcp --tcp-flags SYN,RST SYN,RST -j DROP

        # ICMP rate limiting (already disabled via allowPing=false, but extra safety)
        iptables -A INPUT -p icmp -m limit --limit 1/s --limit-burst 1 -j ACCEPT
        iptables -A INPUT -p icmp -j DROP
      '';

      # Cleanup on stop
      extraStopCommands = ''
        # Flush custom chains
        iptables -F nixos-fw-custom 2>/dev/null || true
        iptables -X nixos-fw-custom 2>/dev/null || true
      '';
    };

    # --------------------------------------------------------------------------
    # System Security Services
    # --------------------------------------------------------------------------
    security = {
      rtkit.enable = true;
      sudo.enable = true;
      polkit.enable = true;

      apparmor = {
        enable = true;
        packages = with pkgs; [ apparmor-profiles apparmor-utils ];
      };

      auditd.enable = true;

      allowUserNamespaces = true;
      protectKernelImage = true;

      # PAM: GNOME Keyring integration
      pam.services = {
        gdm.enableGnomeKeyring = true;
        gdm-password.enableGnomeKeyring = true;
        login.enableGnomeKeyring = true;
      };
    };

    # DBus schemas for gcr/gnome-keyring
    services.dbus.packages = mkAfter [ pkgs.gcr pkgs.gnome-keyring ];

    # --------------------------------------------------------------------------
    # Auditd Configuration
    # --------------------------------------------------------------------------
    environment.etc = {
      # Main auditd config
      "audit/auditd.conf".text = ''
        log_file = /var/log/audit/audit.log
        log_format = RAW
        flush = incremental_async
        freq = 50
        priority_boost = 4
        overflow_action = SYSLOG
        max_log_file = 50
        num_logs = 5
        max_log_file_action = ROTATE
        name_format = HOSTNAME
      '';

      # Suppress filter.conf warning
      "audit/filter.conf" = {
        mode = "0644";
        text = "# empty\n";
      };

      # Audit rules (SINGLE source - rules.d is preferred over audit.rules)
      "audit/rules.d/99-nixos.rules".text = ''
        # Remove all previous rules
        -D
        
        # Buffer size (16384 = good for workstation)
        -b 16384
        
        # Rate limit (0 = unlimited, adjust if needed)
        -r 0

        # --------------------------------------------------------------------------
        # File Watches
        # --------------------------------------------------------------------------
        -w /etc/passwd -p wa -k passwd_changes
        -w /etc/shadow -p wa -k shadow_changes
        -w /etc/group -p wa -k group_changes
        -w /etc/gshadow -p wa -k gshadow_changes
        -w /etc/sudoers -p wa -k sudoers_changes
        -w /etc/sudoers.d/ -p wa -k sudoers_changes
        -w /etc/ssh/sshd_config -p wa -k sshd_config

        # --------------------------------------------------------------------------
        # Syscall Auditing (minimal for workstation)
        # --------------------------------------------------------------------------
        # Root commands executed by regular users
        -a always,exit -F arch=b64 -S execve,execveat -F euid=0 -F auid>=1000 -F auid!=4294967295 -k exec_root

        # UID/GID changes
        -a always,exit -F arch=b64 -S setuid,setresgid,setfsuid,setfsgid -k id_change

        # --------------------------------------------------------------------------
        # Make rules immutable (optional - uncomment for production)
        # --------------------------------------------------------------------------
        # -e 2
      '';
    };

    # --------------------------------------------------------------------------
    # Systemd Services
    # --------------------------------------------------------------------------
    systemd.services = {
      # Override auditd to load rules on start
      auditd = {
        preStart = ''
          set -eu
          PATH="${lib.makeBinPath [ pkgs.coreutils pkgs.findutils pkgs.gawk pkgs.gnugrep pkgs.audit ]}"

          # Load rules from rules.d directory
          if [ -d /etc/audit/rules.d ] && ls /etc/audit/rules.d/*.rules >/dev/null 2>&1; then
            TMP="$(mktemp)"
            find /etc/audit/rules.d -maxdepth 1 -type f -name '*.rules' -print0 \
              | sort -z \
              | xargs -0 cat -- >> "$TMP"
            
            ${pkgs.audit}/sbin/auditctl -D 2>/dev/null || true
            ${pkgs.audit}/sbin/auditctl -R "$TMP" || {
              echo "Warning: Failed to load audit rules"
              cat "$TMP"
            }
            rm -f "$TMP"
          fi
        '';
      };

      # hBlock service (optional)
      hblock = mkIf config.services.hblock.enable {
        description = "hBlock - Update user hosts files";
        after = [ "network-online.target" ];
        wants = [ "network-online.target" ];
        serviceConfig = {
          Type = "oneshot";
          ExecStart = hblockUpdateScript;
          RemainAfterExit = true;
        };
      };
    };

    # hBlock timer
    systemd.timers.hblock = mkIf config.services.hblock.enable {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "daily";
        RandomizedDelaySec = 3600;
        Persistent = true;
      };
    };

    # --------------------------------------------------------------------------
    # SSH Client Configuration
    # --------------------------------------------------------------------------
    programs.ssh = {
      startAgent = false;
      enableAskPassword = false;

      extraConfig = ''
        Host *
          ServerAliveInterval 60
          ServerAliveCountMax 2
          TCPKeepAlive yes
          ProxyCommand ${pkgs.assh}/bin/assh connect --port=%p %h
      '';
    };

    # --------------------------------------------------------------------------
    # Environment & Packages
    # --------------------------------------------------------------------------
    environment = {
      # hBlock integration for new users
      etc."skel/.bashrc".text = mkAfter ''
        export HOSTALIASES="$HOME/.config/hblock/hosts"
      '';

      systemPackages = with pkgs; [
        polkit_gnome
        assh
        hblock
        audit          # auditctl, ausearch, aureport
      ];

      shellAliases = {
        # SSH
        assh               = "${pkgs.assh}/bin/assh";
        sshconfig          = "${pkgs.assh}/bin/assh config build > ~/.ssh/config";
        sshtest            = "ssh -o ConnectTimeout=5 -o BatchMode=yes";
        
        # hBlock
        hblock-update-now  = "sudo ${hblockUpdateScript}";
        
        # Audit
        audit-summary      = "sudo aureport --summary";
        audit-failed       = "sudo aureport --failed";
        audit-search       = "sudo ausearch -i";
      };

      variables = {
        ASSH_CONFIG = "$HOME/.ssh/assh.yml";
      };
    };
  };
}
