#!/usr/bin/env bash
set -euo pipefail

VERSION="15.1.1"

# ========================================================================
# OSC-SYSTEM: Unified Power Management Utility
# ========================================================================
# A consolidated interface for all power management operations.
#
# Usage: osc-system <command> [options]
#
# Commands:
#   status              Show comprehensive system status
#   turbostat-quick     Quick CPU frequency analysis (5 seconds)
#   turbostat-stress    Performance testing under load
#   turbostat-analyze   Parse and analyze turbostat output
#   power-check         Measure instantaneous power consumption
#   power-monitor       Real-time power monitoring dashboard
#   profile-refresh     Restart all power management services
#   help               Show this help message
# ========================================================================

show_help() {
	cat <<EOF
OSC-SYSTEM v${VERSION} - Unified Power Management Utility

Usage: osc-system <command> [options]

Commands:
  status                Show comprehensive system status
  turbostat-quick       Quick CPU frequency analysis (requires root)
  turbostat-stress      Performance testing under load (requires root)
  turbostat-analyze     Parse and analyze turbostat output (requires root)
  power-check           Measure instantaneous power consumption
  power-monitor         Real-time power monitoring dashboard
  profile-refresh       Restart all power management services (requires root)
  help, -h, --help      Show this help message

Examples:
  osc-system status
  sudo osc-system turbostat-quick
  sudo osc-system turbostat-stress --analyze
  sudo osc-system turbostat-analyze --interval 2 --iters 3
  osc-system power-monitor
  sudo osc-system profile-refresh

For command-specific help:
  osc-system <command> --help
EOF
}

