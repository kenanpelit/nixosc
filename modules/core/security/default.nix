# modules/core/security/default.nix
# ==============================================================================
# Security & Hardening Configuration - Defense in Depth
# ==============================================================================
#
# Module:      modules/core/security
# Purpose:     Centralized security configuration and hardening
# Author:      Kenan Pelit
# Created:     2025-10-09
# Modified:    2025-10-18
#
# Architecture:
#   Firewall → Authentication → Access Control → Audit → SSH → Ad Blocking
#
# Security Layers:
#   1. Network Firewall     - Packet filtering, DoS mitigation
#   2. PAM/Polkit          - Authentication and authorization
#   3. AppArmor            - Mandatory access control (MAC)
#   4. Audit Logging       - System activity monitoring
#   5. SSH Hardening       - Secure remote access
#   6. DNS Blocking        - Ad/tracker filtering (hBlock)
#
# Design Principles:
#   • Single Authority - All firewall ports defined HERE only
#   • Use NixOS Framework - Don't fight the framework, extend it
#   • Minimal Custom Rules - Only what NixOS doesn't provide
#   • Defense in Depth - Multiple security layers
#   • Fail Secure - Default deny, explicit allow
#
# Module Boundaries:
#   ✓ Firewall configuration         (THIS MODULE)
#   ✓ PAM/Polkit authentication      (THIS MODULE)
#   ✓ AppArmor MAC                   (THIS MODULE)
#   ✓ Audit logging                  (THIS MODULE)
#   ✓ SSH client config              (THIS MODULE)
#   ✗ SSH daemon config              (networking module)
#   ✗ User authentication            (account module)
#   ✗ GNOME Keyring daemon           (display/services module)
#
# ==============================================================================

{ lib, pkgs, config, ... }:

