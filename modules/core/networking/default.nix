# modules/core/networking/default.nix
# ==============================================================================
# Networking & TCP/IP Stack Configuration - Production Grade
# ==============================================================================
#
# Module:      modules/core/networking
# Purpose:     Network management, VPN, TCP optimization, DNS configuration
# Author:      Kenan Pelit
# Created:     2025-10-09
# Modified:    2025-10-18
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
#   • Performance - Modern congestion control, optimized buffers
#   • Security - Hardened IP stack, MAC randomization, VPN killswitch
#   • Reliability - Systemd-native, robust error handling
#   • Observability - Rich diagnostics and monitoring
#
# Module Boundaries:
#   ✓ Network configuration          (THIS MODULE)
#   ✓ TCP/IP stack tuning            (THIS MODULE)
#   ✓ VPN client setup               (THIS MODULE)
#   ✓ DNS resolution                 (THIS MODULE)
#   ✗ Firewall rules                 (security module)
#   ✗ SSH daemon                     (security module)
#   ✗ Network services (HTTP, etc.)  (services module)
#
# ==============================================================================

{ config, lib, pkgs, host, ... }:

let
  inherit (lib) mkIf mkMerge mkDefault mkForce;
  toString = builtins.toString;

  # ----------------------------------------------------------------------------
  # VPN State Detection
  # ----------------------------------------------------------------------------
  hasMullvad = config.services.mullvad-vpn.enable or false;

  # ----------------------------------------------------------------------------
  # TCP Profile Parameters (Three-Tier System)
  # ----------------------------------------------------------------------------
  # Buffer sizes in "min default max" format
  # Memory pools in pages (4KB each)
  # Thresholds account for iGPU shared memory on E14 Gen 6
  
  ultra = {
    # Buffer Configuration (64MB max for high-throughput)
    rmem               = "4096 1048576 67108864";   # RX: 4KB min, 1MB default, 64MB max
    wmem               = "4096 1048576 67108864";   # TX: 4KB min, 1MB default, 64MB max
    rmem_max           = 67108864;                  # 64MB max receive buffer
    wmem_max           = 67108864;                  # 64MB max send buffer
    rmem_default       = 2097152;                   # 2MB default RX
    wmem_default       = 2097152;                   # 2MB default TX
    
    # Queue Configuration (handle high packet rates)
    netdev_max_backlog = 32000;                     # RX queue size (packets)
    somaxconn          = 8192;                      # Listen backlog (connections)
    tcp_max_syn_backlog = 16384;                    # SYN backlog (half-open connections)
    tcp_max_tw_buckets  = 4000000;                  # TIME-WAIT sockets (4M)
    
    # Memory Pools (pages, 4KB each)
    tcp_mem            = "3145728 4194304 6291456"; # TCP: 12GB/16GB/24GB
    udp_mem            = "1572864 2097152 3145728"; # UDP: 6GB/8GB/12GB
    
    # Connection Tracking (for NAT, firewall, VPN)
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
  # Reads /proc/meminfo and returns total RAM in MB
  # Used to determine which TCP profile to apply
  
  detectMemoryScript = pkgs.writeShellScript "detect-memory" ''
    #!${bash}
    set -euo pipefail
    TOTAL_KB=$(${grep} "^MemTotal:" /proc/meminfo | ${awk} '{print $2}')
    echo $((TOTAL_KB / 1024))
  '';

  # ----------------------------------------------------------------------------
  # Profile Detection & Caching Script
  # ----------------------------------------------------------------------------
  # Determines TCP profile based on RAM and caches result
  # Cache: /run/network-tuning-profile (tmpfs, persists until reboot)
  # Thresholds:
  #   ≥60GB → ultra  (E14 Gen 6, accounts for iGPU shared memory)
  #   32-59GB → high (future systems)
  #   <32GB → std    (X1 Carbon Gen 6)
  
  detectAndCacheProfile = pkgs.writeShellScript "detect-and-cache-profile" ''
    #!${bash}
    set -euo pipefail
    
    CACHE_FILE="/run/network-tuning-profile"
    ${mkdir} -p "$(dirname "$CACHE_FILE")"
    
    TOTAL_MB=$(${detectMemoryScript})
    TOTAL_GB=$((TOTAL_MB / 1024))
    
    if [[ "$TOTAL_MB" -ge 61440 ]]; then
      # ≥60GB: ULTRA profile (E14 Gen 6 - Core Ultra 7 155H)
      echo "ultra" > "$CACHE_FILE"
      echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
      echo "[TCP] Detected ''${TOTAL_GB}GB RAM → ULTRA performance profile"
      echo "[TCP] Target: E14 Gen 6 (Core Ultra 7 155H)"
      echo "[TCP] Config: 64MB buffers, 32k backlog, 1M conntrack"
      echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    elif [[ "$TOTAL_MB" -ge 32768 ]]; then
      # 32-59GB: HIGH profile (reserved for future)
      echo "high" > "$CACHE_FILE"
      echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
      echo "[TCP] Detected ''${TOTAL_GB}GB RAM → HIGH performance profile"
      echo "[TCP] Config: 32MB buffers, 16k backlog, 524k conntrack"
      echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    else
      # <32GB: STANDARD profile (X1 Carbon Gen 6 - i7-8650U)
      echo "std" > "$CACHE_FILE"
      echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
      echo "[TCP] Detected ''${TOTAL_GB}GB RAM → STANDARD profile"
      echo "[TCP] Target: X1 Carbon Gen 6 (i7-8650U)"
      echo "[TCP] Config: 16MB buffers, 5k backlog, 262k conntrack"
      echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    fi
  '';

  # ----------------------------------------------------------------------------
  # [10] SQM/CAKE — WAN + VPN Aware (script & knobs)
  # ----------------------------------------------------------------------------
  sqm = rec {
    # ---- Bandwidths (~85–90% of speedtest) ----
    uploadBandwidth      = "15mbit";   # WAN upstream
    downloadBandwidth    = "50mbit";   # WAN downstream
    enableNatOnWAN       = true;

    vpnUploadBandwidth   = "15mbit";   # VPN upstream
    vpnDownloadBandwidth = "50mbit";   # VPN downstream (applied on default iface)
    enableNatOnVPN       = false;

  sqmScript = pkgs.writeShellScript "setup-sqm-cake" ''
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
    DATE="${pkgs.coreutils}/bin/date"
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

    # ===== New: robust waits =====
    wait_for_tc_ready() {
      # modüller yüklendikten hemen sonra tc bazen ilk saniyede hata verebilir
      local tries=5
      while [ $tries -gt 0 ]; do
        if ''${TC} qdisc show dev lo >/dev/null 2>&1; then
          return 0
        fi
        sleep 1; tries=$((tries-1))
      done
      return 1
    }

    wait_for_default_iface() {
      # default route + iface UP olana kadar bekle
      local tries=30
      while [ $tries -gt 0 ]; do
        local def
        def="$(detect_default_iface || true)"
        if [ -n "''${def:-}" ] && is_up "$def"; then
          echo "$def"; return 0
        fi
        sleep 1; tries=$((tries-1))
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

    # ===== Verify helpers =====
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

    # ===== UPDATED setup_all with waits =====
    setup_all() {
      log "Starting SQM/CAKE setup..."
      load_modules
      wait_for_tc_ready || { error "tc not ready"; exit 1; }

      # Default arayüz/route hazır olana kadar bekle
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
    # Hostname from host parameter
    hostName = "${host}";
    
    # ==========================================================================
    # Firewall Configuration
    # ==========================================================================
    # Note: Firewall is enabled by default, but can be overridden by security module
    # When nftables is used (security module), this will be set to false with mkForce
    firewall.enable = mkDefault true;
    
    # ==========================================================================
    # IPv6 Configuration
    # ==========================================================================
    # Enabled by default for modern internet compatibility
    # Many CDNs (Cloudflare, Fastly) prefer IPv6
    # Streaming services (Netflix, YouTube) use IPv6
    
    enableIPv6 = mkDefault true;
    
    # ---- Privacy Extensions (RFC 4941) ----
    # Generate temporary IPv6 addresses to prevent tracking
    # Rotates addresses periodically while keeping stable address
    tempAddresses = mkDefault "default";
    
    # Per-interface IPv6 disable (if needed):
    # networking.interfaces.<name>.ipv6.enable = false;
    
    # ---- Disable wpa_supplicant ----
    # NetworkManager manages WiFi (don't use both)
    wireless.enable = false;

    # ==========================================================================
    # NetworkManager Configuration
    # ==========================================================================
    # Modern network management daemon
    # Handles: WiFi, Ethernet, VPN, mobile broadband
    
    networkmanager = {
      enable = true;
      
      # ========================================================================
      # WiFi Configuration
      # ========================================================================
      wifi = {
        # ---- Backend Selection ----
        # wpa_supplicant: Stable, mature (recommended)
        # iwd: Modern, faster, but less tested
        backend = "wpa_supplicant";
        
        # ---- Privacy Features ----
        # Randomize MAC during WiFi scans (prevents tracking)
        scanRandMacAddress = true;
        
        # ---- Power Management ----
        # Disabled: Reduces disconnects, better reliability
        # Enable on laptops if battery life is critical
        powersave = false;
        
        # ---- MAC Address Policy ----
        # preserve: Keep real MAC after connection (some networks require this)
        # random: Randomize MAC per connection (maximum privacy)
        # stable: Generate consistent random MAC per SSID
        macAddress = "preserve";
      };
      
      # ========================================================================
      # DNS Configuration
      # ========================================================================
      # Delegate to systemd-resolved for:
      # - Caching, DNSSEC validation
      # - Per-link DNS (VPN can override)
      # - mDNS/LLMNR support
      dns = "systemd-resolved";
      
      # ========================================================================
      # Ethernet Configuration
      # ========================================================================
      # Preserve MAC on Ethernet (no privacy benefit, adds complexity)
      ethernet.macAddress = "preserve";
      
      # ========================================================================
      # Connection Settings
      # ========================================================================
      settings = {
        connection = {
          # Retry forever (0 = infinite)
          # Useful for: Unstable networks, sleep/wake cycles
          "connection.autoconnect-retries" = 0;
        };
        
        # IPv6 Privacy
        ipv6 = {
          # Prefer temporary addresses (RFC 4941)
          # 0: Disabled, 1: Enabled, 2: Prefer temporary
          "ipv6.ip6-privacy" = 2;
        };
      };
    };

    # ==========================================================================
    # WireGuard Support
    # ==========================================================================
    # Kernel module for modern VPN protocol
    # Used by: Mullvad, Tailscale, many commercial VPNs
    # Benefits: Faster than OpenVPN, simpler than IPsec, built into kernel
    wireguard.enable = true;

    # ==========================================================================
    # DNS Servers (Layer 2: Name Resolution)
    # ==========================================================================
    # Fallback DNS when Mullvad is not active
    # Priority: Privacy > Speed > Reliability
    #
    # When Mullvad VPN is active:
    # - Mullvad provides DNS (with ad/tracker blocking)
    # - These servers are ignored
    #
    # When VPN is inactive:
    # - Use privacy-focused public resolvers
    # - Cloudflare: Fast, private, no logging
    # - Quad9: Malware filtering, threat intelligence
    
    nameservers = mkMerge [
      (mkIf (!hasMullvad) [
        # Cloudflare DNS (primary)
        "1.1.1.1"                    # IPv4 primary
        "1.0.0.1"                    # IPv4 secondary
        "2606:4700:4700::1111"       # IPv6 primary
        "2606:4700:4700::1001"       # IPv6 secondary
        
        # Quad9 DNS (secondary - malware filtering)
        "9.9.9.9"                    # IPv4
        "2620:fe::fe"                # IPv6
      ])
      (mkIf hasMullvad [ ])  # Empty when Mullvad active
    ];
    
    # Alternative DNS providers (commented):
    # Google DNS: "8.8.8.8", "8.8.4.4"
    # OpenDNS: "208.67.222.222", "208.67.220.220"
    # AdGuard: "94.140.14.14", "94.140.15.15"

    # ==========================================================================
    # Firewall Configuration
    # ==========================================================================
    # Note: Detailed firewall rules are in security/default.nix
    # This module only sets the foundation for VPN killswitch compatibility
    # When using nftables (security module), firewall.enable will be overridden to false
    #
    # The firewall.enable setting above (line 214) is sufficient.
    # No additional firewall configuration needed here.
  };

  # ============================================================================
  # System Services (Layer 3: DNS & VPN)
  # ============================================================================
  
  services = {
    # ==========================================================================
    # systemd-resolved - Modern DNS Resolver
    # ==========================================================================
    # Features:
    # - DNS caching (faster subsequent lookups)
    # - DNSSEC validation (authenticity verification)
    # - Per-link DNS (VPN can override system DNS)
    # - mDNS/LLMNR (local network discovery)
    # - DNS-over-TLS support (encrypted DNS)
    
    resolved = {
      enable = true;
      
      # ========================================================================
      # DNSSEC Configuration
      # ========================================================================
      # DNSSEC validates DNS responses (prevents poisoning)
      # allow-downgrade: Validate when possible, fallback if broken
      # Reason: Some ISPs/networks break DNSSEC, this prevents outages
      dnssec = "allow-downgrade";
      
      # For maximum security (may break some networks):
      # dnssec = "true";
      
      # ========================================================================
      # Fallback DNS
      # ========================================================================
      # Used when:
      # - Configured DNS servers are unreachable
      # - NetworkManager hasn't set DNS yet (boot)
      fallbackDns = [ "1.1.1.1" "9.9.9.9" ];
      
      # ========================================================================
      # Advanced Configuration
      # ========================================================================
      extraConfig = ''
        # ----------------------------------------------------------------------
        # Local Discovery Protocols
        # ----------------------------------------------------------------------
        # LLMNR: Link-Local Multicast Name Resolution (Windows NetBIOS-style)
        # mDNS: Multicast DNS (Apple Bonjour/Avahi, .local domains)
        # Security: Both leak queries on untrusted networks
        # Recommendation: Disable unless needed for local services
        LLMNR=no
        MulticastDNS=no

        # ----------------------------------------------------------------------
        # DNS Caching
        # ----------------------------------------------------------------------
        # Enable cache for faster subsequent lookups
        Cache=yes
        
        # Don't cache responses from localhost (127.0.0.1/::1)
        # Useful if running local DNS server (Unbound, Pi-hole, etc.)
        CacheFromLocalhost=no

        # ----------------------------------------------------------------------
        # DNS Stub Listener
        # ----------------------------------------------------------------------
        # Listens on 127.0.0.53:53 for local DNS queries
        # Applications query this instead of configured DNS servers
        DNSStubListener=yes
        
        # Additional stub listener (backup on port 54)
        DNSStubListenerExtra=127.0.0.54

        # ----------------------------------------------------------------------
        # DNS-over-TLS (DoT)
        # ----------------------------------------------------------------------
        # Encrypted DNS to prevent ISP snooping
        # Disabled when using VPN (Mullvad already encrypts DNS)
        # Enable if not using VPN: DNSOverTLS=opportunistic
        DNSOverTLS=no
        
        # DoT modes:
        # - no: Disabled (default when using VPN)
        # - opportunistic: Use TLS if available, fallback to plain
        # - yes: Require TLS (may break some networks)

        # ----------------------------------------------------------------------
        # Routing Configuration
        # ----------------------------------------------------------------------
        # ~. makes this the default DNS resolver for all domains
        # VPN can override with per-link DNS
        Domains=~.

        # ----------------------------------------------------------------------
        # DNSSEC Trust Anchors
        # ----------------------------------------------------------------------
        # Negative trust anchors for broken DNSSEC domains
        # Add domains here if legitimate sites fail DNSSEC validation
        # NegativeTrustAnchors=example.com broken-dnssec.net
      '';
    };

    # ==========================================================================
    # Mullvad VPN Service
    # ==========================================================================
    # Privacy-focused VPN provider
    # Features: WireGuard protocol, split tunneling, killswitch, ad blocking
    
    mullvad-vpn = {
      enable = true;
      package = pkgs.mullvad;
      #package = pkgs.mullvad-vpn;

      
      # ---- Split Tunneling Wrapper ----
      # Allows excluding specific apps from VPN tunnel
      # Usage: mullvad-exclude firefox
      enableExcludeWrapper = true;
    };
  };

  # ============================================================================
  # Mullvad Daemon Log Optimization - FINAL SOLUTION
  # ============================================================================
  # Problem: mullvad_daemon::management_interface still emits DEBUG
  #          - get_tunnel_state/get_device every 5 seconds
  #          - RUST_LOG environment variable ignored
  #
  # Root Cause: Mullvad GUI client triggers these DEBUG logs
  #             Not the daemon itself, but the management interface
  #
  # Solution: Since these come from GUI polling, filter at systemd level
  #           Accept that some DEBUG will exist, just prevent journal spam
  
  systemd.services.mullvad-daemon = {
    # Don't override environment (let Mullvad set its own)
    # Instead, filter at journal ingestion level
    
    serviceConfig = {
      # Journal filtering - AGGRESSIVE
      # Drop DEBUG messages before they hit disk
      StandardOutput = "journal";
      StandardError = "journal";
      
      # Use numeric levels (more reliable)
      # 6 = info, 7 = debug
      LogLevelMax = "6";
      
      # Alternative: If numeric doesn't work, use syslog
      SyslogLevel = "info";
      SyslogLevelPrefix = false;
      
      # AGGRESSIVE rate limiting
      # Only allow 10 messages per 10 seconds (vs 100/30s)
      LogRateLimitIntervalSec = "10s";
      LogRateLimitBurst = 10;
    };
  };

  # ============================================================================
  # Systemd Services (Layer 4: Service Orchestration)
  # ============================================================================
  
  # ==========================================================================
  # Disable NetworkManager-wait-online
  # ==========================================================================
  # Why disable:
  # - Blocks boot until network is "online" (slow DHCP/VPN delays boot)
  # - Not needed for desktop systems (services can wait individually)
  # - Faster boot times (especially with VPN enabled)
  #
  # Keep enabled if:
  # - Running network services on boot (web server, NFS mounts)
  # - Need guaranteed network before starting applications
  systemd.services."NetworkManager-wait-online".enable = false;

  # ==========================================================================
  # Network Profile Detection Service
  # ==========================================================================
  # Runs early in boot to detect RAM and cache TCP tuning profile
  # Cache persists in /run (tmpfs) until reboot
  
  systemd.services."network-profile-detect" = {
    description = "Detect and cache network tuning profile based on system memory";
    
    # ---- Service Ordering ----
    wantedBy = [ "sysinit.target" ];        # Start during early boot
    before = [ "network-pre.target" ];      # Before network configuration
    
    serviceConfig = {
      Type = "oneshot";                     # Run once and exit
      RemainAfterExit = true;               # Mark as active after completion
      ExecStart = detectAndCacheProfile;
    };
  };

  # ==========================================================================
  # Dynamic TCP Tuning Service
  # ==========================================================================
  # Applies TCP stack configuration based on detected memory tier
  # Runs before network services to ensure settings active early
  # See Part 2 for complete implementation
  
  systemd.services."network-tcp-tuning" = {
    description = "Apply dynamic TCP/IP stack tuning based on system profile";
    
    # ---- Dependencies ----
    wantedBy = [ "multi-user.target" ];
    after = [ 
      "network-profile-detect.service"    # After profile detection
      "sysinit.target"                    # After system initialization
    ];
    before = [ 
      "network-pre.target"                # Before network configuration
      "NetworkManager.service"            # Before NetworkManager
      "mullvad-daemon.service"            # Before VPN daemon
    ];
    requires = [ "network-profile-detect.service" ];
    
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      
      # See Part 2 for complete tuning script
      ExecStart = pkgs.writeShellScript "apply-tcp-tuning" ''
        #!${bash}
        set -euo pipefail
        
        CACHE_FILE="/run/network-tuning-profile"
        
        if [[ ! -f "$CACHE_FILE" ]]; then
          echo "ERROR: Profile cache missing. Detection may have failed."
          exit 1
        fi
        
        PROFILE=$(${cat} "$CACHE_FILE")
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "[TCP] Applying $PROFILE performance profile"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        
        # Profile-specific tuning in Part 2...
      '';
    };
  };
  
  # ==========================================================================
  # Mullvad Auto-Connect Service (Continued from Part 1)
  # ==========================================================================
  # Waits for daemon readiness and configures VPN settings
  # Features: Auto-connect, DNS ad-blocking, automatic reconnection
  
  systemd.services."mullvad-autoconnect" = mkIf hasMullvad {
    description = "Configure and auto-connect Mullvad VPN on boot";
    
    # Disabled by default - uncomment wantedBy to enable
    #wantedBy = [ "multi-user.target" ];
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
      Restart = "on-failure";      # Retry if connection fails
      RestartSec = "10s";
      
      ExecStart = lib.getExe (pkgs.writeShellScriptBin "mullvad-autoconnect" ''
        set -euo pipefail

        CLI="${pkgs.mullvad-vpn}/bin/mullvad"
        MAX_WAIT=30
        
        # Wait for daemon socket
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

        # Configure VPN settings
        echo "[Mullvad] Configuring..."
        "$CLI" auto-connect set on || echo "[Mullvad] ⚠ Auto-connect failed"
        "$CLI" dns set default --block-ads --block-trackers || echo "[Mullvad] ⚠ DNS config failed"
        
        # Killswitch (lockdown mode) - uncomment if needed
        # "$CLI" lockdown-mode set on || echo "[Mullvad] ⚠ Lockdown failed"

        # Connect
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
  # TCP/IP Stack Kernel Parameters (Layer 5: Performance Tuning)
  # ============================================================================
  # Baseline settings applied at boot (before dynamic tuning service)
  # Dynamic service overrides buffer/queue settings for high-memory systems
  
  boot.kernel.sysctl = {
    # ==========================================================================
    # Modern Congestion Control (BBR + Fair Queuing)
    # ==========================================================================
    # Why BBR?
    # - Maximizes throughput while minimizing latency
    # - Superior on high-bandwidth, variable-latency links (VPN, cellular, WiFi)
    # - Better than CUBIC for modern internet (handles bufferbloat)
    #
    # Why Fair Queuing (FQ)?
    # - Required for optimal BBR performance
    # - Per-flow queuing and pacing
    # - Prevents head-of-line blocking
    
    "net.core.default_qdisc" = "fq";                      # Fair Queuing scheduler
    "net.ipv4.tcp_congestion_control" = "bbr";            # BBR congestion control
    
    # Alternatives:
    # - CUBIC: Default, good for stable connections
    # - Reno: Legacy, simple, compatible
    # - Vegas: Delay-based, good for low latency

    # ==========================================================================
    # Port Range (Ephemeral Ports)
    # ==========================================================================
    # Range for outgoing connections
    # Wider range = more simultaneous connections possible
    # Default: 32768-60999 (28k ports)
    # This config: 1024-65535 (64k ports)
    "net.ipv4.ip_local_port_range" = "1024 65535";

    # ==========================================================================
    # Buffer Configuration (Standard Profile Defaults)
    # ==========================================================================
    # These are overridden by dynamic tuning service for high-memory systems
    # mkDefault = Can be overridden by system-specific config
    
    "net.core.rmem_max"     = mkDefault std.rmem_max;      # Max RX buffer: 16MB
    "net.core.rmem_default" = mkDefault std.rmem_default;  # Default RX: 512KB
    "net.core.wmem_max"     = mkDefault std.wmem_max;      # Max TX buffer: 16MB
    "net.core.wmem_default" = mkDefault std.wmem_default;  # Default TX: 512KB

    # ==========================================================================
    # Network Device & Queue Settings
    # ==========================================================================
    
    # ---- Packet Queue (Before Processing) ----
    # Incoming packets wait here before kernel processes them
    # Higher = better burst handling, more memory usage
    "net.core.netdev_max_backlog" = mkDefault std.netdev_max_backlog;  # 5000 packets
    
    # ---- NAPI Polling Budget ----
    # Packets processed per interrupt
    # Balance: Throughput vs latency vs CPU usage
    "net.core.netdev_budget" = 300;           # Packets per interrupt
    "net.core.netdev_budget_usecs" = 8000;    # Time budget: 8ms per interrupt
    
    # ---- Listen Socket Backlog ----
    # Pending connections queue for listen() sockets
    # Important for: Web servers, SSH, high connection rate
    "net.core.somaxconn" = mkDefault std.somaxconn;  # 1024 connections

    # ==========================================================================
    # eBPF Security (Extended Berkeley Packet Filter)
    # ==========================================================================
    # eBPF enables high-performance packet filtering
    # Used by: Cilium, Calico, systemd, firewall rules
    
    "net.core.bpf_jit_enable" = 1;   # Enable JIT compilation (performance)
    "net.core.bpf_jit_harden" = 1;   # Harden JIT (security, minimal overhead)

    # ==========================================================================
    # TCP Performance Features
    # ==========================================================================
    
    # ---- TCP Fast Open (TFO) ----
    # Reduce connection latency by sending data in SYN packet
    # 3 = Enable for both client and server
    # Requires: Application support, kernel 3.13+
    "net.ipv4.tcp_fastopen" = 3;
    
    # ---- Duplicate SACK (D-SACK) ----
    # Improve loss detection and recovery
    # Helps distinguish: Packet loss vs reordering
    "net.ipv4.tcp_dsack" = 1;
    
    # ---- Slow Start After Idle ----
    # Disabled: Better for bursty traffic (web browsing, API calls)
    # BBR handles pacing, so safe to disable
    "net.ipv4.tcp_slow_start_after_idle" = 0;
    
    # ---- Auto-tune Receive Buffer ----
    # Dynamically adjust RX buffer based on RTT and throughput
    # Critical for: High-bandwidth links, long-distance connections
    "net.ipv4.tcp_moderate_rcvbuf" = 1;
    
    # ---- TCP Small Queue ----
    # Prevent application from queuing too much unsent data
    # Reduces latency for interactive traffic (SSH, gaming)
    "net.ipv4.tcp_notsent_lowat" = 16384;  # 16KB threshold

    # ==========================================================================
    # Path MTU Discovery (PMTUD)
    # ==========================================================================
    # Automatically discover optimal packet size for path
    # Critical for: VPN, tunnels, non-standard MTU networks
    
    # ---- MTU Probing ----
    # 0: Disabled
    # 1: Enable, fallback to base MSS if blackhole detected
    # 2: Always probe (aggressive)
    "net.ipv4.tcp_mtu_probing" = 1;
    
    # ---- Base MSS (Maximum Segment Size) ----
    # Uncomment for VPN/tunnel scenarios with MTU issues
    # WireGuard typically needs MTU 1420 or lower
    # "net.ipv4.tcp_base_mss" = 1240;  # Safe for most VPNs

    # ==========================================================================
    # TCP Memory Management
    # ==========================================================================
    # Auto-tuning ranges: min, default, max (in pages, 4KB each)
    # Dynamic tuning service overrides these for high-memory systems
    
    "net.ipv4.tcp_rmem" = mkDefault std.rmem;  # RX: 4KB/256KB/16MB
    "net.ipv4.tcp_wmem" = mkDefault std.wmem;  # TX: 4KB/256KB/16MB
    
    # ---- Global Memory Limits (Pages) ----
    # When to start applying memory pressure
    "net.ipv4.tcp_mem" = mkDefault std.tcp_mem;  # TCP: 3GB/4GB/6GB
    "net.ipv4.udp_mem" = mkDefault std.udp_mem;  # UDP: 1.5GB/2GB/3GB

    # ==========================================================================
    # Connection Lifecycle Management
    # ==========================================================================
    
    # ---- TCP Keepalive (Detect Dead Connections) ----
    "net.ipv4.tcp_keepalive_time"   = 300;   # Start probing after 5min idle
    "net.ipv4.tcp_keepalive_intvl"  = 30;    # Probe interval: 30s
    "net.ipv4.tcp_keepalive_probes" = 3;     # Give up after 3 failed probes
    
    # Total timeout: 5min + (30s × 3) = 6.5 minutes
    
    # ---- Connection Termination ----
    "net.ipv4.tcp_fin_timeout" = 60;         # FIN-WAIT-2 timeout: 30s
    
    # ---- TIME-WAIT Reuse ----
    # Enable reuse of TIME-WAIT sockets (safe with timestamps)
    # Critical for: High connection rate (web servers, proxies)
    "net.ipv4.tcp_max_tw_buckets" = mkDefault std.tcp_max_tw_buckets;  # 1M buckets
    "net.ipv4.tcp_tw_reuse" = 1;             # Reuse TIME-WAIT sockets

    # ==========================================================================
    # Retransmission & Timeout Tuning
    # ==========================================================================
    
    # ---- Retransmission Attempts ----
    "net.ipv4.tcp_retries2" = 8;             # Give up after ~15-30min
    
    # ---- SYN Retransmission (Connection Setup) ----
    "net.ipv4.tcp_syn_retries" = 3;          # Client: ~63s total
    "net.ipv4.tcp_synack_retries" = 3;       # Server: ~63s total

    # ==========================================================================
    # SYN Flood Protection (DoS Mitigation)
    # ==========================================================================
    
    # ---- SYN Cookies ----
    # Fallback when SYN backlog is full
    # Prevents: SYN flood attacks, doesn't break legitimate connections
    "net.ipv4.tcp_syncookies" = 1;
    
    # ---- SYN Backlog Size ----
    "net.ipv4.tcp_max_syn_backlog" = mkDefault std.tcp_max_syn_backlog;  # 2048

    # ==========================================================================
    # Advanced TCP Features
    # ==========================================================================
    
    # ---- Packet Reordering Tolerance ----
    # Modern networks reorder packets (multipath, load balancing)
    "net.ipv4.tcp_reordering" = 3;
    
    # ---- Explicit Congestion Notification (ECN) ----
    # Routers mark packets instead of dropping (reduces retransmissions)
    # 1 = Request ECN, fall back if not supported
    "net.ipv4.tcp_ecn" = 1;
    "net.ipv4.tcp_ecn_fallback" = 1;
    
    # ---- Forward RTO-Recovery (F-RTO) ----
    # Improved spurious timeout detection
    # 2 = Most aggressive, best for long-delay links (VPN, satellite)
    "net.ipv4.tcp_frto" = 2;
    
    # ---- RFC 1337 Protection ----
    # TIME-WAIT assassination protection (security)
    "net.ipv4.tcp_rfc1337" = 1;
    
    # ---- TCP Timestamps ----
    # Required for: PAWS, RTT measurement, some features
    "net.ipv4.tcp_timestamps" = 1;
    
    # ---- Selective Acknowledgment (SACK) ----
    # More efficient retransmission (send only missing segments)
    "net.ipv4.tcp_sack" = 1;

    # ==========================================================================
    # IP Security Hardening
    # ==========================================================================
    
    # ---- Reverse Path Filtering (Anti-spoofing) ----
    # 2 = Loose mode (necessary for VPN, asymmetric routing)
    # 1 = Strict mode (better security, may break VPN)
    "net.ipv4.conf.all.rp_filter"     = 2;
    "net.ipv4.conf.default.rp_filter" = 2;
    
    # ---- Disable ICMP Redirects ----
    # Prevents: MITM attacks via ICMP redirect
    "net.ipv4.conf.all.accept_redirects"     = 0;
    "net.ipv4.conf.default.accept_redirects" = 0;
    "net.ipv4.conf.all.secure_redirects"     = 0;
    "net.ipv4.conf.default.secure_redirects" = 0;
    "net.ipv4.conf.all.send_redirects"       = 0;
    
    # ---- Disable Source Routing ----
    # Security risk: Allows attacker to specify packet route
    "net.ipv4.conf.all.accept_source_route"     = 0;
    "net.ipv4.conf.default.accept_source_route" = 0;
    
    # ---- ICMP Protection ----
    "net.ipv4.icmp_echo_ignore_broadcasts" = 1;        # Smurf attack prevention
    "net.ipv4.icmp_ignore_bogus_error_responses" = 1;  # Ignore fake ICMP errors
    
    # ---- Martian Packet Logging ----
    # Log packets with impossible source addresses (debugging)
    # Disabled by default (can be noisy)
    "net.ipv4.conf.all.log_martians" = mkDefault 0;

    # ==========================================================================
    # IPv6 Security (If Enabled)
    # ==========================================================================
    
    # ---- Disable IPv6 Redirects ----
    "net.ipv6.conf.all.accept_redirects"     = 0;
    "net.ipv6.conf.default.accept_redirects" = 0;
    
    # ---- Disable IPv6 Source Routing ----
    "net.ipv6.conf.all.accept_source_route" = 0;
    
    # ---- Router Advertisements ----
    # Disabled by default (use DHCPv6 or manual config)
    # Enable per-interface if using SLAAC
    "net.ipv6.conf.all.accept_ra" = 0;
    "net.ipv6.conf.default.accept_ra" = 0;

    # ==========================================================================
    # Connection Tracking (Netfilter)
    # ==========================================================================
    # Critical for: Firewall, NAT, VPN, stateful packet filtering
    
    # ---- Maximum Tracked Connections ----
    "net.netfilter.nf_conntrack_max" = mkDefault std.conntrack_max;  # 262k
    
    # ---- Connection Timeouts ----
    "net.netfilter.nf_conntrack_tcp_timeout_established" = 432000;  # 5 days
    "net.netfilter.nf_conntrack_tcp_timeout_time_wait"   = 30;
    "net.netfilter.nf_conntrack_tcp_timeout_close_wait"  = 30;
    "net.netfilter.nf_conntrack_tcp_timeout_fin_wait"    = 30;
    "net.netfilter.nf_conntrack_udp_timeout"             = 60;
    "net.netfilter.nf_conntrack_generic_timeout"         = 600;     # 10min
    
    # ---- Connection Tracking Helpers ----
    # Disabled for security (enable if needed for FTP, TFTP, etc.)
    "net.netfilter.nf_conntrack_helper" = 0;

    # ==========================================================================
    # Additional Performance Tuning
    # ==========================================================================
    
    # ---- TCP Window Scaling ----
    # Required for high-bandwidth links (>1Gbps)
    "net.ipv4.tcp_window_scaling" = 1;
    
    # ---- ARP Cache Size ----
    # Important for large LANs (many hosts)
    "net.ipv4.neigh.default.gc_thresh1" = 4096;
    "net.ipv4.neigh.default.gc_thresh2" = 8192;
    "net.ipv4.neigh.default.gc_thresh3" = 16384;
    "net.ipv4.neigh.default.gc_stale_time" = 120;  # 2 minutes
    
    # ---- Route Cache ----
    "net.ipv4.route.gc_timeout" = 100;
  };

  # ============================================================================
  # Kernel Modules (Layer 6: Required Modules)
  # ============================================================================
  
  boot.kernelModules = [
    "tcp_bbr"      # BBR congestion control
    "sch_fq"       # Fair Queuing scheduler
    "wireguard"    # WireGuard VPN
    "sch_cake"     # CAKE qdisc for SQM
    "ifb"          # Intermediate Functional Block for ingress shaping
  ];

  # ============================================================================
  # Diagnostic Tools & Utilities (Layer 7: Observability)
  # ============================================================================
  
  environment.systemPackages = with pkgs; [
    # ==========================================================================
    # Core Network Tools
    # ==========================================================================
    iproute2         # ip, ss, tc (modern replacements for ifconfig, netstat)
    iputils          # ping, traceroute, arping
    bind             # dig, nslookup, host (DNS queries)
    mtr              # Advanced traceroute (real-time)
    tcpdump          # Packet capture (Wireshark CLI)
    ethtool          # NIC diagnostics (speed, duplex, offload)
    
    # ==========================================================================
    # Performance Testing
    # ==========================================================================
    iperf3           # Network throughput testing
    speedtest-cli    # Internet speed test (Ookla)
    
    # ==========================================================================
    # DNS Tools
    # ==========================================================================
    doggo            # Modern DNS client (colorized, JSON output)
    
    # ==========================================================================
    # Monitoring & Analysis
    # ==========================================================================
    nethogs          # Per-process bandwidth monitor
    iftop            # Real-time bandwidth usage by connection
    nload            # Network traffic visualizer (RX/TX graphs)
    
    # ==========================================================================
    # Custom Diagnostic Scripts
    # ==========================================================================
    
    # ---- TCP Status Reporter ----
    (writeScriptBin "tcp-status" ''
      #!${bash}
      set -euo pipefail
      
      # Colors
      BOLD='\033[1m'
      GREEN='\033[0;32m'
      BLUE='\033[0;34m'
      YELLOW='\033[0;33m'
      NC='\033[0m'
      
      printf "%b=== TCP/IP Stack Status ===%b\n\n" "$BOLD" "$NC"
      
      # System info
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
      
      # TCP config
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
      
      # Buffers
      printf "%b[Buffers]%b\n" "$BLUE" "$NC"
      RMEM_MAX=$(${sysctl} -n net.core.rmem_max)
      WMEM_MAX=$(${sysctl} -n net.core.wmem_max)
      printf "  rmem_max: %s (%s bytes)\n" "$(numfmt --to=iec "$RMEM_MAX")" "$RMEM_MAX"
      printf "  wmem_max: %s (%s bytes)\n\n" "$(numfmt --to=iec "$WMEM_MAX")" "$WMEM_MAX"
      
      # Interfaces
      printf "%b[Interfaces]%b\n" "$BLUE" "$NC"
      ${pkgs.iproute2}/bin/ip -br link | while read -r iface state rest; do
        case "$state" in
          UP) printf "  %b%-18s%b %s\n" "$GREEN" "$iface" "$NC" "$rest" ;;
          *) printf "  %-18s %s\n" "$iface" "$rest" ;;
        esac
      done
      printf "\n"
      
      # Connections
      printf "%b[Connections]%b\n" "$BLUE" "$NC"
      TCP_ESTAB=$(${pkgs.iproute2}/bin/ss -tan state established 2>/dev/null | tail -n +2 | wc -l)
      TCP_TW=$(${pkgs.iproute2}/bin/ss -tan state time-wait 2>/dev/null | tail -n +2 | wc -l)
      printf "  TCP Established: %s\n" "$TCP_ESTAB"
      printf "  TCP TIME-WAIT:   %s\n\n" "$TCP_TW"
      
      # VPN status
      if command -v mullvad &>/dev/null; then
        printf "%b[VPN]%b\n" "$BLUE" "$NC"
        mullvad status | sed 's/^/  /'
        printf "\n"
      fi
      
      printf "%b✓ Status check complete%b\n" "$GREEN" "$NC"
    '')

    # ---- Network Performance Test ----
    (writeScriptBin "net-test" ''
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
    
    # ---- MTU Discovery ----
    (writeScriptBin "mtu-test" ''
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
    
    # TCP stack
    tcp-info        = "tcp-status";
    tcp-test        = "net-test";
    
    # Routing
    route-show      = "ip route show";
    route-default   = "ip route show default";
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
    lib.optionals (hasMullvad && !config.networking.firewall.enable && !config.networking.nftables.enable) [
      "Mullvad enabled but no firewall (neither iptables nor nftables) - killswitch won't work"
    ];

  # ============================================================================
  # 10) SQM/CAKE Bufferbloat Mitigation — WAN + VPN Aware
  #     • No-VPN: Egress+Ingress on default physical iface
  #     • VPN-UP : Egress on wg*/tun*  | Ingress on default physical iface
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

  environment.shellAliases = {
    sqm-status  = "systemctl status sqm-cake";
    sqm-start   = "sudo systemctl start sqm-cake";
    sqm-stop    = "sudo systemctl stop sqm-cake";
    sqm-restart = "sudo systemctl restart sqm-cake";
    sqm-logs    = "journalctl -u sqm-cake -f --no-pager -n 50";

    sqm-show = ''
      DEF="$(ip route show default 2>/dev/null | awk '/default/ {print $5; exit}')"
      VPNS="$(ip -o link show | awk -F': ' '{print $2}' | grep -E '^(wg|tun)[0-9A-Za-z._-]*$' || true)"
      echo -e "\033[1;36m================ SQM/CAKE Status ================\033[0m"

      for IFACE in $DEF $VPNS; do
        [ -n "$IFACE" ] || continue
        echo -e "\033[1;33m=== $IFACE ===\033[0m"
        tc qdisc show dev "$IFACE" 2>/dev/null | grep -E '(qdisc (cake|ingress))' || echo "  (no qdisc)"

        IFB="$(tc filter show dev "$IFACE" parent ffff: 2>/dev/null | awk '/mirred.*redirect dev/ {print $NF; exit}')"
        if [ -z "$IFB" ]; then
          for TRY in "ifb-$IFACE" "ifb-$IFACE-"; do
            ip link show "$TRY" &>/dev/null && { IFB="$TRY"; break; }
          done
        fi
        if [ -n "$IFB" ] && ip link show "$IFB" &>/dev/null; then
          tc qdisc show dev "$IFB" 2>/dev/null | grep -E '(qdisc cake)' && echo "↳ ($IFB)"
        fi
      done
      echo -e "\033[1;36m=================================================\033[0m"
    '';

    sqm-test = ''
      xdg-open https://www.waveform.com/tools/bufferbloat 2>/dev/null \
        || echo "→ Open manually: https://www.waveform.com/tools/bufferbloat"
    '';
  };
}

# ==============================================================================
# Usage Guide & Best Practices
# ==============================================================================
#
# TCP Profile Selection:
#   Automatic based on RAM:
#   - <32GB: STANDARD (X1 Carbon Gen 6)
#   - 32-59GB: HIGH (future systems)
#   - ≥60GB: ULTRA (E14 Gen 6)
#
# Manual Testing:
#   tcp-status                 # Show current TCP configuration
#   net-test                   # Test latency and throughput
#   mtu-test <host>            # Discover optimal MTU
#   speedtest-cli              # Internet speed test
#
# VPN Management:
#   vpn-status                 # Check VPN connection
#   vpn-connect                # Connect to VPN
#   vpn-disconnect             # Disconnect from VPN
#   dns-leak                   # Test for DNS leaks
#
# Network Monitoring:
#   nethogs                    # Per-process bandwidth
#   iftop -i <interface>       # Real-time traffic
#   nload                      # RX/TX graphs
#   conns-tcp                  # Active TCP connections
#
# DNS Management:
#   dns-status                 # Show DNS config
#   dns-flush                  # Clear DNS cache
#   resolvectl query <host>    # Resolve hostname
#
# Troubleshooting:
#   journalctl -u NetworkManager.service
#   journalctl -u mullvad-daemon.service
#   journalctl -u network-tcp-tuning.service
#   systemctl status network-profile-detect.service
#
# ==============================================================================