# ========================================================================
# COMMAND: status
# ========================================================================
cmd_status() {
	echo "=== SYSTEM STATUS (v${VERSION}) ==="
	echo ""

	# Power Source Detection
	ON_AC=0
	for PS in /sys/class/power_supply/AC*/online /sys/class/power_supply/ADP*/online; do
		[[ -f "$PS" ]] && ON_AC="$(cat "$PS")" && break
	done
	echo "Power Source: $([ "${ON_AC}" = "1" ] && echo "⚡ AC Power" || echo "🔋 Battery")"

	# Intel P-State Status
	if [[ -f "/sys/devices/system/cpu/intel_pstate/status" ]]; then
		PSTATE=$(cat /sys/devices/system/cpu/intel_pstate/status)
		echo "P-State Mode: ${PSTATE}"

		if [[ -r "/sys/devices/system/cpu/intel_pstate/min_perf_pct" ]]; then
			MIN_PERF=$(cat /sys/devices/system/cpu/intel_pstate/min_perf_pct)
			MAX_PERF=$(cat /sys/devices/system/cpu/intel_pstate/max_perf_pct 2>/dev/null || echo "?")
			echo "  Min/Max Performance: ${MIN_PERF}% / ${MAX_PERF}%"
		fi

		if [[ -r "/sys/devices/system/cpu/intel_pstate/no_turbo" ]]; then
			NO_TURBO=$(cat /sys/devices/system/cpu/intel_pstate/no_turbo)
			echo "  Turbo Boost: $([ "${NO_TURBO}" = "0" ] && echo "✓ Active" || echo "✗ Disabled")"
		fi

		if [[ -r "/sys/devices/system/cpu/intel_pstate/hwp_dynamic_boost" ]]; then
			BOOST=$(cat /sys/devices/system/cpu/intel_pstate/hwp_dynamic_boost)
			echo "  HWP Dynamic Boost: $([ "${BOOST}" = "1" ] && echo "✓ Active" || echo "✗ Disabled")"
		fi
	fi

	# ACPI Platform Profile
	if [[ -r "/sys/firmware/acpi/platform_profile" ]]; then
		PROFILE=$(cat /sys/firmware/acpi/platform_profile)
		echo "Platform Profile: ${PROFILE}"
	fi

	# Energy Performance Preference (EPP) Summary
	echo ""
	CPU_COUNT=$(ls -d /sys/devices/system/cpu/cpu[0-9]* 2>/dev/null | wc -l | tr -d ' ')
	declare -A EPP_MAP=()
	for pol in /sys/devices/system/cpu/cpufreq/policy*; do
		[[ -r "$pol/energy_performance_preference" ]] || continue
		epp=$(cat "$pol/energy_performance_preference")
		EPP_MAP["$epp"]=$((${EPP_MAP["$epp"]-0} + 1))
	done

	echo "EPP (Energy Performance Preference):"
	if [[ "${#EPP_MAP[@]}" -eq 0 ]]; then
		echo "  (EPP interface not found)"
	else
		for k in "${!EPP_MAP[@]}"; do
			count="${EPP_MAP[$k]-0}"
			echo "  - ${k} (on ${count} policies)"
		done
	fi

	# RAPL Power Limits (per domain)
	echo ""
	echo "RAPL POWER LIMITS (per domain):"
	if [[ -d /sys/class/powercap/intel-rapl:0 ]]; then
		for R in /sys/class/powercap/intel-rapl:*; do
			[[ -d "$R" ]] || continue
			NAME=$(basename "$R")
			LABEL=$(cat "$R/name" 2>/dev/null || echo "$NAME")

			PL1=$(cat "$R/constraint_0_power_limit_uw" 2>/dev/null || echo 0)
			PL2=$(cat "$R/constraint_1_power_limit_uw" 2>/dev/null || echo 0)

			echo "  Domain: ${LABEL} (${NAME})"
			printf "    PL1 (Sustained): %3d W\n" $((PL1 / 1000000))
			if [[ "$PL2" -gt 0 ]]; then
				printf "    PL2 (Burst):     %3d W\n" $((PL2 / 1000000))
			fi
		done
	else
		echo "  (RAPL interface not available)"
	fi

	# RAPL Consistency Check: MSR vs MMIO (Package 0)
	echo ""
	echo "RAPL CONSISTENCY (MSR vs MMIO, package-0):"
	MSR_BASE="/sys/class/powercap/intel-rapl:0"
	MMIO_BASE="/sys/class/powercap/intel-rapl-mmio:0"
	if [[ -d "$MSR_BASE" && -d "$MMIO_BASE" ]]; then
		msr_pl1=$(cat "$MSR_BASE/constraint_0_power_limit_uw" 2>/dev/null || echo 0)
		msr_pl2=$(cat "$MSR_BASE/constraint_1_power_limit_uw" 2>/dev/null || echo 0)
		mmio_pl1=$(cat "$MMIO_BASE/constraint_0_power_limit_uw" 2>/dev/null || echo 0)
		mmio_pl2=$(cat "$MMIO_BASE/constraint_1_power_limit_uw" 2>/dev/null || echo 0)

		msr_pl1_w=$((msr_pl1 / 1000000))
		msr_pl2_w=$((msr_pl2 / 1000000))
		mmio_pl1_w=$((mmio_pl1 / 1000000))
		mmio_pl2_w=$((mmio_pl2 / 1000000))

		match_pl1=$([ "${msr_pl1}" = "${mmio_pl1}" ] && echo "✓" || echo "⚠")
		match_pl2=$([ "${msr_pl2}" = "${mmio_pl2}" ] && echo "✓" || echo "⚠")

		echo "  PL1: MSR=${msr_pl1_w} W  |  MMIO=${mmio_pl1_w} W   [$match_pl1 match]"
		if [[ "$msr_pl2_w" -gt 0 || "$mmio_pl2_w" -gt 0 ]]; then
			echo "  PL2: MSR=${msr_pl2_w} W  |  MMIO=${mmio_pl2_w} W   [$match_pl2 match]"
		fi
		if [[ "$match_pl1" = "⚠" || "$match_pl2" = "⚠" ]]; then
			echo "  Note: Mismatch detected. A service or firmware may be rewriting one interface."
		fi
	else
		echo "  (One or both interfaces missing; skipping parity check)"
	fi

	# Battery Status and Health Settings
	echo ""
	echo "BATTERY STATUS:"
	found_bat=0
	for bat in /sys/class/power_supply/BAT*; do
		[[ -d "$bat" ]] || continue
		found_bat=1
		NAME=$(basename "$bat")
		CAPACITY=$(cat "$bat/capacity" 2>/dev/null || echo "N/A")
		STATUS=$(cat "$bat/status" 2>/dev/null || echo "N/A")
		START=$(cat "$bat/charge_control_start_threshold" 2>/dev/null || echo "N/A")
		STOP=$(cat "$bat/charge_control_end_threshold" 2>/dev/null || echo "N/A")
		echo "  ${NAME}: ${CAPACITY}% (${STATUS}) | Charge Thresholds: Start=${START}%, Stop=${STOP}%"
	done
	[[ "$found_bat" -eq 0 ]] && echo "  (No battery detected)"

	# Service Health Status
	echo ""
	echo "SERVICE STATUS:"
	for svc in battery-thresholds platform-profile cpu-epp cpu-epb cpu-min-freq-guard rapl-power-limits rapl-thermo-guard disable-rapl-mmio rapl-mmio-sync rapl-mmio-keeper; do
		STATE=$(systemctl show -p ActiveState --value "$svc.service" 2>/dev/null)
		RESULT=$(systemctl show -p Result --value "$svc.service" 2>/dev/null)
		if [[ ("${STATE}" == "inactive" && "${RESULT}" == "success") || "${STATE}" == "active" ]]; then
			printf "  %-25s [ ✅ OK ]\n" "$svc"
		else
			printf "  %-25s [ ⚠️  ${STATE} (${RESULT}) ]\n" "$svc"
		fi
	done

	echo ""
	echo "💡 Tip: Use 'osc-system turbostat-quick' for real-time frequency analysis (requires root)."
	echo "💡 Tip: Use 'osc-system power-monitor' for a live power consumption dashboard."
}

