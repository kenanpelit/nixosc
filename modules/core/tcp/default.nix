# modules/core/tcp/default.nix
# ==============================================================================
# Optimized TCP/IP Stack Configuration for NixOS
# ==============================================================================
# Goal:
# - Keep defaults modern & safe (BBR + fq, sane buffers, ECN with fallback)
# - Scale up on RAM-rich systems without hurting latency
# - Avoid fragile/legacy toggles; prefer kernel defaults where they’re smart
#
# Version: 4.2.0
# Date:    2025-08-28
# Author:  Kenan Pelit
# ==============================================================================

{ config, lib, pkgs, ... }:

let
  awk    = "${pkgs.gawk}/bin/awk";
  grep   = "${pkgs.gnugrep}/bin/grep";
  sysctl = "${pkgs.procps}/bin/sysctl";

  detectMemoryScript = pkgs.writeShellScript "detect-memory" ''
    #!${pkgs.bash}/bin/bash
    set -euo pipefail
    TOTAL_KB=$(${grep} "^MemTotal:" /proc/meminfo | ${awk} '{print $2}')
    echo $((TOTAL_KB / 1024))  # MB
  '';

  # High-RAM profile (>=32GB): generous caps, still reasonable for a client
  high = {
    rmem               = "4096 262144 16777216";
    wmem               = "4096 262144 16777216";
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

  # Standard profile (<32GB): moderate caps (safe on laptops)
  std = {
    rmem               = "4096 131072 8388608";
    wmem               = "4096 131072 8388608";
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
in
{
  # ============================================================================
  # Kernel sysctl — modern, minimal, and effective defaults
  # ============================================================================
  boot.kernel.sysctl = {
    # Queueing & Congestion Control
    "net.core.default_qdisc" = "fq";   # pacing-friendly; good with BBR on Wi-Fi
    "net.ipv4.tcp_congestion_control" = "bbr";

    # Increase ephemeral port range for busy client workloads (browsers, VPN)
    "net.ipv4.ip_local_port_range" = "1024 65535";

    # Socket buffer caps (mkDefault; high profile may override at boot)
    "net.core.rmem_max"     = lib.mkDefault std.rmem_max;
    "net.core.rmem_default" = lib.mkDefault std.rmem_default;
    "net.core.wmem_max"     = lib.mkDefault std.wmem_max;
    "net.core.wmem_default" = lib.mkDefault std.wmem_default;

    # Device backlog / scheduler budgets
    "net.core.netdev_max_backlog" = lib.mkDefault std.netdev_max_backlog;
    "net.core.netdev_budget"      = 300;

    # listen() backlog (server-ish apps / local proxies benefit)
    "net.core.somaxconn" = lib.mkDefault std.somaxconn;

    # eBPF JIT hardening
    "net.core.bpf_jit_enable" = 1;
    "net.core.bpf_jit_harden" = 1;  # 1 is hardened, 2 is extra cost; 1 is good

    # TCP Fast Open (client + server)
    "net.ipv4.tcp_fastopen" = 3;

    # TCP/UDP windows & memory pressure
    "net.ipv4.tcp_rmem" = lib.mkDefault std.rmem;
    "net.ipv4.tcp_wmem" = lib.mkDefault std.wmem;
    "net.ipv4.tcp_mem"  = lib.mkDefault std.tcp_mem;
    "net.ipv4.udp_mem"  = lib.mkDefault std.udp_mem;

    # Selective ACKs (modern defaults; fack is gone; dsack is enough)
    "net.ipv4.tcp_dsack" = 1;

    # Sensible latency/throughput defaults:
    "net.ipv4.tcp_slow_start_after_idle" = 0;
    "net.ipv4.tcp_moderate_rcvbuf"       = 1;

    # Not-sent low water mark: cap large app buffers (helps HTTP/2, browsers)
    # Safe, conservative default. Comment out if you prefer kernel default.
    "net.ipv4.tcp_notsent_lowat" = 16384;

    # Let kernel handle early retrans & thin-stream heuristics (defaults are best)
    # (Removed explicit tcp_early_retrans / tcp_thin_linear_timeouts)

    # Path MTU: probe blackholes, keep conservative base MSS optional
    "net.ipv4.tcp_mtu_probing" = 1;
    # "net.ipv4.tcp_base_mss"    = 1200;  # only if you consistently hit tunnels

    # Connection management
    "net.ipv4.tcp_keepalive_time"   = 300;
    "net.ipv4.tcp_keepalive_intvl"  = 30;
    "net.ipv4.tcp_keepalive_probes" = 3;
    "net.ipv4.tcp_fin_timeout"      = 30;
    "net.ipv4.tcp_max_tw_buckets"   = lib.mkDefault std.tcp_max_tw_buckets;

    # Retransmission knobs (keep near defaults)
    "net.ipv4.tcp_retries2"      = 8;
    "net.ipv4.tcp_syn_retries"   = 3;
    "net.ipv4.tcp_synack_retries"= 3;

    # SYN & backlog protection
    "net.ipv4.tcp_syncookies"      = 1;
    "net.ipv4.tcp_max_syn_backlog" = lib.mkDefault std.tcp_max_syn_backlog;

    # Reordering tolerance (keep conservative)
    "net.ipv4.tcp_reordering" = 3;

    # ECN with fallback (best of both worlds)
    "net.ipv4.tcp_ecn"          = 1;
    "net.ipv4.tcp_ecn_fallback" = 1;

    # FRTO & RFC1337 fix
    "net.ipv4.tcp_frto"    = 2;
    "net.ipv4.tcp_rfc1337" = 1;

    # rp_filter loose (VPN/tether friendly)
    "net.ipv4.conf.all.rp_filter"     = 2;
    "net.ipv4.conf.default.rp_filter" = 2;

    # ICMP redirects/source routes off (hardening)
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

    # Conntrack (only matters if nf_conntrack loaded / firewall active)
    "net.netfilter.nf_conntrack_max"                         = lib.mkDefault std.conntrack_max;
    "net.netfilter.nf_conntrack_tcp_timeout_established"     = 432000;  # 5 days
    "net.netfilter.nf_conntrack_tcp_timeout_time_wait"       = 30;
    "net.netfilter.nf_conntrack_tcp_timeout_fin_wait"        = 30;
    "net.netfilter.nf_conntrack_generic_timeout"             = 600;
  };

  # ============================================================================
  # Dynamic tuning at boot — if RAM >= 32GB, lift ceilings
  # ============================================================================
  systemd.services.dynamic-tcp-tuning = {
    description = "Apply dynamic TCP tuning based on total system memory";
    wantedBy = [ "multi-user.target" ];
    after = [ "sysinit.target" "network-pre.target" ];
    before = [ "network.target" ];
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

  # Small diagnostic helper
  environment.systemPackages = with pkgs; [
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
      echo "Connections:"
      echo -n "  TCP total:     "; ${pkgs.iproute2}/bin/ss -s | ${pkgs.gnugrep}/bin/grep -oP 'TCP:\s+\K\d+'
      echo -n "  TIME-WAIT:     "; ${pkgs.iproute2}/bin/ss -tan state time-wait | wc -l
    '')
  ];
}
