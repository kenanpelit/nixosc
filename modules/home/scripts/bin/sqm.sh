#!/usr/bin/env bash
#===============================================================================
#   Script: Automatic SQM/CAKE Setup (WAN + VPN aware)
#   Version: 2.0.1
#   Date: 2025-11-10
#   Author: Kenan Pelit
#   Desc : WAN'da ve VPN'de (wg*/tun*) bufferbloat azaltımı.
#          - VPN KAPALI:  egress+ingress = default fiziksel arayüz
#          - VPN AÇIK   : egress = tüm wg*/tun*   | ingress = default fiziksel
#   License: MIT
#===============================================================================
set -euo pipefail

#===============================================================================
# Config (env ile değiştirilebilir; ör. WAN_DOWN=40mbit VPN_UP=10mbit ./sqm.sh)
#===============================================================================
WAN_UP="${WAN_UP:-15mbit}"
WAN_DOWN="${WAN_DOWN:-50mbit}"
WAN_NAT="${WAN_NAT:-1}" # 1=nat, 0=nonat

VPN_UP="${VPN_UP:-15mbit}"
VPN_DOWN="${VPN_DOWN:-50mbit}"
VPN_NAT="${VPN_NAT:-0}" # genelde 0

MEMLIMIT="${MEMLIMIT:-32Mb}"

#===============================================================================
# Tools & logging
#===============================================================================
log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"; }
error() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $*" >&2; }
need() { command -v "$1" >/dev/null 2>&1 || {
	error "missing: $1"
	exit 1
}; }

#===============================================================================
# Detect
#===============================================================================
default_iface() {
	ip route show default 2>/dev/null | awk '/default/ {print $5; exit}'
}
vpn_ifaces() {
	ip -o link show | awk -F': ' '{print $2}' | grep -E '^(wg|tun)[0-9A-Za-z._-]*$' || true
}
is_up() {
	# bayraklarda UP var mı? (state UNKNOWN olabilir; WireGuard böyle çalışır)
	ip -o link show "$1" 2>/dev/null | grep -q '<[^>]*UP[^>]*>'
}

#===============================================================================
# IFB helpers
#===============================================================================
ifb_name_for() { echo "ifb-$1" | tr -c '[:alnum:]._-' '-' | sed 's/-\{2,\}/-/g'; }

clean_iface() {
	local i="$1" ifb
	ifb="$(ifb_name_for "$i")"
	log "Cleaning qdisc on $i and $ifb"
	tc qdisc del dev "$i" root 2>/dev/null || true
	tc qdisc del dev "$i" ingress 2>/dev/null || true
	tc qdisc del dev "$ifb" root 2>/dev/null || true
	ip link set dev "$ifb" down 2>/dev/null || true
	ip link del "$ifb" type ifb 2>/dev/null || true
}

#===============================================================================
# Setup primitives
#===============================================================================
setup_egress() {
	local i="$1" bw="$2" nat="$3"
	log "[$i] Set egress CAKE bw=$bw nat=$([ "$nat" = "1" ] && echo on || echo off)"
	local opts=(bandwidth "$bw" diffserv4 triple-isolate wash ack-filter memlimit "$MEMLIMIT")
	[ "$nat" = "1" ] && opts+=(nat)
	tc qdisc add dev "$i" root cake "${opts[@]}"
}

setup_ingress_on_iface() {
	# indirimi her zaman gerçek çıkış arayüzünde (default iface) yap
	local i="$1" bw="$2" nat="$3"
	local ifb
	ifb="$(ifb_name_for "$i")"
	log "[$i] Set ingress via $ifb bw=$bw nat=$([ "$nat" = "1" ] && echo on || echo off)"

	ip link add "$ifb" type ifb 2>/dev/null || true
	ip link set dev "$ifb" up

	tc qdisc add dev "$i" handle ffff: ingress 2>/dev/null || true
	tc filter add dev "$i" parent ffff: protocol all prio 10 u32 match u32 0 0 \
		action mirred egress redirect dev "$ifb"

	local opts=(bandwidth "$bw" diffserv4 triple-isolate wash ingress memlimit "$MEMLIMIT")
	[ "$nat" = "1" ] && opts+=(nat)
	tc qdisc add dev "$ifb" root cake "${opts[@]}"
}

#===============================================================================
# Verify helpers
#===============================================================================
verify_pair() {
	# WAN modu için: egress + ingress aynı iface üzerinde
	local i="$1" ifb
	ifb="$(ifb_name_for "$i")"
	tc qdisc show dev "$i" | grep -q "qdisc cake" || {
		error "[$i] egress cake yok"
		return 1
	}
	tc qdisc show dev "$i" | grep -q "qdisc ingress" || {
		error "[$i] ingress yok"
		return 1
	}
	tc qdisc show dev "$ifb" | grep -q "qdisc cake" || {
		error "[$i] $ifb cake yok"
		return 1
	}
	log "[$i] Verified (egress+ingress)"
}

