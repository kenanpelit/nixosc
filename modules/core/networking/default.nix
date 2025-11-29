# modules/core/networking/default.nix
# ==============================================================================
# Networking & TCP/IP Stack Configuration - Production Grade
# ==============================================================================
#
# Module:      modules/core/networking
# Purpose:     Network management, VPN, TCP optimization, DNS configuration
# Author:      Kenan Pelit
# Created:     2025-10-09
# Modified:    2025-11-15
#
# Architecture:
#   NetworkManager → systemd-resolved → VPN (Mullvad/WireGuard) → TCP Stack
#        ↓                 ↓                    ↓                      ↓
#   WiFi/Ethernet      DNS Cache          Encrypted Tunnel       BBR+FQ+ECN
#
# TCP Tuning Philosophy:
#   Three-tier adaptive tuning based on available system memory:
#   • ULTRA (≥60GB RAM): E14 Gen 6 (Core Ultra 7 155H, 64GB)
#     - 64MB buffers, 32k backlog, 1M conntrack
#     - High-throughput workloads, VMs, containers
#
#   • HIGH (32-59GB RAM): Reserved for future mid-tier systems
#     - 32MB buffers, 16k backlog, 524k conntrack
#     - Balanced performance
#
#   • STANDARD (<32GB RAM): X1 Carbon Gen 6 (i7-8650U, 16GB)
#     - 16MB buffers, 5k backlog, 262k conntrack
#     - Daily driver, power-efficient
#
# Key Features:
#   ✓ Dynamic TCP tuning (memory-aware profiles)
#   ✓ BBR congestion control + FQ qdisc
#   ✓ Mullvad VPN with killswitch support
#   ✓ systemd-resolved (DNSSEC, cache, per-link DNS)
#   ✓ NetworkManager (WiFi, Ethernet, VPN integration)
#   ✓ IPv6 enabled with privacy extensions
#   ✓ Comprehensive diagnostic tools
#
# Design Principles:
#   • Performance  – Modern congestion control, optimized buffers
#   • Security     – Hardened IP stack, MAC randomization, VPN killswitch
#   • Reliability  – Systemd-native, robust error handling
#   • Observability– Rich diagnostics and monitoring
#
# ==============================================================================

{ config, lib, pkgs, host ? "", isPhysicalHost ? false, isVirtualHost ? false, ... }:

let
  inherit (lib) mkIf mkMerge mkDefault mkForce;
  toString = builtins.toString;

  # ----------------------------------------------------------------------------
  # VPN State Detection
  # ----------------------------------------------------------------------------
  hasMullvad = config.services.mullvad-vpn.enable or false;

  # Single Mullvad package reference (CLI + service)
  mullvadPkg = pkgs.mullvad;

  # ----------------------------------------------------------------------------
  # TCP Profile Parameters (Three-Tier System)
  # ----------------------------------------------------------------------------
  # Buffer sizes in "min default max" format
  # Memory pools in pages (4KB each)
  # Thresholds account for iGPU shared memory on E14 Gen 6

  ultra = {
    # Buffer Configuration (64MB max for high-throughput)
    rmem               = "4096 1048576 67108864";   # RX: 4KB / 1MB / 64MB
    wmem               = "4096 1048576 67108864";   # TX: 4KB / 1MB / 64MB
    rmem_max           = 67108864;                  # 64MB max receive buffer
    wmem_max           = 67108864;                  # 64MB max send buffer
    rmem_default       = 2097152;                   # 2MB default RX
    wmem_default       = 2097152;                   # 2MB default TX

    # Queue Configuration
    netdev_max_backlog = 32000;                     # RX queue size (packets)
    somaxconn          = 8192;                      # Listen backlog
    tcp_max_syn_backlog = 16384;                    # SYN backlog
    tcp_max_tw_buckets  = 4000000;                  # TIME-WAIT sockets

    # Memory Pools (pages, 4KB)
    tcp_mem            = "3145728 4194304 6291456"; # TCP: 12GB/16GB/24GB
    udp_mem            = "1572864 2097152 3145728"; # UDP: 6GB/8GB/12GB

    # Connection Tracking
    conntrack_max      = 1048576;                   # 1M tracked connections
  };

  high = {
    rmem               = "4096 524288 33554432";    # RX: 32MB max
    wmem               = "4096 524288 33554432";    # TX: 32MB max
    rmem_max           = 33554432;
    wmem_max           = 33554432;
    rmem_default       = 1048576;                   # 1MB default
    wmem_default       = 1048576;
    netdev_max_backlog = 16000;
    somaxconn          = 4096;
    tcp_max_syn_backlog = 8192;
    tcp_max_tw_buckets  = 2000000;
    tcp_mem            = "1572864 2097152 3145728"; # TCP: 6GB/8GB/12GB
    udp_mem            = "786432 1048576 1572864";  # UDP: 3GB/4GB/6GB
    conntrack_max      = 524288;
  };

  std = {
    rmem               = "4096 262144 16777216";    # RX: 16MB max
    wmem               = "4096 262144 16777216";    # TX: 16MB max
    rmem_max           = 16777216;
    wmem_max           = 16777216;
    rmem_default       = 524288;                    # 512KB default
    wmem_default       = 524288;
    netdev_max_backlog = 5000;
    somaxconn          = 1024;
    tcp_max_syn_backlog = 2048;
    tcp_max_tw_buckets  = 1000000;
    tcp_mem            = "786432 1048576 1572864";  # TCP: 3GB/4GB/6GB
    udp_mem            = "393216 524288 786432";    # UDP: 1.5GB/2GB/3GB
    conntrack_max      = 262144;
  };

  # ----------------------------------------------------------------------------
  # Tool Paths (Stable References)
  # ----------------------------------------------------------------------------
  awk    = "${pkgs.gawk}/bin/awk";
  grep   = "${pkgs.gnugrep}/bin/grep";
  sysctl = "${pkgs.procps}/bin/sysctl";
  cat    = "${pkgs.coreutils}/bin/cat";
  mkdir  = "${pkgs.coreutils}/bin/mkdir";
  bash   = "${pkgs.bash}/bin/bash";

  # ----------------------------------------------------------------------------
  # Memory Detection Script
  # ----------------------------------------------------------------------------
  detectMemoryScript = pkgs.writeShellScript "detect-memory" ''
    #!${bash}
    set -euo pipefail
    TOTAL_KB=$(${grep} "^MemTotal:" /proc/meminfo | ${awk} '{print $2}')
    echo $((TOTAL_KB / 1024))
  '';

  # ----------------------------------------------------------------------------
  # Profile Detection & Caching Script
  # ----------------------------------------------------------------------------
  detectAndCacheProfile = pkgs.writeShellScript "detect-and-cache-profile" ''
    #!${bash}
    set -euo pipefail

    CACHE_FILE="/run/network-tuning-profile"
    ${mkdir} -p "$(dirname "$CACHE_FILE")"

    TOTAL_MB=$(${detectMemoryScript})
    TOTAL_GB=$((TOTAL_MB / 1024))

    if [[ "$TOTAL_MB" -ge 61440 ]]; then
      # ≥60GB: ULTRA profile (E14 Gen 6)
      echo "ultra" > "$CACHE_FILE"
      echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
      echo "[TCP] Detected ''${TOTAL_GB}GB RAM → ULTRA performance profile"
      echo "[TCP] Target: E14 Gen 6 (Core Ultra 7 155H)"
      echo "[TCP] Config: 64MB buffers, 32k backlog, 1M conntrack"
      echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    elif [[ "$TOTAL_MB" -ge 32768 ]]; then
      # 32-59GB: HIGH profile
      echo "high" > "$CACHE_FILE"
      echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
      echo "[TCP] Detected ''${TOTAL_GB}GB RAM → HIGH performance profile"
      echo "[TCP] Config: 32MB buffers, 16k backlog, 524k conntrack"
      echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    else
      # <32GB: STANDARD profile (X1 Carbon Gen 6)
      echo "std" > "$CACHE_FILE"
      echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
      echo "[TCP] Detected ''${TOTAL_GB}GB RAM → STANDARD profile"
      echo "[TCP] Target: X1 Carbon Gen 6 (i7-8650U)"
      echo "[TCP] Config: 16MB buffers, 5k backlog, 262k conntrack"
      echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    fi
  '';

  # ----------------------------------------------------------------------------
  # SQM/CAKE — WAN + VPN Aware (script & knobs)
  # ----------------------------------------------------------------------------
  sqm = rec {
    # ---- Bandwidths (~85–90% of speedtest) ----
    uploadBandwidth      = "15mbit";   # WAN upstream
    downloadBandwidth    = "50mbit";   # WAN downstream
    enableNatOnWAN       = true;

    vpnUploadBandwidth   = "15mbit";   # VPN upstream
    vpnDownloadBandwidth = "50mbit";   # VPN downstream
    enableNatOnVPN       = false;

    sqmScript = pkgs.writeShellScript "setup-sqm-cake" ''
      #!${bash}
      set -euo pipefail

      # ===== Config from Nix =====
      WAN_UP="${uploadBandwidth}"
      WAN_DOWN="${downloadBandwidth}"
      WAN_NAT="${if enableNatOnWAN then "1" else "0"}"

      VPN_UP="${vpnUploadBandwidth}"
      VPN_DOWN="${vpnDownloadBandwidth}"
      VPN_NAT="${if enableNatOnVPN then "1" else "0"}"

      # ===== Binaries =====
      IP="${pkgs.iproute2}/bin/ip"
      TC="${pkgs.iproute2}/bin/tc"
      GREP="${pkgs.gnugrep}/bin/grep"
      AWK="${pkgs.gawk}/bin/awk"
      MODPROBE="${pkgs.kmod}/bin/modprobe"
      LSMOD="${pkgs.kmod}/bin/lsmod"
      SED="${pkgs.gnused}/bin/sed"
      SORT="${pkgs.coreutils}/bin/sort"
      TR="${pkgs.coreutils}/bin/tr"

      log()   { echo "[$(${pkgs.coreutils}/bin/date '+%Y-%m-%d %H:%M:%S')] $*"; }
      error() { echo "[$(${pkgs.coreutils}/bin/date '+%Y-%m-%d %H:%M:%S')] ERROR: $*" >&2; }

      # ===== Detectors =====
      detect_default_iface() {
        ''${IP} route show default 2>/dev/null | ''${AWK} '/default/ {print $5; exit}'
      }

      detect_vpn_ifaces() {
        ''${IP} -o link show | ''${AWK} -F': ' '{print $2}' \
          | ''${GREP} -E '^(wg|tun)[0-9A-Za-z._-]*$' -h || true
      }

      is_up() {
        ''${IP} -o link show "$1" 2>/dev/null | ''${GREP} -q '<[^>]*UP[^>]*>'
      }

      # ===== Kernel modules =====
      load_modules() {
        log "Loading kernel modules..."
        ''${LSMOD} | ''${GREP} -q sch_cake || ''${MODPROBE} sch_cake || { error "Failed to load sch_cake"; return 1; }
        ''${LSMOD} | ''${GREP} -q '\<ifb\>'   || ''${MODPROBE} ifb      || { error "Failed to load ifb"; return 1; }
        log "Kernel modules loaded"
      }

      # ===== Robust waits =====
      wait_for_tc_ready() {
        local tries=5
        while [ $tries -gt 0 ]; do
          if ''${TC} qdisc show dev lo >/dev/null 2>&1; then
            return 0
          fi
          sleep 1
          tries=$((tries-1))
        done
        return 1
      }

      wait_for_default_iface() {
        local tries=30
        while [ $tries -gt 0 ]; do
          local def
          def="$(detect_default_iface || true)"
          if [ -n "''${def:-}" ] && is_up "$def"; then
            echo "$def"; return 0
          fi
          sleep 1
          tries=$((tries-1))
        done
        return 1
      }

      # ===== Helpers =====
      ifb_name_for() {
        echo "ifb-$1" | ''${TR} -c '[:alnum:]._-' '-' | ''${SED} 's/-\{2,\}/-/g'
      }

      clean_iface() {
        local iface="$1" ifb
        ifb="$(ifb_name_for "$iface")"
        log "Cleaning qdiscs for $iface (and $ifb)..."
        ''${TC} qdisc del dev "$iface" root    2>/dev/null || true
        ''${TC} qdisc del dev "$iface" ingress 2>/dev/null || true
        ''${TC} qdisc del dev "$ifb"   root    2>/dev/null || true
        ''${IP} link set dev "$ifb" down 2>/dev/null || true
        ''${IP} link del "$ifb" type ifb 2>/dev/null || true
      }

      setup_egress() {
        local iface="$1" bw="$2" use_nat="$3"
        log "[$iface] Egress CAKE: $bw  nat=$([ "$use_nat" = "1" ] && echo on || echo off)"
        local -a CAKE_OPTS
        CAKE_OPTS=(bandwidth "$bw" diffserv4 triple-isolate wash ack-filter memlimit 32Mb)
        if [ "$use_nat" = "1" ]; then CAKE_OPTS+=(nat); fi
        ''${TC} qdisc add dev "$iface" root cake "''${CAKE_OPTS[@]}"
      }

      setup_ingress_on_iface() {
        local iface="$1" bw="$2" use_nat="$3"
        local ifb; ifb="$(ifb_name_for "$iface")"
        log "[$iface] Ingress via $ifb: $bw  nat=$([ "$use_nat" = "1" ] && echo on || echo off)"
        ''${IP} link add "$ifb" type ifb 2>/dev/null || true
        ''${IP} link set dev "$ifb" up
        ''${TC} qdisc add dev "$iface" handle ffff: ingress 2>/dev/null || true
        ''${TC} filter add dev "$iface" parent ffff: protocol all prio 10 u32 match u32 0 0 \
          action mirred egress redirect dev "$ifb"
        local -a CAKE_OPTS
        CAKE_OPTS=(bandwidth "$bw" diffserv4 triple-isolate wash ingress memlimit 32Mb)
        if [ "$use_nat" = "1" ]; then CAKE_OPTS+=(nat); fi
        ''${TC} qdisc add dev "$ifb" root cake "''${CAKE_OPTS[@]}"
      }

      verify_pair() {
        local iface="$1" ifb; ifb="$(ifb_name_for "$iface")"
        ''${TC} qdisc show dev "$iface" | ''${GREP} -q "qdisc cake"    || { error "[$iface] Egress CAKE missing"; return 1; }
        ''${TC} qdisc show dev "$iface" | ''${GREP} -q "qdisc ingress" || { error "[$iface] Ingress qdisc missing"; return 1; }
        ''${TC} qdisc show dev "$ifb"   | ''${GREP} -q "qdisc cake"    || { error "[$iface] IFB ($ifb) CAKE missing"; return 1; }
        log "[$iface] Verified (egress+ingress)"
      }

      verify_ingress_only() {
        local iface="$1" ifb; ifb="$(ifb_name_for "$iface")"
        ''${TC} qdisc show dev "$iface" | ''${GREP} -q "qdisc ingress" || { error "[$iface] Ingress qdisc missing"; return 1; }
        ''${TC} qdisc show dev "$ifb"   | ''${GREP} -q "qdisc cake"    || { error "[$iface] IFB ($ifb) CAKE missing"; return 1; }
        log "[$iface] Verified (ingress-only)"
      }

      verify_egress_only() {
        local iface="$1"
        ''${TC} qdisc show dev "$iface" | ''${GREP} -q "qdisc cake" || { error "[$iface] Egress CAKE missing"; return 1; }
        log "[$iface] Verified (egress-only)"
      }

      setup_all() {
        log "Starting SQM/CAKE setup..."
        load_modules
        wait_for_tc_ready || { error "tc not ready"; exit 1; }

        local def; def="$(wait_for_default_iface || true)"
        [ -n "$def" ] || { error "No default interface (route not up)"; exit 1; }

        local vpns; vpns="$(detect_vpn_ifaces || true)"
        local vpn_up_any=0
        for v in $vpns; do
          if is_up "$v"; then vpn_up_any=1; break; fi
        done

        if [ "$vpn_up_any" -eq 1 ]; then
          log "Mode: VPN (egress on wg*/tun*, ingress on $def)"
          clean_iface "$def"
          for v in $vpns; do
            is_up "$v" || continue
            clean_iface "$v"
            setup_egress "$v" "$VPN_UP" "$VPN_NAT"
            verify_egress_only "$v"
          done
          setup_ingress_on_iface "$def" "$VPN_DOWN" "$VPN_NAT"
          verify_ingress_only "$def"
        else
          log "Mode: WAN (egress+ingress on $def)"
          clean_iface "$def"
          setup_egress "$def" "$WAN_UP" "$WAN_NAT"
          setup_ingress_on_iface "$def" "$WAN_DOWN" "$WAN_NAT"
          verify_pair "$def"
        fi

        log "All done."
      }

      cleanup_all() {
        log "Cleaning up all SQM configuration..."
        local def; def="$(detect_default_iface || true)"
        if [ -n "$def" ]; then clean_iface "$def"; fi

        local vpns; vpns="$(detect_vpn_ifaces || true)"
        for v in $vpns; do clean_iface "$v"; done

        # leftover ifb-*
        ''${IP} -o link show | ''${AWK} -F': ' '{print $2}' | ''${GREP} -E '^ifb-' | while read -r ifb; do
          ''${TC} qdisc del dev "$ifb" root 2>/dev/null || true
          ''${IP} link set dev "$ifb" down 2>/dev/null || true
          ''${IP} link del "$ifb" type ifb 2>/dev/null || true
        done
        log "Cleanup completed."
      }

      case "''${1:-setup}" in
        setup)   setup_all   ;;
        cleanup) cleanup_all ;;
        *) echo "Usage: $0 {setup|cleanup}"; exit 1 ;;
      esac
    '';
  };