let
  inherit (lib) mkEnableOption mkIf mkAfter;

  # ----------------------------------------------------------------------------
  # Port Configuration (Single Source of Truth)
  # ----------------------------------------------------------------------------
  # All open ports declared here - no duplication in other modules
  
  transmissionWebPort  = 9091;    # Transmission Web UI (HTTP)
  transmissionPeerPort = 51413;   # BitTorrent peer connections (TCP/UDP)

  # ----------------------------------------------------------------------------
  # hBlock Update Script - Per-User DNS Blocking
  # ----------------------------------------------------------------------------
  # Updates HOSTALIASES file for each user with blocked domains
  # Uses hBlock to fetch and merge ad/tracker blocklists
  
  hblockUpdateScript = pkgs.writeShellScript "hblock-update" ''
    #!${pkgs.bash}/bin/bash
    set -euo pipefail

    # Iterate over all user home directories
    for USER_HOME in /home/*; do
      if [ -d "$USER_HOME" ]; then
        USER="$(basename "$USER_HOME")"
        CONFIG_DIR="$USER_HOME/.config/hblock"
        HOSTS_FILE="$CONFIG_DIR/hosts"
        
        # Create config directory if missing
        mkdir -p "$CONFIG_DIR"

        # Generate hosts file with base entries + blocked domains
        {
          echo "# Base entries"
          echo "localhost 127.0.0.1"
          echo "hay 127.0.0.2"
          echo "# hBlock entries (Updated: $(date))"

          # Fetch blocklist and convert to HOSTALIASES format
          # hBlock format: 0.0.0.0 domain.com → domain.com domain.com
          ${pkgs.hblock}/bin/hblock -O - | while read -r LINE; do
            if [[ $LINE =~ ^([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)[[:space:]]+(.+)$ ]]; then
              dom="''${BASH_REMATCH[2]}"
              echo "''${dom} ''${dom}"  # HOSTALIASES format
            fi
          done
        } > "$HOSTS_FILE"

        # Set proper ownership and permissions
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
    # ==========================================================================
    # Network Firewall (Layer 1: Packet Filtering)
    # ==========================================================================
    # NixOS firewall with custom hardening rules
    # Note: networking/default.nix enables firewall, we only configure ports
    
    networking.firewall = {
      # ---- Basic Hardening ----
      allowPing = false;              # Prevent ICMP ping (stealth mode)
      rejectPackets = true;           # Send RST/ICMP unreachable (vs silent drop)
      logReversePathDrops = true;     # Log spoofed packets (RPF check)
      checkReversePath = "loose";     # Reverse path filtering (loose mode)

      # ---- Trusted Interfaces ----
      # Note: VPN interfaces (wg+, tun+) defined in networking module
      # trustedInterfaces = [ "wg+" "tun+" ];

      # ---- TCP Ports (Allowed Inbound) ----
      allowedTCPPorts = [
        transmissionWebPort    # Transmission Web UI (9091)
        1401                   # Custom service
      ];

      # ---- UDP Ports (Allowed Inbound) ----
      allowedUDPPorts = [
        1194 1195 1196        # OpenVPN standard ports
        1401                  # Custom service
        51820                 # WireGuard VPN
      ];

      # ---- Port Ranges (Transmission Peer) ----
      # BitTorrent peer connections (both TCP and UDP)
      allowedTCPPortRanges = [
        { from = transmissionPeerPort; to = transmissionPeerPort; }
      ];
      allowedUDPPortRanges = [
        { from = transmissionPeerPort; to = transmissionPeerPort; }
      ];

      # ------------------------------------------------------------------------
      # Custom Hardening Rules (Beyond NixOS Defaults)
      # ------------------------------------------------------------------------
      # Additional iptables rules for advanced protection
      
      extraCommands = ''
        # ---- DoS Mitigation: SYN Flood Protection ----
        # Limit new TCP connections (SYN packets)
        # Rate: 1 connection/second, burst: 3 connections
        iptables -A INPUT -p tcp --syn -m limit --limit 1/s --limit-burst 3 -j ACCEPT
        
        # Drop excessive connections from single IP
        # Max 15 concurrent connections per IP
        iptables -A INPUT -p tcp --syn -m connlimit --connlimit-above 15 -j REJECT --reject-with tcp-reset

        # ---- Drop Invalid Packets ----
        # Drop packets that don't match any known connection state
        iptables -A INPUT -m conntrack --ctstate INVALID -j DROP

        # ---- Port Scan Detection & Prevention ----
        # Drop common port scan patterns (null scan, xmas scan, etc.)
        iptables -A INPUT -p tcp --tcp-flags ALL NONE -j DROP                        # NULL scan
        iptables -A INPUT -p tcp --tcp-flags ALL ALL -j DROP                         # XMAS scan
        iptables -A INPUT -p tcp --tcp-flags ALL FIN,URG,PSH -j DROP                 # FIN/URG/PSH scan
        iptables -A INPUT -p tcp --tcp-flags ALL SYN,RST,ACK,FIN,URG -j DROP         # Combined scan
        iptables -A INPUT -p tcp --tcp-flags SYN,FIN SYN,FIN -j DROP                 # SYN/FIN scan
        iptables -A INPUT -p tcp --tcp-flags SYN,RST SYN,RST -j DROP                 # SYN/RST scan

        # ---- ICMP Rate Limiting ----
        # Already blocked via allowPing=false, but add extra rate limiting
        # Allow 1 ping per second, burst of 1
        iptables -A INPUT -p icmp -m limit --limit 1/s --limit-burst 1 -j ACCEPT
        iptables -A INPUT -p icmp -j DROP
      '';

      # Cleanup rules on firewall stop
      extraStopCommands = ''
        # Flush and remove custom chains
        iptables -F nixos-fw-custom 2>/dev/null || true
        iptables -X nixos-fw-custom 2>/dev/null || true
      '';
    };

    # ==========================================================================
    # Authentication & Authorization (Layer 2: PAM/Polkit)
    # ==========================================================================
    
    # ---- GNOME Keyring Integration ----
    # System-wide password storage daemon
    # Note: Service enabled here, daemon managed in services module
    services.gnome.gnome-keyring.enable = true;

    # ---- Core Security Services ----
    security = {
      rtkit.enable = true;      # RealtimeKit (audio priority)
      sudo.enable = true;       # Sudo privilege escalation
      polkit.enable = true;     # PolicyKit authorization framework

      # ---- AppArmor Mandatory Access Control ----
      # Linux Security Module for process isolation
      apparmor = {
        enable = true;
        packages = with pkgs; [
          apparmor-profiles    # Default profiles (browsers, etc.)
          apparmor-utils       # aa-enforce, aa-complain, aa-logprof
        ];
      };

      # ---- System Audit Daemon ----
      # Logs security-relevant system calls and events
      auditd.enable = true;

      # ---- Kernel Hardening ----
      allowUserNamespaces = true;    # Required for containers (Podman)
      protectKernelImage = true;     # Prevent kernel module loading

      # ---- PAM GNOME Keyring Integration ----
      # Unlock keyring automatically on login
      pam.services = {
        gdm.enableGnomeKeyring = true;           # GDM login
        gdm-password.enableGnomeKeyring = true;  # Password authentication
        login.enableGnomeKeyring = true;         # Console login
      };
    };

    # ---- D-Bus Service Registration ----
    # Register GNOME security services with D-Bus
    services.dbus.packages = mkAfter [ 
      pkgs.gcr              # Certificate/key management
      pkgs.gnome-keyring    # Password storage
    ];

    # ==========================================================================
    # Audit Logging (Layer 3: Activity Monitoring)
    # ==========================================================================
    # Linux Audit Framework configuration
    
    environment.etc = {
      # ---- Main Auditd Configuration ----
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

      # ---- Filter Configuration ----
      # Suppress warning about missing filter.conf
      "audit/filter.conf" = {
        mode = "0644";
        text = "# empty\n";
      };

      # ---- Audit Rules (Single Source) ----
      # Preferred location: rules.d/ (not audit.rules)
      "audit/rules.d/99-nixos.rules".text = ''
        # Remove all previous rules
        -D
        
        # Buffer size (16384 = workstation, 32768 = server)
        -b 16384
        
        # Rate limit (0 = unlimited, use 100-500 for production)
        -r 0

        # ----------------------------------------------------------------------
        # File Watches (Who Modified Critical Files)
        # ----------------------------------------------------------------------
        -w /etc/passwd -p wa -k passwd_changes           # User database
        -w /etc/shadow -p wa -k shadow_changes           # Password hashes
        -w /etc/group -p wa -k group_changes             # Group database
        -w /etc/gshadow -p wa -k gshadow_changes         # Group passwords
        -w /etc/sudoers -p wa -k sudoers_changes         # Sudo config
        -w /etc/sudoers.d/ -p wa -k sudoers_changes      # Sudo drop-in files
        -w /etc/ssh/sshd_config -p wa -k sshd_config     # SSH daemon config

        # ----------------------------------------------------------------------
        # Syscall Auditing (Minimal for Workstation)
        # ----------------------------------------------------------------------
        # Track root commands executed by normal users
        # Catches privilege escalation attempts
        -a always,exit -F arch=b64 -S execve,execveat -F euid=0 -F auid>=1000 -F auid!=4294967295 -k exec_root

        # Track UID/GID changes (privilege changes)
        -a always,exit -F arch=b64 -S setuid,setresgid,setfsuid,setfsgid -k id_change

        # ----------------------------------------------------------------------
        # Make Rules Immutable (Uncomment for Production)
        # ----------------------------------------------------------------------
        # Prevents rule changes without reboot (security hardening)
        # -e 2
      '';
    };

    # ==========================================================================
    # Systemd Services - Security Daemons
    # ==========================================================================
    
    systemd.services = {
      # ---- Auditd Rule Loading ----
      # Override default auditd to load rules from rules.d/
      auditd = {
        preStart = ''
          set -eu
          PATH="${lib.makeBinPath [ pkgs.coreutils pkgs.findutils pkgs.gawk pkgs.gnugrep pkgs.audit ]}"

          # Load all .rules files from rules.d/ directory
          if [ -d /etc/audit/rules.d ] && ls /etc/audit/rules.d/*.rules >/dev/null 2>&1; then
            # Concatenate all rules files in sorted order
            TMP="$(mktemp)"
            find /etc/audit/rules.d -maxdepth 1 -type f -name '*.rules' -print0 \
              | sort -z \
              | xargs -0 cat -- >> "$TMP"
            
            # Clear existing rules and load new ones
            ${pkgs.audit}/sbin/auditctl -D 2>/dev/null || true
            ${pkgs.audit}/sbin/auditctl -R "$TMP" || {
              echo "Warning: Failed to load audit rules"
              cat "$TMP"
            }
            rm -f "$TMP"
          fi
        '';
      };

      # ---- hBlock Service (DNS Blocking) ----
      # Updates user hosts files with ad/tracker blocklists
      hblock = mkIf config.services.hblock.enable {
        description = "hBlock - Update user hosts files with blocklists";
        after = [ "network-online.target" ];
        wants = [ "network-online.target" ];
        serviceConfig = {
          Type = "oneshot";
          ExecStart = hblockUpdateScript;
          RemainAfterExit = true;
        };
      };
    };

    # ---- hBlock Timer (Daily Updates) ----
    systemd.timers.hblock = mkIf config.services.hblock.enable {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "daily";              # Run once per day
        RandomizedDelaySec = 3600;         # Random delay up to 1 hour
        Persistent = true;                 # Run missed timers on boot
      };
    };

    # ==========================================================================
    # SSH Client Configuration (Layer 4: Secure Remote Access)
    # ==========================================================================
    
    programs.ssh = {
      # Disable SSH agent (using GPG agent instead)
      startAgent = false;
      
      # Disable graphical password prompts
      enableAskPassword = false;

      # Global SSH client options
      extraConfig = ''
        Host *
          # Keep connections alive (prevent timeout)
          ServerAliveInterval 60
          ServerAliveCountMax 2
          TCPKeepAlive yes
          
          # Use ASSH proxy for connection management
          ProxyCommand ${pkgs.assh}/bin/assh connect --port=%p %h
      '';
    };

    # ==========================================================================
    # Environment Configuration
    # ==========================================================================
    
    environment = {
      # ---- hBlock Integration for New Users ----
      # Add HOSTALIASES to default shell config
      etc."skel/.bashrc".text = mkAfter ''
        export HOSTALIASES="$HOME/.config/hblock/hosts"
      '';

      # ---- Security Packages ----
      systemPackages = with pkgs; [
        polkit_gnome         # PolicyKit GNOME agent (GUI authorization)
        assh                 # Advanced SSH config manager
        hblock               # DNS ad/tracker blocker
        audit                # Audit tools (auditctl, ausearch, aureport)
      ];

      # ---- Shell Aliases (Security Tools) ----
      shellAliases = {
        # SSH management
        assh               = "${pkgs.assh}/bin/assh";
        sshconfig          = "${pkgs.assh}/bin/assh config build > ~/.ssh/config";
        sshtest            = "ssh -o ConnectTimeout=5 -o BatchMode=yes";
        
        # hBlock management
        hblock-update-now  = "sudo ${hblockUpdateScript}";
        
        # Audit log analysis
        audit-summary      = "sudo aureport --summary";      # Summary report
        audit-failed       = "sudo aureport --failed";       # Failed events
        audit-search       = "sudo ausearch -i";             # Interactive search
      };

      # ---- Environment Variables ----
      variables = {
        ASSH_CONFIG = "$HOME/.ssh/assh.yml";   # ASSH config location
      };
    };
  };
}

# ==============================================================================
# Security Best Practices
# ==============================================================================
#
# 1. Firewall:
#    - All ports declared in THIS module only
#    - Use NixOS firewall, extend with extraCommands
#    - Test: sudo iptables -L -v -n
#
# 2. AppArmor:
#    - Profiles in /etc/apparmor.d/
#    - Check status: sudo aa-status
#    - Enforce profile: sudo aa-enforce /path/to/profile
#
# 3. Audit:
#    - View logs: sudo ausearch -i
#    - Summary: sudo aureport --summary
#    - Search failed logins: sudo ausearch -m USER_LOGIN --failed
#
# 4. SSH:
#    - Use ASSH for complex configurations
#    - Config: ~/.ssh/assh.yml
#    - Build: assh config build > ~/.ssh/config
#
# 5. hBlock:
#    - Manual update: hblock-update-now
#    - Check file: cat ~/.config/hblock/hosts
#    - Test: ping blocked-domain.com (should fail)
#
# ==============================================================================
# Troubleshooting
# ==============================================================================
#
# Firewall blocking legitimate traffic:
#   sudo iptables -L -v -n  # Check rules
#   journalctl -k           # Check kernel logs for dropped packets
#
# AppArmor denials:
#   sudo journalctl -xe | grep apparmor
#   sudo aa-complain /path/to/profile  # Switch to complain mode
#
# Audit logs too verbose:
#   Edit /etc/audit/rules.d/99-nixos.rules
#   Increase rate limit: -r 100
#
# SSH connection issues:
#   ssh -vvv host  # Verbose debug
#   Check ProxyCommand: assh connect --port=22 host
#
# ==============================================================================
