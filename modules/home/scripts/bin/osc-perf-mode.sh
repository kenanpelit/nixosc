#!/usr/bin/env bash
# ThinkPad Performance Control (intel_pstate passive mode + governor control)
# - Optimized for passive mode operation
# - Fixed RAPL power reading bug
# - Enhanced status reporting

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
	else echo "generic"; fi
}

get_power_source() {
	for PS in /sys/class/power_supply/AC*/online /sys/class/power_supply/ADP*/online; do
		[[ -f "$PS" ]] && {
			cat "$PS"
			return
		}
	done
	echo "0"
}

pstate_mode() {
	# Returns: active|passive|unknown
	if [[ -f /sys/devices/system/cpu/intel_pstate/status ]]; then
		cat /sys/devices/system/cpu/intel_pstate/status 2>/dev/null || echo "unknown"
	else
		echo "unknown"
	fi
}

rapl_base="/sys/class/powercap/intel-rapl:0"
rapl_ok() { [[ -d "$rapl_base" ]]; }

# FIXED: Proper RAPL power reading with error handling
read_pl() {
	local n="$1"
	local file="$rapl_base/constraint_${n}_power_limit_uw"
	if [[ -r "$file" ]]; then
		local value
		value=$(cat "$file" 2>/dev/null || echo "0")
		# Convert µW to W and ensure it's a valid number
		if [[ "$value" =~ ^[0-9]+$ ]] && [[ "$value" -gt 0 ]]; then
			echo "$((value / 1000000))"
		else
			echo "0"
		fi
	else
		echo "0"
	fi
}

write_pl() {
	local n="$1" watts="$2"
	local file="$rapl_base/constraint_${n}_power_limit_uw"
	if [[ -w "$file" ]]; then
		echo $((watts * 1000000)) >"$file" 2>/dev/null && return 0
	fi
	return 1
}

write_tw() { # time window (µs)
	local n="$1" us="$2"
	local file="$rapl_base/constraint_${n}_time_window_us"
	[[ -w "$file" ]] && echo "$us" >"$file" 2>/dev/null || true
}

set_governor_all() {
	local gov="$1"
	for g in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
		[[ -w "$g" ]] && echo "$gov" >"$g" 2>/dev/null || true
	done
}

set_epp_all() {
	local epp="$1"
	for p in /sys/devices/system/cpu/cpufreq/policy*; do
		[[ -w "$p/energy_performance_preference" ]] && echo "$epp" >"$p/energy_performance_preference" 2>/dev/null || true
	done
}

set_min_all() {
	local min="$1"
	for p in /sys/devices/system/cpu/cpufreq/policy*; do
		[[ -n "$min" && -w "$p/scaling_min_freq" ]] && echo "$min" >"$p/scaling_min_freq" 2>/dev/null || true
	done
}

set_max_to_cpuinfo() {
	for p in /sys/devices/system/cpu/cpufreq/policy*; do
		if [[ -f "$p/cpuinfo_max_freq" && -w "$p/scaling_max_freq" ]]; then
			cat "$p/cpuinfo_max_freq" >"$p/scaling_max_freq" 2>/dev/null || true
		fi
	done
}

set_turbo() {
	local onoff="$1" # 1 = disable turbo, 0 = enable turbo
	[[ -w /sys/devices/system/cpu/intel_pstate/no_turbo ]] && echo "$onoff" >/sys/devices/system/cpu/intel_pstate/no_turbo 2>/dev/null || true
}

