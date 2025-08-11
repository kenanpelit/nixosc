# modules/core/tcp/default.nix
# ==============================================================================
# TCP/IP Stack Optimizations (ThinkPad E14 Gen 6 - 64GB RAM)
# ==============================================================================
# This configuration manages TCP/IP stack settings including:
# - TCP BBR congestion control
# - TCP memory and buffer settings (optimized for 64GB RAM laptop)
# - Network security parameters
# - WiFi and mobile optimizations
# - Power-aware networking settings
#
# System: Lenovo ThinkPad E14 Gen 6 (Intel Core Ultra 7 155H, 64GB RAM)
# Author: Kenan Pelit
# ==============================================================================
{ ... }:
{
  boot.kernel.sysctl = {
    # TCP BBR and Performance
    "net.core.default_qdisc" = "fq";
    "net.ipv4.tcp_congestion_control" = "bbr";
    "net.ipv4.tcp_fastopen" = 3;
    "net.ipv4.tcp_slow_start_after_idle" = 0;
    
    # TCP Memory Settings (optimized for 64GB RAM laptop)
    # Slightly more conservative than server settings for battery life
    "net.ipv4.tcp_rmem" = "4096 131072 12582912";      # 12MB max (vs 16MB server)
    "net.ipv4.tcp_wmem" = "4096 131072 12582912";      # 12MB max (vs 16MB server)
    "net.core.rmem_max" = 12582912;                     # 12MB
    "net.core.wmem_max" = 12582912;                     # 12MB
    "net.core.netdev_max_backlog" = 4000;              # Laptop optimized
    
    # TCP Window Scaling and SACK
    "net.ipv4.tcp_window_scaling" = 1;
    "net.ipv4.tcp_sack" = 1;
    "net.ipv4.tcp_fack" = 1;
    "net.ipv4.tcp_timestamps" = 1;
    
    # TCP Keep-alive settings (battery-friendly)
    "net.ipv4.tcp_keepalive_time" = 900;               # 15 min (vs 10 min)
    "net.ipv4.tcp_keepalive_intvl" = 75;               # 75 sec (vs 60 sec)
    "net.ipv4.tcp_keepalive_probes" = 3;
    
    # WiFi and Mobile Network Optimizations
    "net.ipv4.tcp_no_metrics_save" = 1;                # Don't cache metrics for WiFi
    "net.ipv4.tcp_moderate_rcvbuf" = 1;                # Auto-tune receive buffer
    "net.ipv4.tcp_abc" = 1;                            # Appropriate Byte Counting
    
    # Security Settings
    "net.ipv4.tcp_syncookies" = 1;
    "net.ipv4.conf.all.rp_filter" = 1;
    "net.ipv4.conf.default.rp_filter" = 1;
    "net.ipv4.conf.all.accept_redirects" = 0;
    "net.ipv4.conf.default.accept_redirects" = 0;
    "net.ipv4.conf.all.accept_source_route" = 0;
    "net.ipv4.conf.default.accept_source_route" = 0;
    "net.ipv4.icmp_echo_ignore_broadcasts" = 1;
    "net.ipv4.icmp_ignore_bogus_error_responses" = 1;
    
    # IPv6 security
    "net.ipv6.conf.all.accept_redirects" = 0;
    "net.ipv6.conf.default.accept_redirects" = 0;
    "net.ipv6.conf.all.forwarding" = 0;                # Laptop doesn't need forwarding
    
    # Network performance (laptop optimized)
    "net.core.somaxconn" = 768;                        # Between server (1024) and conservative (512)
    "net.ipv4.tcp_max_syn_backlog" = 1536;             # Between server (2048) and conservative (1024)
    
    # Additional laptop-specific optimizations
    "net.ipv4.tcp_frto" = 2;                           # Forward RTO-Recovery for WiFi
    "net.ipv4.tcp_mtu_probing" = 1;                    # Enable Path MTU Discovery
    "net.core.rmem_default" = 262144;                  # 256KB default receive buffer
    "net.core.wmem_default" = 262144;                  # 256KB default send buffer
    
    # Power and mobility optimizations
    "net.ipv4.tcp_orphan_retries" = 1;                 # Reduce retries for power saving
    "net.ipv4.tcp_fin_timeout" = 15;                   # Faster FIN timeout (30->15 sec)
    
    # VPN optimizations (WireGuard detected)
    "net.core.netdev_budget" = 600;                    # Higher packet processing budget
    "net.core.netdev_budget_usecs" = 5000;             # 5ms budget time
  };
}
