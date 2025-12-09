# modules/nixos/tcp/default.nix
# ==============================================================================
# NixOS module for tcp (system-wide stack).
# Provides host defaults and service toggles declared in this file.
# Keeps machine-wide settings centralized under modules/nixos.
# Extend or override options here instead of ad-hoc host tweaks.
# ==============================================================================

{ lib, ... }:

let
  inherit (lib) mkDefault;

  ultra = {
    rmem               = "4096 1048576 67108864";
    wmem               = "4096 1048576 67108864";
    rmem_max           = 67108864;
    wmem_max           = 67108864;
    rmem_default       = 2097152;
    wmem_default       = 2097152;
    netdev_max_backlog = 32000;
    somaxconn          = 8192;
    tcp_max_syn_backlog = 16384;
    tcp_max_tw_buckets  = 4000000;
    tcp_mem            = "3145728 4194304 6291456";
    udp_mem            = "1572864 2097152 3145728";
    conntrack_max      = 1048576;
  };

  high = {
    rmem               = "4096 524288 33554432";
    wmem               = "4096 524288 33554432";
    rmem_max           = 33554432;
    wmem_max           = 33554432;
    rmem_default       = 1048576;
    wmem_default       = 1048576;
    netdev_max_backlog = 16000;
    somaxconn          = 4096;
    tcp_max_syn_backlog = 8192;
    tcp_max_tw_buckets  = 2000000;
    tcp_mem            = "1572864 2097152 3145728";
    udp_mem            = "786432 1048576 1572864";
    conntrack_max      = 524288;
  };

  std = {
    rmem               = "4096 262144 16777216";
    wmem               = "4096 262144 16777216";
    rmem_max           = 16777216;
    wmem_max           = 16777216;
    rmem_default       = 524288;
    wmem_default       = 524288;
    netdev_max_backlog = 5000;
    somaxconn          = 1024;
    tcp_max_syn_backlog = 2048;
    tcp_max_tw_buckets  = 1000000;
    tcp_mem            = "786432 1048576 1572864";
    udp_mem            = "393216 524288 786432";
    conntrack_max      = 262144;
  };

  chosen = ultra;
in
{
  boot.kernel.sysctl = {
    "net.core.default_qdisc" = "fq";
    "net.ipv4.tcp_congestion_control" = "bbr";
    "net.ipv4.ip_local_port_range" = "1024 65535";

    "net.core.rmem_max"     = mkDefault chosen.rmem_max;
    "net.core.rmem_default" = mkDefault chosen.rmem_default;
    "net.core.wmem_max"     = mkDefault chosen.wmem_max;
    "net.core.wmem_default" = mkDefault chosen.wmem_default;
    "net.core.netdev_max_backlog" = mkDefault chosen.netdev_max_backlog;
    "net.core.netdev_budget" = 300;
    "net.core.netdev_budget_usecs" = 8000;
    "net.core.somaxconn" = mkDefault chosen.somaxconn;

    "net.core.bpf_jit_enable" = 1;
    "net.core.bpf_jit_harden" = 1;

    "net.ipv4.tcp_fastopen" = 3;
    "net.ipv4.tcp_dsack" = 1;
    "net.ipv4.tcp_slow_start_after_idle" = 0;
    "net.ipv4.tcp_moderate_rcvbuf" = 1;
    "net.ipv4.tcp_notsent_lowat" = 16384;
    "net.ipv4.tcp_mtu_probing" = 1;

    "net.ipv4.tcp_rmem" = mkDefault chosen.rmem;
    "net.ipv4.tcp_wmem" = mkDefault chosen.wmem;
    "net.ipv4.tcp_mem"  = mkDefault chosen.tcp_mem;
    "net.ipv4.udp_mem"  = mkDefault chosen.udp_mem;

    "net.ipv4.tcp_keepalive_time"   = 300;
    "net.ipv4.tcp_keepalive_intvl"  = 30;
    "net.ipv4.tcp_keepalive_probes" = 3;
    "net.ipv4.tcp_fin_timeout"      = 60;

    "net.ipv4.tcp_max_tw_buckets" = mkDefault chosen.tcp_max_tw_buckets;
    "net.ipv4.tcp_tw_reuse" = 1;
    "net.ipv4.tcp_retries2"       = 8;
    "net.ipv4.tcp_syn_retries"    = 3;
    "net.ipv4.tcp_synack_retries" = 3;
    "net.ipv4.tcp_syncookies" = 1;
    "net.ipv4.tcp_max_syn_backlog" = mkDefault chosen.tcp_max_syn_backlog;
    "net.ipv4.tcp_reordering" = 3;
    "net.ipv4.tcp_ecn" = 1;
    "net.ipv4.tcp_ecn_fallback" = 1;
    "net.ipv4.tcp_frto" = 2;
    "net.ipv4.tcp_rfc1337" = 1;
    "net.ipv4.tcp_timestamps" = 1;
    "net.ipv4.tcp_sack" = 1;

    "net.ipv4.conf.all.rp_filter"     = 2;
    "net.ipv4.conf.default.rp_filter" = 2;
    "net.ipv4.conf.all.accept_redirects"     = 0;
    "net.ipv4.conf.default.accept_redirects" = 0;
    "net.ipv4.conf.all.secure_redirects"     = 0;
    "net.ipv4.conf.default.secure_redirects" = 0;
    "net.ipv4.conf.all.send_redirects"       = 0;
    "net.ipv4.conf.all.accept_source_route"     = 0;
    "net.ipv4.conf.default.accept_source_route" = 0;
    "net.ipv4.icmp_echo_ignore_broadcasts"      = 1;
    "net.ipv4.icmp_ignore_bogus_error_responses" = 1;
    "net.ipv4.conf.all.log_martians" = mkDefault 0;

    "net.ipv6.conf.all.accept_redirects"     = 0;
    "net.ipv6.conf.default.accept_redirects" = 0;
    "net.ipv6.conf.all.accept_source_route"  = 0;
    "net.ipv6.conf.all.accept_ra"            = 0;
    "net.ipv6.conf.default.accept_ra"        = 0;

    "net.netfilter.nf_conntrack_max" = mkDefault chosen.conntrack_max;
    "net.netfilter.nf_conntrack_tcp_timeout_established" = 432000;
    "net.netfilter.nf_conntrack_tcp_timeout_time_wait"   = 30;
    "net.netfilter.nf_conntrack_tcp_timeout_close_wait"  = 30;
    "net.netfilter.nf_conntrack_tcp_timeout_fin_wait"    = 30;
    "net.netfilter.nf_conntrack_udp_timeout"             = 60;
    "net.netfilter.nf_conntrack_generic_timeout"         = 600;
    "net.netfilter.nf_conntrack_helper" = 0;

    "net.ipv4.tcp_window_scaling" = 1;
    "net.ipv4.neigh.default.gc_thresh1" = 4096;
    "net.ipv4.neigh.default.gc_thresh2" = 8192;
    "net.ipv4.neigh.default.gc_thresh3" = 16384;
    "net.ipv4.neigh.default.gc_stale_time" = 120;
  };
}
