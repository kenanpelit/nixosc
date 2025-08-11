# modules/core/tcp/default.nix
# ==============================================================================
# TCP/IP Stack Optimizations (16GB RAM optimized)
# ==============================================================================
# This configuration manages TCP/IP stack settings including:
# - TCP BBR congestion control
# - TCP memory and buffer settings (balanced for 16GB RAM)
# - Network security parameters
#
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
    
    # TCP Memory Settings (balanced for 16GB RAM)
    "net.ipv4.tcp_rmem" = "4096 87380 8388608";
    "net.ipv4.tcp_wmem" = "4096 87380 8388608";
    "net.core.rmem_max" = 8388608;
    "net.core.wmem_max" = 8388608;
    "net.core.netdev_max_backlog" = 2500;
    
    # TCP Window Scaling and SACK
    "net.ipv4.tcp_window_scaling" = 1;
    "net.ipv4.tcp_sack" = 1;
    "net.ipv4.tcp_timestamps" = 1;
    
    # TCP Keep-alive settings
    "net.ipv4.tcp_keepalive_time" = 600;
    "net.ipv4.tcp_keepalive_intvl" = 60;
    "net.ipv4.tcp_keepalive_probes" = 3;
    
    # Security Settings
    "net.ipv4.tcp_syncookies" = 1;
    "net.ipv4.conf.all.rp_filter" = 1;
    "net.ipv4.conf.default.rp_filter" = 1;
    "net.ipv4.conf.all.accept_redirects" = 0;
    "net.ipv4.conf.default.accept_redirects" = 0;
    "net.ipv4.conf.all.accept_source_route" = 0;
    "net.ipv4.icmp_echo_ignore_broadcasts" = 1;
    "net.ipv4.icmp_ignore_bogus_error_responses" = 1;
    
    # IPv6 security
    "net.ipv6.conf.all.accept_redirects" = 0;
    "net.ipv6.conf.default.accept_redirects" = 0;
    
    # Network performance (conservative for 16GB)
    "net.core.somaxconn" = 512;
    "net.ipv4.tcp_max_syn_backlog" = 1024;
  };
}

