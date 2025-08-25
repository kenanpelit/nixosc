# modules/core/tcp/default.nix
# ==============================================================================
# Dynamic TCP/IP Stack Optimizations
# ==============================================================================
# This configuration dynamically adjusts TCP/IP stack settings based on:
# - System RAM (16GB vs 64GB)
# - CPU type (Kaby Lake R vs Meteor Lake)
# - Laptop-specific optimizations
#
# Supported Systems:
# - ThinkPad X1 Carbon 6th (Intel Core i7-8650U, 16GB RAM): Conservative tuning
# - ThinkPad E14 Gen 6 (Intel Core Ultra 7 155H, 64GB RAM): Aggressive tuning
#
# Author: Kenan Pelit
# ==============================================================================
{ config, lib, pkgs, ... }:

let
  # Komutların tam yollarını tanımla
  awk = "${pkgs.gawk}/bin/awk";
  grep = "${pkgs.gnugrep}/bin/grep";
  sysctl = "${pkgs.procps}/bin/sysctl";
  
  # Sistem RAM miktarını tespit et
  detectMemoryScript = pkgs.writeShellScript "detect-memory" ''
    #!/usr/bin/env bash
    # Total memory in KB from /proc/meminfo
    TOTAL_KB=$(${grep} "^MemTotal:" /proc/meminfo | ${awk} '{print $2}')
    # Convert to MB
    TOTAL_MB=$((TOTAL_KB / 1024))
    echo "$TOTAL_MB"
  '';
  
  # 64GB RAM için optimizasyon (E14 Gen 6) - Daha agresif
  highMemConfig = {
    rmem = "4096 131072 6291456";      # min: 4KB, default: 128KB, max: 6MB (12MB -> 6MB)
    wmem = "4096 131072 6291456";      # min: 4KB, default: 128KB, max: 6MB (12MB -> 6MB)
    rmem_max = 6291456;                # 6MB maksimum receive buffer (12MB -> 6MB)
    wmem_max = 6291456;                # 6MB maksimum send buffer (12MB -> 6MB)
    rmem_default = 262144;             # 256KB varsayılan receive buffer
    wmem_default = 262144;             # 256KB varsayılan send buffer
    netdev_max_backlog = 3000;         # Daha yüksek paket kuyruğu (4000 -> 3000)
    somaxconn = 512;                   # Eşzamanlı bağlantı (768 -> 512)
    tcp_max_syn_backlog = 1024;        # SYN kuyruğu (1536 -> 1024)
    tcp_mem = "196608 262144 524288";  # 768MB-1GB-2GB (daha konservatif)
    udp_mem = "98304 131072 262144";   # 384MB-512MB-1GB (daha konservatif)
  };
  
  # 16GB RAM için optimizasyon (X1 Carbon 6th) - Daha konservatif
  standardMemConfig = {
    rmem = "4096 87380 4194304";       # min: 4KB, default: 85KB, max: 4MB (8MB -> 4MB)
    wmem = "4096 87380 4194304";       # min: 4KB, default: 85KB, max: 4MB (8MB -> 4MB)
    rmem_max = 4194304;                # 4MB maksimum receive buffer (8MB -> 4MB)
    wmem_max = 4194304;                # 4MB maksimum send buffer (8MB -> 4MB)
    rmem_default = 131072;             # 128KB varsayılan receive buffer
    wmem_default = 131072;             # 128KB varsayılan send buffer
    netdev_max_backlog = 2000;         # Standart paket kuyruğu (2500 -> 2000)
    somaxconn = 256;                   # Orta seviye bağlantı sayısı (512 -> 256)
    tcp_max_syn_backlog = 512;         # Standart SYN kuyruğu (1024 -> 512)
    tcp_mem = "98304 131072 262144";   # 384MB-512MB-1GB (daha küçük)
    udp_mem = "49152 65536 131072";    # 192MB-256MB-512MB (daha küçük)
  };
  
  # Güç tasarrufu ayarları
  highMemPowerSettings = {
    tcp_keepalive_time = 720;     # 12dk (15dk -> 12dk)
    tcp_keepalive_intvl = 60;     # 60s (75s -> 60s)
    tcp_keepalive_probes = 3;
    tcp_orphan_retries = 1;
    tcp_fin_timeout = 15;
    tcp_retries2 = 5;             # 8 -> 5 (daha agresif timeout)
  };
  
  standardMemPowerSettings = {
    tcp_keepalive_time = 600;     # 10dk
    tcp_keepalive_intvl = 45;     # 45s (60s -> 45s)
    tcp_keepalive_probes = 3;
    tcp_orphan_retries = 1;
    tcp_fin_timeout = 20;
    tcp_retries2 = 5;             # 8 -> 5
  };
  
  # WiFi optimizasyonları
  wifiOptimizations = {
    tcp_no_metrics_save = 1;
    tcp_moderate_rcvbuf = 1;
    tcp_abc = 1;
    tcp_frto = 2;
    tcp_mtu_probing = 1;
    tcp_low_latency = 0;
  };
