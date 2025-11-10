# modules/core/sqm/default.nix
# ==============================================================================
# SQM/CAKE Bufferbloat Mitigation — WAN + VPN Aware
#   • No-VPN: Egress+Ingress on default physical iface
#   • VPN-UP : Egress on wg*/tun*  | Ingress on default physical iface
# ==============================================================================
{ config, lib, pkgs, ... }:

let
  # ---- Bandwidths (~85–90% of speedtest) ----
  uploadBandwidth    = "15mbit";   # WAN upstream
  downloadBandwidth  = "50mbit";   # WAN downstream
  enableNatOnWAN     = true;

  vpnUploadBandwidth   = "15mbit"; # VPN upstream
  vpnDownloadBandwidth = "50mbit"; # VPN downstream (applied on default iface)
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
      # WAN modu için: egress + ingress aynı iface üzerinde
      local iface="$1" ifb; ifb="$(ifb_name_for "$iface")"
      ''${TC} qdisc show dev "$iface" | ''${GREP} -q "qdisc cake"    || { error "[$iface] Egress CAKE missing"; return 1; }
      ''${TC} qdisc show dev "$iface" | ''${GREP} -q "qdisc ingress" || { error "[$iface] Ingress qdisc missing"; return 1; }
      ''${TC} qdisc show dev "$ifb"   | ''${GREP} -q "qdisc cake"    || { error "[$iface] IFB ($ifb) CAKE missing"; return 1; }
      log "[$iface] Verified (egress+ingress)"
    }

    verify_ingress_only() {
      # VPN modu için: default iface üzerinde SADECE ingress + IFB CAKE
      local iface="$1" ifb; ifb="$(ifb_name_for "$iface")"
      ''${TC} qdisc show dev "$iface" | ''${GREP} -q "qdisc ingress" || { error "[$iface] Ingress qdisc missing"; return 1; }
      ''${TC} qdisc show dev "$ifb"   | ''${GREP} -q "qdisc cake"    || { error "[$iface] IFB ($ifb) CAKE missing"; return 1; }
      log "[$iface] Verified (ingress-only)"
    }

    verify_egress_only() {
      # VPN arayüzleri için: SADECE egress CAKE
      local iface="$1"
      ''${TC} qdisc show dev "$iface" | ''${GREP} -q "qdisc cake" || { error "[$iface] Egress CAKE missing"; return 1; }
      log "[$iface] Verified (egress-only)"
    }

    setup_all() {
      log "Starting SQM/CAKE setup..."
      load_modules

      local def; def="$(detect_default_iface || true)"
      [ -n "$def" ] || { error "No default interface"; exit 1; }
      is_up "$def"  || { error "Default iface $def is not UP"; exit 1; }

      local vpns; vpns="$(detect_vpn_ifaces || true)"
      local vpn_up_any=0
      for v in $vpns; do
        if is_up "$v"; then vpn_up_any=1; break; fi
      done

      if [ "$vpn_up_any" -eq 1 ]; then
        log "Mode: VPN (egress on wg*/tun*, ingress on $def)"
        # temizle
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
in
{
  systemd.services.sqm-cake = {
    description   = "SQM/CAKE Bufferbloat Mitigation (WAN + VPN aware)";
    after         = [ "network-online.target" ];
    wants         = [ "network-online.target" ];
    wantedBy      = [ "multi-user.target" ];
    serviceConfig = {
      Type            = "oneshot";
      RemainAfterExit = true;
      ExecStart       = "${sqmScript} setup";
      ExecStop        = "${sqmScript} cleanup";
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

        # IFB çözümleme (güvenli)
        IFB="$(tc filter show dev "$IFACE" parent ffff: 2>/dev/null | awk '/mirred.*redirect dev/ {print $NF; exit}')"
        if [ -z "$IFB" ]; then
          for TRY in "ifb-$IFACE" "ifb-$IFACE-"; do
            ip link show "$TRY" &>/dev/null && { IFB="$TRY"; break; }
          done
        fi

        # IFB varsa göster
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


