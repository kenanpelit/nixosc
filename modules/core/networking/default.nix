# modules/core/networking/default.nix
# ==============================================================================
# Networking & TCP/IP Stack Configuration Module
# ==============================================================================
#
# Module: modules/core/networking
# Author: Kenan Pelit
# Date:   2025-09-04
#
# Scope:
#   - Hostname, NetworkManager, systemd-resolved
#   - Mullvad VPN & WireGuard integration
#   - TCP/IP stack optimizations (BBR + FQ, buffer tuning, ECN)
#   - Dynamic TCP tuning based on system memory (>=32GB gets high profile)
#   - Network diagnostic tools and aliases
#
# Design Notes:
#   - Firewall rules belong in security/default.nix (only enable here)
#   - NM-wait-online disabled to reduce boot blocking
#   - Mullvad DNS handled via mkMerge based on VPN state
#   - IPv6 disabled by default (can cause handshake issues on some networks)
#
# ==============================================================================

{ config, lib, pkgs, host, ... }:

let
  inherit (lib) mkIf mkMerge mkDefault;
  toString = builtins.toString;

  # VPN state detection
  hasMullvad = config.services.mullvad-vpn.enable or false;

  # --------------------------------------------------------------------------
  # TCP Profile Parameters
  # --------------------------------------------------------------------------
  # High-performance profile for systems with >=32GB RAM
  
  high = {
    rmem               = "4096 262144 16777216";  # 16MB max receive buffer
    wmem               = "4096 262144 16777216";  # 16MB max send buffer
    rmem_max           = 16777216;
    wmem_max           = 16777216;
    rmem_default       = 524288;
    wmem_default       = 524288;
    netdev_max_backlog = 5000;
    somaxconn          = 1024;
    tcp_max_syn_backlog = 2048;
    tcp_max_tw_buckets  = 2000000;
    tcp_mem            = "786432 1048576 3145728";
    udp_mem            = "393216 524288 1572864";
    conntrack_max      = 262144;
  };

  # Standard profile for systems with <32GB RAM
  std = {
    rmem               = "4096 131072 8388608";   # 8MB max receive buffer
    wmem               = "4096 131072 8388608";   # 8MB max send buffer
    rmem_max           = 8388608;
    wmem_max           = 8388608;
    rmem_default       = 262144;
    wmem_default       = 262144;
    netdev_max_backlog = 3000;
    somaxconn          = 512;
    tcp_max_syn_backlog = 1024;
    tcp_max_tw_buckets  = 1000000;
    tcp_mem            = "196608 262144 786432";
    udp_mem            = "98304 131072 393216";
    conntrack_max      = 131072;
  };

  # Tool paths
  awk    = "${pkgs.gawk}/bin/awk";
  grep   = "${pkgs.gnugrep}/bin/grep";
  sysctl = "${pkgs.procps}/bin/sysctl";

  # Memory detection script
  detectMemoryScript = pkgs.writeShellScript "detect-memory" ''
    #!${pkgs.bash}/bin/bash
    set -euo pipefail
    TOTAL_KB=$(${grep} "^MemTotal:" /proc/meminfo | ${awk} '{print $2}')
    echo $((TOTAL_KB / 1024))  # Return MB
  '';
