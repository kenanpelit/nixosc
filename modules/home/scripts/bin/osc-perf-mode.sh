#!/usr/bin/env bash
# ThinkPad Performance Control (intel_pstate=active + EPP aware, RAPL windows)
# - Balanced: enable cpu-power-limit.timer (module manages EPP/RAPL)
# - Performance/Powersave: disable timer (manual control stays in place)
# - Meteor Lake perf PL2 = 60W (short boosts), writes RAPL time windows.

set -euo pipefail

# ── Colors ────────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
DIM='\033[2m'
NC='\033[0m'

# ── Helpers ───────────────────────────────────────────────────────────────────
is_root() { [[ $EUID -eq 0 ]]; }
need_root() { is_root || {
	echo -e "${RED}This script must be run with sudo${NC}"
	exit 1
}; }
have() { command -v "$1" >/dev/null 2>&1; }

detect_cpu() {
	local model
	model="$(lscpu 2>/dev/null | grep -F 'Model name' | cut -d: -f2- | tr -s ' ' | tr -d '\n' || true)"
	if echo "$model" | grep -qiE 'Core *Ultra|155H|Meteor *Lake'; then
		echo "meteorlake"
	elif echo "$model" | grep -qiE '8650U|8550U|8350U|8250U|Kaby *Lake'; then
		echo "kabylaker"
	else echo "kabylaker"; fi
}

get_power_source() {
	for PS in /sys/class/power_supply/AC*/online /sys/class/power_supply/AC/online /sys/class/power_supply/AC0/online; do
		[[ -f "$PS" ]] && {
			cat "$PS"
			return
		}
	done
	echo "0"
}

pstate_mode() {
	# Returns: active|passive|unknown
	local m="unknown"
	if grep -qw active /sys/devices/system/cpu/cpufreq/policy0/scaling_driver 2>/dev/null; then
		m="active"
	elif [[ -f /sys/devices/system/cpu/intel_pstate/status ]]; then
		m="$(cat /sys/devices/system/cpu/intel_pstate/status 2>/dev/null || echo unknown)"
	fi
	echo "$m"
}

rapl_base="/sys/class/powercap/intel-rapl:0"
rapl_ok() { [[ -d "$rapl_base" ]]; }
read_pl() {
	local n="$1"
	cat "$rapl_base/constraint_${n}_power_limit_uw" 2>/dev/null || echo 0
}
write_pl() {
	local n="$1" watts="$2"
	echo $((watts * 1000000)) >"$rapl_base/constraint_${n}_power_limit_uw" 2>/dev/null || true
}
write_tw() { # time window (µs)
	local n="$1" us="$2"
	echo "$us" >"$rapl_base/constraint_${n}_time_window_us" 2>/dev/null || true
}

set_governor_all() {
	local gov="$1"
	for g in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
		[[ -f "$g" ]] && echo "$gov" >"$g" 2>/dev/null || true
	done
}

set_epp_all() {
	local epp="$1"
	for p in /sys/devices/system/cpu/cpufreq/policy*; do
		[[ -f "$p/energy_performance_preference" ]] && echo "$epp" >"$p/energy_performance_preference" 2>/dev/null || true
	done
}

set_min_all() {
	local min="$1"
	for p in /sys/devices/system/cpu/cpufreq/policy*; do
		[[ -n "$min" && -f "$p/scaling_min_freq" ]] && echo "$min" >"$p/scaling_min_freq" 2>/dev/null || true
	done
}

set_max_to_cpuinfo() {
	for p in /sys/devices/system/cpu/cpufreq/policy*; do
		if [[ -f "$p/cpuinfo_max_freq" && -f "$p/scaling_max_freq" ]]; then
			cat "$p/cpuinfo_max_freq" >"$p/scaling_max_freq" 2>/dev/null || true
		fi
	done
}

set_turbo() {
	local onoff="$1" # 1 = disable turbo, 0 = enable turbo
	[[ -f /sys/devices/system/cpu/intel_pstate/no_turbo ]] && echo "$onoff" >/sys/devices/system/cpu/intel_pstate/no_turbo 2>/dev/null || true
}

timer_enable() { systemctl enable --now cpu-power-limit.timer 2>/dev/null || true; }
timer_disable() { systemctl disable --now cpu-power-limit.timer 2>/dev/null || true; }
service_reapply() { systemctl restart cpu-power-limit.service 2>/dev/null || true; }

timer_status() {
	local active="inactive" last=""
	systemctl is-enabled cpu-power-limit.timer >/dev/null 2>&1 && active="enabled" || active="disabled"
	last="$(systemctl show -p LastTriggerUSec --value cpu-power-limit.timer 2>/dev/null || true)"
	[[ -z "$last" || "$last" = "0" ]] && last="never"
	echo "$active|$last"
}

