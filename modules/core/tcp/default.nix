# modules/core/tcp/default.nix
# ==============================================================================
# Optimized TCP/IP Stack Configuration for NixOS
# ==============================================================================
# Streamlined TCP/IP configuration with dynamic memory detection and
# adaptive tuning for laptop/desktop systems.
#
# Key Features:
# - BBR congestion control for optimal throughput
# - Dynamic buffer sizing based on available RAM
# - Security hardening without breaking functionality
# - Minimal, effective configuration
#
# Versiyon: 4.1.0
# Tarih:    2025-08-27
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

  # 32GB+ için yüksek profil
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

  # 16GB ve altı için standart profil
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
  # Çekirdek sysctl – modern ve etkili varsayılanlar
  # ============================================================================
  boot.kernel.sysctl = {
    # Çekirdek kuyruğu & BBR
    "net.core.default_qdisc" = "fq";
    "net.ipv4.tcp_congestion_control" = "bbr";

    # Maks. socket buffer’ları (std profilden gelen mkDefault)
    "net.core.rmem_max"     = lib.mkDefault std.rmem_max;
    "net.core.rmem_default" = lib.mkDefault std.rmem_default;
    "net.core.wmem_max"     = lib.mkDefault std.wmem_max;
    "net.core.wmem_default" = lib.mkDefault std.wmem_default;

    # Aygıt backlog
    "net.core.netdev_max_backlog" = lib.mkDefault std.netdev_max_backlog;
    "net.core.netdev_budget"      = 300;

    # listen() backlog
    "net.core.somaxconn" = lib.mkDefault std.somaxconn;

    # eBPF JIT (sertleştirme açık)
    "net.core.bpf_jit_enable" = 1;
    "net.core.bpf_jit_harden" = 1;

    # TCP Fast Open (client+server)
    "net.ipv4.tcp_fastopen" = 3;

    # TCP/UDP bufferları & memory basıncı
    "net.ipv4.tcp_rmem" = lib.mkDefault std.rmem;
    "net.ipv4.tcp_wmem" = lib.mkDefault std.wmem;
    "net.ipv4.tcp_mem"  = lib.mkDefault std.tcp_mem;
    "net.ipv4.udp_mem"  = lib.mkDefault std.udp_mem;

    # Seçmeli ACK ayarları (fack kaldırıldı; dsack yeterli)
    "net.ipv4.tcp_dsack" = 1;

    # TCP performans
    "net.ipv4.tcp_slow_start_after_idle" = 0;
    "net.ipv4.tcp_moderate_rcvbuf"       = 1;
    # "net.ipv4.tcp_notsent_lowat" = 16384;  # Ölçerek fayda görürsen aç

    # Erken yeniden iletim
    "net.ipv4.tcp_early_retrans"         = 3;
    "net.ipv4.tcp_thin_linear_timeouts"  = 1;

    # Path MTU Discovery & MSS tabanı (PMTU açık; base MSS ayarını minimal tut)
    "net.ipv4.tcp_mtu_probing" = 1;
    # "net.ipv4.tcp_base_mss"    = 1200;     # İstersen etkinleştir

    # Bağlantı yönetimi
    "net.ipv4.tcp_keepalive_time"   = 300;
    "net.ipv4.tcp_keepalive_intvl"  = 30;
    "net.ipv4.tcp_keepalive_probes" = 3;
    "net.ipv4.tcp_fin_timeout"      = 30;
    "net.ipv4.tcp_max_tw_buckets"   = lib.mkDefault std.tcp_max_tw_buckets;

    # Retransmission
    "net.ipv4.tcp_retries2"      = 8;
    "net.ipv4.tcp_syn_retries"   = 3;
    "net.ipv4.tcp_synack_retries"= 3;

    # SYN Cookies & backlog
    "net.ipv4.tcp_syncookies"     = 1;
    "net.ipv4.tcp_max_syn_backlog"= lib.mkDefault std.tcp_max_syn_backlog;

    # Paket yeniden sıralama toleransı
    "net.ipv4.tcp_reordering" = 3;

    # ECN (geri düşüş açık)
    "net.ipv4.tcp_ecn"           = 1;
    "net.ipv4.tcp_ecn_fallback"  = 1;

    # FRTO ve RFC1337 koruması
    "net.ipv4.tcp_frto"   = 2;
    "net.ipv4.tcp_rfc1337"= 1;

    # Güvenlik – rp_filter (VPN/tethering uyumlu loose mod)
    "net.ipv4.conf.all.rp_filter"     = 2;
    "net.ipv4.conf.default.rp_filter" = 2;

    # ICMP redirect’ler kapalı
    "net.ipv4.conf.all.accept_redirects"     = 0;
    "net.ipv4.conf.default.accept_redirects" = 0;
    "net.ipv4.conf.all.secure_redirects"     = 0;
    "net.ipv4.conf.default.secure_redirects" = 0;
    "net.ipv4.conf.all.send_redirects"       = 0;

    # Source routing kapalı
    "net.ipv4.conf.all.accept_source_route"     = 0;
    "net.ipv4.conf.default.accept_source_route" = 0;

    # ICMP güvenlikleri
    "net.ipv4.icmp_echo_ignore_broadcasts"   = 1;
    "net.ipv4.icmp_ignore_bogus_error_responses" = 1;

    # IPv6 redirect/source-route kapalı
    "net.ipv6.conf.all.accept_redirects"     = 0;
    "net.ipv6.conf.default.accept_redirects" = 0;
    "net.ipv6.conf.all.accept_source_route"  = 0;

    # Conntrack
    "net.netfilter.nf_conntrack_max"                         = lib.mkDefault std.conntrack_max;
    "net.netfilter.nf_conntrack_tcp_timeout_established"     = 432000;  # 5 gün
    "net.netfilter.nf_conntrack_tcp_timeout_time_wait"       = 30;
    "net.netfilter.nf_conntrack_tcp_timeout_fin_wait"        = 30;
    "net.netfilter.nf_conntrack_generic_timeout"             = 600;
  };

  # ============================================================================
  # RAM’e göre dinamik tuning – yüksek profil gerekiyorsa üzerine yaz
  # ============================================================================
  systemd.services.dynamic-tcp-tuning = {
    description = "Apply dynamic TCP tuning based on total system memory";
    wantedBy = [ "multi-user.target" ];
    after = [ "network-pre.target" ];
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

  # İzleme/diagnostic aracı (ek bilgi satırları eklendi)
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
      echo "  MTU Probing:        $(${sysctl} -n net.ipv4.tcp_mtu_probing)"
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
      echo "Interfaces (MTU):"
      ${pkgs.iproute2}/bin/ip -br link | ${pkgs.gawk}/bin/awk '{print "  " $1 ": " $3}'
      echo
      echo "Connections:"
      echo -n "  TCP total:     "; ${pkgs.iproute2}/bin/ss -s | ${pkgs.gnugrep}/bin/grep -oP 'TCP:\s+\K\d+'
      echo -n "  TIME-WAIT:     "; ${pkgs.iproute2}/bin/ss -tan state time-wait | wc -l
    '')
  ];
}

