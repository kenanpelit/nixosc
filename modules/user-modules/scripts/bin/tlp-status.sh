#!/usr/bin/env bash
# ==============================================================================
#  System Power / TLP Diagnostics
# ------------------------------------------------------------------------------
#  File: tlp-status.sh
#  Author: Kenan Pelit (with assistant help)
#  Purpose:
#    Single-shot report for power/thermal stack on ThinkPad/NixOS:
#      - Kernel cmdline (power-related params)
#      - TLP state/mode/CPU policy summary
#      - intel_pstate knobs (status/min/max/hwp_dynamic_boost)
#      - ACPI platform_profile (balanced/performance/low-power)
#      - PCIe ASPM policy (TLP and/or kernel)
#      - ThinkPad battery charge thresholds
#      - RAPL limits (journal + live sysfs snapshot)
#      - Thinkfan state + lm-sensors temps
#      - Mute/micmute LED brightness
#
#  Usage:
#      ./tlp-status.sh
#    (Some sections call `sudo tlp-stat`; use a sudo-enabled user for full info.)
#
#  Requirements:
#      - tlp (tlp-stat), systemd (journalctl), lm-sensors (sensors)  [optional]
#      - ThinkPad-specific bits (thinkpad_acpi) for thresholds/LEDs/fan (optional)
#
#  Exit codes:
#      0  Report printed (missing subsections are shown as "n/a")
#  Notes:
#      - The script is defensive (no hard failures): unavailable sections print "n/a".
#      - Harmless when run on non-ThinkPad devices; ThinkPad-only parts will be skipped.
# ==============================================================================

set -euo pipefail

section() {
	echo
	echo "=== $* ==="
}

section "Kernel cmdline"
cat /proc/cmdline 2>/dev/null || true

section "TLP State / Mode / CPU"
sudo tlp-stat -s 2>/dev/null | sed -n '1,6p' || echo "n/a"
# Mode / policy / EPP / min-max pct / driver / turbo
{
	sudo tlp-stat -p 2>/dev/null | sed -n '1,60p'
	sudo tlp-stat -c 2>/dev/null | sed -n '1,120p'
} | grep -E '(^Mode|policy|EPP|min|max|Driver|Turbo|intel_pstate)' || echo "n/a"

section "intel_pstate"
for f in status min_perf_pct max_perf_pct hwp_dynamic_boost; do
	p="/sys/devices/system/cpu/intel_pstate/$f"
	if [[ -f "$p" ]]; then
		printf "%-18s %s\n" "$f" "$(cat "$p" 2>/dev/null || echo "n/a")"
	fi
done
[[ -e /sys/devices/system/cpu/intel_pstate/status ]] || echo "n/a"

section "Platform profile (if any)"
if [[ -f /sys/firmware/acpi/platform_profile ]]; then
	cat /sys/firmware/acpi/platform_profile 2>/dev/null || echo "n/a"
else
	echo "n/a"
fi

section "PCIe ASPM policy"
# Önce tlp, yoksa kernel parametresi
if ! sudo tlp-stat -e 2>/dev/null | sed -n '/PCIe ASPM/,+3p' | sed '/^$/q' | grep .; then
	if [[ -f /sys/module/pcie_aspm/parameters/policy ]]; then
		echo -n "Kernel policy: "
		cat /sys/module/pcie_aspm/parameters/policy 2>/dev/null || echo "n/a"
	else
		echo "n/a"
	fi
fi

section "Battery thresholds (ThinkPad)"
show_thresh() {
	local pre="/sys/class/power_supply"
	local any=0
	for bat in "$pre"/BAT*; do
		[[ -d "$bat" ]] || continue
		any=1
		s="$bat/charge_control_start_threshold"
		e="$bat/charge_control_end_threshold"
		echo -n "$(basename "$bat"): "
		if [[ -r "$s" || -r "$e" ]]; then
			printf "start=%s end=%s\n" \
				"$(cat "$s" 2>/dev/null || echo '?')" \
				"$(cat "$e" 2>/dev/null || echo '?')"
		else
			echo "no thresholds"
		fi
	done
	return $any
}
if ! show_thresh; then
	sudo tlp-stat -b 2>/dev/null | sed -n '/charge_control_.*_threshold/p' | grep -E 'start|end' || echo "n/a"
fi

section "RAPL journal"
journalctl -t rapl-power -b --no-pager 2>/dev/null | tail -n 12 || echo "n/a"

section "RAPL files snapshot"
shopt -s nullglob
rapl_found=0
for R in /sys/class/powercap/intel-rapl:*; do
	[[ -d "$R" ]] || continue
	rapl_found=1
	PL1=$(cat "$R/constraint_0_power_limit_uw" 2>/dev/null || echo 0)
	PL2=$(cat "$R/constraint_1_power_limit_uw" 2>/dev/null || echo 0)
	printf "%s: PL1=%sW PL2=%sW\n" \
		"$(basename "$R")" "$((PL1 / 1000000))" "$((PL2 / 1000000))"
done
[[ "$rapl_found" -eq 1 ]] || echo "n/a"

section "Thinkfan & temps"
if systemctl is-active --quiet thinkfan 2>/dev/null; then
	echo "thinkfan: active"
else
	echo "thinkfan: inactive"
fi
# sensors bazı chip'lerde uyarı basıyor → sustur
if command -v sensors >/dev/null 2>&1; then
	sensors 2>/dev/null | sed -n '1,60p' || true
else
	echo "lm-sensors not installed"
fi
[[ -r /proc/acpi/ibm/fan ]] && head -n 1 /proc/acpi/ibm/fan 2>/dev/null || true

section "LED brightness (mute/micmute)"
for f in /sys/class/leds/platform::micmute/brightness /sys/class/leds/platform::mute/brightness; do
	if [[ -f "$f" ]]; then
		printf "%s: %s\n" "$f" "$(cat "$f" 2>/dev/null || echo "?")"
	fi
done
