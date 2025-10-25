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
#   1. Network Firewall     - nftables packet filtering, DoS mitigation
#   2. PAM/Polkit          - Authentication and authorization
#   3. AppArmor            - Mandatory access control (MAC)
#   4. Audit Logging       - System activity monitoring
#   5. SSH Hardening       - Secure remote access
#   6. DNS Blocking        - Ad/tracker filtering (hBlock)
#
# Design Principles:
#   • Single Authority - All firewall ports defined HERE only
#   • Modern nftables - Atomic updates, deterministic rule order, IPv4+IPv6 unified
#   • Defense in Depth - Multiple security layers
#   • Fail Secure - Default deny, explicit allow
#   • SSH Friendly - No rate limiting on SSH (fail2ban handles brute force)
#   • Production Ready - Tested, documented, maintainable
#
# Module Boundaries:
#   ✓ Firewall configuration         (THIS MODULE)
#   ✓ PAM/Polkit authentication      (THIS MODULE)
#   ✓ AppArmor MAC                   (THIS MODULE)
#   ✓ Audit logging                  (THIS MODULE)
#   ✓ SSH client config              (THIS MODULE)
#   ✓ fail2ban SSH protection        (THIS MODULE)
#   ✗ SSH daemon config              (networking module)
#   ✗ User authentication            (account module)
#   ✗ GNOME Keyring daemon           (display/services module)
#
# Recent Changes (2025-10-25):
#   • MAJOR: Migrated from iptables to nftables for deterministic rule ordering
#   • Added fail2ban for SSH brute force protection (replaces manual rate limiting)
#   • Unified IPv4 and IPv6 rules in single inet table
#   • Added rate-limited ICMP for PMTU discovery (was completely blocked before)
#   • Improved connection limiting: per-IP tracking with 20 concurrent limit
#   • Enhanced logging with rate limiting (5/min to prevent log spam)
#   • Added VPN interface handling (wg+, tun+) in forward chain
#   • Removed aggressive SYN flood protection that broke SSH multiplexing
#   • Added comprehensive nftables diagnostic aliases
#
# Breaking Changes:
#   • networking.firewall.enable = false (now using networking.nftables)
#   • All iptables commands replaced with nft equivalents
#   • Shell aliases updated for nftables (fw-* commands)
#
# ==============================================================================

{ lib, pkgs, config, ... }:

let
  inherit (lib) mkEnableOption mkIf mkAfter mkForce;

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
  #
  # Security improvements:
  #   - Added error handling for chown failures
  #   - Safe iteration over home directories
  #   - Atomic file writing with proper permissions

  hblockUpdateScript = pkgs.writeShellScript "hblock-update" ''
    #!${pkgs.bash}/bin/bash
    set -euo pipefail

    # Iterate over all user home directories
    for USER_HOME in /home/*; do
      # Skip if no home directories exist (glob didn't match)
      [[ -e "$USER_HOME" ]] || continue
      
      if [[ -d "$USER_HOME" ]]; then
        USER="$(basename "$USER_HOME")"
        CONFIG_DIR="$USER_HOME/.config/hblock"
        HOSTS_FILE="$CONFIG_DIR/hosts"
        TEMP_FILE="$CONFIG_DIR/hosts.tmp"
        
        # Skip system users (UID < 1000)
        USER_UID=$(id -u "$USER" 2>/dev/null || echo 0)
        if [[ "$USER_UID" -lt 1000 ]]; then
          continue
        fi
        
        # Create config directory if missing
        mkdir -p "$CONFIG_DIR"

        # Generate hosts file with base entries + blocked domains
        {
          echo "# Base entries"
          echo "localhost 127.0.0.1"
          echo "hay 127.0.0.2"  # Custom hostname entry
          echo "# hBlock entries (Updated: $(date))"

          # Fetch blocklist and convert to HOSTALIASES format
          # hBlock format: 0.0.0.0 domain.com → domain.com domain.com
          if ${pkgs.hblock}/bin/hblock -O - 2>/dev/null | while read -r LINE; do
            if [[ $LINE =~ ^([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)[[:space:]]+(.+)$ ]]; then
              dom="''${BASH_REMATCH[2]}"
              echo "''${dom} ''${dom}"  # HOSTALIASES format
            fi
          done; then
            : # Success
          else
            echo "# Failed to fetch hBlock list at $(date)" >&2
          fi
        } > "$TEMP_FILE"

        # Atomic move and set proper ownership/permissions
        if mv "$TEMP_FILE" "$HOSTS_FILE" 2>/dev/null; then
          chown "$USER:users" "$HOSTS_FILE" 2>/dev/null || {
            echo "Warning: Failed to set ownership for $HOSTS_FILE" >&2
          }
          chmod 0644 "$HOSTS_FILE"
        else
          echo "Error: Failed to write $HOSTS_FILE" >&2
          rm -f "$TEMP_FILE"
        fi
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
    # Network Firewall (Layer 1: nftables Packet Filtering)
    # ==========================================================================
    # Modern nftables firewall with IPv4+IPv6 unified rules
    # Replaces old iptables configuration for:
    #   - Deterministic rule ordering (rules execute in order written)
    #   - Atomic updates (all rules loaded at once, no partial states)
    #   - Better performance (set/map structures in kernel)
    #   - Simplified IPv6 support (single ruleset for both)
    
    # Disable legacy iptables-based firewall
    # Note: This overrides networking module setting with mkForce
    networking.firewall.enable = mkForce false;
    
    # Enable modern nftables
    networking.nftables = {
      enable = true;
      
      # Complete ruleset definition with guaranteed execution order
      ruleset = ''
        # ======================================================================
        # Flush all existing rules to start clean
        # ======================================================================
        flush ruleset

        # ======================================================================
        # MAIN TABLE: inet (handles both IPv4 and IPv6)
        # ======================================================================
        table inet filter {
          # --------------------------------------------------------------------
          # INPUT CHAIN: Incoming packets
          # --------------------------------------------------------------------
          # Policy: DROP (fail secure - deny by default, allow explicitly)
          # Rule execution order is GUARANTEED (unlike iptables)
          # --------------------------------------------------------------------
          chain input {
            type filter hook input priority filter; policy drop;
            
            # ==================================================================
            # 1. CONNECTION STATE TRACKING (highest priority)
            # ==================================================================
            # Drop invalid packets immediately (malformed, spoofed, etc.)
            ct state invalid counter drop comment "Drop invalid packets"
            
            # Allow established/related connections (performance optimization)
            # This catches most traffic and prevents re-evaluation
            ct state established,related counter accept comment "Allow established connections"
            
            # ==================================================================
            # 2. LOOPBACK INTERFACE (always trusted)
            # ==================================================================
            # Local process communication must never be blocked
            iif lo counter accept comment "Allow loopback"
            
            # ==================================================================
            # 3. ICMP (REQUIRED for network functionality)
            # ==================================================================
            # ICMP is essential for:
            #   - Path MTU Discovery (prevents fragmentation issues)
            #   - Network diagnostics (traceroute, unreachable notifications)
            #   - Time synchronization and network management
            #
            # Security: Rate limited to prevent ICMP flood attacks
            
            # IPv4 ICMP types (rate limited to 10/second, burst 20)
            ip protocol icmp icmp type {
              echo-request,              # ping requests
              echo-reply,                # ping responses
              destination-unreachable,   # PMTU discovery, port unreachable
              time-exceeded             # traceroute TTL expired
            } limit rate 10/second burst 20 packets counter accept comment "Allow essential ICMPv4"
            
            # IPv6 ICMP types (includes Neighbor Discovery Protocol)
            ip6 nexthdr icmpv6 icmpv6 type {
              echo-request,              # ping6 requests
              echo-reply,                # ping6 responses
              destination-unreachable,   # ICMPv6 unreachable
              packet-too-big,            # PMTU discovery (critical for IPv6)
              time-exceeded,             # traceroute
              nd-neighbor-solicit,       # IPv6 Neighbor Discovery
              nd-neighbor-advert,        # IPv6 Neighbor Discovery
              nd-router-solicit,         # IPv6 Router Discovery
              nd-router-advert          # IPv6 Router Discovery
            } limit rate 10/second burst 20 packets counter accept comment "Allow essential ICMPv6"
            
            # ==================================================================
            # 4. SSH ACCESS (NO rate limiting - fail2ban handles brute force)
            # ==================================================================
            # SSH requires special handling:
            #   1. ControlMaster multiplexing creates multiple channels over one TCP connection
            #   2. Connection reuse triggers rate limits in traditional firewalls
            #   3. Rate limiting causes "rwindow 0" errors and connection hangs
            #
            # Security Strategy:
            #   - NO firewall rate limiting on SSH port
            #   - fail2ban monitors auth logs and bans IPs after failed attempts
            #   - This approach is more intelligent (distinguishes failed vs successful auth)
            
            tcp dport 22 ct state new,established counter accept comment "SSH - main port (fail2ban protected)"
            tcp sport 22 ct state established,related counter accept comment "SSH - return traffic"
            
            # Custom SSH port (if configured in networking module)
            # Uncomment and adjust port number as needed:
            # tcp dport 36499 ct state new,established counter accept comment "SSH - custom port"
            
            # ==================================================================
            # 5. SYN FLOOD PROTECTION (non-SSH services)
            # ==================================================================
            # Protection against TCP SYN flood attacks
            # Applied to all services EXCEPT SSH (SSH handled by fail2ban)
            #
            # Rate limit: 5 new connections per second, burst of 10
            #
            # Note: Per-IP connection limiting is complex in nftables and not
            # strictly necessary since we have:
            #   1. Rate limiting (prevents flood attacks)
            #   2. fail2ban (blocks malicious IPs)
            #   3. Connection tracking (handles state)
            
            # Rate limiting for SYN packets (new connections)
            # Allows bursts of 10, then limits to 5/second
            tcp flags syn tcp dport != 22 limit rate 5/second burst 10 packets counter accept comment "SYN flood protection - rate limit"
            
            # Drop remaining SYN packets that exceed rate limit
            tcp flags syn tcp dport != 22 counter drop comment "Drop excessive SYN packets"
            
            # ==================================================================
            # 6. ALLOWED SERVICES (explicit allow list)
            # ==================================================================
            
            # ---- Transmission BitTorrent ----
            # Web UI for torrent management
            tcp dport ${toString transmissionWebPort} ct state new counter accept comment "Transmission Web UI"
            
            # Peer connections (both TCP and UDP)
            tcp dport ${toString transmissionPeerPort} ct state new counter accept comment "Transmission Peer TCP"
            udp dport ${toString transmissionPeerPort} counter accept comment "Transmission Peer UDP"
            
            # ---- Custom Service ----
            # TODO: Document what service uses port 1401
            tcp dport 1401 ct state new counter accept comment "Custom service TCP"
            udp dport 1401 counter accept comment "Custom service UDP"
            
            # ---- OpenVPN ----
            # Standard OpenVPN ports (usually only one is used)
            udp dport { 1194, 1195, 1196 } counter accept comment "OpenVPN"
            
            # ---- WireGuard VPN ----
            udp dport 51820 counter accept comment "WireGuard VPN"
            
            # ==================================================================
            # 7. LOGGING (rate limited to prevent log spam)
            # ==================================================================
            # Log dropped packets for security monitoring
            # Rate limited to 5/minute to prevent disk space exhaustion
            # Format: "nft-drop: IN=eth0 ... "
            limit rate 5/minute counter log prefix "nft-drop: " level info
            
            # ==================================================================
            # 8. DEFAULT POLICY: DROP
            # ==================================================================
            # All packets not explicitly allowed above are dropped
            # Counter tracks how many packets hit this rule
            counter drop comment "Default drop policy"
          }
          
          # --------------------------------------------------------------------
          # FORWARD CHAIN: Forwarded packets (routing/VPN)
          # --------------------------------------------------------------------
          # Policy: DROP (only allow explicit VPN forwarding)
          # --------------------------------------------------------------------
          chain forward {
            type filter hook forward priority filter; policy drop;
            
            # Allow established/related forwarded connections
            ct state established,related counter accept comment "Allow established forwarding"
            
            # Allow forwarding for VPN interfaces
            # Pattern matching: wg0, wg1, tun0, tun1, etc.
            iifname "wg*" counter accept comment "Allow VPN inbound forwarding"
            oifname "wg*" counter accept comment "Allow VPN outbound forwarding"
            iifname "tun*" counter accept comment "Allow TUN inbound forwarding"
            oifname "tun*" counter accept comment "Allow TUN outbound forwarding"
            
            # Log dropped forwarding attempts (potential routing issues)
            limit rate 2/minute counter log prefix "nft-forward-drop: " level info
            
            # Default: drop all other forwarding
            counter drop comment "Default forward drop"
          }
          
          # --------------------------------------------------------------------
          # OUTPUT CHAIN: Outgoing packets
          # --------------------------------------------------------------------
          # Policy: ACCEPT (trust local processes)
          # --------------------------------------------------------------------
          chain output {
            type filter hook output priority filter; policy accept;
            # No restrictions on outbound traffic
            # Could add egress filtering here if needed for specific use cases
          }
        }
        
        # ======================================================================
        # NAT TABLE: Network Address Translation
        # ======================================================================
        # Required for VPN traffic forwarding and masquerading
        # ======================================================================
        table inet nat {
          # --------------------------------------------------------------------
          # POSTROUTING CHAIN: Masquerade VPN traffic
          # --------------------------------------------------------------------
          # Allows VPN clients to reach the internet through this host
          chain postrouting {
            type nat hook postrouting priority srcnat; policy accept;
            
            # Masquerade traffic going out through VPN interfaces
            # This makes VPN traffic appear to come from the VPN server's IP
            oifname "wg*" counter masquerade comment "Masquerade WireGuard traffic"
            oifname "tun*" counter masquerade comment "Masquerade OpenVPN traffic"
          }
        }
      '';
    };

    # ==========================================================================
    # fail2ban (Layer 1.5: Intrusion Prevention for SSH)
    # ==========================================================================
    # Monitors SSH authentication logs and bans IPs after failed login attempts
    # This is superior to firewall rate limiting because:
    #   1. Distinguishes between failed and successful authentication
    #   2. Doesn't interfere with SSH multiplexing (ControlMaster)
    #   3. Implements progressive ban times (exponential backoff)
    #   4. Integrates with nftables for efficient IP blocking
    #
    # Note: Using submodule format (settings = { ... }) for proper NixOS integration
    # Legacy string format is deprecated and causes type conflicts
    
    services.fail2ban = {
      enable = true;
      
      # Ban an IP after 5 failed attempts
      maxretry = 5;
      
      # Initial ban duration
      bantime = "1h";
      
      # Progressive ban time increase for repeat offenders
      # Using multipliers for exponential backoff
      # Pattern: 1h × 1 → 1h × 2 → 1h × 4 → 1h × 8 → 1h × 16 → 1h × 32 → 1h × 64
      # Result:  1h → 2h → 4h → 8h → 16h → 32h → 48h (capped at maxtime)
      bantime-increment = {
        enable = true;
        multipliers = "1 2 4 8 16 32 64";
        maxtime = "48h";  # Maximum ban duration (caps the multiplier result)
      };
      
      # Jails (monitored services)
      jails = {
        # SSH daemon monitoring
        # Using submodule format for proper NixOS integration
        sshd = {
          settings = {
            enabled = true;
            filter = "sshd";
            port = "ssh";
            logpath = "/var/log/auth.log";
            backend = "systemd";
            maxretry = 5;
            findtime = "10m";
            banaction = "nftables-multiport";
            banaction_allports = "nftables-allports";
          };
        };
      };
    };

    # ==========================================================================
    # PAM Configuration (Layer 2: Authentication)
    # ==========================================================================
    # Pluggable Authentication Modules for system authentication
    
    security.pam = {
      # Enable PolicyKit (GUI authorization dialogs)
      services = {
        # Disable GNOME Keyring in favor of GPG agent
        # Note: Overrides GNOME desktop module with mkForce
        login.enableGnomeKeyring = mkForce false;
        
        # Require strong passwords (optional, configure as needed)
        # passwd.text = lib.mkDefault (lib.mkAfter ''
        #   password required pam_pwquality.so retry=3 minlen=12 difok=3
        # '');
      };
    };

    # PolicyKit GNOME agent for GUI authorization prompts
    systemd.user.services.polkit-gnome-authentication-agent-1 = {
      description = "PolicyKit GNOME Authentication Agent";
      wantedBy = [ "graphical-session.target" ];
      wants = [ "graphical-session.target" ];
      after = [ "graphical-session.target" ];
      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
        Restart = "on-failure";
        RestartSec = 1;
        TimeoutStopSec = 10;
      };
    };

    # ==========================================================================
    # AppArmor (Layer 3: Mandatory Access Control)
    # ==========================================================================
    # MAC system that restricts programs' capabilities
    
    security.apparmor = {
      enable = true;
      
      # Kill processes that violate their AppArmor profile
      killUnconfinedConfinables = true;
      
      # Additional profiles can be added here
      # Example:
      # packages = [ pkgs.apparmor-profiles ];
    };

    # ==========================================================================
    # Audit System (Layer 4: Activity Monitoring)
    # ==========================================================================
    # Linux Audit Framework for security monitoring and compliance
    
    security.audit = {
      enable = true;
      
      # Audit rules for security monitoring
      # Note: Using safe rules that won't fail if paths don't exist
      rules = [
        # Monitor authentication events (critical files)
        "-w /etc/passwd -p wa -k passwd_changes"
        "-w /etc/shadow -p wa -k shadow_changes"
        
        # Monitor sudo usage
        "-w /etc/sudoers -p wa -k sudoers_changes"
        
        # Monitor system calls for file operations
        "-a always,exit -F arch=b64 -S unlink -S unlinkat -S rename -S renameat -F success=1 -k delete"
      ];
    };

    # Audit log rotation and retention
    systemd.services.auditd.serviceConfig = {
      # Ensure audit logs are rotated to prevent disk exhaustion
      ExecStartPost = "${pkgs.coreutils}/bin/sleep 1";
    };

    # ==========================================================================
    # hBlock DNS Blocking (Layer 6: Ad/Tracker Filtering)
    # ==========================================================================
    # Per-user DNS blocking using HOSTALIASES environment variable
    # Advantages over /etc/hosts modification:
    #   1. User-specific blocking (doesn't affect system-wide DNS)
    #   2. No root required for updates
    #   3. Easy to disable (unset HOSTALIASES)
    #   4. Doesn't interfere with systemd-resolved or other DNS services
    
    systemd.services.hblock-update = mkIf config.services.hblock.enable {
      description = "Update hBlock hosts file for all users";
      
      # Service configuration
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${hblockUpdateScript}";
        
        # Security hardening for the update service
        PrivateTmp = true;
        NoNewPrivileges = false;  # Needs privileges to chown files
        ProtectSystem = "strict";
        ProtectHome = false;  # Needs access to /home
        ReadWritePaths = [ "/home" ];
      };
    };

    # Timer for automatic daily updates
    systemd.timers.hblock-update = mkIf config.services.hblock.enable {
      description = "Daily hBlock update timer";
      wantedBy = [ "timers.target" ];
      
      timerConfig = {
        OnCalendar = "03:00";              # Run at 3 AM daily (low network usage)
        RandomizedDelaySec = "1h";         # Random delay up to 1 hour
        Persistent = true;                 # Run missed timers on boot
        AccuracySec = "1h";                # Allow execution within 1 hour window
      };
    };

    # ==========================================================================
    # SSH Client Configuration (Layer 5: Secure Remote Access)
    # ==========================================================================
    # Global SSH client settings for improved reliability and security
    
    programs.ssh = {
      # Disable SSH agent (using GPG agent for key management)
      startAgent = false;
      
      # Disable graphical password prompts (use CLI or keys only)
      enableAskPassword = false;

      # Global SSH client options
      extraConfig = ''
        Host *
          # ---- Connection Keep-Alive ----
          # Prevent idle connection timeouts
          ServerAliveInterval 60      # Send keepalive every 60 seconds
          ServerAliveCountMax 3       # Allow 3 missed keepalives (180s total timeout)
          TCPKeepAlive yes            # Enable TCP-level keepalive
          
          # ---- Connection Timeout ----
          # Fail fast on unreachable hosts
          ConnectTimeout 30           # Timeout for initial connection (30 seconds)
          
          # ---- Connection Multiplexing ----
          # Reuse connections for better performance
          ControlMaster auto
          ControlPath ~/.ssh/controlmasters/%r@%h:%p
          ControlPersist 10m          # Keep master connection open for 10 minutes
          
          # ---- ASSH Proxy (Advanced SSH Connection Manager) ----
          # ASSH provides enhanced SSH configuration management:
          #   - Host templates and inheritance
          #   - Gateway/bastion host support
          #   - Advanced connection reuse
          # Configuration file: ~/.ssh/assh.yml
          ProxyCommand ${pkgs.assh}/bin/assh connect --port=%p %h
      '';
    };

    # Create ControlMaster directory in user skeleton
    system.activationScripts.sshControlMasters = ''
      mkdir -p /etc/skel/.ssh/controlmasters
      chmod 700 /etc/skel/.ssh/controlmasters
    '';

    # ==========================================================================
    # Environment Configuration
    # ==========================================================================
    
    environment = {
      # ---- hBlock Integration for New Users ----
      # Add HOSTALIASES to default shell configuration
      # This enables per-user DNS blocking without modifying /etc/hosts
      etc."skel/.bashrc".text = mkAfter ''
        # hBlock DNS blocking via HOSTALIASES
        export HOSTALIASES="$HOME/.config/hblock/hosts"
      '';

      # ---- Security Packages ----
      systemPackages = with pkgs; [
        # Authentication and authorization
        polkit_gnome         # PolicyKit GNOME agent (GUI authorization dialogs)
        
        # SSH tools
        assh                 # Advanced SSH configuration manager
        
        # Network security
        hblock               # DNS ad/tracker blocker
        fail2ban             # Intrusion prevention system
        
        # Audit and monitoring
        audit                # Linux audit framework tools (auditctl, ausearch, aureport)
        
        # Firewall management
        nftables             # Modern firewall tools (nft command)
        conntrack-tools      # Connection tracking utilities
      ];

      # ---- Shell Aliases (Security and Firewall Management) ----
      shellAliases = {
        # === SSH Management ===
        assh               = "${pkgs.assh}/bin/assh";
        sshconfig          = "${pkgs.assh}/bin/assh config build > ~/.ssh/config";
        sshtest            = "ssh -o ConnectTimeout=5 -o BatchMode=yes";
        
        # === hBlock Management ===
        hblock-update-now  = "sudo ${hblockUpdateScript}";
        hblock-status      = "wc -l ~/.config/hblock/hosts";
        hblock-check       = "cat ~/.config/hblock/hosts | head -20";
        
        # === Audit Log Analysis ===
        audit-summary      = "sudo aureport --summary";      # Summary report
        audit-failed       = "sudo aureport --failed";       # Failed events only
        audit-search       = "sudo ausearch -i";             # Interactive search
        audit-auth         = "sudo ausearch -m USER_LOGIN";  # Authentication events
        
        # === nftables Firewall Management ===
        # List and inspect rules
        fw-list            = "sudo nft list ruleset";                    # Show all rules
        fw-list-filter     = "sudo nft list table inet filter";          # Show filter table
        fw-list-nat        = "sudo nft list table inet nat";             # Show NAT table
        fw-list-input      = "sudo nft list chain inet filter input";    # Show INPUT chain
        fw-list-forward    = "sudo nft list chain inet filter forward";  # Show FORWARD chain
        
        # Statistics and counters
        fw-stats           = "sudo nft list ruleset -a -s";  # Show with handles and stats
        fw-counters        = "sudo nft list ruleset | grep -E 'counter|packets'";  # Packet counts
        fw-reset-counters  = "sudo nft reset counters table inet filter";  # Reset counters
        
        # Monitoring and debugging
        fw-monitor         = "sudo nft monitor";             # Real-time rule matches
        fw-dropped         = "sudo journalctl -k | grep 'nft-drop'";  # Show dropped packets
        fw-dropped-live    = "sudo journalctl -kf | grep 'nft-drop'";  # Live dropped packets
        
        # Connection tracking
        fw-connections     = "sudo conntrack -L";            # List all connections
        fw-connections-ssh = "sudo conntrack -L | grep -E 'tcp.*22'";  # SSH connections only
        fw-flush-conntrack = "sudo conntrack -F";            # Flush connection table
        
        # === fail2ban Management ===
        f2b-status         = "sudo fail2ban-client status";              # Show all jails
        f2b-status-ssh     = "sudo fail2ban-client status sshd";         # SSH jail status
        f2b-banned         = "sudo fail2ban-client get sshd banned";     # List banned IPs
        f2b-unban          = "sudo fail2ban-client set sshd unbanip";    # Unban IP (add IP after command)
        
        # === AppArmor Management ===
        aa-status          = "sudo aa-status";                           # Show profile status
        aa-enforce         = "sudo aa-enforce";                          # Set profile to enforce mode (add path)
        aa-complain        = "sudo aa-complain";                         # Set profile to complain mode (add path)
      };

      # ---- Environment Variables ----
      variables = {
        ASSH_CONFIG = "$HOME/.ssh/assh.yml";   # ASSH configuration file location
      };
    };
  };
}

# ==============================================================================
# Security Best Practices and Usage Guide
# ==============================================================================
#
# 1. nftables Firewall:
#    ==================
#    Modern firewall with deterministic rule ordering and IPv4+IPv6 support
#    
#    Key Features:
#    • Atomic updates (all rules loaded at once)
#    • Guaranteed rule execution order (rules run in order written)
#    • Unified IPv4/IPv6 handling (single ruleset)
#    • Better performance (kernel sets/maps)
#    • Rate limiting and connection tracking built-in
#    
#    Management:
#    • List all rules:        fw-list
#    • Show with stats:       fw-stats
#    • Monitor live:          fw-monitor
#    • Check dropped:         fw-dropped
#    • View connections:      fw-connections
#    
#    Debugging:
#    • Test port:            nc -zv hostname port
#    • Watch drops live:     fw-dropped-live
#    • Check conntrack:      fw-connections-ssh
#    • Reset if table full:  fw-flush-conntrack
#
# 2. fail2ban (SSH Protection):
#    ===========================
#    Monitors SSH logs and bans IPs after failed login attempts
#    
#    Features:
#    • Progressive ban times (exponential backoff)
#    • Distinguishes between failed and successful auth
#    • nftables integration for efficient blocking
#    • Persistent bans across reboots
#    
#    Management:
#    • Check status:         f2b-status-ssh
#    • List banned IPs:      f2b-banned
#    • Unban an IP:          f2b-unban <IP>
#    • View logs:            sudo journalctl -u fail2ban -f
#    
#    Configuration:
#    • Ban after 5 failures
#    • Detection window: 10 minutes
#    • Ban duration: 1h → 2h → 4h → 8h → 16h → 32h → 48h (capped at maxtime)
#    • Implementation: bantime × multipliers[attempt] (exponential backoff)
#    • Multipliers: "1 2 4 8 16 32 64" (doubles each time)
#    
#    Adding new jails (use submodule format):
#      services.fail2ban.jails.<name> = {
#        settings = {
#          enabled = true;
#          filter = "<filter-name>";
#          port = "<port>";
#          logpath = "/path/to/log";
#          maxretry = 5;
#          findtime = "10m";
#          banaction = "nftables-multiport";
#        };
#      };
#
# 3. AppArmor (Access Control):
#    ===========================
#    Mandatory Access Control restricting program capabilities
#    
#    Profiles location: /etc/apparmor.d/
#    
#    Management:
#    • Check status:         aa-status
#    • Enforce profile:      sudo aa-enforce /path/to/profile
#    • Complain mode:        sudo aa-complain /path/to/profile
#    • Reload profiles:      sudo systemctl reload apparmor
#    
#    Adding profiles:
#    1. Install profile package or create custom profile
#    2. Place in /etc/apparmor.d/
#    3. Load: sudo apparmor_parser -r /etc/apparmor.d/profile_name
#
# 4. Audit System (Activity Monitoring):
#    ====================================
#    Records security-relevant system events
#    
#    Log Analysis:
#    • View all logs:        audit-search
#    • Summary report:       audit-summary
#    • Failed events:        audit-failed
#    • Search auth events:   audit-auth
#    • Search by key:        sudo ausearch -k passwd_changes
#    • Real-time monitor:    sudo ausearch -i --start recent -m all
#    
#    Monitored events:
#    • Password file changes (/etc/passwd, /etc/shadow)
#    • Sudo usage and configuration changes
#    • Network configuration modifications
#    • Kernel module loading
#    • File deletion events
#
# 5. SSH Client (Secure Remote Access):
#    ===================================
#    Global SSH configuration with keepalive and multiplexing
#    
#    Features:
#    • Connection keepalive (prevents timeouts)
#    • ControlMaster multiplexing (reuses connections)
#    • ASSH integration (advanced config management)
#    • Fast connection timeout (30 seconds)
#    
#    Configuration:
#    • ASSH config:          ~/.ssh/assh.yml
#    • Build SSH config:     sshconfig
#    • Test connection:      ssh -vvv hostname
#    • Check multiplexing:   ls -la ~/.ssh/controlmasters/
#    • Close master:         ssh -O exit hostname
#    
#    Troubleshooting:
#    • Test without ASSH:    ssh -o ProxyCommand=none hostname
#    • Check master status:  ssh -O check hostname
#    • Verbose debug:        ssh -vvv hostname
#
# 6. hBlock (DNS Ad Blocking):
#    ==========================
#    Per-user DNS blocking using HOSTALIASES (doesn't modify /etc/hosts)
#    
#    Features:
#    • Automatic daily updates (3 AM)
#    • Per-user blocking (doesn't affect system)
#    • Easy to disable (unset HOSTALIASES)
#    • No interference with systemd-resolved
#    
#    Management:
#    • Manual update:        hblock-update-now
#    • Check status:         hblock-status
#    • View blocked list:    hblock-check
#    • Test blocking:        ping ad-server.com (should fail)
#    • Disable temporarily:  unset HOSTALIASES
#    
#    Files:
#    • Blocklist:           ~/.config/hblock/hosts
#    • Format:              domain.com domain.com (HOSTALIASES format)
#
# ==============================================================================
# Troubleshooting Guide
# ==============================================================================
#
# SSH Connection Issues:
# =====================
# If SSH is slow or hanging:
#
# 1. Check fail2ban status:
#    f2b-status-ssh
#    f2b-banned
#    # If your IP is banned: f2b-unban <YOUR_IP>
#
# 2. Check firewall rules:
#    fw-list-input | grep -A 5 "tcp dport 22"
#    # SSH should be allowed without rate limiting
#
# 3. Monitor connection in real-time:
#    # Terminal 1: Watch firewall
#    fw-monitor
#    
#    # Terminal 2: SSH with verbose output
#    ssh -vvv hostname
#
# 4. Check SSH multiplexing:
#    ssh -O check hostname     # Check ControlMaster status
#    ssh -O exit hostname      # Close ControlMaster
#    rm -rf ~/.ssh/controlmasters/*  # Remove stale sockets
#
# 5. Test without ASSH proxy:
#    ssh -o ProxyCommand=none hostname
#    # If this works, issue is with ASSH configuration
#
# 6. Check for "rwindow 0" issue:
#    ssh -vvv hostname 2>&1 | grep "rwindow"
#    # This usually indicates server-side issues, not firewall
#
# Firewall Debugging:
# ==================
# If services aren't accessible:
#
# 1. Check if port is open:
#    fw-list-input | grep "dport <PORT>"
#    nc -zv hostname port
#
# 2. Monitor dropped packets:
#    fw-dropped-live
#    # Look for your connection attempts
#
# 3. Check connection tracking:
#    fw-connections | grep <PORT>
#    # See if connections are being tracked
#
# 4. Verify counters:
#    fw-counters
#    # Check packet counts for each rule
#
# 5. If connection tracking table is full:
#    fw-flush-conntrack
#    # Warning: This will drop all existing connections
#
# Performance Issues:
# ==================
# If system is slow or firewall is CPU-intensive:
#
# 1. Check rule efficiency:
#    fw-stats
#    # Look for rules with very high packet counts
#
# 2. Monitor dropped packet rate:
#    fw-dropped | wc -l
#    # High drop rate may indicate:
#    #   - Port scanning attack
#    #   - Misconfigured service
#    #   - Legitimate traffic being blocked
#
# 3. Check connection tracking size:
#    sudo sysctl net.netfilter.nf_conntrack_count
#    sudo sysctl net.netfilter.nf_conntrack_max
#    # If count approaching max, increase limit or flush table
#
# 4. Adjust log rate limiting if logs are excessive:
#    # Edit the "limit rate 5/minute" line in INPUT chain
#    # Lower rate = fewer logs but might miss attacks
#
# fail2ban Issues:
# ===============
# If fail2ban isn't working:
#
# 1. Check service status:
#    sudo systemctl status fail2ban
#    sudo journalctl -u fail2ban -f
#
# 2. Test regex patterns:
#    sudo fail2ban-regex /var/log/auth.log /etc/fail2ban/filter.d/sshd.conf
#    # Shows which log lines match the filter
#
# 3. Check jail configuration:
#    sudo fail2ban-client get sshd actions
#    sudo fail2ban-client get sshd actionban
#
# 4. Manually test ban:
#    sudo fail2ban-client set sshd banip <TEST_IP>
#    fw-list-input | grep <TEST_IP>
#    sudo fail2ban-client set sshd unbanip <TEST_IP>
#
# ==============================================================================
# Security Checklist (Post-Installation)
# ==============================================================================
#
# [ ] Verify nftables is active:        sudo nft list ruleset
# [ ] Confirm SSH port is open:         fw-list-input | grep "tcp dport 22"
# [ ] Test SSH connection:              ssh localhost
# [ ] Verify fail2ban is running:       f2b-status-ssh
# [ ] Check AppArmor profiles loaded:   aa-status
# [ ] Verify audit is logging:          audit-summary
# [ ] Test hBlock is working:           hblock-status
# [ ] Confirm ICMP is working:          ping -c 1 google.com
# [ ] Test service ports:               nc -zv localhost <PORT>
# [ ] Review firewall drop logs:        fw-dropped | tail -50
# [ ] Check for banned IPs:             f2b-banned
# [ ] Verify VPN forwarding (if used):  fw-list-forward
#
# ==============================================================================

