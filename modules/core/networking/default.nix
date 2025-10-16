# ==============================================================================
# Networking & TCP/IP Stack Configuration Module
# ==============================================================================
#
# Module: modules/core/networking
# Author: Kenan Pelit
# Date:   2025-10-09
#
# Scope:
#   - Hostname, NetworkManager, systemd-resolved
#   - Mullvad VPN & WireGuard integration with killswitch
#   - TCP/IP stack optimizations (BBR + FQ, buffer tuning, ECN)
#   - Dynamic TCP tuning based on system memory (≥16GB gets high profile)
#   - IPv6 support with selective disable for problematic interfaces
#   - Network diagnostic tools and aliases
#
# Design Philosophy:
#   - Performance: Modern congestion control (BBR), fair queuing, ECN
#   - Security: Hardened IP stack, MAC randomization, killswitch ready
#   - Reliability: Systemd-native service ordering, robust error handling
#   - Observability: Rich diagnostics and status tools
#
# Key Improvements (v2):
#   - IPv6 enabled by default with per-interface control
#   - Lowered memory threshold (16GB) for high-performance profile
#   - Improved Mullvad auto-connect with systemd restarts
#   - Cached memory detection to avoid repeated calculations
#   - Enhanced MTU handling for WireGuard/VPN scenarios
#   - JSON-based DNS leak testing
#   - BBR version detection in diagnostics
#
# ==============================================================================

{ config, lib, pkgs, host, ... }:

let
  inherit (lib) mkIf mkMerge mkDefault mkForce;
  toString = builtins.toString;

  # --------------------------------------------------------------------------
  # VPN State Detection
  # --------------------------------------------------------------------------
  hasMullvad = config.services.mullvad-vpn.enable or false;

  # --------------------------------------------------------------------------
  # TCP Profile Parameters
  # --------------------------------------------------------------------------
  # Three-tier tuning based on your hardware:
  #
  # ULTRA Profile (≥60GB RAM):
  #   Target: ThinkPad E14 Gen 6 (Core Ultra 7 155H, 64GB)
  #   Note: Threshold is 60GB to account for iGPU shared memory
  #   Use case: Heavy workloads, VMs, containers, high-throughput
  #
  # HIGH Profile (32-59GB RAM):
  #   Reserved for future mid-tier systems
  #
  # STANDARD Profile (<32GB RAM):
  #   Target: ThinkPad X1 Carbon Gen 6 (i7-8650U, 16GB)
  #   Use case: Daily driver, balanced performance/memory
  
  ultra = {
    rmem               = "4096 1048576 67108864";  # 64MB max receive buffer
    wmem               = "4096 1048576 67108864";  # 64MB max send buffer
    rmem_max           = 67108864;
    wmem_max           = 67108864;
    rmem_default       = 2097152;                  # 2MB default
    wmem_default       = 2097152;
    netdev_max_backlog = 32000;                    # Very high packet rate
    somaxconn          = 8192;                     # Many concurrent connections
    tcp_max_syn_backlog = 16384;
    tcp_max_tw_buckets  = 4000000;
    tcp_mem            = "3145728 4194304 6291456"; # 24GB max TCP memory
    udp_mem            = "1572864 2097152 3145728";  # 12GB max UDP memory
    conntrack_max      = 1048576;                  # 1M conntrack entries
  };

  high = {
    rmem               = "4096 524288 33554432";   # 32MB max receive buffer
    wmem               = "4096 524288 33554432";   # 32MB max send buffer
    rmem_max           = 33554432;
    wmem_max           = 33554432;
    rmem_default       = 1048576;                  # 1MB default
    wmem_default       = 1048576;
    netdev_max_backlog = 16000;
    somaxconn          = 4096;
    tcp_max_syn_backlog = 8192;
    tcp_max_tw_buckets  = 2000000;
    tcp_mem            = "1572864 2097152 3145728"; # 12GB max TCP memory
    udp_mem            = "786432 1048576 1572864";  # 6GB max UDP memory
    conntrack_max      = 524288;
  };

  std = {
    rmem               = "4096 262144 16777216";   # 16MB max receive buffer
    wmem               = "4096 262144 16777216";   # 16MB max send buffer
    rmem_max           = 16777216;
    wmem_max           = 16777216;
    rmem_default       = 524288;                   # 512KB default
    wmem_default       = 524288;
    netdev_max_backlog = 5000;
    somaxconn          = 1024;
    tcp_max_syn_backlog = 2048;
    tcp_max_tw_buckets  = 1000000;
    tcp_mem            = "786432 1048576 1572864"; # 6GB max TCP memory
    udp_mem            = "393216 524288 786432";   # 3GB max UDP memory
    conntrack_max      = 262144;
  };

  # --------------------------------------------------------------------------
  # Tool Paths (for consistent script execution)
  # --------------------------------------------------------------------------
  awk    = "${pkgs.gawk}/bin/awk";
  grep   = "${pkgs.gnugrep}/bin/grep";
  sysctl = "${pkgs.procps}/bin/sysctl";
  cat    = "${pkgs.coreutils}/bin/cat";
  mkdir  = "${pkgs.coreutils}/bin/mkdir";
  bash   = "${pkgs.bash}/bin/bash";

  # --------------------------------------------------------------------------
  # Memory Detection Script
  # --------------------------------------------------------------------------
  # Returns total system memory in MB
  # Used for dynamic TCP profile selection
  
  detectMemoryScript = pkgs.writeShellScript "detect-memory" ''
    #!${bash}
    set -euo pipefail
    TOTAL_KB=$(${grep} "^MemTotal:" /proc/meminfo | ${awk} '{print $2}')
    echo $((TOTAL_KB / 1024))
  '';

  # --------------------------------------------------------------------------
  # Memory Profile Cache Script
  # --------------------------------------------------------------------------
  # Caches detected profile to avoid repeated detection
  # Writes to /run/network-tuning-profile (tmpfs, survives until reboot)
  # 
  # Profile tiers:
  #   ultra: ≥60GB RAM (E14 Gen 6 - accounts for iGPU shared memory)
  #   high:  32-59GB RAM (future systems)
  #   std:   <32GB RAM (X1 Carbon Gen 6 - i7-8650U)
  
  detectAndCacheProfile = pkgs.writeShellScript "detect-and-cache-profile" ''
    #!${bash}
    set -euo pipefail
    
    CACHE_FILE="/run/network-tuning-profile"
    ${mkdir} -p "$(dirname "$CACHE_FILE")"
    
    TOTAL_MB=$(${detectMemoryScript})
    TOTAL_GB=$((TOTAL_MB / 1024))
    
    if [[ "$TOTAL_MB" -ge 61440 ]]; then
      # ≥60GB: ULTRA profile for heavy workloads (accounts for iGPU shared memory)
      echo "ultra" > "$CACHE_FILE"
      echo "Detected ''${TOTAL_GB}GB RAM → ULTRA performance profile (E14 Gen 6)"
      echo "  Target: 64MB buffers, 32k backlog, 1M conntrack"
    elif [[ "$TOTAL_MB" -ge 32768 ]]; then
      # 32-63GB: HIGH profile (reserved for future systems)
      echo "high" > "$CACHE_FILE"
      echo "Detected ''${TOTAL_GB}GB RAM → HIGH performance profile"
      echo "  Target: 32MB buffers, 16k backlog, 524k conntrack"
    else
      # <32GB: STANDARD profile for balanced systems
      echo "std" > "$CACHE_FILE"
      echo "Detected ''${TOTAL_GB}GB RAM → STANDARD profile (X1 Carbon Gen 6)"
      echo "  Target: 16MB buffers, 5k backlog, 262k conntrack"
    fi
  '';

