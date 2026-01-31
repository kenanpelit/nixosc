#!/usr/bin/env bash
# ==============================================================================
# osc-perf-mode: Safe power profile switcher (PPD)
# ------------------------------------------------------------------------------
# This is intentionally minimal: it uses power-profiles-daemon via
# `powerprofilesctl` and avoids directly touching low-level CPU knobs.
# ==============================================================================

set -euo pipefail

have() { command -v "$1" >/dev/null 2>&1; }

die() {
	echo "Error: $*" >&2
	exit 1
}

need_ppd() {
	have powerprofilesctl || die "powerprofilesctl not found (enable power-profiles-daemon / install power-profiles-daemon)"
}

ppd_list_names() {
	powerprofilesctl list 2>/dev/null | awk '/\\*/ {print $2}' | xargs echo 2>/dev/null || true
}

cmd_help() {
	cat <<'EOF'
osc-perf-mode - power-profiles-daemon (PPD) profile helper

Usage:
  osc-perf-mode status
  osc-perf-mode list
  osc-perf-mode get
  osc-perf-mode set <power-saver|balanced|performance>
  osc-perf-mode powersave
  osc-perf-mode balanced
  osc-perf-mode performance
EOF
}

cmd_status() {
	if ! have powerprofilesctl; then
		echo "powerprofilesctl: not installed"
		return 0
	fi

	cur="$(powerprofilesctl get 2>/dev/null || echo "")"
	[[ -n "$cur" ]] && echo "Current profile: $cur"

	avail="$(ppd_list_names)"
	[[ -n "$avail" ]] && echo "Available: $avail"

	pp_sysfs="$(cat /sys/firmware/acpi/platform_profile 2>/dev/null || true)"
	[[ -n "$pp_sysfs" ]] && echo "Platform Profile: $pp_sysfs"

	epp="$(cat /sys/devices/system/cpu/cpufreq/policy0/energy_performance_preference 2>/dev/null || true)"
	[[ -n "$epp" ]] && echo "EPP (policy0): $epp"
}

cmd_set() {
	need_ppd
	profile="${1:-}"
	[[ -n "$profile" ]] || die "missing profile (power-saver|balanced|performance)"

	case "$profile" in
	powersave | power-saver) profile="power-saver" ;;
	esac

	powerprofilesctl set "$profile"
}

cmd="${1:-help}"
shift || true

case "$cmd" in
help | -h | --help) cmd_help ;;
status) cmd_status ;;
list)
	need_ppd
	ppd_list_names
	;;
get)
	need_ppd
	powerprofilesctl get
	;;
set) cmd_set "$@" ;;
performance) cmd_set performance ;;
balanced) cmd_set balanced ;;
powersave | power-saver) cmd_set power-saver ;;
*)
	cmd_help
	exit 2
	;;
esac
