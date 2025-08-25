# modules/core/tcp/default.nix
# ==============================================================================
# Advanced Dynamic TCP/IP Stack Optimization
# ==============================================================================
# High-performance TCP/IP configuration with runtime memory detection and
# adaptive tuning for different system configurations.
#
# Key Features:
# - BBR congestion control for optimal throughput
# - Dynamic buffer sizing based on available RAM
# - WiFi and mobile network optimizations
# - Low-latency tuning for interactive workloads
# - Security hardening with DoS protection
#
# Supported Configurations:
# - Standard (16GB): Conservative buffers, balanced performance
# - High Memory (32GB+): Aggressive buffers, maximum throughput
#
# Version: 3.0.0
# Author: Kenan Pelit
# Last Updated: 2025-08-25
# ==============================================================================
{ config, lib, pkgs, ... }:

let
  # ==============================================================================
  # Helper Commands
  # ==============================================================================
  
  # Define full paths to commands
  awk = "${pkgs.gawk}/bin/awk";
  grep = "${pkgs.gnugrep}/bin/grep";
  sysctl = "${pkgs.procps}/bin/sysctl";
  
  # Memory detection script
  detectMemoryScript = pkgs.writeShellScript "detect-memory" ''
    #!/usr/bin/env bash
    # Get total memory in KB from /proc/meminfo
    TOTAL_KB=$(${grep} "^MemTotal:" /proc/meminfo | ${awk} '{print $2}')
    # Convert to MB
    TOTAL_MB=$((TOTAL_KB / 1024))
    echo "$TOTAL_MB"
  '';
  
  # ==============================================================================
  # TCP Configuration Profiles
  # ==============================================================================
  
  # High memory system configuration (32GB+)
  highMemConfig = {
    # TCP buffer sizes - optimized for high throughput
    rmem = "4096 262144 16777216";     # min: 4KB, default: 256KB, max: 16MB
    wmem = "4096 262144 16777216";     # min: 4KB, default: 256KB, max: 16MB
    rmem_max = 16777216;               # 16MB max receive buffer
    wmem_max = 16777216;               # 16MB max send buffer
    rmem_default = 524288;             # 512KB default receive buffer
    wmem_default = 524288;             # 512KB default send buffer
    
    # Network queue and connection limits
    netdev_max_backlog = 5000;         # Higher packet queue
    netdev_budget = 600;               # More packets per NAPI poll
    somaxconn = 1024;                  # Max queued connections
    tcp_max_syn_backlog = 2048;        # SYN queue size
    tcp_max_tw_buckets = 2000000;      # TIME_WAIT sockets
    tcp_max_orphans = 262144;          # Orphan sockets
    
    # Memory pressure thresholds (pages)
    tcp_mem = "786432 1048576 3145728"; # 3GB-4GB-12GB
    udp_mem = "393216 524288 1572864";  # 1.5GB-2GB-6GB
    
    # Connection tracking
    conntrack_max = 262144;             # Max tracked connections
    conntrack_buckets = 65536;          # Hash table size
  };
  
  # Standard memory system configuration (16GB)
  standardMemConfig = {
    # TCP buffer sizes - balanced for moderate throughput
    rmem = "4096 131072 8388608";      # min: 4KB, default: 128KB, max: 8MB
    wmem = "4096 131072 8388608";      # min: 4KB, default: 128KB, max: 8MB
    rmem_max = 8388608;                # 8MB max receive buffer
    wmem_max = 8388608;                # 8MB max send buffer
    rmem_default = 262144;             # 256KB default receive buffer
    wmem_default = 262144;             # 256KB default send buffer
    
    # Network queue and connection limits
    netdev_max_backlog = 3000;         # Moderate packet queue
    netdev_budget = 400;               # Standard packets per poll
    somaxconn = 512;                   # Max queued connections
    tcp_max_syn_backlog = 1024;        # SYN queue size
    tcp_max_tw_buckets = 1000000;      # TIME_WAIT sockets
    tcp_max_orphans = 131072;          # Orphan sockets
    
    # Memory pressure thresholds (pages)
    tcp_mem = "196608 262144 786432";  # 768MB-1GB-3GB
    udp_mem = "98304 131072 393216";   # 384MB-512MB-1.5GB
    
    # Connection tracking
    conntrack_max = 131072;             # Max tracked connections
    conntrack_buckets = 32768;          # Hash table size
  };
  
  # Power management settings
  highMemPowerSettings = {
    tcp_keepalive_time = 600;          # 10 minutes
    tcp_keepalive_intvl = 60;          # 60 seconds
    tcp_keepalive_probes = 3;          # 3 probes
    tcp_fin_timeout = 30;              # 30 seconds FIN-WAIT-2
    tcp_tw_timeout = 30;               # 30 seconds TIME-WAIT
    tcp_retries2 = 8;                  # Max retransmissions
    tcp_orphan_retries = 1;            # Orphan retries
  };
  
  standardMemPowerSettings = {
    tcp_keepalive_time = 300;          # 5 minutes (more aggressive)
    tcp_keepalive_intvl = 30;          # 30 seconds
    tcp_keepalive_probes = 3;          # 3 probes
    tcp_fin_timeout = 15;              # 15 seconds FIN-WAIT-2
    tcp_tw_timeout = 15;               # 15 seconds TIME-WAIT
    tcp_retries2 = 5;                  # Max retransmissions
    tcp_orphan_retries = 0;            # No orphan retries
  };