in
{
  # ============================================================================
  # Base Networking Configuration
  # ============================================================================
  
  networking = {
    hostName = "${host}";
    
    # IPv6 disabled (can cause handshake issues on some networks)
    enableIPv6 = false;
    
    # Wi-Fi managed by NetworkManager
    wireless.enable = false;

    # --------------------------------------------------------------------------
    # NetworkManager Configuration
    # --------------------------------------------------------------------------
    networkmanager = {
      enable = true;
      wifi = {
        backend = "wpa_supplicant";
        scanRandMacAddress = true;     # Privacy: randomize MAC during scans
        powersave = false;             # Stability over power saving
      };
      dns = "systemd-resolved";        # Delegate DNS to resolved
    };

    # WireGuard kernel module for VPN tunnels
    wireguard.enable = true;

    # --------------------------------------------------------------------------
    # DNS Configuration
    # --------------------------------------------------------------------------
    # When Mullvad is active, it provides its own DNS
    # Otherwise, use privacy-focused public DNS
    
    nameservers = mkMerge [
      (mkIf (!hasMullvad) [
        "1.1.1.1"    # Cloudflare
        "1.0.0.1"    # Cloudflare backup
        "9.9.9.9"    # Quad9
      ])
      (mkIf hasMullvad [ ])  # Empty when Mullvad is active
    ];

    # Firewall enabled here, rules in security/default.nix
    firewall.enable = true;
  };

  # ============================================================================
  # System Services
  # ============================================================================
  
  services = {
    # --------------------------------------------------------------------------
    # systemd-resolved - Modern DNS Resolver
    # --------------------------------------------------------------------------
    resolved = {
      enable = true;
      dnssec = "allow-downgrade";     # Compatibility mode
      extraConfig = ''
        # Disable local multicast protocols (security)
        LLMNR=no
        MulticastDNS=no
        
        # Enable caching and stub listener
        Cache=yes
        DNSStubListener=yes
        
        # No DoT when using VPN (prevents conflicts)
        DNSOverTLS=no
        
        # Mark as default resolver
        Domains=~.
      '';
    };

    # --------------------------------------------------------------------------
    # Mullvad VPN
    # --------------------------------------------------------------------------
    mullvad-vpn = {
      enable = true;
      package = pkgs.mullvad-vpn;
    };
  };

  # ============================================================================
  # Systemd Services
  # ============================================================================
  
  # Disable network-wait to reduce boot time
  systemd.services."NetworkManager-wait-online".enable = false;

  # --------------------------------------------------------------------------
  # Mullvad Auto-connect Service
  # --------------------------------------------------------------------------
  # Waits for daemon socket and configures VPN with safe defaults
  
  systemd.services."mullvad-autoconnect" = {
    description = "Configure and connect Mullvad once daemon socket is ready";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" "NetworkManager.service" "mullvad-daemon.service" ];
    requires = [ "mullvad-daemon.service" ];
    wants = [ "NetworkManager.service" ];
    
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = lib.getExe (pkgs.writeShellScriptBin "mullvad-autoconnect" ''
        set -euo pipefail

        CLI="${pkgs.mullvad-vpn}/bin/mullvad"

        # Wait for daemon socket (max 30s)
        tries=0
        until "$CLI" status >/dev/null 2>&1; do
          tries=$((tries+1))
          if [ "$tries" -ge 30 ]; then
            printf 'mullvad-daemon socket not ready after %ss\n' "$tries" >&2
            exit 1
          fi
          sleep 1
        done

        # Configure safe defaults
        "$CLI" auto-connect set on || true
        "$CLI" dns set default --block-ads --block-trackers || true
        "$CLI" relay set location any || true

        # Try connecting (3 attempts)
        for i in 1 2 3; do
          if "$CLI" connect; then
            exit 0
          fi
          sleep 2
        done

        # Final attempt with relaxed settings
        "$CLI" connect || true
        exit 0
      '');
    };
  };

  # --------------------------------------------------------------------------
  # Dynamic TCP Tuning Service
  # --------------------------------------------------------------------------
  # Applies high-performance settings on systems with >=32GB RAM
  
  systemd.services.dynamic-tcp-tuning = {
    description = "Apply dynamic TCP tuning based on total system memory";
    wantedBy = [ "multi-user.target" ];
    after  = [ "sysinit.target" ];
    before = [ "NetworkManager.service" "mullvad-daemon.service" ];
    
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = pkgs.writeShellScript "apply-tcp-tuning" ''
        #!${pkgs.bash}/bin/bash
        set -euo pipefail

        TOTAL_MB=$(${detectMemoryScript})
        TOTAL_GB=$((TOTAL_MB / 1024))
        echo "System RAM: $TOTAL_GB GB"

        if [[ "$TOTAL_MB" -ge 32768 ]]; then
          echo "Applying HIGH memory TCP profile (32GB+)..."
          ${sysctl} -w net.ipv4.tcp_rmem="${high.rmem}"
          ${sysctl} -w net.ipv4.tcp_wmem="${high.wmem}"
          ${sysctl} -w net.core.rmem_max=${toString high.rmem_max}
          ${sysctl} -w net.core.wmem_max=${toString high.wmem_max}
          ${sysctl} -w net.core.rmem_default=${toString high.rmem_default}
          ${sysctl} -w net.core.wmem_default=${toString high.wmem_default}
          ${sysctl} -w net.core.netdev_max_backlog=${toString high.netdev_max_backlog}
          ${sysctl} -w net.core.somaxconn=${toString high.somaxconn}
          ${sysctl} -w net.ipv4.tcp_max_syn_backlog=${toString high.tcp_max_syn_backlog}
          ${sysctl} -w net.ipv4.tcp_max_tw_buckets=${toString high.tcp_max_tw_buckets}
          ${sysctl} -w net.ipv4.tcp_mem="${high.tcp_mem}"
          ${sysctl} -w net.ipv4.udp_mem="${high.udp_mem}"
          ${sysctl} -w net.netfilter.nf_conntrack_max=${toString high.conntrack_max}
          echo "✓ High profile applied: 16MB buffers, backlog=5000, conntrack=262k"
        else
          echo "Standard profile via sysctl (mkDefault) already active."
          echo "✓ Standard: 8MB buffers, backlog=3000, conntrack=131k"
        fi

        echo "Congestion control: $(${sysctl} -n net.ipv4.tcp_congestion_control)"
      '';
    };
  };

  # ============================================================================
  # TCP/IP Stack Kernel Parameters
  # ============================================================================
  
  boot.kernel.sysctl = {
    # --------------------------------------------------------------------------
    # Queue Management & Congestion Control
    # --------------------------------------------------------------------------
    "net.core.default_qdisc" = "fq";              # Fair queuing for pacing
    "net.ipv4.tcp_congestion_control" = "bbr";    # BBR congestion control

    # Ephemeral port range (for high client workloads)
    "net.ipv4.ip_local_port_range" = "1024 65535";

    # --------------------------------------------------------------------------
    # Buffer Defaults (overridden by dynamic tuning if >=32GB RAM)
    # --------------------------------------------------------------------------
    "net.core.rmem_max"     = mkDefault std.rmem_max;
    "net.core.rmem_default" = mkDefault std.rmem_default;
    "net.core.wmem_max"     = mkDefault std.wmem_max;
    "net.core.wmem_default" = mkDefault std.wmem_default;

    # --------------------------------------------------------------------------
    # Network Device Settings
    # --------------------------------------------------------------------------
    "net.core.netdev_max_backlog" = mkDefault std.netdev_max_backlog;
    "net.core.netdev_budget"      = 300;
    "net.core.netdev_budget_usecs" = 8000;        # Smooths latency under load

    # Listen backlog
    "net.core.somaxconn" = mkDefault std.somaxconn;

    # --------------------------------------------------------------------------
    # Security & Performance
    # --------------------------------------------------------------------------
    # eBPF JIT hardening
    "net.core.bpf_jit_enable" = 1;
    "net.core.bpf_jit_harden" = 1;

    # TCP Fast Open (client + server)
    "net.ipv4.tcp_fastopen" = 3;

    # --------------------------------------------------------------------------
    # TCP/UDP Memory Management
    # --------------------------------------------------------------------------
    "net.ipv4.tcp_rmem" = mkDefault std.rmem;
    "net.ipv4.tcp_wmem" = mkDefault std.wmem;
    "net.ipv4.tcp_mem"  = mkDefault std.tcp_mem;
    "net.ipv4.udp_mem"  = mkDefault std.udp_mem;

    # --------------------------------------------------------------------------
    # TCP Features & Optimizations
    # --------------------------------------------------------------------------
    "net.ipv4.tcp_dsack" = 1;                     # Selective ACK
    "net.ipv4.tcp_slow_start_after_idle" = 0;     # Keep cwnd after idle
    "net.ipv4.tcp_moderate_rcvbuf"       = 1;     # Auto-tune receive buffer
    "net.ipv4.tcp_notsent_lowat" = 16384;         # Limit app buffer bloat
    
    # Path MTU discovery
    "net.ipv4.tcp_mtu_probing" = 1;
    # Enable if tunnels cause MTU issues:
    # "net.ipv4.tcp_base_mss" = 1200;

    # --------------------------------------------------------------------------
    # Connection Management
    # --------------------------------------------------------------------------
    "net.ipv4.tcp_keepalive_time"   = 300;
    "net.ipv4.tcp_keepalive_intvl"  = 30;
    "net.ipv4.tcp_keepalive_probes" = 3;
    "net.ipv4.tcp_fin_timeout"      = 30;
    "net.ipv4.tcp_max_tw_buckets"   = mkDefault std.tcp_max_tw_buckets;

    # Retransmission settings
    "net.ipv4.tcp_retries2"       = 8;
    "net.ipv4.tcp_syn_retries"    = 3;
    "net.ipv4.tcp_synack_retries" = 3;

    # SYN flood protection
    "net.ipv4.tcp_syncookies"      = 1;
    "net.ipv4.tcp_max_syn_backlog" = mkDefault std.tcp_max_syn_backlog;

    # Packet reordering tolerance
    "net.ipv4.tcp_reordering" = 3;

    # ECN support with fallback
    "net.ipv4.tcp_ecn"          = 1;
    "net.ipv4.tcp_ecn_fallback" = 1;

    # F-RTO & RFC1337
    "net.ipv4.tcp_frto"    = 2;
    "net.ipv4.tcp_rfc1337" = 1;

    # --------------------------------------------------------------------------
    # IP Security Hardening
    # --------------------------------------------------------------------------
    # Reverse path filtering (loose mode for VPN/tethering)
    "net.ipv4.conf.all.rp_filter"     = 2;
    "net.ipv4.conf.default.rp_filter" = 2;

    # Disable ICMP redirects and source routing
    "net.ipv4.conf.all.accept_redirects"     = 0;
    "net.ipv4.conf.default.accept_redirects" = 0;
    "net.ipv4.conf.all.secure_redirects"     = 0;
    "net.ipv4.conf.default.secure_redirects" = 0;
    "net.ipv4.conf.all.send_redirects"       = 0;
    "net.ipv4.conf.all.accept_source_route"     = 0;
    "net.ipv4.conf.default.accept_source_route" = 0;
    "net.ipv4.icmp_echo_ignore_broadcasts"      = 1;
    "net.ipv4.icmp_ignore_bogus_error_responses"= 1;

    # IPv6 hardening
    "net.ipv6.conf.all.accept_redirects"     = 0;
    "net.ipv6.conf.default.accept_redirects" = 0;
    "net.ipv6.conf.all.accept_source_route"  = 0;

    # --------------------------------------------------------------------------
    # Connection Tracking (Netfilter)
    # --------------------------------------------------------------------------
    "net.netfilter.nf_conntrack_max"                     = mkDefault std.conntrack_max;
    "net.netfilter.nf_conntrack_tcp_timeout_established" = 432000;  # 5 days
    "net.netfilter.nf_conntrack_tcp_timeout_time_wait"   = 30;
    "net.netfilter.nf_conntrack_tcp_timeout_fin_wait"    = 30;
    "net.netfilter.nf_conntrack_generic_timeout"         = 600;
  };

  # ============================================================================
  # Diagnostic Tools & Utilities
  # ============================================================================
  
  environment.systemPackages = with pkgs; [
    # TCP/IP stack status reporter
    (writeScriptBin "tcp-status" ''
      #!${pkgs.bash}/bin/bash
      set -euo pipefail
      echo "=== TCP/IP Stack Status ==="
      echo
      TOTAL_MB=$(${detectMemoryScript})
      echo "Memory:"
      echo "  System RAM: $((TOTAL_MB / 1024))GB"
      echo
      echo "TCP:"
      echo "  Congestion Control: $(${sysctl} -n net.ipv4.tcp_congestion_control)"
      echo "  Queue Discipline:   $(${sysctl} -n net.core.default_qdisc)"
      echo "  TCP Fast Open:      $(${sysctl} -n net.ipv4.tcp_fastopen)"
      echo "  ECN:                $(${sysctl} -n net.ipv4.tcp_ecn) (fallback: $(${sysctl} -n net.ipv4.tcp_ecn_fallback))"
      echo "  MTU Probing:        $(${sysctl} -n net.ipv4.tcp_mtu_probing)"
      echo "  notsent_lowat:      $(${sysctl} -n net.ipv4.tcp_notsent_lowat 2>/dev/null || echo N/A)"
      echo
      echo "Buffers:"
      echo "  rmem_max: $(${sysctl} -n net.core.rmem_max)"
      echo "  wmem_max: $(${sysctl} -n net.core.wmem_max)"
      echo "  rmem_def: $(${sysctl} -n net.core.rmem_default)"
      echo "  wmem_def: $(${sysctl} -n net.core.wmem_default)"
      echo
      echo "Limits:"
      echo "  netdev_max_backlog: $(${sysctl} -n net.core.netdev_max_backlog)"
      echo "  somaxconn:          $(${sysctl} -n net.core.somaxconn)"
      echo "  nf_conntrack_max:   $(${sysctl} -n net.netfilter.nf_conntrack_max 2>/dev/null || echo N/A)"
      echo
      echo "Interfaces (STATE/MTU):"
      ${pkgs.iproute2}/bin/ip -br link | ${pkgs.gawk}/bin/awk '{printf("  %-16s  %s\n",$1,$3)}'
      echo
      echo "DNS:"
      ${pkgs.systemd}/bin/resolvectl dns | sed -n '1,80p'
      echo
      echo "Default route:"
      ${pkgs.iproute2}/bin/ip route show default
      echo
      echo "Connections:"
      echo -n "  TCP total:     "; ${pkgs.iproute2}/bin/ss -s | ${pkgs.gnugrep}/bin/grep -oP 'TCP:\s+\K\d+'
      echo -n "  TIME-WAIT:     "; ${pkgs.iproute2}/bin/ss -tan state time-wait | wc -l
    '')
  ];

  # ============================================================================
  # Shell Aliases
  # ============================================================================
  
  environment.shellAliases = {
    # WiFi management
    wifi-list       = "nmcli device wifi list";
    wifi-connect    = "nmcli device wifi connect";
    wifi-disconnect = "nmcli connection down";
    wifi-saved      = "nmcli connection show";

    # Network status
    net-status      = "nmcli general status";
    net-connections = "nmcli connection show --active";

    # VPN controls
    vpn-status      = "mullvad status";
    vpn-connect     = "mullvad connect";
    vpn-disconnect  = "mullvad disconnect";
    vpn-relay       = "mullvad relay list";

    # DNS diagnostics
    dns-test        = "resolvectl status";
    dns-leak        = "curl -s https://mullvad.net/en/check | sed -n '1,120p'";
  };
}