# ========================================================================
# COMMAND: turbostat-quick
# ========================================================================
cmd_turbostat_quick() {
	if [[ "${1:-}" == "--help" ]] || [[ "${1:-}" == "-h" ]]; then
		cat <<EOF
Usage: sudo osc-system turbostat-quick

Real CPU frequency analysis using turbostat.
Shows actual CPU behavior by reading hardware counters.

Key metrics:
  - Avg_MHz: True average frequency, including idle time
  - Bzy_MHz: Average frequency of non-idle cores
  - PkgWatt: Total power consumption of the CPU package

Requires root privileges to access Model-Specific Registers (MSRs).
EOF
		return 0
	fi

	echo "=== TURBOSTAT QUICK ANALYSIS (5 seconds) ==="
	echo ""
	echo "NOTE: 'Avg_MHz' is the true average frequency. 'Bzy_MHz' is frequency when busy."
	echo "      scaling_cur_freq from sysfs may show 400 MHz; ignore it under HWP."
	echo ""

	if ! command -v turbostat &>/dev/null; then
		echo "⚠ turbostat not found. Ensure linuxPackages_latest.turbostat is installed."
		exit 1
	fi

	if [[ $EUID -ne 0 ]]; then
		echo "⚠ This command requires root privileges to read MSRs."
		echo "   Please run: sudo osc-system turbostat-quick"
		exit 1
	fi

	turbostat --interval 5 --num_iterations 1
}

