# modules/core/networking/default.nix
# ==============================================================================
# Kapsam:
# - Hostname, NetworkManager, systemd-resolved, Mullvad VPN, WireGuard
# - Ağ hazır olana kadar bekleme (NM-wait-online) → kapalı: boot takozunu azalt
# - TCP/IP stack optimizasyonları (BBR + fq, buffer sınırları, ECN, vs.)
# - RAM’e göre dinamik TCP tavanları (>=32GB için "high" profil)
# - Teşhis araçları ve alias’lar
#
# Not:
# - Firewall kuralları security/default.nix’te. Burada sadece enable=true kalırsa çakışma olmaz.
# - Mullvad DNS / nameserver seçimi VPN aktifliğine göre mkMerge ile belirleniyor.
#
# Author: Kenan Pelit
# Last merged: 2025-09-04
# ==============================================================================

{ config, lib, pkgs, host, ... }:
let
  inherit (lib) mkIf mkMerge mkDefault;
  toString = builtins.toString;

  hasMullvad = config.services.mullvad-vpn.enable or false;

  # ---- TCP profil parametreleri (high/std) ------------------------------------
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

  # Araç yolları
  awk    = "${pkgs.gawk}/bin/awk";
  grep   = "${pkgs.gnugrep}/bin/grep";
  sysctl = "${pkgs.procps}/bin/sysctl";

  detectMemoryScript = pkgs.writeShellScript "detect-memory" ''
    #!${pkgs.bash}/bin/bash
    set -euo pipefail
    TOTAL_KB=$(${grep} "^MemTotal:" /proc/meminfo | ${awk} '{print $2}')
    echo $((TOTAL_KB / 1024))  # MB
  '';