warn_if_not_active() {
	local mode
	mode="$(pstate_mode)"
	if [[ "$mode" != "active" ]]; then
		echo -e "${YELLOW}Note:${NC} intel_pstate mode seems to be '${mode}'. Meteor Lake generally prefers ${GREEN}active${NC} for HWP/EPP."
	fi
}

# ── Status ────────────────────────────────────────────────────────────────────
status() {
	echo -e "${BLUE}=== Current System Status ===${NC}"
	local cpu ps gov temp pl1 pl2 epp0 mems tstat tlast

	cpu="$(detect_cpu)"
	ps="$(get_power_source)"
	echo -e "CPU Type: ${YELLOW}${cpu}${NC}"
	echo -e "Power Source: ${YELLOW}$([[ $ps = 1 ]] && echo AC || echo Battery)${NC}"

	# governor
	if [[ -f /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor ]]; then
		gov="$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor)"
		echo -e "Governor: ${YELLOW}${gov}${NC}"
	else
		echo -e "Governor: ${RED}Not available${NC}"
	fi

	# EPP (policy0 sample + note)
	if [[ -f /sys/devices/system/cpu/cpufreq/policy0/energy_performance_preference ]]; then
		epp0="$(cat /sys/devices/system/cpu/cpufreq/policy0/energy_performance_preference)"
		echo -e "EPP (policy0): ${YELLOW}${epp0}${NC} ${DIM}(applied to all policies)${NC}"
	fi

	# Turbo
	if [[ -f /sys/devices/system/cpu/intel_pstate/no_turbo ]]; then
		[[ "$(cat /sys/devices/system/cpu/intel_pstate/no_turbo)" = "0" ]] &&
			echo -e "Turbo: ${GREEN}Enabled${NC}" || echo -e "Turbo: ${RED}Disabled${NC}"
	fi

	# mem_sleep
	if [[ -f /sys/power/mem_sleep ]]; then
		mems="$(cat /sys/power/mem_sleep)"
		echo -e "mem_sleep: ${YELLOW}${mems}${NC}"
	fi

	# Frequencies (first 8 cores)
	echo -e "\nCPU Frequencies:"
	if grep -q "cpu MHz" /proc/cpuinfo 2>/dev/null; then
		grep "cpu MHz" /proc/cpuinfo | head -8 | awk '{printf "  Core %d: %s MHz\n", NR-1, $4}'
	else
		echo "  Frequency info not available"
	fi

	# RAPL
	if rapl_ok; then
		pl1="$(read_pl 0)"
		pl2="$(read_pl 1)"
		echo -e "\nPower Limits:"
		echo "  PL1: $((pl1 / 1000000))W"
		echo "  PL2: $((pl2 / 1000000))W"
	else
		echo -e "\nPower Limits: ${RED}RAPL not available${NC}"
	fi

	# Temp
	temp="$(cat /sys/class/thermal/thermal_zone*/temp 2>/dev/null | sort -rn | head -1 || echo 0)"
	echo -e "\nCPU Temp: ${YELLOW}$((temp / 1000))°C${NC}"

	# Battery thresholds
	if [[ -f /sys/class/power_supply/BAT0/charge_control_start_threshold ]]; then
		local s e
		s=$(cat /sys/class/power_supply/BAT0/charge_control_start_threshold 2>/dev/null || echo "N/A")
		e=$(cat /sys/class/power_supply/BAT0/charge_control_end_threshold 2>/dev/null || echo "N/A")
		echo -e "Battery Thresholds: ${YELLOW}Start: ${s}% | Stop: ${e}%${NC}"
	fi

	# Timer info
	IFS='|' read -r tstat tlast < <(timer_status)
	echo -e "cpu-power-limit.timer: ${YELLOW}${tstat}${NC} ${DIM}(last: ${tlast})${NC}"

	warn_if_not_active
}

# ── Profiles ──────────────────────────────────────────────────────────────────
apply_profile_balanced() {
	echo -e "${YELLOW}Applying BALANCED (module-managed)${NC}"
	timer_enable
	service_reapply
}

apply_profile_performance() {
	echo -e "${GREEN}Applying PERFORMANCE (manual)${NC}"
	timer_disable

	local cpu
	cpu="$(detect_cpu)"
	# Governor + EPP
	set_governor_all performance
	set_epp_all performance
	set_min_all 1600000
	set_max_to_cpuinfo
	set_turbo 0

	# RAPL + time windows
	if rapl_ok; then
		case "$cpu" in
		meteorlake)
			write_pl 0 42
			write_pl 1 60
			;; # PL2 60W for extra headroom
		kabylaker)
			write_pl 0 25
			write_pl 1 35
			;;
		*)
			write_pl 0 25
			write_pl 1 35
			;;
		esac
		write_tw 0 28000000 # ~28s sustained window
		write_tw 1 10000    # 10ms turbo window
		echo "RAPL applied (PL1/PL2 + time windows)"
	fi
}