in
{
  boot.kernel.sysctl = {
    # Temel TCP ayarları
    "net.core.default_qdisc" = "fq";
    "net.ipv4.tcp_congestion_control" = "bbr";
    
    # TCP performans
    "net.ipv4.tcp_fastopen" = 3;
    "net.ipv4.tcp_slow_start_after_idle" = 0;
    "net.ipv4.tcp_window_scaling" = 1;
    "net.ipv4.tcp_sack" = 1;
    "net.ipv4.tcp_fack" = 1;
    "net.ipv4.tcp_timestamps" = 1;
    "net.ipv4.tcp_dsack" = 1;
    
    # Varsayılan buffer ayarları (X1 Carbon için optimize)
    "net.ipv4.tcp_rmem" = lib.mkDefault standardMemConfig.rmem;
    "net.core.rmem_max" = lib.mkDefault standardMemConfig.rmem_max;
    "net.core.rmem_default" = lib.mkDefault standardMemConfig.rmem_default;
    
    "net.ipv4.tcp_wmem" = lib.mkDefault standardMemConfig.wmem;
    "net.core.wmem_max" = lib.mkDefault standardMemConfig.wmem_max;
    "net.core.wmem_default" = lib.mkDefault standardMemConfig.wmem_default;
    
    "net.ipv4.tcp_mem" = lib.mkDefault standardMemConfig.tcp_mem;
    "net.ipv4.udp_mem" = lib.mkDefault standardMemConfig.udp_mem;
    
    "net.core.netdev_max_backlog" = lib.mkDefault standardMemConfig.netdev_max_backlog;
    "net.core.somaxconn" = lib.mkDefault standardMemConfig.somaxconn;
    "net.ipv4.tcp_max_syn_backlog" = lib.mkDefault standardMemConfig.tcp_max_syn_backlog;
    
    # Bağlantı yönetimi
    "net.ipv4.tcp_fin_timeout" = lib.mkDefault standardMemPowerSettings.tcp_fin_timeout;
    "net.ipv4.tcp_tw_reuse" = 1;
    
    # Keep-alive
    "net.ipv4.tcp_keepalive_time" = lib.mkDefault standardMemPowerSettings.tcp_keepalive_time;
    "net.ipv4.tcp_keepalive_intvl" = lib.mkDefault standardMemPowerSettings.tcp_keepalive_intvl;
    "net.ipv4.tcp_keepalive_probes" = lib.mkDefault standardMemPowerSettings.tcp_keepalive_probes;
    
    # WiFi optimizasyonları
    "net.ipv4.tcp_no_metrics_save" = wifiOptimizations.tcp_no_metrics_save;
    "net.ipv4.tcp_moderate_rcvbuf" = wifiOptimizations.tcp_moderate_rcvbuf;
    "net.ipv4.tcp_abc" = wifiOptimizations.tcp_abc;
    "net.ipv4.tcp_frto" = wifiOptimizations.tcp_frto;
    "net.ipv4.tcp_mtu_probing" = wifiOptimizations.tcp_mtu_probing;
    "net.ipv4.tcp_low_latency" = wifiOptimizations.tcp_low_latency;
    
    # ECN
    "net.ipv4.tcp_ecn" = 1;
    "net.ipv4.tcp_ecn_fallback" = 1;
    
    # Güç tasarrufu
    "net.ipv4.tcp_orphan_retries" = lib.mkDefault standardMemPowerSettings.tcp_orphan_retries;
    "net.ipv4.tcp_retries2" = lib.mkDefault standardMemPowerSettings.tcp_retries2;
    "net.ipv4.tcp_synack_retries" = 2;                 # 3 -> 2
    "net.ipv4.tcp_syn_retries" = 2;                    # 3 -> 2
    
    # Güvenlik
    "net.ipv4.tcp_syncookies" = 1;
    "net.ipv4.tcp_max_orphans" = 16384;                # 32768 -> 16384
    
    # Reverse Path Filtering
    "net.ipv4.conf.all.rp_filter" = 1;
    "net.ipv4.conf.default.rp_filter" = 1;
    
    # ICMP security
    "net.ipv4.icmp_echo_ignore_broadcasts" = 1;
    "net.ipv4.icmp_ignore_bogus_error_responses" = 1;
    "net.ipv4.icmp_errors_use_inbound_ifaddr" = 1;
    
    # IPv6 security
    "net.ipv6.conf.all.accept_redirects" = 0;
    "net.ipv6.conf.default.accept_redirects" = 0;
    "net.ipv6.conf.all.accept_source_route" = 0;
    "net.ipv6.conf.default.accept_source_route" = 0;
    "net.ipv6.conf.all.forwarding" = 0;
    "net.ipv6.conf.all.accept_ra" = 0;
    "net.ipv6.conf.default.accept_ra" = 0;
    
    # VPN optimizasyon
    "net.core.netdev_budget" = 500;                    # 600 -> 500
    "net.core.netdev_budget_usecs" = 4000;             # 5000 -> 4000
    
    # Performans
    "net.ipv4.tcp_reordering" = 3;
    "net.ipv4.tcp_max_reordering" = 300;
    "net.ipv4.tcp_app_win" = 31;
    "net.ipv4.tcp_adv_win_scale" = 1;                  # 2 -> 1 (daha konservatif)
    
    # TCP timer
    "net.ipv4.tcp_rfc1337" = 1;
    "net.ipv4.tcp_abort_on_overflow" = 0;
    
    # IP fragment
    "net.ipv4.ipfrag_high_thresh" = 3145728;           # 4MB -> 3MB
    "net.ipv4.ipfrag_low_thresh" = 2097152;            # 3MB -> 2MB
    "net.ipv4.ipfrag_time" = 30;
    
    # Neighbor table
    "net.ipv4.neigh.default.gc_thresh1" = 128;
    "net.ipv4.neigh.default.gc_thresh2" = 512;
    "net.ipv4.neigh.default.gc_thresh3" = 1024;
   
    # ============================================================================
    # Debugging ve Monitoring (opsiyonel, kapalı)
    # ============================================================================
    # "net.ipv4.tcp_verbose_logging" = 0;              # Verbose logging kapalı
    # "net.ipv4.tcp_log_info" = 0;                     # Info logging kapalı
  };
  
  # ==============================================================================
  # Sistem Bilgi Mesajı
  # ==============================================================================
  system.activationScripts.tcpInfo = ''
    # Runtime'da bellek miktarını kontrol et
    TOTAL_MB=$(${detectMemoryScript})
    
    if [ "$TOTAL_MB" -ge 32768 ]; then
      echo "TCP/IP Stack configured for High Memory System (64GB)"
      echo "Detected RAM: $((TOTAL_MB / 1024))GB"
      echo "TCP buffers: max receive=${toString highMemConfig.rmem_max} bytes, max send=${toString highMemConfig.wmem_max} bytes"
      echo "Network backlog: ${toString highMemConfig.netdev_max_backlog} packets"
    else
      echo "TCP/IP Stack configured for Standard Memory System (16GB)"
      echo "Detected RAM: $((TOTAL_MB / 1024))GB"
      echo "TCP buffers: max receive=${toString standardMemConfig.rmem_max} bytes, max send=${toString standardMemConfig.wmem_max} bytes"
      echo "Network backlog: ${toString standardMemConfig.netdev_max_backlog} packets"
    fi
  '';
  
  # Runtime'da sysctl değerlerini ayarlayan servis
  systemd.services.dynamic-tcp-tuning = {
    description = "Apply dynamic TCP tuning based on system memory";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = pkgs.writeShellScript "apply-tcp-tuning" ''
        #!/usr/bin/env bash
        set -euo pipefail
        
        # Bellek miktarını kontrol et
        TOTAL_MB=$(${detectMemoryScript})
        
        if [ "$TOTAL_MB" -ge 32768 ]; then
          # High Memory System (64GB) ayarları
          echo "Applying TCP settings for High Memory System"
          
          # TCP buffer ayarları - sysctl komutunu tam yoluyla kullan
          ${sysctl} -w net.ipv4.tcp_rmem="${highMemConfig.rmem}"
          ${sysctl} -w net.ipv4.tcp_wmem="${highMemConfig.wmem}"
          ${sysctl} -w net.core.rmem_max=${toString highMemConfig.rmem_max}
          ${sysctl} -w net.core.wmem_max=${toString highMemConfig.wmem_max}
          ${sysctl} -w net.core.rmem_default=${toString highMemConfig.rmem_default}
          ${sysctl} -w net.core.wmem_default=${toString highMemConfig.wmem_default}
          ${sysctl} -w net.core.netdev_max_backlog=${toString highMemConfig.netdev_max_backlog}
          ${sysctl} -w net.core.somaxconn=${toString highMemConfig.somaxconn}
          ${sysctl} -w net.ipv4.tcp_max_syn_backlog=${toString highMemConfig.tcp_max_syn_backlog}
          ${sysctl} -w net.ipv4.tcp_mem="${highMemConfig.tcp_mem}"
          ${sysctl} -w net.ipv4.udp_mem="${highMemConfig.udp_mem}"
          
          # Power settings
          ${sysctl} -w net.ipv4.tcp_keepalive_time=${toString highMemPowerSettings.tcp_keepalive_time}
          ${sysctl} -w net.ipv4.tcp_keepalive_intvl=${toString highMemPowerSettings.tcp_keepalive_intvl}
          ${sysctl} -w net.ipv4.tcp_fin_timeout=${toString highMemPowerSettings.tcp_fin_timeout}
        else
          # Standard Memory System (16GB) ayarları
          echo "Applying TCP settings for Standard Memory System"
          
          # TCP buffer ayarları
          ${sysctl} -w net.ipv4.tcp_rmem="${standardMemConfig.rmem}"
          ${sysctl} -w net.ipv4.tcp_wmem="${standardMemConfig.wmem}"
          ${sysctl} -w net.core.rmem_max=${toString standardMemConfig.rmem_max}
          ${sysctl} -w net.core.wmem_max=${toString standardMemConfig.wmem_max}
          ${sysctl} -w net.core.rmem_default=${toString standardMemConfig.rmem_default}
          ${sysctl} -w net.core.wmem_default=${toString standardMemConfig.wmem_default}
          ${sysctl} -w net.core.netdev_max_backlog=${toString standardMemConfig.netdev_max_backlog}
          ${sysctl} -w net.core.somaxconn=${toString standardMemConfig.somaxconn}
          ${sysctl} -w net.ipv4.tcp_max_syn_backlog=${toString standardMemConfig.tcp_max_syn_backlog}
          ${sysctl} -w net.ipv4.tcp_mem="${standardMemConfig.tcp_mem}"
          ${sysctl} -w net.ipv4.udp_mem="${standardMemConfig.udp_mem}"
          
          # Power settings
          ${sysctl} -w net.ipv4.tcp_keepalive_time=${toString standardMemPowerSettings.tcp_keepalive_time}
          ${sysctl} -w net.ipv4.tcp_keepalive_intvl=${toString standardMemPowerSettings.tcp_keepalive_intvl}
          ${sysctl} -w net.ipv4.tcp_fin_timeout=${toString standardMemPowerSettings.tcp_fin_timeout}
        fi
      '';
    };
  };
}
