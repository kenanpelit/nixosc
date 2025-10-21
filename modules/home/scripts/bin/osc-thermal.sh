#!/usr/bin/env bash
# thermal-monitor.sh - Comprehensive thermal monitoring script
# Usage: ./thermal-monitor.sh [OPTIONS]
#   -d, --duration SECONDS    Monitor duration (default: 60)
#   -i, --interval SECONDS    Sample interval (default: 2)
#   -o, --output FILE         Log file path (default: thermal-log-TIMESTAMP.csv)
#   -p, --plot                Generate plot after logging (requires gnuplot)
#   -h, --help                Show this help

set -euo pipefail

# ============================================================================
# Configuration & Defaults
# ============================================================================
DURATION=60
INTERVAL=2
OUTPUT=""
PLOT=0
SHOW_LIVE=1

# Colors for live output
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# ============================================================================
# Parse Arguments
# ============================================================================
show_help() {
	cat <<EOF
Thermal Monitor - Comprehensive system thermal logging

Usage: $0 [OPTIONS]

Options:
  -d, --duration SECONDS    Monitor duration in seconds (default: 60)
  -i, --interval SECONDS    Sample interval in seconds (default: 2)
  -o, --output FILE         Output CSV file path (default: thermal-log-TIMESTAMP.csv)
  -p, --plot                Generate gnuplot graph after logging
  -q, --quiet               Disable live output, only log to file
  -h, --help                Show this help message

Examples:
  $0                                    # Monitor for 60s with 2s interval
  $0 -d 300 -i 5                       # Monitor for 5 min with 5s interval
  $0 -d 120 -o my-test.csv -p          # Monitor 2 min, save to file, plot
  $0 -d 3600 -i 10 -q                  # Silent 1 hour monitoring

Output Format (CSV):
  timestamp,temp_c,pl1_w,pl2_w,fan_rpm,avg_mhz,pkg_watt

Note: Run with sudo for accurate PkgWatt measurements via turbostat

EOF
}

while [[ $# -gt 0 ]]; do
	case "$1" in
	-d | --duration)
		DURATION="$2"
		shift 2
		;;
	-i | --interval)
		INTERVAL="$2"
		shift 2
		;;
	-o | --output)
		OUTPUT="$2"
		shift 2
		;;
	-p | --plot)
		PLOT=1
		shift
		;;
	-q | --quiet)
		SHOW_LIVE=0
		shift
		;;
	-h | --help)
		show_help
		exit 0
		;;
	*)
		echo "Unknown option: $1"
		show_help
		exit 1
		;;
	esac
done

# Generate default output filename if not specified
if [[ -z "$OUTPUT" ]]; then
	TIMESTAMP=$(date +%Y%m%d_%H%M%S)
	OUTPUT="thermal-log-${TIMESTAMP}.csv"
fi

# ============================================================================
# Helper Functions
# ============================================================================
read_temp() {
	sensors 2>/dev/null | grep "Package id 0" | grep -oP '\+\K[0-9]+' | head -1 || echo "0"
}

read_pl1() {
	if [[ -r /sys/class/powercap/intel-rapl:0/constraint_0_power_limit_uw ]]; then
		cat /sys/class/powercap/intel-rapl:0/constraint_0_power_limit_uw | awk '{print int($1/1000000)}'
	else
		echo "0"
	fi
}

read_pl2() {
	if [[ -r /sys/class/powercap/intel-rapl:0/constraint_1_power_limit_uw ]]; then
		cat /sys/class/powercap/intel-rapl:0/constraint_1_power_limit_uw | awk '{print int($1/1000000)}'
	else
		echo "0"
	fi
}

read_fan() {
	if [[ -r /proc/acpi/ibm/fan ]]; then
		cat /proc/acpi/ibm/fan 2>/dev/null | grep "speed:" | awk '{print $2}' || echo "0"
	else
		echo "0"
	fi
}

read_power_rapl() {
	# Read power consumption using RAPL energy counters (no root required!)
	local ENERGY_FILE="/sys/class/powercap/intel-rapl:0/energy_uj"

	if [[ ! -r "$ENERGY_FILE" ]]; then
		echo "0"
		return
	fi

	local ENERGY_BEFORE=$(cat "$ENERGY_FILE")
	sleep 0.5 # Sample for 0.5 seconds
	local ENERGY_AFTER=$(cat "$ENERGY_FILE")

	# Handle counter wraparound
	local ENERGY_DIFF=$((ENERGY_AFTER - ENERGY_BEFORE))
	if [[ $ENERGY_DIFF -lt 0 ]]; then
		ENERGY_DIFF=$ENERGY_AFTER
	fi

	# Convert to Watts: (microjoules / 0.5 seconds) / 1,000,000
	echo "scale=2; $ENERGY_DIFF / 500000" | bc
}