apply_profile_powersave() {
	echo -e "${BLUE}Applying POWERSAVE (manual)${NC}"
	timer_disable

	local cpu
	cpu="$(detect_cpu)"
	set_governor_all powersave
	set_epp_all power
	set_min_all 800000
	set_max_to_cpuinfo
	set_turbo 1

	if rapl_ok; then
		case "$cpu" in
		meteorlake)
			write_pl 0 28
			write_pl 1 42
			;;
		kabylaker)
			write_pl 0 15
			write_pl 1 25
			;;
		*)
			write_pl 0 15
			write_pl 1 25
			;;
		esac
		write_tw 0 28000000
		write_tw 1 10000
		echo "RAPL applied (battery-friendly limits + time windows)"
	fi
}

apply_custom() {
	echo -e "${YELLOW}Custom Settings${NC}"
	read -rp "Governor (performance/powersave/schedutil[if avail], default=performance): " g
	g="${g:-performance}"
	set_governor_all "$g"

	read -rp "EPP (performance/balance_performance/balance_power/power, default=balance_performance): " e
	e="${e:-balance_performance}"
	set_epp_all "$e"

	read -rp "Turbo (on/off, default=on): " t
	t="${t:-on}"
	[[ "$t" == "on" ]] && set_turbo 0 || set_turbo 1

	if rapl_ok; then
		read -rp "PL1 watts (empty=skip): " pl1
		read -rp "PL2 watts (empty=skip): " pl2
		[[ -n "${pl1:-}" ]] && write_pl 0 "$pl1"
		[[ -n "${pl2:-}" ]] && write_pl 1 "$pl2"
		read -rp "Set PL1 time window µs (empty=skip): " tw1
		read -rp "Set PL2 time window µs (empty=skip): " tw2
		[[ -n "${tw1:-}" ]] && write_tw 0 "$tw1"
		[[ -n "${tw2:-}" ]] && write_tw 1 "$tw2"
	fi

	read -rp "Set scaling_min_freq (kHz, empty=skip): " mn
	[[ -n "${mn:-}" ]] && set_min_all "$mn"

	echo "Disable auto timer to keep your custom values? (y/N)"
	read -r ans
	[[ "${ans,,}" == "y" ]] && timer_disable || timer_enable

	echo -e "${GREEN}Custom settings applied${NC}"
}

reset_defaults() {
	echo -e "${YELLOW}Resetting to module defaults (timer ON + service re-apply)…${NC}"
	timer_enable
	service_reapply
	echo -e "${GREEN}Done${NC}"
}

# ── UI ────────────────────────────────────────────────────────────────────────
menu() {
	echo -e "\n${BLUE}=== ThinkPad Performance Control ===${NC}"
	echo "1) Show current status"
	echo "2) PERFORMANCE mode (manual, timer OFF, PL2=60W on Meteor Lake)"
	echo "3) BALANCED mode (module-managed, timer ON)"
	echo "4) POWERSAVE mode (manual, timer OFF)"
	echo "5) CUSTOM settings"
	echo "6) RESET to module defaults"
	echo "7) Exit"
	echo -n "Select option: "
}

main() {
	if [[ $# -eq 0 ]]; then
		while true; do
			menu
			read -r choice
			case "$choice" in
			1) status ;;
			2)
				need_root
				apply_profile_performance
				status
				;;
			3)
				need_root
				apply_profile_balanced
				status
				;;
			4)
				need_root
				apply_profile_powersave
				status
				;;
			5)
				need_root
				apply_custom
				status
				;;
			6)
				need_root
				reset_defaults
				status
				;;
			7) exit 0 ;;
			*) echo -e "${RED}Invalid option${NC}" ;;
			esac
			echo -e "\nPress Enter to continue…"
			read -r
			clear
		done
	else
		case "$1" in
		status) status ;;
		performance)
			need_root
			apply_profile_performance
			status
			;;
		balanced)
			need_root
			apply_profile_balanced
			status
			;;
		powersave)
			need_root
			apply_profile_powersave
			status
			;;
		custom)
			need_root
			apply_custom
			status
			;;
		reset)
			need_root
			reset_defaults
			status
			;;
		--help | -h)
			cat <<EOF
Usage: $0 [command]

Commands:
  status        Show current status
  performance   Manual performance (timer OFF, EPP=performance, PL2=60W on Meteor Lake)
  balanced      Module-managed defaults (timer ON)
  powersave     Manual battery saver (timer OFF, EPP=power)
  custom        Interactive custom settings (incl. RAPL time windows)
  reset         Re-enable timer and re-apply module defaults
EOF
			;;
		*)
			echo "Invalid command. Use --help"
			exit 1
			;;
		esac
	fi
}

trap 'echo -e "\n${RED}Interrupted.${NC}"; exit 1' INT TERM
main "$@"
