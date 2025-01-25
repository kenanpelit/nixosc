# modules/core/network/tcp/default.nix
# ==============================================================================
# TCP/IP Stack Optimizations
# ==============================================================================
# This configuration manages TCP/IP stack settings including:
# - TCP BBR congestion control
# - TCP memory and buffer settings
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

    # TCP Memory Settings
    "net.ipv4.tcp_rmem" = "4096 87380 6291456";
    "net.ipv4.tcp_wmem" = "4096 87380 6291456";

    # Security Settings
    "net.ipv4.tcp_syncookies" = 1;
    "net.ipv4.conf.all.rp_filter" = 1;
    "net.ipv4.conf.default.rp_filter" = 1;
    "net.ipv4.conf.all.accept_redirects" = 0;
    "net.ipv4.conf.all.accept_source_route" = 0;
    "net.ipv4.icmp_echo_ignore_broadcasts" = 1;
  };
}
