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
# - ThinkPad X1 Carbon 6th (Intel Core i7-8650U, 16GB RAM)
# - ThinkPad E14 Gen 6 (Intel Core Ultra 7 155H, 64GB RAM)
#
# Author: Kenan Pelit
# ==============================================================================
{ config, lib, pkgs, ... }:

let
  # Sistem RAM miktarını MB cinsinden al
  totalMemoryMB = config.hardware.memorySize or 16384; # Varsayılan 16GB
  
  # RAM'e göre sistem tipini belirle
  isHighMemSystem = totalMemoryMB >= 32768; # 32GB ve üzeri
  
  # TCP buffer boyutlarını RAM'e göre ayarla
  tcpConfig = if isHighMemSystem then {
    # 64GB RAM için optimizasyon (E14 Gen 6)
    rmem = "4096 131072 12582912";      # min: 4KB, default: 128KB, max: 12MB
    wmem = "4096 131072 12582912";      # min: 4KB, default: 128KB, max: 12MB
    rmem_max = 12582912;                # 12MB maksimum receive buffer
    wmem_max = 12582912;                # 12MB maksimum send buffer
    rmem_default = 262144;              # 256KB varsayılan receive buffer
    wmem_default = 262144;              # 256KB varsayılan send buffer
    netdev_max_backlog = 4000;          # Daha yüksek paket kuyruğu
    somaxconn = 768;                    # Daha fazla eşzamanlı bağlantı
    tcp_max_syn_backlog = 1536;         # Daha büyük SYN kuyruğu
    tcp_mem = "786432 1048576 3145728"; # 3GB-4GB-12GB (sayfa cinsinden)
    udp_mem = "393216 524288 1572864";  # 1.5GB-2GB-6GB (sayfa cinsinden)
  } else {
    # 16GB RAM için optimizasyon (X1 Carbon 6th)
    rmem = "4096 87380 8388608";        # min: 4KB, default: 85KB, max: 8MB
    wmem = "4096 87380 8388608";        # min: 4KB, default: 85KB, max: 8MB
    rmem_max = 8388608;                 # 8MB maksimum receive buffer
    wmem_max = 8388608;                 # 8MB maksimum send buffer
    rmem_default = 131072;              # 128KB varsayılan receive buffer
    wmem_default = 131072;              # 128KB varsayılan send buffer
    netdev_max_backlog = 2500;          # Standart paket kuyruğu
    somaxconn = 512;                    # Orta seviye bağlantı sayısı
    tcp_max_syn_backlog = 1024;         # Standart SYN kuyruğu
    tcp_mem = "196608 262144 786432";   # 768MB-1GB-3GB (sayfa cinsinden)
    udp_mem = "98304 131072 393216";    # 384MB-512MB-1.5GB (sayfa cinsinden)
  };
  
  # Güç tasarrufu ayarları (her iki sistem için de laptop optimizasyonları)
  powerSettings = {
    # Batarya ömrü için optimize edilmiş keep-alive ayarları
    tcp_keepalive_time = if isHighMemSystem then 900 else 600;     # 15dk vs 10dk
    tcp_keepalive_intvl = if isHighMemSystem then 75 else 60;      # 75s vs 60s
    tcp_keepalive_probes = 3;                                       # Her iki sistem için aynı
    
    # Güç tasarrufu için azaltılmış retry ve timeout değerleri
    tcp_orphan_retries = 1;                                         # Orphan socket retry sayısı
    tcp_fin_timeout = if isHighMemSystem then 15 else 20;          # FIN-WAIT-2 timeout
    tcp_retries2 = 8;                                               # Maksimum TCP retry sayısı
  };
  
  # WiFi ve mobil ağ optimizasyonları (laptop için önemli)
  wifiOptimizations = {
    tcp_no_metrics_save = 1;            # WiFi için metrik kaydetme
    tcp_moderate_rcvbuf = 1;            # Otomatik buffer ayarlama
    tcp_abc = 1;                        # Appropriate Byte Counting
    tcp_frto = 2;                        # Forward RTO-Recovery (WiFi packet loss için)
    tcp_mtu_probing = 1;                # Path MTU Discovery etkin
    tcp_low_latency = 0;                # Latency yerine throughput öncelikli
  };