timer_status() {
	local active="disabled" last="never"
	if systemctl is-enabled cpu-power-limit.timer >/dev/null 2>&1; then
		active="enabled"
		last="$(systemctl show -p LastTriggerUSec --value cpu-power-limit.timer 2>/dev/null || echo "never")"
		[[ "$last" = "0" ]] && last="never"
	fi
	echo "$active|$last"
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

	# Frequencies (current scaling_cur_freq)
	echo -e "\nCPU Frequencies:"
	local i=0
	for f in /sys/devices/system/cpu/cpu[0-9]*/cpufreq/scaling_cur_freq; do
		[[ -f "$f" ]] || continue
		local mhz
		mhz=$(($(cat "$f") / 1000))
		printf "  Core %2d: %4d MHz\n" "$i" "$mhz"
		i=$((i + 1))
		[[ $i -eq 8 ]] && break
	done

	# FIXED: RAPL power reading with proper error handling
	if rapl_ok; then
		pl1="$(read_pl 0)"
		pl2="$(read_pl 1)"
		echo -e "\nPower Limits:"
		if [[ "$pl1" != "0" && "$pl2" != "0" ]]; then
			echo "  PL1: ${pl1}W"
			echo "  PL2: ${pl2}W"
		else
			echo "  ${RED}RAPL reading failed${NC}"
		fi
	else
		echo -e "\nPower Limits: ${RED}RAPL not available${NC}"
	fi

	# Temp - use first thermal zone with reasonable temperature
	temp="0"
	for zone in /sys/class/thermal/thermal_zone*/temp; do
		[[ -r "$zone" ]] || continue
		local t
		t=$(cat "$zone" 2>/dev/null || echo "0")
		# Only consider reasonable temperatures (above 20°C)
		if [[ "$t" -gt 20000 ]]; then
			temp="$t"
			break
		fi
	done
	echo -e "\nCPU Temp: ${YELLOW}$((temp / 1000))°C${NC}"

	# Battery thresholds
	for bat in /sys/class/power_supply/BAT*; do
		[[ -d "$bat" ]] || continue
		if [[ -r "$bat/charge_control_start_threshold" && -r "$bat/charge_control_end_threshold" ]]; then
			local s e
			s=$(cat "$bat/charge_control_start_threshold" 2>/dev/null || echo "N/A")
			e=$(cat "$bat/charge_control_end_threshold" 2>/dev/null || echo "N/A")
			echo -e "Battery Thresholds: ${YELLOW}Start: ${s}% | Stop: ${e}%${NC}"
			break
		fi
	done

	# Timer info
	IFS='|' read -r tstat tlast < <(timer_status)
	echo -e "cpu-power-limit.timer: ${YELLOW}${tstat}${NC} ${DIM}(last: ${tlast})${NC}"

	# P-state mode note
	local mode
	mode="$(pstate_mode)"
	if [[ "$mode" == "passive" ]]; then
		echo -e "${DIM}Note: intel_pstate running in 'passive' mode. Governor controls frequencies.${NC}"
	fi
}

# ── Profiles ──────────────────────────────────────────────────────────────────
apply_profile_balanced() {
	echo -e "${YELLOW}Applying BALANCED mode${NC}"
	set_governor_all "schedutil"
	set_epp_all "balance_performance"
	set_min_all ""
	set_max_to_cpuinfo
	set_turbo 0
	echo -e "${GREEN}Balanced mode applied${NC}"
}

apply_profile_performance() {
	echo -e "${GREEN}Applying PERFORMANCE mode${NC}"
	set_governor_all "performance"
	set_epp_all "performance"
	set_min_all "1400000"
	set_max_to_cpuinfo
	set_turbo 0

	# Set RAPL limits if available
	if rapl_ok; then
		local cpu
		cpu="$(detect_cpu)"
		case "$cpu" in
		meteorlake)
			write_pl 0 28
			write_pl 1 55
			;;
		kabylaker)
			write_pl 0 25
			write_pl 1 35
			;;
		*)
			write_pl 0 25
			write_pl 1 35
			;;
		esac
		echo "RAPL limits applied"
	fi
	echo -e "${GREEN}Performance mode applied${NC}"
}

apply_profile_powersave() {
	echo -e "${BLUE}Applying POWERSAVE mode${NC}"
	set_governor_all "powersave"
	set_epp_all "balance_power"
	set_min_all "800000"
	set_max_to_cpuinfo
	set_turbo 0

	# Conservative RAPL limits for battery
	if rapl_ok; then
		local cpu
		cpu="$(detect_cpu)"
		case "$cpu" in
		meteorlake)
			write_pl 0 20
			write_pl 1 35
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
		echo "RAPL limits applied"
	fi
	echo -e "${GREEN}Powersave mode applied${NC}"
}

apply_custom() {
	echo -e "${YELLOW}Custom Settings${NC}"
	read -rp "Governor (performance/powersave, default=performance): " g
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
	fi

	echo -e "${GREEN}Custom settings applied${NC}"
}

# ── UI ────────────────────────────────────────────────────────────────────────
menu() {
	echo -e "\n${BLUE}=== ThinkPad Performance Control ===${NC}"
	echo "1) Show current status"
	echo "2) PERFORMANCE mode"
	echo "3) BALANCED mode"
	echo "4) POWERSAVE mode"
	echo "5) CUSTOM settings"
	echo "6) Exit"
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
				;;
			3)
				need_root
				apply_profile_balanced
				;;
			4)
				need_root
				apply_profile_powersave
				;;
			5)
				need_root
				apply_custom
				;;
			6) exit 0 ;;
			*) echo -e "${RED}Invalid option${NC}" ;;
			esac
			echo -e "\nPress Enter to continue…"
			read -r
		done
	else
		case "$1" in
		status) status ;;
		performance)
			need_root
			apply_profile_performance
			;;
		balanced)
			need_root
			apply_profile_balanced
			;;
		powersave)
			need_root
			apply_profile_powersave
			;;
		custom)
			need_root
			apply_custom
			;;
		--help | -h)
			cat <<EOF
Usage: $0 [command]

Commands:
  status        Show current status
  performance   Performance mode (governor=performance, EPP=performance)
  balanced      Balanced mode (governor=schedutil, EPP=balance_performance)  
  powersave     Power save mode (governor=powersave, EPP=balance_power)
  custom        Interactive custom settings
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