read_freq() {
	# Average scaling_cur_freq across all CPUs
	local FREQS=($(cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_cur_freq 2>/dev/null || echo "0"))
	if [[ ${#FREQS[@]} -gt 0 ]]; then
		local SUM=$(
			IFS=+
			echo "$((${FREQS[*]}))"
		)
		echo $((SUM / ${#FREQS[@]} / 1000))
	else
		echo "0"
	fi
}

colorize_temp() {
	local temp=$1
	if ((temp >= 80)); then
		echo -e "${RED}${temp}°C${NC}"
	elif ((temp >= 70)); then
		echo -e "${YELLOW}${temp}°C${NC}"
	else
		echo -e "${GREEN}${temp}°C${NC}"
	fi
}

colorize_power() {
	local power=$1
	if (($(echo "$power >= 30" | bc -l))); then
		echo -e "${RED}${power}W${NC}"
	elif (($(echo "$power >= 20" | bc -l))); then
		echo -e "${YELLOW}${power}W${NC}"
	else
		echo -e "${GREEN}${power}W${NC}"
	fi
}

# ============================================================================
# Main Monitoring Loop
# ============================================================================
SAMPLES=$((DURATION / INTERVAL))
CURRENT=0

# Write CSV header
echo "timestamp,temp_c,pl1_w,pl2_w,fan_rpm,avg_mhz,pkg_watt" >"$OUTPUT"

if [[ $SHOW_LIVE -eq 1 ]]; then
	echo -e "${CYAN}=== Thermal Monitoring Started ===${NC}"
	echo -e "Duration: ${DURATION}s | Interval: ${INTERVAL}s | Samples: ${SAMPLES}"
	echo -e "Output:   ${OUTPUT}"
	if [[ $EUID -ne 0 ]]; then
		echo -e "${YELLOW}Note: Running without root. Using RAPL for power measurements.${NC}"
	fi
	echo ""
	printf "%-8s %-10s %-14s %-8s %-8s %-10s %-10s %-12s\n" \
		"Sample" "Time" "Temp" "PL1" "PL2" "Fan" "Avg_MHz" "PkgWatt"
	echo "------------------------------------------------------------------------------------"
fi

START_TIME=$(date +%s)

while [[ $CURRENT -lt $SAMPLES ]]; do
	CURRENT=$((CURRENT + 1))
	TIMESTAMP=$(date +%s)
	ELAPSED=$((TIMESTAMP - START_TIME))
	TIME_STR=$(date +%H:%M:%S)

	# Read all metrics
	TEMP=$(read_temp)
	PL1=$(read_pl1)
	PL2=$(read_pl2)
	FAN=$(read_fan)
	AVG_MHZ=$(read_freq)

	# Read power via RAPL (takes 0.5s)
	PKG_WATT=$(read_power_rapl)

	# Write to CSV
	echo "${TIMESTAMP},${TEMP},${PL1},${PL2},${FAN},${AVG_MHZ},${PKG_WATT}" >>"$OUTPUT"

	# Live display
	if [[ $SHOW_LIVE -eq 1 ]]; then
		TEMP_COLOR=$(colorize_temp "$TEMP")
		POWER_COLOR=$(colorize_power "$PKG_WATT")
		printf "%-8s %-10s %-20s %-8s %-8s %-10s %-10s %-18s\n" \
			"$CURRENT" "$TIME_STR" "$TEMP_COLOR" "${PL1}W" "${PL2}W" "${FAN}rpm" "${AVG_MHZ}MHz" "$POWER_COLOR"
	fi

	# Sleep for remaining interval time (we already slept 0.5s in read_power_rapl)
	SLEEP_TIME=$((INTERVAL - 1)) # -1 because we spent ~0.5s reading power
	if [[ $SLEEP_TIME -gt 0 ]]; then
		sleep "$SLEEP_TIME"
	fi
done

# ============================================================================
# Summary Statistics
# ============================================================================
if [[ $SHOW_LIVE -eq 1 ]]; then
	echo ""
	echo -e "${CYAN}=== Monitoring Complete ===${NC}"
	echo ""

	# Calculate statistics using awk
	read -r MIN_TEMP AVG_TEMP MAX_TEMP AVG_PL2 AVG_FAN AVG_PWR MIN_PWR MAX_PWR <<<$(awk -F, 'NR>1 {
        if (NR==2 || $2<mint) mint=$2;
        if (NR==2 || $2>maxt) maxt=$2;
        if (NR==2 || $7<minp) minp=$7;
        if (NR==2 || $7>maxp) maxp=$7;
        sumt+=$2; pl2+=$4; fan+=$5; pwr+=$7; count++
    } END {
        printf "%.0f %.1f %.0f %.1f %.0f %.2f %.2f %.2f", mint, sumt/count, maxt, pl2/count, fan/count, pwr/count, minp, maxp
    }' "$OUTPUT")

	echo "Temperature:"
	echo "  Min:     ${MIN_TEMP}°C"
	echo "  Average: ${AVG_TEMP}°C"
	echo "  Max:     ${MAX_TEMP}°C"
	echo ""
	echo "Package Power (RAPL):"
	echo "  Min:     ${MIN_PWR}W"
	echo "  Average: ${AVG_PWR}W"
	echo "  Max:     ${MAX_PWR}W"
	echo ""
	echo "Limits & Fan:"
	echo "  Avg PL2: ${AVG_PL2}W"
	echo "  Avg Fan: ${AVG_FAN} RPM"
	echo ""
	echo "Log saved to: $OUTPUT"
fi

# ============================================================================
# Generate Plot (Optional)
# ============================================================================
if [[ $PLOT -eq 1 ]]; then
	if ! command -v gnuplot &>/dev/null; then
		echo -e "${YELLOW}Warning: gnuplot not found. Skipping plot generation.${NC}"
		echo "Install with: sudo apt install gnuplot  (or equivalent)"
	else
		PLOT_FILE="${OUTPUT%.csv}.png"

		gnuplot <<EOF
set terminal pngcairo size 1400,900 enhanced font 'Arial,11'
set output '${PLOT_FILE}'
set datafile separator ","
set title "Thermal & Power Monitoring - $(basename ${OUTPUT%.csv})" font 'Arial,14'
set xlabel "Time (seconds from start)" font 'Arial,12'
set ylabel "Temperature (°C)" textcolor rgb "red" font 'Arial,12'
set y2label "Power (W) / Fan (RPM/10)" textcolor rgb "blue" font 'Arial,12'
set y2tics
set ytics nomirror
set grid
set key outside right top vertical font 'Arial,10'

# Define colors
set style line 1 lc rgb '#d62728' lt 1 lw 2.5  # Red - Temperature
set style line 2 lc rgb '#1f77b4' lt 1 lw 2  # Blue - PL2
set style line 3 lc rgb '#ff7f0e' lt 1 lw 2  # Orange - PL1
set style line 4 lc rgb '#2ca02c' lt 1 lw 1.5  # Green - Fan
set style line 5 lc rgb '#9467bd' lt 1 lw 2  # Purple - Package Power

# Convert timestamp to relative seconds
plot '${OUTPUT}' using (\$1-$(head -2 "$OUTPUT" | tail -1 | cut -d, -f1)):(column(2)) with lines ls 1 title "Temp (°C)" axes x1y1, \\
     '' using (\$1-$(head -2 "$OUTPUT" | tail -1 | cut -d, -f1)):(column(4)) with lines ls 2 title "PL2 (W)" axes x1y2, \\
     '' using (\$1-$(head -2 "$OUTPUT" | tail -1 | cut -d, -f1)):(column(3)) with lines ls 3 title "PL1 (W)" axes x1y2, \\
     '' using (\$1-$(head -2 "$OUTPUT" | tail -1 | cut -d, -f1)):(column(7)) with lines ls 5 title "Pkg Power (W)" axes x1y2, \\
     '' using (\$1-$(head -2 "$OUTPUT" | tail -1 | cut -d, -f1)):(column(5)/10) with lines ls 4 title "Fan (RPM/10)" axes x1y2
EOF

		if [[ $SHOW_LIVE -eq 1 ]]; then
			echo -e "${GREEN}Plot saved to: ${PLOT_FILE}${NC}"
		fi
	fi
fi

exit 0
