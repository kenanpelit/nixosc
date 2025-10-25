# modules/core/security/default.nix
# ==============================================================================
# Security & Hardening Configuration - Defense in Depth
# ==============================================================================
#
# Module:      modules/core/security
# Purpose:     Centralized security configuration and hardening
# Author:      Kenan Pelit
# Created:     2025-10-09
# Modified:    2025-10-25
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
#   • SSH Friendly - Special handling for SSH connections and multiplexing
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
# Recent Changes (2025-10-25):
#   • Fixed SSH connection issues with ControlMaster/multiplexing
#   • Added SSH exception to DoS rate limiting
#   • Increased rate limits to be more tolerant (5/s, burst 10)
#   • Increased connection limit from 15 to 50 per IP
#   • Added detailed comments about SSH handling
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
      # IMPORTANT: SSH connections are exempted from rate limiting to prevent
      # issues with SSH multiplexing (ControlMaster) and connection reuse
      
      extraCommands = ''
        # ====================================================================
        # SSH Exception Rules (CRITICAL - Must be first)
        # ====================================================================
        # SSH connections need special handling because:
        # 1. SSH ControlMaster creates multiple channels over one connection
        # 2. Connection reuse can trigger rate limits
        # 3. Aggressive limits break SSH multiplexing (rwindow 0 issue)
        # 
        # Solution: Allow SSH traffic BEFORE applying rate limits
        
        # Allow established SSH connections (outbound client connections)
        iptables -A INPUT -p tcp --sport 22 -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
        iptables -A INPUT -p tcp --sport 36499 -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
        
        # Allow SSH daemon connections (if running SSH server)
        iptables -A INPUT -p tcp --dport 22 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT
        
        # Allow custom SSH ports (add your custom ports here)
        # iptables -A INPUT -p tcp --dport XXXXX -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT

        # ====================================================================
        # DoS Mitigation: SYN Flood Protection
        # ====================================================================
        # Applies to all NON-SSH connections (SSH already handled above)
        # 
        # Previous settings (TOO AGGRESSIVE):
        #   - Rate: 1/s, burst: 3  → Caused SSH multiplexing issues
        #   - Connlimit: 15        → Too restrictive for modern apps
        # 
        # New settings (BALANCED):
        #   - Rate: 5/s, burst: 10 → Allows SSH channels + normal usage
        #   - Connlimit: 50        → Reasonable for web browsers, dev tools
        
        # Limit new TCP connections (SYN packets)
        # Rate: 5 connections/second, burst: 10 connections
        iptables -A INPUT -p tcp --syn -m limit --limit 5/s --limit-burst 10 -j ACCEPT
        
        # Drop excessive connections from single IP
        # Max 50 concurrent connections per IP (increased from 15)
        iptables -A INPUT -p tcp --syn -m connlimit --connlimit-above 50 -j REJECT --reject-with tcp-reset

        # ====================================================================
        # Invalid Packet Filtering
        # ====================================================================
        # Drop packets that don't match any known connection state
        # This catches malformed packets and certain attack patterns
        iptables -A INPUT -m conntrack --ctstate INVALID -j DROP

        # ====================================================================
        # Port Scan Detection & Prevention
        # ====================================================================
        # Drop common port scan patterns
        # These flag combinations are never used in legitimate traffic
        
        iptables -A INPUT -p tcp --tcp-flags ALL NONE -j DROP                        # NULL scan
        iptables -A INPUT -p tcp --tcp-flags ALL ALL -j DROP                         # XMAS scan
        iptables -A INPUT -p tcp --tcp-flags ALL FIN,URG,PSH -j DROP                 # FIN/URG/PSH scan
        iptables -A INPUT -p tcp --tcp-flags ALL SYN,RST,ACK,FIN,URG -j DROP         # Combined scan
        iptables -A INPUT -p tcp --tcp-flags SYN,FIN SYN,FIN -j DROP                 # SYN/FIN scan
        iptables -A INPUT -p tcp --tcp-flags SYN,RST SYN,RST -j DROP                 # SYN/RST scan

        # ====================================================================
        # ICMP Rate Limiting
        # ====================================================================
        # Already blocked via allowPing=false, but add extra rate limiting
        # Allow 1 ping per second, burst of 1 (for diagnostic purposes)
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
    # Note: Daemon itself configured in display/services module
    # Here we only configure PAM integration
    
    security.pam.services = {
      # Enable GNOME Keyring for login sessions
      login.enableGnomeKeyring = true;
      
      # Enable for graphical display manager
      gdm.enableGnomeKeyring = true;
      
      # Enable for sudo (unlock keyring with sudo password)
      sudo.enableGnomeKeyring = true;
    };

    # ---- Polkit Configuration ----
    # PolicyKit - Authorization framework for privileged operations
    
    security.polkit = {
      enable = true;
      
      # Allow users in 'wheel' group to perform admin actions without password
      # (For specific actions like reboot, shutdown, package management)
      extraConfig = ''
        /* Allow members of wheel group to execute actions without authentication */
        polkit.addRule(function(action, subject) {
          if (subject.isInGroup("wheel")) {
            return polkit.Result.YES;
          }
        });
      '';
    };

    # ==========================================================================
    # Mandatory Access Control (Layer 3: AppArmor)
    # ==========================================================================
    # AppArmor provides additional security layer beyond DAC (Discretionary Access Control)
    # Profiles define what resources each program can access
    
    security.apparmor = {
      enable = true;
      
      # Kill processes that violate their AppArmor profile
      killUnconfinedConfinables = true;
      
      # Custom AppArmor profiles can be added here
      # packages = [ pkgs.apparmor-profiles ];
    };

    # ==========================================================================
    # Audit Logging (Layer 4: System Activity Monitoring)
    # ==========================================================================
    # Linux Audit Framework - Records security-relevant events
    # Useful for forensics, compliance, and intrusion detection
    
    security.audit = {
      enable = true;
      
      # Audit rules configuration
      # Format: auditctl syntax (see: man auditctl)
      rules = [
        # ----------------------------------------------------------------------
        # Buffer & Rate Configuration
        # ----------------------------------------------------------------------
        # Audit system tuning parameters
        "-b 8192"                    # Buffer size: 8192 events (default: 64)
        "-f 1"                       # Failure mode: 1=printk (log to kernel buffer)
        "--backlog_wait_time 60000"  # Wait 60s if buffer full (prevent data loss)
        "-r 100"                     # Rate limit: 100 messages/second per rule
        
        # ----------------------------------------------------------------------
        # File Integrity Monitoring
        # ----------------------------------------------------------------------
        # Watch critical system files for unauthorized modifications
        # Format: -w PATH -p PERMISSIONS -k KEY
        #   -w: watch path
        #   -p: permissions to audit (r=read, w=write, x=execute, a=attribute)
        #   -k: key name for filtering logs
        
        "-w /etc/passwd -p wa -k passwd_changes"         # User accounts
        "-w /etc/shadow -p wa -k shadow_changes"         # Password hashes
        "-w /etc/group -p wa -k group_changes"           # Group database
        "-w /etc/gshadow -p wa -k gshadow_changes"       # Group passwords
        "-w /etc/sudoers -p wa -k sudoers_changes"       # Sudo config
        "-w /etc/sudoers.d/ -p wa -k sudoers_changes"    # Sudo drop-in files
        "-w /etc/ssh/sshd_config -p wa -k sshd_config"   # SSH daemon config

        # ----------------------------------------------------------------------
        # Syscall Auditing (Minimal for Workstation)
        # ----------------------------------------------------------------------
        # Track security-relevant system calls
        # More comprehensive rules available for servers/production systems
        
        # Track root commands executed by normal users
        # Catches privilege escalation attempts
        # Format: -a ACTION,FILTER -F FIELD=VALUE -S SYSCALL -k KEY
        "-a always,exit -F arch=b64 -S execve,execveat -F euid=0 -F auid>=1000 -F auid!=4294967295 -k exec_root"

        # Track UID/GID changes (privilege changes)
        "-a always,exit -F arch=b64 -S setuid,setresgid,setfsuid,setfsgid -k id_change"

        # ----------------------------------------------------------------------
        # Make Rules Immutable (Uncomment for Production)
        # ----------------------------------------------------------------------
        # Prevents rule changes without reboot (security hardening)
        # WARNING: Once enabled, requires reboot to modify audit rules
        # "-e 2"
      ];
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
    # SSH Client Configuration (Layer 5: Secure Remote Access)
    # ==========================================================================
    
    programs.ssh = {
      # Disable SSH agent (using GPG agent instead)
      startAgent = false;
      
      # Disable graphical password prompts
      enableAskPassword = false;

      # Global SSH client options
      # These settings improve connection reliability and timeout handling
      extraConfig = ''
        Host *
          # ---- Connection Keep-Alive ----
          # Prevent timeouts on idle connections
          ServerAliveInterval 60      # Send keepalive every 60 seconds
          ServerAliveCountMax 3       # Allow 3 missed keepalives (180s total)
          TCPKeepAlive yes            # Enable TCP keepalive
          
          # ---- Connection Timeout ----
          ConnectTimeout 30           # Timeout for initial connection (30 seconds)
          
          # ---- ASSH Proxy (Advanced SSH Connection Manager) ----
          # ASSH provides enhanced SSH configuration management
          # Includes: host templates, gateways, connection reuse
          # Config file: ~/.ssh/assh.yml
          ProxyCommand ${pkgs.assh}/bin/assh connect --port=%p %h
      '';
    };

    # ==========================================================================
    # Environment Configuration
    # ==========================================================================
    
    environment = {
      # ---- hBlock Integration for New Users ----
      # Add HOSTALIASES to default shell config
      # This enables per-user DNS blocking without modifying /etc/hosts
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
        
        # Firewall diagnostics
        fw-list            = "sudo iptables -L -v -n";       # List all rules
        fw-list-custom     = "sudo iptables -L INPUT -v -n"; # List INPUT chain
        fw-stats           = "sudo iptables -L -v -n -x";    # Show packet counts
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
#    - All ports declared in THIS module only (single source of truth)
#    - Use NixOS firewall, extend with extraCommands
#    - SSH connections exempt from rate limiting (prevents multiplexing issues)
#    - Test commands:
#      * sudo iptables -L -v -n           (list all rules)
#      * sudo iptables -L INPUT -v -n -x  (show INPUT chain with packet counts)
#      * journalctl -k | grep "IN=.*OUT=" (check dropped packets)
#
# 2. AppArmor:
#    - Profiles in /etc/apparmor.d/
#    - Check status: sudo aa-status
#    - Enforce profile: sudo aa-enforce /path/to/profile
#    - Complain mode: sudo aa-complain /path/to/profile (log violations only)
#
# 3. Audit:
#    - View logs: sudo ausearch -i
#    - Summary: sudo aureport --summary
#    - Search failed logins: sudo ausearch -m USER_LOGIN --failed
#    - Search by key: sudo ausearch -k passwd_changes
#    - Real-time monitoring: sudo ausearch -i --start recent -m all
#
# 4. SSH:
#    - Use ASSH for complex configurations
#    - Config: ~/.ssh/assh.yml
#    - Build: assh config build > ~/.ssh/config
#    - Test connection: ssh -vvv hostname (verbose debug)
#    - Check multiplexing: ls -la ~/.ssh/controlmasters/
#
# 5. hBlock:
#    - Manual update: hblock-update-now
#    - Check file: cat ~/.config/hblock/hosts
#    - Test blocking: ping ad-server.com (should fail/redirect)
#    - Disable temporarily: unset HOSTALIASES
#
# ==============================================================================
# Troubleshooting SSH Connection Issues
# ==============================================================================
#
# If SSH connections are slow or hanging:
#
# 1. Check firewall rules:
#    sudo iptables -L INPUT -v -n | grep -E "tcp.*22|tcp.*syn"
#    
#    Look for:
#    - SSH exceptions are listed BEFORE rate limit rules
#    - Rate limits are reasonable (5/s, burst 10)
#    - Connection limits are not too low (<50)
#
# 2. Test without rate limiting:
#    sudo iptables -D INPUT -p tcp --syn -m limit --limit 5/s --limit-burst 10 -j ACCEPT
#    sudo iptables -D INPUT -p tcp --syn -m connlimit --connlimit-above 50 -j REJECT
#    
#    Then test SSH. If it works, firewall rules are the issue.
#
# 3. Check SSH multiplexing:
#    ssh -O check hostname     # Check ControlMaster status
#    ssh -O exit hostname      # Close ControlMaster
#    rm -rf ~/.ssh/controlmasters/*  # Remove stale sockets
#
# 4. Test without ASSH proxy:
#    ssh -o ProxyCommand=none hostname
#    
#    If this works, issue is with ASSH configuration.
#
# 5. Monitor connection in real-time:
#    # Terminal 1: Watch firewall
#    sudo iptables -L INPUT -v -n -x --line-numbers && watch -n1 'sudo iptables -L INPUT -v -n -x'
#    
#    # Terminal 2: SSH with verbose output
#    ssh -vvv hostname
#    
#    Look for packets being dropped in firewall counters.
#
# 6. Check for rwindow 0 issue:
#    ssh -vvv hostname 2>&1 | grep "rwindow"
#    
#    If you see "rwindow 0", the server is not ready to receive data.
#    Possible causes:
#    - Rate limiting (should be fixed with these rules)
#    - Network congestion
#    - Server-side shell initialization hanging
#    - BBR congestion control issues (check networking module)
#
# ==============================================================================
# Advanced Firewall Diagnostics
# ==============================================================================
#
# Monitor dropped packets:
#   sudo journalctl -k -f | grep "IN=.*OUT="
#
# Count dropped packets by rule:
#   sudo iptables -L INPUT -v -n -x | awk '/DROP|REJECT/ {print $1, $2, $NF}'
#
# Test specific port:
#   nc -zv hostname port
#
# Check connection tracking:
#   sudo conntrack -L | grep -E "tcp.*22"
#
# Reset connection tracking (if table full):
#   sudo conntrack -F
#
# ==============================================================================