# ========================================================================
# COMMAND: turbostat-stress
# ========================================================================
cmd_turbostat_stress() {
	ANALYZE=0
	while [[ $# -gt 0 ]]; do
		case "$1" in
		--analyze)
			ANALYZE=1
			shift
			;;
		-h | --help)
			cat <<EOF
Usage: sudo osc-system turbostat-stress [--analyze]

Performance testing under load with turbostat monitoring.

Options:
  --analyze     Show detailed analysis summary after test

Test sequence:
  1. Measure baseline idle state (2 seconds)
  2. Launch stress test with full CPU load
  3. Monitor performance under load (8 seconds)

Expected results:
  - Sustained (PL1): ~1900 MHz @ 27W
  - Burst (PL2): ~2700 MHz @ 41W (first 2 seconds)

Requires root privileges.
EOF
			return 0
			;;
		*)
			echo "Unknown arg: $1" >&2
			exit 2
			;;
		esac
	done

	echo "=== CPU PERFORMANCE STRESS TEST (10 seconds) ==="
	echo ""

	MISSING=""
	if ! command -v turbostat &>/dev/null; then
		MISSING="turbostat"
	fi
	if ! command -v stress-ng &>/dev/null; then
		MISSING="${MISSING:+$MISSING, }stress-ng"
	fi
	if [[ -n "${MISSING}" ]]; then
		echo "⚠ Required tools not found: ${MISSING}"
		exit 1
	fi

	if [[ $EUID -ne 0 ]]; then
		echo "⚠ This command requires root privileges to read MSRs."
		echo "   Please run: sudo osc-system turbostat-stress"
		exit 1
	fi

	echo "--- Measuring initial idle state (2 seconds)... ---"
	turbostat --interval 2 --num_iterations 1

	echo ""
	echo "--- Starting stress test and monitoring under load (8 seconds)... ---"

	stress-ng --cpu 0 --timeout 10s &
	STRESS_PID=$!
	sleep 1

	if [[ "${ANALYZE}" -eq 1 ]]; then
		turbostat --interval 8 --num_iterations 1 | tee /dev/stderr | osc-system turbostat-analyze --file - --mode load
	else
		turbostat --interval 8 --num_iterations 1
	fi

	wait "${STRESS_PID}" 2>/dev/null || true

	echo ""
	echo "Stress test complete."
	echo ""
	echo "📊 Evaluation Criteria:"
	echo "   - Avg_MHz ≥ 2000 MHz indicates good performance"
	echo "   - PkgWatt should approach RAPL limits (35W sustained, 55W burst)"
	echo "   - Package Temperature should stay below 85°C"
	echo "   - Bzy_MHz shows frequency when cores are busy"
}

# ========================================================================
# COMMAND: turbostat-analyze
# ========================================================================
cmd_turbostat_analyze() {
	INTERVAL=5
	ITERS=1
	INPUT="-"
	RUN_TURBOSTAT=1
	MODE="auto"

	while [[ $# -gt 0 ]]; do
		case "$1" in
		--interval)
			INTERVAL="$2"
			shift 2
			;;
		--iters | --num-iterations)
			ITERS="$2"
			shift 2
			;;
		--file)
			INPUT="$2"
			RUN_TURBOSTAT=0
			shift 2
			;;
		--mode)
			MODE="$2"
			shift 2
			;;
		-h | --help)
			cat <<EOF
Usage: sudo osc-system turbostat-analyze [options]

Parse turbostat output and print a concise summary.

Options:
  --interval N           Turbostat sample interval in seconds (default: 5)
  --iters N              Number of iterations (default: 1)
  --file PATH|-          Parse from file or STDIN instead of running turbostat
  --mode auto|load|idle  Analysis mode (default: auto)

Modes:
  auto  - Automatic detection (IDLE for very low load, otherwise normal analysis)
  load  - Force load thresholds (no IDLE shortcut)
  idle  - Force IDLE verdict (for quiet checks)

Examples:
  sudo osc-system turbostat-analyze
  sudo osc-system turbostat-analyze --interval 2 --iters 3
  turbostat ... | sudo osc-system turbostat-analyze --file -
  sudo osc-system turbostat-analyze --file /path/to/turbostat.log
  sudo osc-system turbostat-analyze --mode load