verify_ingress_only() {
	# VPN modu: default iface üzerinde SADECE ingress + IFB CAKE
	local i="$1" ifb
	ifb="$(ifb_name_for "$i")"
	tc qdisc show dev "$i" | grep -q "qdisc ingress" || {
		error "[$i] ingress yok"
		return 1
	}
	tc qdisc show dev "$ifb" | grep -q "qdisc cake" || {
		error "[$i] $ifb cake yok"
		return 1
	}
	log "[$i] Verified (ingress-only)"
}

verify_egress_only() {
	# VPN arayüzleri: SADECE egress CAKE
	local i="$1"
	tc qdisc show dev "$i" | grep -q "qdisc cake" || {
		error "[$i] egress cake yok"
		return 1
	}
	log "[$i] Verified (egress-only)"
}

#===============================================================================
# Modes
#===============================================================================
setup_mode() {
	need ip
	need tc
	need grep
	need awk
	need sed
	need tr

	local def
	def="$(default_iface || true)"
	[ -n "$def" ] || {
		error "Default route arayüzü yok"
		exit 1
	}
	is_up "$def" || {
		error "Default arayüz UP değil: $def"
		exit 1
	}

	# VPN açık mı? (en az bir wg*/tun* UP)
	local any_vpn_up=0 vpns
	vpns="$(vpn_ifaces)"
	for v in $vpns; do
		if is_up "$v"; then
			any_vpn_up=1
			break
		fi
	done

	if [ "$any_vpn_up" -eq 1 ]; then
		log "Mode: VPN — egress on wg*/tun*, ingress on $def"
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
		log "Mode: WAN — egress+ingress on $def"
		clean_iface "$def"
		setup_egress "$def" "$WAN_UP" "$WAN_NAT"
		setup_ingress_on_iface "$def" "$WAN_DOWN" "$WAN_NAT"
		verify_pair "$def"
	fi

	log "Done."
}

cleanup_all() {
	local def
	def="$(default_iface || true)"
	[ -n "$def" ] && clean_iface "$def"
	local vpns
	vpns="$(vpn_ifaces)"
	for v in $vpns; do clean_iface "$v"; done
	# kalan tüm ifb-*'leri temizle
	ip -o link show | awk -F': ' '{print $2}' | grep -E '^ifb-' | while read -r f; do
		tc qdisc del dev "$f" root 2>/dev/null || true
		ip link set dev "$f" down 2>/dev/null || true
		ip link del "$f" type ifb 2>/dev/null || true
	done
	log "Cleanup completed."
}

status_show() {
	local def
	def="$(default_iface || true)"
	local vpns
	vpns="$(vpn_ifaces)"
	echo "================ SQM Status ================"
	echo "Default : ${def:-N/A}"
	echo "VPNs    : $(echo $vpns | tr '\n' ' ')"
	echo "WAN_UP/DOWN=${WAN_UP}/${WAN_DOWN}  VPN_UP/DOWN=${VPN_UP}/${VPN_DOWN}"
	echo "--------------------------------------------"
	for i in $def $vpns; do
		[ -n "$i" ] || continue
		local ifb="(no-ifb)"
		ifb="$(ifb_name_for "$i")"
		echo "=== $i ==="
		tc qdisc show dev "$i" 2>/dev/null | grep -E "(qdisc (cake|ingress))" || echo "  (no qdisc)"
		tc qdisc show dev "$ifb" 2>/dev/null | grep -E "(qdisc cake)" || true
	done
	echo "============================================"
}

#===============================================================================
# Main
#===============================================================================
usage() {
	cat <<USAGE
Usage: $0 {setup|cleanup|status}

Env vars:
  WAN_UP (def: $WAN_UP)       WAN upstream
  WAN_DOWN (def: $WAN_DOWN)   WAN downstream
  WAN_NAT (def: $WAN_NAT)     1/0

  VPN_UP (def: $VPN_UP)       VPN upstream (wg*/tun*)
  VPN_DOWN (def: $VPN_DOWN)   VPN downstream (applies on default iface)
  VPN_NAT (def: $VPN_NAT)     1/0

Examples:
  WAN_DOWN=40mbit VPN_DOWN=45mbit $0 setup
USAGE
}

cmd="${1:-setup}"
case "$cmd" in
setup) setup_mode ;;
cleanup) cleanup_all ;;
status) status_show ;;
-h | --help | help) usage ;;
*)
	usage
	exit 1
	;;
esac
