#!/usr/bin/env bash
set -euo pipefail

SCRIPT_NAME="$(basename "$0")"

if [[ -t 1 ]]; then
	GRN=$'\033[0;32m'
	YLW=$'\033[0;33m'
	RED=$'\033[0;31m'
	CYN=$'\033[0;36m'
	DIM=$'\033[0;2m'
	RST=$'\033[0m'
else
	GRN='' YLW='' RED='' CYN='' DIM='' RST=''
fi

have() { command -v "$1" >/dev/null 2>&1; }

hr() { printf "%s\n" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"; }

print_kv() {
	local key="$1"
	shift
	printf "%s%s:%s %s\n" "${CYN}" "$key" "${RST}" "$*"
}

get_nameservers() {
	# Parse /etc/resolv.conf in a conservative way.
	# Only prints the IP/host part after "nameserver".
	[[ -r /etc/resolv.conf ]] || return 0
	awk '$1=="nameserver"{print $2}' /etc/resolv.conf 2>/dev/null || true
}

dig_short() {
	# Usage: dig_short <server|empty> <name> <type>
	local server="$1"
	local name="$2"
	local qtype="${3:-A}"

	if ! have dig; then
		echo "${DIM}<dig not installed>${RST}"
		return 0
	fi

	local out
	if [[ -n "$server" ]]; then
		out="$(dig @"$server" "$name" "$qtype" +tries=1 +timeout=2 +short 2>/dev/null || true)"
	else
		out="$(dig "$name" "$qtype" +tries=1 +timeout=2 +short 2>/dev/null || true)"
	fi

	if [[ -n "$out" ]]; then
		echo "$out" | head -n 3
	else
		echo "${DIM}<no answer>${RST}"
	fi
}

show_service_state() {
	local unit="$1"
	if ! have systemctl; then
		echo "${DIM}<systemctl not available>${RST}"
		return 0
	fi

	if systemctl list-unit-files "$unit" >/dev/null 2>&1; then
		if systemctl is-active --quiet "$unit" 2>/dev/null; then
			echo "${GRN}active${RST}"
		else
			local state
			state="$(systemctl show -p ActiveState --value "$unit" 2>/dev/null || echo "unknown")"
			echo "${YLW}${state}${RST}"
		fi
	else
		echo "${DIM}not installed${RST}"
	fi
}

show_dns_status() {
	echo "=== DNS STATUS ==="
	print_kv "Time" "$(date -Is)"

	hr
	print_kv "systemd-resolved" "$(show_service_state systemd-resolved.service)"
	print_kv "blocky" "$(show_service_state blocky.service)"
	print_kv "mullvad-daemon" "$(show_service_state mullvad-daemon.service)"

	if have mullvad; then
		local mv_state
		mv_state="$(mullvad status 2>/dev/null | head -n 1 || true)"
		print_kv "mullvad" "${mv_state:-<unknown>}"
	fi

	hr
	echo "${CYN}/etc/resolv.conf${RST}"
	if [[ -r /etc/resolv.conf ]]; then
		sed -n '1,40p' /etc/resolv.conf
	else
		echo "${DIM}<not readable>${RST}"
	fi

	hr
	if have resolvconf; then
		echo "${CYN}resolvconf sources (-i)${RST}"
		resolvconf -i 2>/dev/null || true
	else
		echo "${DIM}resolvconf not installed${RST}"
	fi

	hr
	echo "${CYN}Resolution sanity${RST}"
	print_kv "dig example.com (default)" "$(dig_short "" example.com A)"
	if have getent; then
		print_kv "getent ahosts example.com" "$(getent ahosts example.com 2>/dev/null | head -n 1 || echo "<no answer>")"
	else
		print_kv "getent" "<not available>"
	fi

	hr
	echo "${CYN}Per-nameserver tests${RST}"
	local ns_list=()
	while IFS= read -r ns; do
		[[ -n "$ns" ]] || continue
		ns_list+=("$ns")
	done < <(get_nameservers)

	if [[ ${#ns_list[@]} -eq 0 ]]; then
		echo "${DIM}<no nameserver entries found>${RST}"
	else
		for ns in "${ns_list[@]}"; do
			echo "— ${CYN}${ns}${RST}"
			echo "  example.com A:      $(dig_short "$ns" example.com A)"
			echo "  ad.doubleclick.net: $(dig_short "$ns" ad.doubleclick.net A)"
			echo "  www.youtube.com:    $(dig_short "$ns" www.youtube.com A)"
		done
	fi

	hr
	echo "${DIM}Tips:${RST}"
	echo "  • Blocky ON  → /etc/resolv.conf should be 127.0.0.1/::1"
	echo "  • Mullvad ON → /etc/resolv.conf should include 100.64.0.3 (Mullvad DNS)"
	echo "  • No systemd-resolved → resolvectl won't work (expected)"
}

usage() {
	cat <<EOF
Usage:
  ${SCRIPT_NAME} status

Commands:
  status   Show DNS resolver state and quick query tests (default)
EOF
}

main() {
	case "${1:-status}" in
	status) show_dns_status ;;
	-h | --help | help) usage ;;
	*)
		echo "${RED}Unknown command:${RST} ${1:-}" >&2
		usage >&2
		exit 2
		;;
	esac
}

main "$@"