in
{
  # ==============================================================================
  # Kernel Sysctl Parametreleri
  # ==============================================================================
  boot.kernel.sysctl = {
    # ============================================================================
    # TCP Congestion Control (BBR)
    # ============================================================================
    # BBR (Bottleneck Bandwidth and RTT) modern congestion control algoritması
    "net.core.default_qdisc" = "fq";                    # Fair Queue (BBR için gerekli)
    "net.ipv4.tcp_congestion_control" = "bbr";          # BBR algoritması
    
    # ============================================================================
    # TCP Performans Ayarları
    # ============================================================================
    # TCP Fast Open - 3-way handshake optimizasyonu
    "net.ipv4.tcp_fastopen" = 3;                        # Hem client hem server için etkin
    
    # Idle connection optimizasyonu
    "net.ipv4.tcp_slow_start_after_idle" = 0;          # Idle sonrası yavaş başlama kapalı
    
    # TCP Window Scaling ve SACK (Selective Acknowledgment)
    "net.ipv4.tcp_window_scaling" = 1;                 # Büyük pencereler için
    "net.ipv4.tcp_sack" = 1;                          # Selective ACK etkin
    "net.ipv4.tcp_fack" = 1;                          # Forward ACK etkin
    "net.ipv4.tcp_timestamps" = 1;                    # Timestamp etkin (RTT ölçümü için)
    "net.ipv4.tcp_dsack" = 1;                         # Duplicate SACK etkin
    
    # ============================================================================
    # TCP Memory ve Buffer Ayarları (RAM'e göre dinamik)
    # ============================================================================
    # Receive buffer boyutları (min, default, max)
    "net.ipv4.tcp_rmem" = tcpConfig.rmem;
    "net.core.rmem_max" = tcpConfig.rmem_max;
    "net.core.rmem_default" = tcpConfig.rmem_default;
    
    # Send buffer boyutları (min, default, max)
    "net.ipv4.tcp_wmem" = tcpConfig.wmem;
    "net.core.wmem_max" = tcpConfig.wmem_max;
    "net.core.wmem_default" = tcpConfig.wmem_default;
    
    # TCP memory limits (low, pressure, high) - sayfa cinsinden
    "net.ipv4.tcp_mem" = tcpConfig.tcp_mem;
    "net.ipv4.udp_mem" = tcpConfig.udp_mem;
    
    # Network device backlog
    "net.core.netdev_max_backlog" = tcpConfig.netdev_max_backlog;
    
    # ============================================================================
    # Connection Management
    # ============================================================================
    # Maksimum eşzamanlı bağlantı sayısı
    "net.core.somaxconn" = tcpConfig.somaxconn;
    "net.ipv4.tcp_max_syn_backlog" = tcpConfig.tcp_max_syn_backlog;
    
    # Bağlantı yaşam döngüsü
    "net.ipv4.tcp_fin_timeout" = powerSettings.tcp_fin_timeout;
    "net.ipv4.tcp_tw_reuse" = 1;                       # TIME-WAIT socket'leri yeniden kullan
    
    # ============================================================================
    # Keep-alive Ayarları (Güç tasarrufu optimize)
    # ============================================================================
    "net.ipv4.tcp_keepalive_time" = powerSettings.tcp_keepalive_time;
    "net.ipv4.tcp_keepalive_intvl" = powerSettings.tcp_keepalive_intvl;
    "net.ipv4.tcp_keepalive_probes" = powerSettings.tcp_keepalive_probes;
    
    # ============================================================================
    # WiFi ve Mobil Ağ Optimizasyonları
    # ============================================================================
    "net.ipv4.tcp_no_metrics_save" = wifiOptimizations.tcp_no_metrics_save;
    "net.ipv4.tcp_moderate_rcvbuf" = wifiOptimizations.tcp_moderate_rcvbuf;
    "net.ipv4.tcp_abc" = wifiOptimizations.tcp_abc;
    "net.ipv4.tcp_frto" = wifiOptimizations.tcp_frto;
    "net.ipv4.tcp_mtu_probing" = wifiOptimizations.tcp_mtu_probing;
    "net.ipv4.tcp_low_latency" = wifiOptimizations.tcp_low_latency;
    
    # ECN (Explicit Congestion Notification) - WiFi için faydalı
    "net.ipv4.tcp_ecn" = 1;                            # ECN etkin
    "net.ipv4.tcp_ecn_fallback" = 1;                  # ECN başarısız olursa geri dön
    
    # ============================================================================
    # Güç Tasarrufu Optimizasyonları
    # ============================================================================
    "net.ipv4.tcp_orphan_retries" = powerSettings.tcp_orphan_retries;
    "net.ipv4.tcp_retries2" = powerSettings.tcp_retries2;
    "net.ipv4.tcp_synack_retries" = 3;                 # SYN-ACK retry sayısı
    "net.ipv4.tcp_syn_retries" = 3;                    # SYN retry sayısı
    
    # ============================================================================
    # Güvenlik Ayarları
    # ============================================================================
    # SYN flood koruması
    "net.ipv4.tcp_syncookies" = 1;                     # SYN cookie etkin
    "net.ipv4.tcp_max_orphans" = 32768;                # Maksimum orphan socket
    
    # Reverse Path Filtering (spoofing koruması)
    "net.ipv4.conf.all.rp_filter" = 1;
    "net.ipv4.conf.default.rp_filter" = 1;
    
    # ICMP yönlendirmeleri reddet
    "net.ipv4.conf.all.accept_redirects" = 0;
    "net.ipv4.conf.default.accept_redirects" = 0;
    "net.ipv4.conf.all.secure_redirects" = 0;
    "net.ipv4.conf.default.secure_redirects" = 0;
    "net.ipv4.conf.all.send_redirects" = 0;
    "net.ipv4.conf.default.send_redirects" = 0;
    
    # Kaynak yönlendirme reddet
    "net.ipv4.conf.all.accept_source_route" = 0;
    "net.ipv4.conf.default.accept_source_route" = 0;
    
    # ICMP güvenlik
    "net.ipv4.icmp_echo_ignore_broadcasts" = 1;       # Broadcast ping'leri yoksay
    "net.ipv4.icmp_ignore_bogus_error_responses" = 1; # Hatalı ICMP yanıtlarını yoksay
    "net.ipv4.icmp_errors_use_inbound_ifaddr" = 1;    # ICMP hata mesajları için doğru kaynak IP
    
    # IPv6 güvenlik
    "net.ipv6.conf.all.accept_redirects" = 0;
    "net.ipv6.conf.default.accept_redirects" = 0;
    "net.ipv6.conf.all.accept_source_route" = 0;
    "net.ipv6.conf.default.accept_source_route" = 0;
    "net.ipv6.conf.all.forwarding" = 0;                # Laptop'ta forwarding kapalı
    "net.ipv6.conf.all.accept_ra" = 0;                 # Router Advertisement güvenlik
    "net.ipv6.conf.default.accept_ra" = 0;
    
    # ============================================================================
    # VPN Optimizasyonları (WireGuard/OpenVPN için)
    # ============================================================================
    "net.core.netdev_budget" = 600;                    # Paket işleme bütçesi
    "net.core.netdev_budget_usecs" = 5000;             # Paket işleme zaman limiti (5ms)
    
    # ============================================================================
    # Ek Performans Ayarları
    # ============================================================================
    # TCP algoritma seçenekleri
    "net.ipv4.tcp_reordering" = 3;                     # Packet reordering threshold
    "net.ipv4.tcp_max_reordering" = 300;               # Maksimum reordering
    "net.ipv4.tcp_app_win" = 31;                       # Reserved window for application
    "net.ipv4.tcp_adv_win_scale" = 2;                  # Window scaling factor
    
    # TCP timer ayarları
    "net.ipv4.tcp_rfc1337" = 1;                        # TIME-WAIT assassination hazards koruması
    "net.ipv4.tcp_abort_on_overflow" = 0;              # Overflow durumunda bağlantıyı kesme
    
    # IP fragment ayarları
    "net.ipv4.ipfrag_high_thresh" = 4194304;           # 4MB high threshold
    "net.ipv4.ipfrag_low_thresh" = 3145728;            # 3MB low threshold
    "net.ipv4.ipfrag_time" = 30;                       # Fragment timeout (30 saniye)
    
    # Neighbor table ayarları
    "net.ipv4.neigh.default.gc_thresh1" = 128;         # Minimum neighbor entries
    "net.ipv4.neigh.default.gc_thresh2" = 512;         # Soft maximum
    "net.ipv4.neigh.default.gc_thresh3" = 1024;        # Hard maximum
    
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
    echo "TCP/IP Stack configured for $(if [ "${toString isHighMemSystem}" = "true" ]; then echo "High Memory System (64GB)"; else echo "Standard Memory System (16GB)"; fi)"
    echo "TCP buffers: max receive=${toString tcpConfig.rmem_max} bytes, max send=${toString tcpConfig.wmem_max} bytes"
    echo "Network backlog: ${toString tcpConfig.netdev_max_backlog} packets"
  '';
}