in
{
  ##############################################################################
  # Base networking
  ##############################################################################
  networking = {
    hostName = "${host}";

    # IPv6 bazı ağlarda ilk el sıkışmaları bozabiliyor; stabil sonrası açılabilir.
    enableIPv6 = false;

    # Wi-Fi yönetimini NM’ye bırak
    wireless.enable = false;

    networkmanager = {
      enable = true;
      wifi = {
        backend = "wpa_supplicant";
        scanRandMacAddress = true;
        powersave = false; # stabilite için kapalı (isteğe göre aç)
      };
      dns = "systemd-resolved"; # DNS’i resolved’a devret
    };

    # Mullvad’ın WireGuard tüneli için kernel modülü
    wireguard.enable = true;

    # VPN açık/kapalıya göre isim sunucuları
    # Mullvad AÇIKKEN statik nameserver YAZMIYORUZ → Mullvad kendi DNS’ini verir.
    nameservers = mkMerge [
      (mkIf (!hasMullvad) [
        "1.1.1.1"
        "1.0.0.1"
        "9.9.9.9"
      ])
      (mkIf hasMullvad [ ])
    ];

    # Firewall’u burada sadece açıyoruz; kurallar security/default.nix’te.
    firewall.enable = true;
  };

  ##############################################################################
  # Services
  ##############################################################################
  services = {
    # Modern DNS çözümleyici (VPN dostu)
    resolved = {
      enable = true;
      dnssec = "allow-downgrade"; # uyumluluk
      extraConfig = ''
        # Yerel multicast ve LLMNR kapalı (gerekmiyorsa kapatmak iyi pratik)
        LLMNR=no
        MulticastDNS=no
        # Önbellek açık, stub listener açık
        Cache=yes
        DNSStubListener=yes
        # Mullvad tünel içi DNS'te DoT gereksiz; çakışmayı önlemek için kapalı
        DNSOverTLS=no
        # resolved'ı varsayılan olarak işaretle
        Domains=~.
      '';
    };

    # Mullvad daemon + GUI
    mullvad-vpn = {
      enable = true;
      package = pkgs.mullvad-vpn;
    };
  };

  ##############################################################################
  # Ağ hazır bekleme (boot takozunu azaltmak için kapalı)
  ##############################################################################
  systemd.services."NetworkManager-wait-online".enable = false;

  ##############################################################################
  # Mullvad otomatizasyonu (race fix, socket polling)
  ##############################################################################
  systemd.services."mullvad-autoconnect" = {
    description = "Configure and connect Mullvad once daemon socket is ready";
    wantedBy = [ "multi-user.target" ];
    # network-online yerine daha erken: NM ve daemon geldikten sonra çalışır.
    after = [ "network.target" "NetworkManager.service" "mullvad-daemon.service" ];
    requires = [ "mullvad-daemon.service" ];
    wants = [ "NetworkManager.service" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = lib.getExe (pkgs.writeShellScriptBin "mullvad-autoconnect" ''
        set -euo pipefail

        CLI="${pkgs.mullvad-vpn}/bin/mullvad"

        # Daemon soketi hazır olana kadar bekle (max 30s)
        tries=0
        until "$CLI" status >/dev/null 2>&1; do
          tries=$((tries+1))
          if [ "$tries" -ge 30 ]; then
            printf 'mullvad-daemon socket not ready after %ss\n' "$tries" >&2
            exit 1
          fi
          sleep 1
        done

        # Güvenli varsayılanlar
        "$CLI" auto-connect set on || true
        "$CLI" dns set default --block-ads --block-trackers || true
        "$CLI" relay set location any || true

        # Bağlantı denemeleri (3 kez)
        for i in 1 2 3; do
          if "$CLI" connect; then
            exit 0
          fi
          sleep 2
        done

        # Olmadıysa, protokol/konumu gevşetip tekrar dene (isteğe bağlı)
        # "$CLI" relay set tunnel-protocol any || true
        # "$CLI" relay set location any || true
        "$CLI" connect || true

        exit 0
      '');
      RemainAfterExit = true;
    };
  };

  ##############################################################################
  # TCP/IP STACK — Sabit ve dinamik ayarlar (eski tcp/default.nix birleşti)
  ##############################################################################
  boot.kernel.sysctl = {
    # Kuyruk & tıkanıklık kontrolü
    "net.core.default_qdisc" = "fq";   # pacing için iyi; Wi-Fi’da BBR ile uyumlu
    "net.ipv4.tcp_congestion_control" = "bbr";

    # Ephemeral port aralığı (yoğun client iş yükleri için)
    "net.ipv4.ip_local_port_range" = "1024 65535";

    # Varsayılan buffer tavanları (std profil — high profil boot’ta override eder)
    "net.core.rmem_max"     = mkDefault std.rmem_max;
    "net.core.rmem_default" = mkDefault std.rmem_default;
    "net.core.wmem_max"     = mkDefault std.wmem_max;
    "net.core.wmem_default" = mkDefault std.wmem_default;

    # Aygıt backlog / scheduler bütçeleri
    "net.core.netdev_max_backlog" = mkDefault std.netdev_max_backlog;
    "net.core.netdev_budget"      = 300;
    # Ağ yoğunluğunda latency’i yumuşatır (opsiyonel iyileştirme)
    "net.core.netdev_budget_usecs" = 8000;

    # listen() backlog
    "net.core.somaxconn" = mkDefault std.somaxconn;

    # eBPF JIT hardening
    "net.core.bpf_jit_enable" = 1;
    "net.core.bpf_jit_harden" = 1;  # 1: hardened, 2: ek maliyetli

    # TCP Fast Open (client + server)
    "net.ipv4.tcp_fastopen" = 3;

    # TCP/UDP pencereleri & memory pressure
    "net.ipv4.tcp_rmem" = mkDefault std.rmem;
    "net.ipv4.tcp_wmem" = mkDefault std.wmem;
    "net.ipv4.tcp_mem"  = mkDefault std.tcp_mem;
    "net.ipv4.udp_mem"  = mkDefault std.udp_mem;

    # Seçmeli ACK
    "net.ipv4.tcp_dsack" = 1;

    # Gecikme/throughput dengesi:
    "net.ipv4.tcp_slow_start_after_idle" = 0;
    "net.ipv4.tcp_moderate_rcvbuf"       = 1;

    # Not-sent low water mark (büyük app bufferlarını sınırla)
    "net.ipv4.tcp_notsent_lowat" = 16384;

    # Path MTU probing
    "net.ipv4.tcp_mtu_probing" = 1;
    # Sürekli MTU/MSS problemi varsa aç (tünellerde):
    # "net.ipv4.tcp_base_mss"    = 1200;

    # Keepalive / FIN / TW
    "net.ipv4.tcp_keepalive_time"   = 300;
    "net.ipv4.tcp_keepalive_intvl"  = 30;
    "net.ipv4.tcp_keepalive_probes" = 3;
    "net.ipv4.tcp_fin_timeout"      = 30;
    "net.ipv4.tcp_max_tw_buckets"   = mkDefault std.tcp_max_tw_buckets;

    # Retrans & SYN
    "net.ipv4.tcp_retries2"       = 8;
    "net.ipv4.tcp_syn_retries"    = 3;
    "net.ipv4.tcp_synack_retries" = 3;

    # SYN/backlog korumaları
    "net.ipv4.tcp_syncookies"      = 1;
    "net.ipv4.tcp_max_syn_backlog" = mkDefault std.tcp_max_syn_backlog;

    # Reordering toleransı
    "net.ipv4.tcp_reordering" = 3;

    # ECN + fallback
    "net.ipv4.tcp_ecn"          = 1;
    "net.ipv4.tcp_ecn_fallback" = 1;

    # FRTO & RFC1337
    "net.ipv4.tcp_frto"    = 2;
    "net.ipv4.tcp_rfc1337" = 1;

    # rp_filter loose (VPN/tether dostu)
    "net.ipv4.conf.all.rp_filter"     = 2;
    "net.ipv4.conf.default.rp_filter" = 2;

    # ICMP redirects/source routes kapalı (hardening)
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

    # Conntrack (firewall varsa anlamlı)
    "net.netfilter.nf_conntrack_max"                         = mkDefault std.conntrack_max;
    "net.netfilter.nf_conntrack_tcp_timeout_established"     = 432000;  # 5 gün
    "net.netfilter.nf_conntrack_tcp_timeout_time_wait"       = 30;
    "net.netfilter.nf_conntrack_tcp_timeout_fin_wait"        = 30;
    "net.netfilter.nf_conntrack_generic_timeout"             = 600;
  };

  # RAM’e göre dinamik tavanlar (>=32GB ise high profil uygulansın)
  systemd.services.dynamic-tcp-tuning = {
    description = "Apply dynamic TCP tuning based on total system memory";
    wantedBy = [ "multi-user.target" ];
    # Ağ servislerinden ÖNCE çalışsın
    after  = [ "sysinit.target" ];
    before = [ "NetworkManager.service" "mullvad-daemon.service" ];
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

  # Teşhis yardımcıları
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
      echo "DNS:"
      ${pkgs.systemd}/bin/resolvectl dns | sed -n '1,80p'
      echo
      echo "Default route:"
      ${pkgs.iproute2}/bin/ip route show default
      echo
      echo "Connections:"
      echo -n "  TCP total:     "; ${pkgs.iproute2}/bin/ss -s | ${pkgs.gnugrep}/bin/grep -oP 'TCP:\s+\K\d+'
      echo -n "  TIME-WAIT:     "; ${pkgs.iproute2}/bin/ss -tan state time-wait | wc -l
    '')
  ];

  ##############################################################################
  # Shell alias’lar
  ##############################################################################
  environment.shellAliases = {
    # WiFi
    wifi-list = "nmcli device wifi list";
    wifi-connect = "nmcli device wifi connect";
    wifi-disconnect = "nmcli connection down";
    wifi-saved = "nmcli connection show";

    # Ağ
    net-status = "nmcli general status";
    net-connections = "nmcli connection show --active";

    # VPN
    vpn-status = "mullvad status";
    vpn-connect = "mullvad connect";
    vpn-disconnect = "mullvad disconnect";
    vpn-relay = "mullvad relay list";

    # DNS
    dns-test = "resolvectl status";
    dns-leak = "curl -s https://mullvad.net/en/check | sed -n '1,120p'";
  };
}