in
{
  # ============================================================================
  # Base Networking Configuration (Layer 1: Foundation)
  # ============================================================================

  networking = {
    hostName = host;

    # Firewall: default on, security module may override with nftables
    firewall.enable = mkDefault true;

    # IPv6
    enableIPv6 = mkDefault true;
    tempAddresses = mkDefault "default";

    # WiFi handled by NetworkManager, not wireless.*
    wireless.enable = false;

    # --------------------------------------------------------------------------
    # NetworkManager
    # --------------------------------------------------------------------------
    networkmanager = {
      enable = true;

      wifi = {
        backend = "wpa_supplicant";
        scanRandMacAddress = true;
        powersave = false;
        macAddress = "preserve";
      };

      dns = "systemd-resolved";
      ethernet.macAddress = "preserve";

      settings = {
        connection."connection.autoconnect-retries" = 0;

        ipv6."ipv6.ip6-privacy" = 2;
      };
    };

    # WireGuard kernel support (for Mullvad, etc.)
    wireguard.enable = true;

    # --------------------------------------------------------------------------
    # DNS (Name Resolution)
    # --------------------------------------------------------------------------
    nameservers = mkMerge [
      (mkIf (!hasMullvad) [
        # Cloudflare
        "1.1.1.1"
        "1.0.0.1"
        "2606:4700:4700::1111"
        "2606:4700:4700::1001"

        # Quad9
        "9.9.9.9"
        "2620:fe::fe"
      ])
      (mkIf hasMullvad [ ])
    ];
  };

  # ============================================================================
  # System Services (Layer 3: DNS & VPN)
  # ============================================================================

  services = {
    # --------------------------------------------------------------------------
    # systemd-resolved
    # --------------------------------------------------------------------------
    resolved = {
      enable = true;
      dnssec = "allow-downgrade";
      fallbackDns = [ "1.1.1.1" "9.9.9.9" ];
      extraConfig = ''
        LLMNR=no
        MulticastDNS=no

        Cache=yes
        CacheFromLocalhost=no

        DNSStubListener=yes
        DNSStubListenerExtra=127.0.0.54

        DNSOverTLS=no

        Domains=~.
      '';
    };

    # --------------------------------------------------------------------------
    # Mullvad VPN
    # --------------------------------------------------------------------------
    mullvad-vpn = mkIf isPhysicalHost {
      enable = true;
      package = mullvadPkg;
      enableExcludeWrapper = true;
    };
  };

  # ============================================================================
  # Mullvad Daemon Log Optimization
  # ============================================================================

  systemd.services.mullvad-daemon = {
    serviceConfig = {
      StandardOutput = "journal";
      StandardError  = "journal";

      # 6 = info
      LogLevelMax = "6";
      SyslogLevel = "info";
      SyslogLevelPrefix = false;

      LogRateLimitIntervalSec = "10s";
      LogRateLimitBurst = 10;
    };
  };

  # ============================================================================
  # Systemd Services (Layer 4: Service Orchestration)
  # ============================================================================

  # NetworkManager-wait-online slows boot, not needed for desktop
  systemd.services."NetworkManager-wait-online".enable = false;

  # Network Profile Detection Service
  systemd.services."network-profile-detect" = {
    description = "Detect and cache network tuning profile based on system memory";
    wantedBy = [ "sysinit.target" ];
    before = [ "network-pre.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = detectAndCacheProfile;
    };
  };

  # Dynamic TCP Tuning Service (actually applies sysctl based on profile)
  systemd.services."network-tcp-tuning" = {
    description = "Apply dynamic TCP/IP stack tuning based on system profile";

    # Boot sonrası otomatik çalışsın
    wantedBy = [ "multi-user.target" ];

    # Sıralama:
    #  - Önce profil tespiti
    #  - Ağ gerçekten online olsun
    #  - Firewall / nftables muhtemelen nf_conntrack modülünü yüklemiş olsun
    after = [
      "network-profile-detect.service"
      "network-online.target"
      "nftables.service"
      "firewall.service"
    ];

    # network-online hedefini iste ama ona bağımlı olma
    wants = [ "network-online.target" ];

    # Profile detection’a gerçekten bağımlıyız
    requires = [ "network-profile-detect.service" ];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;

      ExecStart = pkgs.writeShellScript "apply-tcp-tuning" ''
        #!${bash}
        set -euo pipefail

        CACHE_FILE="/run/network-tuning-profile"

        # Profil cache yoksa burada da oluştur (boot race durumlarına karşı)
        if [[ ! -f "$CACHE_FILE" ]]; then
          echo "[TCP] Profile cache missing, running detection..."
          ${detectAndCacheProfile}
        fi

        PROFILE="$(${cat} "$CACHE_FILE" 2>/dev/null || echo std)"

        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "[TCP] Applying ''${PROFILE} performance profile"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

        # Güvenli sysctl helper: key yoksa atla, fail etme
        apply_sysctl() {
          local key="$1"
          local val="$2"
          local path="/proc/sys/''${key//./\/}"

          if [[ -e "$path" ]]; then
            ${sysctl} -w "$key=$val" >/dev/null
          else
            echo "[TCP] Skipping $key (no /proc/sys entry)"
          fi
        }

        case "$PROFILE" in
          ultra)
            apply_sysctl net.core.rmem_max     ${toString ultra.rmem_max}
            apply_sysctl net.core.wmem_max     ${toString ultra.wmem_max}
            apply_sysctl net.core.rmem_default ${toString ultra.rmem_default}
            apply_sysctl net.core.wmem_default ${toString ultra.wmem_default}

            apply_sysctl net.core.netdev_max_backlog ${toString ultra.netdev_max_backlog}
            apply_sysctl net.core.somaxconn          ${toString ultra.somaxconn}

            apply_sysctl net.ipv4.tcp_max_syn_backlog ${toString ultra.tcp_max_syn_backlog}
            apply_sysctl net.ipv4.tcp_max_tw_buckets  ${toString ultra.tcp_max_tw_buckets}

            apply_sysctl net.ipv4.tcp_rmem "${ultra.rmem}"
            apply_sysctl net.ipv4.tcp_wmem "${ultra.wmem}"
            apply_sysctl net.ipv4.tcp_mem  "${ultra.tcp_mem}"
            apply_sysctl net.ipv4.udp_mem  "${ultra.udp_mem}"

            apply_sysctl net.netfilter.nf_conntrack_max ${toString ultra.conntrack_max}
            ;;

          high)
            apply_sysctl net.core.rmem_max     ${toString high.rmem_max}
            apply_sysctl net.core.wmem_max     ${toString high.wmem_max}
            apply_sysctl net.core.rmem_default ${toString high.rmem_default}
            apply_sysctl net.core.wmem_default ${toString high.wmem_default}

            apply_sysctl net.core.netdev_max_backlog ${toString high.netdev_max_backlog}
            apply_sysctl net.core.somaxconn          ${toString high.somaxconn}

            apply_sysctl net.ipv4.tcp_max_syn_backlog ${toString high.tcp_max_syn_backlog}
            apply_sysctl net.ipv4.tcp_max_tw_buckets  ${toString high.tcp_max_tw_buckets}

            apply_sysctl net.ipv4.tcp_rmem "${high.rmem}"
            apply_sysctl net.ipv4.tcp_wmem "${high.wmem}"
            apply_sysctl net.ipv4.tcp_mem  "${high.tcp_mem}"
            apply_sysctl net.ipv4.udp_mem  "${high.udp_mem}"

            apply_sysctl net.netfilter.nf_conntrack_max ${toString high.conntrack_max}
            ;;

          std|*)
            apply_sysctl net.core.rmem_max     ${toString std.rmem_max}
            apply_sysctl net.core.wmem_max     ${toString std.wmem_max}
            apply_sysctl net.core.rmem_default ${toString std.rmem_default}
            apply_sysctl net.core.wmem_default ${toString std.wmem_default}

            apply_sysctl net.core.netdev_max_backlog ${toString std.netdev_max_backlog}
            apply_sysctl net.core.somaxconn          ${toString std.somaxconn}

            apply_sysctl net.ipv4.tcp_max_syn_backlog ${toString std.tcp_max_syn_backlog}
            apply_sysctl net.ipv4.tcp_max_tw_buckets  ${toString std.tcp_max_tw_buckets}

            apply_sysctl net.ipv4.tcp_rmem "${std.rmem}"
            apply_sysctl net.ipv4.tcp_wmem "${std.wmem}"
            apply_sysctl net.ipv4.tcp_mem  "${std.tcp_mem}"
            apply_sysctl net.ipv4.udp_mem  "${std.udp_mem}"

            apply_sysctl net.netfilter.nf_conntrack_max ${toString std.conntrack_max}
            ;;
        esac

        echo "[TCP] Tuning applied successfully."
      '';
    };
  };

  # Mullvad Auto-Connect Service
  systemd.services."mullvad-autoconnect" = mkIf hasMullvad {
    description = "Configure and auto-connect Mullvad VPN on boot";

    wantedBy = [ ];
    after = [
      "network-online.target"
      "NetworkManager.service"
      "mullvad-daemon.service"
    ];
    requires = [ "mullvad-daemon.service" ];
    wants = [ "network-online.target" ];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      Restart = "on-failure";
      RestartSec = "10s";

      ExecStart = lib.getExe (pkgs.writeShellScriptBin "mullvad-autoconnect" ''
        #!${bash}
        set -euo pipefail

        CLI="${mullvadPkg}/bin/mullvad"
        MAX_WAIT=30

        echo "[Mullvad] Waiting for daemon..."
        for i in $(seq 1 $MAX_WAIT); do
          if "$CLI" status >/dev/null 2>&1; then
            echo "[Mullvad] ✓ Daemon ready after ''${i}s"
            break
          fi

          if [[ "$i" -eq "$MAX_WAIT" ]]; then
            echo "[Mullvad] ✗ Timeout after ''${MAX_WAIT}s"
            exit 1
          fi
          sleep 1
        done

        echo "[Mullvad] Configuring..."
        "$CLI" auto-connect set on || echo "[Mullvad] ⚠ Auto-connect failed"
        "$CLI" dns set default --block-ads --block-trackers || echo "[Mullvad] ⚠ DNS config failed"
        # "$CLI" lockdown-mode set on || echo "[Mullvad] ⚠ Lockdown failed"

        echo "[Mullvad] Connecting..."
        if "$CLI" connect; then
          echo "[Mullvad] ✓ Connected"
          exit 0
        fi

        echo "[Mullvad] ✗ Connection failed, will retry in 10s..."
        exit 1
      '');
    };
  };

  # ============================================================================
  # TCP/IP Stack Kernel Parameters (Layer 5: Baseline Tuning)
  # ============================================================================

  boot.kernel.sysctl = {
    # Congestion control & qdisc
    "net.core.default_qdisc" = "fq";
    "net.ipv4.tcp_congestion_control" = "bbr";

    # Ephemeral port range
    "net.ipv4.ip_local_port_range" = "1024 65535";

    # Buffer defaults (STANDARD profile; overridden by dynamic tuning)
    "net.core.rmem_max"     = mkDefault std.rmem_max;
    "net.core.rmem_default" = mkDefault std.rmem_default;
    "net.core.wmem_max"     = mkDefault std.wmem_max;
    "net.core.wmem_default" = mkDefault std.wmem_default;

    "net.core.netdev_max_backlog" = mkDefault std.netdev_max_backlog;
    "net.core.netdev_budget" = 300;
    "net.core.netdev_budget_usecs" = 8000;
    "net.core.somaxconn" = mkDefault std.somaxconn;

    # eBPF
    "net.core.bpf_jit_enable" = 1;
    "net.core.bpf_jit_harden" = 1;

    # TCP features
    "net.ipv4.tcp_fastopen" = 3;
    "net.ipv4.tcp_dsack" = 1;
    "net.ipv4.tcp_slow_start_after_idle" = 0;
    "net.ipv4.tcp_moderate_rcvbuf" = 1;
    "net.ipv4.tcp_notsent_lowat" = 16384;

    # MTU / PMTUD
    "net.ipv4.tcp_mtu_probing" = 1;

    # TCP memory baseline
    "net.ipv4.tcp_rmem" = mkDefault std.rmem;
    "net.ipv4.tcp_wmem" = mkDefault std.wmem;
    "net.ipv4.tcp_mem"  = mkDefault std.tcp_mem;
    "net.ipv4.udp_mem"  = mkDefault std.udp_mem;

    # Keepalive
    "net.ipv4.tcp_keepalive_time"   = 300;
    "net.ipv4.tcp_keepalive_intvl"  = 30;
    "net.ipv4.tcp_keepalive_probes" = 3;
    "net.ipv4.tcp_fin_timeout"      = 60;

    # TIME-WAIT
    "net.ipv4.tcp_max_tw_buckets" = mkDefault std.tcp_max_tw_buckets;
    "net.ipv4.tcp_tw_reuse" = 1;

    # Retries
    "net.ipv4.tcp_retries2"       = 8;
    "net.ipv4.tcp_syn_retries"    = 3;
    "net.ipv4.tcp_synack_retries" = 3;

    # SYN flood
    "net.ipv4.tcp_syncookies" = 1;
    "net.ipv4.tcp_max_syn_backlog" = mkDefault std.tcp_max_syn_backlog;

    # Advanced TCP
    "net.ipv4.tcp_reordering" = 3;
    "net.ipv4.tcp_ecn" = 1;
    "net.ipv4.tcp_ecn_fallback" = 1;
    "net.ipv4.tcp_frto" = 2;
    "net.ipv4.tcp_rfc1337" = 1;
    "net.ipv4.tcp_timestamps" = 1;
    "net.ipv4.tcp_sack" = 1;

    # IPv4 hardening
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

    # IPv6
    "net.ipv6.conf.all.accept_redirects"     = 0;
    "net.ipv6.conf.default.accept_redirects" = 0;
    "net.ipv6.conf.all.accept_source_route"  = 0;
    "net.ipv6.conf.all.accept_ra"            = 0;
    "net.ipv6.conf.default.accept_ra"        = 0;

    # Conntrack
    "net.netfilter.nf_conntrack_max" = mkDefault std.conntrack_max;
    "net.netfilter.nf_conntrack_tcp_timeout_established" = 432000;
    "net.netfilter.nf_conntrack_tcp_timeout_time_wait"   = 30;
    "net.netfilter.nf_conntrack_tcp_timeout_close_wait"  = 30;
    "net.netfilter.nf_conntrack_tcp_timeout_fin_wait"    = 30;
    "net.netfilter.nf_conntrack_udp_timeout"             = 60;
    "net.netfilter.nf_conntrack_generic_timeout"         = 600;
    "net.netfilter.nf_conntrack_helper" = 0;

    # Window scaling
    "net.ipv4.tcp_window_scaling" = 1;

    # ARP cache
    "net.ipv4.neigh.default.gc_thresh1" = 4096;
    "net.ipv4.neigh.default.gc_thresh2" = 8192;
    "net.ipv4.neigh.default.gc_thresh3" = 16384;
    "net.ipv4.neigh.default.gc_stale_time" = 120;

    # Route cache
    "net.ipv4.route.gc_timeout" = 100;
  };

  # ============================================================================
  # Kernel Modules (Layer 6: Required Modules)
  # ============================================================================

  boot.kernelModules = [
    "tcp_bbr"
    "sch_fq"
    "wireguard"
    "sch_cake"
    "ifb"
  ];

  # ============================================================================
  # Diagnostic Tools & Utilities (Layer 7: Observability)
  # ============================================================================

  environment.systemPackages = with pkgs; [
    iproute2
    iputils
    bind
    mtr
    tcpdump
    ethtool

    iperf3
    speedtest-cli

    doggo
    nethogs
    iftop
    nload

    (pkgs.writeShellScriptBin "tcp-status" ''
      #!${bash}
      set -euo pipefail

      BOLD='\033[1m'
      GREEN='\033[0;32m'
      BLUE='\033[0;34m'
      YELLOW='\033[0;33m'
      NC='\033[0m'

      printf "%b=== TCP/IP Stack Status ===%b\n\n" "$BOLD" "$NC"

      printf "%b[System]%b\n" "$BLUE" "$NC"
      TOTAL_MB=$(${detectMemoryScript})
      TOTAL_GB=$((TOTAL_MB / 1024))
      printf "  RAM: %sGB (%sMB)\n" "$TOTAL_GB" "$TOTAL_MB"

      if [[ -f /run/network-tuning-profile ]]; then
        PROFILE=$(${cat} /run/network-tuning-profile)
        printf "  Profile: %b%s%b\n\n" "$GREEN" "''${PROFILE^^}" "$NC"
      else
        printf "  Profile: unknown\n\n"
      fi

      printf "%b[TCP Configuration]%b\n" "$BLUE" "$NC"
      CC=$(${sysctl} -n net.ipv4.tcp_congestion_control)
      QDISC=$(${sysctl} -n net.core.default_qdisc)
      printf "  Congestion Control: %b%s%b\n" "$GREEN" "$CC" "$NC"
      printf "  Queue Discipline:   %b%s%b\n" "$GREEN" "$QDISC" "$NC"

      if [[ -f /sys/module/tcp_bbr/version ]]; then
        BBR_VER=$(${cat} /sys/module/tcp_bbr/version)
        printf "  BBR Version:        %s\n" "$BBR_VER"
      fi

      TFO=$(${sysctl} -n net.ipv4.tcp_fastopen)
      ECN=$(${sysctl} -n net.ipv4.tcp_ecn)
      printf "  TCP Fast Open:      %s\n" "$TFO"
      printf "  ECN:                %s\n\n" "$ECN"

      printf "%b[Buffers]%b\n" "$BLUE" "$NC"
      RMEM_MAX=$(${sysctl} -n net.core.rmem_max)
      WMEM_MAX=$(${sysctl} -n net.core.wmem_max)
      printf "  rmem_max: %s (%s bytes)\n" "$(numfmt --to=iec "$RMEM_MAX")" "$RMEM_MAX"
      printf "  wmem_max: %s (%s bytes)\n\n" "$(numfmt --to=iec "$WMEM_MAX")" "$WMEM_MAX"

      printf "%b[Interfaces]%b\n" "$BLUE" "$NC"
      ${pkgs.iproute2}/bin/ip -br link | while read -r iface state rest; do
        case "$state" in
          UP) printf "  %b%-18s%b %s\n" "$GREEN" "$iface" "$NC" "$rest" ;;
          *)  printf "  %-18s %s\n" "$iface" "$rest" ;;
        esac
      done
      printf "\n"

      printf "%b[Connections]%b\n" "$BLUE" "$NC"
      TCP_ESTAB=$(${pkgs.iproute2}/bin/ss -tan state established 2>/dev/null | tail -n +2 | wc -l)
      TCP_TW=$(${pkgs.iproute2}/bin/ss -tan state time-wait 2>/dev/null | tail -n +2 | wc -l)
      printf "  TCP Established: %s\n" "$TCP_ESTAB"
      printf "  TCP TIME-WAIT:   %s\n\n" "$TCP_TW"

      if command -v mullvad &>/dev/null; then
        printf "%b[VPN]%b\n" "$BLUE" "$NC"
        mullvad status | sed 's/^/  /'
        printf "\n"
      fi

      printf "%b✓ Status check complete%b\n" "$GREEN" "$NC"
    '')

    (pkgs.writeShellScriptBin "net-test" ''
      #!${bash}
      set -euo pipefail

      echo "=== Network Performance Test ==="
      echo

      echo "[Latency]"
      echo -n "  Google (8.8.8.8): "
      ${pkgs.iputils}/bin/ping -c 5 -q 8.8.8.8 2>/dev/null | ${grep} "rtt" | ${awk} -F'/' '{print $5 "ms"}' || echo "FAILED"

      echo -n "  Cloudflare (1.1.1.1): "
      ${pkgs.iputils}/bin/ping -c 5 -q 1.1.1.1 2>/dev/null | ${grep} "rtt" | ${awk} -F'/' '{print $5 "ms"}' || echo "FAILED"
      echo

      echo "[Throughput]"
      echo "  Running speedtest..."
      ${pkgs.speedtest-cli}/bin/speedtest-cli --simple 2>/dev/null | sed 's/^/  /' || echo "  FAILED"
      echo

      echo "✓ Test complete"
    '')

    (pkgs.writeShellScriptBin "mtu-test" ''
      #!${bash}
      set -euo pipefail

      TARGET="''${1:-1.1.1.1}"
      echo "=== MTU Discovery for ''${TARGET} ==="
      echo

      for mtu in 1500 1492 1472 1420 1400 1280; do
        payload=$((mtu - 28))
        echo -n "Testing MTU ''${mtu}: "

        if ${pkgs.iputils}/bin/ping -c 1 -M do -s ''${payload} ''${TARGET} >/dev/null 2>&1; then
          echo "✓ OK"
          echo
          echo "Maximum MTU: ''${mtu} bytes"
          break
        else
          echo "✗ Too large"
        fi
      done
    '')
  ];

  # ============================================================================
  # Shell Aliases (Layer 8: Convenience)
  # ============================================================================

  environment.shellAliases = {
    # WiFi
    wifi-list       = "nmcli device wifi list --rescan yes";
    wifi-connect    = "nmcli device wifi connect";
    wifi-saved      = "nmcli connection show";
    wifi-current    = "nmcli -t -f active,ssid dev wifi | grep '^yes' | cut -d':' -f2";

    # Network status
    net-status      = "nmcli general status";
    net-info        = "ip -c -br addr show";

    # VPN (Mullvad)
    vpn-status      = "mullvad status";
    vpn-connect     = "mullvad connect";
    vpn-disconnect  = "mullvad disconnect";
    vpn-reconnect   = "mullvad reconnect";

    # DNS
    dns-status      = "resolvectl status";
    dns-flush       = "resolvectl flush-caches";
    dns-leak        = "curl -s https://am.i.mullvad.net/json | ${pkgs.jq}/bin/jq -r '.ip'";

    # Connections
    conns-tcp       = "ss -tupn | grep ESTAB";
    conns-listen    = "ss -tlnp";
    conns-count     = "ss -s";

    # Performance
    net-speed       = "speedtest-cli";
    net-trace       = "mtr";

    # TCP stack helpers
    tcp-info        = "tcp-status";
    tcp-test        = "net-test";

    # Routing
    route-show      = "ip route show";
    route-default   = "ip route show default";

    # SQM control
    sqm-status  = "systemctl status sqm-cake";
    sqm-start   = "sudo systemctl start sqm-cake";
    sqm-stop    = "sudo systemctl stop sqm-cake";
    sqm-restart = "sudo systemctl restart sqm-cake";
    sqm-logs    = "journalctl -u sqm-cake -f --no-pager -n 50";

    sqm-show = ''
      DEF="$(ip route show default 2>/dev/null | awk "/default/ {print \$5; exit}")"
      VPNS="$(ip -o link show | awk -F': ' "{print \$2}" | grep -E "^(wg|tun)[0-9A-Za-z._-]*$" || true)"
      echo -e "\033[1;36m================ SQM/CAKE Status ================\033[0m"

      for IFACE in $DEF $VPNS; do
        [ -n "$IFACE" ] || continue
        echo -e "\033[1;33m=== $IFACE ===\033[0m"
        tc qdisc show dev "$IFACE" 2>/dev/null | grep -E "(qdisc (cake|ingress))" || echo "  (no qdisc)"

        IFB="$(tc filter show dev "$IFACE" parent ffff: 2>/dev/null | awk "/mirred.*redirect dev/ {print \$NF; exit}")"
        if [ -z "$IFB" ]; then
          for TRY in "ifb-$IFACE" "ifb-$IFACE-"; do
            ip link show "$TRY" &>/dev/null && { IFB="$TRY"; break; }
          done
        fi
        if [ -n "$IFB" ] && ip link show "$IFB" &>/dev/null; then
          tc qdisc show dev "$IFB" 2>/dev/null | grep -E "(qdisc cake)" && echo "↳ ($IFB)"
        fi
      done
      echo -e "\033[1;36m=================================================\033[0m"
    '';

    sqm-test = ''
      xdg-open https://www.waveform.com/tools/bufferbloat 2>/dev/null \
        || echo "→ Open manually: https://www.waveform.com/tools/bufferbloat"
    '';
  };

  # ============================================================================
  # SQM/CAKE Service
  # ============================================================================

  systemd.services.sqm-cake = {
    description = "SQM/CAKE Bufferbloat Mitigation (WAN + VPN aware)";
    after  = [ "network.target" "NetworkManager.service" "mullvad-daemon.service" ];
    wants  = [ "NetworkManager.service" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      Type            = "oneshot";
      RemainAfterExit = true;
      ExecStart       = "${sqm.sqmScript} setup";
      ExecStop        = "${sqm.sqmScript} cleanup";
      Restart         = "on-failure";
      RestartSec      = "10s";
    };
  };

  # ============================================================================
  # Assertions & Warnings (Layer 9: Validation)
  # ============================================================================

  assertions = [
    {
      assertion = config.networking.networkmanager.enable;
      message = "NetworkManager must be enabled";
    }
    {
      assertion = config.services.resolved.enable;
      message = "systemd-resolved must be enabled for DNS";
    }
  ];

  warnings =
    lib.optionals (!config.networking.enableIPv6) [
      "IPv6 disabled - may cause issues with modern CDNs and services"
    ] ++
    lib.optionals (hasMullvad && !config.networking.firewall.enable && !(config.networking.nftables.enable or false)) [
      "Mullvad enabled but no firewall (neither iptables nor nftables) - killswitch won't work"
    ];
}