in
{
  # ============================================================================
  # Base Networking Configuration
  # ============================================================================
  
  networking = {
    hostName = "${host}";
    
    # --------------------------------------------------------------------------
    # IPv6 Configuration
    # --------------------------------------------------------------------------
    # Enabled by default for modern internet compatibility
    # Can be disabled per-interface if causing issues:
    #   networking.interfaces.<name>.ipv6.enable = false;
    
    enableIPv6 = mkDefault true;
    
    # Privacy extensions for IPv6 (RFC 4941)
    # Generates temporary addresses to prevent tracking
    tempAddresses = mkDefault "default";
    
    # Wi-Fi managed by NetworkManager (not wpa_supplicant directly)
    wireless.enable = false;

    # --------------------------------------------------------------------------
    # NetworkManager Configuration
    # --------------------------------------------------------------------------
    networkmanager = {
      enable = true;
      
      # Wi-Fi backend and privacy settings
      wifi = {
        backend = "wpa_supplicant";
        scanRandMacAddress = true;     # Privacy: randomize MAC during scans
        powersave = false;             # Stability > power saving (reduce disconnects)
        macAddress = "preserve";       # Keep MAC after connection (some networks require this)
      };
      
      # Delegate DNS resolution to systemd-resolved
      dns = "systemd-resolved";
      
      # Additional privacy/security settings
      ethernet.macAddress = "preserve";
      
      # Connection-specific settings
      settings = {
        connection = {
          # Auto-connect to known networks
          "connection.autoconnect-retries" = 0;  # Infinite retries
        };
        
        # IPv6 privacy
        ipv6 = {
          "ipv6.ip6-privacy" = 2;  # Prefer temporary addresses
        };
      };
    };

    # --------------------------------------------------------------------------
    # WireGuard Support
    # --------------------------------------------------------------------------
    # Kernel module for VPN tunnels (Mullvad uses WireGuard)
    wireguard.enable = true;

    # --------------------------------------------------------------------------
    # DNS Configuration
    # --------------------------------------------------------------------------
    # When Mullvad is active, it provides its own DNS (with ad/tracker blocking)
    # Otherwise, use privacy-focused public DNS servers
    # Priority: Privacy > Speed > Reliability
    
    nameservers = mkMerge [
      (mkIf (!hasMullvad) [
        "1.1.1.1"        # Cloudflare (fast, private)
        "1.0.0.1"        # Cloudflare backup
        "2606:4700:4700::1111"  # Cloudflare IPv6
        "9.9.9.9"        # Quad9 (malware filtering)
        "2620:fe::fe"    # Quad9 IPv6
      ])
      (mkIf hasMullvad [ ])  # Empty when Mullvad provides DNS
    ];

    # --------------------------------------------------------------------------
    # Firewall
    # --------------------------------------------------------------------------
    # Enabled here, detailed rules should be in security/default.nix
    # This provides the foundation for VPN killswitch functionality
    firewall = {
      enable = true;
      
      # Log refused connections for debugging
      logRefusedConnections = mkDefault false;  # Reduce log spam
      
      # Allow ping responses (useful for diagnostics)
      allowPing = mkDefault true;
    };
  };

  # ============================================================================
  # System Services
  # ============================================================================
  
  services = {
    # --------------------------------------------------------------------------
    # systemd-resolved - Modern DNS Resolver
    # --------------------------------------------------------------------------
    # Features: Caching, DNSSEC validation, mDNS/LLMNR, per-link DNS
    
    resolved = {
      enable = true;
      
      # DNSSEC validation (allow-downgrade for compatibility)
      # Some networks/ISPs break DNSSEC, this prevents connectivity issues
      dnssec = "allow-downgrade";
      
      # Fallback DNS (used if configured DNS servers fail)
      fallbackDns = [ "1.1.1.1" "9.9.9.9" ];
      
      extraConfig = ''
        # ------------------------------------------------------------------
        # Local Discovery Protocols (disabled for security)
        # ------------------------------------------------------------------
        # LLMNR: Link-Local Multicast Name Resolution (Windows-style)
        # mDNS: Multicast DNS (Bonjour/Avahi)
        # Both can leak queries on untrusted networks
        LLMNR=no
        MulticastDNS=no
        
        # ------------------------------------------------------------------
        # Performance & Caching
        # ------------------------------------------------------------------
        Cache=yes
        CacheFromLocalhost=no
        DNSStubListener=yes
        DNSStubListenerExtra=127.0.0.54
        
        # ------------------------------------------------------------------
        # DNS-over-TLS (DoT)
        # ------------------------------------------------------------------
        # Disabled when using VPN (Mullvad already encrypts DNS)
        # Enable if not using VPN: DNSOverTLS=opportunistic
        DNSOverTLS=no
        
        # ------------------------------------------------------------------
        # Routing & Default Domain
        # ------------------------------------------------------------------
        # ~. makes this the default DNS resolver for all domains
        Domains=~.
        
        # ------------------------------------------------------------------
        # DNSSEC Settings
        # ------------------------------------------------------------------
        # Validate DNSSEC but allow fallback if broken
        # NegativeTrustAnchors can be added here for broken domains
      '';
    };

    # --------------------------------------------------------------------------
    # Mullvad VPN Service
    # --------------------------------------------------------------------------
    # Provides: WireGuard-based VPN, split tunneling, DNS control
    mullvad-vpn = {
      enable = true;
      package = pkgs.mullvad-vpn;
      
      # Enable killswitch (block internet if VPN drops)
      # This is enforced via firewall rules
      enableExcludeWrapper = true;  # Enable split tunneling wrapper
    };
  };

  # ============================================================================
  # Systemd Services
  # ============================================================================
  
  # --------------------------------------------------------------------------
  # Disable NetworkManager-wait-online
  # --------------------------------------------------------------------------
  # Reason: Blocks boot until network is "online"
  # Impact: Faster boots, especially with slow DHCP/VPN
  # Tradeoff: Services requiring network may start before connectivity
  systemd.services."NetworkManager-wait-online".enable = false;

  # --------------------------------------------------------------------------
  # Network Tuning Profile Detection Service
  # --------------------------------------------------------------------------
  # Runs early in boot to detect system memory and cache the profile
  # This cache is used by the tuning service to avoid repeated detection
  
  systemd.services."network-profile-detect" = {
    description = "Detect and cache network tuning profile based on system memory";
    wantedBy = [ "sysinit.target" ];
    before = [ "network-pre.target" ];
    
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = detectAndCacheProfile;
    };
  };

  # --------------------------------------------------------------------------
  # Dynamic TCP Tuning Service
  # --------------------------------------------------------------------------
  # Applies performance settings based on detected memory tier
  # Uses cached profile from network-profile-detect service
  # Runs before network services to ensure settings are applied early
  
  systemd.services."network-tcp-tuning" = {
    description = "Apply dynamic TCP/IP stack tuning based on system profile";
    wantedBy = [ "multi-user.target" ];
    after = [ "network-profile-detect.service" "sysinit.target" ];
    before = [ "network-pre.target" "NetworkManager.service" "mullvad-daemon.service" ];
    requires = [ "network-profile-detect.service" ];
    
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = pkgs.writeShellScript "apply-tcp-tuning" ''
        #!${bash}
        set -euo pipefail

        CACHE_FILE="/run/network-tuning-profile"
        
        if [[ ! -f "$CACHE_FILE" ]]; then
          echo "ERROR: Profile cache not found. Detection service may have failed."
          exit 1
        fi
        
        PROFILE=$(${cat} "$CACHE_FILE")
        echo "Applying $PROFILE performance profile..."

        case "$PROFILE" in
          ultra)
            # ----------------------------------------------------------------
            # ULTRA PERFORMANCE PROFILE (≥64GB RAM)
            # Target: ThinkPad E14 Gen 6 (Core Ultra 7 155H, 64GB)
            # ----------------------------------------------------------------
            echo "→ Buffer sizes: 64MB max, 2MB default"
            ${sysctl} -w net.ipv4.tcp_rmem="${ultra.rmem}"
            ${sysctl} -w net.ipv4.tcp_wmem="${ultra.wmem}"
            ${sysctl} -w net.core.rmem_max=${toString ultra.rmem_max}
            ${sysctl} -w net.core.wmem_max=${toString ultra.wmem_max}
            ${sysctl} -w net.core.rmem_default=${toString ultra.rmem_default}
            ${sysctl} -w net.core.wmem_default=${toString ultra.wmem_default}
            
            echo "→ Queue limits: backlog=32000, somaxconn=8192"
            ${sysctl} -w net.core.netdev_max_backlog=${toString ultra.netdev_max_backlog}
            ${sysctl} -w net.core.somaxconn=${toString ultra.somaxconn}
            ${sysctl} -w net.ipv4.tcp_max_syn_backlog=${toString ultra.tcp_max_syn_backlog}
            
            echo "→ Connection tracking: max=1048576 (1M buckets)"
            ${sysctl} -w net.ipv4.tcp_max_tw_buckets=${toString ultra.tcp_max_tw_buckets}
            ${sysctl} -w net.netfilter.nf_conntrack_max=${toString ultra.conntrack_max} 2>/dev/null || true
            
            echo "→ Memory pools: TCP=24GB, UDP=12GB"
            ${sysctl} -w net.ipv4.tcp_mem="${ultra.tcp_mem}"
            ${sysctl} -w net.ipv4.udp_mem="${ultra.udp_mem}"
            
            echo "✓ ULTRA profile active (optimized for Core Ultra 7 155H)"
            ;;
            
          high)
            # ----------------------------------------------------------------
            # HIGH PERFORMANCE PROFILE (32-63GB RAM)
            # Reserved for future mid-tier systems
            # ----------------------------------------------------------------
            echo "→ Buffer sizes: 32MB max, 1MB default"
            ${sysctl} -w net.ipv4.tcp_rmem="${high.rmem}"
            ${sysctl} -w net.ipv4.tcp_wmem="${high.wmem}"
            ${sysctl} -w net.core.rmem_max=${toString high.rmem_max}
            ${sysctl} -w net.core.wmem_max=${toString high.wmem_max}
            ${sysctl} -w net.core.rmem_default=${toString high.rmem_default}
            ${sysctl} -w net.core.wmem_default=${toString high.wmem_default}
            
            echo "→ Queue limits: backlog=16000, somaxconn=4096"
            ${sysctl} -w net.core.netdev_max_backlog=${toString high.netdev_max_backlog}
            ${sysctl} -w net.core.somaxconn=${toString high.somaxconn}
            ${sysctl} -w net.ipv4.tcp_max_syn_backlog=${toString high.tcp_max_syn_backlog}
            
            echo "→ Connection tracking: max=524288 (524k buckets)"
            ${sysctl} -w net.ipv4.tcp_max_tw_buckets=${toString high.tcp_max_tw_buckets}
            ${sysctl} -w net.netfilter.nf_conntrack_max=${toString high.conntrack_max} 2>/dev/null || true
            
            echo "→ Memory pools: TCP=12GB, UDP=6GB"
            ${sysctl} -w net.ipv4.tcp_mem="${high.tcp_mem}"
            ${sysctl} -w net.ipv4.udp_mem="${high.udp_mem}"
            
            echo "✓ HIGH profile active"
            ;;
            
          std|*)
            # ----------------------------------------------------------------
            # STANDARD PROFILE (<32GB RAM)
            # Target: ThinkPad X1 Carbon Gen 6 (i7-8650U, 16GB)
            # ----------------------------------------------------------------
            echo "→ Using STANDARD profile (sysctl defaults with optimizations)"
            echo "  Buffer sizes: 16MB max, 512KB default"
            echo "  Queue limits: backlog=5000, somaxconn=1024"
            echo "  Connection tracking: max=262144 (262k buckets)"
            echo "✓ STANDARD profile active (optimized for i7-8650U)"
            ;;
        esac

        # Show applied congestion control
        CC=$(${sysctl} -n net.ipv4.tcp_congestion_control)
        QDISC=$(${sysctl} -n net.core.default_qdisc)
        echo "→ Congestion control: $CC + $QDISC"
        
        # BBR version detection (if available)
        if [[ -f /sys/module/tcp_bbr/version ]]; then
          BBR_VER=$(${cat} /sys/module/tcp_bbr/version)
          echo "→ BBR version: $BBR_VER"
        fi
      '';
    };
  };

  # --------------------------------------------------------------------------
  # Mullvad Auto-Connect Service
  # --------------------------------------------------------------------------
  # Waits for daemon readiness and configures VPN with safe defaults
  # Features:
  #   - Auto-connect on boot
  #   - DNS-based ad/tracker blocking
  #   - Automatic reconnection on failure
  #   - Graceful degradation if daemon is slow to start
  
  systemd.services."mullvad-autoconnect" = mkIf hasMullvad {
    description = "Configure and auto-connect Mullvad VPN on boot";
    #wantedBy = [ "multi-user.target" ];
    wantedBy = [ ];
    after = [ 
      "network-online.target"
      "NetworkManager.service" 
      "mullvad-daemon.service" 
    ];
    requires = [ "mullvad-daemon.service" ];
    wants = [ "network-online.target" ];
    
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      Restart = "on-failure";
      RestartSec = "10s";
      
      ExecStart = lib.getExe (pkgs.writeShellScriptBin "mullvad-autoconnect" ''
        set -euo pipefail

        CLI="${pkgs.mullvad-vpn}/bin/mullvad"
        MAX_WAIT=30
        
        # ----------------------------------------------------------------
        # Wait for daemon socket
        # ----------------------------------------------------------------
        echo "Waiting for mullvad-daemon socket..."
        for i in $(seq 1 $MAX_WAIT); do
          if "$CLI" status >/dev/null 2>&1; then
            echo "✓ Daemon ready after ''${i}s"
            break
          fi
          
          if [[ "$i" -eq "$MAX_WAIT" ]]; then
            echo "✗ Daemon not ready after ''${MAX_WAIT}s, giving up"
            exit 1
          fi
          
          sleep 1
        done

        # ----------------------------------------------------------------
        # Configure VPN settings
        # ----------------------------------------------------------------
        echo "Configuring Mullvad..."
        
        # Auto-connect on network change
        "$CLI" auto-connect set on || echo "⚠ Failed to set auto-connect"
        
        # DNS with ad/tracker blocking
        "$CLI" dns set default --block-ads --block-trackers || echo "⚠ Failed to set DNS"
        
        # Killswitch (lockdown mode)
        # Blocks all non-VPN traffic if VPN disconnects
        #"$CLI" lockdown-mode set on || echo "⚠ Failed to set lockdown mode"
        
        # Optional: Set specific relay location
        # "$CLI" relay set location se got || true

        # ----------------------------------------------------------------
        # Attempt connection
        # ----------------------------------------------------------------
        echo "Connecting to VPN..."
        if "$CLI" connect; then
          echo "✓ Connected successfully"
          exit 0
        fi
        
        # Connection failed, systemd will retry due to Restart=on-failure
        echo "✗ Connection failed, will retry in 10s..."
        exit 1
      '');
    };
  };

  # ============================================================================
  # TCP/IP Stack Kernel Parameters (sysctl)
  # ============================================================================
  # These are baseline settings applied at boot
  # Dynamic tuning service overrides buffer/queue settings for high-mem systems
  
  boot.kernel.sysctl = {
    # --------------------------------------------------------------------------
    # Core Network Performance
    # --------------------------------------------------------------------------
    
    # Queue Discipline: Fair Queuing (required for optimal BBR performance)
    # FQ provides per-flow queuing and pacing, critical for BBR
    "net.core.default_qdisc" = "fq";
    
    # Congestion Control: BBR (Bottleneck Bandwidth and RTT)
    # Modern algorithm that maximizes throughput while minimizing latency
    # Superior to CUBIC for high-bandwidth, variable-latency links (VPNs, cellular)
    "net.ipv4.tcp_congestion_control" = "bbr";

    # Ephemeral port range for outgoing connections
    # Wider range = more simultaneous connections possible
    "net.ipv4.ip_local_port_range" = "1024 65535";

    # --------------------------------------------------------------------------
    # Buffer Defaults (Standard Profile)
    # --------------------------------------------------------------------------
    # These mkDefault values are overridden by dynamic tuning for high-mem systems
    
    "net.core.rmem_max"     = mkDefault std.rmem_max;
    "net.core.rmem_default" = mkDefault std.rmem_default;
    "net.core.wmem_max"     = mkDefault std.wmem_max;
    "net.core.wmem_default" = mkDefault std.wmem_default;

    # --------------------------------------------------------------------------
    # Network Device & Queue Settings
    # --------------------------------------------------------------------------
    
    # Incoming packet queue (before processing)
    # Higher = better burst handling, but more memory usage
    "net.core.netdev_max_backlog" = mkDefault std.netdev_max_backlog;
    
    # NAPI polling budget (packets processed per interrupt)
    "net.core.netdev_budget" = 300;
    
    # NAPI polling time budget (microseconds per interrupt)
    # Balance between latency and throughput
    "net.core.netdev_budget_usecs" = 8000;

    # Listen socket backlog (pending connections)
    "net.core.somaxconn" = mkDefault std.somaxconn;

    # --------------------------------------------------------------------------
    # eBPF Security
    # --------------------------------------------------------------------------
    # Enable JIT compilation for eBPF (performance)
    "net.core.bpf_jit_enable" = 1;
    
    # Harden JIT against some exploits (minimal performance impact)
    "net.core.bpf_jit_harden" = 1;

    # --------------------------------------------------------------------------
    # TCP Features
    # --------------------------------------------------------------------------
    
    # TCP Fast Open (TFO): Reduce connection latency
    # 3 = enable for both client and server
    # Requires application support, but safe to enable
    "net.ipv4.tcp_fastopen" = 3;

    # Duplicate SACK (D-SACK): Improve loss detection
    "net.ipv4.tcp_dsack" = 1;
    
    # Disable slow start after idle (better for bursty traffic)
    # BBR handles pacing, so this is safe
    "net.ipv4.tcp_slow_start_after_idle" = 0;
    
    # Auto-tune receive buffer based on RTT and throughput
    "net.ipv4.tcp_moderate_rcvbuf" = 1;
    
    # Prevent application from queuing too much unsent data
    # Reduces latency for interactive traffic
    "net.ipv4.tcp_notsent_lowat" = 16384;

    # --------------------------------------------------------------------------
    # Path MTU Discovery
    # --------------------------------------------------------------------------
    # Automatically discover optimal packet size
    # 1 = enable PMTUD, fall back to MSS if blackhole detected
    "net.ipv4.tcp_mtu_probing" = 1;
    
    # Base MSS for PMTUD (useful for VPN/tunnel scenarios)
    # Uncomment if experiencing MTU issues with WireGuard
    # "net.ipv4.tcp_base_mss" = 1240;  # WireGuard-safe value

    # --------------------------------------------------------------------------
    # TCP Memory Management
    # --------------------------------------------------------------------------
    # Auto-tuning ranges: min, pressure, max (in pages, 4KB each)
    "net.ipv4.tcp_rmem" = mkDefault std.rmem;
    "net.ipv4.tcp_wmem" = mkDefault std.wmem;
    
    # Global TCP memory limits (pages)
    "net.ipv4.tcp_mem" = mkDefault std.tcp_mem;
    
    # Global UDP memory limits (pages)
    "net.ipv4.udp_mem" = mkDefault std.udp_mem;

    # --------------------------------------------------------------------------
    # Connection Lifecycle
    # --------------------------------------------------------------------------
    
    # TCP Keepalive: Detect dead connections
    "net.ipv4.tcp_keepalive_time"   = 300;   # Start probing after 5min idle
    "net.ipv4.tcp_keepalive_intvl"  = 30;    # Probe interval
    "net.ipv4.tcp_keepalive_probes" = 3;     # Give up after 3 failed probes
    
    # FIN-WAIT-2 timeout (waiting for remote FIN)
    "net.ipv4.tcp_fin_timeout" = 30;
    
    # TIME-WAIT bucket limit (2MSL state)
    # Higher = better for high connection rate, but more memory
    "net.ipv4.tcp_max_tw_buckets" = mkDefault std.tcp_max_tw_buckets;
    
    # Enable TIME-WAIT reuse (safe with timestamps)
    "net.ipv4.tcp_tw_reuse" = 1;

    # --------------------------------------------------------------------------
    # Retransmission & Timeout
    # --------------------------------------------------------------------------
    
    # Retransmission attempts before giving up
    "net.ipv4.tcp_retries2" = 8;      # 15-30min timeout
    
    # SYN retransmits (connection setup)
    "net.ipv4.tcp_syn_retries" = 3;   # ~63s total
    
    # SYN-ACK retransmits (server side)
    "net.ipv4.tcp_synack_retries" = 3;

    # --------------------------------------------------------------------------
    # SYN Flood Protection
    # --------------------------------------------------------------------------
    
    # Enable SYN cookies (fallback when backlog full)
    "net.ipv4.tcp_syncookies" = 1;
    
    # SYN backlog size
    "net.ipv4.tcp_max_syn_backlog" = mkDefault std.tcp_max_syn_backlog;

    # --------------------------------------------------------------------------
    # Advanced TCP Features
    # --------------------------------------------------------------------------
    
    # Packet reordering tolerance (modern networks have reordering)
    "net.ipv4.tcp_reordering" = 3;
    
    # Explicit Congestion Notification (ECN)
    # 1 = request ECN, fall back if not supported
    "net.ipv4.tcp_ecn" = 1;
    "net.ipv4.tcp_ecn_fallback" = 1;
    
    # Forward RTO-Recovery (F-RTO): Improved spurious timeout detection
    # 2 = most aggressive, best for long-delay links (VPN, satellite)
    "net.ipv4.tcp_frto" = 2;
    
    # RFC 1337 TIME-WAIT assassination protection
    "net.ipv4.tcp_rfc1337" = 1;
    
    # TCP timestamps (required for some features)
    "net.ipv4.tcp_timestamps" = 1;
    
    # SACK (Selective Acknowledgment)
    "net.ipv4.tcp_sack" = 1;

    # --------------------------------------------------------------------------
    # IP Security Hardening
    # --------------------------------------------------------------------------
    
    # Reverse Path Filtering (anti-spoofing)
    # 2 = loose mode (necessary for VPN, tethering, asymmetric routing)
    "net.ipv4.conf.all.rp_filter"     = 2;
    "net.ipv4.conf.default.rp_filter" = 2;
    
    # Disable ICMP redirect acceptance (prevent MITM)
    "net.ipv4.conf.all.accept_redirects"     = 0;
    "net.ipv4.conf.default.accept_redirects" = 0;
    "net.ipv4.conf.all.secure_redirects"     = 0;
    "net.ipv4.conf.default.secure_redirects" = 0;
    
    # Disable sending ICMP redirects
    "net.ipv4.conf.all.send_redirects" = 0;
    
    # Disable source routing (security risk)
    "net.ipv4.conf.all.accept_source_route"     = 0;
    "net.ipv4.conf.default.accept_source_route" = 0;
    
    # Ignore ICMP broadcast requests (smurf attack protection)
    "net.ipv4.icmp_echo_ignore_broadcasts" = 1;
    
    # Ignore bogus ICMP error responses
    "net.ipv4.icmp_ignore_bogus_error_responses" = 1;
    
    # Log martian packets (debugging, can be noisy)
    "net.ipv4.conf.all.log_martians" = mkDefault 0;

    # --------------------------------------------------------------------------
    # IPv6 Security (if enabled)
    # --------------------------------------------------------------------------
    
    # Disable IPv6 redirects
    "net.ipv6.conf.all.accept_redirects"     = 0;
    "net.ipv6.conf.default.accept_redirects" = 0;
    
    # Disable IPv6 source routing
    "net.ipv6.conf.all.accept_source_route" = 0;
    
    # Disable router advertisements on all interfaces by default
    # Override per-interface if using SLAAC
    "net.ipv6.conf.all.accept_ra" = 0;
    "net.ipv6.conf.default.accept_ra" = 0;

    # --------------------------------------------------------------------------
    # Connection Tracking (Netfilter/iptables/nftables)
    # --------------------------------------------------------------------------
    
    # Maximum tracked connections
    # Important for NAT, stateful firewall, VPN
    "net.netfilter.nf_conntrack_max" = mkDefault std.conntrack_max;
    
    # Connection tracking timeouts
    "net.netfilter.nf_conntrack_tcp_timeout_established" = 432000;  # 5 days
    "net.netfilter.nf_conntrack_tcp_timeout_time_wait"   = 30;
    "net.netfilter.nf_conntrack_tcp_timeout_close_wait"  = 30;
    "net.netfilter.nf_conntrack_tcp_timeout_fin_wait"    = 30;
    "net.netfilter.nf_conntrack_udp_timeout"             = 60;
    "net.netfilter.nf_conntrack_generic_timeout"         = 600;  # 10min for other protocols
    
    # Conntrack helpers (disable for security, enable if needed for specific protocols)
    "net.netfilter.nf_conntrack_helper" = 0;

    # --------------------------------------------------------------------------
    # Additional Performance Tuning
    # --------------------------------------------------------------------------
    
    # TCP window scaling (required for high-bandwidth links)
    "net.ipv4.tcp_window_scaling" = 1;
    
    # Increase ARP cache size (useful for large LANs)
    "net.ipv4.neigh.default.gc_thresh1" = 4096;
    "net.ipv4.neigh.default.gc_thresh2" = 8192;
    "net.ipv4.neigh.default.gc_thresh3" = 16384;
    
    # ARP cache timeout
    "net.ipv4.neigh.default.gc_stale_time" = 120;
    
    # Route cache settings
    "net.ipv4.route.gc_timeout" = 100;
  };

  # ============================================================================
  # Kernel Modules
  # ============================================================================
  # Ensure required modules are loaded
  
  boot.kernelModules = [
    "tcp_bbr"           # BBR congestion control
    "sch_fq"            # Fair queuing scheduler
    "wireguard"         # WireGuard VPN
  ];

  # ============================================================================
  # Diagnostic Tools & Utilities
  # ============================================================================
  
  environment.systemPackages = with pkgs; [
    # --------------------------------------------------------------------------
    # Core Network Tools
    # --------------------------------------------------------------------------
    iproute2            # ip, ss, tc
    iputils             # ping, traceroute
    bind                # dig, nslookup
    mtr                 # Advanced traceroute
    tcpdump             # Packet capture
    ethtool             # NIC diagnostics
    
    # --------------------------------------------------------------------------
    # Bandwidth & Performance Testing
    # --------------------------------------------------------------------------
    iperf3              # Network performance
    speedtest-cli       # Internet speed test
    
    # --------------------------------------------------------------------------
    # DNS & TLS Testing
    # --------------------------------------------------------------------------
    doggo               # Modern DNS client
    
    # --------------------------------------------------------------------------
    # Monitoring & Analysis
    # --------------------------------------------------------------------------
    nethogs             # Per-process bandwidth monitor
    iftop               # Real-time bandwidth usage
    nload               # Network traffic visualizer
    
    # --------------------------------------------------------------------------
    # TCP/IP Stack Status Reporter
    # --------------------------------------------------------------------------
    (writeScriptBin "tcp-status" ''
      #!${bash}
      set -euo pipefail
      
      # Colors for better readability
      BOLD='\033[1m'
      GREEN='\033[0;32m'
      BLUE='\033[0;34m'
      YELLOW='\033[0;33m'
      NC='\033[0m' # No Color
      
      printf "%b=== TCP/IP Stack Status ===%b\n\n" "$BOLD" "$NC"
      
      # ----------------------------------------------------------------
      # System Information
      # ----------------------------------------------------------------
      printf "%b[System]%b\n" "$BLUE" "$NC"
      TOTAL_MB=$(${detectMemoryScript})
      TOTAL_GB=$((TOTAL_MB / 1024))
      printf "  RAM: %sGB (%sMB)\n" "$TOTAL_GB" "$TOTAL_MB"
      
      if [[ -f /run/network-tuning-profile ]]; then
        PROFILE=$(${cat} /run/network-tuning-profile)
        printf "  Profile: %b%s%b\n\n" "$GREEN" "''${PROFILE^^}" "$NC"
      else
        printf "  Profile: unknown (cache missing)\n\n"
      fi
      
      # ----------------------------------------------------------------
      # TCP Configuration
      # ----------------------------------------------------------------
      printf "%b[TCP Configuration]%b\n" "$BLUE" "$NC"
      CC=$(${sysctl} -n net.ipv4.tcp_congestion_control)
      QDISC=$(${sysctl} -n net.core.default_qdisc)
      printf "  Congestion Control: %b%s%b\n" "$GREEN" "$CC" "$NC"
      printf "  Queue Discipline:   %b%s%b\n" "$GREEN" "$QDISC" "$NC"
      
      # BBR version (if available)
      if [[ -f /sys/module/tcp_bbr/version ]]; then
        BBR_VER=$(${cat} /sys/module/tcp_bbr/version)
        printf "  BBR Version:        %s\n" "$BBR_VER"
      fi
      
      TFO=$(${sysctl} -n net.ipv4.tcp_fastopen)
      printf "  TCP Fast Open:      %s (3=client+server)\n" "$TFO"
      
      ECN=$(${sysctl} -n net.ipv4.tcp_ecn)
      ECN_FB=$(${sysctl} -n net.ipv4.tcp_ecn_fallback)
      printf "  ECN:                %s (fallback: %s)\n" "$ECN" "$ECN_FB"
      
      MTU=$(${sysctl} -n net.ipv4.tcp_mtu_probing)
      printf "  MTU Probing:        %s\n" "$MTU"
      
      NOTSENT=$(${sysctl} -n net.ipv4.tcp_notsent_lowat 2>/dev/null || echo "N/A")
      printf "  notsent_lowat:      %s bytes\n\n" "$NOTSENT"
      
      # ----------------------------------------------------------------
      # Buffer Configuration
      # ----------------------------------------------------------------
      printf "%b[Buffers]%b\n" "$BLUE" "$NC"
      RMEM_MAX=$(${sysctl} -n net.core.rmem_max)
      WMEM_MAX=$(${sysctl} -n net.core.wmem_max)
      RMEM_DEF=$(${sysctl} -n net.core.rmem_default)
      WMEM_DEF=$(${sysctl} -n net.core.wmem_default)
      
      printf "  rmem_max:     %s (%s bytes)\n" "$(numfmt --to=iec "$RMEM_MAX")" "$RMEM_MAX"
      printf "  wmem_max:     %s (%s bytes)\n" "$(numfmt --to=iec "$WMEM_MAX")" "$WMEM_MAX"
      printf "  rmem_default: %s (%s bytes)\n" "$(numfmt --to=iec "$RMEM_DEF")" "$RMEM_DEF"
      printf "  wmem_default: %s (%s bytes)\n" "$(numfmt --to=iec "$WMEM_DEF")" "$WMEM_DEF"
      
      TCP_RMEM=$(${sysctl} -n net.ipv4.tcp_rmem)
      TCP_WMEM=$(${sysctl} -n net.ipv4.tcp_wmem)
      printf "  tcp_rmem:     %s\n" "$TCP_RMEM"
      printf "  tcp_wmem:     %s\n\n" "$TCP_WMEM"
      
      # ----------------------------------------------------------------
      # Queue & Connection Limits
      # ----------------------------------------------------------------
      printf "%b[Limits]%b\n" "$BLUE" "$NC"
      BACKLOG=$(${sysctl} -n net.core.netdev_max_backlog)
      SOMAXCONN=$(${sysctl} -n net.core.somaxconn)
      printf "  netdev_max_backlog: %s\n" "$BACKLOG"
      printf "  somaxconn:          %s\n" "$SOMAXCONN"
      
      CONNTRACK=$(${sysctl} -n net.netfilter.nf_conntrack_max 2>/dev/null || echo "N/A")
      if [[ "$CONNTRACK" != "N/A" ]]; then
        CONNTRACK_COUNT=$(${cat} /proc/sys/net/netfilter/nf_conntrack_count 2>/dev/null || echo "0")
        CONNTRACK_PCT=$((CONNTRACK_COUNT * 100 / CONNTRACK))
        printf "  nf_conntrack_max:   %s (current: %s = %s%%)\n\n" "$CONNTRACK" "$CONNTRACK_COUNT" "$CONNTRACK_PCT"
      else
        printf "  nf_conntrack_max:   N/A (module not loaded)\n\n"
      fi
      
      # ----------------------------------------------------------------
      # Network Interfaces
      # ----------------------------------------------------------------
      printf "%b[Interfaces]%b\n" "$BLUE" "$NC"
      ${pkgs.iproute2}/bin/ip -br link | while read -r iface state rest; do
        case "$state" in
          UP)
            printf "  %b%-18s%b %s\n" "$GREEN" "$iface" "$NC" "$rest"
            ;;
          DOWN)
            printf "  %-18s %s\n" "$iface" "$rest"
            ;;
          *)
            printf "  %b%-18s%b %s\n" "$YELLOW" "$iface" "$NC" "$rest"
            ;;
        esac
      done
      printf "\n"
      
      # ----------------------------------------------------------------
      # DNS Configuration
      # ----------------------------------------------------------------
      printf "%b[DNS]%b\n" "$BLUE" "$NC"
      ${pkgs.systemd}/bin/resolvectl status | ${grep} -A5 "DNS Servers:" | head -n 6 || printf "  No DNS info available\n"
      printf "\n"
      
      # ----------------------------------------------------------------
      # Routing
      # ----------------------------------------------------------------
      printf "%b[Routing]%b\n" "$BLUE" "$NC"
      printf "  Default IPv4:\n"
      ${pkgs.iproute2}/bin/ip -4 route show default | sed 's/^/    /'
      
      if ${sysctl} -n net.ipv6.conf.all.disable_ipv6 2>/dev/null | grep -q 0; then
        printf "  Default IPv6:\n"
        ${pkgs.iproute2}/bin/ip -6 route show default | sed 's/^/    /' || printf "    (none)\n"
      fi
      printf "\n"
      
      # ----------------------------------------------------------------
      # Connection Statistics
      # ----------------------------------------------------------------
      printf "%b[Connections]%b\n" "$BLUE" "$NC"
      
      # TCP summary
      TCP_ESTAB=$(${pkgs.iproute2}/bin/ss -tan state established 2>/dev/null | tail -n +2 | wc -l)
      TCP_TIMEWAIT=$(${pkgs.iproute2}/bin/ss -tan state time-wait 2>/dev/null | tail -n +2 | wc -l)
      TCP_SYN_SENT=$(${pkgs.iproute2}/bin/ss -tan state syn-sent 2>/dev/null | tail -n +2 | wc -l)
      TCP_SYN_RECV=$(${pkgs.iproute2}/bin/ss -tan state syn-recv 2>/dev/null | tail -n +2 | wc -l)
      TCP_SYN=$((TCP_SYN_SENT + TCP_SYN_RECV))
      TCP_TOTAL=$((TCP_ESTAB + TCP_TIMEWAIT + TCP_SYN))
      
      printf "  TCP Total:       %s\n" "$TCP_TOTAL"
      printf "  TCP Established: %s\n" "$TCP_ESTAB"
      printf "  TCP TIME-WAIT:   %s\n" "$TCP_TIMEWAIT"
      printf "  TCP SYN:         %s\n" "$TCP_SYN"
      
      # UDP count
      UDP_TOTAL=$(${pkgs.iproute2}/bin/ss -uan | tail -n +2 | wc -l)
      printf "  UDP Total:       %s\n\n" "$UDP_TOTAL"
      
      # ----------------------------------------------------------------
      # VPN Status (if Mullvad is enabled)
      # ----------------------------------------------------------------
      if command -v mullvad &>/dev/null; then
        printf "%b[VPN Status]%b\n" "$BLUE" "$NC"
        mullvad status | sed 's/^/  /'
        printf "\n"
      fi
      
      printf "%b✓ Status check complete%b\n" "$GREEN" "$NC"
    '')

    # --------------------------------------------------------------------------
    # Network Performance Test Script
    # --------------------------------------------------------------------------
    (writeScriptBin "net-test" ''
      #!${bash}
      set -euo pipefail
      
      echo "=== Network Performance Test ==="
      echo
      
      # Latency test
      echo "[Latency Test]"
      echo -n "  Google DNS (8.8.8.8): "
      ${pkgs.iputils}/bin/ping -c 5 -q 8.8.8.8 2>/dev/null | ${grep} "rtt min/avg/max" | ${awk} -F'/' '{print $5 "ms avg"}' || echo "FAILED"
      
      echo -n "  Cloudflare (1.1.1.1): "
      ${pkgs.iputils}/bin/ping -c 5 -q 1.1.1.1 2>/dev/null | ${grep} "rtt min/avg/max" | ${awk} -F'/' '{print $5 "ms avg"}' || echo "FAILED"
      echo
      
      # DNS resolution test
      echo "[DNS Resolution Test]"
      echo -n "  github.com: "
      time (${pkgs.bind}/bin/dig +short github.com @127.0.0.53 >/dev/null 2>&1) 2>&1 | ${grep} real | ${awk} '{print $2}'
      
      echo -n "  google.com: "
      time (${pkgs.bind}/bin/dig +short google.com @127.0.0.53 >/dev/null 2>&1) 2>&1 | ${grep} real | ${awk} '{print $2}'
      echo
      
      # Throughput test
      echo "[Throughput Test]"
      echo "  Running speedtest-cli (this may take 30-60s)..."
      ${pkgs.speedtest-cli}/bin/speedtest-cli --simple 2>/dev/null | sed 's/^/  /' || echo "  FAILED (check internet connection)"
      echo
      
      echo "✓ Test complete"
    '')
    
    # --------------------------------------------------------------------------
    # MTU Discovery Tool
    # --------------------------------------------------------------------------
    (writeScriptBin "mtu-test" ''
      #!${bash}
      set -euo pipefail
      
      TARGET="''${1:-1.1.1.1}"
      
      echo "=== MTU Discovery for ''${TARGET} ==="
      echo
      
      # Test common MTU values
      for mtu in 1500 1492 1472 1420 1400 1280; do
        # DF bit set, payload = MTU - 28 (20 IP + 8 ICMP)
        payload=$((mtu - 28))
        echo -n "Testing MTU ''${mtu} (payload ''${payload}): "
        
        if ${pkgs.iputils}/bin/ping -c 1 -M do -s ''${payload} ''${TARGET} >/dev/null 2>&1; then
          echo "✓ OK"
          echo
          echo "Maximum working MTU: ''${mtu} bytes"
          break
        else
          echo "✗ Too large"
        fi
      done
    '')
  ];

  # ============================================================================
  # Shell Aliases
  # ============================================================================
  # Convenient shortcuts for network management
  
  environment.shellAliases = {
    # --------------------------------------------------------------------------
    # WiFi Management (NetworkManager)
    # --------------------------------------------------------------------------
    wifi-list       = "nmcli device wifi list --rescan yes";
    wifi-connect    = "nmcli device wifi connect";
    wifi-disconnect = "nmcli connection down";
    wifi-saved      = "nmcli connection show";
    wifi-current    = "nmcli -t -f active,ssid dev wifi | grep '^yes' | cut -d':' -f2";
    wifi-password   = "nmcli -s -g 802-11-wireless-security.psk connection show";
    
    # --------------------------------------------------------------------------
    # Network Status
    # --------------------------------------------------------------------------
    net-status      = "nmcli general status";
    net-connections = "nmcli connection show --active";
    net-devices     = "nmcli device status";
    net-info        = "ip -c -br addr show";
    
    # --------------------------------------------------------------------------
    # VPN Controls (Mullvad)
    # --------------------------------------------------------------------------
    vpn-status      = "mullvad status";
    vpn-connect     = "mullvad connect";
    vpn-disconnect  = "mullvad disconnect";
    vpn-reconnect   = "mullvad reconnect";
    vpn-relay       = "mullvad relay list";
    vpn-location    = "mullvad relay set location";
    vpn-lockdown    = "mullvad lockdown-mode";
    vpn-dns         = "mullvad dns";
    
    # --------------------------------------------------------------------------
    # DNS Diagnostics
    # --------------------------------------------------------------------------
    dns-status      = "resolvectl status";
    dns-query       = "resolvectl query";
    dns-flush       = "resolvectl flush-caches";
    dns-stats       = "resolvectl statistics";
    
    # DNS leak test (requires curl)
    dns-leak        = "curl -s https://am.i.mullvad.net/json | ${pkgs.jq}/bin/jq -r '.ip, .mullvad_exit_ip, .mullvad_exit_ip_hostname'";
    
    # Alternative leak test (Cloudflare)
    dns-leak-cf     = "curl -s https://1.1.1.1/cdn-cgi/trace";
    
    # --------------------------------------------------------------------------
    # Connection Monitoring
    # --------------------------------------------------------------------------
    conns-tcp       = "ss -tupn | grep ESTAB";
    conns-listen    = "ss -tlnp";
    conns-all       = "ss -tuapn";
    conns-count     = "ss -s";
    
    # --------------------------------------------------------------------------
    # Performance & Diagnostics
    # --------------------------------------------------------------------------
    net-speed       = "speedtest-cli";
    net-trace       = "mtr";
    net-bandwidth   = "nethogs";
    net-traffic     = "iftop -i";
    
    # --------------------------------------------------------------------------
    # TCP/IP Stack Info
    # --------------------------------------------------------------------------
    tcp-info        = "tcp-status";
    tcp-test        = "net-test";
    tcp-tune        = "systemctl status network-tcp-tuning";
    
    # --------------------------------------------------------------------------
    # Interface Control
    # --------------------------------------------------------------------------
    if-up           = "sudo ip link set";
    if-down         = "sudo ip link set";
    if-list         = "ip -c -br link";
    if-addr         = "ip -c -br addr";
    
    # --------------------------------------------------------------------------
    # Route Management
    # --------------------------------------------------------------------------
    route-show      = "ip route show";
    route-show6     = "ip -6 route show";
    route-default   = "ip route show default";
  };

  # ============================================================================
  # User Groups
  # ============================================================================
  # Note: Users should be added to networkmanager group in their user config
  # Example in users/kenan/default.nix:
  #   users.users.kenan.extraGroups = [ "networkmanager" ];

  # ============================================================================
  # Assertions & Warnings
  # ============================================================================
  
  assertions = [
    {
      assertion = config.networking.networkmanager.enable;
      message = "NetworkManager must be enabled for this configuration";
    }
    {
      assertion = config.services.resolved.enable;
      message = "systemd-resolved must be enabled for DNS management";
    }
  ];

  warnings = lib.optionals (!config.networking.enableIPv6) [
    ''
      IPv6 is disabled. This may cause issues with:
      - Modern CDNs (Cloudflare, Fastly) that prefer IPv6
      - Some streaming services (Netflix, YouTube)
      - Apple services (iCloud, FaceTime)
      
      Consider enabling IPv6 and using per-interface disable if needed:
        networking.interfaces.<interface>.ipv6.enable = false;
    ''
  ] ++ lib.optionals (hasMullvad && !config.networking.firewall.enable) [
    ''
      Mullvad VPN is enabled but firewall is disabled.
      This prevents the killswitch from working properly.
      Internet traffic may leak if VPN disconnects.
    ''
  ];
}
