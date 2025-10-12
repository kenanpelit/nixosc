#!/usr/bin/env bash

# System Status Script with JSON support

if [[ "${1:-}" == "--json" ]]; then
	# Detect CPU type
	CPU_TYPE="unknown"
	if grep -q "Intel" /proc/cpuinfo 2>/dev/null; then
		CPU_TYPE="intel"
	elif grep -q "AMD" /proc/cpuinfo 2>/dev/null; then
		CPU_TYPE="amd"
	fi

	# Check power source
	ON_AC=0
	for PS in /sys/class/power_supply/AC*/online /sys/class/power_supply/ADP*/online; do
		[[ -f "$PS" ]] && ON_AC="$(cat "$PS")" && break
	done

	# Get governor and pstate
	GOVERNOR=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null || echo "unknown")
	PSTATE=$(cat /sys/devices/system/cpu/intel_pstate/status 2>/dev/null || echo "unknown")

	# Calculate average frequency
	FREQ_SUM=0
	FREQ_COUNT=0
	for f in /sys/devices/system/cpu/cpu[0-9]*/cpufreq/scaling_cur_freq; do
		[[ -f "$f" ]] || continue
		FREQ_SUM=$((FREQ_SUM + $(cat "$f")))
		FREQ_COUNT=$((FREQ_COUNT + 1))
	done
	FREQ_AVG=0
	[[ $FREQ_COUNT -gt 0 ]] && FREQ_AVG=$((FREQ_SUM / FREQ_COUNT / 1000))

	# Get temperature
	TEMP=$(sensors 2>/dev/null |
		grep -E 'Package id 0|Tctl' |
		awk '{match($0, /[+]?([0-9]+\.[0-9]+)/, arr); if(arr[1]!="") print arr[1]; exit}')
	[[ -z "$TEMP" ]] && TEMP="0"

	# Get power limits
	PL1=0
	PL2=0
	if [[ -d /sys/class/powercap/intel-rapl:0 ]]; then
		PL1=$(($(cat /sys/class/powercap/intel-rapl:0/constraint_0_power_limit_uw 2>/dev/null || echo 0) / 1000000))
		PL2=$(($(cat /sys/class/powercap/intel-rapl:0/constraint_1_power_limit_uw 2>/dev/null || echo 0) / 1000000))
	fi

	# Output JSON
	jq -n \
		--arg cpu_type "$CPU_TYPE" \
		--argjson on_ac "$ON_AC" \
		--arg governor "$GOVERNOR" \
		--arg pstate "$PSTATE" \
		--argjson freq_avg "$FREQ_AVG" \
		--argjson temp "$TEMP" \
		--argjson pl1 "$PL1" \
		--argjson pl2 "$PL2" \
		'{
      cpu_type: $cpu_type,
      power_source: (if $on_ac == 1 then "AC" else "Battery" end),
      governor: $governor,
      pstate_mode: $pstate,
      freq_avg_mhz: $freq_avg,
      temp_celsius: $temp,
      power_limits: {
        pl1_watts: $pl1,
        pl2_watts: $pl2
      },
      timestamp: now | strftime("%Y-%m-%dT%H:%M:%S%z")
    }'
	exit 0
fi

# Human-readable output
echo "=== SYSTEM STATUS - STABLE PASSIVE MODE ==="
echo ""

# Detect CPU type
CPU_TYPE="unknown"
if grep -q "Intel" /proc/cpuinfo 2>/dev/null; then
	CPU_TYPE="intel"
elif grep -q "AMD" /proc/cpuinfo 2>/dev/null; then
	CPU_TYPE="amd"
fi
echo "CPU Type: $CPU_TYPE"

# Check power source
ON_AC=0
for PS in /sys/class/power_supply/AC*/online /sys/class/power_supply/ADP*/online; do
	[[ -f "$PS" ]] && ON_AC="$(cat "$PS")" && break
done
echo "Power Source: $([ "$ON_AC" = "1" ] && echo "AC" || echo "Battery")"

echo ""
echo "CPU FREQUENCIES (Governor Managed):"
i=0
for f in /sys/devices/system/cpu/cpu[0-9]*/cpufreq/scaling_cur_freq; do
	[[ -f "$f" ]] || continue
	mhz=$(($(cat "$f") / 1000))
	printf "  Core %2d: %4d MHz\n" "$i" "$mhz"
	i=$((i + 1))
done

echo ""
echo "CPU GOVERNOR: $(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null || echo "unknown")"
echo "P-STATE MODE: $(cat /sys/devices/system/cpu/intel_pstate/status 2>/dev/null || echo "unknown")"

echo ""
echo "TEMPERATURE:"
sensors 2>/dev/null | grep -E 'Package|Core|Tctl' | head -3 ||
	echo "  Temperature data unavailable"

echo ""
echo "POWER LIMITS:"
if [[ -d /sys/class/powercap/intel-rapl:0 ]]; then
	RAPL_NAME=$(cat /sys/class/powercap/intel-rapl:0/name 2>/dev/null || echo "unknown")
	PL1=$(($(cat /sys/class/powercap/intel-rapl:0/constraint_0_power_limit_uw 2>/dev/null || echo 0) / 1000000))
	PL2=$(($(cat /sys/class/powercap/intel-rapl:0/constraint_1_power_limit_uw 2>/dev/null || echo 0) / 1000000))
	echo "  Package ($RAPL_NAME):"
	echo "    PL1: ${PL1}W (sustained)"
	echo "    PL2: ${PL2}W (turbo)"
else
	echo "  RAPL interface unavailable"
fi

echo ""
echo "SERVICE STATUS:"

for service in cpu-profile-optimizer thermald; do
	if systemctl is-active "$service.service" >/dev/null 2>&1; then
		echo "  ✅ $service: ACTIVE"
	else
		echo "  ❌ $service: INACTIVE"
	fi
done

ONESHOTS="platform-profile hardware-monitor early-rapl-limits rapl-power-limits battery-thresholds cpu-min-freq-guard"
for service in $ONESHOTS; do
	ACTIVE_STATE=$(systemctl show -p ActiveState --value "$service.service" 2>/dev/null || echo "unknown")
	RESULT=$(systemctl show -p Result --value "$service.service" 2>/dev/null || echo "unknown")

	if [[ "$ACTIVE_STATE" == "inactive" ]] && [[ "$RESULT" == "success" ]]; then
		echo "  ✅ $service: RAN (success)"
	elif [[ "$ACTIVE_STATE" == "inactive" ]] && [[ "$RESULT" == "exit-code" ]]; then
		echo "  ⚠️  $service: RAN (failed)"
	elif [[ "$ACTIVE_STATE" == "active" ]] && [[ "$RESULT" == "success" ]]; then
		echo "  ✅ $service: ACTIVE (success)"
	else
		echo "  ❓ $service: $ACTIVE_STATE ($RESULT)"
	fi
done

echo ""
echo "NOTE: System running in stable passive mode. Governor controls frequencies."
echo "TIP: Use 'system-status --json' for machine-readable output"