in
{
  # ==============================================================================
  # Kernel Sysctl Parameters
  # ==============================================================================
  
  boot.kernel.sysctl = {
    # ============================================================================
    # Core Network Stack
    # ============================================================================
    
    # Default queueing discipline - Fair Queue for BBR
    "net.core.default_qdisc" = "fq";
    
    # Maximum receive socket buffer size
    "net.core.rmem_max" = lib.mkDefault standardMemConfig.rmem_max;
    "net.core.rmem_default" = lib.mkDefault standardMemConfig.rmem_default;
    
    # Maximum send socket buffer size
    "net.core.wmem_max" = lib.mkDefault standardMemConfig.wmem_max;
    "net.core.wmem_default" = lib.mkDefault standardMemConfig.wmem_default;
    
    # Network device backlog queue
    "net.core.netdev_max_backlog" = lib.mkDefault standardMemConfig.netdev_max_backlog;
    "net.core.netdev_budget" = lib.mkDefault standardMemConfig.netdev_budget;
    "net.core.netdev_budget_usecs" = 4000;  # 4ms budget time
    
    # Socket listen() backlog
    "net.core.somaxconn" = lib.mkDefault standardMemConfig.somaxconn;
    
    # BPF JIT compiler (for eBPF programs)
    "net.core.bpf_jit_enable" = 1;
    "net.core.bpf_jit_harden" = 1;
    
    # Busy polling (reduce latency)
    "net.core.busy_poll" = 50;         # 50 microseconds
    "net.core.busy_read" = 50;
    
    # Flow limiting
    "net.core.flow_limit_cpu_bitmap" = "0";  # Disable flow limiting
    
    # ============================================================================
    # TCP/IPv4 Configuration
    # ============================================================================
    
    # BBR congestion control
    "net.ipv4.tcp_congestion_control" = "bbr";
    
    # TCP Fast Open (both client and server)
    "net.ipv4.tcp_fastopen" = 3;
    
    # TCP buffer sizes
    "net.ipv4.tcp_rmem" = lib.mkDefault standardMemConfig.rmem;
    "net.ipv4.tcp_wmem" = lib.mkDefault standardMemConfig.wmem;
    "net.ipv4.tcp_mem" = lib.mkDefault standardMemConfig.tcp_mem;
    "net.ipv4.udp_mem" = lib.mkDefault standardMemConfig.udp_mem;
    
    # TCP window scaling and timestamps (required for high bandwidth)
    "net.ipv4.tcp_window_scaling" = 1;
    "net.ipv4.tcp_timestamps" = 1;
    
    # Selective Acknowledgments
    "net.ipv4.tcp_sack" = 1;
    "net.ipv4.tcp_fack" = 1;
    "net.ipv4.tcp_dsack" = 1;
    
    # TCP performance optimizations
    "net.ipv4.tcp_slow_start_after_idle" = 0;  # Disable slow start after idle
    "net.ipv4.tcp_no_metrics_save" = 1;        # Don't cache metrics
    "net.ipv4.tcp_moderate_rcvbuf" = 1;        # Auto-tune receive buffer
    "net.ipv4.tcp_autocorking" = 0;            # Disable autocorking for low latency
    "net.ipv4.tcp_notsent_lowat" = 16384;      # 16KB unsent bytes threshold
    
    # Early retransmit and thin streams
    "net.ipv4.tcp_early_retrans" = 3;          # Enable early retransmit
    "net.ipv4.tcp_thin_linear_timeouts" = 1;   # Better for thin streams
    "net.ipv4.tcp_thin_dupack" = 1;
    
    # MTU probing
    "net.ipv4.tcp_mtu_probing" = 1;
    "net.ipv4.tcp_base_mss" = 1024;
    
    # TCP keepalive (default values, runtime adjusted)
    "net.ipv4.tcp_keepalive_time" = lib.mkDefault standardMemPowerSettings.tcp_keepalive_time;
    "net.ipv4.tcp_keepalive_intvl" = lib.mkDefault standardMemPowerSettings.tcp_keepalive_intvl;
    "net.ipv4.tcp_keepalive_probes" = lib.mkDefault standardMemPowerSettings.tcp_keepalive_probes;
    
    # Connection timeouts
    "net.ipv4.tcp_fin_timeout" = lib.mkDefault standardMemPowerSettings.tcp_fin_timeout;
    "net.ipv4.tcp_tw_reuse" = 1;               # Reuse TIME_WAIT sockets
    "net.ipv4.tcp_max_tw_buckets" = lib.mkDefault standardMemConfig.tcp_max_tw_buckets;
    
    # Retransmission settings
    "net.ipv4.tcp_retries2" = lib.mkDefault standardMemPowerSettings.tcp_retries2;
    "net.ipv4.tcp_syn_retries" = 3;            # SYN retries
    "net.ipv4.tcp_synack_retries" = 3;         # SYN-ACK retries
    "net.ipv4.tcp_orphan_retries" = lib.mkDefault standardMemPowerSettings.tcp_orphan_retries;
    
    # SYN cookies and backlog
    "net.ipv4.tcp_syncookies" = 1;             # Enable SYN cookies
    "net.ipv4.tcp_max_syn_backlog" = lib.mkDefault standardMemConfig.tcp_max_syn_backlog;
    "net.ipv4.tcp_max_orphans" = lib.mkDefault standardMemConfig.tcp_max_orphans;
    
    # TCP algorithm parameters
    "net.ipv4.tcp_reordering" = 3;             # Packet reordering threshold
    "net.ipv4.tcp_max_reordering" = 300;       # Max reordering
    "net.ipv4.tcp_app_win" = 31;               # Application window
    "net.ipv4.tcp_adv_win_scale" = 2;          # Window scale
    
    # ECN (Explicit Congestion Notification)
    "net.ipv4.tcp_ecn" = 1;                    # Enable ECN negotiation
    "net.ipv4.tcp_ecn_fallback" = 1;           # Fallback if ECN fails
    
    # F-RTO (Forward RTO Recovery)
    "net.ipv4.tcp_frto" = 2;                   # Enable F-RTO
    
    # ABC (Appropriate Byte Counting)
    "net.ipv4.tcp_abc" = 1;
    
    # Low latency settings
    "net.ipv4.tcp_low_latency" = 0;            # Prefer throughput over latency
    
    # RFC1337 TIME-WAIT assassination hazards
    "net.ipv4.tcp_rfc1337" = 1;
    
    # Abort on overflow
    "net.ipv4.tcp_abort_on_overflow" = 0;
    
    # ============================================================================
    # IP Protocol Settings
    # ============================================================================
    
    # IP forwarding (disabled for laptops)
    "net.ipv4.ip_forward" = 0;
    "net.ipv6.conf.all.forwarding" = 0;
    
    # IP fragmentation
    "net.ipv4.ipfrag_high_thresh" = 8388608;   # 8MB high threshold
    "net.ipv4.ipfrag_low_thresh" = 6291456;    # 6MB low threshold
    "net.ipv4.ipfrag_time" = 30;               # 30 seconds timeout
    
    # ARP settings
    "net.ipv4.neigh.default.gc_thresh1" = 128;
    "net.ipv4.neigh.default.gc_thresh2" = 512;
    "net.ipv4.neigh.default.gc_thresh3" = 1024;
    "net.ipv4.neigh.default.gc_interval" = 30;
    "net.ipv4.neigh.default.gc_stale_time" = 60;
    
    # ============================================================================
    # Security Settings
    # ============================================================================
    
    # Reverse Path Filtering (prevent IP spoofing)
    "net.ipv4.conf.all.rp_filter" = 1;
    "net.ipv4.conf.default.rp_filter" = 1;
    
    # ICMP redirects (disabled for security)
    "net.ipv4.conf.all.accept_redirects" = 0;
    "net.ipv4.conf.default.accept_redirects" = 0;
    "net.ipv4.conf.all.secure_redirects" = 0;
    "net.ipv4.conf.default.secure_redirects" = 0;
    "net.ipv4.conf.all.send_redirects" = 0;
    "net.ipv4.conf.default.send_redirects" = 0;
    
    # Source routing (disabled for security)
    "net.ipv4.conf.all.accept_source_route" = 0;
    "net.ipv4.conf.default.accept_source_route" = 0;
    
    # ICMP settings
    "net.ipv4.icmp_echo_ignore_broadcasts" = 1;
    "net.ipv4.icmp_ignore_bogus_error_responses" = 1;
    "net.ipv4.icmp_errors_use_inbound_ifaddr" = 1;
    "net.ipv4.icmp_ratelimit" = 100;
    "net.ipv4.icmp_ratemask" = 88089;
    
    # Martian packet logging
    "net.ipv4.conf.all.log_martians" = 0;      # Disable to reduce log spam
    "net.ipv4.conf.default.log_martians" = 0;
    
    # ============================================================================
    # IPv6 Security
    # ============================================================================
    
    "net.ipv6.conf.all.accept_redirects" = 0;
    "net.ipv6.conf.default.accept_redirects" = 0;
    "net.ipv6.conf.all.accept_source_route" = 0;
    "net.ipv6.conf.default.accept_source_route" = 0;
    "net.ipv6.conf.all.accept_ra" = 0;
    "net.ipv6.conf.default.accept_ra" = 0;
    "net.ipv6.conf.all.router_solicitations" = 0;
    "net.ipv6.conf.default.router_solicitations" = 0;
    
    # ============================================================================
    # Connection Tracking
    # ============================================================================
    
    "net.netfilter.nf_conntrack_max" = lib.mkDefault standardMemConfig.conntrack_max;
    "net.netfilter.nf_conntrack_buckets" = lib.mkDefault standardMemConfig.conntrack_buckets;
    "net.netfilter.nf_conntrack_tcp_timeout_established" = 432000;  # 5 days
    "net.netfilter.nf_conntrack_tcp_timeout_time_wait" = 30;
    "net.netfilter.nf_conntrack_tcp_timeout_close_wait" = 60;
    "net.netfilter.nf_conntrack_tcp_timeout_fin_wait" = 30;
    "net.netfilter.nf_conntrack_generic_timeout" = 600;
    
  };
  
  # ==============================================================================
  # System Services
  # ==============================================================================
  
  # Activation script for TCP info
  system.activationScripts.tcpInfo = ''
    # Detect memory and display configuration
    TOTAL_MB=$(${detectMemoryScript})
    TOTAL_GB=$((TOTAL_MB / 1024))
    
    if [ "$TOTAL_MB" -ge 32768 ]; then
      echo "TCP/IP: High Memory Profile (Detected: $${TOTAL_GB}GB RAM)"
      echo "Buffers: 16MB max | Queue: 5000 packets | Connections: 1024 max"
    else
      echo "TCP/IP: Standard Profile (Detected: $${TOTAL_GB}GB RAM)"
      echo "Buffers: 8MB max | Queue: 3000 packets | Connections: 512 max"
    fi
  '';
  
  # Dynamic TCP tuning service
  systemd.services.dynamic-tcp-tuning = {
    description = "Apply dynamic TCP tuning based on system memory";
    wantedBy = [ "multi-user.target" ];
    after = [ "network-pre.target" ];
    before = [ "network.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = pkgs.writeShellScript "apply-tcp-tuning" ''
        #!/usr/bin/env bash
        set -euo pipefail
        
        # Detect total memory
        TOTAL_MB=$(${detectMemoryScript})
        
        echo "System memory detected: $((TOTAL_MB / 1024))GB"
        
        # Apply appropriate configuration
        if [ "$TOTAL_MB" -ge 32768 ]; then
          echo "Applying high memory TCP configuration..."
          
          # TCP buffers
          ${sysctl} -w net.ipv4.tcp_rmem="${highMemConfig.rmem}"
          ${sysctl} -w net.ipv4.tcp_wmem="${highMemConfig.wmem}"
          ${sysctl} -w net.core.rmem_max=${toString highMemConfig.rmem_max}
          ${sysctl} -w net.core.wmem_max=${toString highMemConfig.wmem_max}
          ${sysctl} -w net.core.rmem_default=${toString highMemConfig.rmem_default}
          ${sysctl} -w net.core.wmem_default=${toString highMemConfig.wmem_default}
          
          # Network parameters
          ${sysctl} -w net.core.netdev_max_backlog=${toString highMemConfig.netdev_max_backlog}
          ${sysctl} -w net.core.netdev_budget=${toString highMemConfig.netdev_budget}
          ${sysctl} -w net.core.somaxconn=${toString highMemConfig.somaxconn}
          ${sysctl} -w net.ipv4.tcp_max_syn_backlog=${toString highMemConfig.tcp_max_syn_backlog}
          ${sysctl} -w net.ipv4.tcp_max_tw_buckets=${toString highMemConfig.tcp_max_tw_buckets}
          ${sysctl} -w net.ipv4.tcp_max_orphans=${toString highMemConfig.tcp_max_orphans}
          
          # Memory limits
          ${sysctl} -w net.ipv4.tcp_mem="${highMemConfig.tcp_mem}"
          ${sysctl} -w net.ipv4.udp_mem="${highMemConfig.udp_mem}"
          
          # Connection tracking
          ${sysctl} -w net.netfilter.nf_conntrack_max=${toString highMemConfig.conntrack_max}
          
          # Keepalive settings
          ${sysctl} -w net.ipv4.tcp_keepalive_time=${toString highMemPowerSettings.tcp_keepalive_time}
          ${sysctl} -w net.ipv4.tcp_keepalive_intvl=${toString highMemPowerSettings.tcp_keepalive_intvl}
          ${sysctl} -w net.ipv4.tcp_fin_timeout=${toString highMemPowerSettings.tcp_fin_timeout}
          
          echo "High memory configuration applied"
        else
          echo "Applying standard memory TCP configuration..."
          
          # TCP buffers
          ${sysctl} -w net.ipv4.tcp_rmem="${standardMemConfig.rmem}"
          ${sysctl} -w net.ipv4.tcp_wmem="${standardMemConfig.wmem}"
          ${sysctl} -w net.core.rmem_max=${toString standardMemConfig.rmem_max}
          ${sysctl} -w net.core.wmem_max=${toString standardMemConfig.wmem_max}
          ${sysctl} -w net.core.rmem_default=${toString standardMemConfig.rmem_default}
          ${sysctl} -w net.core.wmem_default=${toString standardMemConfig.wmem_default}
          
          # Network parameters
          ${sysctl} -w net.core.netdev_max_backlog=${toString standardMemConfig.netdev_max_backlog}
          ${sysctl} -w net.core.netdev_budget=${toString standardMemConfig.netdev_budget}
          ${sysctl} -w net.core.somaxconn=${toString standardMemConfig.somaxconn}
          ${sysctl} -w net.ipv4.tcp_max_syn_backlog=${toString standardMemConfig.tcp_max_syn_backlog}
          ${sysctl} -w net.ipv4.tcp_max_tw_buckets=${toString standardMemConfig.tcp_max_tw_buckets}
          ${sysctl} -w net.ipv4.tcp_max_orphans=${toString standardMemConfig.tcp_max_orphans}
          
          # Memory limits
          ${sysctl} -w net.ipv4.tcp_mem="${standardMemConfig.tcp_mem}"
          ${sysctl} -w net.ipv4.udp_mem="${standardMemConfig.udp_mem}"
          
          # Connection tracking
          ${sysctl} -w net.netfilter.nf_conntrack_max=${toString standardMemConfig.conntrack_max}
          
          # Keepalive settings
          ${sysctl} -w net.ipv4.tcp_keepalive_time=${toString standardMemPowerSettings.tcp_keepalive_time}
          ${sysctl} -w net.ipv4.tcp_keepalive_intvl=${toString standardMemPowerSettings.tcp_keepalive_intvl}
          ${sysctl} -w net.ipv4.tcp_fin_timeout=${toString standardMemPowerSettings.tcp_fin_timeout}
          
          echo "Standard memory configuration applied"
        fi
      '';
    };
  };
}