Requires root privileges when running turbostat.
EOF
			return 0
			;;
		*)
			echo "Unknown arg: $1" >&2
			exit 2
			;;
		esac
	done

	if [[ "${RUN_TURBOSTAT}" -eq 1 ]]; then
		if [[ $EUID -ne 0 ]]; then
			echo "⚠ This command needs root to read MSRs. Try: sudo osc-system turbostat-analyze" >&2
			exit 1
		fi
		if ! command -v turbostat >/dev/null 2>&1; then
			echo "⚠ turbostat not found." >&2
			exit 1
		fi
	fi

	if [[ "${RUN_TURBOSTAT}" -eq 1 ]]; then
		DATA="$(turbostat --interval "${INTERVAL}" --num_iterations "${ITERS}" 2>/dev/null)"
	else
		if [[ "${INPUT}" = "-" ]]; then
			DATA="$(cat -)"
		else
			DATA="$(cat "${INPUT}")"
		fi
	fi

	parse_out="$(
		echo "${DATA}" | awk '
            BEGIN { FS="[ \t]+"; gotHdr=0 }
            $1=="Core" {
                gotHdr=1
                for (i=1; i<=NF; i++) h[$i]=i
                next
            }
            gotHdr && $1=="-" {
                avg=""; busy=""; bzy=""; ipc=""; pkgw=""; corw=""; gfxw=""; unc=""; diec6=""
                i=h["Avg_MHz"]; if (i>0 && i<=NF) avg=$(i)
                i=h["Busy%"];  if (i>0 && i<=NF) busy=$(i)
                i=h["Bzy_MHz"]; if (i>0 && i<=NF) bzy=$(i)
                i=h["IPC"];     if (i>0 && i<=NF) ipc=$(i)
                i=h["PkgWatt"]; if (i>0 && i<=NF) pkgw=$(i)
                i=h["CorWatt"]; if (i>0 && i<=NF) corw=$(i)
                i=h["GFXWatt"]; if (i>0 && i<=NF) gfxw=$(i)
                i=h["UncMHz"];  if (i>0 && i<=NF) unc=$(i)
                i=h["Die%c6"];  if (i>0 && i<=NF) diec6=$(i)
                print avg "\t" busy "\t" bzy "\t" ipc "\t" pkgw "\t" corw "\t" gfxw "\t" unc "\t" diec6
                exit
            }
        '
	)"

	if [[ -z "${parse_out}" ]]; then
		echo "⚠ Could not parse turbostat summary row. Is the input complete?" >&2
		echo "Tip: Ensure the output includes a header line starting with 'Core' and a summary row starting with '-'." >&2
		exit 3
	fi

	IFS=$'\t' read -r AVG_MHZ BUSY_PCT BZY_MHZ IPC PKG_W COR_W GFX_W UNC_MHZ DIE_C6 <<<"${parse_out}"

	PL1=""
	PL2=""
	if [[ -r /sys/class/powercap/intel-rapl:0/constraint_0_power_limit_uw ]]; then
		PL1=$(cat /sys/class/powercap/intel-rapl:0/constraint_0_power_limit_uw 2>/dev/null || echo "")
		[[ -n "${PL1}" ]] && PL1=$((PL1 / 1000000))
	fi
	if [[ -r /sys/class/powercap/intel-rapl:0/constraint_1_power_limit_uw ]]; then
		PL2=$(cat /sys/class/powercap/intel-rapl:0/constraint_1_power_limit_uw 2>/dev/null || echo "")
		[[ -n "${PL2}" ]] && PL2=$((PL2 / 1000000))
	fi

	pct_of() {
		local val="$1" lim="$2"
		if [[ -z "${val}" || -z "${lim}" || "${lim}" = "0" ]]; then
			echo "N/A"
			return
		fi
		printf "%0.1f%%" "$(echo "scale=3; (${val}/${lim})*100" | bc)"
	}

	echo "=== TURBOSTAT ANALYZE SUMMARY ==="
	printf "Avg_MHz:   %s\n" "${AVG_MHZ:-N/A}"
	printf "Busy%%:     %s\n" "${BUSY_PCT:-N/A}"
	printf "Bzy_MHz:   %s\n" "${BZY_MHZ:-N/A}"
	printf "IPC:       %s\n" "${IPC:-N/A}"
	printf "PkgWatt:   %s W\n" "${PKG_W:-N/A}"
	printf "CorWatt:   %s W\n" "${COR_W:-N/A}"
	printf "GFXWatt:   %s W\n" "${GFX_W:-N/A}"
	printf "UncMHz:    %s\n" "${UNC_MHZ:-N/A}"
	[[ -n "${DIE_C6:-}" ]] && printf "Die%%c6:   %s\n" "${DIE_C6}"

	PCT_PL1=""
	PCT_PL2=""
	if [[ -n "${PL1}" && -n "${PKG_W}" ]]; then
		PCT_PL1="$(pct_of "${PKG_W}" "${PL1}")"
	fi
	if [[ -n "${PL2}" && -n "${PKG_W}" ]]; then
		PCT_PL2="$(pct_of "${PKG_W}" "${PL2}")"
	fi

	if [[ -n "${PL1}" || -n "${PL2}" ]]; then
		echo ""
		echo "RAPL Limits:"
		if [[ -n "${PL1}" ]]; then
			if [[ -n "${PCT_PL1}" && "${PCT_PL1}" != "N/A" ]]; then
				echo "  PL1 (Sustained): ${PL1} W  → ${PCT_PL1} of PL1"
			else
				echo "  PL1 (Sustained): ${PL1} W"
			fi
		fi
		if [[ -n "${PL2}" ]]; then
			if [[ -n "${PCT_PL2}" && "${PCT_PL2}" != "N/A" ]]; then
				echo "  PL2 (Burst):     ${PL2} W  → ${PCT_PL2} of PL2"
			else
				echo "  PL2 (Burst):     ${PL2} W"
			fi
		fi
	fi

	echo ""
	verdict="OK"
	reason=()

	if [[ -n "${AVG_MHZ:-}" ]]; then
		avg_int=$(printf "%.0f" "${AVG_MHZ}")
	else
		avg_int=0
	fi
	busy_int=$(awk -v v="${BUSY_PCT:-0}" 'BEGIN{print int(v+0.5)}')

	case "${MODE}" in
	idle)
		verdict="IDLE"
		;;
	load)
		((avg_int < 2000)) && {
			verdict="WARN"
			reason+=("Avg_MHz < 2000")
		}
		((busy_int < 95)) && reason+=("Busy% < 95 (may not be full load)")
		if [[ -n "${PL1:-}" && -n "${PKG_W:-}" ]]; then
			hit_pl1=$(bc <<<"scale=3; ${PKG_W}/${PL1} >= 0.8")
			[[ "${hit_pl1}" -ne 1 ]] && reason+=("PkgWatt < 80% of PL1")
		fi
		;;
	auto | *)
		if ((busy_int < 10)) && ((avg_int < 500)); then
			verdict="IDLE"
		else
			((avg_int < 2000)) && {
				verdict="WARN"
				reason+=("Avg_MHz < 2000")
			}
			((busy_int < 95)) && reason+=("Busy% < 95 (may not be full load)")
			if [[ -n "${PL1:-}" && -n "${PKG_W:-}" ]]; then
				hit_pl1=$(bc <<<"scale=3; ${PKG_W}/${PL1} >= 0.8")
				[[ "${hit_pl1}" -ne 1 ]] && reason+=("PkgWatt < 80% of PL1")
			fi
		fi
		;;
	esac

	echo "Verdict: ${verdict}"
	if ((${#reason[@]})); then
		echo "Notes:"
		for r in "${reason[@]}"; do
			echo "  - $r"
		done
	fi
}

# ========================================================================
# COMMAND: power-check
# ========================================================================
cmd_power_check() {
	if [[ "${1:-}" == "--help" ]] || [[ "${1:-}" == "-h" ]]; then
		cat <<EOF
Usage: osc-system power-check

Measure instantaneous CPU package power consumption by sampling
RAPL energy counters over a 2-second interval.

Shows:
  - Current power source (AC/Battery)
  - Instantaneous package power in watts
  - Active RAPL limits (PL1/PL2)
  - Qualitative power level interpretation
EOF
		return 0
	fi

	echo "=== INSTANTANEOUS POWER CONSUMPTION CHECK ==="
	echo ""

	ON_AC=0
	for PS in /sys/class/power_supply/AC*/online /sys/class/power_supply/ADP*/online; do
		[[ -f "$PS" ]] && ON_AC="$(cat "$PS")" && break
	done
	echo "Power Source: $([ "${ON_AC}" = "1" ] && echo "⚡ AC Power" || echo "🔋 Battery")"
	echo ""

	if [[ ! -f /sys/class/powercap/intel-rapl:0/energy_uj ]]; then
		echo "⚠ RAPL interface not found. Cannot measure power."
		exit 1
	fi

	echo "Measuring power consumption over a 2-second interval..."
	ENERGY_BEFORE=$(cat /sys/class/powercap/intel-rapl:0/energy_uj)
	sleep 2
	ENERGY_AFTER=$(cat /sys/class/powercap/intel-rapl:0/energy_uj)

	ENERGY_DIFF=$((ENERGY_AFTER - ENERGY_BEFORE))
	[[ "${ENERGY_DIFF}" -lt 0 ]] && ENERGY_DIFF="${ENERGY_AFTER}"

	WATTS=$(echo "scale=2; ${ENERGY_DIFF} / 2000000" | bc)

	echo ""
	echo ">> INSTANTANEOUS PACKAGE POWER: ${WATTS} W"
	echo ""

	PL1=$(cat /sys/class/powercap/intel-rapl:0/constraint_0_power_limit_uw)
	PL2=$(cat /sys/class/powercap/intel-rapl:0/constraint_1_power_limit_uw)
	printf "Active RAPL Limits:\n  PL1 (Sustained): %3d W\n  PL2 (Burst):     %3d W\n\n" $((PL1 / 1000000)) $((PL2 / 1000000))

	WATTS_INT=$(echo "${WATTS}" | cut -d. -f1)
	if [[ "${WATTS_INT}" -lt 10 ]]; then
		echo "📊 Status: Idle or light usage."
	elif [[ "${WATTS_INT}" -lt 30 ]]; then
		echo "📊 Status: Normal productivity workload."
	elif [[ "${WATTS_INT}" -lt 50 ]]; then
		echo "📊 Status: High load (compiling, gaming)."
	else
		echo "📊 Status: Very high load (stress test)."
	fi
}

# ========================================================================
# COMMAND: power-monitor
# ========================================================================
cmd_power_monitor() {
	if [[ "${1:-}" == "--help" ]] || [[ "${1:-}" == "-h" ]]; then
		cat <<EOF
Usage: osc-system power-monitor

Real-time power monitoring dashboard.
Continuously updates every second showing:
  - Power source (AC/Battery)
  - Current EPP setting
  - Package temperature
  - RAPL power consumption
  - CPU frequency statistics

Press Ctrl+C to stop monitoring.
EOF
		return 0
	fi

	trap "tput cnorm; exit" INT
	tput civis

	while true; do
		clear
		echo "=== REAL-TIME POWER MONITOR (v${VERSION}) | Press Ctrl+C to stop ==="
		echo "Timestamp: $(date '+%H:%M:%S')"
		echo "------------------------------------------------------------"

		ON_AC=0
		for PS in /sys/class/power_supply/AC*/online /sys/class/power_supply/ADP*/online; do
			[[ -f "$PS" ]] && ON_AC="$(cat "$PS")" && break
		done
		echo "Power Source:  $([ "${ON_AC}" = "1" ] && echo "⚡ AC Power" || echo "🔋 Battery")"

		EPP=$(cat /sys/devices/system/cpu/cpufreq/policy0/energy_performance_preference 2>/dev/null || echo "N/A")
		echo "EPP Setting:   ${EPP}"

		TEMP=$(sensors 2>/dev/null | grep "Package id 0" | awk '{match($0, /[+]?([0-9]+\.[0-9]+)/, a); print a[1]}')
		[[ -n "${TEMP}" ]] && printf "Temperature:   %.1f°C\n" "${TEMP}" || echo "Temperature:   N/A"

		echo "------------------------------------------------------------"

		if [[ -f /sys/class/powercap/intel-rapl:0/energy_uj ]]; then
			ENERGY_BEFORE=$(cat /sys/class/powercap/intel-rapl:0/energy_uj)
			sleep 0.5
			ENERGY_AFTER=$(cat /sys/class/powercap/intel-rapl:0/energy_uj)

			ENERGY_DIFF=$((ENERGY_AFTER - ENERGY_BEFORE))
			[[ "${ENERGY_DIFF}" -lt 0 ]] && ENERGY_DIFF="${ENERGY_AFTER}"
			WATTS=$(echo "scale=2; ${ENERGY_DIFF} / 500000" | bc)

			PL1=$(cat /sys/class/powercap/intel-rapl:0/constraint_0_power_limit_uw 2>/dev/null || echo 0)
			PL2=$(cat /sys/class/powercap/intel-rapl:0/constraint_1_power_limit_uw 2>/dev/null || echo 0)

			echo "PACKAGE POWER (RAPL):"
			printf "  Current Consumption: %6.2f W\n" "${WATTS}"
			printf "  Sustained Limit (PL1): %4d W\n" $((PL1 / 1000000))
			printf "  Burst Limit (PL2):     %4d W\n" $((PL2 / 1000000))
		else
			echo "PACKAGE POWER (RAPL): Not Available"
		fi

		echo "------------------------------------------------------------"
		echo "CPU FREQUENCY (scaling_cur_freq):"
		FREQS=($(cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_cur_freq))
		if [[ ${#FREQS[@]} -gt 0 ]]; then
			SUM=$(
				IFS=+
				echo "$((${FREQS[*]}))"
			)
			AVG=$((SUM / ${#FREQS[@]} / 1000))
			MIN=$(printf "%s\n" "${FREQS[@]}" | sort -n | head -1)
			MAX=$(printf "%s\n" "${FREQS[@]}" | sort -n | tail -1)
			printf "  Average: %5d MHz\n" "$AVG"
			printf "  Min/Max: %5d / %d MHz\n" "$((MIN / 1000))" "$((MAX / 1000))"
			echo "  (NOTE: This value can be misleading; use turbostat for ground truth)"
		else
			echo "  Frequency data not available."
		fi
		sleep 0.5
	done
}

# ========================================================================
# COMMAND: profile-refresh
# ========================================================================
cmd_profile_refresh() {
	if [[ "${1:-}" == "--help" ]] || [[ "${1:-}" == "-h" ]]; then
		cat <<EOF
Usage: sudo osc-system profile-refresh

Restart all custom power management services.
Useful for testing configuration changes or recovering
from a failed state without needing a full reboot.

Services restarted:
  - platform-profile
  - cpu-epp
  - cpu-epb
  - cpu-min-freq-guard
  - rapl-power-limits
  - disable-rapl-mmio
  - rapl-mmio-sync
  - rapl-mmio-keeper
  - rapl-thermo-guard
  - battery-thresholds

Requires root privileges.
EOF
		return 0
	fi

	echo "=== RESTARTING POWER PROFILE SERVICES ==="
	echo ""
	if [[ $EUID -ne 0 ]]; then
		echo "⚠ This command requires root privileges. Please run with sudo."
		exit 1
	fi

	SERVICES=(
		"platform-profile.service"
		"cpu-epp.service"
		"cpu-epb.service"
		"cpu-min-freq-guard.service"
		"rapl-power-limits.service"
		"disable-rapl-mmio.service"
		"rapl-mmio-sync.service"
		"rapl-mmio-keeper.service"
		"rapl-thermo-guard.service"
		"battery-thresholds.service"
	)

	for SVC in "${SERVICES[@]}"; do
		printf "Restarting %-30s ... " "$SVC"
		if systemctl restart "$SVC" 2>/dev/null; then
			echo "[ OK ]"
		else
			echo "[ FAILED ]"
		fi
	done

	echo ""
	echo "✓ All power-related services have been refreshed."
	echo "-------------------------------------------------"
	cmd_status
}

# ========================================================================
# MAIN DISPATCHER
# ========================================================================
main() {
	if [[ $# -eq 0 ]]; then
		show_help
		exit 0
	fi

	case "$1" in
	status)
		shift
		cmd_status "$@"
		;;
	turbostat-quick)
		shift
		cmd_turbostat_quick "$@"
		;;
	turbostat-stress)
		shift
		cmd_turbostat_stress "$@"
		;;
	turbostat-analyze)
		shift
		cmd_turbostat_analyze "$@"
		;;
	power-check)
		shift
		cmd_power_check "$@"
		;;
	power-monitor)
		shift
		cmd_power_monitor "$@"
		;;
	profile-refresh)
		shift
		cmd_profile_refresh "$@"
		;;
	help | -h | --help)
		show_help
		;;
	*)
		echo "Error: Unknown command '$1'" >&2
		echo "" >&2
		show_help
		exit 1
		;;
	esac
}

main "$@"
